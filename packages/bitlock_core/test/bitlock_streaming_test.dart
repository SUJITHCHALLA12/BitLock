import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bitlock_core/bitlock_core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

const chunkSize = 1024;
const fastKdf = KdfParams(memoryKiB: 8, iterations: 1, parallelism: 1);
final _rng = Random.secure();

Future<List<int>> read(File file) => file.readAsBytes();
Future<void> write(File file, List<int> bytes) => file.writeAsBytes(bytes, flush: true);

void main() {
  late Directory temp;
  setUp(() async { temp = await Directory.systemTemp.createTemp('bitlock-test-'); });
  tearDown(() async { if (await temp.exists()) await temp.delete(recursive: true); });

  test('round trips empty, boundary, and multi-chunk files', () async {
    for (final size in [0, 1, 1000, chunkSize - 1, chunkSize, chunkSize + 1, 3 * chunkSize, 3 * chunkSize + 17]) {
      final original = List<int>.generate(size, (i) => (i * 37 + 11) & 0xff);
      final src = File('${temp.path}/in-$size');
      final encrypted = File('${temp.path}/out-$size.bitlock');
      final restored = File('${temp.path}/restored-$size');
      await write(src, original);
      await encryptFile(src.path, encrypted.path, 'correct horse', chunkSize: chunkSize, kdf: fastKdf);
      final metadata = await decryptFile(encrypted.path, restored.path, 'correct horse');
      expect(await read(restored), original, reason: 'size $size');
      expect(metadata.filename, src.uri.pathSegments.last);
      expect(metadata.mimeType, 'application/octet-stream');
    }
  });

  test('binary file signatures remain type agnostic', () async {
    final samples = <String, List<int>>{
      'sample.pdf': [...ascii.encode('%PDF-1.7\n'), ..._randomBytes(4096)],
      'sample.zip': [0x50, 0x4b, 0x03, 0x04, ..._randomBytes(4096)],
      'sample.png': [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, ..._randomBytes(4096)],
      'random.bin': _randomBytes(4096),
    };
    for (final entry in samples.entries) {
      final src = File('${temp.path}/${entry.key}');
      final encrypted = File('${temp.path}/${entry.key}.bitlock');
      final output = File('${temp.path}/${entry.key}.out');
      await write(src, entry.value);
      await encryptFile(src.path, encrypted.path, 'pw', chunkSize: chunkSize, kdf: fastKdf);
      await decryptFile(encrypted.path, output.path, 'pw');
      expect(await read(output), entry.value, reason: entry.key);
    }
  });

  test('filename, MIME type, and creation time are encrypted metadata', () async {
    final source = File('${temp.path}/source')..writeAsBytesSync([1, 2, 3]);
    final encrypted = File('${temp.path}/metadata.bitlock');
    final output = File('${temp.path}/metadata.out');
    final timestamp = DateTime.utc(2026, 10, 8, 11, 15);
    await encryptFile(source.path, encrypted.path, 'pw', kdf: fastKdf,
        filename: 'private-marker.pdf', mimeType: 'application/pdf', createdAt: timestamp);
    final raw = await read(encrypted);
    final headerJson = utf8.decode(raw.sublist(9, 9 + _jsonLength(raw)));
    expect(headerJson, isNot(contains('private-marker.pdf')));
    expect(headerJson, isNot(contains('application/pdf')));
    final metadata = await decryptFile(encrypted.path, output.path, 'pw');
    expect(metadata.filename, 'private-marker.pdf');
    expect(metadata.mimeType, 'application/pdf');
    expect(metadata.createdAt, timestamp);
  });

  test('wrong password fails without creating output', () async {
    final src = File('${temp.path}/source')..writeAsBytesSync(List<int>.filled(2000, 3));
    final encrypted = File('${temp.path}/encrypted');
    final output = File('${temp.path}/wrong-output');
    await encryptFile(src.path, encrypted.path, 'right', chunkSize: chunkSize, kdf: fastKdf);
    await expectLater(decryptFile(encrypted.path, output.path, 'wrong'), throwsA(isA<BitlockIntegrityException>()));
    await _expectNoOutput(output);
  });

  test('tampering with JSON, wrapped DEK, MAC, or metadata fails closed', () async {
    final artifact = await _encryptedFixture(temp);
    final headerEnd = _headerEnd(artifact);
    final json = [...artifact]..[9 + 4] ^= 1;
    final mac = [...artifact]..[headerEnd - 1] ^= 1;
    final wrapped = [...artifact];
    final jsonLength = _jsonLength(artifact);
    final jsonText = utf8.decode(artifact.sublist(9, 9 + jsonLength));
    final wrappedValueOffset = jsonText.indexOf('"w":"') + 5;
    final wrappedByteOffset = 9 + wrappedValueOffset;
    wrapped[wrappedByteOffset] = wrapped[wrappedByteOffset] == 65 ? 66 : 65;
    final metadataOffset = headerEnd;
    final metadata = [...artifact]..[metadataOffset + BitlockFormat.nonceLength] ^= 1;
    for (final entry in {'json': json, 'wrapped': wrapped, 'mac': mac, 'metadata': metadata}.entries) {
      await _mustFail(temp, entry.value, 'header-${entry.key}');
    }
  });

  test('first, middle, last, swapped, duplicate, and spliced chunks fail', () async {
    final artifact = await _encryptedFixture(temp);
    final dataOffset = _dataOffset(artifact);
    final chunkBytes = chunkSize + 28;
    final firstCorrupt = [...artifact]..[dataOffset + 12] ^= 1;
    final middleCorrupt = [...artifact]..[dataOffset + chunkBytes + 12] ^= 1;
    final lastOffset = dataOffset + (3 * chunkSize) + (3 * 28);
    final lastCorrupt = [...artifact]..[lastOffset + 12] ^= 1;
    await _mustFail(temp, firstCorrupt, 'first-corrupt');
    await _mustFail(temp, middleCorrupt, 'middle-corrupt');
    await _mustFail(temp, lastCorrupt, 'last-corrupt');

    final first = artifact.sublist(dataOffset, dataOffset + chunkBytes);
    final second = artifact.sublist(dataOffset + chunkBytes, dataOffset + 2 * chunkBytes);
    final swapped = [...artifact.sublist(0, dataOffset), ...second, ...first,
      ...artifact.sublist(dataOffset + 2 * chunkBytes)];
    await _mustFail(temp, swapped, 'swapped');

    final middleStart = dataOffset + chunkBytes;
    final middle = artifact.sublist(middleStart, middleStart + chunkBytes);
    final duplicated = [...artifact.sublist(0, middleStart + chunkBytes), ...middle,
      ...artifact.sublist(middleStart + chunkBytes)];
    await _mustFail(temp, duplicated, 'duplicate');

    final secondContainer = await _encryptedFixture(temp, name: 'second', byteValue: 0x99);
    final sameIdContainer = await _rewriteContainerId(secondContainer, _header(artifact).fileId);
    final spliced = [...artifact];
    spliced.replaceRange(dataOffset + chunkBytes, dataOffset + 2 * chunkBytes,
        sameIdContainer.sublist(_dataOffset(sameIdContainer) + chunkBytes,
          _dataOffset(sameIdContainer) + 2 * chunkBytes));
    await _mustFail(temp, spliced, 'same-id-splice');
  });

  test('truncation, removing the final chunk, and trailing bytes fail', () async {
    final artifact = await _encryptedFixture(temp);
    await _mustFail(temp, artifact.sublist(0, artifact.length - 17 - 28), 'removed-last');
    await _mustFail(temp, artifact.sublist(0, artifact.length - 1), 'truncated-one');
    await _mustFail(temp, [...artifact, 0x7f], 'trailing');
  });

  test('ciphertext does not expose a long plaintext run', () async {
    final src = File('${temp.path}/repeated')..writeAsBytesSync(List<int>.filled(4096, 0x41));
    final encrypted = File('${temp.path}/repeated.bitlock');
    await encryptFile(src.path, encrypted.path, 'pw', chunkSize: chunkSize, kdf: fastKdf);
    final bytes = await read(encrypted);
    var run = 0;
    for (final byte in bytes) {
      run = byte == 0x41 ? run + 1 : 0;
      expect(run, lessThan(16));
    }
  });

  test('encryptions of same input differ', () async {
    final src = File('${temp.path}/same')..writeAsBytesSync(List<int>.filled(2000, 8));
    final a = File('${temp.path}/a');
    final b = File('${temp.path}/b');
    await encryptFile(src.path, a.path, 'pw', chunkSize: chunkSize, kdf: fastKdf);
    await encryptFile(src.path, b.path, 'pw', chunkSize: chunkSize, kdf: fastKdf);
    expect(await read(a), isNot(await read(b)));
  });

  test('failed decrypt leaves no output or part file', () async {
    final artifact = await _encryptedFixture(temp);
    artifact[artifact.length - 2] ^= 0x55;
    await _mustFail(temp, artifact, 'cleanup');
  });

  test('decrypt failure preserves the original ciphertext bytes', () async {
    final artifact = await _encryptedFixture(temp);
    final damaged = [...artifact]..[_dataOffset(artifact) + 12] ^= 0x80;
    final input = File('${temp.path}/preserved.bitlock');
    final output = File('${temp.path}/preserved.out');
    await write(input, damaged);
    await expectLater(decryptFile(input.path, output.path, 'pw'), throwsA(isA<BitlockIntegrityException>()));
    expect(await read(input), damaged);
    await _expectNoOutput(output);
  });

  test('core refuses to overwrite existing output files', () async {
    final source = File('${temp.path}/source')..writeAsBytesSync([1, 2, 3]);
    final output = File('${temp.path}/existing')..writeAsBytesSync([9, 8, 7]);
    await expectLater(encryptFile(source.path, output.path, 'pw', kdf: fastKdf), throwsA(isA<FileSystemException>()));
    expect(await read(output), [9, 8, 7]);
  });

  test('integrity failures invoke the optional audit and notification seam', () async {
    final artifact = await _encryptedFixture(temp);
    artifact[_dataOffset(artifact) + 12] ^= 0x01;
    final input = File('${temp.path}/observed.bitlock');
    final output = File('${temp.path}/observed.out');
    await write(input, artifact);
    final observer = _TestIntegrityObserver();
    await expectLater(decryptFile(input.path, output.path, 'pw', integrityObserver: observer),
        throwsA(isA<BitlockIntegrityException>()));
    expect(observer.calls, 1);
    expect(await read(input), artifact);
    await _expectNoOutput(output);
  });
}

class _TestIntegrityObserver implements BitlockIntegrityObserver {
  int calls = 0;

  @override
  Future<void> onIntegrityFailure() async { calls++; }
}

List<int> _randomBytes(int count) => List<int>.generate(count, (_) => _rng.nextInt(256));

Future<List<int>> _encryptedFixture(Directory temp, {String name = 'fixture', int byteValue = 0x31}) async {
  final source = File('${temp.path}/$name-input');
  await source.writeAsBytes(List<int>.filled(3 * chunkSize + 17, byteValue));
  final encrypted = File('${temp.path}/$name.bitlock');
  await encryptFile(source.path, encrypted.path, 'pw', chunkSize: chunkSize, kdf: fastKdf,
      filename: '$name.dat', mimeType: 'application/octet-stream', createdAt: DateTime.utc(2026));
  return read(encrypted);
}

int _jsonLength(List<int> bytes) => (bytes[5] << 24) | (bytes[6] << 16) | (bytes[7] << 8) | bytes[8];
int _headerEnd(List<int> bytes) => 9 + _jsonLength(bytes) + BitlockFormat.tagLength;
BitlockHeader _header(List<int> bytes) => BitlockHeader.parse(bytes.sublist(0, _headerEnd(bytes))).header;

int _dataOffset(List<int> bytes) {
  final header = _header(bytes);
  final dataRecordBytes = header.plaintextLength + header.chunkCount * 28;
  final metadataRecordBytes = bytes.length - _headerEnd(bytes) - dataRecordBytes;
  return _headerEnd(bytes) + metadataRecordBytes;
}

Future<List<int>> _rewriteContainerId(List<int> bytes, List<int> newId) async {
  final parsed = BitlockHeader.parse(bytes.sublist(0, _headerEnd(bytes)));
  final header = parsed.header;
  final keys = await deriveKeys('pw', header.salt, header.kdf);
  final dek = await unwrapDek(header.wrappedDek, keys.kek, header.fileId);
  try {
    final updatedHeader = BitlockHeader(fileId: newId, salt: header.salt,
      wrappedDek: await wrapDek(dek, keys.kek, newId), chunkSize: header.chunkSize,
      plaintextLength: header.plaintextLength, kdf: header.kdf);
    final prefix = updatedHeader.prefixBytes();
    final mac = await computeHeaderMac(keys.headerMacKey, prefix);
    final oldMetaStart = _headerEnd(bytes);
    final oldDataStart = _dataOffset(bytes);
    final metaPlaintext = await decryptAead(bytes.sublist(oldMetaStart, oldDataStart), SecretKey(dek),
        aad: [...ascii.encode('META'), ...header.fileId, ...parsed.mac]);
    final newMeta = await encryptAead(metaPlaintext, SecretKey(dek), secureRandomBytes(12),
        aad: [...ascii.encode('META'), ...newId, ...mac]);
    metaPlaintext.fillRange(0, metaPlaintext.length, 0);
    final output = <int>[...prefix, ...mac, ...newMeta];
    var oldOffset = oldDataStart;
    for (var index = 0; index < header.chunkCount; index++) {
      final plainLength = header.plaintextLength == 0 ? 0 : min(header.chunkSize,
          header.plaintextLength - index * header.chunkSize);
      final recordLength = 12 + plainLength + 16;
      final oldRecord = bytes.sublist(oldOffset, oldOffset + recordLength);
      final plaintext = await decryptAead(oldRecord, SecretKey(dek),
          aad: [...ascii.encode('CHUNK'), ...header.fileId, ...uint32Bytes(index),
            index == header.chunkCount - 1 ? 1 : 0, ...parsed.mac]);
      output.addAll(await encryptAead(plaintext, SecretKey(dek), secureRandomBytes(12),
          aad: [...ascii.encode('CHUNK'), ...newId, ...uint32Bytes(index),
            index == header.chunkCount - 1 ? 1 : 0, ...mac]));
      plaintext.fillRange(0, plaintext.length, 0);
      oldOffset += recordLength;
    }
    return output;
  } finally {
    dek.fillRange(0, dek.length, 0);
  }
}

Future<void> _mustFail(Directory temp, List<int> bytes, String label) async {
  final input = File('${temp.path}/$label.bitlock');
  final output = File('${temp.path}/$label.output');
  await write(input, bytes);
  await expectLater(decryptFile(input.path, output.path, 'pw'), throwsA(isA<BitlockIntegrityException>()), reason: label);
  expect(await read(input), bytes, reason: 'ciphertext must remain intact on $label');
  await _expectNoOutput(output);
}

Future<void> _expectNoOutput(File output) async {
  expect(await output.exists(), isFalse);
  expect(await File('${output.path}.part').exists(), isFalse);
}
