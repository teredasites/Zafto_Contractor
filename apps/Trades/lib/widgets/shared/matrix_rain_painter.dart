import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shared color constants used across premium widgets
const Color crmEmerald = Color(0xFF10B981);
const Color brandAmber = Color(0xFFFFB020);

/// Matrix rain — vertical falling trade codes (optimized CustomPainter)
///
/// Reusable across any screen that needs the matrix code rain effect.
/// Used by AIBrainCard, AI chat screens, and home screens.
class MatrixRainPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<String> codes;
  final int numColumns;

  static const List<String> defaultCodes = [
    'NEC210', 'NEC250', '#12AWG', 'GFCI', 'AFCI', '200A',
    'UPC301', 'HVAC', 'CFM', 'R410A', 'SEER', '30A240',
    'ART100', 'EMT¾', 'AWG10', 'IMC3', 'P=IR', '120V',
  ];

  late final List<ColumnData> _columns;

  MatrixRainPainter({
    required this.progress,
    this.color = crmEmerald,
    this.codes = defaultCodes,
    this.numColumns = 12,
  }) {
    _columns = List.generate(numColumns, (i) {
      final seed = i * 73 + 17;
      return ColumnData(
        code: codes[i % codes.length],
        speed: 1.5 + (seed % 100) / 100.0,
        phase: (seed % 100) / 100.0,
        xOffset: (seed % 10) - 5.0,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final colSpacing = size.width / (numColumns + 1);
    const charH = 16.0;

    final textStyle = TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
    );

    for (int c = 0; c < numColumns; c++) {
      final col = _columns[c];
      final code = col.code;

      final x = (c + 1) * colSpacing + col.xOffset;

      final totalTravel = size.height + code.length * charH + 80;
      final yOffset = ((progress * col.speed + col.phase) * totalTravel) % totalTravel;
      final headY = yOffset - 40;

      for (int i = 0; i < code.length; i++) {
        final y = headY + i * charH;

        if (y < -charH || y > size.height + charH) continue;

        double alpha = i == 0 ? 0.85 : (0.65 - i * 0.08).clamp(0.12, 0.65);
        if (y < 30) alpha *= (y + charH) / 40;
        if (y > size.height - 35) alpha *= (size.height - y + 10) / 45;
        if (alpha < 0.08) continue;

        if (i < 2 && alpha > 0.3) {
          final glowPaint = Paint()
            ..color = color.withValues(alpha: alpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(x + 4, y + 6), 8, glowPaint);
        }

        final paragraph = _buildParagraph(
          code[i],
          textStyle.copyWith(
            color: color.withValues(alpha: alpha),
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
          ),
        );
        canvas.drawParagraph(paragraph, Offset(x, y));
      }
    }
  }

  static ui.Paragraph _buildParagraph(String text, TextStyle style) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: TextDirection.ltr,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontFamily: style.fontFamily,
    ))
      ..pushStyle(ui.TextStyle(
        color: style.color,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontFamily: style.fontFamily,
      ))
      ..addText(text);
    return builder.build()..layout(const ui.ParagraphConstraints(width: 20));
  }

  @override
  bool shouldRepaint(covariant MatrixRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Pre-computed column configuration for matrix rain
class ColumnData {
  final String code;
  final double speed;
  final double phase;
  final double xOffset;

  const ColumnData({
    required this.code,
    required this.speed,
    required this.phase,
    required this.xOffset,
  });
}
