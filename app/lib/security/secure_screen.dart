import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Applies Android's FLAG_SECURE to the window while this widget is in
/// the tree, so viewer routes block supported capture paths (screenshots
/// and screen recording on standard Android).
///
/// DRAFT (Phase 2): talks to a `bitlock/security` method channel that
/// still needs its Android side — in `MainActivity`, handle
/// `setFlagSecure(bool)` with
/// `window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)` /
/// `window.clearFlags(...)`. Until that handler exists the channel call
/// fails silently and the screen is NOT protected; the Phase 2 report
/// must record the on-device screenshot test as the real proof.
///
/// Honest-claims rule: FLAG_SECURE does not stop rooted devices or an
/// external camera. UI copy says "blocks supported capture paths",
/// never "screenshot-proof".
class SecureScreen extends StatefulWidget {
  /// Creates a screen region protected while mounted.
  const SecureScreen({required this.child, super.key});

  /// The content to protect.
  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const MethodChannel _channel = MethodChannel('bitlock/security');

  @override
  void initState() {
    super.initState();
    _setSecure(true);
  }

  @override
  void dispose() {
    _setSecure(false);
    super.dispose();
  }

  Future<void> _setSecure(bool on) async {
    try {
      await _channel.invokeMethod<void>('setFlagSecure', on);
    } on MissingPluginException {
      // No Android handler yet (draft) — protection is not active.
    } on PlatformException {
      // Best effort only; never crash the viewer over the flag.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
