import 'package:bitlock_core/bitlock_core.dart';
import 'package:test/test.dart';

void main() {
  test('default Argon2id parameters complete', () async {
    final watch = Stopwatch()..start();
    await deriveKeys('test password', List<int>.filled(16, 1), const KdfParams());
    watch.stop();
    // ignore: avoid_print
    print('Default KDF elapsed: ${watch.elapsed}');
  }, skip: 'Slow default 64 MiB KDF check; run explicitly when desired.');
}
