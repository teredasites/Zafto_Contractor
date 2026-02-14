// ZAFTO Equipment Lifecycle Data Model
// W6: Reference data for equipment lifespan, maintenance intervals, failure modes.

import 'package:equatable/equatable.dart';

class FailureMode {
  final String mode;
  final double probability;
  final double typicalAgeYears;

  const FailureMode({
    required this.mode,
    required this.probability,
    required this.typicalAgeYears,
  });

  factory FailureMode.fromJson(Map<String, dynamic> json) {
    return FailureMode(
      mode: json['mode'] as String,
      probability: (json['probability'] as num).toDouble(),
      typicalAgeYears: (json['typical_age_years'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'probability': probability,
    'typical_age_years': typicalAgeYears,
  };

  String get label => mode.replaceAll('_', ' ').replaceFirstMapped(
    RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase(),
  );
}

class EquipmentLifecycleData extends Equatable {
  final String id;
  final String equipmentCategory;
  final String? manufacturer;
  final double avgLifespanYears;
  final int maintenanceIntervalMonths;
  final List<FailureMode> commonFailureModes;
  final List<String> seasonalMaintenance;
  final String? source;
  final DateTime createdAt;

  const EquipmentLifecycleData({
    required this.id,
    required this.equipmentCategory,
    this.manufacturer,
    required this.avgLifespanYears,
    required this.maintenanceIntervalMonths,
    required this.commonFailureModes,
    required this.seasonalMaintenance,
    this.source,
    required this.createdAt,
  });

  factory EquipmentLifecycleData.fromJson(Map<String, dynamic> json) {
    final failureModes = (json['common_failure_modes'] as List? ?? [])
        .map((e) => FailureMode.fromJson(e as Map<String, dynamic>))
        .toList();
    final seasonal = (json['seasonal_maintenance'] as List? ?? [])
        .map((e) => e as String)
        .toList();

    return EquipmentLifecycleData(
      id: json['id'] as String,
      equipmentCategory: json['equipment_category'] as String,
      manufacturer: json['manufacturer'] as String?,
      avgLifespanYears: (json['avg_lifespan_years'] as num).toDouble(),
      maintenanceIntervalMonths: json['maintenance_interval_months'] as int? ?? 12,
      commonFailureModes: failureModes,
      seasonalMaintenance: seasonal,
      source: json['source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'equipment_category': equipmentCategory,
    'manufacturer': manufacturer,
    'avg_lifespan_years': avgLifespanYears,
    'maintenance_interval_months': maintenanceIntervalMonths,
    'common_failure_modes': commonFailureModes.map((e) => e.toJson()).toList(),
    'seasonal_maintenance': seasonalMaintenance,
    'source': source,
  };

  EquipmentLifecycleData copyWith({
    String? id,
    String? equipmentCategory,
    String? manufacturer,
    double? avgLifespanYears,
    int? maintenanceIntervalMonths,
    List<FailureMode>? commonFailureModes,
    List<String>? seasonalMaintenance,
    String? source,
    DateTime? createdAt,
  }) {
    return EquipmentLifecycleData(
      id: id ?? this.id,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      manufacturer: manufacturer ?? this.manufacturer,
      avgLifespanYears: avgLifespanYears ?? this.avgLifespanYears,
      maintenanceIntervalMonths: maintenanceIntervalMonths ?? this.maintenanceIntervalMonths,
      commonFailureModes: commonFailureModes ?? this.commonFailureModes,
      seasonalMaintenance: seasonalMaintenance ?? this.seasonalMaintenance,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get categoryLabel => equipmentCategory
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());

  /// Top failure mode by probability
  FailureMode? get topFailureMode {
    if (commonFailureModes.isEmpty) return null;
    return commonFailureModes.reduce((a, b) => a.probability > b.probability ? a : b);
  }

  @override
  List<Object?> get props => [id, equipmentCategory, manufacturer];
}
