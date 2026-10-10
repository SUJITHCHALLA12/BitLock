import 'dart:convert';
import 'dart:io';

import 'package:bitlock_core/bitlock_core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

List<int> _hex(String value) => [for (var i = 0; i < value.length; i += 2) int.parse(value.substring(i, i + 2), radix: 16)];
bool _sameBytes(List<int> left, List<int> right) => constantTimeMacEquals(left, right);

void main() {
  test('Argon2id and HKDF derive two distinct 32-byte keys', () async {
    final derived = await deriveKeys('fast test password', List<int>.filled(16, 4),
        const KdfParams(memoryKiB: 8, iterations: 1, parallelism: 1));
    final kek = (await derived.kek.extractBytes()).toList();
    final headerKey = (await derived.headerMacKey.extractBytes()).toList();
    expect(kek.length, 32);
    expect(headerKey.length, 32);
    expect(_sameBytes(kek, headerKey), isFalse);
    kek.fillRange(0, kek.length, 0);
    headerKey.fillRange(0, headerKey.length, 0);
  });

  test('HKDF-SHA256 matches RFC 5869 test case 1', () async {
    final vector = jsonDecode(await File('test/vectors/hkdf_sha256_rfc5869_case1.json').readAsString()) as Map<String, dynamic>;
    final output = await Hkdf(hmac: Hmac.sha256(), outputLength: vector['length'] as int).deriveKey(
      secretKey: SecretKey(_hex(vector['ikm'] as String)),
      nonce: _hex(vector['salt'] as String),
      info: _hex(vector['info'] as String),
    );
    expect(_sameBytes(await output.extractBytes(), _hex(vector['okm'] as String)), isTrue);
  });

  test('version 1 header MAC vector is stable', () async {
    final vector = jsonDecode(await File('test/vectors/header_mac_v1.json').readAsString()) as Map<String, dynamic>;
    expect(_sameBytes(await computeHeaderMac(SecretKey(_hex(vector['key'] as String)),
        _hex(vector['prefix'] as String)), _hex(vector['mac16'] as String)), isTrue);
  });

  test('DEK wrapping authenticates the key and file identifier', () async {
    final params = const KdfParams(memoryKiB: 8, iterations: 1, parallelism: 1);
    final derived = await deriveKeys('vector password', List<int>.filled(16, 2), params);
    final dek = List<int>.generate(32, (i) => i);
    final id = List<int>.filled(16, 5);
    final wrapped = await wrapDek(dek, derived.kek, id);
    expect(_sameBytes(await unwrapDek(wrapped, derived.kek, id), dek), isTrue);
    await expectLater(unwrapDek(wrapped, derived.kek, List<int>.filled(16, 6)),
        throwsA(isA<BitlockIntegrityException>()));
    wrapped[20] ^= 1;
    await expectLater(unwrapDek(wrapped, derived.kek, id), throwsA(isA<BitlockIntegrityException>()));
  });

  test('AES-GCM record authentication rejects changes', () async {
    final key = SecretKey(List<int>.filled(32, 3));
    final record = await encryptAead([1, 2, 3], key, List<int>.filled(12, 4), aad: [5]);
    expect(await decryptAead(record, key, aad: [5]), [1, 2, 3]);
    record[12] ^= 1;
    await expectLater(decryptAead(record, key, aad: [5]), throwsA(anything));
  });
}
