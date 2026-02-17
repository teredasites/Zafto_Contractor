// ZAFTO Treatment Log Model
// Maps to `treatment_logs` table. Sprint NICHE1 — Pest control module.

enum PestServiceType {
  generalPest,
  termite,
  mosquito,
  bedBug,
  wildlife,
  fumigation,
  rodent,
  ant,
  cockroach,
  tickFlea,
  spider,
  waspBee,
  bird,
  exclusion;

  String get dbValue {
    switch (this) {
      case PestServiceType.generalPest:
        return 'general_pest';
      case PestServiceType.bedBug:
        return 'bed_bug';
      case PestServiceType.tickFlea:
        return 'tick_flea';
      case PestServiceType.waspBee:
        return 'wasp_bee';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case PestServiceType.generalPest:
        return 'General Pest';
      case PestServiceType.termite:
        return 'Termite';
      case PestServiceType.mosquito:
        return 'Mosquito';
      case PestServiceType.bedBug:
        return 'Bed Bug';
      case PestServiceType.wildlife:
        return 'Wildlife';
      case PestServiceType.fumigation:
        return 'Fumigation';
      case PestServiceType.rodent:
        return 'Rodent';
      case PestServiceType.ant:
        return 'Ant';
      case PestServiceType.cockroach:
        return 'Cockroach';
      case PestServiceType.tickFlea:
        return 'Tick / Flea';
      case PestServiceType.spider:
        return 'Spider';
      case PestServiceType.waspBee:
        return 'Wasp / Bee';
      case PestServiceType.bird:
        return 'Bird';
      case PestServiceType.exclusion:
        return 'Exclusion';
    }
  }

  static PestServiceType fromString(String? value) {
    if (value == null) return PestServiceType.generalPest;
    switch (value) {
      case 'general_pest':
        return PestServiceType.generalPest;
      case 'bed_bug':
        return PestServiceType.bedBug;
      case 'tick_flea':
        return PestServiceType.tickFlea;
      case 'wasp_bee':
        return PestServiceType.waspBee;
      default:
        return PestServiceType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PestServiceType.generalPest,
        );
    }
  }
}

enum TreatmentType {
  spray,
  bait,
  trap,
  fog,
  dust,
  granular,
  heat,
  fumigation,
  exclusion,
  monitoring;

  String get label {
    switch (this) {
      case TreatmentType.spray:
        return 'Spray';
      case TreatmentType.bait:
        return 'Bait';
      case TreatmentType.trap:
        return 'Trap';
      case TreatmentType.fog:
        return 'Fog / ULV';
      case TreatmentType.dust:
        return 'Dust';
      case TreatmentType.granular:
        return 'Granular';
      case TreatmentType.heat:
        return 'Heat Treatment';
      case TreatmentType.fumigation:
        return 'Fumigation';
      case TreatmentType.exclusion:
        return 'Exclusion';
      case TreatmentType.monitoring:
        return 'Monitoring';
    }
  }

  static TreatmentType fromString(String? value) {
    if (value == null) return TreatmentType.spray;
    return TreatmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TreatmentType.spray,
    );
  }
}

enum ServiceFrequency {
  oneTime,
  monthly,
  biMonthly,
  quarterly,
  semiAnnual,
  annual;

  String get dbValue {
    switch (this) {
      case ServiceFrequency.oneTime:
        return 'one_time';
      case ServiceFrequency.biMonthly:
        return 'bi_monthly';
      case ServiceFrequency.semiAnnual:
        return 'semi_annual';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ServiceFrequency.oneTime:
        return 'One-Time';
      case ServiceFrequency.monthly:
        return 'Monthly';
      case ServiceFrequency.biMonthly:
        return 'Bi-Monthly';
      case ServiceFrequency.quarterly:
        return 'Quarterly';
      case ServiceFrequency.semiAnnual:
        return 'Semi-Annual';
      case ServiceFrequency.annual:
        return 'Annual';
    }
  }

  static ServiceFrequency fromString(String? value) {
    if (value == null) return ServiceFrequency.oneTime;
    switch (value) {
      case 'one_time':
        return ServiceFrequency.oneTime;
      case 'bi_monthly':
        return ServiceFrequency.biMonthly;
      case 'semi_annual':
        return ServiceFrequency.semiAnnual;
      default:
        return ServiceFrequency.values.firstWhere(
          (e) => e.name == value,
          orElse: () => ServiceFrequency.oneTime,
        );
    }
  }
}

class TreatmentLog {
  final String id;
  final String companyId;
  final String? jobId;
  final String? propertyId;
  final PestServiceType serviceType;
  final TreatmentType treatmentType;
  final List<String> targetPests;
  final String? chemicalName;
  final String? epaRegistrationNumber;
  final String? activeIngredient;
  final String? applicationRate;
  final String? dilutionRatio;
  final String? amountUsed;
  final String? concentration;
  final String? applicationMethod;
  final List<Map<String, dynamic>> areasTreated;
  final double? targetAreaSqft;
  final Map<String, dynamic> weatherConditions;
  final double? temperatureF;
  final double? windMph;
  final String? applicatorId;
  final String? applicatorName;
  final String? licenseNumber;
  final double? reEntryTimeHours;
  final DateTime? nextServiceDate;
  final ServiceFrequency serviceFrequency;
  final List<Map<String, dynamic>> photos;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TreatmentLog({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.propertyId,
    this.serviceType = PestServiceType.generalPest,
    this.treatmentType = TreatmentType.spray,
    this.targetPests = const [],
    this.chemicalName,
    this.epaRegistrationNumber,
    this.activeIngredient,
    this.applicationRate,
    this.dilutionRatio,
    this.amountUsed,
    this.concentration,
    this.applicationMethod,
    this.areasTreated = const [],
    this.targetAreaSqft,
    this.weatherConditions = const {},
    this.temperatureF,
    this.windMph,
    this.applicatorId,
    this.applicatorName,
    this.licenseNumber,
    this.reEntryTimeHours,
    this.nextServiceDate,
    this.serviceFrequency = ServiceFrequency.oneTime,
    this.photos = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        if (propertyId != null) 'property_id': propertyId,
        'service_type': serviceType.dbValue,
        'treatment_type': treatmentType.name,
        'target_pests': targetPests,
        if (chemicalName != null) 'chemical_name': chemicalName,
        if (epaRegistrationNumber != null)
          'epa_registration_number': epaRegistrationNumber,
        if (activeIngredient != null) 'active_ingredient': activeIngredient,
        if (applicationRate != null) 'application_rate': applicationRate,
        if (dilutionRatio != null) 'dilution_ratio': dilutionRatio,
        if (amountUsed != null) 'amount_used': amountUsed,
        if (concentration != null) 'concentration': concentration,
        if (applicationMethod != null) 'application_method': applicationMethod,
        'areas_treated': areasTreated,
        if (targetAreaSqft != null) 'target_area_sqft': targetAreaSqft,
        'weather_conditions': weatherConditions,
        if (temperatureF != null) 'temperature_f': temperatureF,
        if (windMph != null) 'wind_mph': windMph,
        if (applicatorId != null) 'applicator_id': applicatorId,
        if (applicatorName != null) 'applicator_name': applicatorName,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (reEntryTimeHours != null) 're_entry_time_hours': reEntryTimeHours,
        if (nextServiceDate != null)
          'next_service_date': nextServiceDate!.toIso8601String().split('T')[0],
        'service_frequency': serviceFrequency.dbValue,
        'photos': photos,
        if (notes != null) 'notes': notes,
      };

  factory TreatmentLog.fromJson(Map<String, dynamic> json) {
    return TreatmentLog(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      propertyId: json['property_id'] as String?,
      serviceType:
          PestServiceType.fromString(json['service_type'] as String?),
      treatmentType:
          TreatmentType.fromString(json['treatment_type'] as String?),
      targetPests: (json['target_pests'] as List?)
              ?.whereType<String>()
              .toList() ??
          [],
      chemicalName: json['chemical_name'] as String?,
      epaRegistrationNumber: json['epa_registration_number'] as String?,
      activeIngredient: json['active_ingredient'] as String?,
      applicationRate: json['application_rate'] as String?,
      dilutionRatio: json['dilution_ratio'] as String?,
      amountUsed: json['amount_used'] as String?,
      concentration: json['concentration'] as String?,
      applicationMethod: json['application_method'] as String?,
      areasTreated: _parseRaw(json['areas_treated']),
      targetAreaSqft: (json['target_area_sqft'] as num?)?.toDouble(),
      weatherConditions:
          (json['weather_conditions'] as Map<String, dynamic>?) ?? {},
      temperatureF: (json['temperature_f'] as num?)?.toDouble(),
      windMph: (json['wind_mph'] as num?)?.toDouble(),
      applicatorId: json['applicator_id'] as String?,
      applicatorName: json['applicator_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      reEntryTimeHours: (json['re_entry_time_hours'] as num?)?.toDouble(),
      nextServiceDate: _parseDate(json['next_service_date']),
      serviceFrequency:
          ServiceFrequency.fromString(json['service_frequency'] as String?),
      photos: _parseRaw(json['photos']),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }
}

List<Map<String, dynamic>> _parseRaw(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.whereType<Map<String, dynamic>>().toList();
  return [];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
