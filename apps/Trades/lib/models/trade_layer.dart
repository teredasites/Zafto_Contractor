// ZAFTO Trade Layer Model — SK4
// Wraps trade overlay layers (electrical, plumbing, HVAC, damage) with
// visibility/lock/opacity controls. Each layer contains typed elements and
// paths that composite on top of the base floor plan.

import 'dart:ui';

import 'floor_plan_elements.dart';

// =============================================================================
// TRADE LAYER TYPE
// =============================================================================

enum TradeLayerType {
  electrical,
  plumbing,
  hvac,
  damage,
}

const Map<TradeLayerType, String> tradeLayerLabels = {
  TradeLayerType.electrical: 'Electrical',
  TradeLayerType.plumbing: 'Plumbing',
  TradeLayerType.hvac: 'HVAC',
  TradeLayerType.damage: 'Damage',
};

// Standard colors for each layer type
const Map<TradeLayerType, int> tradeLayerColors = {
  TradeLayerType.electrical: 0xFFEAB308, // amber
  TradeLayerType.plumbing: 0xFF3B82F6, // blue
  TradeLayerType.hvac: 0xFF22C55E, // green
  TradeLayerType.damage: 0xFFEF4444, // red
};

// =============================================================================
// TRADE LAYER — wraps layer metadata + typed data
// =============================================================================

class TradeLayer {
  final String id;
  final TradeLayerType type;
  final String name;
  final bool visible;
  final bool locked;
  final double opacity; // 0.0 - 1.0
  final TradeLayerData tradeData; // elements + paths (elec/plumb/hvac)
  final DamageLayerData damageData; // zones + barriers (damage only)
  final List<MoistureReading> moistureReadings; // damage only
  final List<ContainmentLine> containmentLines; // damage only

  TradeLayer({
    required this.id,
    required this.type,
    String? name,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.tradeData = const TradeLayerData(),
    this.damageData = const DamageLayerData(),
    this.moistureReadings = const [],
    this.containmentLines = const [],
  }) : name = name ?? (tradeLayerLabels[type] ?? 'Layer');

  int get colorValue => tradeLayerColors[type] ?? 0xFF6B7280;
  Color get color => Color(colorValue);

  bool get isEmpty =>
      tradeData.elements.isEmpty &&
      tradeData.paths.isEmpty &&
      damageData.zones.isEmpty &&
      damageData.barriers.isEmpty &&
      moistureReadings.isEmpty &&
      containmentLines.isEmpty;

  TradeLayer copyWith({
    String? id,
    TradeLayerType? type,
    String? name,
    bool? visible,
    bool? locked,
    double? opacity,
    TradeLayerData? tradeData,
    DamageLayerData? damageData,
    List<MoistureReading>? moistureReadings,
    List<ContainmentLine>? containmentLines,
  }) {
    return TradeLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      tradeData: tradeData ?? this.tradeData,
      damageData: damageData ?? this.damageData,
      moistureReadings: moistureReadings ?? this.moistureReadings,
      containmentLines: containmentLines ?? this.containmentLines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'visible': visible,
        'locked': locked,
        'opacity': opacity,
        'trade_data': tradeData.toJson(),
        'damage_data': damageData.toJson(),
        'moisture_readings':
            moistureReadings.map((e) => e.toJson()).toList(),
        'containment_lines':
            containmentLines.map((e) => e.toJson()).toList(),
      };

  factory TradeLayer.fromJson(Map<String, dynamic> json) {
    return TradeLayer(
      id: json['id'] as String,
      type: TradeLayerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TradeLayerType.electrical,
      ),
      name: json['name'] as String?,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      tradeData: json['trade_data'] != null
          ? TradeLayerData.fromJson(
              json['trade_data'] as Map<String, dynamic>)
          : const TradeLayerData(),
      damageData: json['damage_data'] != null
          ? DamageLayerData.fromJson(
              json['damage_data'] as Map<String, dynamic>)
          : const DamageLayerData(),
      moistureReadings: _parseList(
          json['moisture_readings'], MoistureReading.fromJson),
      containmentLines: _parseList(
          json['containment_lines'], ContainmentLine.fromJson),
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
// MOISTURE READING — point measurement on damage layer
// =============================================================================

class MoistureReading {
  final String id;
  final Offset position;
  final double value; // percentage (0-100)
  final String severity; // 'dry', 'warning', 'wet', 'saturated'
  final String? materialType; // 'drywall', 'wood', 'concrete', etc.
  final DateTime? timestamp;

  const MoistureReading({
    required this.id,
    required this.position,
    required this.value,
    this.severity = 'dry',
    this.materialType,
    this.timestamp,
  });

  // Severity thresholds per IICRC S500
  static String severityFromValue(double value, {String? material}) {
    if (value <= 15) return 'dry';
    if (value <= 30) return 'warning';
    if (value <= 60) return 'wet';
    return 'saturated';
  }

  int get severityColor {
    switch (severity) {
      case 'dry':
        return 0xFF22C55E; // green
      case 'warning':
        return 0xFFEAB308; // amber
      case 'wet':
        return 0xFFF97316; // orange
      case 'saturated':
        return 0xFFEF4444; // red
      default:
        return 0xFF6B7280; // gray
    }
  }

  MoistureReading copyWith({
    String? id,
    Offset? position,
    double? value,
    String? severity,
    String? materialType,
    DateTime? timestamp,
  }) {
    return MoistureReading(
      id: id ?? this.id,
      position: position ?? this.position,
      value: value ?? this.value,
      severity: severity ?? this.severity,
      materialType: materialType ?? this.materialType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': {'x': position.dx, 'y': position.dy},
        'value': value,
        'severity': severity,
        if (materialType != null) 'material_type': materialType,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  factory MoistureReading.fromJson(Map<String, dynamic> json) {
    final p = json['position'] as Map<String, dynamic>;
    return MoistureReading(
      id: json['id'] as String,
      position: Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      ),
      value: (json['value'] as num).toDouble(),
      severity: json['severity'] as String? ?? 'dry',
      materialType: json['material_type'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }
}

// =============================================================================
// CONTAINMENT LINE — dashed barrier line on damage layer
// =============================================================================

class ContainmentLine {
  final String id;
  final Offset start;
  final Offset end;
  final String barrierType; // 'containment', 'negative_pressure', 'decon'
  final String? label;

  const ContainmentLine({
    required this.id,
    required this.start,
    required this.end,
    this.barrierType = 'containment',
    this.label,
  });

  double get length => (end - start).distance;

  ContainmentLine copyWith({
    String? id,
    Offset? start,
    Offset? end,
    String? barrierType,
    String? label,
  }) {
    return ContainmentLine(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      barrierType: barrierType ?? this.barrierType,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': {'x': start.dx, 'y': start.dy},
        'end': {'x': end.dx, 'y': end.dy},
        'barrier_type': barrierType,
        if (label != null) 'label': label,
      };

  factory ContainmentLine.fromJson(Map<String, dynamic> json) {
    final s = json['start'] as Map<String, dynamic>;
    final e = json['end'] as Map<String, dynamic>;
    return ContainmentLine(
      id: json['id'] as String,
      start: Offset(
        (s['x'] as num).toDouble(),
        (s['y'] as num).toDouble(),
      ),
      end: Offset(
        (e['x'] as num).toDouble(),
        (e['y'] as num).toDouble(),
      ),
      barrierType: json['barrier_type'] as String? ?? 'containment',
      label: json['label'] as String?,
    );
  }
}

// =============================================================================
// IICRC CONSTANTS — Water damage classification
// =============================================================================

class IicrcClassification {
  // Damage Classes (extent of water absorption)
  static const Map<String, String> damageClasses = {
    '1': 'Class 1 — Least amount of absorption',
    '2': 'Class 2 — Significant absorption (up to 24" wall wicking)',
    '3': 'Class 3 — Greatest absorption (ceilings, walls, insulation)',
    '4': 'Class 4 — Specialty drying (hardwood, concrete, stone)',
  };

  // Water Categories (contamination level)
  static const Map<String, String> waterCategories = {
    '1': 'Cat 1 — Clean water (supply lines)',
    '2': 'Cat 2 — Gray water (dishwasher, washing machine)',
    '3': 'Cat 3 — Black water (sewage, flooding)',
  };

  // IICRC category colors for overlay tinting
  static int colorForCategory(String? category) {
    switch (category) {
      case '1':
        return 0x302563EB; // blue tint
      case '2':
        return 0x30EAB308; // yellow tint
      case '3':
        return 0x30EF4444; // red tint
      default:
        return 0x206B7280; // gray tint
    }
  }

  // Damage class colors for zone outlines
  static int colorForClass(String? damageClass) {
    switch (damageClass) {
      case '1':
        return 0xFF22C55E; // green
      case '2':
        return 0xFFEAB308; // yellow
      case '3':
        return 0xFFF97316; // orange
      case '4':
        return 0xFFEF4444; // red
      default:
        return 0xFF6B7280; // gray
    }
  }
}

// =============================================================================
// TRADE TOOL ENUM — tools available per trade layer
// =============================================================================

enum TradeTool {
  // Shared
  select,
  erase,

  // Electrical
  placeElecSymbol,
  drawWire,
  drawCircuit,

  // Plumbing
  placePlumbSymbol,
  drawPipeHot,
  drawPipeCold,
  drawPipeDrain,
  drawPipeGas,

  // HVAC
  placeHvacSymbol,
  drawDuctSupply,
  drawDuctReturn,

  // Damage
  drawDamageZone,
  placeMoisture,
  drawContainment,
  placeEquipment,
}

// Map trade layer type to available tools
const Map<TradeLayerType, List<TradeTool>> tradeToolsForLayer = {
  TradeLayerType.electrical: [
    TradeTool.select,
    TradeTool.placeElecSymbol,
    TradeTool.drawWire,
    TradeTool.drawCircuit,
    TradeTool.erase,
  ],
  TradeLayerType.plumbing: [
    TradeTool.select,
    TradeTool.placePlumbSymbol,
    TradeTool.drawPipeHot,
    TradeTool.drawPipeCold,
    TradeTool.drawPipeDrain,
    TradeTool.drawPipeGas,
    TradeTool.erase,
  ],
  TradeLayerType.hvac: [
    TradeTool.select,
    TradeTool.placeHvacSymbol,
    TradeTool.drawDuctSupply,
    TradeTool.drawDuctReturn,
    TradeTool.erase,
  ],
  TradeLayerType.damage: [
    TradeTool.select,
    TradeTool.drawDamageZone,
    TradeTool.placeMoisture,
    TradeTool.drawContainment,
    TradeTool.placeEquipment,
    TradeTool.erase,
  ],
};

// Trade symbol groups for toolbar pickers
const Map<TradeLayerType, Map<String, List<TradeSymbolType>>>
    tradeSymbolGroups = {
  TradeLayerType.electrical: {
    'Receptacles': [
      TradeSymbolType.outlet120v,
      TradeSymbolType.outlet240v,
      TradeSymbolType.gfciOutlet,
    ],
    'Switches': [
      TradeSymbolType.switchSingle,
      TradeSymbolType.switchThreeWay,
      TradeSymbolType.switchDimmer,
    ],
    'Lighting': [
      TradeSymbolType.lightFixture,
      TradeSymbolType.lightRecessed,
      TradeSymbolType.ceilingFan,
    ],
    'Equipment': [
      TradeSymbolType.panelMain,
      TradeSymbolType.panelSub,
      TradeSymbolType.junctionBox,
      TradeSymbolType.smokeDetector,
      TradeSymbolType.thermostat,
    ],
  },
  TradeLayerType.plumbing: {
    'Fixtures': [
      TradeSymbolType.shutoffValve,
      TradeSymbolType.prv,
      TradeSymbolType.cleanout,
      TradeSymbolType.floorDrain,
      TradeSymbolType.sumpPump,
    ],
    'Connections': [
      TradeSymbolType.waterMeter,
      TradeSymbolType.hosebibb,
      TradeSymbolType.seweLine,
    ],
  },
  TradeLayerType.hvac: {
    'Equipment': [
      TradeSymbolType.airHandler,
      TradeSymbolType.condenser,
      TradeSymbolType.miniSplit,
      TradeSymbolType.exhaustFan,
    ],
    'Distribution': [
      TradeSymbolType.register,
      TradeSymbolType.returnGrille,
      TradeSymbolType.damper,
    ],
  },
  TradeLayerType.damage: {
    'Indicators': [
      TradeSymbolType.waterDamage,
      TradeSymbolType.fireDamage,
      TradeSymbolType.moldPresent,
      TradeSymbolType.asbestosWarning,
    ],
  },
};

// Labels for trade symbols
const Map<TradeSymbolType, String> tradeSymbolLabels = {
  // Electrical
  TradeSymbolType.outlet120v: '120V Outlet',
  TradeSymbolType.outlet240v: '240V Outlet',
  TradeSymbolType.gfciOutlet: 'GFCI Outlet',
  TradeSymbolType.switchSingle: 'Single Switch',
  TradeSymbolType.switchThreeWay: '3-Way Switch',
  TradeSymbolType.switchDimmer: 'Dimmer',
  TradeSymbolType.junctionBox: 'J-Box',
  TradeSymbolType.panelMain: 'Main Panel',
  TradeSymbolType.panelSub: 'Sub Panel',
  TradeSymbolType.lightFixture: 'Light',
  TradeSymbolType.lightRecessed: 'Recessed',
  TradeSymbolType.lightSwitch: 'Light Switch',
  TradeSymbolType.smokeDetector: 'Smoke Det.',
  TradeSymbolType.thermostat: 'Thermostat',
  TradeSymbolType.ceilingFan: 'Ceiling Fan',
  // Plumbing
  TradeSymbolType.pipeHot: 'Hot Pipe',
  TradeSymbolType.pipeCold: 'Cold Pipe',
  TradeSymbolType.pipeDrain: 'Drain Pipe',
  TradeSymbolType.pipeVent: 'Vent Pipe',
  TradeSymbolType.cleanout: 'Cleanout',
  TradeSymbolType.shutoffValve: 'Shutoff Valve',
  TradeSymbolType.prv: 'PRV',
  TradeSymbolType.waterMeter: 'Water Meter',
  TradeSymbolType.seweLine: 'Sewer Line',
  TradeSymbolType.hosebibb: 'Hose Bibb',
  TradeSymbolType.floorDrain: 'Floor Drain',
  TradeSymbolType.sumpPump: 'Sump Pump',
  // HVAC
  TradeSymbolType.supplyDuct: 'Supply Duct',
  TradeSymbolType.returnDuct: 'Return Duct',
  TradeSymbolType.flexDuct: 'Flex Duct',
  TradeSymbolType.register: 'Register',
  TradeSymbolType.returnGrille: 'Return Grille',
  TradeSymbolType.damper: 'Damper',
  TradeSymbolType.airHandler: 'Air Handler',
  TradeSymbolType.condenser: 'Condenser',
  TradeSymbolType.miniSplit: 'Mini-Split',
  TradeSymbolType.exhaustFan: 'Exhaust Fan',
  // Damage
  TradeSymbolType.waterDamage: 'Water Damage',
  TradeSymbolType.fireDamage: 'Fire Damage',
  TradeSymbolType.moldPresent: 'Mold Present',
  TradeSymbolType.asbestosWarning: 'Asbestos',
};

// Pipe path type → color mapping
const Map<String, int> pipePathColors = {
  'pipe_hot': 0xFFEF4444, // red
  'pipe_cold': 0xFF3B82F6, // blue
  'pipe_drain': 0xFF6B7280, // gray
  'pipe_gas': 0xFFEAB308, // yellow
  'pipe_vent': 0xFF8B5CF6, // purple
  'wire': 0xFFEAB308, // yellow (electrical)
  'circuit': 0xFFF97316, // orange (electrical circuit)
  'duct_supply': 0xFF3B82F6, // blue
  'duct_return': 0xFFEF4444, // red
  'duct_flex': 0xFF22C55E, // green
};

// =============================================================================
// TRADE LAYER COMMANDS — undo/redo for trade layer operations
// =============================================================================

class AddTradeElementCommand extends SketchCommand {
  final String layerId;
  final TradeElement element;
  AddTradeElementCommand({required this.layerId, required this.element});

  @override
  FloorPlanData execute(FloorPlanData data) => _updateLayer(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _updateLayer(data, false);

  FloorPlanData _updateLayer(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final elements = add
            ? [...l.tradeData.elements, element]
            : l.tradeData.elements
                .where((e) => e.id != element.id)
                .toList();
        return l.copyWith(
            tradeData: l.tradeData.copyWith(elements: elements));
      }).toList(),
    );
  }
}

class RemoveTradeElementCommand extends SketchCommand {
  final String layerId;
  final TradeElement element;
  RemoveTradeElementCommand({required this.layerId, required this.element});

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          tradeData: l.tradeData.copyWith(
            elements: l.tradeData.elements
                .where((e) => e.id != element.id)
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          tradeData: l.tradeData.copyWith(
            elements: [...l.tradeData.elements, element],
          ),
        );
      }).toList(),
    );
  }
}

class AddTradePathCommand extends SketchCommand {
  final String layerId;
  final TradePath path;
  AddTradePathCommand({required this.layerId, required this.path});

  @override
  FloorPlanData execute(FloorPlanData data) => _update(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _update(data, false);

  FloorPlanData _update(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final paths = add
            ? [...l.tradeData.paths, path]
            : l.tradeData.paths
                .where((p) => p.id != path.id)
                .toList();
        return l.copyWith(
            tradeData: l.tradeData.copyWith(paths: paths));
      }).toList(),
    );
  }
}

class RemoveTradePathCommand extends SketchCommand {
  final String layerId;
  final TradePath path;
  RemoveTradePathCommand({required this.layerId, required this.path});

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          tradeData: l.tradeData.copyWith(
            paths: l.tradeData.paths
                .where((p) => p.id != path.id)
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          tradeData: l.tradeData.copyWith(
            paths: [...l.tradeData.paths, path],
          ),
        );
      }).toList(),
    );
  }
}

class AddDamageZoneCommand extends SketchCommand {
  final String layerId;
  final DamageZone zone;
  AddDamageZoneCommand({required this.layerId, required this.zone});

  @override
  FloorPlanData execute(FloorPlanData data) => _update(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _update(data, false);

  FloorPlanData _update(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final zones = add
            ? [...l.damageData.zones, zone]
            : l.damageData.zones
                .where((z) => z.id != zone.id)
                .toList();
        return l.copyWith(
            damageData: l.damageData.copyWith(zones: zones));
      }).toList(),
    );
  }
}

class RemoveDamageZoneCommand extends SketchCommand {
  final String layerId;
  final DamageZone zone;
  RemoveDamageZoneCommand({required this.layerId, required this.zone});

  @override
  FloorPlanData execute(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          damageData: l.damageData.copyWith(
            zones: l.damageData.zones
                .where((z) => z.id != zone.id)
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  FloorPlanData undo(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          damageData: l.damageData.copyWith(
            zones: [...l.damageData.zones, zone],
          ),
        );
      }).toList(),
    );
  }
}

class AddMoistureReadingCommand extends SketchCommand {
  final String layerId;
  final MoistureReading reading;
  AddMoistureReadingCommand({required this.layerId, required this.reading});

  @override
  FloorPlanData execute(FloorPlanData data) => _update(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _update(data, false);

  FloorPlanData _update(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final readings = add
            ? [...l.moistureReadings, reading]
            : l.moistureReadings
                .where((r) => r.id != reading.id)
                .toList();
        return l.copyWith(moistureReadings: readings);
      }).toList(),
    );
  }
}

class AddContainmentLineCommand extends SketchCommand {
  final String layerId;
  final ContainmentLine line;
  AddContainmentLineCommand({required this.layerId, required this.line});

  @override
  FloorPlanData execute(FloorPlanData data) => _update(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _update(data, false);

  FloorPlanData _update(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final lines = add
            ? [...l.containmentLines, line]
            : l.containmentLines
                .where((c) => c.id != line.id)
                .toList();
        return l.copyWith(containmentLines: lines);
      }).toList(),
    );
  }
}

class AddDamageBarrierCommand extends SketchCommand {
  final String layerId;
  final DamageBarrier barrier;
  AddDamageBarrierCommand({required this.layerId, required this.barrier});

  @override
  FloorPlanData execute(FloorPlanData data) => _update(data, true);
  @override
  FloorPlanData undo(FloorPlanData data) => _update(data, false);

  FloorPlanData _update(FloorPlanData data, bool add) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        final barriers = add
            ? [...l.damageData.barriers, barrier]
            : l.damageData.barriers
                .where((b) => b.id != barrier.id)
                .toList();
        return l.copyWith(
            damageData: l.damageData.copyWith(barriers: barriers));
      }).toList(),
    );
  }
}

class MoveTradeElementCommand extends SketchCommand {
  final String layerId;
  final String elementId;
  final Offset oldPosition;
  final Offset newPosition;

  MoveTradeElementCommand({
    required this.layerId,
    required this.elementId,
    required this.oldPosition,
    required this.newPosition,
  });

  @override
  FloorPlanData execute(FloorPlanData data) =>
      _apply(data, newPosition);
  @override
  FloorPlanData undo(FloorPlanData data) =>
      _apply(data, oldPosition);

  FloorPlanData _apply(FloorPlanData data, Offset pos) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(
          tradeData: l.tradeData.copyWith(
            elements: l.tradeData.elements.map((e) {
              if (e.id == elementId) return e.copyWith(position: pos);
              return e;
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// Toggle layer visibility command
class ToggleLayerVisibilityCommand extends SketchCommand {
  final String layerId;
  ToggleLayerVisibilityCommand(this.layerId);

  @override
  FloorPlanData execute(FloorPlanData data) => _toggle(data);
  @override
  FloorPlanData undo(FloorPlanData data) => _toggle(data);

  FloorPlanData _toggle(FloorPlanData data) {
    return data.copyWith(
      tradeLayers: data.tradeLayers.map((l) {
        if (l.id != layerId) return l;
        return l.copyWith(visible: !l.visible);
      }).toList(),
    );
  }
}
