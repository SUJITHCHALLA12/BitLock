import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';
import '../../widgets/bitlock_widgets.dart';
import 'share_models.dart';

/// Outcome of a redemption attempt, as decided by the backend.
///
/// The values map to distinct server responses: the client reports
/// what the server said and never treats a local guess as access.
enum RedeemResult {
  /// The server granted access.
  success('Access granted by the server. The file will be downloaded '
      'encrypted and opened here.'),

  /// The grant passed its expiry time.
  expired('This link has expired. Ask the sender for a new link.'),

  /// The owner revoked the grant.
  revoked('This link was revoked by its owner.'),

  /// The grant reached its access limit.
  exhausted('This link has no accesses left.'),

  /// The link or grant is not recognised.
  invalid('This link is invalid or no longer exists.'),

  /// The passcode or recipient authentication failed.
  authFailed('That passcode was not accepted. Check it and try again.'),

  /// The sharing backend could not be reached or is not configured.
  backendUnavailable('The sharing service could not be reached. '
      'It may not be configured yet — try again later.');

  /// Creates a redeem result with its user-facing [message].
  const RedeemResult(this.message);

  /// User-facing explanation of this outcome.
  final String message;
}

/// Recipient side: paste a BitLock share link, redeem it against the
/// backend, and see a clear state for every outcome.
///
/// The link format is validated locally first (cheap syntax check
/// only — it proves nothing about authorization). [onRedeem] then
/// asks the server, which checks expiry, revocation, the access
/// allowance, and the passcode, and only then releases ciphertext
/// for local decryption.
class ReceivedFilesScreen extends StatefulWidget {
  /// Creates the received-files screen.
  const ReceivedFilesScreen({
    required this.onRedeem,
    this.incomingShares = const <ShareGrant>[],
    super.key,
  });

  /// Redeems a link (with an optional passcode) against the backend.
  final Future<RedeemResult> Function(String link, String? passcode)
      onRedeem;

  /// Grants addressed to this user, as reported by the backend.
  final List<ShareGrant> incomingShares;

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  bool _busy = false;
  bool _showPasscode = false;
  String? _formatError;
  RedeemResult? _result;

  @override
  void dispose() {
    _linkController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  /// Local syntax check only: a `bitlock://share/<token>` deep link,
  /// or an `https://` link with a token segment. Authorization is the
  /// server's job and is never inferred from this check.
  static bool _looksLikeShareLink(String raw) {
    final String link = raw.trim();
    if (link.isEmpty || link.contains(' ')) {
      return false;
    }
    const String prefix = 'bitlock://share/';
    if (link.startsWith(prefix)) {
      final String token = link.substring(prefix.length);
      return token.isNotEmpty && !token.contains('/');
    }
    if (link.startsWith('https://')) {
      final Uri? uri = Uri.tryParse(link);
      if (uri == null || uri.host.isEmpty) {
        return false;
      }
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.last.isNotEmpty;
    }
    return false;
  }

  Future<void> _redeem() async {
    if (_busy) {
      return;
    }
    final String link = _linkController.text.trim();
    if (!_looksLikeShareLink(link)) {
      setState(() {
        _formatError = 'This does not look like a BitLock share link.';
        _result = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _formatError = null;
      _result = null;
    });
    final String passcode = _passcodeController.text;
    final RedeemResult result =
        await widget.onRedeem(link, passcode.isEmpty ? null : passcode);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final RedeemResult? result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Received files')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Paste a BitLock share link to open a file someone shared '
            'with you. The server checks the link before anything is '
            'downloaded, and the file is downloaded encrypted and '
            'decrypted on this device.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Share link',
              hintText: 'bitlock://share/…',
              errorText: _formatError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passcodeController,
            obscureText: !_showPasscode,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Passcode (if the sender set one)',
              suffixIcon: IconButton(
                icon: Icon(
                  _showPasscode
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _showPasscode ? 'Hide passcode' : 'Show passcode',
                onPressed: () {
                  setState(() {
                    _showPasscode = !_showPasscode;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          BitLockPrimaryButton(
            label: 'Redeem link',
            busy: _busy,
            onPressed: _redeem,
          ),
          if (result != null) ...<Widget>[
            const SizedBox(height: 20),
            _ResultCard(result: result),
          ],
          if (widget.incomingShares.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Shared with you'),
            const SizedBox(height: 4),
            for (final ShareGrant grant in widget.incomingShares)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(grant.fileName),
                subtitle: Text(
                  '${grant.statusLabel} · ${grant.expiryLabel} · '
                  '${grant.permissionLabel}',
                ),
                trailing: StatusChip(
                  label: grant.statusLabel,
                  color: grant.isActive
                      ? BitLockColors.success
                      : BitLockColors.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Result card for one redemption attempt, styled per outcome.
class _ResultCard extends StatelessWidget {
  /// Creates a result card.
  const _ResultCard({required this.result});

  /// The outcome to present.
  final RedeemResult result;

  @override
  Widget build(BuildContext context) {
    final bool ok = result == RedeemResult.success;
    final Color color =
        ok ? BitLockColors.success : BitLockColors.error;
    final IconData icon = ok
        ? Icons.check_circle_outline
        : result == RedeemResult.backendUnavailable
            ? Icons.cloud_off_outlined
            : Icons.error_outline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(result.message)),
          ],
        ),
      ),
    );
  }
}
