import 'package:flutter/material.dart';

/// One entry in the local audit log, as shown by [AuditLogScreen].
///
/// DRAFT (Phase 2): display shape only. The real entries come from the
/// append-only, hash-chained log in `data/local/`; this screen never
/// edits or deletes entries — the log has no edit/delete API by design.
class AuditLogEntry {
  /// Creates an audit log entry for display.
  const AuditLogEntry({
    required this.at,
    required this.event,
    required this.detail,
  });

  /// When the event happened.
  final DateTime at;

  /// Short event name, e.g. `Vault opened`, `File viewed`.
  final String event;

  /// Extra context, e.g. the file name involved.
  final String detail;
}

/// Audit log viewer: what happened in this vault, newest first.
///
/// DRAFT (Phase 2): renders entries passed in by the caller. A
/// "chain verified" indicator belongs here only once it is backed by a
/// real hash-chain check in code (honest-claims rule) — until then the
/// screen shows the entries and nothing more.
class AuditLogScreen extends StatelessWidget {
  /// Creates the audit log screen.
  const AuditLogScreen({required this.entries, super.key});

  /// Log entries to display, newest first.
  final List<AuditLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: entries.isEmpty
          ? const Center(child: Text('No events recorded yet.'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(entry.event),
                  subtitle: Text(entry.detail),
                  trailing: Text(_timeLabel(entry.at)),
                );
              },
            ),
    );
  }

  static String _timeLabel(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
