/// What kind of content a vault entry holds, for list icons and routing
/// to the matching viewer.
enum VaultEntryKind {
  /// A PDF document, opened in the PDF viewer.
  pdf,

  /// An image, opened in the image viewer.
  image,

  /// A plain-text file, opened in the text viewer.
  text,

  /// Anything else; listed but not viewable in Phase 2.
  other,
}

/// Metadata for one encrypted file in the vault.
///
/// DRAFT (Phase 2): this is the shape the vault file list renders. The
/// store behind it is not built yet.
///
/// OPEN DECISION (Sujith's call, from the Phase 2 plan): which of these
/// fields stay readable in plaintext on disk — e.g. is [name] visible
/// before unlock, or does the list stay hidden until the vault opens?
/// Document the choice in `docs/DECISIONS.md` before the store lands.
class VaultEntry {
  /// Creates a vault entry description.
  const VaultEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.sizeBytes,
    required this.addedAt,
    this.lastAccessedAt,
    this.mimeLabel,
  });

  /// Stable identifier of the entry inside the vault.
  final String id;

  /// Display name of the file as the user knows it.
  final String name;

  /// Content kind, used for the list icon and viewer routing.
  final VaultEntryKind kind;

  /// Size of the stored (encrypted) file in bytes.
  final int sizeBytes;

  /// When the file was added to the vault.
  final DateTime addedAt;

  /// When the file was last opened, if it has been opened.
  final DateTime? lastAccessedAt;

  /// MIME-type label for display (e.g. `application/pdf`), when known.
  ///
  /// A label only: the stored bytes are treated as opaque content and
  /// the extension or MIME type is never trusted as proof of content.
  final String? mimeLabel;

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
