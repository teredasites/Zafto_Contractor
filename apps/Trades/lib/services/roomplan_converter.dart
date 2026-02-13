// ZAFTO RoomPlan Converter — SK5
// Converts Apple RoomPlan CapturedRoom JSON into FloorPlanData.
// 3D→2D projection: extract X and Z from 4x4 transform (Y = height).
// Scale: meters → inches (× 39.3701).

import 'dart:math';
import 'dart:ui';

import '../models/floor_plan_elements.dart';

class RoomPlanConverter {
  static const double _metersToInches = 39.3701;

  // Convert CapturedRoom JSON → FloorPlanData
  static FloorPlanData convert(Map<String, dynamic> capturedRoom) {
    final walls = <Wall>[];
    final doors = <DoorPlacement>[];
    final windows = <WindowPlacement>[];
    final fixtures = <FixturePlacement>[];
    int wallIdx = 0;
    int doorIdx = 0;
    int windowIdx = 0;
    int fixtureIdx = 0;

    // Parse walls from CapturedRoom.walls[]
    final rawWalls = capturedRoom['walls'] as List<dynamic>? ?? [];
    for (final rawWall in rawWalls) {
      final w = rawWall as Map<String, dynamic>;
      final transform = _parseTransform(w['transform']);
      if (transform == null) continue;

      final position = _extractXZ(transform); // meters
      final dimensions = w['dimensions'] as Map<String, dynamic>?;
      final length = (dimensions?['x'] as num?)?.toDouble() ?? 2.0;
      final height = (dimensions?['y'] as num?)?.toDouble() ?? 2.4;

      // Orientation: extract rotation from transform matrix
      final angle = _extractYRotation(transform);

      // Wall endpoints: center ± (length/2) along orientation
      final halfLen = (length / 2) * _metersToInches;
      final startX = position.dx * _metersToInches + halfLen * cos(angle);
      final startY = position.dy * _metersToInches + halfLen * sin(angle);
      final endX = position.dx * _metersToInches - halfLen * cos(angle);
      final endY = position.dy * _metersToInches - halfLen * sin(angle);

      final wallId = 'scan_wall_${wallIdx++}';
      walls.add(Wall(
        id: wallId,
        start: Offset(startX, startY),
        end: Offset(endX, endY),
        thickness: 6.0, // default, user can adjust
        height: height * _metersToInches,
      ));
    }

    // Parse doors from CapturedRoom.doors[]
    final rawDoors = capturedRoom['doors'] as List<dynamic>? ?? [];
    for (final rawDoor in rawDoors) {
      final d = rawDoor as Map<String, dynamic>;
      final transform = _parseTransform(d['transform']);
      if (transform == null) continue;

      final position = _extractXZ(transform);
      final dimensions = d['dimensions'] as Map<String, dynamic>?;
      final width = (dimensions?['x'] as num?)?.toDouble() ?? 0.9;

      // Find parent wall
      final doorPos = Offset(
        position.dx * _metersToInches,
        position.dy * _metersToInches,
      );
      final parentResult = _findParentWall(doorPos, walls);
      if (parentResult == null) continue;

      doors.add(DoorPlacement(
        id: 'scan_door_${doorIdx++}',
        wallId: parentResult.wallId,
        position: parentResult.t,
        width: width * _metersToInches,
        type: _parseDoorType(d['type'] as String?),
      ));
    }

    // Parse windows from CapturedRoom.windows[]
    final rawWindows = capturedRoom['windows'] as List<dynamic>? ?? [];
    for (final rawWindow in rawWindows) {
      final w = rawWindow as Map<String, dynamic>;
      final transform = _parseTransform(w['transform']);
      if (transform == null) continue;

      final position = _extractXZ(transform);
      final dimensions = w['dimensions'] as Map<String, dynamic>?;
      final width = (dimensions?['x'] as num?)?.toDouble() ?? 0.9;

      final winPos = Offset(
        position.dx * _metersToInches,
        position.dy * _metersToInches,
      );
      final parentResult = _findParentWall(winPos, walls);
      if (parentResult == null) continue;

      windows.add(WindowPlacement(
        id: 'scan_window_${windowIdx++}',
        wallId: parentResult.wallId,
        position: parentResult.t,
        width: width * _metersToInches,
        type: WindowType.standard,
      ));
    }

    // Parse objects from CapturedRoom.objects[]
    final rawObjects = capturedRoom['objects'] as List<dynamic>? ?? [];
    for (final rawObj in rawObjects) {
      final o = rawObj as Map<String, dynamic>;
      final transform = _parseTransform(o['transform']);
      if (transform == null) continue;

      final position = _extractXZ(transform);
      final category = o['category'] as String? ?? '';
      final fixtureType = _mapObjectToFixture(category);
      if (fixtureType == null) continue;

      fixtures.add(FixturePlacement(
        id: 'scan_fixture_${fixtureIdx++}',
        position: Offset(
          position.dx * _metersToInches,
          position.dy * _metersToInches,
        ),
        type: fixtureType,
        rotation: _extractYRotation(transform) * 180 / pi,
      ));
    }

    // Auto-detect rooms from connected walls
    final rooms = SketchGeometry.detectRooms(walls);

    return FloorPlanData(
      walls: walls,
      doors: doors,
      windows: windows,
      fixtures: fixtures,
      rooms: rooms,
      scale: 4.0,
      units: MeasurementUnit.imperial,
    );
  }

  // Parse 4x4 column-major transform matrix
  static List<double>? _parseTransform(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  // Extract X,Z position from 4x4 column-major matrix (meters)
  // In RoomPlan coordinate system: X = right, Y = up, Z = forward
  // We project to 2D using X,Z (top-down view)
  static Offset _extractXZ(List<double> transform) {
    if (transform.length < 16) return Offset.zero;
    // Translation is in column 3 (indices 12, 13, 14 for x, y, z)
    final x = transform[12]; // right
    final z = transform[14]; // forward
    return Offset(x, z);
  }

  // Extract Y-axis rotation from 4x4 column-major matrix
  static double _extractYRotation(List<double>? transform) {
    if (transform == null || transform.length < 16) return 0.0;
    // Rotation matrix: extract angle from m[0] (cos) and m[8] (sin)
    // For Y rotation: R = [[cos, 0, sin], [0, 1, 0], [-sin, 0, cos]]
    // Column-major: m[0]=cos, m[8]=sin
    return atan2(transform[8], transform[0]);
  }

  // Find the nearest wall and parametric position for a door/window
  static _WallHit? _findParentWall(Offset point, List<Wall> walls) {
    double bestDist = double.infinity;
    _WallHit? best;

    for (final wall in walls) {
      final dist = SketchGeometry.pointToSegmentDistance(
          point, wall.start, wall.end);
      if (dist < bestDist) {
        bestDist = dist;
        final t = SketchGeometry.projectOntoWall(point, wall);
        best = _WallHit(wallId: wall.id, t: t, distance: dist);
      }
    }

    // Only accept if within reasonable threshold (24 inches = ~2 feet)
    if (best != null && best.distance < 24.0) return best;
    return null;
  }

  static DoorType _parseDoorType(String? type) {
    switch (type?.toLowerCase()) {
      case 'open':
      case 'single':
        return DoorType.single;
      case 'double':
        return DoorType.double_;
      case 'sliding':
        return DoorType.sliding;
      default:
        return DoorType.single;
    }
  }

  static FixtureType? _mapObjectToFixture(String category) {
    switch (category.toLowerCase()) {
      case 'toilet':
        return FixtureType.toilet;
      case 'sink':
      case 'washbasin':
        return FixtureType.sink;
      case 'bathtub':
      case 'bath':
        return FixtureType.bathtub;
      case 'shower':
        return FixtureType.shower;
      case 'stove':
      case 'oven':
      case 'range':
        return FixtureType.stove;
      case 'refrigerator':
      case 'fridge':
        return FixtureType.refrigerator;
      case 'dishwasher':
        return FixtureType.dishwasher;
      case 'washer':
      case 'washing_machine':
        return FixtureType.washer;
      case 'dryer':
        return FixtureType.dryer;
      case 'sofa':
      case 'couch':
        return FixtureType.sofa;
      case 'table':
      case 'dining_table':
        return FixtureType.table;
      case 'bed':
        return FixtureType.bed;
      case 'desk':
        return FixtureType.desk;
      case 'fireplace':
        return FixtureType.fireplace;
      case 'stairs':
      case 'staircase':
        return FixtureType.stairs;
      default:
        return null; // Unknown object, skip
    }
  }
}

class _WallHit {
  final String wallId;
  final double t; // parametric position 0-1 along wall
  final double distance;

  const _WallHit({
    required this.wallId,
    required this.t,
    required this.distance,
  });
}
