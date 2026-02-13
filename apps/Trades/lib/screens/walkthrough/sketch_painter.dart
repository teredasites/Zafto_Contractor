// ZAFTO Sketch Painter — CustomPainter for Floor Plan Canvas
// Renders grid, walls, doors, windows, fixtures, labels, dimensions, rooms.
// Professional architectural drawing style: white bg, gray grid, black walls.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/floor_plan_elements.dart';

class SketchPainter extends CustomPainter {
  final FloorPlanData planData;
  final String? selectedElementId;
  final String? selectedElementType;
  final Wall? ghostWall;
  final Offset? snapIndicator;
  final Offset? ghostDimensionStart;
  final double scale;
  final MeasurementUnit units;
  final Set<String> multiSelectedIds;
  final List<Offset>? lassoPoints;

  // Colors
  static const _gridColor = Color(0xFFE5E7EB);
  static const _gridBoldColor = Color(0xFFD1D5DB);
  static const _wallColor = Color(0xFF1F2937);
  static const _wallFillColor = Color(0xFF374151);
  static const _doorColor = Color(0xFF2563EB);
  static const _windowColor = Color(0xFF0EA5E9);
  static const _fixtureColor = Color(0xFF6B7280);
  static const _fixtureFillColor = Color(0xFFF3F4F6);
  static const _labelColor = Color(0xFF111827);
  static const _dimensionColor = Color(0xFFDC2626);
  static const _roomFillColor = Color(0x0D3B82F6);
  static const _roomLabelColor = Color(0xFF6B7280);
  static const _selectionColor = Color(0xFF3B82F6);
  static const _ghostColor = Color(0x804B5563);
  static const _snapColor = Color(0xFFEF4444);

  SketchPainter({
    required this.planData,
    this.selectedElementId,
    this.selectedElementType,
    this.ghostWall,
    this.snapIndicator,
    this.ghostDimensionStart,
    this.scale = 4.0,
    this.units = MeasurementUnit.imperial,
    this.multiSelectedIds = const {},
    this.lassoPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawRooms(canvas);
    _drawWalls(canvas);
    _drawArcWalls(canvas);
    _drawDoors(canvas);
    _drawWindows(canvas);
    _drawFixtures(canvas);
    _drawLabels(canvas);
    _drawDimensions(canvas);
    _drawGhostWall(canvas);
    _drawLasso(canvas);
    _drawSnapIndicator(canvas);
  }

  bool _isMultiSelected(String id) => multiSelectedIds.contains(id);

  // =========================================================================
  // GRID
  // =========================================================================

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.5;
    final boldPaint = Paint()
      ..color = _gridBoldColor
      ..strokeWidth = 1.0;

    // Grid spacing: 1 foot = 12 inches * scale
    final minorSpacing = 12.0 * scale; // 1 foot
    final majorSpacing = 60.0 * scale; // 5 feet

    // Extend grid well beyond visible canvas for pan/zoom
    final maxDim = max(size.width, size.height) * 3;

    // Minor grid (1ft)
    if (minorSpacing > 4) {
      // Only draw if spacing is visible
      for (double x = 0; x < maxDim; x += minorSpacing) {
        canvas.drawLine(Offset(x, -maxDim), Offset(x, maxDim), gridPaint);
      }
      for (double x = -minorSpacing; x > -maxDim; x -= minorSpacing) {
        canvas.drawLine(Offset(x, -maxDim), Offset(x, maxDim), gridPaint);
      }
      for (double y = 0; y < maxDim; y += minorSpacing) {
        canvas.drawLine(Offset(-maxDim, y), Offset(maxDim, y), gridPaint);
      }
      for (double y = -minorSpacing; y > -maxDim; y -= minorSpacing) {
        canvas.drawLine(Offset(-maxDim, y), Offset(maxDim, y), gridPaint);
      }
    }

    // Major grid (5ft)
    for (double x = 0; x < maxDim; x += majorSpacing) {
      canvas.drawLine(Offset(x, -maxDim), Offset(x, maxDim), boldPaint);
    }
    for (double x = -majorSpacing; x > -maxDim; x -= majorSpacing) {
      canvas.drawLine(Offset(x, -maxDim), Offset(x, maxDim), boldPaint);
    }
    for (double y = 0; y < maxDim; y += majorSpacing) {
      canvas.drawLine(Offset(-maxDim, y), Offset(maxDim, y), boldPaint);
    }
    for (double y = -majorSpacing; y > -maxDim; y -= majorSpacing) {
      canvas.drawLine(Offset(-maxDim, y), Offset(maxDim, y), boldPaint);
    }
  }

  // =========================================================================
  // ROOMS (semi-transparent fills)
  // =========================================================================

  void _drawRooms(Canvas canvas) {
    final fillPaint = Paint()
      ..color = _roomFillColor
      ..style = PaintingStyle.fill;

    for (final room in planData.rooms) {
      // Build polygon from wall start points
      final points = <Offset>[];
      for (final wallId in room.wallIds) {
        final wall = planData.wallById(wallId);
        if (wall != null) {
          points.add(_toCanvas(wall.start));
        }
      }
      if (points.length >= 3) {
        final path = Path()..moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.close();
        canvas.drawPath(path, fillPaint);
      }

      // Room label
      final center = _toCanvas(room.center);
      _drawText(
        canvas,
        room.name,
        center,
        fontSize: 11,
        color: _roomLabelColor,
        bold: true,
      );
      // Area label below name — unit-aware
      if (room.area > 0) {
        _drawText(
          canvas,
          _formatArea(room.area),
          Offset(center.dx, center.dy + 14),
          fontSize: 9,
          color: _roomLabelColor,
        );
      }
    }
  }

  // =========================================================================
  // WALLS
  // =========================================================================

  void _drawWalls(Canvas canvas) {
    for (final wall in planData.walls) {
      final isSelected =
          (selectedElementType == 'wall' && selectedElementId == wall.id) ||
              _isMultiSelected(wall.id);
      _drawSingleWall(canvas, wall, isSelected: isSelected);
    }
  }

  void _drawSingleWall(Canvas canvas, Wall wall, {bool isSelected = false}) {
    final start = _toCanvas(wall.start);
    final end = _toCanvas(wall.end);
    final thickness = wall.thickness * scale;

    // Wall fill
    final fillPaint = Paint()
      ..color = isSelected ? _selectionColor.withValues(alpha: 0.3) : _wallFillColor
      ..style = PaintingStyle.fill;

    // Wall outline
    final outlinePaint = Paint()
      ..color = isSelected ? _selectionColor : _wallColor
      ..strokeWidth = isSelected ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;

    // Build wall rectangle along its direction
    final dir = end - start;
    final len = dir.distance;
    if (len == 0) return;

    final unitDir = Offset(dir.dx / len, dir.dy / len);
    final normal = Offset(-unitDir.dy, unitDir.dx);
    final halfThick = thickness / 2;

    final corners = [
      Offset(start.dx + normal.dx * halfThick, start.dy + normal.dy * halfThick),
      Offset(end.dx + normal.dx * halfThick, end.dy + normal.dy * halfThick),
      Offset(end.dx - normal.dx * halfThick, end.dy - normal.dy * halfThick),
      Offset(start.dx - normal.dx * halfThick, start.dy - normal.dy * halfThick),
    ];

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);

    // Draw endpoint dots (small when unselected, large handles when selected)
    if (isSelected) {
      // Selection handles — white border circle + blue fill (draggable)
      final handleBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final handleFillPaint = Paint()
        ..color = _selectionColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(start, 8.0, handleBorderPaint);
      canvas.drawCircle(start, 6.0, handleFillPaint);
      canvas.drawCircle(end, 8.0, handleBorderPaint);
      canvas.drawCircle(end, 6.0, handleFillPaint);

      // Wall thickness label (centered on wall)
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final wallLen = sqrt(dx * dx + dy * dy);
      if (wallLen > 0) {
        final perpX = -dy / wallLen * 18;
        final perpY = dx / wallLen * 18;
        _drawText(
          canvas,
          _formatDim(wall.thickness),
          Offset(mid.dx + perpX, mid.dy + perpY),
          fontSize: 9,
          color: _selectionColor,
          bold: true,
        );
      }
    } else {
      final dotPaint = Paint()
        ..color = _wallColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(start, 3.0, dotPaint);
      canvas.drawCircle(end, 3.0, dotPaint);
    }
  }

  // =========================================================================
  // ARC WALLS
  // =========================================================================

  void _drawArcWalls(Canvas canvas) {
    for (final arc in planData.arcWalls) {
      final isSelected =
          (selectedElementType == 'arcWall' && selectedElementId == arc.id) ||
              _isMultiSelected(arc.id);
      _drawSingleArcWall(canvas, arc, isSelected: isSelected);
    }
  }

  void _drawSingleArcWall(Canvas canvas, ArcWall arc,
      {bool isSelected = false}) {
    final center = _toCanvas(arc.center);
    final outerRadius = (arc.radius + arc.thickness / 2) * scale;
    final innerRadius = (arc.radius - arc.thickness / 2) * scale;

    final fillPaint = Paint()
      ..color = isSelected
          ? _selectionColor.withValues(alpha: 0.3)
          : _wallFillColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = isSelected ? _selectionColor : _wallColor
      ..strokeWidth = isSelected ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;

    // Build arc path as thick band (outer arc + inner arc reversed)
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    final path = Path()
      ..addArc(outerRect, arc.startAngle, arc.sweepAngle);
    // Connect outer end to inner end
    final innerEndAngle = arc.startAngle + arc.sweepAngle;
    path.lineTo(
      center.dx + innerRadius * cos(innerEndAngle),
      center.dy + innerRadius * sin(innerEndAngle),
    );
    // Inner arc in reverse
    path.arcTo(innerRect, innerEndAngle, -arc.sweepAngle, false);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);

    // Endpoint dots
    if (isSelected) {
      final startOuter = Offset(
        center.dx + outerRadius * cos(arc.startAngle),
        center.dy + outerRadius * sin(arc.startAngle),
      );
      final endOuter = Offset(
        center.dx + outerRadius * cos(arc.startAngle + arc.sweepAngle),
        center.dy + outerRadius * sin(arc.startAngle + arc.sweepAngle),
      );
      final handleBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final handleFill = Paint()
        ..color = _selectionColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startOuter, 7, handleBorder);
      canvas.drawCircle(startOuter, 5, handleFill);
      canvas.drawCircle(endOuter, 7, handleBorder);
      canvas.drawCircle(endOuter, 5, handleFill);

      // Arc length label
      final midAngle = arc.startAngle + arc.sweepAngle / 2;
      final labelPos = Offset(
        center.dx + (arc.radius * scale + 18) * cos(midAngle),
        center.dy + (arc.radius * scale + 18) * sin(midAngle),
      );
      _drawText(canvas, _formatDim(arc.arcLength), labelPos,
          fontSize: 9, color: _selectionColor, bold: true);
    }
  }

  // =========================================================================
  // DOORS
  // =========================================================================

  void _drawDoors(Canvas canvas) {
    for (final door in planData.doors) {
      final wall = planData.wallById(door.wallId);
      if (wall == null) continue;
      final isSelected =
          selectedElementType == 'door' && selectedElementId == door.id;
      _drawSingleDoor(canvas, door, wall, isSelected: isSelected);
    }
  }

  void _drawSingleDoor(Canvas canvas, DoorPlacement door, Wall wall,
      {bool isSelected = false}) {
    final wallStart = _toCanvas(wall.start);
    final wallEnd = _toCanvas(wall.end);
    final doorPos = Offset(
      wallStart.dx + (wallEnd.dx - wallStart.dx) * door.position,
      wallStart.dy + (wallEnd.dy - wallStart.dy) * door.position,
    );

    final doorWidth = door.width * scale;
    final halfWidth = doorWidth / 2;
    final color = isSelected ? _selectionColor : _doorColor;

    final wallDir = wallEnd - wallStart;
    final wallLen = wallDir.distance;
    if (wallLen == 0) return;
    final unitDir = Offset(wallDir.dx / wallLen, wallDir.dy / wallLen);
    final normal = Offset(-unitDir.dy, unitDir.dx);

    switch (door.type) {
      case DoorType.single:
        _drawSingleDoorArc(canvas, doorPos, unitDir, normal, halfWidth, color,
            door.swingAngle);
        break;
      case DoorType.double_:
        // Two arcs mirrored
        final left =
            Offset(doorPos.dx - unitDir.dx * halfWidth / 2, doorPos.dy - unitDir.dy * halfWidth / 2);
        final right =
            Offset(doorPos.dx + unitDir.dx * halfWidth / 2, doorPos.dy + unitDir.dy * halfWidth / 2);
        _drawSingleDoorArc(
            canvas, left, unitDir, normal, halfWidth / 2, color, 90);
        _drawSingleDoorArc(canvas, right, unitDir,
            Offset(-normal.dx, -normal.dy), halfWidth / 2, color, 90);
        break;
      case DoorType.sliding:
        _drawSlidingDoor(canvas, doorPos, unitDir, halfWidth, color);
        break;
      case DoorType.pocket:
        _drawPocketDoor(canvas, doorPos, unitDir, halfWidth, color);
        break;
      case DoorType.french:
        // Two arcs both opening outward
        final left =
            Offset(doorPos.dx - unitDir.dx * halfWidth / 2, doorPos.dy - unitDir.dy * halfWidth / 2);
        final right =
            Offset(doorPos.dx + unitDir.dx * halfWidth / 2, doorPos.dy + unitDir.dy * halfWidth / 2);
        _drawSingleDoorArc(
            canvas, left, unitDir, normal, halfWidth / 2, color, 90);
        _drawSingleDoorArc(
            canvas, right, unitDir, normal, halfWidth / 2, color, 90);
        break;
      case DoorType.bifold:
        _drawBifoldDoor(canvas, doorPos, unitDir, halfWidth, color);
        break;
      case DoorType.garage:
        _drawGarageDoor(canvas, doorPos, unitDir, halfWidth, color);
        break;
    }

    // Gap in wall (white fill)
    final gapPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final wallThickness = wall.thickness * scale;

    // Rotate gap rect to align with wall
    canvas.save();
    canvas.translate(doorPos.dx, doorPos.dy);
    final angle = atan2(unitDir.dy, unitDir.dx);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: doorWidth,
        height: wallThickness + 2,
      ),
      gapPaint,
    );
    canvas.restore();
  }

  void _drawSingleDoorArc(Canvas canvas, Offset pos, Offset dir, Offset normal,
      double radius, Color color, double swingDeg) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Arc from wall direction to normal direction
    final startAngle = atan2(dir.dy, dir.dx);
    final sweepAngle = swingDeg * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Door line (the door panel)
    final endAngle = startAngle + sweepAngle;
    final panelEnd = Offset(
      pos.dx + radius * cos(endAngle),
      pos.dy + radius * sin(endAngle),
    );
    canvas.drawLine(pos, panelEnd, paint);
  }

  void _drawSlidingDoor(
      Canvas canvas, Offset pos, Offset dir, double halfWidth, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Two parallel lines with arrows
    final p1 = Offset(pos.dx - dir.dx * halfWidth, pos.dy - dir.dy * halfWidth);
    final p2 = Offset(pos.dx + dir.dx * halfWidth, pos.dy + dir.dy * halfWidth);
    final mid = pos;

    canvas.drawLine(p1, mid, paint);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Arrow on first half pointing right
    final arrowSize = 4.0 * scale;
    final arrowTip = Offset(mid.dx - dir.dx * 2, mid.dy - dir.dy * 2);
    canvas.drawLine(
      arrowTip,
      Offset(arrowTip.dx - dir.dx * arrowSize + dir.dy * arrowSize * 0.5,
          arrowTip.dy - dir.dy * arrowSize - dir.dx * arrowSize * 0.5),
      arrowPaint,
    );

    // Second half
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(mid, p2, dashPaint);
  }

  void _drawPocketDoor(
      Canvas canvas, Offset pos, Offset dir, double halfWidth, Color color) {
    // Dashed line receding into wall
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final p1 = Offset(pos.dx - dir.dx * halfWidth, pos.dy - dir.dy * halfWidth);

    // Solid half
    canvas.drawLine(p1, pos, paint);

    // Dashed half (into wall pocket)
    const dashLen = 4.0;
    final totalDist = halfWidth;
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double drawn = 0;
    bool dash = true;
    while (drawn < totalDist) {
      final segLen = min(dashLen, totalDist - drawn);
      final segStart = Offset(
        pos.dx + dir.dx * drawn,
        pos.dy + dir.dy * drawn,
      );
      final segEnd = Offset(
        pos.dx + dir.dx * (drawn + segLen),
        pos.dy + dir.dy * (drawn + segLen),
      );
      if (dash) canvas.drawLine(segStart, segEnd, dashPaint);
      drawn += segLen;
      dash = !dash;
    }

  }

  void _drawBifoldDoor(
      Canvas canvas, Offset pos, Offset dir, double halfWidth, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Zigzag pattern
    final p1 = Offset(pos.dx - dir.dx * halfWidth, pos.dy - dir.dy * halfWidth);
    final p2 = Offset(pos.dx + dir.dx * halfWidth, pos.dy + dir.dy * halfWidth);
    final normal = Offset(-dir.dy, dir.dx);
    final foldDepth = 6.0 * scale;
    final mid = pos;
    final fold1 = Offset(
      (p1.dx + mid.dx) / 2 + normal.dx * foldDepth,
      (p1.dy + mid.dy) / 2 + normal.dy * foldDepth,
    );
    final fold2 = Offset(
      (mid.dx + p2.dx) / 2 + normal.dx * foldDepth,
      (mid.dy + p2.dy) / 2 + normal.dy * foldDepth,
    );

    canvas.drawLine(p1, fold1, paint);
    canvas.drawLine(fold1, mid, paint);
    canvas.drawLine(mid, fold2, paint);
    canvas.drawLine(fold2, p2, paint);
  }

  void _drawGarageDoor(
      Canvas canvas, Offset pos, Offset dir, double halfWidth, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Thick line with hash marks (sectional segments)
    final p1 = Offset(pos.dx - dir.dx * halfWidth, pos.dy - dir.dy * halfWidth);
    final p2 = Offset(pos.dx + dir.dx * halfWidth, pos.dy + dir.dy * halfWidth);
    canvas.drawLine(p1, p2, paint);

    // Hash marks every 1/4 of width
    final normal = Offset(-dir.dy, dir.dx);
    final hashLen = 4.0 * scale;
    for (int i = 1; i < 4; i++) {
      final t = i / 4.0;
      final pt = Offset(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
      canvas.drawLine(
        Offset(pt.dx - normal.dx * hashLen, pt.dy - normal.dy * hashLen),
        Offset(pt.dx + normal.dx * hashLen, pt.dy + normal.dy * hashLen),
        paint..strokeWidth = 1.0,
      );
    }
  }

  // =========================================================================
  // WINDOWS
  // =========================================================================

  void _drawWindows(Canvas canvas) {
    for (final window in planData.windows) {
      final wall = planData.wallById(window.wallId);
      if (wall == null) continue;
      final isSelected =
          selectedElementType == 'window' && selectedElementId == window.id;
      _drawSingleWindow(canvas, window, wall, isSelected: isSelected);
    }
  }

  void _drawSingleWindow(Canvas canvas, WindowPlacement window, Wall wall,
      {bool isSelected = false}) {
    final wallStart = _toCanvas(wall.start);
    final wallEnd = _toCanvas(wall.end);
    final winPos = Offset(
      wallStart.dx + (wallEnd.dx - wallStart.dx) * window.position,
      wallStart.dy + (wallEnd.dy - wallStart.dy) * window.position,
    );

    final winWidth = window.width * scale;
    final halfWidth = winWidth / 2;
    final color = isSelected ? _selectionColor : _windowColor;

    final wallDir = wallEnd - wallStart;
    final wallLen = wallDir.distance;
    if (wallLen == 0) return;
    final unitDir = Offset(wallDir.dx / wallLen, wallDir.dy / wallLen);

    final wallThickness = wall.thickness * scale;
    final halfThick = wallThickness / 2;

    // Gap in wall (white fill)
    canvas.save();
    canvas.translate(winPos.dx, winPos.dy);
    final angle = atan2(unitDir.dy, unitDir.dx);
    canvas.rotate(angle);

    final gapPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: winWidth,
        height: wallThickness + 2,
      ),
      gapPaint,
    );

    // Three parallel lines (standard window symbol)
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final lineSpacing = halfThick * 0.6;

    for (int i = -1; i <= 1; i++) {
      final y = i * lineSpacing;
      canvas.drawLine(
        Offset(-halfWidth, y),
        Offset(halfWidth, y),
        linePaint,
      );
    }

    // End caps
    canvas.drawLine(
      Offset(-halfWidth, -lineSpacing),
      Offset(-halfWidth, lineSpacing),
      linePaint,
    );
    canvas.drawLine(
      Offset(halfWidth, -lineSpacing),
      Offset(halfWidth, lineSpacing),
      linePaint,
    );

    canvas.restore();
  }

  // =========================================================================
  // FIXTURES
  // =========================================================================

  void _drawFixtures(Canvas canvas) {
    for (final fixture in planData.fixtures) {
      final isSelected =
          (selectedElementType == 'fixture' && selectedElementId == fixture.id) ||
              _isMultiSelected(fixture.id);
      _drawSingleFixture(canvas, fixture, isSelected: isSelected);
    }
  }

  void _drawSingleFixture(Canvas canvas, FixturePlacement fixture,
      {bool isSelected = false}) {
    final pos = _toCanvas(fixture.position);
    final color = isSelected ? _selectionColor : _fixtureColor;
    final fillColor = isSelected
        ? _selectionColor.withValues(alpha: 0.1)
        : _fixtureFillColor;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(fixture.rotation * pi / 180);

    final outlinePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final s = scale; // shorthand

    switch (fixture.type) {
      case FixtureType.toilet:
        _drawToilet(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.sink:
        _drawSink(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.bathtub:
        _drawBathtub(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.shower:
        _drawShower(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.vanity:
        _drawVanity(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.stove:
        _drawStove(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.refrigerator:
        _drawRefrigerator(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.dishwasher:
        _drawDishwasher(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.microwave:
        _drawMicrowave(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.washer:
      case FixtureType.dryer:
        _drawWasherDryer(canvas, s, fillPaint, outlinePaint,
            isDryer: fixture.type == FixtureType.dryer);
        break;
      case FixtureType.waterHeater:
        _drawWaterHeater(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.furnace:
        _drawFurnace(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.acUnit:
        _drawACUnit(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.electricalPanel:
        _drawElectricalPanel(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.outlet:
        _drawOutlet(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.switchBox:
        _drawSwitch(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.stairs:
        _drawStairs(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.fireplace:
        _drawFireplace(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.closetRod:
        _drawClosetRod(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.desk:
        _drawDesk(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.bed:
        _drawBed(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.sofa:
        _drawSofa(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.table:
        _drawTable(canvas, s, fillPaint, outlinePaint);
        break;
      case FixtureType.custom:
        _drawCustom(canvas, s, fillPaint, outlinePaint);
        break;
    }

    canvas.restore();

    // Selection: rotation handle + bounding circle
    if (isSelected) {
      // Bounding circle (selection indicator)
      final selectPaint = Paint()
        ..color = _selectionColor.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 18 * scale, selectPaint);

      // Rotation handle — small circle with arc arrow above fixture
      final handleCenter = Offset(pos.dx, pos.dy - 22 * scale);
      final handleBg = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final handleFill = Paint()
        ..color = _selectionColor
        ..style = PaintingStyle.fill;
      final handleArc = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(handleCenter, 9, handleBg);
      canvas.drawCircle(handleCenter, 7, handleFill);
      // Arc arrow icon inside handle
      canvas.drawArc(
        Rect.fromCircle(center: handleCenter, radius: 4),
        -pi / 2,
        pi * 1.3,
        false,
        handleArc,
      );

      // Rotation degree label
      if (fixture.rotation != 0) {
        _drawText(
          canvas,
          '${fixture.rotation.round()}°',
          Offset(pos.dx + 22 * scale, pos.dy - 22 * scale),
          fontSize: 8,
          color: _selectionColor,
          bold: true,
        );
      }
    }

    // Label below fixture
    if (fixture.label != null && fixture.label!.isNotEmpty) {
      _drawText(
        canvas,
        fixture.label!,
        Offset(pos.dx, pos.dy + 16 * scale),
        fontSize: 9,
        color: color,
      );
    }
  }

  // -- Fixture drawing methods --

  void _drawToilet(Canvas canvas, double s, Paint fill, Paint outline) {
    // Oval bowl + circular tank
    final bowlRect = Rect.fromCenter(center: Offset(0, 2 * s), width: 14 * s, height: 16 * s);
    canvas.drawOval(bowlRect, fill);
    canvas.drawOval(bowlRect, outline);
    // Tank
    final tankRect = Rect.fromCenter(center: Offset(0, -8 * s), width: 12 * s, height: 6 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(tankRect, Radius.circular(2 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(tankRect, Radius.circular(2 * s)), outline);
  }

  void _drawSink(Canvas canvas, double s, Paint fill, Paint outline) {
    // Rectangle with inner oval
    final rect = Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 12 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2 * s)), outline);
    // Basin
    final basin = Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 7 * s);
    canvas.drawOval(basin, outline);
    // Faucet dot
    canvas.drawCircle(Offset(0, -4 * s), 1.5 * s, outline);
  }

  void _drawBathtub(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 28 * s, height: 14 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3 * s)), outline);
    // Inner tub
    final inner = Rect.fromCenter(center: Offset.zero, width: 24 * s, height: 10 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(2 * s)), outline);
  }

  void _drawShower(Canvas canvas, double s, Paint fill, Paint outline) {
    // Square with X pattern (drain)
    final rect = Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 18 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Drain circle
    canvas.drawCircle(Offset.zero, 3 * s, outline);
    // Showerhead indicator (small lines)
    final hw = 9 * s;
    canvas.drawLine(Offset(-hw, -hw), Offset(-hw + 4 * s, -hw), outline);
    canvas.drawLine(Offset(-hw, -hw), Offset(-hw, -hw + 4 * s), outline);
  }

  void _drawVanity(Canvas canvas, double s, Paint fill, Paint outline) {
    // Rectangle with two sinks
    final rect = Rect.fromCenter(center: Offset.zero, width: 24 * s, height: 10 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(1 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(1 * s)), outline);
    // Two basins
    canvas.drawOval(Rect.fromCenter(center: Offset(-6 * s, 0), width: 8 * s, height: 6 * s), outline);
    canvas.drawOval(Rect.fromCenter(center: Offset(6 * s, 0), width: 8 * s, height: 6 * s), outline);
  }

  void _drawStove(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 18 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Four burners
    final r = 3 * s;
    final offset = 4.5 * s;
    canvas.drawCircle(Offset(-offset, -offset), r, outline);
    canvas.drawCircle(Offset(offset, -offset), r, outline);
    canvas.drawCircle(Offset(-offset, offset), r, outline);
    canvas.drawCircle(Offset(offset, offset), r, outline);
  }

  void _drawRefrigerator(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 20 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Divider line
    canvas.drawLine(Offset(-9 * s, -3 * s), Offset(9 * s, -3 * s), outline);
    // Handle
    canvas.drawLine(Offset(7 * s, -8 * s), Offset(7 * s, 0), outline);
    canvas.drawLine(Offset(7 * s, -1 * s), Offset(7 * s, 8 * s), outline);
  }

  void _drawDishwasher(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 16 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // "DW" text
    _drawTextOnCanvas(canvas, 'DW', Offset.zero, 8 * s, outline.color);
  }

  void _drawMicrowave(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(1 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(1 * s)), outline);
    // Screen area
    final screen = Rect.fromCenter(center: Offset(-1 * s, 0), width: 8 * s, height: 6 * s);
    canvas.drawRect(screen, outline);
  }

  void _drawWasherDryer(Canvas canvas, double s, Paint fill, Paint outline,
      {bool isDryer = false}) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 16 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Door circle
    canvas.drawCircle(Offset.zero, 5 * s, outline);
    // Label
    _drawTextOnCanvas(canvas, isDryer ? 'D' : 'W', Offset.zero, 7 * s, outline.color);
  }

  void _drawWaterHeater(Canvas canvas, double s, Paint fill, Paint outline) {
    // Tall cylinder
    final rect = Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 20 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(7 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(7 * s)), outline);
    _drawTextOnCanvas(canvas, 'WH', Offset.zero, 7 * s, outline.color);
  }

  void _drawFurnace(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 18 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Flame symbol (simple triangle)
    final path = Path()
      ..moveTo(0, -5 * s)
      ..lineTo(-3 * s, 4 * s)
      ..lineTo(3 * s, 4 * s)
      ..close();
    canvas.drawPath(path, outline);
  }

  void _drawACUnit(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 14 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Fan circle
    canvas.drawCircle(Offset.zero, 4 * s, outline);
    // Blades
    canvas.drawLine(Offset(-3 * s, 0), Offset(3 * s, 0), outline);
    canvas.drawLine(Offset(0, -3 * s), Offset(0, 3 * s), outline);
  }

  void _drawElectricalPanel(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 18 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Breaker lines
    for (int i = -3; i <= 3; i++) {
      final y = i * 2 * s;
      canvas.drawLine(Offset(-5 * s, y), Offset(5 * s, y), outline..strokeWidth = 0.8);
    }
    outline.strokeWidth = 1.5; // restore
  }

  void _drawOutlet(Canvas canvas, double s, Paint fill, Paint outline) {
    // Circle with two vertical slots
    canvas.drawCircle(Offset.zero, 5 * s, fill);
    canvas.drawCircle(Offset.zero, 5 * s, outline);
    // Slots
    canvas.drawLine(Offset(-1.5 * s, -2 * s), Offset(-1.5 * s, 0), outline);
    canvas.drawLine(Offset(1.5 * s, -2 * s), Offset(1.5 * s, 0), outline);
    // Ground
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, 2 * s), width: 3 * s, height: 2 * s),
      0, pi, false, outline);
  }

  void _drawSwitch(Canvas canvas, double s, Paint fill, Paint outline) {
    // Circle with S
    canvas.drawCircle(Offset.zero, 5 * s, fill);
    canvas.drawCircle(Offset.zero, 5 * s, outline);
    _drawTextOnCanvas(canvas, 'S', Offset.zero, 7 * s, outline.color);
  }

  void _drawStairs(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 20 * s, height: 28 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Step lines
    const steps = 7;
    final stepH = 28 * s / steps;
    for (int i = 1; i < steps; i++) {
      final y = -14 * s + i * stepH;
      canvas.drawLine(Offset(-10 * s, y), Offset(10 * s, y), outline);
    }
    // Arrow (direction indicator)
    canvas.drawLine(Offset(0, -12 * s), Offset(0, 10 * s), outline);
    canvas.drawLine(Offset(0, 10 * s), Offset(-3 * s, 6 * s), outline);
    canvas.drawLine(Offset(0, 10 * s), Offset(3 * s, 6 * s), outline);
  }

  void _drawFireplace(Canvas canvas, double s, Paint fill, Paint outline) {
    // U-shaped with mantle
    final rect = Rect.fromCenter(center: Offset.zero, width: 20 * s, height: 10 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Opening
    final opening = Path()
      ..moveTo(-6 * s, 5 * s)
      ..lineTo(-6 * s, -2 * s)
      ..quadraticBezierTo(0, -6 * s, 6 * s, -2 * s)
      ..lineTo(6 * s, 5 * s);
    canvas.drawPath(opening, outline);
  }

  void _drawClosetRod(Canvas canvas, double s, Paint fill, Paint outline) {
    // Line with small circles at ends
    canvas.drawLine(Offset(-12 * s, 0), Offset(12 * s, 0), outline);
    canvas.drawCircle(Offset(-12 * s, 0), 2 * s, fill);
    canvas.drawCircle(Offset(-12 * s, 0), 2 * s, outline);
    canvas.drawCircle(Offset(12 * s, 0), 2 * s, fill);
    canvas.drawCircle(Offset(12 * s, 0), 2 * s, outline);
  }

  void _drawDesk(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 24 * s, height: 14 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Chair circle
    canvas.drawCircle(Offset(0, 10 * s), 4 * s, outline);
  }

  void _drawBed(Canvas canvas, double s, Paint fill, Paint outline) {
    // Rectangle with pillow area
    final rect = Rect.fromCenter(center: Offset.zero, width: 20 * s, height: 28 * s);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, outline);
    // Pillow line
    canvas.drawLine(Offset(-10 * s, -10 * s), Offset(10 * s, -10 * s), outline);
    // Two pillows
    final pillow1 = Rect.fromCenter(center: Offset(-4 * s, -12 * s), width: 7 * s, height: 4 * s);
    final pillow2 = Rect.fromCenter(center: Offset(4 * s, -12 * s), width: 7 * s, height: 4 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(pillow1, Radius.circular(1 * s)), outline);
    canvas.drawRRect(RRect.fromRectAndRadius(pillow2, Radius.circular(1 * s)), outline);
  }

  void _drawSofa(Canvas canvas, double s, Paint fill, Paint outline) {
    // Outer shape
    final outer = Rect.fromCenter(center: Offset.zero, width: 28 * s, height: 12 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(outer, Radius.circular(3 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(outer, Radius.circular(3 * s)), outline);
    // Back
    final back = Rect.fromLTWH(-14 * s, -6 * s, 28 * s, 4 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(back, Radius.circular(2 * s)), outline);
    // Arms
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-14 * s, -6 * s, 4 * s, 12 * s), Radius.circular(2 * s)),
        outline);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(10 * s, -6 * s, 4 * s, 12 * s), Radius.circular(2 * s)),
        outline);
  }

  void _drawTable(Canvas canvas, double s, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 20 * s, height: 14 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2 * s)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2 * s)), outline);
  }

  void _drawCustom(Canvas canvas, double s, Paint fill, Paint outline) {
    // Diamond shape
    final path = Path()
      ..moveTo(0, -8 * s)
      ..lineTo(8 * s, 0)
      ..lineTo(0, 8 * s)
      ..lineTo(-8 * s, 0)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
    _drawTextOnCanvas(canvas, '?', Offset.zero, 10 * s, outline.color);
  }

  // =========================================================================
  // LABELS
  // =========================================================================

  void _drawLabels(Canvas canvas) {
    for (final label in planData.labels) {
      final isSelected =
          selectedElementType == 'label' && selectedElementId == label.id;
      final pos = _toCanvas(label.position);
      final color = isSelected ? _selectionColor : label.color;

      if (isSelected) {
        // Selection highlight
        final bgPaint = Paint()
          ..color = _selectionColor.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: pos,
              width: label.text.length * label.fontSize * 0.7 + 12,
              height: label.fontSize + 10,
            ),
            const Radius.circular(4),
          ),
          bgPaint,
        );
      }

      _drawText(
        canvas,
        label.text,
        pos,
        fontSize: label.fontSize,
        color: color,
        bold: true,
      );
    }
  }

  // =========================================================================
  // DIMENSIONS
  // =========================================================================

  void _drawDimensions(Canvas canvas) {
    for (final dim in planData.dimensions) {
      final isSelected =
          selectedElementType == 'dimension' && selectedElementId == dim.id;
      _drawSingleDimension(canvas, dim, isSelected: isSelected);
    }

    // Ghost dimension start point
    if (ghostDimensionStart != null) {
      final pos = _toCanvas(ghostDimensionStart!);
      final dotPaint = Paint()
        ..color = _dimensionColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 4, dotPaint);
    }
  }

  void _drawSingleDimension(Canvas canvas, DimensionLine dim,
      {bool isSelected = false}) {
    final start = _toCanvas(dim.start);
    final end = _toCanvas(dim.end);
    final color = isSelected ? _selectionColor : _dimensionColor;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Main line
    canvas.drawLine(start, end, paint);

    // Direction and perpendicular for tick marks
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final perpX = -dy / len * 6;
    final perpY = dx / len * 6;

    // Tick marks at start and end
    canvas.drawLine(
      Offset(start.dx + perpX, start.dy + perpY),
      Offset(start.dx - perpX, start.dy - perpY),
      paint,
    );
    canvas.drawLine(
      Offset(end.dx + perpX, end.dy + perpY),
      Offset(end.dx - perpX, end.dy - perpY),
      paint,
    );

    // Arrowheads
    const arrowLen = 8.0;
    const arrowAngle = 25.0 * pi / 180;
    final dirAngle = atan2(dy, dx);

    // Arrow at end pointing from start to end
    _drawArrowhead(canvas, end, dirAngle + pi, arrowLen, arrowAngle, paint);
    // Arrow at start pointing from end to start
    _drawArrowhead(canvas, start, dirAngle, arrowLen, arrowAngle, paint);

    // Label — use unit-aware formatting
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final labelText = (dim.isManual && dim.label.isNotEmpty)
        ? dim.label
        : _formatDim(dim.distanceInches);

    // White background behind text
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final textWidth = labelText.length * 6.5 + 8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(mid.dx + perpX * 2, mid.dy + perpY * 2),
            width: textWidth, height: 14),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    _drawText(
      canvas,
      labelText,
      Offset(mid.dx + perpX * 2, mid.dy + perpY * 2),
      fontSize: 10,
      color: color,
      bold: true,
    );
  }

  void _drawArrowhead(Canvas canvas, Offset tip, double angle, double length,
      double halfAngle, Paint paint) {
    final x1 = tip.dx + length * cos(angle + halfAngle);
    final y1 = tip.dy + length * sin(angle + halfAngle);
    final x2 = tip.dx + length * cos(angle - halfAngle);
    final y2 = tip.dy + length * sin(angle - halfAngle);
    canvas.drawLine(tip, Offset(x1, y1), paint);
    canvas.drawLine(tip, Offset(x2, y2), paint);
  }

  // =========================================================================
  // GHOST WALL (while drawing)
  // =========================================================================

  void _drawGhostWall(Canvas canvas) {
    if (ghostWall == null) return;

    final start = _toCanvas(ghostWall!.start);
    final end = _toCanvas(ghostWall!.end);

    final paint = Paint()
      ..color = _ghostColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    // Ghost endpoints
    final dotPaint = Paint()
      ..color = _ghostColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, 3, dotPaint);
    canvas.drawCircle(end, 3, dotPaint);

    // Ghost dimension
    final dist = ghostWall!.length;
    if (dist > 0) {
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final len = sqrt(dx * dx + dy * dy);
      final perpX = -dy / len * 14;
      final perpY = dx / len * 14;

      final dimText = _formatDim(dist);

      _drawText(
        canvas,
        dimText,
        Offset(mid.dx + perpX, mid.dy + perpY),
        fontSize: 10,
        color: _ghostColor,
        bold: true,
      );
    }
  }

  // =========================================================================
  // LASSO SELECTION
  // =========================================================================

  void _drawLasso(Canvas canvas) {
    if (lassoPoints == null || lassoPoints!.length < 2) return;

    final paint = Paint()
      ..color = _selectionColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = _selectionColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final first = _toCanvas(lassoPoints!.first);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < lassoPoints!.length; i++) {
      final p = _toCanvas(lassoPoints![i]);
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  // =========================================================================
  // SNAP INDICATOR
  // =========================================================================

  void _drawSnapIndicator(Canvas canvas) {
    if (snapIndicator == null) return;
    final pos = _toCanvas(snapIndicator!);
    final paint = Paint()
      ..color = _snapColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Crosshair
    canvas.drawLine(Offset(pos.dx - 8, pos.dy), Offset(pos.dx + 8, pos.dy), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 8), Offset(pos.dx, pos.dy + 8), paint);
    canvas.drawCircle(pos, 6, paint);
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  // Convert model coordinates (inches) to canvas pixels
  Offset _toCanvas(Offset modelPoint) {
    return Offset(modelPoint.dx * scale, modelPoint.dy * scale);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 12,
    Color color = _labelColor,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawTextOnCanvas(
      Canvas canvas, String text, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  // Format inches to current unit system
  String _formatDim(double inches) {
    if (units == MeasurementUnit.metric) {
      final cm = inches * 2.54;
      if (cm >= 100) return '${(cm / 100).toStringAsFixed(2)} m';
      return '${cm.toStringAsFixed(1)} cm';
    }
    final feet = inches ~/ 12;
    final rem = (inches % 12).round();
    if (feet == 0) return '$rem"';
    if (rem == 0) return "$feet'";
    return "$feet' $rem\"";
  }

  // Format area to current unit system
  String _formatArea(double sqFt) {
    if (units == MeasurementUnit.metric) {
      final sqM = sqFt * 0.092903;
      return '${sqM.toStringAsFixed(1)} m\u00B2';
    }
    return '${sqFt.round()} sq ft';
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return planData != oldDelegate.planData ||
        selectedElementId != oldDelegate.selectedElementId ||
        selectedElementType != oldDelegate.selectedElementType ||
        ghostWall != oldDelegate.ghostWall ||
        snapIndicator != oldDelegate.snapIndicator ||
        ghostDimensionStart != oldDelegate.ghostDimensionStart ||
        scale != oldDelegate.scale ||
        units != oldDelegate.units ||
        multiSelectedIds != oldDelegate.multiSelectedIds ||
        lassoPoints != oldDelegate.lassoPoints;
  }
}
