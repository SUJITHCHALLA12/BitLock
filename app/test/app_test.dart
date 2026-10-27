import 'package:bitlock_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

// Test change note: this file previously expected the placeholder
// text 'BitLock foundation' from the foundation shell. That
// placeholder was replaced by the real UI entry (BitLockApp now
// mounts BitLockRoot, starting at the splash screen), so the
// expectation now checks for the splash branding instead. No other
// test expectations were changed.
void main() {
  testWidgets('app starts at the BitLock splash screen', (tester) async {
    await tester.pumpWidget(const BitLockApp());
    expect(find.text('BitLock'), findsOneWidget);
    // Let the splash timer fire so no timer is left pending, and the
    // flow advances to first-run onboarding.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Files encrypted on this device'), findsOneWidget);
  });
}
