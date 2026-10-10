import 'package:bitlock_core/bitlock_core.dart';

/// Measures one default Argon2id and HKDF derivation without printing secrets.
Future<void> main() async {
  final stopwatch = Stopwatch()..start();
  await deriveKeys('benchmark-only-password', List<int>.filled(16, 7), const KdfParams());
  stopwatch.stop();
  // ignore: avoid_print
  print('Default KDF elapsed: ${stopwatch.elapsed}; ${stopwatch.elapsedMilliseconds} ms per derivation.');
}
