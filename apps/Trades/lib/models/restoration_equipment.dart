// ZAFTO Restoration Equipment Model — Supabase Backend
// Maps to `restoration_equipment` table. Deployed equipment tracking with daily billing.

enum EquipmentType {
  dehumidifier,
  airMover,
  airScrubber,
  heater,
  moistureMeter,
  thermalCamera,
  hydroxylGenerator,
  negativeAirMachine,
  injectidry,
  other;

  String get dbValue {
    switch (this) {
      case EquipmentType.dehumidifier:
        return 'dehumidifier';
      case EquipmentType.airMover:
        return 'air_mover';
      case EquipmentType.airScrubber:
        return 'air_scrubber';
      case EquipmentType.heater:
        return 'heater';
      case EquipmentType.moistureMeter:
        return 'moisture_meter';
      case EquipmentType.thermalCamera:
        return 'thermal_camera';
      case EquipmentType.hydroxylGenerator:
        return 'hydroxyl_generator';
      case EquipmentType.negativeAirMachine:
        return 'negative_air_machine';
      case EquipmentType.injectidry:
        return 'injectidry';
      case EquipmentType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case EquipmentType.dehumidifier:
        return 'Dehumidifier';
      case EquipmentType.airMover:
        return 'Air Mover';
      case EquipmentType.airScrubber:
        return 'Air Scrubber';
      case EquipmentType.heater:
        return 'Heater';
      case EquipmentType.moistureMeter:
        return 'Moisture Meter';
      case EquipmentType.thermalCamera:
        return 'Thermal Camera';
      case EquipmentType.hydroxylGenerator:
        return 'Hydroxyl Generator';
      case EquipmentType.negativeAirMachine:
        return 'Negative Air Machine';
      case EquipmentType.injectidry:
        return 'Injectidry';
      case EquipmentType.other:
        return 'Other';
    }
  }

  static EquipmentType fromString(String? value) {
    if (value == null) return EquipmentType.other;
    switch (value) {
      case 'dehumidifier':
        return EquipmentType.dehumidifier;
      case 'air_mover':
        return EquipmentType.airMover;
      case 'air_scrubber':
        return EquipmentType.airScrubber;
      case 'heater':
        return EquipmentType.heater;
      case 'moisture_meter':
        return EquipmentType.moistureMeter;
      case 'thermal_camera':
        return EquipmentType.thermalCamera;
      case 'hydroxyl_generator':
        return EquipmentType.hydroxylGenerator;
      case 'negative_air_machine':
        return EquipmentType.negativeAirMachine;
      case 'injectidry':
        return EquipmentType.injectidry;
      case 'other':
        return EquipmentType.other;
      default:
        return EquipmentType.other;
    }
  }
}

enum EquipmentStatus {
  deployed,
  removed,
  maintenance,
  lost;

  String get dbValue => name;

  String get label {
    switch (this) {
      case EquipmentStatus.deployed:
        return 'Deployed';
      case EquipmentStatus.removed:
        return 'Removed';
      case EquipmentStatus.maintenance:
        return 'Maintenance';
      case EquipmentStatus.lost:
        return 'Lost';
    }
  }

  static EquipmentStatus fromString(String? value) {
    if (value == null) return EquipmentStatus.deployed;
    return EquipmentStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => EquipmentStatus.deployed,
    );
  }
}

class RestorationEquipment {
  final String id;
  final String companyId;
  final String jobId;
  final String? claimId;
  final EquipmentType equipmentType;
  final String? make;
  final String? model;
  final String? serialNumber;
  final String? assetTag;
  final String areaDeployed;
  final DateTime deployedAt;
  final DateTime? removedAt;
  final double dailyRate;
  final int? totalDays; // computed by DB
  final EquipmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestorationEquipment({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.claimId,
    required this.equipmentType,
    this.make,
    this.model,
    this.serialNumber,
    this.assetTag,
    required this.areaDeployed,
    required this.deployedAt,
    this.removedAt,
    this.dailyRate = 0,
    this.totalDays,
    this.status = EquipmentStatus.deployed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        if (claimId != null) 'claim_id': claimId,
        'equipment_type': equipmentType.dbValue,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (assetTag != null) 'asset_tag': assetTag,
        'area_deployed': areaDeployed,
        'deployed_at': deployedAt.toUtc().toIso8601String(),
        'daily_rate': dailyRate,
        'status': status.dbValue,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'equipment_type': equipmentType.dbValue,
        'make': make,
        'model': model,
        'serial_number': serialNumber,
        'asset_tag': assetTag,
        'area_deployed': areaDeployed,
        if (removedAt != null)
          'removed_at': removedAt!.toUtc().toIso8601String(),
        'daily_rate': dailyRate,
        'status': status.dbValue,
        'notes': notes,
      };

  factory RestorationEquipment.fromJson(Map<String, dynamic> json) {
    return RestorationEquipment(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      claimId: json['claim_id'] as String?,
      equipmentType:
          EquipmentType.fromString(json['equipment_type'] as String?),
      make: json['make'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      assetTag: json['asset_tag'] as String?,
      areaDeployed: json['area_deployed'] as String? ?? '',
      deployedAt: _parseDate(json['deployed_at']),
      removedAt: _parseOptionalDate(json['removed_at']),
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0,
      totalDays: json['total_days'] as int?,
      status: EquipmentStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get isDeployed => status == EquipmentStatus.deployed;
  bool get isRemoved => status == EquipmentStatus.removed;
  double get totalCost => dailyRate * (totalDays ?? 1);
  int get daysDeployed => totalDays ?? 1;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
