import 'package:bitlock_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation app shell starts', (tester) async {
    await tester.pumpWidget(const BitLockApp());
    expect(find.text('BitLock foundation'), findsOneWidget);
  });
}
