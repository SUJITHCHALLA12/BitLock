import 'package:cryptography/cryptography.dart';

/// Encrypts bytes with AES-256-GCM and returns nonce, ciphertext, and tag.
Future<List<int>> encryptAead(List<int> plaintext, SecretKey key, List<int> nonce,
    {List<int> aad = const []}) async {
  if (nonce.length != 12) throw ArgumentError.value(nonce.length, 'nonce.length');
  final box = await AesGcm.with256bits().encrypt(plaintext, secretKey: key, nonce: nonce, aad: aad);
  return [...box.nonce, ...box.cipherText, ...box.mac.bytes];
}

/// Authenticates and decrypts an AES-256-GCM record.
Future<List<int>> decryptAead(List<int> record, SecretKey key, {List<int> aad = const []}) async {
  if (record.length < 28) throw const FormatException('Short AES-GCM record');
  return AesGcm.with256bits().decrypt(
    SecretBox(record.sublist(12, record.length - 16),
      nonce: record.sublist(0, 12), mac: Mac(record.sublist(record.length - 16))),
    secretKey: key,
    aad: aad,
  );
}
