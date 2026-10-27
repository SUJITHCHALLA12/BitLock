import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';
import '../../widgets/bitlock_widgets.dart';
import 'share_models.dart';

/// Status filter for the share list.
enum _ShareFilter {
  /// Every grant.
  all,

  /// Active grants only.
  active,

  /// Expired grants only.
  expired,

  /// Revoked grants only.
  revoked,

  /// Exhausted grants only.
  exhausted,
}

/// Share management: the owner's grants and their server-confirmed
/// state, with revoke and copy-link actions.
///
/// Revocation is optimistic nowhere: tapping Revoke asks
/// [onRevoke] to revoke server-side, and the row changes only when
/// it returns `true`. On `false` the screen shows that the server
/// did not confirm the revocation.
class ShareManagementScreen extends StatefulWidget {
  /// Creates the share management screen.
  const ShareManagementScreen({
    required this.shares,
    required this.onRevoke,
    required this.onCopyLink,
    this.linkFor,
    this.backendConfigured = true,
    super.key,
  });

  /// Grants to display (server-confirmed state from the caller).
  final List<ShareGrant> shares;

  /// Revokes a grant server-side. Returns `true` only when the
  /// server confirmed the revocation.
  final Future<bool> Function(ShareGrant grant) onRevoke;

  /// Copies (or otherwise shares out) the link for a grant.
  final void Function(ShareGrant grant) onCopyLink;

  /// Returns the share link for a grant, when the caller can produce
  /// one. Used only to enable the copy action's display.
  final String Function(ShareGrant grant)? linkFor;

  /// Whether the sharing backend is configured. When false, a banner
  /// states plainly that shares cannot be created or changed yet.
  final bool backendConfigured;

  @override
  State<ShareManagementScreen> createState() =>
      _ShareManagementScreenState();
}

class _ShareManagementScreenState extends State<ShareManagementScreen> {
  _ShareFilter _filter = _ShareFilter.all;
  final Set<String> _locallyRevoked = <String>{};
  String? _revokingId;

  ShareStatus _statusOf(ShareGrant grant) {
    if (_locallyRevoked.contains(grant.id)) {
      return ShareStatus.revoked;
    }
    return grant.status;
  }

  bool _matches(ShareGrant grant) {
    final ShareStatus status = _statusOf(grant);
    switch (_filter) {
      case _ShareFilter.all:
        return true;
      case _ShareFilter.active:
        return status == ShareStatus.active;
      case _ShareFilter.expired:
        return status == ShareStatus.expired;
      case _ShareFilter.revoked:
        return status == ShareStatus.revoked;
      case _ShareFilter.exhausted:
        return status == ShareStatus.exhausted;
    }
  }

  String _statusLabel(ShareStatus status) {
    switch (status) {
      case ShareStatus.active:
        return 'Active';
      case ShareStatus.expired:
        return 'Expired';
      case ShareStatus.revoked:
        return 'Revoked';
      case ShareStatus.exhausted:
        return 'Exhausted';
      case ShareStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(ShareStatus status) {
    switch (status) {
      case ShareStatus.active:
        return BitLockColors.success;
      case ShareStatus.expired:
        return BitLockColors.warning;
      case ShareStatus.revoked:
        return BitLockColors.error;
      case ShareStatus.exhausted:
        return BitLockColors.warning;
      case ShareStatus.pending:
        return BitLockColors.textSecondary;
    }
  }

  Future<void> _revoke(ShareGrant grant) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Revoke this share?',
      message: 'The server will stop honouring the link for '
          '"${grant.fileName}". Anyone who already obtained a '
          'plaintext copy keeps that copy — revocation cannot take '
          'it back.',
      confirmLabel: 'Revoke',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _revokingId = grant.id;
    });
    final bool ok = await widget.onRevoke(grant);
    if (!mounted) {
      return;
    }
    setState(() {
      _revokingId = null;
      if (ok) {
        _locallyRevoked.add(grant.id);
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revocation was not confirmed by the server.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ShareGrant> visible =
        widget.shares.where(_matches).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Shared files')),
      body: Column(
        children: <Widget>[
          if (!widget.backendConfigured)
            Container(
              width: double.infinity,
              color: BitLockColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.cloud_off_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sharing backend is not configured — shares '
                      'cannot be created or changed yet.',
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                _chip(_ShareFilter.all, 'All'),
                _chip(_ShareFilter.active, 'Active'),
                _chip(_ShareFilter.expired, 'Expired'),
                _chip(_ShareFilter.revoked, 'Revoked'),
                _chip(_ShareFilter.exhausted, 'Exhausted'),
              ],
            ),
          ),
          Expanded(
            child: widget.shares.isEmpty
                ? const EmptyStateView(
                    icon: Icons.share_outlined,
                    title: 'No shares yet',
                    message: 'Open a file in your vault and choose '
                        '"Create share" to share an encrypted copy.',
                  )
                : visible.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.filter_alt_outlined,
                        title: 'No shares with this status',
                        message:
                            'Try a different status filter above.',
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder:
                            (BuildContext context, int index) =>
                                const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final ShareGrant grant = visible[index];
                          final ShareStatus status = _statusOf(grant);
                          return _ShareRow(
                            grant: grant,
                            status: status,
                            statusLabel: _statusLabel(status),
                            statusColor: _statusColor(status),
                            busy: _revokingId == grant.id,
                            canRevoke: widget.backendConfigured,
                            onRevoke: () => _revoke(grant),
                            onCopyLink: () => widget.onCopyLink(grant),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(_ShareFilter filter, String label) {
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
}

/// One grant row in the management list.
class _ShareRow extends StatelessWidget {
  /// Creates a share row.
  const _ShareRow({
    required this.grant,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.busy,
    required this.canRevoke,
    required this.onRevoke,
    required this.onCopyLink,
  });

  /// The grant to display.
  final ShareGrant grant;

  /// Effective status shown for this row.
  final ShareStatus status;

  /// Label for the status chip, matching [status].
  final String statusLabel;

  /// Colour for the status chip.
  final Color statusColor;

  /// Whether a revocation is in flight for this row.
  final bool busy;

  /// Whether revocation is available (backend configured).
  final bool canRevoke;

  /// Called when the user confirms revocation.
  final VoidCallback onRevoke;

  /// Called when the user taps copy link.
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == ShareStatus.active;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.insert_drive_file_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  grant.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${grant.expiryLabel} · ${grant.accessLabel} · '
            '${grant.permissionLabel}'
            '${grant.hasPasscode ? ' · Passcode set' : ''}',
          ),
          if (isActive) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy link'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: busy || !canRevoke ? null : onRevoke,
                  icon: busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block_outlined, size: 18),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
