@Tags(['slow'])
library;

import 'dart:io';
import 'dart:math';

import 'package:bitlock_core/bitlock_core.dart';
import 'package:test/test.dart';

void main() {
  test('streams a 512 MiB file with bounded additional resident memory', () async {
    // ProcessInfo.maxRss is a lifetime peak that includes the Dart VM and
    // test-runner baseline, which varies by runner image and SDK: on the
    // ubuntu-26.04 runner with Dart 3.13 the baseline alone already
    // exceeded the old absolute 256 MiB bound, while the code was unchanged
    // since it passed on 2026-10-27. What this test proves is that the
    // streaming work itself adds only bounded memory, so measure the growth
    // above the baseline taken at the start of the test instead of an
    // absolute value. The 192 MiB bound covers two retained 64 MiB Argon2id
    // blocks (one per encrypt/decrypt KDF) plus JIT and buffer growth, and
    // is still far below the 512 MiB file, so loading the whole file into
    // memory would still fail.
    final baselineRss = ProcessInfo.maxRss;
    final temp = await Directory.systemTemp.createTemp('bitlock-large-');
    try {
      final input = File('${temp.path}/large.bin');
      final encrypted = File('${temp.path}/large.bitlock');
      final output = File('${temp.path}/large.out');
      final random = Random.secure();
      final chunk = List<int>.generate(64 * 1024, (_) => random.nextInt(256));
      final writer = await input.open(mode: FileMode.writeOnly);
      try {
        for (var i = 0; i < 512 * 16; i++) {
          await writer.writeFrom(chunk);
        }
      } finally {
        await writer.close();
      }
      await encryptFile(input.path, encrypted.path, 'nightly-test-password');
      await decryptFile(encrypted.path, output.path, 'nightly-test-password');
      expect(await output.length(), 512 * 1024 * 1024);
      expect(ProcessInfo.maxRss - baselineRss, lessThan(192 * 1024 * 1024),
          reason: '512 MiB input should be processed with bounded additional resident memory');
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
