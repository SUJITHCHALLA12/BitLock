@Tags(['slow'])
library;

import 'dart:io';
import 'dart:math';

import 'package:bitlock_core/bitlock_core.dart';
import 'package:test/test.dart';

void main() {
  test('streams a 512 MiB file within a 256 MiB process RSS bound', () async {
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
      expect(ProcessInfo.maxRss, lessThan(256 * 1024 * 1024),
          reason: '512 MiB input should be processed with bounded resident memory');
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
