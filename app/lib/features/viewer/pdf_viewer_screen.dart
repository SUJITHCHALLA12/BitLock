import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../security/secure_screen.dart';
import '../../security/watermark_overlay.dart';

/// PDF viewer: controlled viewing of a decrypted PDF, in memory only.
///
/// DRAFT (Phase 2): the screen shell — secure flag, watermark, app bar —
/// is ready; page rendering plugs in through `pdfx`, which renders from
/// in-memory bytes without a plaintext file. Dependency status: the
/// Phase 2 plan (decision F5) requires the license check first — done
/// 2026-10-17: `pdfx` is MIT-licensed, clear to add; record it in
/// `docs/DEPENDENCIES.md` and eyeball the license tab of the exact
/// version pinned in `pubspec.yaml`.
class PdfViewerScreen extends StatelessWidget {
  /// Creates a PDF viewer for already-decrypted [bytes].
  const PdfViewerScreen({
    required this.title,
    required this.bytes,
    required this.watermarkLabel,
    super.key,
  });

  /// File name shown in the app bar.
  final String title;

  /// Decrypted PDF bytes, held in memory only.
  final Uint8List bytes;

  /// Watermark text laid over the pages.
  final String watermarkLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SecureScreen(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // TODO(phase-2): replace this placeholder with the pdfx
            // controller/view fed from [bytes] once the dependency lands.
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'PDF preview (${bytes.length} bytes decrypted in memory)\n'
                  'Page rendering plugs in here via pdfx.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            WatermarkOverlay(label: watermarkLabel),
          ],
        ),
      ),
    );
  }
}
