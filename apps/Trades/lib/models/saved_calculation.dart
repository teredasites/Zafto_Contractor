import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'saved_calculation.g.dart';

/// Calculator types matching screen IDs
@HiveType(typeId: 10)
enum CalculatorType {
  @HiveField(0)
  voltageDrop,
  @HiveField(1)
  wireSizing,
  @HiveField(2)
  conduitFill,
  @HiveField(3)
  boxFill,
  @HiveField(4)
  motorFla,
  @HiveField(5)
  ampacity,
  @HiveField(6)
  conduitBending,
  @HiveField(7)
  dwellingLoad,
  @HiveField(8)
  transformer,
  @HiveField(9)
  grounding,
  @HiveField(10)
  powerConverter,
  @HiveField(11)
  pullBox,
  @HiveField(12)
  motorCircuit,
  @HiveField(13)
  faultCurrent,
  @HiveField(14)
  commercialLoad,
  @HiveField(15)
  tapRule,
  @HiveField(16)
  lumen,
  @HiveField(17)
  unitConverter,
  @HiveField(18)
  raceway,
  @HiveField(19)
  parallelConductor,
  @HiveField(20)
  powerFactor,
  @HiveField(21)
  disconnect,
  @HiveField(22)
  serviceEntrance,
  @HiveField(23)
  evCharger,
  @HiveField(24)
  solarPv,
  @HiveField(25)
  electricRange,
  @HiveField(26)
  dryerCircuit,
  @HiveField(27)
  waterHeater,
  @HiveField(28)
  generatorSizing,
  @HiveField(29)
  continuousLoad,
  @HiveField(30)
  motorInrush,
  @HiveField(31)
  mwbc,
  @HiveField(32)
  cableTray,
  @HiveField(33)
  lightingSqft,
  @HiveField(34)
  ohmsLaw,
}

/// Extension for calculator display names
extension CalculatorTypeExtension on CalculatorType {
  String get displayName {
    switch (this) {
      case CalculatorType.voltageDrop:
        return 'Voltage Drop';
      case CalculatorType.wireSizing:
        return 'Wire Sizing';
      case CalculatorType.conduitFill:
        return 'Conduit Fill';
      case CalculatorType.boxFill:
        return 'Box Fill';
      case CalculatorType.motorFla:
        return 'Motor FLA';
      case CalculatorType.ampacity:
        return 'Ampacity';
      case CalculatorType.conduitBending:
        return 'Conduit Bending';
      case CalculatorType.dwellingLoad:
        return 'Dwelling Load';
      case CalculatorType.transformer:
        return 'Transformer';
      case CalculatorType.grounding:
        return 'Grounding';
      case CalculatorType.powerConverter:
        return 'Power Converter';
      case CalculatorType.pullBox:
        return 'Pull Box';
      case CalculatorType.motorCircuit:
        return 'Motor Circuit';
      case CalculatorType.faultCurrent:
        return 'Fault Current';
      case CalculatorType.commercialLoad:
        return 'Commercial Load';
      case CalculatorType.tapRule:
        return 'Tap Rule';
      case CalculatorType.lumen:
        return 'Lumen';
      case CalculatorType.unitConverter:
        return 'Unit Converter';
      case CalculatorType.raceway:
        return 'Raceway';
      case CalculatorType.parallelConductor:
        return 'Parallel Conductor';
      case CalculatorType.powerFactor:
        return 'Power Factor';
      case CalculatorType.disconnect:
        return 'Disconnect';
      case CalculatorType.serviceEntrance:
        return 'Service Entrance';
      case CalculatorType.evCharger:
        return 'EV Charger';
      case CalculatorType.solarPv:
        return 'Solar PV';
      case CalculatorType.electricRange:
        return 'Electric Range';
      case CalculatorType.dryerCircuit:
        return 'Dryer Circuit';
      case CalculatorType.waterHeater:
        return 'Water Heater';
      case CalculatorType.generatorSizing:
        return 'Generator Sizing';
      case CalculatorType.continuousLoad:
        return 'Continuous Load';
      case CalculatorType.motorInrush:
        return 'Motor Inrush';
      case CalculatorType.mwbc:
        return 'MWBC';
      case CalculatorType.cableTray:
        return 'Cable Tray';
      case CalculatorType.lightingSqft:
        return 'Lighting per Sq Ft';
      case CalculatorType.ohmsLaw:
        return "Ohm's Law";
    }
  }

  String get screenId {
    return name;
  }
}

/// Saved calculation model for Hive persistence
@HiveType(typeId: 11)
class SavedCalculation with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final CalculatorType calculatorType;

  @HiveField(2)
  final String? name;

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final Map<String, dynamic> inputs;

  @HiveField(5)
  final Map<String, dynamic> outputs;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  @HiveField(8)
  final String? jobId;

  @HiveField(9)
  final String? jobAddress;

  @HiveField(10)
  final bool isFavorite;

  @HiveField(11)
  final List<String> tags;

  SavedCalculation({
    required this.id,
    required this.calculatorType,
    this.name,
    this.notes,
    required this.inputs,
    required this.outputs,
    required this.createdAt,
    this.updatedAt,
    this.jobId,
    this.jobAddress,
    this.isFavorite = false,
    this.tags = const [],
  });

  /// Create a new calculation with auto-generated ID
  factory SavedCalculation.create({
    required CalculatorType calculatorType,
    String? name,
    String? notes,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
    String? jobId,
    String? jobAddress,
    List<String> tags = const [],
  }) {
    return SavedCalculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      calculatorType: calculatorType,
      name: name,
      notes: notes,
      inputs: inputs,
      outputs: outputs,
      createdAt: DateTime.now(),
      jobId: jobId,
      jobAddress: jobAddress,
      tags: tags,
    );
  }

  /// Copy with updated values
  SavedCalculation copyWith({
    String? id,
    CalculatorType? calculatorType,
    String? name,
    String? notes,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? outputs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? jobId,
    String? jobAddress,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return SavedCalculation(
      id: id ?? this.id,
      calculatorType: calculatorType ?? this.calculatorType,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      jobId: jobId ?? this.jobId,
      jobAddress: jobAddress ?? this.jobAddress,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  /// Get display title (custom name or calculator type)
  String get displayTitle => name ?? calculatorType.displayName;

  /// Get primary result for preview
  String? get primaryResult {
    if (outputs.isEmpty) return null;
    final firstKey = outputs.keys.first;
    final value = outputs[firstKey];
    return '$firstKey: $value';
  }

  /// Convert to JSON for Firestore sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculatorType': calculatorType.name,
      'name': name,
      'notes': notes,
      'inputs': inputs,
      'outputs': outputs,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'jobId': jobId,
      'jobAddress': jobAddress,
      'isFavorite': isFavorite,
      'tags': tags,
    };
  }

  /// Create from JSON (Firestore sync)
  factory SavedCalculation.fromJson(Map<String, dynamic> json) {
    return SavedCalculation(
      id: json['id'] as String,
      calculatorType: CalculatorType.values.firstWhere(
        (e) => e.name == json['calculatorType'],
        orElse: () => CalculatorType.voltageDrop,
      ),
      name: json['name'] as String?,
      notes: json['notes'] as String?,
      inputs: Map<String, dynamic>.from(json['inputs'] as Map? ?? {}),
      outputs: Map<String, dynamic>.from(json['outputs'] as Map? ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      jobId: json['jobId'] as String?,
      jobAddress: json['jobAddress'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [
        id,
        calculatorType,
        name,
        notes,
        inputs,
        outputs,
        createdAt,
        updatedAt,
        jobId,
        jobAddress,
        isFavorite,
        tags,
      ];
}

/// Hive adapter for Map<String, dynamic>
class MapAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 12;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    final length = reader.readInt();
    final map = <String, dynamic>{};
    for (var i = 0; i < length; i++) {
      final key = reader.readString();
      final value = reader.read();
      map[key] = value;
    }
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeInt(obj.length);
    for (final entry in obj.entries) {
      writer.writeString(entry.key);
      writer.write(entry.value);
    }
  }
}
