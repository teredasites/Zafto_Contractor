// ZAFTO Mini Gantt Widget
// GC10: Compact Gantt chart for embedding in job detail, dashboard cards, etc.
// Shows task bars with critical path highlighting, progress fill, milestones.
// Tap navigates to full Gantt screen.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/zafto_colors.dart';

/// Lightweight task data for mini gantt rendering.
class MiniGanttTask {
  final String id;
  final String name;
  final DateTime? start;
  final DateTime? finish;
  final double percentComplete;
  final bool isCritical;
  final bool isMilestone;

  const MiniGanttTask({
    required this.id,
    required this.name,
    this.start,
    this.finish,
    this.percentComplete = 0,
    this.isCritical = false,
    this.isMilestone = false,
  });
}

class MiniGanttWidget extends StatelessWidget {
  final List<MiniGanttTask> tasks;
  final ZaftoColors colors;
  final double height;
  final VoidCallback? onTap;

  const MiniGanttWidget({
    super.key,
    required this.tasks,
    required this.colors,
    this.height = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No scheduled tasks',
            style: TextStyle(fontSize: 12, color: colors.textQuaternary),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: _MiniGanttPainter(
              tasks: tasks,
              colors: colors,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _MiniGanttPainter extends CustomPainter {
  final List<MiniGanttTask> tasks;
  final ZaftoColors colors;

  _MiniGanttPainter({required this.tasks, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (tasks.isEmpty) return;

    // Calculate date range
    DateTime? earliest;
    DateTime? latest;
    for (final t in tasks) {
      if (t.start != null) {
        earliest = earliest == null || t.start!.isBefore(earliest) ? t.start! : earliest;
      }
      if (t.finish != null) {
        latest = latest == null || t.finish!.isAfter(latest) ? t.finish! : latest;
      }
    }

    if (earliest == null || latest == null) return;

    // Add 1 day padding on each side
    final rangeStart = earliest.subtract(const Duration(days: 1));
    final rangeEnd = latest.add(const Duration(days: 1));
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    if (totalDays <= 0) return;

    final dayWidth = size.width / totalDays;

    // Filter to visible tasks (with dates), limit to top N
    final visibleTasks = tasks.where((t) => t.start != null && t.finish != null).toList();
    final maxRows = math.min(visibleTasks.length, (size.height / 18).floor().clamp(1, 20));
    final displayTasks = visibleTasks.take(maxRows).toList();

    final barHeight = math.min(14.0, (size.height / maxRows) - 4);
    final rowHeight = barHeight + 4;

    // Draw today line
    final today = DateTime.now();
    if (today.isAfter(rangeStart) && today.isBefore(rangeEnd)) {
      final todayX = today.difference(rangeStart).inDays * dayWidth;
      final todayPaint = Paint()
        ..color = colors.accentError.withValues(alpha: 0.5)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(todayX, 0), Offset(todayX, size.height), todayPaint);
    }

    // Draw task bars
    for (int i = 0; i < displayTasks.length; i++) {
      final task = displayTasks[i];
      final startX = task.start!.difference(rangeStart).inDays * dayWidth;
      final endX = task.finish!.difference(rangeStart).inDays * dayWidth;
      final y = i * rowHeight + 2;
      final taskWidth = math.max(endX - startX, 4.0);

      if (task.isMilestone) {
        // Diamond
        final cx = startX;
        final cy = y + barHeight / 2;
        final r = barHeight / 2 - 1;
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = task.isCritical ? colors.accentError : colors.accentPrimary,
        );
      } else {
        // Background bar
        final bgColor = task.isCritical
            ? colors.accentError.withValues(alpha: 0.2)
            : colors.accentPrimary.withValues(alpha: 0.15);
        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, y, taskWidth, barHeight),
          const Radius.circular(2),
        );
        canvas.drawRRect(bgRect, Paint()..color = bgColor);

        // Progress fill
        if (task.percentComplete > 0) {
          final progressWidth = taskWidth * (task.percentComplete / 100).clamp(0.0, 1.0);
          final progressColor = task.isCritical ? colors.accentError : colors.accentPrimary;
          final progressRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(startX, y, progressWidth, barHeight),
            const Radius.circular(2),
          );
          canvas.drawRRect(progressRect, Paint()..color = progressColor.withValues(alpha: 0.7));
        }

        // Border
        final borderColor = task.isCritical
            ? colors.accentError.withValues(alpha: 0.5)
            : colors.accentPrimary.withValues(alpha: 0.3);
        canvas.drawRRect(
          bgRect,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }

    // "More" indicator if truncated
    if (visibleTasks.length > maxRows) {
      final remaining = visibleTasks.length - maxRows;
      final tp = TextPainter(
        text: TextSpan(
          text: '+$remaining more',
          style: TextStyle(fontSize: 9, color: colors.textQuaternary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 4, size.height - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGanttPainter oldDelegate) {
    return tasks != oldDelegate.tasks;
  }
}
