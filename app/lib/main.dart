import 'package:flutter/material.dart';

import 'app/bitlock_shell.dart';
import 'theme/bitlock_theme.dart';

/// Starts the BitLock app.
///
/// UI-PREVIEW WIRING — read before shipping:
/// [BitLockApp] currently mounts [BitLockRoot] with no create/unlock
/// callbacks, so the root uses its UI-preview defaults, which accept
/// any non-empty password purely so the screens can be walked
/// through, and the shell is fed by `sampleVaultEntries()` /
/// `sampleShareGrants()`. That is NOT a real vault: no keys are
/// derived and nothing is encrypted by this wiring.
///
/// Production wiring must:
/// - pass `onCreateVault` / `onUnlockVault` that derive keys with
///   Argon2id via `bitlock_core` and return `false` on any failure,
/// - feed the shell from the real vault metadata store,
/// - set `backendConfigured` only once the sharing backend is live.
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
        theme: BitLockTheme.dark(),
        darkTheme: BitLockTheme.dark(),
        home: const BitLockRoot(),
      );
}
