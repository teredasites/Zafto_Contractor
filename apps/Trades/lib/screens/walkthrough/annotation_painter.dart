// ZAFTO Annotation Painter — CustomPainter for Photo Annotations
// Renders all annotation types (draw, arrow, circle, rectangle, text,
// measurement, stamp) onto the photo canvas overlay.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/annotation.dart';

// Paints completed and in-progress annotations onto the canvas
class AnnotationPainter extends CustomPainter {
  final List<PhotoAnnotation> annotations;
  final PhotoAnnotation? currentAnnotation;

  AnnotationPainter({
    required this.annotations,
    this.currentAnnotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      _paintAnnotation(canvas, size, annotation);
    }

    if (currentAnnotation != null) {
      _paintAnnotation(canvas, size, currentAnnotation!);
    }
  }

  void _paintAnnotation(
      Canvas canvas, Size size, PhotoAnnotation annotation) {
    switch (annotation.type) {
      case AnnotationType.draw:
        _paintDraw(canvas, annotation);
        break;
      case AnnotationType.arrow:
        _paintArrow(canvas, annotation);
        break;
      case AnnotationType.circle:
        _paintCircle(canvas, annotation);
        break;
      case AnnotationType.rectangle:
        _paintRectangle(canvas, annotation);
        break;
      case AnnotationType.text:
        _paintText(canvas, annotation);
        break;
      case AnnotationType.measurement:
        _paintMeasurement(canvas, annotation);
        break;
      case AnnotationType.stamp:
        _paintStamp(canvas, annotation);
        break;
    }
  }

  // Freehand drawing — connected line segments along collected points
  void _paintDraw(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(
          annotation.points.first.dx, annotation.points.first.dy);

    for (int i = 1; i < annotation.points.length; i++) {
      path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  // Arrow — line from start to end with filled arrowhead triangle
  void _paintArrow(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final start = annotation.points.first;
    final end = annotation.points.last;

    final linePaint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw the shaft
    canvas.drawLine(start, end, linePaint);

    // Draw the arrowhead
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);
    final arrowLength = annotation.strokeWidth * 5;
    const arrowAngle = math.pi / 6; // 30 degrees

    final arrowPaint = Paint()
      ..color = annotation.color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLength * math.cos(angle - arrowAngle),
        end.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        end.dx - arrowLength * math.cos(angle + arrowAngle),
        end.dy - arrowLength * math.sin(angle + arrowAngle),
      )
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  // Circle — from center (first point) with radius to second point
  void _paintCircle(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final center = annotation.points.first;
    final edge = annotation.points.last;
    final radius = (edge - center).distance;

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);
  }

  // Rectangle — from corner (first point) to opposite corner (last point)
  void _paintRectangle(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final p1 = annotation.points.first;
    final p2 = annotation.points.last;

    final rect = Rect.fromPoints(p1, p2);

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
  }

  // Text — rendered at tap position with background
  void _paintText(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.text == null || annotation.text!.isEmpty) return;
    if (annotation.points.isEmpty) return;

    final position = annotation.points.first;
    final textFontSize = annotation.fontSize ?? 18.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: annotation.text!,
        style: TextStyle(
          color: annotation.color,
          fontSize: textFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    // Draw semi-transparent background for readability
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - 6,
        position.dy - 4,
        textPainter.width + 12,
        textPainter.height + 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(canvas, position);
  }

  // Measurement — line with end ticks and distance label
  void _paintMeasurement(
      Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final start = annotation.points.first;
    final end = annotation.points.last;

    final linePaint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main measurement line
    canvas.drawLine(start, end, linePaint);

    // Draw end ticks perpendicular to the line
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);
    final perpAngle = angle + math.pi / 2;
    final tickLength = annotation.strokeWidth * 4;

    // Start tick
    canvas.drawLine(
      Offset(
        start.dx + tickLength * math.cos(perpAngle),
        start.dy + tickLength * math.sin(perpAngle),
      ),
      Offset(
        start.dx - tickLength * math.cos(perpAngle),
        start.dy - tickLength * math.sin(perpAngle),
      ),
      linePaint,
    );

    // End tick
    canvas.drawLine(
      Offset(
        end.dx + tickLength * math.cos(perpAngle),
        end.dy + tickLength * math.sin(perpAngle),
      ),
      Offset(
        end.dx - tickLength * math.cos(perpAngle),
        end.dy - tickLength * math.sin(perpAngle),
      ),
      linePaint,
    );

    // Distance label — use custom text from metadata if set, otherwise pixel distance
    final pixelDistance = (end - start).distance;
    final displayText = annotation.text ??
        annotation.metadata['displayText'] as String? ??
        '${pixelDistance.toStringAsFixed(0)} px';

    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: annotation.color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    // Background behind measurement label
    final labelBg = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        midpoint.dx - textPainter.width / 2 - 6,
        midpoint.dy - textPainter.height - 8,
        textPainter.width + 12,
        textPainter.height + 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, labelBg);

    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height - 4,
      ),
    );
  }

  // Stamp — colored rounded rectangle badge with text label
  void _paintStamp(Canvas canvas, PhotoAnnotation annotation) {
    if (annotation.points.isEmpty) return;

    final position = annotation.points.first;
    final stampText = annotation.text ?? 'NOTE';

    // Determine stamp color from metadata or annotation color
    final stampTypeName =
        annotation.metadata['stampType'] as String?;
    final stampColor = stampTypeName != null
        ? StampType.fromString(stampTypeName).color
        : annotation.color;

    final textPainter = TextPainter(
      text: TextSpan(
        text: stampText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    const paddingH = 14.0;
    const paddingV = 8.0;
    final badgeWidth = textPainter.width + paddingH * 2;
    final badgeHeight = textPainter.height + paddingV * 2;

    // Badge background
    final bgPaint = Paint()..color = stampColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - badgeWidth / 2,
        position.dy - badgeHeight / 2,
        badgeWidth,
        badgeHeight,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Badge border for contrast
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bgRect, borderPaint);

    // Stamp text centered in badge
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.currentAnnotation != currentAnnotation;
  }
}
