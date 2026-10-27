import 'package:flutter/material.dart';

import '../../widgets/bitlock_widgets.dart';

/// Persisted security and preference values edited by [SettingsScreen].
///
/// Holds no secrets: no passwords, keys, or tokens ever belong in
/// settings storage.
class BitLockSettingsData {
  /// Creates settings data.
  const BitLockSettingsData({
    this.autoLockMinutes = 5,
    this.biometricUnlock = false,
    this.notificationsEnabled = true,
    this.darkTheme = true,
  });

  /// Minutes of inactivity before the vault locks itself.
  ///
  /// Zero means lock immediately when the app leaves the foreground.
  final int autoLockMinutes;

  /// Whether biometric unlock is offered (key release still goes
  /// through the device-protected key store).
  final bool biometricUnlock;

  /// Whether non-sensitive notifications are enabled.
  final bool notificationsEnabled;

  /// Whether the dark theme is used.
  final bool darkTheme;

  /// Returns a copy with the given fields replaced.
  BitLockSettingsData copyWith({
    int? autoLockMinutes,
    bool? biometricUnlock,
    bool? notificationsEnabled,
    bool? darkTheme,
  }) {
    return BitLockSettingsData(
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// Settings: app lock, biometric unlock, theme, notifications,
/// storage, temporary-file cleanup, and links into share management
/// and the security activity log.
///
/// Every control updates local state and reports the new value
/// through [onChanged]; the caller persists it. Nothing on this
/// screen displays keys, passwords, or tokens.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    required this.initial,
    required this.onChanged,
    required this.storageUsedLabel,
    required this.onClearTempFiles,
    required this.onOpenAuditLog,
    required this.onOpenShareManagement,
    this.appVersion = '0.1.0',
    super.key,
  });

  /// Settings values to start from.
  final BitLockSettingsData initial;

  /// Called with the full updated settings after every change.
  final void Function(BitLockSettingsData data) onChanged;

  /// Factual storage-usage label computed by the caller.
  final String storageUsedLabel;

  /// Deletes eligible temporary files and returns how many were
  /// cleared.
  final Future<int> Function() onClearTempFiles;

  /// Opens the security activity (audit log) screen.
  final VoidCallback onOpenAuditLog;

  /// Opens share-link management.
  final VoidCallback onOpenShareManagement;

  /// App version shown in the About section.
  final String appVersion;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BitLockSettingsData _data;
  bool _clearing = false;

  static const List<int> _autoLockOptions = <int>[0, 1, 5, 15, 30];

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
  }

  void _update(BitLockSettingsData next) {
    setState(() {
      _data = next;
    });
    widget.onChanged(next);
  }

  static String _autoLockLabel(int minutes) {
    if (minutes == 0) {
      return 'Immediately';
    }
    if (minutes == 1) {
      return '1 minute';
    }
    return '$minutes minutes';
  }

  Future<void> _clearTempFiles() async {
    if (_clearing) {
      return;
    }
    setState(() {
      _clearing = true;
    });
    final int cleared = await widget.onClearTempFiles();
    if (!mounted) {
      return;
    }
    setState(() {
      _clearing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared $cleared temporary files')),
    );
  }

  Future<void> _showPrivacy() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Privacy & security'),
          content: const SingleChildScrollView(
            child: Text(
              'How BitLock handles your files:\n\n'
              '• Files are encrypted on this device with per-file '
              'keys wrapped by a key derived from your vault '
              'password.\n\n'
              '• The sharing backend stores ciphertext only — it '
              'never receives your password or plaintext file keys, '
              'and share tokens are stored as hashes.\n\n'
              '• View-only sharing means BitLock provides no download '
              'action and controlled viewing blocks supported capture '
              'paths (FLAG_SECURE). It cannot stop an external camera '
              'or a compromised device.\n\n'
              '• Revoking or expiring a link stops future access '
              'through BitLock. It cannot take back a plaintext copy '
              'a recipient already exported.\n\n'
              '• Diagnostic exports never include passwords, keys, '
              'tokens, or file contents.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: <Widget>[
          const SectionHeader(title: 'Security'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock after'),
            trailing: DropdownButton<int>(
              value: _data.autoLockMinutes,
              items: <DropdownMenuItem<int>>[
                for (final int minutes in _autoLockOptions)
                  DropdownMenuItem<int>(
                    value: minutes,
                    child: Text(_autoLockLabel(minutes)),
                  ),
              ],
              onChanged: (int? value) {
                if (value != null) {
                  _update(_data.copyWith(autoLockMinutes: value));
                }
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric unlock'),
            subtitle: const Text(
              'Offer device biometrics to release the vault key.',
            ),
            value: _data.biometricUnlock,
            onChanged: (bool value) {
              _update(_data.copyWith(biometricUnlock: value));
            },
          ),
          const Divider(),
          const SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text(
              'Status notifications. File names and contents are '
              'never shown in notifications.',
            ),
            value: _data.notificationsEnabled,
            onChanged: (bool value) {
              _update(_data.copyWith(notificationsEnabled: value));
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark theme'),
            value: _data.darkTheme,
            onChanged: (bool value) {
              _update(_data.copyWith(darkTheme: value));
            },
          ),
          const Divider(),
          const SectionHeader(title: 'Storage'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Storage used'),
            subtitle: Text(widget.storageUsedLabel),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear temporary files'),
            subtitle: const Text(
              'Removes decrypted temporary files left by viewing. '
              'Vault ciphertext is not touched.',
            ),
            trailing: _clearing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _clearing ? null : _clearTempFiles,
          ),
          const Divider(),
          const SectionHeader(title: 'Sharing & activity'),
          ListTile(
            leading: const Icon(Icons.link_outlined),
            title: const Text('Manage share links'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenShareManagement,
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Security activity'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenAuditLog,
          ),
          const Divider(),
          const SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(widget.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy & security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacy,
          ),
        ],
      ),
    );
  }
}
