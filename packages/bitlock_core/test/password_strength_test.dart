import 'package:bitlock_core/bitlock_core.dart';
import 'package:test/test.dart';

void main() {
  test('empty, common, and repeated passwords are weak', () {
    expect(estimatePasswordStrength('').level, PasswordStrengthLevel.weak);
    expect(estimatePasswordStrength('password').level, PasswordStrengthLevel.weak);
    expect(estimatePasswordStrength('aaaaaaaaaaaaaaaa').level, PasswordStrengthLevel.weak);
  });

  test('length and variety improve the estimate and provide a hint', () {
    final short = estimatePasswordStrength('cat7');
    final long = estimatePasswordStrength('amber-river-orbit-cactus-82!');
    expect(long.estimatedBits, greaterThan(short.estimatedBits));
    expect(long.level, PasswordStrengthLevel.strong);
    expect(long.hint, isNotEmpty);
  });

  test('sequential patterns are penalized', () {
    expect(estimatePasswordStrength('abcdEFGH1234').level, PasswordStrengthLevel.weak);
  });
}
