import 'dart:convert';

import 'package:bitlock_core/bitlock_core.dart';
import 'package:test/test.dart';

BitlockHeader sampleHeader() => BitlockHeader(
  fileId: List<int>.generate(16, (i) => i), salt: List<int>.generate(16, (i) => 20 + i),
  wrappedDek: List<int>.generate(60, (i) => i), chunkSize: 1024, plaintextLength: 2049,
  kdf: const KdfParams(memoryKiB: 8, iterations: 1, parallelism: 1),
);

void main() {
  test('header round trip preserves all fields', () {
    final original = sampleHeader();
    final bytes = original.toBytes(List<int>.filled(16, 9));
    final parsed = BitlockHeader.parse(bytes);
    expect(parsed.header.fileId, original.fileId);
    expect(parsed.header.salt, original.salt);
    expect(parsed.header.wrappedDek, original.wrappedDek);
    expect(parsed.header.chunkSize, original.chunkSize);
    expect(parsed.header.plaintextLength, original.plaintextLength);
    expect(parsed.header.kdf.toJson(), original.kdf.toJson());
    expect(parsed.mac, List<int>.filled(16, 9));
  });

  test('parse rejects malformed headers', () {
    final valid = sampleHeader().toBytes(List<int>.filled(16, 0));
    final badMagic = [...valid]..[0] = 0;
    final badVersion = [...valid]..[4] = 2;
    final zeroLength = [...valid]..[5] = 0..[6] = 0..[7] = 0..[8] = 0;
    final tooLarge = [...valid]..[5] = 0..[6] = 0..[7] = 0x40..[8] = 1;
    expect(() => BitlockHeader.parse(badMagic), throwsA(isA<BitlockIntegrityException>()));
    expect(() => BitlockHeader.parse(badVersion), throwsA(isA<BitlockIntegrityException>()));
    expect(() => BitlockHeader.parse(zeroLength), throwsA(isA<BitlockIntegrityException>()));
    expect(() => BitlockHeader.parse(tooLarge), throwsA(isA<BitlockIntegrityException>()));
    expect(() => BitlockHeader.parse([1, 2, 3]), throwsA(isA<BitlockIntegrityException>()));
    expect(() => BitlockHeader.parse(valid.sublist(0, valid.length - 1)), throwsA(isA<BitlockIntegrityException>()));
  });

  test('chunk count follows empty and boundary rules', () {
    expect(chunkCountFor(0, 1024), 1);
    expect(chunkCountFor(1, 1024), 1);
    expect(chunkCountFor(1024, 1024), 1);
    expect(chunkCountFor(1025, 1024), 2);
    expect(chunkCountFor(3072, 1024), 3);
    expect(chunkCountFor(3 * 1024 + 17, 1024), 4);
    expect(() => chunkCountFor(1, 0), throwsArgumentError);
  });

  test('KDF parameters reject attacker-controlled resource extremes', () {
    expect(() => KdfParams.fromJson({'m': 8, 't': 1, 'p': 1, 'extra': 1}), throwsFormatException);
    expect(() => KdfParams.fromJson({'m': KdfLimits.maxMemoryKiB + 1, 't': 1, 'p': 1}), throwsFormatException);
    expect(() => KdfParams.fromJson({'m': 8, 't': KdfLimits.maxIterations + 1, 'p': 1}), throwsFormatException);
  });

  test('encrypted metadata model preserves UTC timestamps', () {
    final timestamp = DateTime.utc(2026, 10, 8, 12, 30);
    final metadata = BitlockMetadata(filename: 'report.pdf', mimeType: 'application/pdf', createdAt: timestamp);
    final decoded = BitlockMetadata.fromJson(metadata.toJson());
    expect(decoded.filename, 'report.pdf');
    expect(decoded.mimeType, 'application/pdf');
    expect(decoded.createdAt, timestamp);
  });

  test('header plaintext excludes original descriptive metadata', () {
    final encoded = utf8.decode(sampleHeader().prefixBytes().sublist(9));
    expect(encoded, isNot(contains('report.pdf')));
    expect(encoded, isNot(contains('application/pdf')));
    expect(encoded, isNot(contains('createdAt')));
  });
}
