import 'package:flutter/material.dart';

import '../../widgets/bitlock_widgets.dart';

/// Basic facts about a file the user picked, before it is encrypted.
///
/// File contents are always treated as opaque bytes: BitLock does
/// not need to parse a file to encrypt it, and the name or MIME label
/// is never trusted as proof of what the bytes are.
class PickedFileInfo {
  /// Creates picked-file information.
  const PickedFileInfo({
    required this.name,
    required this.sizeBytes,
    required this.mimeLabel,
  });

  /// Display name reported by the document picker.
  final String name;

  /// Size in bytes, when the picker could report it.
  final int sizeBytes;

  /// MIME-type label reported by the picker (display only).
  final String mimeLabel;

  /// Human-readable size, e.g. `2.4 MB`.
  String get sizeLabel {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Import flow: pick a file, confirm, encrypt it into the vault.
///
/// Picking is the caller's job: [onPickFile] must open the Android
/// Storage Access Framework document picker and return the chosen
/// file's facts (or null when the user cancels). This screen never
/// requests broad storage permissions.
///
/// [onConfirmImport] performs the real work — read the bytes, encrypt
/// with `bitlock_core`, write ciphertext to app-private storage, then
/// commit the vault metadata — and returns `true` only when all of
/// that succeeded. This screen shows success only on `true`.
class ImportFileScreen extends StatefulWidget {
  /// Creates the import screen.
  const ImportFileScreen({
    required this.onPickFile,
    required this.onConfirmImport,
    super.key,
  });

  /// Opens the system document picker and describes the chosen file.
  final Future<PickedFileInfo?> Function() onPickFile;

  /// Encrypts the picked file into the vault.
  ///
  /// Returns `true` only when the encrypted copy and its metadata
  /// were committed. Any failure returns `false`.
  final Future<bool> Function(PickedFileInfo info) onConfirmImport;

  @override
  State<ImportFileScreen> createState() => _ImportFileScreenState();
}

class _ImportFileScreenState extends State<ImportFileScreen> {
  PickedFileInfo? _picked;
  bool _picking = false;
  bool _importing = false;
  bool _done = false;
  String? _errorText;

  Future<void> _pick() async {
    if (_picking || _importing) {
      return;
    }
    setState(() {
      _picking = true;
      _errorText = null;
      _done = false;
    });
    final PickedFileInfo? info = await widget.onPickFile();
    if (!mounted) {
      return;
    }
    setState(() {
      _picking = false;
      if (info != null) {
        _picked = info;
      }
    });
  }

  Future<void> _import() async {
    final PickedFileInfo? info = _picked;
    if (info == null || _importing) {
      return;
    }
    setState(() {
      _importing = true;
      _errorText = null;
    });
    final bool ok = await widget.onConfirmImport(info);
    if (!mounted) {
      return;
    }
    setState(() {
      _importing = false;
      if (ok) {
        _done = true;
      } else {
        _errorText = 'The file could not be imported. Nothing was added '
            'to the vault — check storage space and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PickedFileInfo? picked = _picked;
    return Scaffold(
      appBar: AppBar(title: const Text('Import file')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Choose a file with the system picker. BitLock encrypts '
            'the bytes locally and stores only ciphertext in the vault.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Supported: PDF, Word, PowerPoint and Excel documents, '
            'text and CSV, images, ZIP and other archives, audio and '
            'video — every file is treated as bytes and encrypted the '
            'same way.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          BitLockPrimaryButton(
            label: picked == null ? 'Choose file' : 'Choose a different file',
            icon: Icons.folder_open_outlined,
            busy: _picking,
            onPressed: _pick,
          ),
          if (picked != null) ...<Widget>[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(picked.name),
                subtitle: Text('${picked.sizeLabel} · ${picked.mimeLabel}'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The original file is not deleted or modified by '
              'importing. Only the encrypted copy inside BitLock is '
              'managed here.',
            ),
          ],
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_done)
            Column(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'File encrypted and added to your vault.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                BitLockPrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            )
          else if (picked != null)
            BitLockPrimaryButton(
              label: 'Encrypt into vault',
              icon: Icons.lock_outline,
              busy: _importing,
              onPressed: _import,
            ),
          if (_importing) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              'Encrypting… large files can take a while. Keep the app '
              'open until this finishes.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
