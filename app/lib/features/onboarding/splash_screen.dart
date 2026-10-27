import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';

/// Splash screen: BitLock identity while the app decides where to go.
///
/// Calls [onDone] once after a short delay so the root can route to
/// onboarding, vault creation, or unlock. The timer is cancelled if
/// the screen leaves the tree first.
class SplashScreen extends StatefulWidget {
  /// Creates the splash screen.
  const SplashScreen({required this.onDone, super.key});

  /// Called once, shortly after the splash is shown.
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: BitLockColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BitLock',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zero-trust file protection',
              style: TextStyle(color: BitLockColors.textSecondary),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
