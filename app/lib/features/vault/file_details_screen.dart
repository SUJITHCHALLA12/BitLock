import 'package:flutter/material.dart';

import '../../widgets/bitlock_widgets.dart';
import 'vault_entry.dart';

/// Details and actions for one vault file.
///
/// Export and delete are gated behind explicit confirmation dialogs:
/// exporting produces a plaintext copy outside BitLock's control, and
/// the dialog says so before [onExport] is ever called.
class FileDetailsScreen extends StatelessWidget {
  /// Creates the file details screen.
  const FileDetailsScreen({
    required this.entry,
    required this.onView,
    required this.onExport,
    required this.onShare,
    required this.onRename,
    required this.onDelete,
    this.activeShares = 0,
    super.key,
  });

  /// The file being shown.
  final VaultEntry entry;

  /// Called when the user chooses controlled viewing.
  final VoidCallback onView;

  /// Called only after the user confirms the export warning.
  final VoidCallback onExport;

  /// Called when the user chooses to create a share.
  final VoidCallback onShare;

  /// Renames the vault entry. Called only with a validated name.
  final Future<void> Function(String newName) onRename;

  /// Called only after the user confirms the destructive dialog.
  final VoidCallback onDelete;

  /// Number of active share grants for this file, as reported by the
  /// backend (display only).
  final int activeShares;

  Future<void> _confirmExport(BuildContext context) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Export an unprotected copy?',
      message: 'The exported file is a decrypted copy. Once it leaves '
          'BitLock it is no longer protected by BitLock — anyone with '
          'access to the destination can read it, unless that '
          'destination protects it separately.',
      confirmLabel: 'Export copy',
    );
    if (confirmed) {
      onExport();
    }
  }

  Future<void> _rename(BuildContext context) async {
    final TextEditingController controller =
        TextEditingController(text: entry.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Rename file'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'File name',
                  errorText: error,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final String value = controller.text.trim();
                    if (value.isEmpty) {
                      setState(() {
                        error = 'Enter a file name';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Rename'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (newName != null && newName != entry.name) {
      await onRename(newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete vault copy?',
      message: 'This deletes the encrypted copy of "${entry.name}" '
          'from this vault. This cannot be undone from inside BitLock.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_iconFor(entry.kind), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Details'),
          _MetaRow(label: 'Name', value: entry.name),
          _MetaRow(label: 'Type', value: _typeLabel(entry)),
          _MetaRow(label: 'Size', value: entry.sizeLabel),
          _MetaRow(label: 'Added', value: _dateTimeLabel(entry.addedAt)),
          _MetaRow(
            label: 'Last accessed',
            value: entry.lastAccessedAt == null
                ? 'Not opened yet'
                : _dateTimeLabel(entry.lastAccessedAt!),
          ),
          _MetaRow(
            label: 'Active shares',
            value: activeShares == 1
                ? '1 active share'
                : '$activeShares active shares',
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Security'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This copy is stored as ciphertext in the app-private '
                'vault, encrypted with a per-file key wrapped by your '
                'vault password (BitLock encrypted container — see '
                'docs/FORMAT.md). Viewing decrypts in memory only. '
                'Exporting creates a separate plaintext copy that '
                'BitLock no longer protects.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          BitLockPrimaryButton(
            label: 'View',
            icon: Icons.visibility_outlined,
            onPressed: onView,
          ),
          const SizedBox(height: 10),
          BitLockPrimaryButton(
            label: 'Create share',
            icon: Icons.share_outlined,
            onPressed: onShare,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _rename(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Rename'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmExport(context),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete vault copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(VaultEntry entry) {
    final String kindLabel;
    switch (entry.kind) {
      case VaultEntryKind.pdf:
        kindLabel = 'PDF document';
      case VaultEntryKind.image:
        kindLabel = 'Image';
      case VaultEntryKind.text:
        kindLabel = 'Text file';
      case VaultEntryKind.other:
        kindLabel = 'File';
    }
    final String? mime = entry.mimeLabel;
    if (mime == null || mime.isEmpty) {
      return kindLabel;
    }
    return '$kindLabel · $mime';
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

  static String _dateTimeLabel(DateTime time) {
    final String day = time.day.toString().padLeft(2, '0');
    final String month = time.month.toString().padLeft(2, '0');
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month/${time.year} $hour:$minute';
  }
}

/// One label/value metadata row.
class _MetaRow extends StatelessWidget {
  /// Creates a metadata row.
  const _MetaRow({required this.label, required this.value});

  /// Row label.
  final String label;

  /// Row value.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
