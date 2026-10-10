import 'package:cryptography/cryptography.dart';

import '../format/bitlock_format.dart';

/// Computes the 16-byte truncated HMAC-SHA256 for an encoded header prefix.
Future<List<int>> computeHeaderMac(SecretKey key, List<int> prefix) async =>
    (await Hmac.sha256().calculateMac(prefix, secretKey: key)).bytes.sublist(0, BitlockFormat.tagLength);

/// Compares MACs without returning early on the first differing byte.
bool constantTimeMacEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }
  return difference == 0;
}
