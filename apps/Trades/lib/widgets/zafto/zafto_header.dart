import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ZAFTO Trades Header Logo with Hazard Stripes
///
/// Premium industrial header with yellow/black diagonal hazard bars
/// above and below the "ZAFTO TRADES" text.
///
/// Design: Steel-cut precision aesthetic with warning stripe motif
class ZaftoHazardHeader extends StatelessWidget {
  final double height;
  final Color primaryColor;
  final Color stripeColor;

  const ZaftoHazardHeader({
    super.key,
    this.height = 48,
    this.primaryColor = Colors.white,
    this.stripeColor = const Color(0xFFFFD600), // Trades yellow (hazard warning)
  });

  @override
  Widget build(BuildContext context) {
    final stripeHeight = height * 0.12;
    final textHeight = height * 0.76;

    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top hazard stripe bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: stripeHeight,
              child: CustomPaint(
                painter: _HazardStripePainter(stripeColor: stripeColor),
                size: Size.infinite,
              ),
            ),
          ),

          // ZAFTO TRADES text
          SizedBox(
            height: textHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ZAFTO',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: textHeight * 0.7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: textHeight * 0.25),
                Text(
                  'TRADES',
                  style: TextStyle(
                    color: stripeColor,
                    fontSize: textHeight * 0.45,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Bottom hazard stripe bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: stripeHeight,
              child: CustomPaint(
                painter: _HazardStripePainter(stripeColor: stripeColor),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact hazard header for smaller spaces
class ZaftoHazardHeaderCompact extends StatelessWidget {
  final double height;
  final Color primaryColor;
  final Color stripeColor;

  const ZaftoHazardHeaderCompact({
    super.key,
    this.height = 36,
    this.primaryColor = Colors.white,
    this.stripeColor = const Color(0xFFFFD600), // Trades yellow (hazard warning)
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left hazard stripe (vertical)
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: SizedBox(
            width: 4,
            height: height,
            child: CustomPaint(
              painter: _HazardStripePainter(
                stripeColor: stripeColor,
                vertical: true,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Text
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZAFTO',
              style: TextStyle(
                color: primaryColor,
                fontSize: height * 0.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.0,
              ),
            ),
            Text(
              'TRADES',
              style: TextStyle(
                color: stripeColor,
                fontSize: height * 0.28,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                height: 1.2,
              ),
            ),
          ],
        ),

        const SizedBox(width: 10),
        // Right hazard stripe (vertical)
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: SizedBox(
            width: 4,
            height: height,
            child: CustomPaint(
              painter: _HazardStripePainter(
                stripeColor: stripeColor,
                vertical: true,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints diagonal hazard stripes (orange/black warning pattern)
class _HazardStripePainter extends CustomPainter {
  final Color stripeColor;
  final bool vertical;

  _HazardStripePainter({
    required this.stripeColor,
    this.vertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = const Color(0xFF1A1A1A);
    final orangePaint = Paint()..color = stripeColor;

    // Fill background black
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), blackPaint);

    // Draw diagonal orange stripes
    final stripeWidth = vertical ? size.width * 1.5 : size.height * 1.5;
    final stripeSpacing = stripeWidth * 2;

    orangePaint.strokeWidth = stripeWidth;
    orangePaint.style = PaintingStyle.stroke;

    // Calculate how many stripes we need
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final numStripes = (diagonal / stripeSpacing).ceil() + 4;

    for (int i = -numStripes; i < numStripes; i++) {
      final offset = i * stripeSpacing;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        orangePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HazardStripePainter oldDelegate) =>
      oldDelegate.stripeColor != stripeColor || oldDelegate.vertical != vertical;
}
