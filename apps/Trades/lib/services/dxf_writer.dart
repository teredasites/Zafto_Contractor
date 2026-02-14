import '../models/floor_plan_elements.dart';
import '../models/trade_layer.dart';

/// DXF Writer — Generates AutoCAD-compatible DXF files from floor plan data.
/// ASCII DXF format (R2000/AC1015) — readable by AutoCAD, LibreCAD, DraftSight.
class DxfWriter {
  static const String _acadVersion = 'AC1015';
  static const int _insUnits = 1; // 1 = Inches

  /// Generate complete DXF string from floor plan data.
  static String generate({
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    String? projectTitle,
    String? companyName,
  }) {
    final buf = StringBuffer();
    _writeHeader(buf, plan);
    _writeTables(buf, tradeLayers);
    _writeBlocks(buf);
    _writeEntities(buf, plan, tradeLayers);
    _writeEof(buf);
    return buf.toString();
  }

  static void _writeHeader(StringBuffer buf, FloorPlanData plan) {
    buf.writeln('0');
    buf.writeln('SECTION');
    buf.writeln('2');
    buf.writeln('HEADER');

    _writeVariable(buf, r'$ACADVER', 1, _acadVersion);
    _writeVariable(buf, r'$INSUNITS', 70, _insUnits.toString());

    // Drawing extents
    double maxX = 0, maxY = 0;
    for (final wall in plan.walls) {
      if (wall.start.dx > maxX) maxX = wall.start.dx;
      if (wall.end.dx > maxX) maxX = wall.end.dx;
      if (wall.start.dy > maxY) maxY = wall.start.dy;
      if (wall.end.dy > maxY) maxY = wall.end.dy;
    }
    _writeVariable2D(buf, r'$EXTMIN', 0, 0);
    _writeVariable2D(buf, r'$EXTMAX', maxX, maxY);

    buf.writeln('0');
    buf.writeln('ENDSEC');
  }

  static void _writeTables(StringBuffer buf, List<TradeLayer>? tradeLayers) {
    buf.writeln('0');
    buf.writeln('SECTION');
    buf.writeln('2');
    buf.writeln('TABLES');

    // Layer table
    buf.writeln('0');
    buf.writeln('TABLE');
    buf.writeln('2');
    buf.writeln('LAYER');

    final layers = <_DxfLayer>[
      _DxfLayer('0', 7), // Default — white
      _DxfLayer('WALLS', 8), // Dark gray
      _DxfLayer('ROOMS', 150), // Light blue
      _DxfLayer('DOORS', 200), // Purple
      _DxfLayer('WINDOWS', 4), // Cyan
      _DxfLayer('FIXTURES', 3), // Green
      _DxfLayer('DIMENSIONS', 1), // Red
      _DxfLayer('LABELS', 7), // White
    ];

    if (tradeLayers != null) {
      for (final tl in tradeLayers) {
        final color = _tradeLayerColor(tl.type);
        layers.add(_DxfLayer(tl.type.name.toUpperCase(), color));
      }
    }

    _writeGroupCode(buf, 70, layers.length.toString());

    for (final layer in layers) {
      buf.writeln('0');
      buf.writeln('LAYER');
      _writeGroupCode(buf, 2, layer.name);
      _writeGroupCode(buf, 70, '0'); // Not frozen
      _writeGroupCode(buf, 62, layer.color.toString());
      _writeGroupCode(buf, 6, 'CONTINUOUS');
    }

    buf.writeln('0');
    buf.writeln('ENDTAB');

    buf.writeln('0');
    buf.writeln('ENDSEC');
  }

  static void _writeBlocks(StringBuffer buf) {
    buf.writeln('0');
    buf.writeln('SECTION');
    buf.writeln('2');
    buf.writeln('BLOCKS');
    buf.writeln('0');
    buf.writeln('ENDSEC');
  }

  static void _writeEntities(
    StringBuffer buf,
    FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
  ) {
    buf.writeln('0');
    buf.writeln('SECTION');
    buf.writeln('2');
    buf.writeln('ENTITIES');

    // Walls → LINE entities with thickness
    for (final wall in plan.walls) {
      _writeLine(buf, 'WALLS', wall.start.dx, wall.start.dy, wall.end.dx,
          wall.end.dy);
    }

    // Arc walls → ARC entities
    for (final arc in plan.arcWalls) {
      _writeArc(
        buf,
        'WALLS',
        arc.center.dx,
        arc.center.dy,
        arc.radius,
        _radToDeg(arc.startAngle),
        _radToDeg(arc.startAngle + arc.sweepAngle),
      );
    }

    // Rooms → LWPOLYLINE + label at center
    for (final room in plan.rooms) {
      final wallPts = _roomWallPoints(room, plan);
      if (wallPts.isNotEmpty) {
        _writeLwPolyline(buf, 'ROOMS', wallPts, closed: true);
      }
      _writeText(buf, 'ROOMS', room.center.dx, room.center.dy, room.name,
          height: 6.0);
    }

    // Doors → short LINE segments on walls
    for (final door in plan.doors) {
      final wall = plan.wallById(door.wallId);
      if (wall == null) continue;
      final pos = wall.pointAt(door.position);
      final halfW = door.width / 2;
      final along = wall.direction;
      _writeLine(
        buf,
        'DOORS',
        pos.dx - along.dx * halfW,
        pos.dy - along.dy * halfW,
        pos.dx + along.dx * halfW,
        pos.dy + along.dy * halfW,
      );
      // Swing arc indicator
      _writeArc(
        buf,
        'DOORS',
        pos.dx - along.dx * halfW,
        pos.dy - along.dy * halfW,
        door.width,
        0,
        door.swingAngle,
      );
    }

    // Windows → double-line on walls
    for (final win in plan.windows) {
      final wall = plan.wallById(win.wallId);
      if (wall == null) continue;
      final pos = wall.pointAt(win.position);
      final along = wall.direction;
      final halfW = win.width / 2;
      final normal = wall.normal;
      final offset = wall.thickness / 2;
      // Outer line
      _writeLine(
        buf,
        'WINDOWS',
        pos.dx - along.dx * halfW + normal.dx * offset,
        pos.dy - along.dy * halfW + normal.dy * offset,
        pos.dx + along.dx * halfW + normal.dx * offset,
        pos.dy + along.dy * halfW + normal.dy * offset,
      );
      // Inner line
      _writeLine(
        buf,
        'WINDOWS',
        pos.dx - along.dx * halfW - normal.dx * offset,
        pos.dy - along.dy * halfW - normal.dy * offset,
        pos.dx + along.dx * halfW - normal.dx * offset,
        pos.dy + along.dy * halfW - normal.dy * offset,
      );
    }

    // Fixtures → POINT + TEXT label
    for (final fix in plan.fixtures) {
      _writePoint(buf, 'FIXTURES', fix.position.dx, fix.position.dy);
      _writeText(
        buf,
        'FIXTURES',
        fix.position.dx + 3,
        fix.position.dy + 3,
        fix.label ?? fix.type.name,
        height: 4.0,
      );
    }

    // Dimension lines
    for (final dim in plan.dimensions) {
      _writeLine(buf, 'DIMENSIONS', dim.start.dx, dim.start.dy,
          dim.end.dx, dim.end.dy);
      final mx = (dim.start.dx + dim.end.dx) / 2;
      final my = (dim.start.dy + dim.end.dy) / 2;
      _writeText(
        buf,
        'DIMENSIONS',
        mx,
        my + 3,
        dim.label.isNotEmpty ? dim.label : dim.formattedDistance,
        height: 3.0,
      );
    }

    // Labels
    for (final lbl in plan.labels) {
      _writeText(
        buf,
        'LABELS',
        lbl.position.dx,
        lbl.position.dy,
        lbl.text,
        height: lbl.fontSize / plan.scale,
      );
    }

    // Trade layers
    if (tradeLayers != null) {
      for (final tl in tradeLayers) {
        if (!tl.visible) continue;
        final layerName = tl.type.name.toUpperCase();

        for (final elem in tl.tradeData.elements) {
          _writePoint(buf, layerName, elem.position.dx, elem.position.dy);
          _writeText(
            buf,
            layerName,
            elem.position.dx + 3,
            elem.position.dy + 3,
            elem.label ?? elem.symbolType.name,
            height: 3.0,
          );
        }

        for (final path in tl.tradeData.paths) {
          if (path.points.length >= 2) {
            final pts = path.points
                .map((p) => _Point(p.dx, p.dy))
                .toList();
            _writeLwPolyline(buf, layerName, pts);
          }
        }

        if (tl.damageData.zones.isNotEmpty) {
          for (final zone in tl.damageData.zones) {
            if (zone.boundary.length >= 3) {
              final pts = zone.boundary
                  .map((p) => _Point(p.dx, p.dy))
                  .toList();
              _writeLwPolyline(buf, layerName, pts, closed: true);
              final cx = pts.fold(0.0, (s, p) => s + p.x) / pts.length;
              final cy = pts.fold(0.0, (s, p) => s + p.y) / pts.length;
              _writeText(
                buf,
                layerName,
                cx,
                cy,
                '${zone.damageType} (${zone.severity})',
                height: 4.0,
              );
            }
          }
        }
      }
    }

    buf.writeln('0');
    buf.writeln('ENDSEC');
  }

  static void _writeEof(StringBuffer buf) {
    buf.writeln('0');
    buf.writeln('EOF');
  }

  // --- DXF entity helpers ---

  static void _writeLine(
    StringBuffer buf,
    String layer,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    buf.writeln('0');
    buf.writeln('LINE');
    _writeGroupCode(buf, 8, layer);
    _writeGroupCode(buf, 10, x1.toStringAsFixed(4));
    _writeGroupCode(buf, 20, y1.toStringAsFixed(4));
    _writeGroupCode(buf, 11, x2.toStringAsFixed(4));
    _writeGroupCode(buf, 21, y2.toStringAsFixed(4));
  }

  static void _writeArc(
    StringBuffer buf,
    String layer,
    double cx,
    double cy,
    double radius,
    double startDeg,
    double endDeg,
  ) {
    buf.writeln('0');
    buf.writeln('ARC');
    _writeGroupCode(buf, 8, layer);
    _writeGroupCode(buf, 10, cx.toStringAsFixed(4));
    _writeGroupCode(buf, 20, cy.toStringAsFixed(4));
    _writeGroupCode(buf, 40, radius.toStringAsFixed(4));
    _writeGroupCode(buf, 50, startDeg.toStringAsFixed(2));
    _writeGroupCode(buf, 51, endDeg.toStringAsFixed(2));
  }

  static void _writeLwPolyline(
    StringBuffer buf,
    String layer,
    List<_Point> points, {
    bool closed = false,
  }) {
    buf.writeln('0');
    buf.writeln('LWPOLYLINE');
    _writeGroupCode(buf, 8, layer);
    _writeGroupCode(buf, 90, points.length.toString());
    _writeGroupCode(buf, 70, closed ? '1' : '0');
    for (final p in points) {
      _writeGroupCode(buf, 10, p.x.toStringAsFixed(4));
      _writeGroupCode(buf, 20, p.y.toStringAsFixed(4));
    }
  }

  static void _writePoint(
      StringBuffer buf, String layer, double x, double y) {
    buf.writeln('0');
    buf.writeln('POINT');
    _writeGroupCode(buf, 8, layer);
    _writeGroupCode(buf, 10, x.toStringAsFixed(4));
    _writeGroupCode(buf, 20, y.toStringAsFixed(4));
  }

  static void _writeText(
    StringBuffer buf,
    String layer,
    double x,
    double y,
    String text, {
    double height = 4.0,
  }) {
    buf.writeln('0');
    buf.writeln('TEXT');
    _writeGroupCode(buf, 8, layer);
    _writeGroupCode(buf, 10, x.toStringAsFixed(4));
    _writeGroupCode(buf, 20, y.toStringAsFixed(4));
    _writeGroupCode(buf, 40, height.toStringAsFixed(2));
    _writeGroupCode(buf, 1, text);
  }

  static void _writeGroupCode(StringBuffer buf, int code, String value) {
    buf.writeln(code.toString());
    buf.writeln(value);
  }

  static void _writeVariable(
      StringBuffer buf, String name, int code, String value) {
    buf.writeln('9');
    buf.writeln(name);
    buf.writeln(code.toString());
    buf.writeln(value);
  }

  static void _writeVariable2D(
      StringBuffer buf, String name, double x, double y) {
    buf.writeln('9');
    buf.writeln(name);
    buf.writeln('10');
    buf.writeln(x.toStringAsFixed(4));
    buf.writeln('20');
    buf.writeln(y.toStringAsFixed(4));
  }

  static int _tradeLayerColor(TradeLayerType type) {
    switch (type) {
      case TradeLayerType.electrical:
        return 5; // Blue
      case TradeLayerType.plumbing:
        return 1; // Red
      case TradeLayerType.hvac:
        return 3; // Green
      case TradeLayerType.damage:
        return 30; // Orange
    }
  }

  static double _radToDeg(double rad) => rad * 180 / 3.14159265358979;

  /// Build room polygon from wall endpoints.
  static List<_Point> _roomWallPoints(DetectedRoom room, FloorPlanData plan) {
    final points = <_Point>[];
    for (final wid in room.wallIds) {
      final wall = plan.wallById(wid);
      if (wall != null) {
        points.add(_Point(wall.start.dx, wall.start.dy));
        points.add(_Point(wall.end.dx, wall.end.dy));
      }
    }
    return points;
  }
}

class _DxfLayer {
  final String name;
  final int color;
  const _DxfLayer(this.name, this.color);
}

class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);
}
