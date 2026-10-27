import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/audit/audit_log_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/create_vault_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/share/received_files_screen.dart';
import '../features/share/share_management_screen.dart';
import '../features/share/share_models.dart';
import '../features/vault/sample_vault_data.dart';
import '../features/vault/unlock_vault_screen.dart';
import '../features/vault/vault_entry.dart';
import '../features/vault/vault_home_screen.dart';

/// Stages of the root flow.
enum _RootStage {
  /// Splash is showing.
  splash,

  /// First-run onboarding is showing.
  onboarding,

  /// Vault creation is showing.
  createVault,

  /// Unlock is showing.
  unlock,

  /// The unlocked shell is showing.
  shell,
}

/// Root of the BitLock flow: splash → onboarding/create (first run)
/// or unlock (returning) → the tabbed shell.
///
/// This widget owns navigation state only. Creating and unlocking a
/// vault are delegated to [onCreateVault] / [onUnlockVault]; when
/// they are omitted, clearly-marked UI-preview defaults are used
/// (see `main.dart`): they accept any non-empty password so the UI
/// can be walked through, and are NOT a real vault. Real wiring must
/// derive keys with Argon2id via `bitlock_core` and return `false`
/// on any failure.
class BitLockRoot extends StatefulWidget {
  /// Creates the root flow widget.
  const BitLockRoot({
    this.onCreateVault,
    this.onUnlockVault,
    this.hasVault = false,
    this.entries,
    this.shares,
    this.events,
    this.incomingShares = const <ShareGrant>[],
    this.backendConfigured = false,
    super.key,
  });

  /// Creates a vault from a chosen password. Returns `true` on
  /// success. When null, a UI-preview default is used.
  final Future<bool> Function(String password)? onCreateVault;

  /// Attempts to unlock with a password. Returns `true` on success.
  /// When null, a UI-preview default is used.
  final Future<bool> Function(String password)? onUnlockVault;

  /// Whether a vault already exists on this device (returning user).
  final bool hasVault;

  /// Vault entries for the shell. Defaults to sample preview data.
  final List<VaultEntry>? entries;

  /// Share grants for the shell. Defaults to sample preview data.
  final List<ShareGrant>? shares;

  /// Audit events for the shell. Defaults to sample preview data.
  final List<AuditLogEntry>? events;

  /// Grants addressed to this user, for the Received tab.
  final List<ShareGrant> incomingShares;

  /// Whether the sharing backend is configured. Defaults to false so
  /// the preview is honest: share screens surface the
  /// not-configured state until real wiring lands.
  final bool backendConfigured;

  @override
  State<BitLockRoot> createState() => _BitLockRootState();
}

class _BitLockRootState extends State<BitLockRoot> {
  _RootStage _stage = _RootStage.splash;
  bool _hasVault = false;

  @override
  void initState() {
    super.initState();
    _hasVault = widget.hasVault;
  }

  Future<bool> _createVault(String password) async {
    final Future<bool> Function(String)? create = widget.onCreateVault;
    // UI-preview default: accepts any non-empty password. Real wiring
    // replaces this via the constructor — see the class doc.
    final bool ok = create != null
        ? await create(password)
        : password.isNotEmpty;
    if (ok && mounted) {
      setState(() {
        _hasVault = true;
        _stage = _RootStage.shell;
      });
    }
    return ok;
  }

  Future<bool> _unlockVault(String password) async {
    final Future<bool> Function(String)? unlock = widget.onUnlockVault;
    // UI-preview default: accepts any non-empty password. Real wiring
    // replaces this via the constructor — see the class doc.
    final bool ok = unlock != null
        ? await unlock(password)
        : password.isNotEmpty;
    if (ok && mounted) {
      setState(() {
        _stage = _RootStage.shell;
      });
    }
    return ok;
  }

  void _lock() {
    setState(() {
      _stage = _RootStage.unlock;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _RootStage.splash:
        return SplashScreen(
          onDone: () {
            setState(() {
              _stage = _hasVault
                  ? _RootStage.unlock
                  : _RootStage.onboarding;
            });
          },
        );
      case _RootStage.onboarding:
        return OnboardingScreen(
          onGetStarted: () {
            setState(() {
              _stage = _RootStage.createVault;
            });
          },
          onAlreadyHaveVault: () {
            setState(() {
              _hasVault = true;
              _stage = _RootStage.unlock;
            });
          },
        );
      case _RootStage.createVault:
        return CreateVaultScreen(onCreate: _createVault);
      case _RootStage.unlock:
        return UnlockVaultScreen(onUnlock: _unlockVault);
      case _RootStage.shell:
        return BitLockShell(
          entries: widget.entries ?? sampleVaultEntries(),
          shares: widget.shares ?? sampleShareGrants(),
          events: widget.events ?? _sampleEvents(),
          incomingShares: widget.incomingShares,
          backendConfigured: widget.backendConfigured,
          onLock: _lock,
          onOpenEntry: (_) {},
          onAddFile: () {},
          onRevokeShare: (_) async => widget.backendConfigured,
          onCopyShareLink: (_) {},
          onRedeem: (_, __) async => widget.backendConfigured
              ? RedeemResult.invalid
              : RedeemResult.backendUnavailable,
        );
    }
  }

  /// Preview-only audit events for the dashboard and settings links.
  static List<AuditLogEntry> _sampleEvents() => <AuditLogEntry>[
        AuditLogEntry(
          at: DateTime(2026, 10, 26, 9, 30),
          event: 'File viewed',
          detail: 'land-records.pdf',
        ),
        AuditLogEntry(
          at: DateTime(2026, 10, 26, 9, 12),
          event: 'Vault opened',
          detail: '',
        ),
        AuditLogEntry(
          at: DateTime(2026, 10, 25, 18, 3),
          event: 'Share created',
          detail: 'land-records.pdf',
        ),
      ];
}

/// The unlocked app: a [NavigationBar] switching between Dashboard,
/// Vault, Shared, Received, and Settings.
///
/// This shell is deliberately pragmatic: it holds the selected tab
/// and the settings values, and forwards data and callbacks to the
/// feature screens. The Dashboard's navigation callbacks switch tabs
/// here instead of pushing routes.
class BitLockShell extends StatefulWidget {
  /// Creates the tabbed shell.
  const BitLockShell({
    required this.entries,
    required this.shares,
    required this.events,
    required this.onLock,
    required this.onOpenEntry,
    required this.onAddFile,
    required this.onRevokeShare,
    required this.onCopyShareLink,
    required this.onRedeem,
    this.incomingShares = const <ShareGrant>[],
    this.backendConfigured = true,
    this.statusLabel,
    this.initialSettings = const BitLockSettingsData(),
    this.onSettingsChanged,
    super.key,
  });

  /// Vault entries shown on the Dashboard and Vault tabs.
  final List<VaultEntry> entries;

  /// Share grants shown on the Dashboard and Shared tab.
  final List<ShareGrant> shares;

  /// Audit events shown on the Dashboard.
  final List<AuditLogEntry> events;

  /// Called when the user locks the vault from any tab.
  final VoidCallback onLock;

  /// Called when a vault entry is opened.
  final ValueChanged<VaultEntry> onOpenEntry;

  /// Called when the user adds/imports a file.
  final VoidCallback onAddFile;

  /// Revokes a grant server-side; `true` only on server confirmation.
  final Future<bool> Function(ShareGrant grant) onRevokeShare;

  /// Copies the link for a grant.
  final void Function(ShareGrant grant) onCopyShareLink;

  /// Redeems a received share link against the backend.
  final Future<RedeemResult> Function(String link, String? passcode)
      onRedeem;

  /// Grants addressed to this user, for the Received tab.
  final List<ShareGrant> incomingShares;

  /// Whether the sharing backend is configured.
  final bool backendConfigured;

  /// Factual dashboard status line. Defaults to the dashboard's own
  /// default when null.
  final String? statusLabel;

  /// Initial settings values for the Settings tab.
  final BitLockSettingsData initialSettings;

  /// Optional observer notified when settings change.
  final void Function(BitLockSettingsData data)? onSettingsChanged;

  @override
  State<BitLockShell> createState() => _BitLockShellState();
}

class _BitLockShellState extends State<BitLockShell> {
  int _index = 0;
  late BitLockSettingsData _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
    });
  }

  String get _storageLabel {
    final int bytes = widget.entries.fold<int>(
      0,
      (int sum, VaultEntry e) => sum + e.sizeBytes,
    );
    if (bytes < 1024) {
      return '$bytes B used by vault ciphertext';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB used by vault ciphertext';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB used by '
        'vault ciphertext';
  }

  void _copyLink(ShareGrant grant) {
    widget.onCopyShareLink(grant);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      DashboardScreen(
        entries: widget.entries,
        shares: widget.shares,
        recentEvents: widget.events,
        statusLabel: widget.statusLabel ??
            'Vault unlocked · files stored encrypted on this device',
        onImport: widget.onAddFile,
        onOpenVault: () => _goTo(1),
        onOpenShared: () => _goTo(2),
        onOpenReceived: () => _goTo(3),
        onOpenSettings: () => _goTo(4),
        onOpenEntry: widget.onOpenEntry,
      ),
      VaultHomeScreen(
        entries: widget.entries,
        onOpenEntry: widget.onOpenEntry,
        onAddFile: widget.onAddFile,
        onLock: widget.onLock,
      ),
      ShareManagementScreen(
        shares: widget.shares,
        onRevoke: widget.onRevokeShare,
        onCopyLink: (ShareGrant grant) => _copyLink(grant),
        backendConfigured: widget.backendConfigured,
      ),
      ReceivedFilesScreen(
        onRedeem: widget.onRedeem,
        incomingShares: widget.incomingShares,
      ),
      _SettingsTab(
        initial: _settings,
        storageUsedLabel: _storageLabel,
        onChanged: (BitLockSettingsData data) {
          setState(() {
            _settings = data;
          });
          widget.onSettingsChanged?.call(data);
        },
        onLock: widget.onLock,
        shares: widget.shares,
        events: widget.events,
        onRevokeShare: widget.onRevokeShare,
        onCopyShareLink: widget.onCopyShareLink,
        backendConfigured: widget.backendConfigured,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: 'Shared',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Received',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Settings tab: the settings screen plus a lock action, with its
/// "manage shares" and "security activity" rows pushing the real
/// screens.
class _SettingsTab extends StatelessWidget {
  /// Creates the settings tab.
  const _SettingsTab({
    required this.initial,
    required this.storageUsedLabel,
    required this.onChanged,
    required this.onLock,
    required this.shares,
    required this.events,
    required this.onRevokeShare,
    required this.onCopyShareLink,
    required this.backendConfigured,
  });

  /// Initial settings values.
  final BitLockSettingsData initial;

  /// Storage label for the settings screen.
  final String storageUsedLabel;

  /// Called when settings change.
  final void Function(BitLockSettingsData data) onChanged;

  /// Called when the user taps Lock vault.
  final VoidCallback onLock;

  /// Grants for the pushed share-management screen.
  final List<ShareGrant> shares;

  /// Events for the pushed audit-log screen.
  final List<AuditLogEntry> events;

  /// Revoke callback for the pushed share-management screen.
  final Future<bool> Function(ShareGrant grant) onRevokeShare;

  /// Copy-link callback for the pushed share-management screen.
  final void Function(ShareGrant grant) onCopyShareLink;

  /// Whether the sharing backend is configured.
  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SettingsScreen(
          initial: initial,
          onChanged: onChanged,
          storageUsedLabel: storageUsedLabel,
          onClearTempFiles: () async {
            // No decrypted-temp store is wired in the UI preview, so
            // there is honestly nothing to clear yet.
            return 0;
          },
          onOpenAuditLog: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    AuditLogScreen(entries: events),
              ),
            );
          },
          onOpenShareManagement: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => ShareManagementScreen(
                  shares: shares,
                  onRevoke: onRevokeShare,
                  onCopyLink: onCopyShareLink,
                  backendConfigured: backendConfigured,
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'lockVaultFab',
            onPressed: onLock,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Lock'),
          ),
        ),
      ],
    );
  }
}

/// Copies [text] to the clipboard — small helper kept here so share
/// screens in the shell share one implementation.
Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}
