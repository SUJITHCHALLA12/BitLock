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
        home: const Scaffold(body: Center(child: Text('BitLock foundation'))),
      );
}
