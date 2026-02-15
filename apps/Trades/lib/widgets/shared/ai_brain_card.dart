import 'package:flutter/material.dart';

import '../../theme/zafto_colors.dart';
import 'matrix_rain_painter.dart';

/// AI Brain Card — Premium Industrial Design with Screws & Matrix Animation
///
/// Reusable across all role home screens (owner, tech, inspector, etc.)
class AIBrainCard extends StatefulWidget {
  final ZaftoColors colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String subtitle;

  const AIBrainCard({
    super.key,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
    this.subtitle = 'Create a bid, start a job, or ask me anything',
  });

  @override
  State<AIBrainCard> createState() => _AIBrainCardState();
}

class _AIBrainCardState extends State<AIBrainCard> with SingleTickerProviderStateMixin {
  late AnimationController _matrixController;

  @override
  void initState() {
    super.initState();
    _matrixController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _matrixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Matrix code rain background
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _matrixController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: MatrixRainPainter(
                        progress: _matrixController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              // Gradient overlay for depth
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
              // Corner screws
              buildCornerScrew(8, 8),
              buildCornerScrew(null, 8, right: 8),
              buildCornerScrew(8, null, bottom: 8),
              buildCornerScrew(null, null, right: 8, bottom: 8),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CustomPaint(
                        painter: IndustrialZPainter(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to work',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decorative corner screw
  static Widget buildCornerScrew(double? left, double? top, {double? right, double? bottom}) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF333333), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

/// Industrial Z mark with glow effect
///
/// Reusable across AI brain cards, AI chat screens, etc.
class IndustrialZPainter extends CustomPainter {
  final Color color;

  IndustrialZPainter({this.color = crmEmerald});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final margin = size.width * 0.24;
    final strokeWidth = size.width * 0.09;

    Path createZ() {
      return Path()
        ..moveTo(margin, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin);
    }

    // Glow layer
    paint.color = color.withValues(alpha: 0.25);
    paint.strokeWidth = strokeWidth * 3;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(createZ(), paint);
    paint.maskFilter = null;

    // Main Z stroke
    paint.color = color;
    paint.strokeWidth = strokeWidth * 1.3;
    canvas.drawPath(createZ(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
