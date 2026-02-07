// ZAFTO Floor Plan Elements — Data Models
// Typed representations of all elements stored in property_floor_plans.plan_data JSONB.
// All coordinates use a virtual canvas coordinate system (1 unit = 1 inch).

import 'dart:math';
import 'dart:ui';

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
  final String? material;

  const Wall({
    required this.id,
    required this.start,
    required this.end,
    this.thickness = 6.0,
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
    String? material,
  }) {
    return Wall(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      thickness: thickness ?? this.thickness,
      material: material ?? this.material,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': {'x': start.dx, 'y': start.dy},
        'end': {'x': end.dx, 'y': end.dy},
        'thickness': thickness,
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
  final List<DoorPlacement> doors;
  final List<WindowPlacement> windows;
  final List<FixturePlacement> fixtures;
  final List<FloorLabel> labels;
  final List<DimensionLine> dimensions;
  final List<DetectedRoom> rooms;
  final double scale; // pixels per unit (inch)

  const FloorPlanData({
    this.walls = const [],
    this.doors = const [],
    this.windows = const [],
    this.fixtures = const [],
    this.labels = const [],
    this.dimensions = const [],
    this.rooms = const [],
    this.scale = 4.0,
  });

  FloorPlanData copyWith({
    List<Wall>? walls,
    List<DoorPlacement>? doors,
    List<WindowPlacement>? windows,
    List<FixturePlacement>? fixtures,
    List<FloorLabel>? labels,
    List<DimensionLine>? dimensions,
    List<DetectedRoom>? rooms,
    double? scale,
  }) {
    return FloorPlanData(
      walls: walls ?? this.walls,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      fixtures: fixtures ?? this.fixtures,
      labels: labels ?? this.labels,
      dimensions: dimensions ?? this.dimensions,
      rooms: rooms ?? this.rooms,
      scale: scale ?? this.scale,
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
        'doors': doors.map((e) => e.toJson()).toList(),
        'windows': windows.map((e) => e.toJson()).toList(),
        'fixtures': fixtures.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => e.toJson()).toList(),
        'dimensions': dimensions.map((e) => e.toJson()).toList(),
        'rooms': rooms.map((e) => e.toJson()).toList(),
        'scale': scale,
      };

  factory FloorPlanData.fromJson(Map<String, dynamic> json) {
    return FloorPlanData(
      walls: _parseList(json['walls'], Wall.fromJson),
      doors: _parseList(json['doors'], DoorPlacement.fromJson),
      windows: _parseList(json['windows'], WindowPlacement.fromJson),
      fixtures: _parseList(json['fixtures'], FixturePlacement.fromJson),
      labels: _parseList(json['labels'], FloorLabel.fromJson),
      dimensions: _parseList(json['dimensions'], DimensionLine.fromJson),
      rooms: _parseList(json['rooms'], DetectedRoom.fromJson),
      scale: (json['scale'] as num?)?.toDouble() ?? 4.0,
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
// SKETCH TOOL ENUM
// =============================================================================

enum SketchTool {
  select,
  wall,
  door,
  window,
  fixture,
  label,
  dimension,
  erase,
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
