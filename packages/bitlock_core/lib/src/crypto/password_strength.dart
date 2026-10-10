import 'dart:math' as math;

/// Relative strength of a candidate password based on an entropy estimate.
enum PasswordStrengthLevel { weak, fair, good, strong }

/// Strength estimate and actionable, non-secret guidance for a password.
class PasswordStrength {
  /// Creates a strength result.
  const PasswordStrength({required this.level, required this.estimatedBits, required this.hint});

  /// Coarse strength category.
  final PasswordStrengthLevel level;
  /// Estimated search entropy in bits; this is not a guarantee against guessing.
  final double estimatedBits;
  /// Plain-language suggestion suitable for an onboarding screen.
  final String hint;
}

/// Estimates password strength using character-set entropy and pattern penalties.
///
/// This lightweight estimate is guidance only; it is not a password verifier or
/// a replacement for rate limiting and a memory-hard password KDF.
PasswordStrength estimatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrength(level: PasswordStrengthLevel.weak, estimatedBits: 0,
      hint: 'Use a longer passphrase with several unrelated words.');
  }
  var pool = 0;
  if (RegExp('[a-z]').hasMatch(password)) pool += 26;
  if (RegExp('[A-Z]').hasMatch(password)) pool += 26;
  if (RegExp('[0-9]').hasMatch(password)) pool += 10;
  if (RegExp('[^A-Za-z0-9]').hasMatch(password)) pool += 33;
  final unique = password.runes.toSet().length;
  final repeatedRatio = unique / password.runes.length;
  var bits = password.length * math.log(pool == 0 ? 1 : pool) / math.ln2;
  bits *= repeatedRatio;
  if (_isCommon(password) || _hasLongSequence(password)) bits = math.min(bits, 12);
  final level = switch (bits) {
    < 28 => PasswordStrengthLevel.weak,
    < 45 => PasswordStrengthLevel.fair,
    < 65 => PasswordStrengthLevel.good,
    _ => PasswordStrengthLevel.strong,
  };
  final hint = switch (level) {
    PasswordStrengthLevel.weak => 'Use a longer passphrase with several unrelated words.',
    PasswordStrengthLevel.fair => 'Add length and avoid repeated or predictable patterns.',
    PasswordStrengthLevel.good => 'Good length; avoid reusing this password elsewhere.',
    PasswordStrengthLevel.strong => 'Strong estimate; keep it unique and private.',
  };
  return PasswordStrength(level: level, estimatedBits: bits, hint: hint);
}

bool _isCommon(String value) {
  const common = {'password', 'password1', '12345678', 'qwerty123', 'letmein', 'admin'};
  return common.contains(value.toLowerCase());
}

bool _hasLongSequence(String value) {
  if (value.length < 4) return false;
  var ascending = 1;
  var descending = 1;
  for (var i = 1; i < value.length; i++) {
    final delta = value.codeUnitAt(i) - value.codeUnitAt(i - 1);
    ascending = delta == 1 ? ascending + 1 : 1;
    descending = delta == -1 ? descending + 1 : 1;
    if (ascending >= 4 || descending >= 4) return true;
  }
  return false;
}
