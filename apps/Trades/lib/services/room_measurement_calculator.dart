// ZAFTO Room Measurement Calculator — SK8
// Computes per-room measurements from FloorPlanData geometry.
// Used by the auto-estimate pipeline to populate estimate_areas.
//
// Measurements computed:
//   - Floor SF: shoelace formula on room boundary polygon
//   - Wall SF: sum(wall_length x wall_height) minus door/window openings
//   - Ceiling SF: same as floor SF (flat ceiling, adjustable per room)
//   - Baseboard LF: perimeter minus door widths
//   - Door/window counts per room
//   - Paint SF: wall SF + ceiling SF (configurable)

import 'dart:math' as math;
import 'dart:ui';

import '../models/floor_plan_elements.dart';

// =============================================================================
// MEASUREMENT RESULT
// =============================================================================

class RoomMeasurements {
  final String roomId;
  final String roomName;
  final double floorSf;
  final double wallSf;
  final double ceilingSf;
  final double baseboardLf;
  final double perimeterLf;
  final int doorCount;
  final int windowCount;
  final double paintSfWallsOnly;
  final double paintSfCeilingOnly;
  final double paintSfBoth;
  final double wallHeight; // inches
  final List<WallMeasurement> wallDetails;

  const RoomMeasurements({
    required this.roomId,
    required this.roomName,
    required this.floorSf,
    required this.wallSf,
    required this.ceilingSf,
    required this.baseboardLf,
    required this.perimeterLf,
    required this.doorCount,
    required this.windowCount,
    required this.paintSfWallsOnly,
    required this.paintSfCeilingOnly,
    required this.paintSfBoth,
    required this.wallHeight,
    required this.wallDetails,
  });
}

class WallMeasurement {
  final String wallId;
  final double lengthInches;
  final double heightInches;
  final double grossSf; // before openings
  final double netSf; // after subtracting openings
  final int doorsOnWall;
  final int windowsOnWall;

  const WallMeasurement({
    required this.wallId,
    required this.lengthInches,
    required this.heightInches,
    required this.grossSf,
    required this.netSf,
    required this.doorsOnWall,
    required this.windowsOnWall,
  });
}

// =============================================================================
// CALCULATOR
// =============================================================================

class RoomMeasurementCalculator {
  // Default opening heights (inches) — used when height not available
  static const double _defaultDoorHeight = 80.0; // 6'8"
  static const double _defaultWindowHeight = 48.0; // 4'0"

  /// Compute measurements for all rooms in a floor plan.
  List<RoomMeasurements> calculateAll(FloorPlanData planData) {
    final results = <RoomMeasurements>[];
    for (final room in planData.rooms) {
      final measurement = calculateRoom(room, planData);
      if (measurement != null) {
        results.add(measurement);
      }
    }
    return results;
  }

  /// Compute measurements for a single room.
  RoomMeasurements? calculateRoom(
      DetectedRoom room, FloorPlanData planData) {
    // Get boundary walls
    final boundaryWalls = <Wall>[];
    for (final wallId in room.wallIds) {
      final wall = planData.walls
          .where((w) => w.id == wallId)
          .firstOrNull;
      if (wall != null) boundaryWalls.add(wall);
    }

    if (boundaryWalls.length < 3) return null;

    // Build ordered polygon from boundary walls
    final polygon = _buildOrderedPolygon(boundaryWalls);
    if (polygon.length < 3) return null;

    // Floor area (shoelace formula) — convert from sq inches to sq ft
    final floorSqInches = _shoelaceArea(polygon);
    final floorSf = floorSqInches / 144.0;

    // Get doors and windows on boundary walls
    final roomDoors = planData.doors
        .where((d) => room.wallIds.contains(d.wallId))
        .toList();
    final roomWindows = planData.windows
        .where((w) => room.wallIds.contains(w.wallId))
        .toList();

    // Per-wall measurements
    final wallDetails = <WallMeasurement>[];
    double totalWallSf = 0;
    double totalPerimeter = 0;
    double totalDoorWidth = 0;

    for (final wall in boundaryWalls) {
      final lengthInches = _wallLength(wall);
      final heightInches = wall.height;

      // Gross wall area
      final grossSf = (lengthInches * heightInches) / 144.0;

      // Door openings on this wall
      final doorsOnWall =
          roomDoors.where((d) => d.wallId == wall.id).toList();
      double doorOpeningSf = 0;
      for (final door in doorsOnWall) {
        doorOpeningSf += (door.width * _defaultDoorHeight) / 144.0;
        totalDoorWidth += door.width;
      }

      // Window openings on this wall
      final windowsOnWall =
          roomWindows.where((w) => w.wallId == wall.id).toList();
      double windowOpeningSf = 0;
      for (final window in windowsOnWall) {
        windowOpeningSf += (window.width * _defaultWindowHeight) / 144.0;
      }

      // Net wall area (subtract openings)
      final netSf = math.max(0.0, grossSf - doorOpeningSf - windowOpeningSf);

      wallDetails.add(WallMeasurement(
        wallId: wall.id,
        lengthInches: lengthInches,
        heightInches: heightInches,
        grossSf: grossSf,
        netSf: netSf,
        doorsOnWall: doorsOnWall.length,
        windowsOnWall: windowsOnWall.length,
      ));

      totalWallSf += netSf;
      totalPerimeter += lengthInches;
    }

    // Ceiling SF = floor SF (flat ceiling assumption)
    final ceilingSf = floorSf;

    // Baseboard LF = perimeter minus door widths (in feet)
    final perimeterLf = totalPerimeter / 12.0;
    final baseboardLf = math.max(0.0, (totalPerimeter - totalDoorWidth) / 12.0);

    // Average wall height from boundary walls
    final avgHeight = boundaryWalls.isEmpty
        ? 96.0
        : boundaryWalls.map((w) => w.height).reduce((a, b) => a + b) /
            boundaryWalls.length;

    return RoomMeasurements(
      roomId: room.id,
      roomName: room.name,
      floorSf: _round2(floorSf),
      wallSf: _round2(totalWallSf),
      ceilingSf: _round2(ceilingSf),
      baseboardLf: _round2(baseboardLf),
      perimeterLf: _round2(perimeterLf),
      doorCount: roomDoors.length,
      windowCount: roomWindows.length,
      paintSfWallsOnly: _round2(totalWallSf),
      paintSfCeilingOnly: _round2(ceilingSf),
      paintSfBoth: _round2(totalWallSf + ceilingSf),
      wallHeight: avgHeight,
      wallDetails: wallDetails,
    );
  }

  // ===========================================================================
  // GEOMETRY HELPERS
  // ===========================================================================

  /// Build an ordered polygon from boundary walls by connecting endpoints.
  List<Offset> _buildOrderedPolygon(List<Wall> walls) {
    if (walls.isEmpty) return [];

    // Use endpoint adjacency to order walls into a loop
    final ordered = <Offset>[];
    final used = <int>{};
    var current = walls[0].start;
    ordered.add(current);
    used.add(0);

    // Find the endpoint of the first wall that connects to the chain
    var nextPoint = walls[0].end;

    for (var i = 0; i < walls.length - 1; i++) {
      ordered.add(nextPoint);

      // Find the next wall that connects to nextPoint
      int? nextIdx;
      Offset? newNext;

      for (var j = 0; j < walls.length; j++) {
        if (used.contains(j)) continue;
        if (_closeEnough(walls[j].start, nextPoint)) {
          nextIdx = j;
          newNext = walls[j].end;
          break;
        }
        if (_closeEnough(walls[j].end, nextPoint)) {
          nextIdx = j;
          newNext = walls[j].start;
          break;
        }
      }

      if (nextIdx == null || newNext == null) break;
      used.add(nextIdx);
      nextPoint = newNext;
    }

    return ordered;
  }

  /// Shoelace formula for polygon area (in square units of the coordinates).
  double _shoelaceArea(List<Offset> points) {
    if (points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area.abs() / 2.0;
  }

  /// Wall length in inches.
  double _wallLength(Wall wall) {
    final dx = wall.end.dx - wall.start.dx;
    final dy = wall.end.dy - wall.start.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Check if two points are close enough to be considered the same endpoint.
  bool _closeEnough(Offset a, Offset b, [double threshold = 6.0]) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return (dx * dx + dy * dy) <= threshold * threshold;
  }

  /// Round to 2 decimal places.
  double _round2(double v) => (v * 100).roundToDouble() / 100;
}
