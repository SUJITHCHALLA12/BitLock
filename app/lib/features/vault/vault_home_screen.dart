import 'package:flutter/material.dart';

import '../../widgets/bitlock_widgets.dart';
import 'vault_entry.dart';

/// Sort orders offered by the vault list.
enum _VaultSort {
  /// By display name, A to Z.
  nameAsc,

  /// Newest added first.
  newest,

  /// Oldest added first.
  oldest,

  /// Largest stored size first.
  largest,
}

/// Type filters offered by the vault list.
enum _VaultFilter {
  /// Every entry.
  all,

  /// PDF documents only.
  pdf,

  /// Images only.
  images,

  /// Text files only.
  text,

  /// Everything that is not PDF, image, or text.
  other,
}

/// Vault home: the list of files in the opened vault, with in-widget
/// search, sorting, and type filters over the entries it is given.
///
/// Wiring still to do:
/// - entries come from the vault metadata store (`data/local/`),
/// - [onAddFile] runs the add-file flow (pick a file, encrypt it with
///   `bitlock_core`, store ciphertext, append metadata),
/// - [onOpenEntry] decrypts in memory and routes to the matching viewer,
/// - [onLock] wipes keys from memory and returns to the unlock screen.
///
/// Search, sort, and filter are presentation state only, held inside
/// this widget; the source list is always [entries].
class VaultHomeScreen extends StatefulWidget {
  /// Creates the vault home screen.
  const VaultHomeScreen({
    required this.entries,
    required this.onOpenEntry,
    required this.onAddFile,
    required this.onLock,
    super.key,
  });

  /// Files currently in the vault.
  final List<VaultEntry> entries;

  /// Called when the user taps a file in the list.
  final ValueChanged<VaultEntry> onOpenEntry;

  /// Called when the user taps the add-file button.
  final VoidCallback onAddFile;

  /// Called when the user taps the lock action.
  final VoidCallback onLock;

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  String _query = '';
  _VaultSort _sort = _VaultSort.newest;
  _VaultFilter _filter = _VaultFilter.all;

  List<VaultEntry> get _visible {
    final String query = _query.trim().toLowerCase();
    final List<VaultEntry> filtered = widget.entries.where((VaultEntry e) {
      if (!_matchesFilter(e)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return e.name.toLowerCase().contains(query);
    }).toList();
    switch (_sort) {
      case _VaultSort.nameAsc:
        filtered.sort(
          (VaultEntry a, VaultEntry b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _VaultSort.newest:
        filtered.sort(
          (VaultEntry a, VaultEntry b) => b.addedAt.compareTo(a.addedAt),
        );
      case _VaultSort.oldest:
        filtered.sort(
          (VaultEntry a, VaultEntry b) => a.addedAt.compareTo(b.addedAt),
        );
      case _VaultSort.largest:
        filtered.sort(
          (VaultEntry a, VaultEntry b) => b.sizeBytes.compareTo(a.sizeBytes),
        );
    }
    return filtered;
  }

  bool _matchesFilter(VaultEntry entry) {
    switch (_filter) {
      case _VaultFilter.all:
        return true;
      case _VaultFilter.pdf:
        return entry.kind == VaultEntryKind.pdf;
      case _VaultFilter.images:
        return entry.kind == VaultEntryKind.image;
      case _VaultFilter.text:
        return entry.kind == VaultEntryKind.text;
      case _VaultFilter.other:
        return entry.kind == VaultEntryKind.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<VaultEntry> visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My vault'),
        actions: <Widget>[
          PopupMenuButton<_VaultSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort files',
            initialValue: _sort,
            onSelected: (_VaultSort value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_VaultSort>>[
              const PopupMenuItem<_VaultSort>(
                value: _VaultSort.nameAsc,
                child: Text('Name A–Z'),
              ),
              const PopupMenuItem<_VaultSort>(
                value: _VaultSort.newest,
                child: Text('Newest'),
              ),
              const PopupMenuItem<_VaultSort>(
                value: _VaultSort.oldest,
                child: Text('Oldest'),
              ),
              const PopupMenuItem<_VaultSort>(
                value: _VaultSort.largest,
                child: Text('Largest'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Lock vault',
            onPressed: widget.onLock,
          ),
        ],
      ),
      body: widget.entries.isEmpty
          ? const _EmptyVault()
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: BitLockSearchField(
                    hintText: 'Search files',
                    onChanged: (String value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: <Widget>[
                      _filterChip(_VaultFilter.all, 'All'),
                      _filterChip(_VaultFilter.pdf, 'PDF'),
                      _filterChip(_VaultFilter.images, 'Images'),
                      _filterChip(_VaultFilter.text, 'Text'),
                      _filterChip(_VaultFilter.other, 'Other'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      visible.length == 1
                          ? '1 file'
                          : '${visible.length} files',
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.search_off_outlined,
                          title: 'No files match your search',
                          message:
                              'Try a different name, or clear the type '
                              'filter above.',
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final VaultEntry entry = visible[index];
                            return ListTile(
                              leading: Icon(_iconFor(entry.kind)),
                              title: Text(entry.name),
                              subtitle: Text(
                                '${entry.sizeLabel} · '
                                '${_dateLabel(entry.addedAt)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => widget.onOpenEntry(entry),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddFile,
        icon: const Icon(Icons.add),
        label: const Text('Add file'),
      ),
    );
  }

  Widget _filterChip(_VaultFilter filter, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _filter = filter;
            });
          }
        },
      ),
    );
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
}

/// Shown when the vault has no files yet.
class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.folder_open_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'No files yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Add file" to encrypt your first file into this vault.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
