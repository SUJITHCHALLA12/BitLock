import 'package:flutter/material.dart';

import '../../security/secure_screen.dart';
import '../../security/watermark_overlay.dart';

/// Text viewer: renders decrypted plain text in memory.
///
/// DRAFT (Phase 2): the text is shown in a non-editable, non-selectable
/// scroll view — copy-resistance by design for controlled viewing. The
/// caller decodes the decrypted bytes (UTF-8) and drops them when the
/// route closes; nothing is cached to disk.
class TextViewerScreen extends StatelessWidget {
  /// Creates a text viewer for already-decrypted [text].
  const TextViewerScreen({
    required this.title,
    required this.text,
    required this.watermarkLabel,
    super.key,
  });

  /// File name shown in the app bar.
  final String title;

  /// Decrypted file contents, held in memory only.
  final String text;

  /// Watermark text laid over the content.
  final String watermarkLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SecureScreen(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            WatermarkOverlay(label: watermarkLabel),
          ],
        ),
      ),
    );
  }
}
