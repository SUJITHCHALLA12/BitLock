import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/bitlock_theme.dart';
import '../../widgets/bitlock_widgets.dart';
import 'share_models.dart';

/// Expiry presets offered when creating a share.
enum _ExpiryChoice {
  /// Expires one hour after creation.
  oneHour,

  /// Expires 24 hours after creation.
  oneDay,

  /// Expires seven days after creation.
  sevenDays,

  /// No expiry; only allowed with an extra confirmation, because
  /// revocation works only while the grant stays server-controlled.
  noExpiry,
}

/// Owner-side share creation: pick permission, expiry, access limit,
/// and an optional passcode, then create the grant on the backend.
///
/// [onCreate] performs the real work — prepare ciphertext, create
/// the grant server-side, return the share link. It returns null on
/// any failure (including "backend not configured"), and this screen
/// then shows an error. A link is shown only when [onCreate] returns
/// one; this screen never invents a link locally.
class CreateShareScreen extends StatefulWidget {
  /// Creates the share-creation screen.
  const CreateShareScreen({
    required this.fileName,
    required this.onCreate,
    super.key,
  });

  /// Display name of the file being shared.
  final String fileName;

  /// Creates the grant on the backend and returns its share link, or
  /// null when creation failed.
  final Future<String?> Function(ShareDraft draft) onCreate;

  @override
  State<CreateShareScreen> createState() => _CreateShareScreenState();
}

class _CreateShareScreenState extends State<CreateShareScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  SharePermission _permission = SharePermission.viewOnly;
  _ExpiryChoice _expiry = _ExpiryChoice.oneDay;
  bool _oneTime = false;
  int _accessLimit = 5;
  bool _noExpiryConfirmed = false;
  bool _showPasscode = false;
  bool _busy = false;
  String? _createdLink;
  String? _errorText;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  bool get _needsNoExpiryConfirm => _expiry == _ExpiryChoice.noExpiry;

  bool get _canCreate =>
      !_busy &&
      _createdLink == null &&
      (!_needsNoExpiryConfirm || _noExpiryConfirmed);

  DateTime? _expiresAt() {
    final DateTime now = DateTime.now();
    switch (_expiry) {
      case _ExpiryChoice.oneHour:
        return now.add(const Duration(hours: 1));
      case _ExpiryChoice.oneDay:
        return now.add(const Duration(hours: 24));
      case _ExpiryChoice.sevenDays:
        return now.add(const Duration(days: 7));
      case _ExpiryChoice.noExpiry:
        return null;
    }
  }

  Future<void> _create() async {
    if (!_canCreate) {
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final String passcode = _passcodeController.text;
    final ShareDraft draft = ShareDraft(
      permission: _permission,
      expiresAt: _expiresAt(),
      accessLimit: _oneTime ? 1 : _accessLimit,
      passcode: passcode.isEmpty ? null : passcode,
    );
    final String? link = await widget.onCreate(draft);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (link == null) {
        _errorText = 'Share could not be created. The sharing backend '
            'may not be configured yet.';
      } else {
        _createdLink = link;
      }
    });
  }

  Future<void> _copyLink() async {
    final String? link = _createdLink;
    if (link == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? link = _createdLink;
    return Scaffold(
      appBar: AppBar(title: const Text('Create share')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Share "${widget.fileName}"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The file is shared as ciphertext. The backend checks '
            'expiry, revocation, and the access limit on every request.',
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Permission'),
          _PermissionTile(
            title: 'View only',
            subtitle: 'The recipient can view the file inside BitLock. '
                'BitLock provides no download or export action in '
                'view-only mode, and controlled viewing blocks '
                'supported capture paths — it cannot stop someone '
                'photographing the screen.',
            selected: _permission == SharePermission.viewOnly,
            onTap: () {
              setState(() {
                _permission = SharePermission.viewOnly;
              });
            },
          ),
          _PermissionTile(
            title: 'View + export',
            subtitle: 'The recipient can view the file and export the '
                'original bytes. Exported copies are no longer '
                'protected by BitLock.',
            selected: _permission == SharePermission.viewAndExport,
            onTap: () {
              setState(() {
                _permission = SharePermission.viewAndExport;
              });
            },
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Expiry'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('1 hour'),
                selected: _expiry == _ExpiryChoice.oneHour,
                onSelected: (_) {
                  setState(() {
                    _expiry = _ExpiryChoice.oneHour;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('24 hours'),
                selected: _expiry == _ExpiryChoice.oneDay,
                onSelected: (_) {
                  setState(() {
                    _expiry = _ExpiryChoice.oneDay;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('7 days'),
                selected: _expiry == _ExpiryChoice.sevenDays,
                onSelected: (_) {
                  setState(() {
                    _expiry = _ExpiryChoice.sevenDays;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('No expiry'),
                selected: _expiry == _ExpiryChoice.noExpiry,
                onSelected: (_) {
                  setState(() {
                    _expiry = _ExpiryChoice.noExpiry;
                  });
                },
              ),
            ],
          ),
          if (_needsNoExpiryConfirm)
            CheckboxListTile(
              value: _noExpiryConfirmed,
              onChanged: (bool? value) {
                setState(() {
                  _noExpiryConfirmed = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand this link keeps working until I revoke '
                'it, and revocation works only while the grant is '
                'controlled by the server',
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _oneTime,
            onChanged: (bool value) {
              setState(() {
                _oneTime = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('One-time access'),
            subtitle: const Text(
              'The grant stops working after one successful access, '
              'enforced by the server.',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Access limit')),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Decrease access limit',
                onPressed: _oneTime || _accessLimit <= 1
                    ? null
                    : () {
                        setState(() {
                          _accessLimit -= 1;
                        });
                      },
              ),
              Text(
                _oneTime ? '1' : '$_accessLimit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Increase access limit',
                onPressed: _oneTime || _accessLimit >= 100
                    ? null
                    : () {
                        setState(() {
                          _accessLimit += 1;
                        });
                      },
              ),
            ],
          ),
          if (_oneTime)
            const Text(
              'One-time access is on, so the limit is fixed at 1.',
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Passcode (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _passcodeController,
            obscureText: !_showPasscode,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Share passcode',
              helperText:
                  'The passcode is not stored in plaintext and is '
                  'never used as the file-encryption key.',
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
          if (link != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_outline,
                          color: BitLockColors.success,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Share created',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(link),
                    const SizedBox(height: 8),
                    const Text(
                      'Anyone with this link and the passcode (if set) '
                      'can request access; the server checks the grant '
                      'every time. Treat the link like a secret.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy link'),
                    ),
                  ],
                ),
              ),
            )
          else
            BitLockPrimaryButton(
              label: 'Create share link',
              busy: _busy,
              onPressed: _canCreate ? _create : null,
            ),
        ],
      ),
    );
  }
}

/// One selectable permission option.
class _PermissionTile extends StatelessWidget {
  /// Creates a permission option tile.
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  /// Option title.
  final String title;

  /// Option explanation.
  final String subtitle;

  /// Whether this option is selected.
  final bool selected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: selected ? BitLockColors.primaryLight : null,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        selected: selected,
      ),
    );
  }
}
