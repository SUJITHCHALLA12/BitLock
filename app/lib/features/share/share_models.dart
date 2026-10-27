/// Lifecycle state of a share grant, as confirmed by the sharing
/// backend. The client displays this state; it never invents it —
/// expiry, revocation, and exhaustion are enforced server-side.
enum ShareStatus {
  /// The grant can still be redeemed.
  active,

  /// The grant passed its expiry time.
  expired,

  /// The owner revoked the grant.
  revoked,

  /// The grant reached its access limit.
  exhausted,

  /// The grant was created locally and is awaiting server confirmation.
  pending,
}

/// What a recipient is allowed to do with a shared file.
enum SharePermission {
  /// Controlled viewing inside BitLock only; BitLock provides no
  /// download or export action for this grant.
  viewOnly,

  /// The recipient may view and export the original bytes.
  viewAndExport,
}

/// The owner's choices for a new share, passed to the create callback.
///
/// The passcode is recipient key material: it is never sent to the
/// server in plaintext and is not the file-encryption key itself.
class ShareDraft {
  /// Creates a share draft.
  const ShareDraft({
    required this.permission,
    this.expiresAt,
    this.accessLimit,
    this.passcode,
  });

  /// When the grant stops working, or null for no expiry.
  final DateTime? expiresAt;

  /// Maximum number of successful redemptions, or null for no limit.
  final int? accessLimit;

  /// What the recipient may do with the file.
  final SharePermission permission;

  /// Optional passcode the recipient must supply, or null.
  final String? passcode;

  /// Whether a passcode was set.
  bool get hasPasscode => passcode != null && passcode!.isNotEmpty;
}

/// One share grant as shown in share management and on the dashboard.
///
/// Instances mirror server-confirmed state. When the backend is not
/// configured, screens must say so instead of presenting these as
/// live grants.
class ShareGrant {
  /// Creates a share grant summary.
  const ShareGrant({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.status,
    required this.permission,
    required this.accessCount,
    this.expiresAt,
    this.accessLimit,
    this.hasPasscode = false,
  });

  /// Stable identifier of the grant (not the secret token itself).
  final String id;

  /// Display name of the shared file.
  final String fileName;

  /// When the grant was created.
  final DateTime createdAt;

  /// When the grant expires, or null when it has no expiry.
  final DateTime? expiresAt;

  /// Current lifecycle state, as reported by the backend.
  final ShareStatus status;

  /// What the recipient may do with the file.
  final SharePermission permission;

  /// Maximum successful redemptions, or null for no limit.
  final int? accessLimit;

  /// Successful redemptions so far, as reported by the backend.
  final int accessCount;

  /// Whether redemption requires a passcode.
  final bool hasPasscode;

  /// Whether the grant can still be redeemed.
  bool get isActive => status == ShareStatus.active;

  /// Human-readable status, e.g. `Active`.
  String get statusLabel {
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

  /// Human-readable permission, e.g. `View only`.
  String get permissionLabel {
    switch (permission) {
      case SharePermission.viewOnly:
        return 'View only';
      case SharePermission.viewAndExport:
        return 'View + export';
    }
  }

  /// Human-readable expiry, e.g. `Expires 28/10/2026 09:30` or
  /// `No expiry`.
  String get expiryLabel {
    final DateTime? expiry = expiresAt;
    if (expiry == null) {
      return 'No expiry';
    }
    if (status == ShareStatus.expired) {
      return 'Expired ${_dateLabel(expiry)}';
    }
    return 'Expires ${_dateLabel(expiry)} ${_timeLabel(expiry)}';
  }

  /// Human-readable access usage, e.g. `2 of 5 accesses used`.
  String get accessLabel {
    if (accessLimit == null) {
      return '$accessCount accesses';
    }
    return '$accessCount of $accessLimit accesses used';
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

/// Sample grants so the sharing screens can be previewed and
/// widget-tested before the backend is connected.
///
/// Preview only: never present these as real, server-confirmed
/// grants in a release flow.
List<ShareGrant> sampleShareGrants() => <ShareGrant>[
      ShareGrant(
        id: 'sample-share-1',
        fileName: 'land-records.pdf',
        createdAt: DateTime(2026, 10, 24, 10, 5),
        expiresAt: DateTime(2026, 10, 31, 10, 5),
        status: ShareStatus.active,
        permission: SharePermission.viewOnly,
        accessLimit: 3,
        accessCount: 1,
        hasPasscode: true,
      ),
      ShareGrant(
        id: 'sample-share-2',
        fileName: 'passport-scan.png',
        createdAt: DateTime(2026, 10, 18, 19, 40),
        expiresAt: DateTime(2026, 10, 19, 19, 40),
        status: ShareStatus.expired,
        permission: SharePermission.viewAndExport,
        accessCount: 2,
      ),
      ShareGrant(
        id: 'sample-share-3',
        fileName: 'recovery-codes.txt',
        createdAt: DateTime(2026, 10, 15, 8, 12),
        status: ShareStatus.revoked,
        permission: SharePermission.viewOnly,
        accessLimit: 1,
        accessCount: 0,
      ),
    ];
