// ZAFTO — Garage Door Service Model
// Sprint NICHE2 — Service Trades

import 'package:equatable/equatable.dart';

enum GarageDoorType {
  sectional('sectional', 'Sectional'),
  rollUp('roll_up', 'Roll-Up'),
  tiltUp('tilt_up', 'Tilt-Up'),
  slide('slide', 'Slide'),
  commercialRollingSteel('commercial_rolling_steel', 'Commercial Rolling Steel'),
  carriage('carriage', 'Carriage'),
  modernAluminum('modern_aluminum', 'Modern Aluminum'),
  fullView('full_view', 'Full View');

  final String dbValue;
  final String label;
  const GarageDoorType(this.dbValue, this.label);
  static GarageDoorType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => sectional);
}

enum OpenerType {
  chainDrive('chain_drive', 'Chain Drive'),
  beltDrive('belt_drive', 'Belt Drive'),
  screwDrive('screw_drive', 'Screw Drive'),
  jackshaft('jackshaft', 'Jackshaft'),
  directDrive('direct_drive', 'Direct Drive'),
  none('none', 'No Opener');

  final String dbValue;
  final String label;
  const OpenerType(this.dbValue, this.label);
  static OpenerType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => chainDrive);
}

enum SpringType {
  torsion('torsion', 'Torsion'),
  extension('extension', 'Extension'),
  torquemaster('torquemaster', 'Torquemaster'),
  ezSet('ez_set', 'EZ-Set'),
  wayneDalton('wayne_dalton', 'Wayne Dalton');

  final String dbValue;
  final String label;
  const SpringType(this.dbValue, this.label);
  static SpringType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => torsion);
}

enum GarageDoorServiceType {
  springReplacement('spring_replacement', 'Spring Replacement'),
  openerRepair('opener_repair', 'Opener Repair'),
  openerInstall('opener_install', 'Opener Install'),
  panelReplacement('panel_replacement', 'Panel Replacement'),
  cableRepair('cable_repair', 'Cable Repair'),
  trackAlignment('track_alignment', 'Track Alignment'),
  rollerReplacement('roller_replacement', 'Roller Replacement'),
  weatherseal('weatherseal', 'Weatherseal'),
  safetySensor('safety_sensor', 'Safety Sensor'),
  fullDoorInstall('full_door_install', 'Full Door Install'),
  balanceAdjustment('balance_adjustment', 'Balance Adjustment'),
  annualMaintenance('annual_maintenance', 'Annual Maintenance');

  final String dbValue;
  final String label;
  const GarageDoorServiceType(this.dbValue, this.label);
  static GarageDoorServiceType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => springReplacement);
}

class GarageDoorService extends Equatable {
  final String id;
  final String companyId;
  final String? jobId;
  final String? propertyId;
  final GarageDoorType doorType;
  final double? doorWidthInches;
  final double? doorHeightInches;
  final String? panelMaterial;
  final double? insulationRValue;
  final String? trackType;
  final String? openerBrand;
  final String? openerModel;
  final OpenerType? openerType;
  final double? openerHp;
  final SpringType? springType;
  final double? springWireSize;
  final double? springLength;
  final double? springInsideDiameter;
  final int? springCyclesRating;
  final String? springWindDirection;
  final GarageDoorServiceType serviceType;
  final List<String> symptoms;
  final String? safetySensorStatus;
  final String? balanceTestResult;
  final double? forceSettingUp;
  final double? forceSettingDown;
  final String? diagnosis;
  final String? workPerformed;
  final List<Map<String, dynamic>> partsUsed;
  final List<String> photos;
  final List<Map<String, dynamic>> diagnosticSteps;
  final int? laborMinutes;
  final double? partsCost;
  final double? laborCost;
  final double? totalCost;
  final String? technicianName;
  final String? notes;
  final DateTime createdAt;

  const GarageDoorService({
    required this.id,
    required this.companyId,
    this.jobId,
    this.propertyId,
    required this.doorType,
    this.doorWidthInches,
    this.doorHeightInches,
    this.panelMaterial,
    this.insulationRValue,
    this.trackType,
    this.openerBrand,
    this.openerModel,
    this.openerType,
    this.openerHp,
    this.springType,
    this.springWireSize,
    this.springLength,
    this.springInsideDiameter,
    this.springCyclesRating,
    this.springWindDirection,
    required this.serviceType,
    this.symptoms = const [],
    this.safetySensorStatus,
    this.balanceTestResult,
    this.forceSettingUp,
    this.forceSettingDown,
    this.diagnosis,
    this.workPerformed,
    this.partsUsed = const [],
    this.photos = const [],
    this.diagnosticSteps = const [],
    this.laborMinutes,
    this.partsCost,
    this.laborCost,
    this.totalCost,
    this.technicianName,
    this.notes,
    required this.createdAt,
  });

  factory GarageDoorService.fromJson(Map<String, dynamic> json) {
    return GarageDoorService(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String?,
      propertyId: json['property_id'] as String?,
      doorType: GarageDoorType.fromString(json['door_type'] as String),
      doorWidthInches: (json['door_width_inches'] as num?)?.toDouble(),
      doorHeightInches: (json['door_height_inches'] as num?)?.toDouble(),
      panelMaterial: json['panel_material'] as String?,
      insulationRValue: (json['insulation_r_value'] as num?)?.toDouble(),
      trackType: json['track_type'] as String?,
      openerBrand: json['opener_brand'] as String?,
      openerModel: json['opener_model'] as String?,
      openerType: json['opener_type'] != null ? OpenerType.fromString(json['opener_type'] as String) : null,
      openerHp: (json['opener_hp'] as num?)?.toDouble(),
      springType: json['spring_type'] != null ? SpringType.fromString(json['spring_type'] as String) : null,
      springWireSize: (json['spring_wire_size'] as num?)?.toDouble(),
      springLength: (json['spring_length'] as num?)?.toDouble(),
      springInsideDiameter: (json['spring_inside_diameter'] as num?)?.toDouble(),
      springCyclesRating: json['spring_cycles_rating'] as int?,
      springWindDirection: json['spring_wind_direction'] as String?,
      serviceType: GarageDoorServiceType.fromString(json['service_type'] as String),
      symptoms: (json['symptoms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      safetySensorStatus: json['safety_sensor_status'] as String?,
      balanceTestResult: json['balance_test_result'] as String?,
      forceSettingUp: (json['force_setting_up'] as num?)?.toDouble(),
      forceSettingDown: (json['force_setting_down'] as num?)?.toDouble(),
      diagnosis: json['diagnosis'] as String?,
      workPerformed: json['work_performed'] as String?,
      partsUsed: (json['parts_used'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      diagnosticSteps: (json['diagnostic_steps'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      laborMinutes: json['labor_minutes'] as int?,
      partsCost: (json['parts_cost'] as num?)?.toDouble(),
      laborCost: (json['labor_cost'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      technicianName: json['technician_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'company_id': companyId,
    if (jobId != null) 'job_id': jobId,
    if (propertyId != null) 'property_id': propertyId,
    'door_type': doorType.dbValue,
    if (doorWidthInches != null) 'door_width_inches': doorWidthInches,
    if (doorHeightInches != null) 'door_height_inches': doorHeightInches,
    if (panelMaterial != null) 'panel_material': panelMaterial,
    if (insulationRValue != null) 'insulation_r_value': insulationRValue,
    if (trackType != null) 'track_type': trackType,
    if (openerBrand != null) 'opener_brand': openerBrand,
    if (openerModel != null) 'opener_model': openerModel,
    if (openerType != null) 'opener_type': openerType!.dbValue,
    if (openerHp != null) 'opener_hp': openerHp,
    if (springType != null) 'spring_type': springType!.dbValue,
    if (springWireSize != null) 'spring_wire_size': springWireSize,
    if (springLength != null) 'spring_length': springLength,
    if (springInsideDiameter != null) 'spring_inside_diameter': springInsideDiameter,
    if (springCyclesRating != null) 'spring_cycles_rating': springCyclesRating,
    if (springWindDirection != null) 'spring_wind_direction': springWindDirection,
    'service_type': serviceType.dbValue,
    'symptoms': symptoms,
    if (safetySensorStatus != null) 'safety_sensor_status': safetySensorStatus,
    if (balanceTestResult != null) 'balance_test_result': balanceTestResult,
    if (forceSettingUp != null) 'force_setting_up': forceSettingUp,
    if (forceSettingDown != null) 'force_setting_down': forceSettingDown,
    if (diagnosis != null) 'diagnosis': diagnosis,
    if (workPerformed != null) 'work_performed': workPerformed,
    'parts_used': partsUsed,
    'photos': photos,
    'diagnostic_steps': diagnosticSteps,
    if (laborMinutes != null) 'labor_minutes': laborMinutes,
    if (partsCost != null) 'parts_cost': partsCost,
    if (laborCost != null) 'labor_cost': laborCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (technicianName != null) 'technician_name': technicianName,
    if (notes != null) 'notes': notes,
  };

  String get doorDimensions {
    if (doorWidthInches == null || doorHeightInches == null) return 'Unknown';
    final w = (doorWidthInches! / 12).toStringAsFixed(0);
    final h = (doorHeightInches! / 12).toStringAsFixed(0);
    return "${w}' x ${h}'";
  }

  bool get needsSpringWork =>
      serviceType == GarageDoorServiceType.springReplacement ||
      serviceType == GarageDoorServiceType.balanceAdjustment;

  @override
  List<Object?> get props => [id];
}
