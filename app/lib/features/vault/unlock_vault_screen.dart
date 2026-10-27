import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';

/// Unlock screen: asks for the vault password and hands it to [onUnlock].
///
/// The real [onUnlock] derives keys with Argon2id via `bitlock_core`
/// and opens the vault container. Any failure — wrong password,
/// tampered header, truncated file — surfaces here as the single
/// generic message below. Never show the underlying error: the core
/// throws `BitlockIntegrityException` with a generic message on
/// purpose, and this screen keeps it that way.
///
/// Biometric unlock is optional and separate: when
/// [onBiometricUnlock] is provided, a successful biometric check is
/// reported through [onAuthenticated]. The biometric prompt by itself
/// is not encryption — the wiring behind it must release the vault
/// key through the device-protected key store.
class UnlockVaultScreen extends StatefulWidget {
  /// Creates the unlock screen.
  const UnlockVaultScreen({
    required this.onUnlock,
    this.onBiometricUnlock,
    this.onAuthenticated,
    this.maxAttempts,
    super.key,
  });

  /// Attempts to open the vault with the entered password.
  ///
  /// Returns `true` when the vault opened. Any failure returns `false`;
  /// the screen does not learn (or reveal) why.
  final Future<bool> Function(String password) onUnlock;

  /// Optional biometric unlock attempt.
  ///
  /// Returns `true` when the device authenticated the user. When null,
  /// no biometric button is shown.
  final Future<bool> Function()? onBiometricUnlock;

  /// Called after any successful authentication (password or
  /// biometric), in addition to [onUnlock] returning `true`.
  final VoidCallback? onAuthenticated;

  /// Optional hint for the expected attempt budget, shown after
  /// failures (for example `3 failed attempts of 5`).
  final int? maxAttempts;

  @override
  State<UnlockVaultScreen> createState() => _UnlockVaultScreenState();
}

class _UnlockVaultScreenState extends State<UnlockVaultScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  int _failedAttempts = 0;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptUnlock() async {
    final String password = _passwordController.text;
    if (password.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final bool opened = await widget.onUnlock(password);
    _passwordController.clear();
    if (!mounted) {
      return;
    }
    if (opened) {
      widget.onAuthenticated?.call();
    }
    setState(() {
      _busy = false;
      if (!opened) {
        _failedAttempts += 1;
        _errorText = "Couldn't open the vault. Check your password and try again.";
      }
    });
  }

  Future<void> _attemptBiometric() async {
    final Future<bool> Function()? biometric = widget.onBiometricUnlock;
    if (biometric == null || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final bool ok = await biometric();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
    });
    if (ok) {
      widget.onAuthenticated?.call();
    }
  }

  String get _attemptsLabel {
    final String base = _failedAttempts == 1
        ? '1 failed attempt'
        : '$_failedAttempts failed attempts';
    final int? max = widget.maxAttempts;
    if (max != null) {
      return '$base of $max';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BitLock')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: BitLockColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 44,
                  color: BitLockColors.primaryLight,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Open your vault',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _attemptUnlock(),
                decoration: InputDecoration(
                  labelText: 'Vault password',
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip:
                        _showPassword ? 'Hide password' : 'Show password',
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),
              if (_failedAttempts > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _attemptsLabel,
                  style: const TextStyle(color: BitLockColors.warning),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _attemptUnlock,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock'),
                ),
              ),
              if (widget.onBiometricUnlock != null) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _attemptBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use biometrics'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Unlocking can take a few seconds — that delay is the '
                'password protection doing its work.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
