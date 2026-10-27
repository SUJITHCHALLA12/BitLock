import 'package:flutter/material.dart';

/// Repeating diagonal watermark laid over viewed content.
///
/// DRAFT (Phase 2): shows [label] (typically the vault owner's name or
/// device label) across the content so a photo of the screen carries the
/// mark. The watermark discourages leaks; it does not prevent them, and
/// no copy in the app may claim otherwise.
class WatermarkOverlay extends StatelessWidget {
  /// Creates a watermark overlay with the given [label].
  const WatermarkOverlay({required this.label, super.key});

  /// Text repeated across the content, e.g. the owner's name.
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double stepX = 220;
          const double stepY = 150;
          final int columns = (constraints.maxWidth / stepX).ceil() + 1;
          final int rows = (constraints.maxHeight / stepY).ceil() + 1;
          return Stack(
            children: <Widget>[
              for (int r = 0; r < rows; r++)
                for (int c = 0; c < columns; c++)
                  Positioned(
                    left: c * stepX - 40,
                    top: r * stepY,
                    child: Transform.rotate(
                      angle: -0.42,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0x2EFFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
