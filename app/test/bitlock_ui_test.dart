import 'package:bitlock_app/features/audit/audit_log_screen.dart';
import 'package:bitlock_app/features/dashboard/dashboard_screen.dart';
import 'package:bitlock_app/features/onboarding/create_vault_screen.dart';
import 'package:bitlock_app/features/settings/settings_screen.dart';
import 'package:bitlock_app/features/share/create_share_screen.dart';
import 'package:bitlock_app/features/share/received_files_screen.dart';
import 'package:bitlock_app/features/share/share_models.dart';
import 'package:bitlock_app/features/vault/file_details_screen.dart';
import 'package:bitlock_app/features/vault/sample_vault_data.dart';
import 'package:bitlock_app/features/vault/vault_entry.dart';
import 'package:bitlock_app/features/vault/vault_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard shows counts derived from the data it is given',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final List<VaultEntry> entries = <VaultEntry>[
      VaultEntry(
        id: 'a',
        name: 'alpha.pdf',
        kind: VaultEntryKind.pdf,
        sizeBytes: 1024,
        addedAt: DateTime(2026, 10, 26, 9, 0),
      ),
      VaultEntry(
        id: 'b',
        name: 'beta.txt',
        kind: VaultEntryKind.text,
        sizeBytes: 2048,
        addedAt: DateTime(2026, 10, 26, 10, 0),
      ),
    ];
    final List<ShareGrant> shares = <ShareGrant>[
      ShareGrant(
        id: 's1',
        fileName: 'alpha.pdf',
        createdAt: DateTime(2026, 10, 26, 9, 30),
        status: ShareStatus.active,
        permission: SharePermission.viewOnly,
        accessCount: 0,
      ),
      ShareGrant(
        id: 's2',
        fileName: 'beta.txt',
        createdAt: DateTime(2026, 10, 25, 9, 30),
        status: ShareStatus.expired,
        permission: SharePermission.viewAndExport,
        accessCount: 1,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          entries: entries,
          shares: shares,
          recentEvents: <AuditLogEntry>[
            AuditLogEntry(
              at: DateTime(2026, 10, 26, 11, 15),
              event: 'Vault opened',
              detail: 'this device',
            ),
          ],
          onImport: () {},
          onOpenVault: () {},
          onOpenShared: () {},
          onOpenReceived: () {},
          onOpenSettings: () {},
          onOpenEntry: (_) {},
        ),
      ),
    );
    // Two protected files, one active share (the expired one excluded).
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Protected files'), findsOneWidget);
    expect(find.text('Active shares'), findsOneWidget);
    expect(find.text('Vault opened'), findsOneWidget);
    expect(find.text('alpha.pdf'), findsOneWidget);
  });

  testWidgets('create share with one-time access sends a limit of 1',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ShareDraft? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: CreateShareScreen(
          fileName: 'alpha.pdf',
          onCreate: (ShareDraft draft) async {
            captured = draft;
            return 'bitlock://share/test-token';
          },
        ),
      ),
    );
    await tester.tap(find.text('One-time access'));
    await tester.pump();
    await tester.tap(find.text('Create share link'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.accessLimit, 1);
    expect(captured!.permission, SharePermission.viewOnly);
    expect(find.text('bitlock://share/test-token'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('create share shows an error and no link when creation fails',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CreateShareScreen(
          fileName: 'alpha.pdf',
          onCreate: (_) async => null,
        ),
      ),
    );
    await tester.tap(find.text('Create share link'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Share could not be created. The sharing backend may not be '
        'configured yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Copy link'), findsNothing);
  });

  testWidgets('received screen rejects a malformed link without calling '
      'the backend', (tester) async {
    bool redeemCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReceivedFilesScreen(
          onRedeem: (_, __) async {
            redeemCalled = true;
            return RedeemResult.success;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'not a link');
    await tester.tap(find.text('Redeem link'));
    await tester.pump();
    expect(
      find.text('This does not look like a BitLock share link.'),
      findsOneWidget,
    );
    expect(redeemCalled, isFalse);
  });

  testWidgets('settings toggle reports the change through onChanged',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    BitLockSettingsData? latest;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          initial: const BitLockSettingsData(),
          onChanged: (BitLockSettingsData data) {
            latest = data;
          },
          storageUsedLabel: '3.0 MB used by vault ciphertext',
          onClearTempFiles: () async => 0,
          onOpenAuditLog: () {},
          onOpenShareManagement: () {},
        ),
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    expect(latest, isNotNull);
    expect(latest!.notificationsEnabled, isFalse);
  });

  testWidgets('create vault shows a mismatch error and stays disabled',
      (tester) async {
    bool createCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CreateVaultScreen(
          onCreate: (_) async {
            createCalled = true;
            return true;
          },
        ),
      ),
    );
    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'correct horse battery');
    await tester.enterText(fields.at(1), 'different password');
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    final FilledButton button =
        tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
    expect(createCalled, isFalse);
  });

  testWidgets('file details export runs only after the warning is confirmed',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int exportCount = 0;
    final VaultEntry entry = sampleVaultEntries().first;
    await tester.pumpWidget(
      MaterialApp(
        home: FileDetailsScreen(
          entry: entry,
          onView: () {},
          onExport: () {
            exportCount += 1;
          },
          onShare: () {},
          onRename: (_) async {},
          onDelete: () {},
        ),
      ),
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    // The warning dialog is up; export has not run yet.
    expect(find.text('Export an unprotected copy?'), findsOneWidget);
    expect(exportCount, 0);
    await tester.tap(find.text('Export copy'));
    await tester.pumpAndSettle();
    expect(exportCount, 1);
  });

  testWidgets('vault home search filters the list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VaultHomeScreen(
          entries: sampleVaultEntries(),
          onOpenEntry: (_) {},
          onAddFile: () {},
          onLock: () {},
        ),
      ),
    );
    expect(find.text('land-records.pdf'), findsOneWidget);
    expect(find.text('passport-scan.png'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'passport');
    await tester.pump();
    expect(find.text('passport-scan.png'), findsOneWidget);
    expect(find.text('land-records.pdf'), findsNothing);
    expect(find.text('recovery-codes.txt'), findsNothing);
  });
}
