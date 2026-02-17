// ZAFTO — Locksmith Service Model
// Sprint NICHE2 — Service Trades

import 'package:equatable/equatable.dart';

enum LocksmithServiceType {
  rekey('rekey', 'Rekey'),
  lockout('lockout', 'Lockout'),
  lockChange('lock_change', 'Lock Change'),
  masterKey('master_key', 'Master Key'),
  safe('safe', 'Safe'),
  automotiveLockout('automotive_lockout', 'Automotive Lockout'),
  transponderKey('transponder_key', 'Transponder Key'),
  highSecurity('high_security', 'High Security'),
  accessControl('access_control', 'Access Control'),
  keyDuplication('key_duplication', 'Key Duplication'),
  lockRepair('lock_repair', 'Lock Repair'),
  deadboltInstall('deadbolt_install', 'Deadbolt Install'),
  commercialLockout('commercial_lockout', 'Commercial Lockout');

  final String dbValue;
  final String label;
  const LocksmithServiceType(this.dbValue, this.label);
  static LocksmithServiceType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => rekey);
}

enum LockType {
  deadbolt('deadbolt', 'Deadbolt'),
  knob('knob', 'Knob'),
  lever('lever', 'Lever'),
  padlock('padlock', 'Padlock'),
  mortise('mortise', 'Mortise'),
  rim('rim', 'Rim'),
  cam('cam', 'Cam'),
  electronic('electronic', 'Electronic'),
  smart('smart', 'Smart'),
  automotive('automotive', 'Automotive'),
  cabinet('cabinet', 'Cabinet'),
  mailbox('mailbox', 'Mailbox'),
  safeLock('safe', 'Safe');

  final String dbValue;
  final String label;
  const LockType(this.dbValue, this.label);
  static LockType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => deadbolt);
}

enum KeyType {
  standard('standard', 'Standard'),
  restricted('restricted', 'Restricted'),
  highSecurity('high_security', 'High Security'),
  transponder('transponder', 'Transponder'),
  proximity('proximity', 'Proximity'),
  smartKey('smart', 'Smart'),
  tubular('tubular', 'Tubular'),
  dimple('dimple', 'Dimple'),
  skeleton('skeleton', 'Skeleton'),
  magnetic('magnetic', 'Magnetic');

  final String dbValue;
  final String label;
  const KeyType(this.dbValue, this.label);
  static KeyType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => standard);
}

class LocksmithService extends Equatable {
  final String id;
  final String companyId;
  final String? jobId;
  final String? propertyId;
  final LocksmithServiceType serviceType;
  final String? lockBrand;
  final LockType? lockType;
  final KeyType? keyType;
  final int? pins;
  final String? bittingCode;
  final String? masterKeySystemId;
  final String? keyway;
  final String? vinNumber;
  final int? vehicleYear;
  final String? vehicleMake;
  final String? vehicleModel;
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

  const LocksmithService({
    required this.id,
    required this.companyId,
    this.jobId,
    this.propertyId,
    required this.serviceType,
    this.lockBrand,
    this.lockType,
    this.keyType,
    this.pins,
    this.bittingCode,
    this.masterKeySystemId,
    this.keyway,
    this.vinNumber,
    this.vehicleYear,
    this.vehicleMake,
    this.vehicleModel,
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

  factory LocksmithService.fromJson(Map<String, dynamic> json) {
    return LocksmithService(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String?,
      propertyId: json['property_id'] as String?,
      serviceType: LocksmithServiceType.fromString(json['service_type'] as String),
      lockBrand: json['lock_brand'] as String?,
      lockType: json['lock_type'] != null ? LockType.fromString(json['lock_type'] as String) : null,
      keyType: json['key_type'] != null ? KeyType.fromString(json['key_type'] as String) : null,
      pins: json['pins'] as int?,
      bittingCode: json['bitting_code'] as String?,
      masterKeySystemId: json['master_key_system_id'] as String?,
      keyway: json['keyway'] as String?,
      vinNumber: json['vin_number'] as String?,
      vehicleYear: json['vehicle_year'] as int?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
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
    'service_type': serviceType.dbValue,
    if (lockBrand != null) 'lock_brand': lockBrand,
    if (lockType != null) 'lock_type': lockType!.dbValue,
    if (keyType != null) 'key_type': keyType!.dbValue,
    if (pins != null) 'pins': pins,
    if (bittingCode != null) 'bitting_code': bittingCode,
    if (masterKeySystemId != null) 'master_key_system_id': masterKeySystemId,
    if (keyway != null) 'keyway': keyway,
    if (vinNumber != null) 'vin_number': vinNumber,
    if (vehicleYear != null) 'vehicle_year': vehicleYear,
    if (vehicleMake != null) 'vehicle_make': vehicleMake,
    if (vehicleModel != null) 'vehicle_model': vehicleModel,
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

  bool get isAutomotive =>
      serviceType == LocksmithServiceType.automotiveLockout ||
      serviceType == LocksmithServiceType.transponderKey;

  String get vehicleDescription =>
      [vehicleYear?.toString(), vehicleMake, vehicleModel].where((e) => e != null && e.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id];
}
