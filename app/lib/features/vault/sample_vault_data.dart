import 'vault_entry.dart';

/// Sample entries so the vault screens can be previewed and widget-tested
/// before the real vault store exists.
///
/// DRAFT (Phase 2): never ship sample data in the release flow — the vault
/// home gets its entries from the vault metadata store once it is built.
List<VaultEntry> sampleVaultEntries() => <VaultEntry>[
      VaultEntry(
        id: 'sample-1',
        name: 'land-records.pdf',
        kind: VaultEntryKind.pdf,
        sizeBytes: 2457600,
        addedAt: DateTime(2026, 10, 20, 9, 14),
      ),
      VaultEntry(
        id: 'sample-2',
        name: 'passport-scan.png',
        kind: VaultEntryKind.image,
        sizeBytes: 891289,
        addedAt: DateTime(2026, 10, 21, 18, 2),
      ),
      VaultEntry(
        id: 'sample-3',
        name: 'recovery-codes.txt',
        kind: VaultEntryKind.text,
        sizeBytes: 1024,
        addedAt: DateTime(2026, 10, 22, 7, 45),
      ),
    ];
