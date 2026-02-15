import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// ZAFTO Logo System
///
/// Two variants:
/// - ZaftoMark() - "ZAFTO CONTRACTOR" stacked text logo
/// - ZaftoMark.zMark() - The Z glyph with offset echo (for AI assistant, icons)
///
/// Usage:
/// ```dart
/// ZaftoMark(size: 40, color: colors.textPrimary) // Full logo
/// ZaftoMark.zMark(size: 32, color: colors.accentPrimary) // Just Z
/// ```

class ZaftoMark extends StatefulWidget {
  final double size;
  final Color color;
  final bool animate;
  final double glowIntensity;
  final bool _isZMark;

  /// Full "ZAFTO CONTRACTOR" stacked logo
  const ZaftoMark({
    super.key,
    this.size = 40,
    required this.color,
    this.animate = false,
    this.glowIntensity = 0.6,
  }) : _isZMark = false;

  /// Just the Z glyph with offset echo effect
  const ZaftoMark.zMark({
    super.key,
    this.size = 32,
    required this.color,
    this.animate = false,
    this.glowIntensity = 0.6,
  }) : _isZMark = true;

  @override
  State<ZaftoMark> createState() => _ZaftoMarkState();
}

class _ZaftoMarkState extends State<ZaftoMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _strokeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _strokeAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ZaftoMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isZMark) {
      // Z glyph version
      if (widget.animate) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _buildZMark(_glowAnimation.value, _strokeAnimation.value);
          },
        );
      }
      return _buildZMark(1.0, 1.0);
    } else {
      // Full text logo version
      if (widget.animate) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _buildTextLogo(_glowAnimation.value);
          },
        );
      }
      return _buildTextLogo(1.0);
    }
  }

  /// Builds the Z glyph with offset echo effect
  Widget _buildZMark(double glowMultiplier, double strokeMultiplier) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ZMarkPainter(
          color: widget.color,
          glowIntensity: widget.glowIntensity * glowMultiplier,
          strokeMultiplier: strokeMultiplier,
        ),
      ),
    );
  }

  /// Builds the "ZAFTO CONTRACTOR" stacked text logo
  Widget _buildTextLogo(double glowMultiplier) {
    final glowColor =
        widget.color.withValues(alpha: 0.4 * widget.glowIntensity * glowMultiplier);
    final fontSize = widget.size * 0.85;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ZAFTO - Main text
        Text(
          'ZAFTO',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: fontSize * 0.15,
            height: 1.0,
            color: widget.color,
            shadows: widget.glowIntensity > 0
                ? [
                    Shadow(
                      color: glowColor,
                      blurRadius: 8 * glowMultiplier,
                    ),
                    Shadow(
                      color: glowColor,
                      blurRadius: 16 * glowMultiplier,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: widget.size * 0.05),
        // TRADES - Secondary text
        Text(
          'CONTRACTOR',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize * 0.48,
            fontWeight: FontWeight.w700,
            letterSpacing: fontSize * 0.35,
            height: 1.0,
            color: widget.color.withValues(alpha: 0.7),
            shadows: widget.glowIntensity > 0
                ? [
                    Shadow(
                      color: glowColor.withValues(alpha: 0.3),
                      blurRadius: 4 * glowMultiplier,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the Z mark with offset echo effect and glow
class _ZMarkPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final double strokeMultiplier;

  _ZMarkPainter({
    required this.color,
    this.glowIntensity = 0.6,
    this.strokeMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale factor
    final s = size.width / 44;
    final margin = 10 * s;
    final baseStrokeWidth = 2.5 * s;

    Path createZ() {
      return Path()
        ..moveTo(margin, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin);
    }

    // Glow layer (blur effect simulation)
    if (glowIntensity > 0) {
      paint.color = color.withValues(alpha: 0.15 * glowIntensity);
      paint.strokeWidth = baseStrokeWidth * 2.5;
      paint.maskFilter =
          ui.MaskFilter.blur(ui.BlurStyle.normal, 3 * s * glowIntensity);
      canvas.drawPath(createZ(), paint);
      paint.maskFilter = null;
    }

    // Back shadow (deepest) - offset 6,6 in SVG coords (scaled to 4,4)
    paint.color = color.withValues(alpha: 0.08 * (0.5 + glowIntensity * 0.5));
    paint.strokeWidth = baseStrokeWidth;
    canvas.save();
    canvas.translate(4 * s, 4 * s);
    canvas.drawPath(createZ(), paint);
    canvas.restore();

    // Middle shadow - offset 3,3 in SVG coords (scaled to 2,2)
    paint.color = color.withValues(alpha: 0.18 * (0.5 + glowIntensity * 0.5));
    canvas.save();
    canvas.translate(2 * s, 2 * s);
    canvas.drawPath(createZ(), paint);
    canvas.restore();

    // Front Z (main) - with slight glow
    if (glowIntensity > 0.3) {
      paint.color = color.withValues(alpha: 0.3);
      paint.strokeWidth = baseStrokeWidth * 1.8 * strokeMultiplier;
      paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 1.5 * s);
      canvas.drawPath(createZ(), paint);
      paint.maskFilter = null;
    }

    // Front Z (crisp)
    paint.color = color;
    paint.strokeWidth = baseStrokeWidth * 1.1 * strokeMultiplier;
    canvas.drawPath(createZ(), paint);
  }

  @override
  bool shouldRepaint(covariant _ZMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.strokeMultiplier != strokeMultiplier;
}

/// Horizontal version of the logo for app bars and headers
class ZaftoMarkHorizontal extends StatelessWidget {
  final double height;
  final Color color;
  final double glowIntensity;

  const ZaftoMarkHorizontal({
    super.key,
    this.height = 32,
    required this.color,
    this.glowIntensity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = color.withValues(alpha: 0.4 * glowIntensity);
    final mainFontSize = height * 0.75;
    final subFontSize = height * 0.38;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'ZAFTO',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: mainFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: mainFontSize * 0.12,
            color: color,
            shadows: glowIntensity > 0
                ? [
                    Shadow(color: glowColor, blurRadius: 8),
                    Shadow(color: glowColor, blurRadius: 16),
                  ]
                : null,
          ),
        ),
        SizedBox(width: height * 0.2),
        Text(
          'CONTRACTOR',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: subFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: subFontSize * 0.2,
            color: color.withValues(alpha: 0.6),
            shadows: glowIntensity > 0
                ? [
                    Shadow(
                        color: glowColor.withValues(alpha: 0.3), blurRadius: 4)
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
