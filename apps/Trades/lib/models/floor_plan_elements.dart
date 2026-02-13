// ZAFTO Floor Plan Elements — Data Models
// Typed representations of all elements stored in property_floor_plans.plan_data JSONB.
// All coordinates use a virtual canvas coordinate system (1 unit = 1 inch).

import 'dart:math';
import 'dart:ui';

import 'trade_layer.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum DoorType { single, double_, sliding, pocket, french, garage, bifold }

enum WindowType { standard, picture, sliding, casement, bay, skylight }

enum FixtureType {
  // Bathroom
  toilet,
  sink,
  bathtub,
  shower,
  vanity,
  // Kitchen
  stove,
  refrigerator,
  dishwasher,
  microwave,
  // Laundry
  washer,
  dryer,
  // Mechanical
  waterHeater,
  furnace,
  acUnit,
  // Electrical
  electricalPanel,
  outlet,
  switchBox,
  // Structural
  stairs,
  fireplace,
  closetRod,
  // Furniture
  desk,
  bed,
  sofa,
  table,
  // Custom
  custom,
}

// =============================================================================
// FIXTURE CATEGORY HELPERS
// =============================================================================

enum FixtureCategory {
  bathroom,
  kitchen,
  laundry,
  mechanical,
  electrical,
  structural,
  furniture,
}

const Map<FixtureCategory, String> fixtureCategoryLabels = {
  FixtureCategory.bathroom: 'Bathroom',
  FixtureCategory.kitchen: 'Kitchen',
  FixtureCategory.laundry: 'Laundry',
  FixtureCategory.mechanical: 'Mechanical',
  FixtureCategory.electrical: 'Electrical',
  FixtureCategory.structural: 'Structural',
  FixtureCategory.furniture: 'Furniture',
};

const Map<FixtureCategory, List<FixtureType>> fixturesByCategory = {
  FixtureCategory.bathroom: [
    FixtureType.toilet,
    FixtureType.sink,
    FixtureType.bathtub,
    FixtureType.shower,
    FixtureType.vanity,
  ],
  FixtureCategory.kitchen: [
    FixtureType.stove,
    FixtureType.refrigerator,
    FixtureType.dishwasher,
    FixtureType.microwave,
  ],
  FixtureCategory.laundry: [
    FixtureType.washer,
    FixtureType.dryer,
  ],
  FixtureCategory.mechanical: [
    FixtureType.waterHeater,
    FixtureType.furnace,
    FixtureType.acUnit,
  ],
  FixtureCategory.electrical: [
    FixtureType.electricalPanel,
    FixtureType.outlet,
    FixtureType.switchBox,
  ],
  FixtureCategory.structural: [
    FixtureType.stairs,
    FixtureType.fireplace,
    FixtureType.closetRod,
  ],
  FixtureCategory.furniture: [
    FixtureType.desk,
    FixtureType.bed,
    FixtureType.sofa,
    FixtureType.table,
  ],
};

const Map<FixtureType, String> fixtureLabels = {
  FixtureType.toilet: 'Toilet',
  FixtureType.sink: 'Sink',
  FixtureType.bathtub: 'Bathtub',
  FixtureType.shower: 'Shower',
  FixtureType.vanity: 'Vanity',
  FixtureType.stove: 'Stove',
  FixtureType.refrigerator: 'Fridge',
  FixtureType.dishwasher: 'Dishwasher',
  FixtureType.microwave: 'Microwave',
  FixtureType.washer: 'Washer',
  FixtureType.dryer: 'Dryer',
  FixtureType.waterHeater: 'Water Heater',
  FixtureType.furnace: 'Furnace',
  FixtureType.acUnit: 'A/C Unit',
  FixtureType.electricalPanel: 'Panel',
  FixtureType.outlet: 'Outlet',
  FixtureType.switchBox: 'Switch',
  FixtureType.stairs: 'Stairs',
  FixtureType.fireplace: 'Fireplace',
  FixtureType.closetRod: 'Closet Rod',
  FixtureType.desk: 'Desk',
  FixtureType.bed: 'Bed',
  FixtureType.sofa: 'Sofa',
  FixtureType.table: 'Table',
  FixtureType.custom: 'Custom',
};

// =============================================================================
// WALL
// =============================================================================

class Wall {
  final String id;
  final Offset start;
  final Offset end;
  final double thickness;
  final double height; // inches (default 96 = 8ft)
  final String? material;

  const Wall({
    required this.id,
    required this.start,
    required this.end,
    this.thickness = 6.0,
    this.height = 96.0,
    this.material,
  });

  double get length => (end - start).distance;

  // Direction vector (unit)
  Offset get direction {
    final d = end - start;
    final len = d.distance;
    if (len == 0) return Offset.zero;
    return Offset(d.dx / len, d.dy / len);
  }

  // Normal vector (perpendicular, unit)
  Offset get normal {
    final dir = direction;
    return Offset(-dir.dy, dir.dx);
  }

  // Get point along wall at parameter t (0..1)
  Offset pointAt(double t) {
    return Offset(
      start.dx + (end.dx - start.dx) * t,
      start.dy + (end.dy - start.dy) * t,
    );
  }

  Wall copyWith({
    String? id,
    Offset? start,
    Offset? end,
    double? thickness,
    double? height,
    String? material,
  }) {
    return Wall(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      thickness: thickness ?? this.thickness,
      height: height ?? this.height,
      material: material ?? this.material,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': {'x': start.dx, 'y': start.dy},
        'end': {'x': end.dx, 'y': end.dy},
        'thickness': thickness,
        'height': height,
        if (material != null) 'material': material,
      };

  factory Wall.fromJson(Map<String, dynamic> json) {
    final s = json['start'] as Map<String, dynamic>;
    final e = json['end'] as Map<String, dynamic>;
    return Wall(
      id: json['id'] as String,
      start: Offset(
        (s['x'] as num).toDouble(),
        (s['y'] as num).toDouble(),
      ),
      end: Offset(
        (e['x'] as num).toDouble(),
        (e['y'] as num).toDouble(),
      ),
      thickness: (json['thickness'] as num?)?.toDouble() ?? 6.0,
      height: (json['height'] as num?)?.toDouble() ?? 96.0,
      material: json['material'] as String?,
    );
  }
}

// =============================================================================
// DOOR PLACEMENT
// =============================================================================

class DoorPlacement {
  final String id;
  final String wallId;
  final double position; // 0-1 along wall
  final double width;
  final DoorType type;
  final double swingAngle; // degrees, 0-180

  const DoorPlacement({
    required this.id,
    required this.wallId,
    this.position = 0.5,
    this.width = 36.0,
    this.type = DoorType.single,
    this.swingAngle = 90.0,
  });

  DoorPlacement copyWith({
    String? id,
    String? wallId,
    double? position,
    double? width,
    DoorType? type,
    double? swingAngle,
  }) {
    return DoorPlacement(
      id: id ?? this.id,
      wallId: wallId ?? this.wallId,
      position: position ?? this.position,
      width: width ?? this.width,
      type: type ?? this.type,
      swingAngle: swingAngle ?? this.swingAngle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall_id': wallId,
        'position': position,
        'width': width,
        'type': type.name,
        'swing_angle': swingAngle,
      };

  factory DoorPlacement.fromJson(Map<String, dynamic> json) {
    return DoorPlacement(
      id: json['id'] as String,
      wallId: json['wall_id'] as String,
      position: (json['position'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 36.0,
      type: DoorType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DoorType.single,
      ),
      swingAngle: (json['swing_angle'] as num?)?.toDouble() ?? 90.0,
    );
  }
}

// =============================================================================
// WINDOW PLACEMENT
// =============================================================================

class WindowPlacement {
  final String id;
  final String wallId;
  final double position;
  final double width;
  final WindowType type;

  const WindowPlacement({
    required this.id,
    required this.wallId,
    this.position = 0.5,
    this.width = 36.0,
    this.type = WindowType.standard,
  });

  WindowPlacement copyWith({
    String? id,
    String? wallId,
    double? position,
    double? width,
    WindowType? type,
  }) {
    return WindowPlacement(
      id: id ?? this.id,
      wallId: wallId ?? this.wallId,
      position: position ?? this.position,
      width: width ?? this.width,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall_id': wallId,
        'position': position,
        'width': width,
        'type': type.name,
      };

  factory WindowPlacement.fromJson(Map<String, dynamic> json) {
    return WindowPlacement(
      id: json['id'] as String,
      wallId: json['wall_id'] as String,
      position: (json['position'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 36.0,
      type: WindowType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WindowType.standard,
      ),
    );
  }
}

// =============================================================================
// FIXTURE PLACEMENT
// =============================================================================

class FixturePlacement {
  final String id;
  final Offset position;
  final FixtureType type;
  final double rotation; // degrees
  final String? label;

  const FixturePlacement({
    required this.id,
    required this.position,
    required this.type,
    this.rotation = 0.0,
    this.label,
  });

  FixturePlacement copyWith({
    String? id,
    Offset? position,
    FixtureType? type,
    double? rotation,
    String? label,
  }) {
    return FixturePlacement(
      id: id ?? this.id,
      position: position ?? this.position,
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': {'x': position.dx, 'y': position.dy},
        'type': type.name,
        'rotation': rotation,
        if (label != null) 'label': label,
      };

  factory FixturePlacement.fromJson(Map<String, dynamic> json) {
    final p = json['position'] as Map<String, dynamic>;
    return FixturePlacement(
      id: json['id'] as String,
      position: Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      ),
      type: FixtureType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FixtureType.custom,
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
    );
  }
}

// =============================================================================
// FLOOR LABEL
// =============================================================================

class FloorLabel {
  final String id;
  final Offset position;
  final String text;
  final double fontSize;
  final int colorValue;

  const FloorLabel({
    required this.id,
    required this.position,
    required this.text,
    this.fontSize = 14.0,
    this.colorValue = 0xFF000000,
  });

  Color get color => Color(colorValue);

  FloorLabel copyWith({
    String? id,
    Offset? position,
    String? text,
    double? fontSize,
    int? colorValue,
  }) {
    return FloorLabel(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': {'x': position.dx, 'y': position.dy},
        'text': text,
        'font_size': fontSize,
        'color': colorValue,
      };

  factory FloorLabel.fromJson(Map<String, dynamic> json) {
    final p = json['position'] as Map<String, dynamic>;
    return FloorLabel(
      id: json['id'] as String,
      position: Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      ),
      text: json['text'] as String? ?? '',
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 14.0,
      colorValue: json['color'] as int? ?? 0xFF000000,
    );
  }
}

// =============================================================================
// DIMENSION LINE
// =============================================================================

class DimensionLine {
  final String id;
  final Offset start;
  final Offset end;
  final String label;
  final bool isManual;

  const DimensionLine({
    required this.id,
    required this.start,
    required this.end,
    this.label = '',
    this.isManual = false,
  });

  // Auto-calculated distance in inches
  double get distanceInches => (end - start).distance;

  // Formatted as feet and inches: 12' 6"
  String get formattedDistance {
    if (isManual && label.isNotEmpty) return label;
    final totalInches = distanceInches;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    if (feet == 0) return '$inches"';
    if (inches == 0) return "$feet'";
    return "$feet' $inches\"";
  }

  DimensionLine copyWith({
    String? id,
    Offset? start,
    Offset? end,
    String? label,
    bool? isManual,
  }) {
    return DimensionLine(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': {'x': start.dx, 'y': start.dy},
        'end': {'x': end.dx, 'y': end.dy},
        'label': label,
        'is_manual': isManual,
      };

  factory DimensionLine.fromJson(Map<String, dynamic> json) {
    final s = json['start'] as Map<String, dynamic>;
    final e = json['end'] as Map<String, dynamic>;
    return DimensionLine(
      id: json['id'] as String,
      start: Offset(
        (s['x'] as num).toDouble(),
        (s['y'] as num).toDouble(),
      ),
      end: Offset(
        (e['x'] as num).toDouble(),
        (e['y'] as num).toDouble(),
      ),
      label: json['label'] as String? ?? '',
      isManual: json['is_manual'] as bool? ?? false,
    );
  }
}

// =============================================================================
// DETECTED ROOM
// =============================================================================

class DetectedRoom {
  final String id;
  final String name;
  final List<String> wallIds;
  final Offset center;
  final double area; // square feet

  const DetectedRoom({
    required this.id,
    required this.name,
    required this.wallIds,
    required this.center,
    this.area = 0.0,
  });

  DetectedRoom copyWith({
    String? id,
    String? name,
    List<String>? wallIds,
    Offset? center,
    double? area,
  }) {
    return DetectedRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      wallIds: wallIds ?? this.wallIds,
      center: center ?? this.center,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wall_ids': wallIds,
        'center': {'x': center.dx, 'y': center.dy},
        'area': area,
      };

  factory DetectedRoom.fromJson(Map<String, dynamic> json) {
    final c = json['center'] as Map<String, dynamic>;
    return DetectedRoom(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Room',
      wallIds: (json['wall_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      center: Offset(
        (c['x'] as num).toDouble(),
        (c['y'] as num).toDouble(),
      ),
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// =============================================================================
// FLOOR PLAN DATA — Top-level container
// =============================================================================

class FloorPlanData {
  final List<Wall> walls;
  final List<ArcWall> arcWalls;
  final List<DoorPlacement> doors;
  final List<WindowPlacement> windows;
  final List<FixturePlacement> fixtures;
  final List<FloorLabel> labels;
  final List<DimensionLine> dimensions;
  final List<DetectedRoom> rooms;
  final List<TradeLayer> tradeLayers; // SK4: trade overlay layers
  final double scale; // pixels per unit (inch)
  final MeasurementUnit units;

  const FloorPlanData({
    this.walls = const [],
    this.arcWalls = const [],
    this.doors = const [],
    this.windows = const [],
    this.fixtures = const [],
    this.labels = const [],
    this.dimensions = const [],
    this.rooms = const [],
    this.tradeLayers = const [],
    this.scale = 4.0,
    this.units = MeasurementUnit.imperial,
  });

  // Find a trade layer by ID
  TradeLayer? tradeLayerById(String id) {
    for (final l in tradeLayers) {
      if (l.id == id) return l;
    }
    return null;
  }

  FloorPlanData copyWith({
    List<Wall>? walls,
    List<ArcWall>? arcWalls,
    List<DoorPlacement>? doors,
    List<WindowPlacement>? windows,
    List<FixturePlacement>? fixtures,
    List<FloorLabel>? labels,
    List<DimensionLine>? dimensions,
    List<DetectedRoom>? rooms,
    List<TradeLayer>? tradeLayers,
    double? scale,
    MeasurementUnit? units,
  }) {
    return FloorPlanData(
      walls: walls ?? this.walls,
      arcWalls: arcWalls ?? this.arcWalls,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      fixtures: fixtures ?? this.fixtures,
      labels: labels ?? this.labels,
      dimensions: dimensions ?? this.dimensions,
      rooms: rooms ?? this.rooms,
      tradeLayers: tradeLayers ?? this.tradeLayers,
      scale: scale ?? this.scale,
      units: units ?? this.units,
    );
  }

  // Find a wall by ID
  Wall? wallById(String id) {
    for (final w in walls) {
      if (w.id == id) return w;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'walls': walls.map((e) => e.toJson()).toList(),
        'arc_walls': arcWalls.map((e) => e.toJson()).toList(),
        'doors': doors.map((e) => e.toJson()).toList(),
        'windows': windows.map((e) => e.toJson()).toList(),
        'fixtures': fixtures.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => e.toJson()).toList(),
        'dimensions': dimensions.map((e) => e.toJson()).toList(),
        'rooms': rooms.map((e) => e.toJson()).toList(),
        if (tradeLayers.isNotEmpty)
          'trade_layers': tradeLayers.map((e) => e.toJson()).toList(),
        'scale': scale,
        'units': units.name,
      };

  factory FloorPlanData.fromJson(Map<String, dynamic> json) {
    return FloorPlanData(
      walls: _parseList(json['walls'], Wall.fromJson),
      arcWalls: _parseList(json['arc_walls'], ArcWall.fromJson),
      doors: _parseList(json['doors'], DoorPlacement.fromJson),
      windows: _parseList(json['windows'], WindowPlacement.fromJson),
      fixtures: _parseList(json['fixtures'], FixturePlacement.fromJson),
      labels: _parseList(json['labels'], FloorLabel.fromJson),
      dimensions: _parseList(json['dimensions'], DimensionLine.fromJson),
      rooms: _parseList(json['rooms'], DetectedRoom.fromJson),
      tradeLayers: _parseList(json['trade_layers'], TradeLayer.fromJson),
      scale: (json['scale'] as num?)?.toDouble() ?? 4.0,
      units: _parseUnits(json['units'] as String?),
    );
  }

  static MeasurementUnit _parseUnits(String? value) {
    if (value == 'metric') return MeasurementUnit.metric;
    return MeasurementUnit.imperial;
  }

  static List<T> _parseList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => parser(e as Map<String, dynamic>))
        .toList();
  }
}

// =============================================================================
// SKETCH TOOL ENUM
// =============================================================================

enum SketchTool {
  select,
  wall,
  arcWall,
  door,
  window,
  fixture,
  label,
  dimension,
  erase,
  lasso,
  pan,
}

// =============================================================================
// UNDO/REDO COMMAND SYSTEM
// =============================================================================

// Represents a reversible action on the floor plan
abstract class SketchCommand {
  FloorPlanData execute(FloorPlanData data);
  FloorPlanData undo(FloorPlanData data);
}

class AddWallCommand extends SketchCommand {
  final Wall wall;
  AddWallCommand(this.wall);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(walls: [...data.walls, wall]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.where((w) => w.id != wall.id).toList(),
    );
  }
}

class RemoveWallCommand extends SketchCommand {
  final Wall wall;
  RemoveWallCommand(this.wall);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.where((w) => w.id != wall.id).toList(),
      // Also remove doors/windows on this wall
      doors: data.doors.where((d) => d.wallId != wall.id).toList(),
      windows: data.windows.where((w) => w.wallId != wall.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(walls: [...data.walls, wall]);
  }
}

class MoveWallCommand extends SketchCommand {
  final String wallId;
  final Offset oldStart;
  final Offset oldEnd;
  final Offset newStart;
  final Offset newEnd;

  MoveWallCommand({
    required this.wallId,
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.map((w) {
        if (w.id == wallId) return w.copyWith(start: newStart, end: newEnd);
        return w;
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.map((w) {
        if (w.id == wallId) return w.copyWith(start: oldStart, end: oldEnd);
        return w;
      }).toList(),
    );
  }
}

class AddDoorCommand extends SketchCommand {
  final DoorPlacement door;
  AddDoorCommand(this.door);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(doors: [...data.doors, door]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      doors: data.doors.where((d) => d.id != door.id).toList(),
    );
  }
}

class RemoveDoorCommand extends SketchCommand {
  final DoorPlacement door;
  RemoveDoorCommand(this.door);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      doors: data.doors.where((d) => d.id != door.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(doors: [...data.doors, door]);
  }
}

class AddWindowCommand extends SketchCommand {
  final WindowPlacement window;
  AddWindowCommand(this.window);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(windows: [...data.windows, window]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      windows: data.windows.where((w) => w.id != window.id).toList(),
    );
  }
}

class RemoveWindowCommand extends SketchCommand {
  final WindowPlacement window;
  RemoveWindowCommand(this.window);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      windows: data.windows.where((w) => w.id != window.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(windows: [...data.windows, window]);
  }
}

class AddFixtureCommand extends SketchCommand {
  final FixturePlacement fixture;
  AddFixtureCommand(this.fixture);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(fixtures: [...data.fixtures, fixture]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.where((f) => f.id != fixture.id).toList(),
    );
  }
}

class RemoveFixtureCommand extends SketchCommand {
  final FixturePlacement fixture;
  RemoveFixtureCommand(this.fixture);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.where((f) => f.id != fixture.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(fixtures: [...data.fixtures, fixture]);
  }
}

class MoveFixtureCommand extends SketchCommand {
  final String fixtureId;
  final Offset oldPosition;
  final Offset newPosition;

  MoveFixtureCommand({
    required this.fixtureId,
    required this.oldPosition,
    required this.newPosition,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.map((f) {
        if (f.id == fixtureId) return f.copyWith(position: newPosition);
        return f;
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.map((f) {
        if (f.id == fixtureId) return f.copyWith(position: oldPosition);
        return f;
      }).toList(),
    );
  }
}

class AddLabelCommand extends SketchCommand {
  final FloorLabel label;
  AddLabelCommand(this.label);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(labels: [...data.labels, label]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      labels: data.labels.where((l) => l.id != label.id).toList(),
    );
  }
}

class RemoveLabelCommand extends SketchCommand {
  final FloorLabel label;
  RemoveLabelCommand(this.label);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      labels: data.labels.where((l) => l.id != label.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(labels: [...data.labels, label]);
  }
}

class AddDimensionCommand extends SketchCommand {
  final DimensionLine dimension;
  AddDimensionCommand(this.dimension);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(dimensions: [...data.dimensions, dimension]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      dimensions: data.dimensions.where((d) => d.id != dimension.id).toList(),
    );
  }
}

class RemoveDimensionCommand extends SketchCommand {
  final DimensionLine dimension;
  RemoveDimensionCommand(this.dimension);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      dimensions: data.dimensions.where((d) => d.id != dimension.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(dimensions: [...data.dimensions, dimension]);
  }
}

class UpdateRoomNameCommand extends SketchCommand {
  final String roomId;
  final String oldName;
  final String newName;

  UpdateRoomNameCommand({
    required this.roomId,
    required this.oldName,
    required this.newName,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      rooms: data.rooms.map((r) {
        if (r.id == roomId) return r.copyWith(name: newName);
        return r;
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      rooms: data.rooms.map((r) {
        if (r.id == roomId) return r.copyWith(name: oldName);
        return r;
      }).toList(),
    );
  }
}

// Generic delete command for eraser tool
class EraseElementCommand extends SketchCommand {
  final String elementId;
  final String elementType; // 'wall','door','window','fixture','label','dimension'
  final dynamic _element; // stored for undo

  EraseElementCommand({
    required this.elementId,
    required this.elementType,
    required dynamic element,
  }) : _element = element;

  @override
  FloorPlanData execute(FloorPlanData data) {
    switch (elementType) {
      case 'wall':
        return data.copyWith(
          walls: data.walls.where((w) => w.id != elementId).toList(),
          doors: data.doors.where((d) => d.wallId != elementId).toList(),
          windows: data.windows.where((w) => w.wallId != elementId).toList(),
        );
      case 'door':
        return data.copyWith(
          doors: data.doors.where((d) => d.id != elementId).toList(),
        );
      case 'window':
        return data.copyWith(
          windows: data.windows.where((w) => w.id != elementId).toList(),
        );
      case 'fixture':
        return data.copyWith(
          fixtures: data.fixtures.where((f) => f.id != elementId).toList(),
        );
      case 'label':
        return data.copyWith(
          labels: data.labels.where((l) => l.id != elementId).toList(),
        );
      case 'dimension':
        return data.copyWith(
          dimensions:
              data.dimensions.where((d) => d.id != elementId).toList(),
        );
      default:
        return data;
    }
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    switch (elementType) {
      case 'wall':
        return data.copyWith(walls: [...data.walls, _element as Wall]);
      case 'door':
        return data.copyWith(
            doors: [...data.doors, _element as DoorPlacement]);
      case 'window':
        return data.copyWith(
            windows: [...data.windows, _element as WindowPlacement]);
      case 'fixture':
        return data.copyWith(
            fixtures: [...data.fixtures, _element as FixturePlacement]);
      case 'label':
        return data.copyWith(
            labels: [...data.labels, _element as FloorLabel]);
      case 'dimension':
        return data.copyWith(
            dimensions: [...data.dimensions, _element as DimensionLine]);
      default:
        return data;
    }
  }
}

// SK2: Split wall into two segments (undoable)
class SplitWallCommand extends SketchCommand {
  final Wall originalWall;
  final Wall wall1;
  final Wall wall2;
  final List<DoorPlacement> originalDoors;
  final List<DoorPlacement> updatedDoors;
  final List<WindowPlacement> originalWindows;
  final List<WindowPlacement> updatedWindows;

  SplitWallCommand({
    required this.originalWall,
    required this.wall1,
    required this.wall2,
    required this.originalDoors,
    required this.updatedDoors,
    required this.originalWindows,
    required this.updatedWindows,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    final walls =
        data.walls.where((w) => w.id != originalWall.id).toList()
          ..addAll([wall1, wall2]);
    return data.copyWith(walls: walls, doors: updatedDoors, windows: updatedWindows);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    final walls = data.walls
        .where((w) => w.id != wall1.id && w.id != wall2.id)
        .toList()
      ..add(originalWall);
    return data.copyWith(walls: walls, doors: originalDoors, windows: originalWindows);
  }
}

// SK2: Update wall properties (thickness, height, material) — undoable
class UpdateWallPropertiesCommand extends SketchCommand {
  final String wallId;
  final double oldThickness;
  final double newThickness;
  final double oldHeight;
  final double newHeight;
  final String? oldMaterial;
  final String? newMaterial;

  UpdateWallPropertiesCommand({
    required this.wallId,
    required this.oldThickness,
    required this.newThickness,
    required this.oldHeight,
    required this.newHeight,
    required this.oldMaterial,
    required this.newMaterial,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.map((w) {
        if (w.id == wallId) {
          return w.copyWith(
            thickness: newThickness,
            height: newHeight,
            material: newMaterial,
          );
        }
        return w;
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      walls: data.walls.map((w) {
        if (w.id == wallId) {
          return w.copyWith(
            thickness: oldThickness,
            height: oldHeight,
            material: oldMaterial,
          );
        }
        return w;
      }).toList(),
    );
  }
}

// SK2: Rotate fixture — undoable
class RotateFixtureCommand extends SketchCommand {
  final String fixtureId;
  final double oldRotation;
  final double newRotation;

  RotateFixtureCommand({
    required this.fixtureId,
    required this.oldRotation,
    required this.newRotation,
  });

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.map((f) {
        if (f.id == fixtureId) return f.copyWith(rotation: newRotation);
        return f;
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      fixtures: data.fixtures.map((f) {
        if (f.id == fixtureId) return f.copyWith(rotation: oldRotation);
        return f;
      }).toList(),
    );
  }
}

// SK3: Arc wall commands
class AddArcWallCommand extends SketchCommand {
  final ArcWall arcWall;
  AddArcWallCommand(this.arcWall);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(arcWalls: [...data.arcWalls, arcWall]);
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      arcWalls: data.arcWalls.where((a) => a.id != arcWall.id).toList(),
    );
  }
}

class RemoveArcWallCommand extends SketchCommand {
  final ArcWall arcWall;
  RemoveArcWallCommand(this.arcWall);

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      arcWalls: data.arcWalls.where((a) => a.id != arcWall.id).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(arcWalls: [...data.arcWalls, arcWall]);
  }
}

// SK3: Batch command for paste/group operations
class BatchCommand extends SketchCommand {
  final List<SketchCommand> commands;
  BatchCommand(this.commands);

  @override
  FloorPlanData execute(FloorPlanData data) {
    var result = data;
    for (final cmd in commands) {
      result = cmd.execute(result);
    }
    return result;
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    var result = data;
    for (final cmd in commands.reversed) {
      result = cmd.undo(result);
    }
    return result;
  }
}

// SK3: Move group of elements
class MoveGroupCommand extends SketchCommand {
  final Set<String> elementIds;
  final Map<String, String> elementTypes; // id -> type
  final Offset delta;

  MoveGroupCommand({
    required this.elementIds,
    required this.elementTypes,
    required this.delta,
  });

  @override
  FloorPlanData execute(FloorPlanData data) => _applyDelta(data, delta);

  @override
  FloorPlanData undo(FloorPlanData data) =>
      _applyDelta(data, Offset(-delta.dx, -delta.dy));

  FloorPlanData _applyDelta(FloorPlanData data, Offset d) {
    return data.copyWith(
      walls: data.walls.map((w) {
        if (elementIds.contains(w.id)) {
          return w.copyWith(
            start: Offset(w.start.dx + d.dx, w.start.dy + d.dy),
            end: Offset(w.end.dx + d.dx, w.end.dy + d.dy),
          );
        }
        return w;
      }).toList(),
      fixtures: data.fixtures.map((f) {
        if (elementIds.contains(f.id)) {
          return f.copyWith(
            position: Offset(f.position.dx + d.dx, f.position.dy + d.dy),
          );
        }
        return f;
      }).toList(),
      labels: data.labels.map((l) {
        if (elementIds.contains(l.id)) {
          return l.copyWith(
            position: Offset(l.position.dx + d.dx, l.position.dy + d.dy),
          );
        }
        return l;
      }).toList(),
      dimensions: data.dimensions.map((dim) {
        if (elementIds.contains(dim.id)) {
          return dim.copyWith(
            start: Offset(dim.start.dx + d.dx, dim.start.dy + d.dy),
            end: Offset(dim.end.dx + d.dx, dim.end.dy + d.dy),
          );
        }
        return dim;
      }).toList(),
      arcWalls: data.arcWalls.map((a) {
        if (elementIds.contains(a.id)) {
          return a.copyWith(
            center: Offset(a.center.dx + d.dx, a.center.dy + d.dy),
          );
        }
        return a;
      }).toList(),
    );
  }
}

// =============================================================================
// UNDO/REDO MANAGER
// =============================================================================

class UndoRedoManager {
  final List<SketchCommand> _undoStack = [];
  final List<SketchCommand> _redoStack = [];
  static const int _maxHistory = 100;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  FloorPlanData execute(SketchCommand command, FloorPlanData data) {
    final result = command.execute(data);
    _undoStack.add(command);
    _redoStack.clear();
    // Limit history
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    return result;
  }

  FloorPlanData undo(FloorPlanData data) {
    if (!canUndo) return data;
    final command = _undoStack.removeLast();
    _redoStack.add(command);
    return command.undo(data);
  }

  FloorPlanData redo(FloorPlanData data) {
    if (!canRedo) return data;
    final command = _redoStack.removeLast();
    _undoStack.add(command);
    return command.execute(data);
  }

  // Record a command that was already applied externally (e.g. during drag).
  // Does NOT re-execute — just pushes onto undo stack for reversibility.
  void pushExternal(SketchCommand command) {
    _undoStack.add(command);
    _redoStack.clear();
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

// =============================================================================
// GEOMETRY HELPERS
// =============================================================================

class SketchGeometry {
  // Snap angle to nearest standard angle (0, 45, 90, 135, 180, etc.)
  // threshold is in degrees
  static double snapAngle(double angle, {double threshold = 5.0}) {
    const snapAngles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    // Normalize to 0-360
    double normalized = angle % 360;
    if (normalized < 0) normalized += 360;

    for (final snap in snapAngles) {
      if ((normalized - snap).abs() < threshold) return snap;
      // Also check wrap-around (360 == 0)
      if ((normalized - snap + 360).abs() < threshold) return snap;
      if ((normalized - snap - 360).abs() < threshold) return snap;
    }
    return angle; // no snap
  }

  // Snap an endpoint so the wall drawn from [start] to [proposed] snaps to
  // standard angles. Returns the snapped endpoint.
  static Offset snapEndpoint(Offset start, Offset proposed,
      {double threshold = 5.0}) {
    final dx = proposed.dx - start.dx;
    final dy = proposed.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return proposed;

    final angle = atan2(dy, dx) * 180 / pi;
    final snapped = snapAngle(angle, threshold: threshold);

    if ((snapped - angle).abs() > 0.01) {
      // Angle was snapped — compute new endpoint
      final rad = snapped * pi / 180;
      return Offset(
        start.dx + distance * cos(rad),
        start.dy + distance * sin(rad),
      );
    }
    return proposed;
  }

  // Find nearest existing wall endpoint within threshold
  static Offset? findNearestEndpoint(
    Offset point,
    List<Wall> walls, {
    double threshold = 12.0,
    String? excludeWallId,
  }) {
    Offset? nearest;
    double bestDist = threshold;

    for (final wall in walls) {
      if (wall.id == excludeWallId) continue;
      final dStart = (wall.start - point).distance;
      final dEnd = (wall.end - point).distance;
      if (dStart < bestDist) {
        bestDist = dStart;
        nearest = wall.start;
      }
      if (dEnd < bestDist) {
        bestDist = dEnd;
        nearest = wall.end;
      }
    }
    return nearest;
  }

  // Distance from point to line segment
  static double pointToSegmentDistance(Offset point, Offset a, Offset b) {
    final ab = b - a;
    final ap = point - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (point - a).distance;

    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (point - closest).distance;
  }

  // Find the wall nearest to a point, within threshold
  static Wall? findNearestWall(
    Offset point,
    List<Wall> walls, {
    double threshold = 12.0,
  }) {
    Wall? nearest;
    double bestDist = threshold;
    for (final wall in walls) {
      final d = pointToSegmentDistance(point, wall.start, wall.end);
      if (d < bestDist) {
        bestDist = d;
        nearest = wall;
      }
    }
    return nearest;
  }

  // Get the parameter t (0-1) where point projects onto wall segment
  static double projectOntoWall(Offset point, Wall wall) {
    final ab = wall.end - wall.start;
    final ap = point - wall.start;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return 0.0;
    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / lenSq;
    return t.clamp(0.0, 1.0);
  }

  // Find nearest fixture to point
  static FixturePlacement? findNearestFixture(
    Offset point,
    List<FixturePlacement> fixtures, {
    double threshold = 24.0,
  }) {
    FixturePlacement? nearest;
    double bestDist = threshold;
    for (final f in fixtures) {
      final d = (f.position - point).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = f;
      }
    }
    return nearest;
  }

  // Find nearest label to point
  static FloorLabel? findNearestLabel(
    Offset point,
    List<FloorLabel> labels, {
    double threshold = 24.0,
  }) {
    FloorLabel? nearest;
    double bestDist = threshold;
    for (final l in labels) {
      final d = (l.position - point).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = l;
      }
    }
    return nearest;
  }

  // Find nearest dimension line to point
  static DimensionLine? findNearestDimension(
    Offset point,
    List<DimensionLine> dimensions, {
    double threshold = 16.0,
  }) {
    DimensionLine? nearest;
    double bestDist = threshold;
    for (final d in dimensions) {
      final dist = pointToSegmentDistance(point, d.start, d.end);
      if (dist < bestDist) {
        bestDist = dist;
        nearest = d;
      }
    }
    return nearest;
  }

  // Find nearest arc wall to a point
  static ArcWall? findNearestArcWall(
    Offset point,
    List<ArcWall> arcWalls, {
    double threshold = 16.0,
  }) {
    ArcWall? nearest;
    double bestDist = threshold;
    for (final arc in arcWalls) {
      // Distance from point to arc: distance from center minus radius
      final distToCenter = (point - arc.center).distance;
      final distToArc = (distToCenter - arc.radius).abs();
      // Also check the point is within the sweep angle range
      final angle = atan2(point.dy - arc.center.dy, point.dx - arc.center.dx);
      double normalAngle = angle - arc.startAngle;
      if (normalAngle < 0) normalAngle += 2 * pi;
      if (normalAngle < 0) normalAngle += 2 * pi;
      final sweep = arc.sweepAngle.abs();
      if (normalAngle <= sweep && distToArc < bestDist) {
        bestDist = distToArc;
        nearest = arc;
      }
    }
    return nearest;
  }

  // Check if a point is inside a polygon (lasso selection)
  static bool pointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  // Find all elements inside a lasso polygon
  static Map<String, String> findElementsInLasso(
    List<Offset> lassoPoints,
    FloorPlanData data,
  ) {
    final result = <String, String>{}; // id -> type
    for (final w in data.walls) {
      final mid = Offset(
        (w.start.dx + w.end.dx) / 2,
        (w.start.dy + w.end.dy) / 2,
      );
      if (pointInPolygon(mid, lassoPoints)) {
        result[w.id] = 'wall';
      }
    }
    for (final a in data.arcWalls) {
      if (pointInPolygon(a.center, lassoPoints)) {
        result[a.id] = 'arcWall';
      }
    }
    for (final f in data.fixtures) {
      if (pointInPolygon(f.position, lassoPoints)) {
        result[f.id] = 'fixture';
      }
    }
    for (final l in data.labels) {
      if (pointInPolygon(l.position, lassoPoints)) {
        result[l.id] = 'label';
      }
    }
    for (final d in data.dimensions) {
      final mid = Offset(
        (d.start.dx + d.end.dx) / 2,
        (d.start.dy + d.end.dy) / 2,
      );
      if (pointInPolygon(mid, lassoPoints)) {
        result[d.id] = 'dimension';
      }
    }
    return result;
  }

  // Find any element near point. Returns (type, id) or null.
  static (String, String)? findElementAt(
    Offset point,
    FloorPlanData data, {
    double threshold = 16.0,
  }) {
    // Check fixtures first (point-based, most specific)
    final fixture =
        findNearestFixture(point, data.fixtures, threshold: threshold);
    if (fixture != null) return ('fixture', fixture.id);

    // Check labels
    final label = findNearestLabel(point, data.labels, threshold: threshold);
    if (label != null) return ('label', label.id);

    // Check doors (on walls)
    for (final door in data.doors) {
      final wall = data.wallById(door.wallId);
      if (wall == null) continue;
      final doorCenter = wall.pointAt(door.position);
      if ((doorCenter - point).distance < threshold) {
        return ('door', door.id);
      }
    }

    // Check windows (on walls)
    for (final win in data.windows) {
      final wall = data.wallById(win.wallId);
      if (wall == null) continue;
      final winCenter = wall.pointAt(win.position);
      if ((winCenter - point).distance < threshold) {
        return ('window', win.id);
      }
    }

    // Check dimension lines
    final dim =
        findNearestDimension(point, data.dimensions, threshold: threshold);
    if (dim != null) return ('dimension', dim.id);

    // Check arc walls
    final arcWall = findNearestArcWall(point, data.arcWalls, threshold: threshold);
    if (arcWall != null) return ('arcWall', arcWall.id);

    // Check walls last (they're large targets)
    final wall = findNearestWall(point, data.walls, threshold: threshold);
    if (wall != null) return ('wall', wall.id);

    return null;
  }

  // Simple room detection: find cycles of connected walls.
  // This is a basic version — detect rectangular rooms from connected wall endpoints.
  static List<DetectedRoom> detectRooms(List<Wall> walls) {
    if (walls.length < 3) return [];

    // Build adjacency: endpoint → list of walls that share that endpoint
    const snapThreshold = 6.0;
    final Map<String, List<Wall>> endpointMap = {};

    String pointKey(Offset p) =>
        '${(p.dx / snapThreshold).round()},${(p.dy / snapThreshold).round()}';

    for (final wall in walls) {
      final sKey = pointKey(wall.start);
      final eKey = pointKey(wall.end);
      endpointMap.putIfAbsent(sKey, () => []).add(wall);
      endpointMap.putIfAbsent(eKey, () => []).add(wall);
    }

    // Find cycles using simple DFS. Track visited walls to avoid re-detection.
    final Set<String> usedInRoom = {};
    final List<DetectedRoom> rooms = [];
    int roomIndex = 0;

    // For each wall, try to trace a cycle back to its start
    for (final startWall in walls) {
      if (usedInRoom.contains(startWall.id)) continue;

      final cycle = _traceCycle(
        startWall,
        walls,
        endpointMap,
        pointKey,
        usedInRoom,
        snapThreshold,
      );

      if (cycle != null && cycle.length >= 3) {
        roomIndex++;
        final wallIds = cycle.map((w) => w.id).toList();
        final center = _computeCentroid(cycle);
        final area = _computeArea(cycle);

        for (final w in cycle) {
          usedInRoom.add(w.id);
        }

        rooms.add(DetectedRoom(
          id: 'room_$roomIndex',
          name: 'Room $roomIndex',
          wallIds: wallIds,
          center: center,
          area: area / 144.0, // convert sq inches to sq feet
        ));
      }
    }

    return rooms;
  }

  // Trace a closed cycle of walls starting from startWall
  static List<Wall>? _traceCycle(
    Wall startWall,
    List<Wall> allWalls,
    Map<String, List<Wall>> endpointMap,
    String Function(Offset) pointKey,
    Set<String> usedInRoom,
    double snapThreshold,
  ) {
    final List<Wall> path = [startWall];
    final Set<String> visited = {startWall.id};
    Offset currentEnd = startWall.end;
    final targetKey = pointKey(startWall.start);

    for (int step = 0; step < 20; step++) {
      final key = pointKey(currentEnd);

      // Check if we've returned to start
      if (step >= 2 && key == targetKey) {
        return path;
      }

      final neighbors = endpointMap[key] ?? [];
      Wall? next;

      for (final w in neighbors) {
        if (visited.contains(w.id)) continue;
        if (usedInRoom.contains(w.id)) continue;
        next = w;
        break;
      }

      if (next == null) break;

      visited.add(next.id);
      path.add(next);

      // Determine which end to continue from
      final nextStartKey = pointKey(next.start);
      if (nextStartKey == key) {
        currentEnd = next.end;
      } else {
        currentEnd = next.start;
      }
    }

    return null; // no cycle found
  }

  // Compute centroid of polygon formed by wall endpoints
  static Offset _computeCentroid(List<Wall> cycle) {
    if (cycle.isEmpty) return Offset.zero;
    double cx = 0, cy = 0;
    for (final w in cycle) {
      cx += w.start.dx;
      cy += w.start.dy;
    }
    return Offset(cx / cycle.length, cy / cycle.length);
  }

  // Compute area using shoelace formula
  static double _computeArea(List<Wall> cycle) {
    if (cycle.length < 3) return 0;
    final points = cycle.map((w) => w.start).toList();
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area.abs() / 2.0;
  }
}

// =============================================================================
// V2 TYPES — SK1 Sketch Engine Extension
// Arc walls, trade elements, damage zones, layer data structures
// =============================================================================

/// Arc wall — curved wall segment defined by center, radius, and angles
class ArcWall {
  final String id;
  final Offset center;
  final double radius;
  final double startAngle; // radians
  final double sweepAngle; // radians
  final double thickness;
  final String? material;

  const ArcWall({
    required this.id,
    required this.center,
    required this.radius,
    this.startAngle = 0.0,
    this.sweepAngle = 3.14159,
    this.thickness = 6.0,
    this.material,
  });

  // Approximate chord length for measurement display
  double get chordLength {
    final halfAngle = sweepAngle.abs() / 2;
    return 2 * radius * sin(halfAngle);
  }

  // Arc length
  double get arcLength => radius * sweepAngle.abs();

  ArcWall copyWith({
    String? id,
    Offset? center,
    double? radius,
    double? startAngle,
    double? sweepAngle,
    double? thickness,
    String? material,
  }) {
    return ArcWall(
      id: id ?? this.id,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      startAngle: startAngle ?? this.startAngle,
      sweepAngle: sweepAngle ?? this.sweepAngle,
      thickness: thickness ?? this.thickness,
      material: material ?? this.material,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'center': {'x': center.dx, 'y': center.dy},
        'radius': radius,
        'start_angle': startAngle,
        'sweep_angle': sweepAngle,
        'thickness': thickness,
        if (material != null) 'material': material,
      };

  factory ArcWall.fromJson(Map<String, dynamic> json) {
    final c = json['center'] as Map<String, dynamic>;
    return ArcWall(
      id: json['id'] as String,
      center: Offset(
        (c['x'] as num).toDouble(),
        (c['y'] as num).toDouble(),
      ),
      radius: (json['radius'] as num).toDouble(),
      startAngle: (json['start_angle'] as num?)?.toDouble() ?? 0.0,
      sweepAngle: (json['sweep_angle'] as num?)?.toDouble() ?? 3.14159,
      thickness: (json['thickness'] as num?)?.toDouble() ?? 6.0,
      material: json['material'] as String?,
    );
  }
}

// =============================================================================
// TRADE ELEMENT — symbol placed on a trade layer
// =============================================================================

enum TradeSymbolType {
  // Electrical (15 symbols)
  outlet120v, outlet240v, gfciOutlet, switchSingle, switchThreeWay,
  switchDimmer, junctionBox, panelMain, panelSub, lightFixture,
  lightRecessed, lightSwitch, smokeDetector, thermostat, ceilingFan,
  // Plumbing (12 symbols)
  pipeHot, pipeCold, pipeDrain, pipeVent, cleanout,
  shutoffValve, prv, waterMeter, seweLine, hosebibb,
  floorDrain, sumpPump,
  // HVAC (10 symbols)
  supplyDuct, returnDuct, flexDuct, register, returnGrille,
  damper, airHandler, condenser, miniSplit, exhaustFan,
  // Damage (4 symbols)
  waterDamage, fireDamage, moldPresent, asbestosWarning,
}

class TradeElement {
  final String id;
  final Offset position;
  final TradeSymbolType symbolType;
  final double rotation;
  final String? label;
  final Map<String, dynamic> properties;

  const TradeElement({
    required this.id,
    required this.position,
    required this.symbolType,
    this.rotation = 0.0,
    this.label,
    this.properties = const {},
  });

  TradeElement copyWith({
    String? id,
    Offset? position,
    TradeSymbolType? symbolType,
    double? rotation,
    String? label,
    Map<String, dynamic>? properties,
  }) {
    return TradeElement(
      id: id ?? this.id,
      position: position ?? this.position,
      symbolType: symbolType ?? this.symbolType,
      rotation: rotation ?? this.rotation,
      label: label ?? this.label,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': {'x': position.dx, 'y': position.dy},
        'symbol_type': symbolType.name,
        'rotation': rotation,
        if (label != null) 'label': label,
        if (properties.isNotEmpty) 'properties': properties,
      };

  factory TradeElement.fromJson(Map<String, dynamic> json) {
    final p = json['position'] as Map<String, dynamic>;
    return TradeElement(
      id: json['id'] as String,
      position: Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      ),
      symbolType: TradeSymbolType.values.firstWhere(
        (t) => t.name == json['symbol_type'],
        orElse: () => TradeSymbolType.outlet120v,
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
      properties:
          (json['properties'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

// =============================================================================
// TRADE PATH — line/polyline on a trade layer (pipes, ducts, wiring runs)
// =============================================================================

class TradePath {
  final String id;
  final List<Offset> points;
  final String pathType; // 'wire', 'pipe_hot', 'pipe_cold', 'duct_supply', etc.
  final double strokeWidth;
  final int colorValue;
  final bool isDashed;
  final String? label;

  const TradePath({
    required this.id,
    required this.points,
    required this.pathType,
    this.strokeWidth = 2.0,
    this.colorValue = 0xFF000000,
    this.isDashed = false,
    this.label,
  });

  double get totalLength {
    double len = 0;
    for (int i = 0; i < points.length - 1; i++) {
      len += (points[i + 1] - points[i]).distance;
    }
    return len;
  }

  TradePath copyWith({
    String? id,
    List<Offset>? points,
    String? pathType,
    double? strokeWidth,
    int? colorValue,
    bool? isDashed,
    String? label,
  }) {
    return TradePath(
      id: id ?? this.id,
      points: points ?? this.points,
      pathType: pathType ?? this.pathType,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      colorValue: colorValue ?? this.colorValue,
      isDashed: isDashed ?? this.isDashed,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points
            .map((p) => {'x': p.dx, 'y': p.dy})
            .toList(),
        'path_type': pathType,
        'stroke_width': strokeWidth,
        'color': colorValue,
        'is_dashed': isDashed,
        if (label != null) 'label': label,
      };

  factory TradePath.fromJson(Map<String, dynamic> json) {
    return TradePath(
      id: json['id'] as String,
      points: _parseOffsetList(json['points']),
      pathType: json['path_type'] as String? ?? 'wire',
      strokeWidth: (json['stroke_width'] as num?)?.toDouble() ?? 2.0,
      colorValue: json['color'] as int? ?? 0xFF000000,
      isDashed: json['is_dashed'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  static List<Offset> _parseOffsetList(dynamic list) {
    if (list == null) return [];
    return (list as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return Offset(
        (m['x'] as num).toDouble(),
        (m['y'] as num).toDouble(),
      );
    }).toList();
  }
}

// =============================================================================
// DAMAGE ZONE — polygonal area marking damage extent
// =============================================================================

class DamageZone {
  final String id;
  final List<Offset> boundary;
  final String damageType; // 'water', 'fire', 'mold', 'impact', 'structural'
  final String severity; // 'minor', 'moderate', 'severe', 'catastrophic'
  final String? damageClass; // IICRC 1-4
  final String? iicrcCategory; // IICRC 1-3
  final String? notes;
  final int colorValue;

  const DamageZone({
    required this.id,
    required this.boundary,
    required this.damageType,
    this.severity = 'moderate',
    this.damageClass,
    this.iicrcCategory,
    this.notes,
    this.colorValue = 0x40F44336, // semi-transparent red
  });

  double get areaSqInches {
    if (boundary.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < boundary.length; i++) {
      final j = (i + 1) % boundary.length;
      area += boundary[i].dx * boundary[j].dy;
      area -= boundary[j].dx * boundary[i].dy;
    }
    return area.abs() / 2.0;
  }

  double get areaSqFt => areaSqInches / 144.0;

  DamageZone copyWith({
    String? id,
    List<Offset>? boundary,
    String? damageType,
    String? severity,
    String? damageClass,
    String? iicrcCategory,
    String? notes,
    int? colorValue,
  }) {
    return DamageZone(
      id: id ?? this.id,
      boundary: boundary ?? this.boundary,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      damageClass: damageClass ?? this.damageClass,
      iicrcCategory: iicrcCategory ?? this.iicrcCategory,
      notes: notes ?? this.notes,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'boundary': boundary
            .map((p) => {'x': p.dx, 'y': p.dy})
            .toList(),
        'damage_type': damageType,
        'severity': severity,
        if (damageClass != null) 'damage_class': damageClass,
        if (iicrcCategory != null) 'iicrc_category': iicrcCategory,
        if (notes != null) 'notes': notes,
        'color': colorValue,
      };

  factory DamageZone.fromJson(Map<String, dynamic> json) {
    return DamageZone(
      id: json['id'] as String,
      boundary: _parseOffsetList(json['boundary']),
      damageType: json['damage_type'] as String? ?? 'water',
      severity: json['severity'] as String? ?? 'moderate',
      damageClass: json['damage_class'] as String?,
      iicrcCategory: json['iicrc_category'] as String?,
      notes: json['notes'] as String?,
      colorValue: json['color'] as int? ?? 0x40F44336,
    );
  }

  static List<Offset> _parseOffsetList(dynamic list) {
    if (list == null) return [];
    return (list as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return Offset(
        (m['x'] as num).toDouble(),
        (m['y'] as num).toDouble(),
      );
    }).toList();
  }
}

// =============================================================================
// DAMAGE BARRIER — equipment placement markers (dehu, air mover, etc.)
// =============================================================================

enum BarrierType {
  dehumidifier, airMover, airScrubber, containmentBarrier,
  negativePressure, moistureMeter, thermalCamera, dryingMat,
}

class DamageBarrier {
  final String id;
  final Offset position;
  final BarrierType barrierType;
  final double rotation;
  final String? label;
  final String? equipmentId;

  const DamageBarrier({
    required this.id,
    required this.position,
    required this.barrierType,
    this.rotation = 0.0,
    this.label,
    this.equipmentId,
  });

  DamageBarrier copyWith({
    String? id,
    Offset? position,
    BarrierType? barrierType,
    double? rotation,
    String? label,
    String? equipmentId,
  }) {
    return DamageBarrier(
      id: id ?? this.id,
      position: position ?? this.position,
      barrierType: barrierType ?? this.barrierType,
      rotation: rotation ?? this.rotation,
      label: label ?? this.label,
      equipmentId: equipmentId ?? this.equipmentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': {'x': position.dx, 'y': position.dy},
        'barrier_type': barrierType.name,
        'rotation': rotation,
        if (label != null) 'label': label,
        if (equipmentId != null) 'equipment_id': equipmentId,
      };

  factory DamageBarrier.fromJson(Map<String, dynamic> json) {
    final p = json['position'] as Map<String, dynamic>;
    return DamageBarrier(
      id: json['id'] as String,
      position: Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      ),
      barrierType: BarrierType.values.firstWhere(
        (t) => t.name == json['barrier_type'],
        orElse: () => BarrierType.dehumidifier,
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
      equipmentId: json['equipment_id'] as String?,
    );
  }
}

// =============================================================================
// TRADE LAYER DATA — structured data stored in floor_plan_layers.layer_data
// =============================================================================

class TradeLayerData {
  final List<TradeElement> elements;
  final List<TradePath> paths;

  const TradeLayerData({
    this.elements = const [],
    this.paths = const [],
  });

  TradeLayerData copyWith({
    List<TradeElement>? elements,
    List<TradePath>? paths,
  }) {
    return TradeLayerData(
      elements: elements ?? this.elements,
      paths: paths ?? this.paths,
    );
  }

  Map<String, dynamic> toJson() => {
        'elements': elements.map((e) => e.toJson()).toList(),
        'paths': paths.map((e) => e.toJson()).toList(),
      };

  factory TradeLayerData.fromJson(Map<String, dynamic> json) {
    return TradeLayerData(
      elements: _parseList(json['elements'], TradeElement.fromJson),
      paths: _parseList(json['paths'], TradePath.fromJson),
    );
  }

  static List<T> _parseList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => parser(e as Map<String, dynamic>))
        .toList();
  }
}

// =============================================================================
// DAMAGE LAYER DATA — structured data for damage overlay layer
// =============================================================================

class DamageLayerData {
  final List<DamageZone> zones;
  final List<DamageBarrier> barriers;

  const DamageLayerData({
    this.zones = const [],
    this.barriers = const [],
  });

  DamageLayerData copyWith({
    List<DamageZone>? zones,
    List<DamageBarrier>? barriers,
  }) {
    return DamageLayerData(
      zones: zones ?? this.zones,
      barriers: barriers ?? this.barriers,
    );
  }

  Map<String, dynamic> toJson() => {
        'zones': zones.map((e) => e.toJson()).toList(),
        'barriers': barriers.map((e) => e.toJson()).toList(),
      };

  factory DamageLayerData.fromJson(Map<String, dynamic> json) {
    return DamageLayerData(
      zones: _parseList(json['zones'], DamageZone.fromJson),
      barriers: _parseList(json['barriers'], DamageBarrier.fromJson),
    );
  }

  static List<T> _parseList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => parser(e as Map<String, dynamic>))
        .toList();
  }
}

// =============================================================================
// FLOOR PLAN DATA V2 — Extended container with trade layers and arc walls
// Backward compatible: V1 data (no 'version' field) is treated as V2 with
// empty trade layers and no arc walls.
// =============================================================================

enum MeasurementUnit { imperial, metric }

class FloorPlanDataV2 {
  final int version;
  final List<Wall> walls;
  final List<ArcWall> arcWalls;
  final List<DoorPlacement> doors;
  final List<WindowPlacement> windows;
  final List<FixturePlacement> fixtures;
  final List<FloorLabel> labels;
  final List<DimensionLine> dimensions;
  final List<DetectedRoom> rooms;
  final double scale;
  final MeasurementUnit units;

  const FloorPlanDataV2({
    this.version = 2,
    this.walls = const [],
    this.arcWalls = const [],
    this.doors = const [],
    this.windows = const [],
    this.fixtures = const [],
    this.labels = const [],
    this.dimensions = const [],
    this.rooms = const [],
    this.scale = 4.0,
    this.units = MeasurementUnit.imperial,
  });

  /// Convert V1 FloorPlanData to V2 (lossless upgrade)
  factory FloorPlanDataV2.fromV1(FloorPlanData v1) {
    return FloorPlanDataV2(
      walls: v1.walls,
      doors: v1.doors,
      windows: v1.windows,
      fixtures: v1.fixtures,
      labels: v1.labels,
      dimensions: v1.dimensions,
      rooms: v1.rooms,
      scale: v1.scale,
    );
  }

  /// Downgrade to V1 for backward compatibility (loses arc walls)
  FloorPlanData toV1() {
    return FloorPlanData(
      walls: walls,
      doors: doors,
      windows: windows,
      fixtures: fixtures,
      labels: labels,
      dimensions: dimensions,
      rooms: rooms,
      scale: scale,
    );
  }

  FloorPlanDataV2 copyWith({
    int? version,
    List<Wall>? walls,
    List<ArcWall>? arcWalls,
    List<DoorPlacement>? doors,
    List<WindowPlacement>? windows,
    List<FixturePlacement>? fixtures,
    List<FloorLabel>? labels,
    List<DimensionLine>? dimensions,
    List<DetectedRoom>? rooms,
    double? scale,
    MeasurementUnit? units,
  }) {
    return FloorPlanDataV2(
      version: version ?? this.version,
      walls: walls ?? this.walls,
      arcWalls: arcWalls ?? this.arcWalls,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      fixtures: fixtures ?? this.fixtures,
      labels: labels ?? this.labels,
      dimensions: dimensions ?? this.dimensions,
      rooms: rooms ?? this.rooms,
      scale: scale ?? this.scale,
      units: units ?? this.units,
    );
  }

  Wall? wallById(String id) {
    for (final w in walls) {
      if (w.id == id) return w;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'walls': walls.map((e) => e.toJson()).toList(),
        'arc_walls': arcWalls.map((e) => e.toJson()).toList(),
        'doors': doors.map((e) => e.toJson()).toList(),
        'windows': windows.map((e) => e.toJson()).toList(),
        'fixtures': fixtures.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => e.toJson()).toList(),
        'dimensions': dimensions.map((e) => e.toJson()).toList(),
        'rooms': rooms.map((e) => e.toJson()).toList(),
        'scale': scale,
        'units': units.name,
      };

  /// Parse from JSON with automatic V1/V2 detection.
  /// If 'version' field is absent, treats as V1 data (empty arc_walls).
  factory FloorPlanDataV2.fromJson(Map<String, dynamic> json) {
    return FloorPlanDataV2(
      version: json['version'] as int? ?? 1,
      walls: _parseList(json['walls'], Wall.fromJson),
      arcWalls: _parseList(json['arc_walls'], ArcWall.fromJson),
      doors: _parseList(json['doors'], DoorPlacement.fromJson),
      windows: _parseList(json['windows'], WindowPlacement.fromJson),
      fixtures: _parseList(json['fixtures'], FixturePlacement.fromJson),
      labels: _parseList(json['labels'], FloorLabel.fromJson),
      dimensions: _parseList(json['dimensions'], DimensionLine.fromJson),
      rooms: _parseList(json['rooms'], DetectedRoom.fromJson),
      scale: (json['scale'] as num?)?.toDouble() ?? 4.0,
      units: _parseUnit(json['units'] as String?),
    );
  }

  static MeasurementUnit _parseUnit(String? value) {
    if (value == 'metric') return MeasurementUnit.metric;
    return MeasurementUnit.imperial;
  }

  static List<T> _parseList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => parser(e as Map<String, dynamic>))
        .toList();
  }
}
