import 'package:flutter/material.dart';

import '../../widgets/bitlock_widgets.dart';

/// First-time setup: choose the vault password.
///
/// The password itself is handed to [onCreate], which is responsible
/// for deriving keys from it (Argon2id via `bitlock_core`) — this
/// screen never stores the password and there is no default or
/// fallback password. The strength label is a rough guide based on
/// length and variety only; it is labelled as such in the UI.
class CreateVaultScreen extends StatefulWidget {
  /// Creates the vault-creation screen.
  const CreateVaultScreen({required this.onCreate, super.key});

  /// Attempts to create the vault with the chosen password.
  ///
  /// Returns `true` when the vault was created. Any failure returns
  /// `false` and the screen shows a single generic failure message.
  final Future<bool> Function(String password) onCreate;

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _understandsRisk = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _password => _passwordController.text;

  String get _confirm => _confirmController.text;

  bool get _mismatch => _confirm.isNotEmpty && _confirm != _password;

  bool get _isValid =>
      _password.length >= 8 && !_mismatch && _confirm == _password && _understandsRisk;

  /// Rough, length-and-variety-only strength label.
  String get _strengthLabel {
    final String password = _password;
    if (password.isEmpty) {
      return '';
    }
    int variety = 0;
    if (password.contains(RegExp('[a-z]'))) {
      variety++;
    }
    if (password.contains(RegExp('[A-Z]'))) {
      variety++;
    }
    if (password.contains(RegExp('[0-9]'))) {
      variety++;
    }
    if (password.contains(RegExp('[^a-zA-Z0-9]'))) {
      variety++;
    }
    final int score = password.length + variety * 4;
    if (password.length < 8 || score < 16) {
      return 'Weak';
    }
    if (score < 26) {
      return 'Fair';
    }
    if (score < 36) {
      return 'Good';
    }
    return 'Strong';
  }

  Future<void> _create() async {
    if (!_isValid || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool created = await widget.onCreate(_password);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _failed = !created;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your vault')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.shield_outlined, size: 44),
            const SizedBox(height: 16),
            const Text(
              'Choose a vault password',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'This password protects the keys that encrypt your files. '
              'BitLock cannot reset it for you.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Vault password',
                helperText: _password.isEmpty
                    ? 'At least 8 characters'
                    : 'Strength (rough guide): $_strengthLabel',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                errorText: _mismatch ? 'Passwords do not match' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _showConfirm ? 'Hide password' : 'Show password',
                  onPressed: () {
                    setState(() {
                      _showConfirm = !_showConfirm;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _understandsRisk,
              onChanged: (bool? value) {
                setState(() {
                  _understandsRisk = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand a forgotten password cannot be recovered',
              ),
            ),
            if (_failed) ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'The vault could not be created. Please try again.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 16),
            BitLockPrimaryButton(
              label: 'Create vault',
              busy: _busy,
              onPressed: _isValid ? _create : null,
            ),
          ],
        ),
      ),
    );
  }
}
