import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';
import '../../widgets/bitlock_widgets.dart';
import '../audit/audit_log_screen.dart';
import '../share/share_models.dart';
import '../vault/vault_entry.dart';

/// Home dashboard: real counts and recent activity from the vault.
///
/// Every number on this screen is derived from [entries], [shares],
/// and [recentEvents] at build time. Nothing is hardcoded, and no
/// security score or audit result is shown — the status card states
/// only the factual [statusLabel].
class DashboardScreen extends StatelessWidget {
  /// Creates the dashboard.
  const DashboardScreen({
    required this.entries,
    required this.shares,
    required this.recentEvents,
    required this.onImport,
    required this.onOpenVault,
    required this.onOpenShared,
    required this.onOpenReceived,
    required this.onOpenSettings,
    required this.onOpenEntry,
    this.statusLabel = 'Vault unlocked · files stored encrypted on this device',
    super.key,
  });

  /// Files currently in the vault.
  final List<VaultEntry> entries;

  /// Share grants known to this device (server-confirmed state).
  final List<ShareGrant> shares;

  /// Recent security activity, newest first.
  final List<AuditLogEntry> recentEvents;

  /// Called when the user taps Import File.
  final VoidCallback onImport;

  /// Called when the user taps My Vault.
  final VoidCallback onOpenVault;

  /// Called when the user taps Shared.
  final VoidCallback onOpenShared;

  /// Called when the user taps Received.
  final VoidCallback onOpenReceived;

  /// Called when the user taps the settings action.
  final VoidCallback onOpenSettings;

  /// Called when the user taps a recent file.
  final ValueChanged<VaultEntry> onOpenEntry;

  /// Factual encryption-status line shown under the header.
  final String statusLabel;

  int get _activeShares =>
      shares.where((ShareGrant s) => s.status == ShareStatus.active).length;

  int get _totalBytes =>
      entries.fold<int>(0, (int sum, VaultEntry e) => sum + e.sizeBytes);

  @override
  Widget build(BuildContext context) {
    final List<VaultEntry> recentFiles = entries.take(5).toList();
    final List<AuditLogEntry> events = recentEvents.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('BitLock'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.shield_outlined,
                    color: BitLockColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(statusLabel)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: StatCard(
                  icon: Icons.folder_outlined,
                  value: '${entries.length}',
                  label: 'Protected files',
                  onTap: onOpenVault,
                ),
              ),
              Expanded(
                child: StatCard(
                  icon: Icons.link_outlined,
                  value: '$_activeShares',
                  label: 'Active shares',
                  onTap: onOpenShared,
                ),
              ),
              Expanded(
                child: StatCard(
                  icon: Icons.storage_outlined,
                  value: _sizeLabel(_totalBytes),
                  label: 'Storage used',
                  onTap: onOpenVault,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _QuickAction(
                icon: Icons.file_upload_outlined,
                label: 'Import File',
                onTap: onImport,
              ),
              _QuickAction(
                icon: Icons.folder_open_outlined,
                label: 'My Vault',
                onTap: onOpenVault,
              ),
              _QuickAction(
                icon: Icons.share_outlined,
                label: 'Shared',
                onTap: onOpenShared,
              ),
              _QuickAction(
                icon: Icons.download_outlined,
                label: 'Received',
                onTap: onOpenReceived,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Recent files'),
          const SizedBox(height: 4),
          if (recentFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No files in the vault yet.'),
            )
          else
            for (final VaultEntry entry in recentFiles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconFor(entry.kind)),
                title: Text(entry.name),
                subtitle: Text(
                  '${entry.sizeLabel} · ${_dateLabel(entry.addedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenEntry(entry),
              ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Recent security activity'),
          const SizedBox(height: 4),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No security activity recorded yet.'),
            )
          else
            for (final AuditLogEntry event in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(event.event),
                subtitle: Text(event.detail),
                trailing: Text(_timeLabel(event.at)),
              ),
        ],
      ),
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData _iconFor(VaultEntryKind kind) {
    switch (kind) {
      case VaultEntryKind.pdf:
        return Icons.picture_as_pdf_outlined;
      case VaultEntryKind.image:
        return Icons.image_outlined;
      case VaultEntryKind.text:
        return Icons.description_outlined;
      case VaultEntryKind.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _dateLabel(DateTime time) {
    final String day = time.day.toString().padLeft(2, '0');
    final String month = time.month.toString().padLeft(2, '0');
    return '$day/$month/${time.year}';
  }

  static String _timeLabel(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// One quick-action chip on the dashboard.
class _QuickAction extends StatelessWidget {
  /// Creates a quick action.
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  /// Icon for the action.
  final IconData icon;

  /// Label for the action.
  final String label;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
