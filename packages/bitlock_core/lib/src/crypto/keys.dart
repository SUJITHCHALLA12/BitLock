import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../errors.dart';
import 'kdf.dart';

/// Random per-file material and password-derived wrapping keys.
class FileKeyMaterial {
  /// Creates the key material for one container.
  const FileKeyMaterial({required this.fileId, required this.salt, required this.dek, required this.keys});

  /// Random identifier bound into all authenticated data.
  final List<int> fileId;
  /// Random Argon2id salt.
  final List<int> salt;
  /// Random 32-byte data encryption key.
  final List<int> dek;
  /// KEK and header-MAC key derived from the password.
  final DerivedKeys keys;
}

/// Generates cryptographically random bytes using the platform CSPRNG.
List<int> secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

/// Creates a random file identifier, salt, DEK, and password-derived keys.
Future<FileKeyMaterial> createFileKeyMaterial(String password, KdfParams params) async {
  final id = secureRandomBytes(16);
  final salt = secureRandomBytes(16);
  final dek = secureRandomBytes(32);
  try {
    final keys = await deriveKeys(password, salt, params);
    return FileKeyMaterial(fileId: id, salt: salt, dek: dek, keys: keys);
  } on Object {
    dek.fillRange(0, dek.length, 0);
    rethrow;
  }
}

/// Wraps a DEK using AES-256-GCM and `ASCII("DEK") || fileId` as AAD.
Future<List<int>> wrapDek(List<int> dek, SecretKey kek, List<int> fileId) async {
  if (dek.length != 32 || fileId.length != 16) throw ArgumentError('Invalid DEK or file ID length');
  final nonce = secureRandomBytes(12);
  final box = await AesGcm.with256bits().encrypt(dek, secretKey: kek, nonce: nonce,
      aad: [...'DEK'.codeUnits, ...fileId]);
  return [...nonce, ...box.cipherText, ...box.mac.bytes];
}

/// Authenticates and unwraps a 32-byte DEK.
Future<List<int>> unwrapDek(List<int> wrapped, SecretKey kek, List<int> fileId) async {
  if (wrapped.length != 60 || fileId.length != 16) {
    throw const BitlockIntegrityException('Invalid password or BitLock data');
  }
  try {
    final key = await AesGcm.with256bits().decrypt(
      SecretBox(wrapped.sublist(12, 44), nonce: wrapped.sublist(0, 12), mac: Mac(wrapped.sublist(44))),
      secretKey: kek,
      aad: [...'DEK'.codeUnits, ...fileId],
    );
    if (key.length != 32) throw const FormatException('Invalid DEK');
    return key;
  } on Object {
    throw const BitlockIntegrityException('Invalid password or BitLock data');
  }
}

/// Encodes an unsigned big-endian 32-bit integer.
List<int> uint32Bytes(int value) => (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();
