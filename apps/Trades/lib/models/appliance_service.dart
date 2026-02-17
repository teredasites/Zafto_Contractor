// ZAFTO — Appliance Service Model
// Sprint NICHE2 — Service Trades

import 'package:equatable/equatable.dart';

enum ApplianceType {
  refrigerator('refrigerator', 'Refrigerator'),
  washer('washer', 'Washer'),
  dryer('dryer', 'Dryer'),
  dishwasher('dishwasher', 'Dishwasher'),
  oven('oven', 'Oven'),
  range('range', 'Range'),
  microwave('microwave', 'Microwave'),
  garbageDisposal('garbage_disposal', 'Garbage Disposal'),
  iceMaker('ice_maker', 'Ice Maker'),
  wineCooler('wine_cooler', 'Wine Cooler'),
  trashCompactor('trash_compactor', 'Trash Compactor'),
  rangeHood('range_hood', 'Range Hood'),
  freezer('freezer', 'Freezer'),
  cooktop('cooktop', 'Cooktop');

  final String dbValue;
  final String label;
  const ApplianceType(this.dbValue, this.label);
  static ApplianceType fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => refrigerator);
}

enum RepairVsReplace {
  repair('repair', 'Repair'),
  replace('replace', 'Replace'),
  customerChoice('customer_choice', 'Customer Choice'),
  notEconomical('not_economical', 'Not Economical');

  final String dbValue;
  final String label;
  const RepairVsReplace(this.dbValue, this.label);
  static RepairVsReplace fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => repair);
}

enum WarrantyStatus {
  inWarranty('in_warranty', 'In Warranty'),
  extendedWarranty('extended_warranty', 'Extended Warranty'),
  expired('expired', 'Expired'),
  unknown('unknown', 'Unknown');

  final String dbValue;
  final String label;
  const WarrantyStatus(this.dbValue, this.label);
  static WarrantyStatus fromString(String v) =>
      values.firstWhere((e) => e.dbValue == v, orElse: () => unknown);
}

class ApplianceService extends Equatable {
  final String id;
  final String companyId;
  final String? jobId;
  final String? propertyId;
  final ApplianceType applianceType;
  final String? brand;
  final String? modelNumber;
  final String? serialNumber;
  final String? manufactureDate;
  final String? purchaseDate;
  final WarrantyStatus? warrantyStatus;
  final String? errorCode;
  final String? errorDescription;
  final List<String> symptoms;
  final List<Map<String, dynamic>> diagnosticSteps;
  final String? diagnosis;
  final String? workPerformed;
  final List<Map<String, dynamic>> partsUsed;
  final RepairVsReplace? repairVsReplace;
  final int? estimatedRemainingLifeYears;
  final double? estimatedRepairCost;
  final double? estimatedReplaceCost;
  final List<String> photos;
  final int? laborMinutes;
  final double? partsCost;
  final double? laborCost;
  final double? totalCost;
  final String? technicianName;
  final String? notes;
  final DateTime createdAt;

  const ApplianceService({
    required this.id,
    required this.companyId,
    this.jobId,
    this.propertyId,
    required this.applianceType,
    this.brand,
    this.modelNumber,
    this.serialNumber,
    this.manufactureDate,
    this.purchaseDate,
    this.warrantyStatus,
    this.errorCode,
    this.errorDescription,
    this.symptoms = const [],
    this.diagnosticSteps = const [],
    this.diagnosis,
    this.workPerformed,
    this.partsUsed = const [],
    this.repairVsReplace,
    this.estimatedRemainingLifeYears,
    this.estimatedRepairCost,
    this.estimatedReplaceCost,
    this.photos = const [],
    this.laborMinutes,
    this.partsCost,
    this.laborCost,
    this.totalCost,
    this.technicianName,
    this.notes,
    required this.createdAt,
  });

  factory ApplianceService.fromJson(Map<String, dynamic> json) {
    return ApplianceService(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String?,
      propertyId: json['property_id'] as String?,
      applianceType: ApplianceType.fromString(json['appliance_type'] as String),
      brand: json['brand'] as String?,
      modelNumber: json['model_number'] as String?,
      serialNumber: json['serial_number'] as String?,
      manufactureDate: json['manufacture_date'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      warrantyStatus: json['warranty_status'] != null ? WarrantyStatus.fromString(json['warranty_status'] as String) : null,
      errorCode: json['error_code'] as String?,
      errorDescription: json['error_description'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      diagnosticSteps: (json['diagnostic_steps'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      diagnosis: json['diagnosis'] as String?,
      workPerformed: json['work_performed'] as String?,
      partsUsed: (json['parts_used'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      repairVsReplace: json['repair_vs_replace'] != null ? RepairVsReplace.fromString(json['repair_vs_replace'] as String) : null,
      estimatedRemainingLifeYears: json['estimated_remaining_life_years'] as int?,
      estimatedRepairCost: (json['estimated_repair_cost'] as num?)?.toDouble(),
      estimatedReplaceCost: (json['estimated_replace_cost'] as num?)?.toDouble(),
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
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
    'appliance_type': applianceType.dbValue,
    if (brand != null) 'brand': brand,
    if (modelNumber != null) 'model_number': modelNumber,
    if (serialNumber != null) 'serial_number': serialNumber,
    if (manufactureDate != null) 'manufacture_date': manufactureDate,
    if (purchaseDate != null) 'purchase_date': purchaseDate,
    if (warrantyStatus != null) 'warranty_status': warrantyStatus!.dbValue,
    if (errorCode != null) 'error_code': errorCode,
    if (errorDescription != null) 'error_description': errorDescription,
    'symptoms': symptoms,
    'diagnostic_steps': diagnosticSteps,
    if (diagnosis != null) 'diagnosis': diagnosis,
    if (workPerformed != null) 'work_performed': workPerformed,
    'parts_used': partsUsed,
    if (repairVsReplace != null) 'repair_vs_replace': repairVsReplace!.dbValue,
    if (estimatedRemainingLifeYears != null) 'estimated_remaining_life_years': estimatedRemainingLifeYears,
    if (estimatedRepairCost != null) 'estimated_repair_cost': estimatedRepairCost,
    if (estimatedReplaceCost != null) 'estimated_replace_cost': estimatedReplaceCost,
    'photos': photos,
    if (laborMinutes != null) 'labor_minutes': laborMinutes,
    if (partsCost != null) 'parts_cost': partsCost,
    if (laborCost != null) 'labor_cost': laborCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (technicianName != null) 'technician_name': technicianName,
    if (notes != null) 'notes': notes,
  };

  bool get shouldReplace =>
      repairVsReplace == RepairVsReplace.replace ||
      repairVsReplace == RepairVsReplace.notEconomical;

  double get repairToReplaceRatio {
    if (estimatedRepairCost == null || estimatedReplaceCost == null || estimatedReplaceCost == 0) return 0;
    return estimatedRepairCost! / estimatedReplaceCost!;
  }

  /// Industry rule of thumb: repair if cost < 50% of replacement
  bool get repairRecommended => repairToReplaceRatio < 0.5;

  @override
  List<Object?> get props => [id];
}
