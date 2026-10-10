import 'package:bitlock_core/bitlock_core.dart';
import 'package:flutter/material.dart';

/// Starts the foundation app shell.
void main() {
  runApp(const BitLockApp());
}

/// Root widget for the BitLock Android application.
class BitLockApp extends StatelessWidget {
  /// Creates the application shell.
  const BitLockApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BitLock',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff234f76))),
        home: const BenchmarkScreen(),
      );
}

/// TEMPORARY Phase 1 screen: runs the KDF benchmark on this device.
/// Remove once the reference-device measurement is recorded in docs/DECISIONS.md.
class BenchmarkScreen extends StatefulWidget {
  /// Creates the temporary benchmark screen.
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  String _output =
      'Tap the button to run the KDF benchmark.\nIt derives a key 3 times with the default\nArgon2id settings and reports the time.';
  bool _running = false;

  Future<void> _runBenchmark() async {
    setState(() {
      _running = true;
      _output = 'Running... (takes a few seconds)';
    });
    final results = <int>[];
    for (var i = 0; i < 3; i++) {
      final stopwatch = Stopwatch()..start();
      await deriveKeys(
          'benchmark-only-password', List<int>.filled(16, 7), const KdfParams());
      stopwatch.stop();
      results.add(stopwatch.elapsedMilliseconds);
    }
    final average = results.reduce((a, b) => a + b) ~/ results.length;
    setState(() {
      _running = false;
      _output = 'Default KDF (Argon2id 64 MiB / t=3 / p=2):\n'
          'Run 1: ${results[0]} ms\n'
          'Run 2: ${results[1]} ms\n'
          'Run 3: ${results[2]} ms\n'
          'Average: $average ms\n\n'
          'Target: 500-1000 ms.\nSend these numbers to record the benchmark.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('BitLock')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('BitLock foundation'),
                const SizedBox(height: 16),
                Text(_output, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _running ? null : _runBenchmark,
                  child: const Text('Run KDF benchmark'),
                ),
              ],
            ),
          ),
        ),
      );
}
