import 'package:bitlock_app/features/audit/audit_log_screen.dart';
import 'package:bitlock_app/features/vault/sample_vault_data.dart';
import 'package:bitlock_app/features/vault/unlock_vault_screen.dart';
import 'package:bitlock_app/features/vault/vault_home_screen.dart';
import 'package:bitlock_app/features/viewer/text_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vault home lists the entries it is given', (tester) async {
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
    expect(find.text('recovery-codes.txt'), findsOneWidget);
  });

  testWidgets('vault home shows the empty state with no entries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VaultHomeScreen(
          entries: const [],
          onOpenEntry: (_) {},
          onAddFile: () {},
          onLock: () {},
        ),
      ),
    );
    expect(find.text('No files yet'), findsOneWidget);
  });

  testWidgets('unlock screen shows a password field and unlock button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: UnlockVaultScreen(onUnlock: (_) async => false)),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('failed unlock surfaces only the generic error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: UnlockVaultScreen(onUnlock: (_) async => false)),
    );
    await tester.enterText(find.byType(TextField), 'wrong-password');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(
      find.text("Couldn't open the vault. Check your password and try again."),
      findsOneWidget,
    );
  });

  testWidgets('text viewer renders content under a watermark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TextViewerScreen(
          title: 'note.txt',
          text: 'top secret hello',
          watermarkLabel: 'Sujith',
        ),
      ),
    );
    expect(find.text('top secret hello'), findsOneWidget);
    expect(find.text('Sujith'), findsWidgets);
  });

  testWidgets('audit log lists entries newest first as given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogScreen(
          entries: <AuditLogEntry>[
            AuditLogEntry(
              at: DateTime(2026, 10, 26, 9, 30),
              event: 'File viewed',
              detail: 'land-records.pdf',
            ),
            AuditLogEntry(
              at: DateTime(2026, 10, 26, 9, 12),
              event: 'Vault opened',
              detail: '',
            ),
          ],
        ),
      ),
    );
    expect(find.text('File viewed'), findsOneWidget);
    expect(find.text('Vault opened'), findsOneWidget);
  });
}
