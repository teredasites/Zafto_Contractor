// ZAFTO Trade Layer Painter — SK4
// Renders trade overlay layers (electrical, plumbing, HVAC, damage) on top
// of the base floor plan. Each symbol is drawn with Canvas primitives for
// performance — no SVG parsing at runtime.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/floor_plan_elements.dart';
import '../models/trade_layer.dart';

class TradeLayerPainter extends CustomPainter {
  final List<TradeLayer> layers;
  final String? activeLayerId;
  final String? selectedElementId;
  final MeasurementUnit units;
  final double scale;

  TradeLayerPainter({
    required this.layers,
    this.activeLayerId,
    this.selectedElementId,
    this.units = MeasurementUnit.imperial,
    this.scale = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      if (!layer.visible) continue;
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color.fromRGBO(0, 0, 0, layer.opacity),
      );

      if (layer.type == TradeLayerType.damage) {
        _drawDamageLayer(canvas, layer);
      } else {
        _drawTradeLayer(canvas, layer);
      }

      canvas.restore();
    }
  }

  // ===========================================================================
  // TRADE LAYER (electrical, plumbing, HVAC)
  // ===========================================================================

  void _drawTradeLayer(Canvas canvas, TradeLayer layer) {
    final layerColor = Color(layer.colorValue);

    // Draw paths first (behind symbols)
    for (final path in layer.tradeData.paths) {
      _drawTradePath(canvas, path, layerColor);
    }

    // Draw elements (symbols)
    for (final element in layer.tradeData.elements) {
      _drawTradeElement(canvas, element, layer.type);
    }
  }

  void _drawTradePath(Canvas canvas, TradePath path, Color fallbackColor) {
    if (path.points.length < 2) return;

    final colorValue = pipePathColors[path.pathType];
    final color = colorValue != null ? Color(colorValue) : fallbackColor;
    final paint = Paint()
      ..color = color
      ..strokeWidth = path.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (path.isDashed) {
      _drawDashedPolyline(canvas, path.points, paint, 8.0, 4.0);
    } else {
      final p = ui.Path();
      p.moveTo(path.points.first.dx, path.points.first.dy);
      for (int i = 1; i < path.points.length; i++) {
        p.lineTo(path.points[i].dx, path.points[i].dy);
      }
      canvas.drawPath(p, paint);
    }

    // Draw label at midpoint
    if (path.label != null && path.label!.isNotEmpty) {
      final mid = path.points[path.points.length ~/ 2];
      _drawSmallLabel(canvas, mid, path.label!, color);
    }
  }

  void _drawTradeElement(
      Canvas canvas, TradeElement element, TradeLayerType layerType) {
    final pos = element.position;
    final isSelected = element.id == selectedElementId;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (element.rotation != 0) {
      canvas.rotate(element.rotation * pi / 180);
    }

    // Selection highlight
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 16, highlightPaint);
    }

    // Draw the symbol
    _drawSymbol(canvas, element.symbolType, layerType);

    // Draw label below symbol
    if (element.label != null && element.label!.isNotEmpty) {
      _drawSmallLabel(canvas, const Offset(0, 18), element.label!,
          Color(tradeLayerColors[layerType] ?? 0xFF6B7280));
    }

    canvas.restore();
  }

  // ===========================================================================
  // SYMBOL DRAWING — Canvas primitives for each trade symbol type
  // ===========================================================================

  void _drawSymbol(
      Canvas canvas, TradeSymbolType type, TradeLayerType layerType) {
    final color = Color(tradeLayerColors[layerType] ?? 0xFF6B7280);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    switch (type) {
      // ---- ELECTRICAL ----
      case TradeSymbolType.outlet120v:
        _drawOutletSymbol(canvas, paint, fillPaint, false);
      case TradeSymbolType.outlet240v:
        _drawOutletSymbol(canvas, paint, fillPaint, true);
      case TradeSymbolType.gfciOutlet:
        _drawGfciSymbol(canvas, paint, fillPaint);
      case TradeSymbolType.switchSingle:
        _drawSwitchSymbol(canvas, paint, '1');
      case TradeSymbolType.switchThreeWay:
        _drawSwitchSymbol(canvas, paint, '3');
      case TradeSymbolType.switchDimmer:
        _drawSwitchSymbol(canvas, paint, 'D');
      case TradeSymbolType.junctionBox:
        _drawBoxSymbol(canvas, paint, fillPaint, 'J');
      case TradeSymbolType.panelMain:
        _drawPanelSymbol(canvas, paint, fillPaint, 'M');
      case TradeSymbolType.panelSub:
        _drawPanelSymbol(canvas, paint, fillPaint, 'S');
      case TradeSymbolType.lightFixture:
        _drawLightSymbol(canvas, paint, fillPaint, false);
      case TradeSymbolType.lightRecessed:
        _drawLightSymbol(canvas, paint, fillPaint, true);
      case TradeSymbolType.lightSwitch:
        _drawSwitchSymbol(canvas, paint, 'L');
      case TradeSymbolType.smokeDetector:
        _drawDetectorSymbol(canvas, paint, fillPaint, 'SD');
      case TradeSymbolType.thermostat:
        _drawDetectorSymbol(canvas, paint, fillPaint, 'T');
      case TradeSymbolType.ceilingFan:
        _drawCeilingFanSymbol(canvas, paint, fillPaint);

      // ---- PLUMBING ----
      case TradeSymbolType.pipeHot:
      case TradeSymbolType.pipeCold:
      case TradeSymbolType.pipeDrain:
      case TradeSymbolType.pipeVent:
        // These are typically drawn as paths, not point symbols
        _drawPipeEndpoint(canvas, paint, fillPaint, type);
      case TradeSymbolType.cleanout:
        _drawCleanoutSymbol(canvas, paint, fillPaint);
      case TradeSymbolType.shutoffValve:
        _drawValveSymbol(canvas, paint, fillPaint, 'V');
      case TradeSymbolType.prv:
        _drawValveSymbol(canvas, paint, fillPaint, 'P');
      case TradeSymbolType.waterMeter:
        _drawMeterSymbol(canvas, paint, fillPaint, 'WM');
      case TradeSymbolType.seweLine:
        _drawBoxSymbol(canvas, paint, fillPaint, 'SE');
      case TradeSymbolType.hosebibb:
        _drawHosebibbSymbol(canvas, paint, fillPaint);
      case TradeSymbolType.floorDrain:
        _drawFloorDrainSymbol(canvas, paint, fillPaint);
      case TradeSymbolType.sumpPump:
        _drawBoxSymbol(canvas, paint, fillPaint, 'SP');

      // ---- HVAC ----
      case TradeSymbolType.supplyDuct:
      case TradeSymbolType.returnDuct:
      case TradeSymbolType.flexDuct:
        _drawDuctEndpoint(canvas, paint, fillPaint, type);
      case TradeSymbolType.register:
        _drawRegisterSymbol(canvas, paint, fillPaint, true);
      case TradeSymbolType.returnGrille:
        _drawRegisterSymbol(canvas, paint, fillPaint, false);
      case TradeSymbolType.damper:
        _drawDamperSymbol(canvas, paint, fillPaint);
      case TradeSymbolType.airHandler:
        _drawHvacEquipment(canvas, paint, fillPaint, 'AH');
      case TradeSymbolType.condenser:
        _drawHvacEquipment(canvas, paint, fillPaint, 'CU');
      case TradeSymbolType.miniSplit:
        _drawHvacEquipment(canvas, paint, fillPaint, 'MS');
      case TradeSymbolType.exhaustFan:
        _drawExhaustFanSymbol(canvas, paint, fillPaint);

      // ---- DAMAGE ----
      case TradeSymbolType.waterDamage:
        _drawDamageIndicator(canvas, 0xFF3B82F6, 'W');
      case TradeSymbolType.fireDamage:
        _drawDamageIndicator(canvas, 0xFFEF4444, 'F');
      case TradeSymbolType.moldPresent:
        _drawDamageIndicator(canvas, 0xFF22C55E, 'M');
      case TradeSymbolType.asbestosWarning:
        _drawDamageIndicator(canvas, 0xFFF97316, '!');
    }
  }

  // ---- Electrical symbols ----

  void _drawOutletSymbol(
      Canvas canvas, Paint stroke, Paint fill, bool is240) {
    // Circle with two parallel lines (standard outlet symbol)
    canvas.drawCircle(Offset.zero, 8, fill);
    canvas.drawCircle(Offset.zero, 8, stroke);
    // Two slots
    canvas.drawLine(
        const Offset(-3, -3), const Offset(-3, 3), stroke);
    canvas.drawLine(
        const Offset(3, -3), const Offset(3, 3), stroke);
    if (is240) {
      // Ground pin
      canvas.drawLine(
          const Offset(0, 4), const Offset(0, 7), stroke);
    }
  }

  void _drawGfciSymbol(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset.zero, 8, fill);
    canvas.drawCircle(Offset.zero, 8, stroke);
    _drawSymbolText(canvas, 'GF', 7, stroke.color);
  }

  void _drawSwitchSymbol(Canvas canvas, Paint stroke, String label) {
    // Small circle with a line (toggle switch symbol)
    canvas.drawCircle(Offset.zero, 4, stroke);
    canvas.drawLine(Offset.zero, const Offset(8, -6), stroke);
    _drawSymbolText(canvas, label, 6, stroke.color,
        offset: const Offset(0, 10));
  }

  void _drawBoxSymbol(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 16, height: 16);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
    _drawSymbolText(canvas, label, 7, stroke.color);
  }

  void _drawPanelSymbol(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 20, height: 24);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
    // Internal bus bars
    canvas.drawLine(
        const Offset(-4, -8), const Offset(-4, 8), stroke);
    canvas.drawLine(
        const Offset(4, -8), const Offset(4, 8), stroke);
    _drawSymbolText(canvas, label, 7, stroke.color,
        offset: const Offset(0, 18));
  }

  void _drawLightSymbol(
      Canvas canvas, Paint stroke, Paint fill, bool recessed) {
    if (recessed) {
      // Circle with X (recessed light)
      canvas.drawCircle(Offset.zero, 8, fill);
      canvas.drawCircle(Offset.zero, 8, stroke);
      canvas.drawLine(
          const Offset(-5, -5), const Offset(5, 5), stroke);
      canvas.drawLine(
          const Offset(5, -5), const Offset(-5, 5), stroke);
    } else {
      // Circle with rays (surface mount light)
      canvas.drawCircle(Offset.zero, 6, fill);
      canvas.drawCircle(Offset.zero, 6, stroke);
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final inner = Offset(cos(angle) * 7, sin(angle) * 7);
        final outer = Offset(cos(angle) * 10, sin(angle) * 10);
        canvas.drawLine(inner, outer, stroke);
      }
    }
  }

  void _drawDetectorSymbol(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    // Diamond shape
    final path = ui.Path()
      ..moveTo(0, -8)
      ..lineTo(8, 0)
      ..lineTo(0, 8)
      ..lineTo(-8, 0)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    _drawSymbolText(canvas, label, 6, stroke.color);
  }

  void _drawCeilingFanSymbol(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset.zero, 4, fill);
    canvas.drawCircle(Offset.zero, 4, stroke);
    // Fan blades
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final tip = Offset(cos(angle) * 10, sin(angle) * 10);
      canvas.drawLine(Offset.zero, tip, stroke);
    }
  }

  // ---- Plumbing symbols ----

  void _drawPipeEndpoint(Canvas canvas, Paint stroke, Paint fill,
      TradeSymbolType type) {
    final color = Color(pipePathColors[_pipeTypeKey(type)] ?? 0xFF6B7280);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 5, p);
    canvas.drawCircle(
        Offset.zero,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  String _pipeTypeKey(TradeSymbolType type) {
    switch (type) {
      case TradeSymbolType.pipeHot:
        return 'pipe_hot';
      case TradeSymbolType.pipeCold:
        return 'pipe_cold';
      case TradeSymbolType.pipeDrain:
        return 'pipe_drain';
      case TradeSymbolType.pipeVent:
        return 'pipe_vent';
      default:
        return 'pipe_cold';
    }
  }

  void _drawCleanoutSymbol(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset.zero, 7, fill);
    canvas.drawCircle(Offset.zero, 7, stroke);
    // CO letters
    _drawSymbolText(canvas, 'CO', 7, stroke.color);
  }

  void _drawValveSymbol(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    // Bowtie shape (standard valve symbol)
    final path = ui.Path()
      ..moveTo(-8, -6)
      ..lineTo(0, 0)
      ..lineTo(-8, 6)
      ..close();
    final path2 = ui.Path()
      ..moveTo(8, -6)
      ..lineTo(0, 0)
      ..lineTo(8, 6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawPath(path2, fill);
    canvas.drawPath(path2, stroke);
    _drawSymbolText(canvas, label, 6, stroke.color,
        offset: const Offset(0, 12));
  }

  void _drawMeterSymbol(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    canvas.drawCircle(Offset.zero, 10, fill);
    canvas.drawCircle(Offset.zero, 10, stroke);
    _drawSymbolText(canvas, label, 7, stroke.color);
  }

  void _drawHosebibbSymbol(Canvas canvas, Paint stroke, Paint fill) {
    // Triangle pointing right (faucet symbol)
    final path = ui.Path()
      ..moveTo(-6, -6)
      ..lineTo(8, 0)
      ..lineTo(-6, 6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawFloorDrainSymbol(Canvas canvas, Paint stroke, Paint fill) {
    // Square with circle inside (floor drain)
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 14, height: 14);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
    canvas.drawCircle(Offset.zero, 4, stroke);
  }

  // ---- HVAC symbols ----

  void _drawDuctEndpoint(Canvas canvas, Paint stroke, Paint fill,
      TradeSymbolType type) {
    // Rectangle endpoint for duct
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 12, height: 8);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawRegisterSymbol(
      Canvas canvas, Paint stroke, Paint fill, bool isSupply) {
    // Rectangle with horizontal lines (register/grille)
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 16, height: 10);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
    // Slats
    for (double y = -3; y <= 3; y += 3) {
      canvas.drawLine(
          Offset(-6, y), Offset(6, y), stroke);
    }
    if (!isSupply) {
      // Return grille: diagonal lines
      canvas.drawLine(
          const Offset(-6, -4), const Offset(6, 4), stroke);
      canvas.drawLine(
          const Offset(6, -4), const Offset(-6, 4), stroke);
    }
  }

  void _drawDamperSymbol(Canvas canvas, Paint stroke, Paint fill) {
    // Horizontal line with angled flap
    canvas.drawLine(
        const Offset(-8, 0), const Offset(8, 0), stroke);
    canvas.drawLine(
        const Offset(-4, -6), const Offset(4, 6), stroke);
  }

  void _drawHvacEquipment(
      Canvas canvas, Paint stroke, Paint fill, String label) {
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 24, height: 20);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
    _drawSymbolText(canvas, label, 8, stroke.color);
  }

  void _drawExhaustFanSymbol(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset.zero, 8, fill);
    canvas.drawCircle(Offset.zero, 8, stroke);
    // Arrow pointing up (exhaust direction)
    canvas.drawLine(
        const Offset(0, 4), const Offset(0, -6), stroke);
    canvas.drawLine(
        const Offset(-3, -3), const Offset(0, -6), stroke);
    canvas.drawLine(
        const Offset(3, -3), const Offset(0, -6), stroke);
  }

  // ---- Damage symbols ----

  void _drawDamageIndicator(Canvas canvas, int colorValue, String label) {
    final color = Color(colorValue);
    final fill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    // Warning triangle
    final path = ui.Path()
      ..moveTo(0, -10)
      ..lineTo(9, 7)
      ..lineTo(-9, 7)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    _drawSymbolText(canvas, label, 8, color,
        offset: const Offset(0, 2));
  }

  // ===========================================================================
  // DAMAGE LAYER
  // ===========================================================================

  void _drawDamageLayer(Canvas canvas, TradeLayer layer) {
    // Draw damage zones first (background polygons)
    for (final zone in layer.damageData.zones) {
      _drawDamageZone(canvas, zone);
    }

    // Draw containment lines
    for (final line in layer.containmentLines) {
      _drawContainmentLine(canvas, line);
    }

    // Draw moisture readings
    for (final reading in layer.moistureReadings) {
      _drawMoistureReading(canvas, reading);
    }

    // Draw equipment barriers
    for (final barrier in layer.damageData.barriers) {
      _drawEquipmentMarker(canvas, barrier);
    }

    // Draw damage indicator symbols (from tradeData)
    for (final element in layer.tradeData.elements) {
      _drawTradeElement(canvas, element, TradeLayerType.damage);
    }
  }

  void _drawDamageZone(Canvas canvas, DamageZone zone) {
    if (zone.boundary.length < 3) return;

    final path = ui.Path();
    path.moveTo(zone.boundary.first.dx, zone.boundary.first.dy);
    for (int i = 1; i < zone.boundary.length; i++) {
      path.lineTo(zone.boundary[i].dx, zone.boundary[i].dy);
    }
    path.close();

    // IICRC category tint
    final tintColor = Color(
        IicrcClassification.colorForCategory(zone.iicrcCategory));
    canvas.drawPath(
        path, Paint()..color = tintColor..style = PaintingStyle.fill);

    // Damage class outline color
    final outlineColor = Color(
        IicrcClassification.colorForClass(zone.damageClass));
    canvas.drawPath(
        path,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);

    // Area label at centroid
    if (zone.areaSqFt > 0) {
      final centroid = _polygonCentroid(zone.boundary);
      final areaText = units == MeasurementUnit.imperial
          ? '${zone.areaSqFt.toStringAsFixed(1)} sq ft'
          : '${(zone.areaSqFt * 0.092903).toStringAsFixed(1)} m\u00B2';
      _drawSmallLabel(canvas, centroid, areaText, outlineColor);
    }

    // Damage class label
    if (zone.damageClass != null) {
      final centroid = _polygonCentroid(zone.boundary);
      _drawSmallLabel(
        canvas,
        Offset(centroid.dx, centroid.dy + 14),
        'Class ${zone.damageClass}',
        outlineColor,
      );
    }
  }

  void _drawContainmentLine(Canvas canvas, ContainmentLine line) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, line.start, line.end, paint, 10.0, 5.0);

    // Label
    if (line.label != null && line.label!.isNotEmpty) {
      final mid = Offset(
        (line.start.dx + line.end.dx) / 2,
        (line.start.dy + line.end.dy) / 2,
      );
      _drawSmallLabel(canvas, mid, line.label!, const Color(0xFFEF4444));
    }
  }

  void _drawMoistureReading(Canvas canvas, MoistureReading reading) {
    final color = Color(reading.severityColor);
    final isSelected = reading.id == selectedElementId;

    // Circle with value
    final fill = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;

    canvas.drawCircle(reading.position, 12, fill);
    canvas.drawCircle(reading.position, 12, stroke);

    // Moisture percentage
    _drawSymbolText(canvas, '${reading.value.round()}%', 8, color,
        offset: reading.position);

    // Selection ring
    if (isSelected) {
      canvas.drawCircle(
          reading.position,
          15,
          Paint()
            ..color = const Color(0xFF3B82F6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
    }
  }

  void _drawEquipmentMarker(Canvas canvas, DamageBarrier barrier) {
    final pos = barrier.position;
    final isSelected = barrier.id == selectedElementId;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (barrier.rotation != 0) {
      canvas.rotate(barrier.rotation * pi / 180);
    }

    const color = Color(0xFFF97316); // orange for equipment
    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;

    // Equipment icon based on type
    final label = _barrierLabel(barrier.barrierType);
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 20, height: 16);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
    _drawSymbolText(canvas, label, 7, color);

    if (isSelected) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect.inflate(3), const Radius.circular(5)),
          Paint()
            ..color = const Color(0xFF3B82F6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
    }

    canvas.restore();
  }

  String _barrierLabel(BarrierType type) {
    switch (type) {
      case BarrierType.dehumidifier:
        return 'DH';
      case BarrierType.airMover:
        return 'AM';
      case BarrierType.airScrubber:
        return 'AS';
      case BarrierType.containmentBarrier:
        return 'CB';
      case BarrierType.negativePressure:
        return 'NP';
      case BarrierType.moistureMeter:
        return 'MM';
      case BarrierType.thermalCamera:
        return 'TC';
      case BarrierType.dryingMat:
        return 'DM';
    }
  }

  // ===========================================================================
  // HELPER DRAWING UTILITIES
  // ===========================================================================

  void _drawSymbolText(Canvas canvas, String text, double fontSize,
      Color color,
      {Offset offset = Offset.zero}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2),
    );
  }

  void _drawSmallLabel(
      Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background
    final bgRect = Rect.fromCenter(
      center: pos,
      width: tp.width + 6,
      height: tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    tp.paint(canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end,
      Paint paint, double dashLen, double gapLen) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double drawn = 0;
    bool isDash = true;
    while (drawn < dist) {
      final segLen = isDash ? dashLen : gapLen;
      final remaining = dist - drawn;
      final len = segLen < remaining ? segLen : remaining;
      if (isDash) {
        canvas.drawLine(
          Offset(start.dx + ux * drawn, start.dy + uy * drawn),
          Offset(start.dx + ux * (drawn + len),
              start.dy + uy * (drawn + len)),
          paint,
        );
      }
      drawn += len;
      isDash = !isDash;
    }
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points,
      Paint paint, double dashLen, double gapLen) {
    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], paint,
          dashLen, gapLen);
    }
  }

  Offset _polygonCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double cx = 0, cy = 0;
    for (final p in points) {
      cx += p.dx;
      cy += p.dy;
    }
    return Offset(cx / points.length, cy / points.length);
  }

  @override
  bool shouldRepaint(covariant TradeLayerPainter oldDelegate) {
    return layers != oldDelegate.layers ||
        activeLayerId != oldDelegate.activeLayerId ||
        selectedElementId != oldDelegate.selectedElementId ||
        units != oldDelegate.units;
  }
}
