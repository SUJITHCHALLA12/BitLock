import 'dart:convert';
import 'dart:typed_data';

import '../crypto/kdf.dart';
import '../errors.dart';

/// Container constants and binary header encoding helpers.
abstract final class BitlockFormat {
  /// Four byte container signature.
  static const magic = [0x42, 0x4c, 0x4b, 0x31];
  /// Current container version.
  static const version = 1;
  /// AES-GCM nonce size.
  static const nonceLength = 12;
  /// Authentication tag size.
  static const tagLength = 16;
  /// Default plaintext chunk size.
  static const defaultChunkSize = 64 * 1024;
  /// Largest accepted chunk size, bounding memory use for parsed containers.
  static const maxChunkSize = 16 * 1024 * 1024;
  /// Maximum encoded JSON header size.
  static const maxHeaderJsonLength = 16 * 1024;
  /// File identifier size.
  static const fileIdLength = 16;
  /// Argon2id salt size.
  static const saltLength = 16;
  /// Encrypted metadata record overhead (nonce and tag).
  static const metadataRecordOverhead = nonceLength + tagLength;
}

/// Descriptive file metadata encrypted in a META record.
class BitlockMetadata {
  /// Creates metadata kept encrypted inside the container.
  const BitlockMetadata({required this.filename, required this.mimeType, required this.createdAt});

  /// Original leaf filename, never stored in the plaintext header.
  final String filename;
  /// MIME type, never stored in the plaintext header.
  final String mimeType;
  /// Creation timestamp in UTC.
  final DateTime createdAt;

  /// Serializes metadata for encryption.
  Map<String, Object> toJson() => {
    'filename': filename,
    'mimeType': mimeType,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// Parses metadata JSON after its AEAD tag has been verified.
  factory BitlockMetadata.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value.length != 3 ||
        value['filename'] is! String || value['mimeType'] is! String || value['createdAt'] is! String) {
      throw const FormatException('Invalid encrypted metadata');
    }
    return BitlockMetadata(filename: value['filename'] as String, mimeType: value['mimeType'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String).toUtc());
  }
}

/// Authenticated metadata stored between the fixed prefix and header MAC.
class BitlockHeader {
  /// Creates container metadata.
  const BitlockHeader({required this.fileId, required this.salt, required this.wrappedDek,
    required this.chunkSize, required this.plaintextLength, required this.kdf});

  /// Random file identifier.
  final List<int> fileId;
  /// Random Argon2id salt.
  final List<int> salt;
  /// Wrapped DEK: nonce, ciphertext, then tag.
  final List<int> wrappedDek;
  /// Plaintext size of each full chunk.
  final int chunkSize;
  /// Original file size.
  final int plaintextLength;
  /// Password derivation settings.
  final KdfParams kdf;

  /// Number of encrypted chunks, including the empty chunk for an empty file.
  int get chunkCount => plaintextLength == 0 ? 1 : (plaintextLength + chunkSize - 1) ~/ chunkSize;

  /// Encodes the authenticated metadata using the specified short JSON keys.
  Map<String, Object> toJson() => {
    'id': base64Encode(fileId), 's': base64Encode(salt), 'w': base64Encode(wrappedDek),
    'cs': chunkSize, 'pl': plaintextLength, 'kdf': kdf.toJson(),
  };

  /// Encodes magic, version, JSON length, and JSON bytes (without the MAC).
  List<int> prefixBytes() {
    final jsonBytes = utf8.encode(jsonEncode(toJson()));
    if (jsonBytes.length > BitlockFormat.maxHeaderJsonLength) throw const FormatException('Header too large');
    final out = BytesBuilder(copy: false)..add(BitlockFormat.magic)..add([BitlockFormat.version]);
    final len = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
    out.add(len.buffer.asUint8List());
    out.add(jsonBytes);
    return out.takeBytes();
  }

  /// Encodes the full header, including its 16 byte MAC.
  List<int> toBytes(List<int> headerMac) {
    if (headerMac.length != BitlockFormat.tagLength) throw const FormatException('Invalid header MAC length');
    return [...prefixBytes(), ...headerMac];
  }

  /// Parses a complete header prefix and MAC from a byte buffer.
  static ParsedHeader parse(List<int> bytes) {
    try {
      if (bytes.length < 9 + BitlockFormat.tagLength) throw const FormatException('Short header');
      for (var i = 0; i < 4; i++) { if (bytes[i] != BitlockFormat.magic[i]) throw const FormatException('Bad magic'); }
      if (bytes[4] != BitlockFormat.version) throw const FormatException('Bad version');
      final jsonLength = ByteData.sublistView(Uint8List.fromList(bytes), 5, 9).getUint32(0, Endian.big);
      if (jsonLength == 0 || jsonLength > BitlockFormat.maxHeaderJsonLength) throw const FormatException('Bad header length');
      final total = 9 + jsonLength + BitlockFormat.tagLength;
      if (bytes.length != total) throw const FormatException('Truncated header');
      final map = jsonDecode(utf8.decode(bytes.sublist(9, 9 + jsonLength)));
      if (map is! Map<String, dynamic> || map.length != 6 ||
          !map.keys.toSet().containsAll({'id', 's', 'w', 'cs', 'pl', 'kdf'})) {
        throw const FormatException('Invalid header');
      }
      final id = base64Decode(map['id'] as String);
      final salt = base64Decode(map['s'] as String);
      final wrapped = base64Decode(map['w'] as String);
      final cs = map['cs'];
      final pl = map['pl'];
      if (id.length != BitlockFormat.fileIdLength || salt.length != BitlockFormat.saltLength ||
          wrapped.length != 60 || cs is! int || cs < 1 || cs > BitlockFormat.maxChunkSize ||
          pl is! int || pl < 0) {
        throw const FormatException('Invalid header fields');
      }
      final header = BitlockHeader(fileId: id, salt: salt, wrappedDek: wrapped, chunkSize: cs,
        plaintextLength: pl, kdf: KdfParams.fromJson(map['kdf']));
      return ParsedHeader(header, bytes.sublist(0, 9 + jsonLength), bytes.sublist(9 + jsonLength), total);
    } on BitlockIntegrityException { rethrow; }
    on Object { throw const BitlockIntegrityException('Invalid or unauthenticated BitLock data'); }
  }
}

/// Parsed header with the bytes required for authentication and the file offset.
class ParsedHeader {
  /// Creates parsed header data.
  const ParsedHeader(this.header, this.prefix, this.mac, this.length);
  /// Decoded metadata.
  final BitlockHeader header;
  /// Exact bytes covered by the header MAC.
  final List<int> prefix;
  /// Stored truncated header MAC.
  final List<int> mac;
  /// Header length in bytes.
  final int length;
}

/// Computes the encrypted chunk count for a plaintext size and chunk size.
int chunkCountFor(int plaintextLength, int chunkSize) {
  if (plaintextLength < 0 || chunkSize < 1) throw ArgumentError('Invalid file or chunk size');
  return plaintextLength == 0 ? 1 : (plaintextLength + chunkSize - 1) ~/ chunkSize;
}
