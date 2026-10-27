import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../security/secure_screen.dart';
import '../../security/watermark_overlay.dart';

/// Image viewer: renders decrypted image bytes from memory.
///
/// DRAFT (Phase 2): bytes arrive already decrypted by the caller and are
/// never written to disk as plaintext. When the route closes, the caller
/// drops its reference so the bytes can be reclaimed (best-effort
/// clearing, the same standard as the core).
class ImageViewerScreen extends StatelessWidget {
  /// Creates an image viewer for already-decrypted [bytes].
  const ImageViewerScreen({
    required this.title,
    required this.bytes,
    required this.watermarkLabel,
    super.key,
  });

  /// File name shown in the app bar.
  final String title;

  /// Decrypted image bytes, held in memory only.
  final Uint8List bytes;

  /// Watermark text laid over the image.
  final String watermarkLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: SecureScreen(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            InteractiveViewer(
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
            WatermarkOverlay(label: watermarkLabel),
          ],
        ),
      ),
    );
  }
}
