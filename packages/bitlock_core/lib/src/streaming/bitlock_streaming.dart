import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../crypto/aead.dart';
import '../crypto/header_mac.dart';
import '../crypto/kdf.dart';
import '../crypto/keys.dart';
import '../errors.dart';
import '../format/bitlock_format.dart';

const _mimeTypes = <String, String>{
  'pdf': 'application/pdf', 'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
  'gif': 'image/gif', 'webp': 'image/webp', 'txt': 'text/plain', 'zip': 'application/zip',
};

List<int> _chunkAad(List<int> id, int index, bool last, List<int> headerMac) =>
    [...ascii.encode('CHUNK'), ...id, ...uint32Bytes(index), last ? 1 : 0, ...headerMac];

List<int> _metaAad(List<int> id, List<int> headerMac) =>
    [...ascii.encode('META'), ...id, ...headerMac];

Future<List<int>> _readExact(RandomAccessFile file, int count) async {
  final result = <int>[];
  while (result.length < count) {
    final next = await file.read(count - result.length);
    if (next.isEmpty) throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data');
    result.addAll(next);
  }
  return result;
}

String _mimeType(String filename) {
  final extension = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
  return _mimeTypes[extension] ?? 'application/octet-stream';
}

String _leafName(String path) => path.split(RegExp(r'[/\\]')).last;

/// Encrypts a file into the version 1 BitLock format using bounded memory.
///
/// The original name, MIME type, and timestamp are encrypted in the metadata
/// record. The final output is installed only after encryption succeeds.
Future<void> encryptFile(String inputPath, String outputPath, String password, {
  int chunkSize = BitlockFormat.defaultChunkSize,
  KdfParams kdf = const KdfParams(),
  String? filename,
  String? mimeType,
  DateTime? createdAt,
}) async {
  if (chunkSize < 1 || chunkSize > BitlockFormat.maxChunkSize) throw ArgumentError.value(chunkSize, 'chunkSize');
  final partPath = '$outputPath.part';
  if (await File(outputPath).exists()) throw FileSystemException('Output already exists', outputPath);
  if (await File(partPath).exists()) throw FileSystemException('Temporary output already exists', partPath);
  final input = await File(inputPath).open(mode: FileMode.read);
  RandomAccessFile? output;
  FileKeyMaterial? material;
  var ownsPart = false;
  var inputOpen = true;
  try {
    final length = await input.length();
    final count = chunkCountFor(length, chunkSize);
    if (count - 1 > 0xffffffff) throw ArgumentError('File needs too many chunks');
    final fileKeys = await createFileKeyMaterial(password, kdf);
    material = fileKeys;
    final wrapped = await wrapDek(fileKeys.dek, fileKeys.keys.kek, fileKeys.fileId);
    final header = BitlockHeader(fileId: fileKeys.fileId, salt: fileKeys.salt, wrappedDek: wrapped,
      chunkSize: chunkSize, plaintextLength: length, kdf: kdf);
    final prefix = header.prefixBytes();
    final headerMac = await computeHeaderMac(fileKeys.keys.headerMacKey, prefix);
    final metadata = BitlockMetadata(
      filename: filename ?? _leafName(inputPath),
      mimeType: mimeType ?? _mimeType(filename ?? _leafName(inputPath)),
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
    );
    final metadataPlaintext = utf8.encode(jsonEncode(metadata.toJson()));
    if (metadataPlaintext.length > 4096) throw ArgumentError('Metadata exceeds 4096 bytes');
    final metadataNonce = secureRandomBytes(BitlockFormat.nonceLength);
    late final List<int> metadataRecord;
    try {
      metadataRecord = await encryptAead(metadataPlaintext, SecretKey(fileKeys.dek), metadataNonce,
          aad: _metaAad(fileKeys.fileId, headerMac));
    } finally {
      metadataPlaintext.fillRange(0, metadataPlaintext.length, 0);
    }

    await File(partPath).create(exclusive: true);
    ownsPart = true;
    output = await File(partPath).open(mode: FileMode.writeOnly);
    await output.writeFrom([...prefix, ...headerMac]);
    await output.writeFrom(metadataRecord);
    for (var index = 0; index < count; index++) {
      final plainLength = length == 0 ? 0 : min(chunkSize, length - index * chunkSize);
      final plaintext = await _readExact(input, plainLength);
      final nonce = secureRandomBytes(BitlockFormat.nonceLength);
      late final List<int> record;
      try {
        record = await encryptAead(plaintext, SecretKey(fileKeys.dek), nonce,
            aad: _chunkAad(fileKeys.fileId, index, index == count - 1, headerMac));
      } finally {
        plaintext.fillRange(0, plaintext.length, 0);
      }
      await output.writeFrom(record);
    }
    if ((await input.read(1)).isNotEmpty) throw FileSystemException('Input changed during encryption');
    await output.flush();
    await output.close();
    output = null;
    await input.close();
    inputOpen = false;
    await File(partPath).rename(outputPath);
    ownsPart = false;
  } catch (_) {
    if (output != null) {
      try { await output.close(); } on Object { /* Continue cleanup after close errors. */ }
    }
    if (inputOpen) {
      try { await input.close(); } on Object { /* Continue cleanup after close errors. */ }
    }
    final part = File(partPath);
    if (ownsPart) {
      try { if (await part.exists()) await part.delete(); } on Object { /* Preserve the original failure. */ }
    }
    rethrow;
  } finally {
    final generated = material;
    if (generated != null) generated.dek.fillRange(0, generated.dek.length, 0);
  }
}

/// Authenticates a container and writes its plaintext only after full validation.
///
/// Plaintext is first written to `<outputPath>.part`; it is renamed only after
/// metadata, all data chunks, and end-of-file have been verified. Returns the
/// decrypted descriptive metadata for the caller.
Future<BitlockMetadata> decryptFile(String inputPath, String outputPath, String password, {
  BitlockIntegrityObserver? integrityObserver,
}) async {
  final partPath = '$outputPath.part';
  if (await File(outputPath).exists()) throw FileSystemException('Output already exists', outputPath);
  if (await File(partPath).exists()) throw FileSystemException('Temporary output already exists', partPath);
  final input = await File(inputPath).open(mode: FileMode.read);
  RandomAccessFile? output;
  List<int>? dek;
  var ownsPart = false;
  var inputOpen = true;
  try {
    final fixed = await _readExact(input, 9);
    final jsonLength = ByteData.sublistView(Uint8List.fromList(fixed), 5, 9).getUint32(0, Endian.big);
    if (jsonLength == 0 || jsonLength > BitlockFormat.maxHeaderJsonLength) {
      throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data');
    }
    final headerBytes = [...fixed, ...await _readExact(input, jsonLength + BitlockFormat.tagLength)];
    final parsed = BitlockHeader.parse(headerBytes);
    final keys = await deriveKeys(password, parsed.header.salt, parsed.header.kdf);
    final expectedMac = await computeHeaderMac(keys.headerMacKey, parsed.prefix);
    if (!constantTimeMacEquals(expectedMac, parsed.mac)) {
      throw const BitlockIntegrityException('Invalid password or BitLock data');
    }
    dek = await unwrapDek(parsed.header.wrappedDek, keys.kek, parsed.header.fileId);

    final metadataRecord = await _readExact(input, _metadataRecordLength(input, parsed.header));
    late final BitlockMetadata metadata;
    try {
      final metadataBytes = await decryptAead(metadataRecord, SecretKey(dek),
          aad: _metaAad(parsed.header.fileId, parsed.mac));
      try {
        metadata = BitlockMetadata.fromJson(jsonDecode(utf8.decode(metadataBytes)));
      } finally {
        metadataBytes.fillRange(0, metadataBytes.length, 0);
      }
    } on Object {
      throw const BitlockIntegrityException('Invalid password or BitLock data');
    }

    await File(partPath).create(exclusive: true);
    ownsPart = true;
    output = await File(partPath).open(mode: FileMode.writeOnly);
    final header = parsed.header;
    final count = header.chunkCount;
    if (count - 1 > 0xffffffff) throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data');
    for (var index = 0; index < count; index++) {
      final plainLength = header.plaintextLength == 0 ? 0 : min(header.chunkSize, header.plaintextLength - index * header.chunkSize);
      final record = await _readExact(input, BitlockFormat.nonceLength + plainLength + BitlockFormat.tagLength);
      late final List<int> plaintext;
      try {
        plaintext = await decryptAead(record, SecretKey(dek),
            aad: _chunkAad(header.fileId, index, index == count - 1, parsed.mac));
      } on Object {
        throw const BitlockIntegrityException('Invalid password or BitLock data');
      }
      try {
        await output.writeFrom(plaintext);
      } finally {
        plaintext.fillRange(0, plaintext.length, 0);
      }
    }
    if ((await input.read(1)).isNotEmpty) throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data');
    await output.flush();
    await output.close();
    output = null;
    await input.close();
    inputOpen = false;
    await File(partPath).rename(outputPath);
    ownsPart = false;
    return metadata;
  } catch (error) {
    if (output != null) {
      try { await output.close(); } on Object { /* Continue cleanup after close errors. */ }
    }
    if (inputOpen) {
      try { await input.close(); } on Object { /* Continue cleanup after close errors. */ }
    }
    final part = File(partPath);
    if (ownsPart) {
      try { if (await part.exists()) await part.delete(); } on Object { /* Preserve the original failure. */ }
    }
    final integrityError = error is BitlockIntegrityException
        ? error
        : error is FormatException || error is RangeError || error is TypeError || error is ArgumentError
            ? const BitlockIntegrityException('Invalid or unauthenticated BitLock data')
            : null;
    if (integrityError != null) {
      if (integrityObserver != null) {
        try { await integrityObserver.onIntegrityFailure(); } on Object { /* Preserve the generic integrity failure. */ }
      }
      throw integrityError;
    }
    rethrow;
  } finally {
    final dataKey = dek;
    if (dataKey != null) dataKey.fillRange(0, dataKey.length, 0);
  }
}

int _metadataRecordLength(RandomAccessFile input, BitlockHeader header) {
  final length = input.lengthSync() - input.positionSync() - header.plaintextLength -
      header.chunkCount * (BitlockFormat.nonceLength + BitlockFormat.tagLength);
  if (length < BitlockFormat.metadataRecordOverhead || length > 4096 + BitlockFormat.metadataRecordOverhead) {
    throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data');
  }
  return length;
}
