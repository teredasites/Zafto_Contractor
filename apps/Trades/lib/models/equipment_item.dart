// ZAFTO Equipment Item Model
// Created: Sprint FIELD2 (Session 131)

import 'package:equatable/equatable.dart';

enum EquipmentCategory {
  handTool,
  powerTool,
  testingEquipment,
  safetyEquipment,
  vehicleMounted,
  specialty;

  String get label => switch (this) {
        handTool => 'Hand Tool',
        powerTool => 'Power Tool',
        testingEquipment => 'Testing Equipment',
        safetyEquipment => 'Safety Equipment',
        vehicleMounted => 'Vehicle Mounted',
        specialty => 'Specialty',
      };

  String get dbValue => switch (this) {
        handTool => 'hand_tool',
        powerTool => 'power_tool',
        testingEquipment => 'testing_equipment',
        safetyEquipment => 'safety_equipment',
        vehicleMounted => 'vehicle_mounted',
        specialty => 'specialty',
      };

  static EquipmentCategory fromDb(String? value) => switch (value) {
        'hand_tool' => handTool,
        'power_tool' => powerTool,
        'testing_equipment' => testingEquipment,
        'safety_equipment' => safetyEquipment,
        'vehicle_mounted' => vehicleMounted,
        'specialty' => specialty,
        _ => handTool,
      };
}

enum EquipmentCondition {
  newCondition,
  good,
  fair,
  poor,
  damaged,
  retired;

  String get label => switch (this) {
        newCondition => 'New',
        good => 'Good',
        fair => 'Fair',
        poor => 'Poor',
        damaged => 'Damaged',
        retired => 'Retired',
      };

  String get dbValue => switch (this) {
        newCondition => 'new',
        good => 'good',
        fair => 'fair',
        poor => 'poor',
        damaged => 'damaged',
        retired => 'retired',
      };

  static EquipmentCondition fromDb(String? value) => switch (value) {
        'new' => newCondition,
        'good' => good,
        'fair' => fair,
        'poor' => poor,
        'damaged' => damaged,
        'retired' => retired,
        _ => good,
      };
}

class EquipmentItem extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final EquipmentCategory category;
  final String? serialNumber;
  final String? barcode;
  final String? manufacturer;
  final String? modelNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final EquipmentCondition condition;
  final String? currentHolderId;
  final String? storageLocation;
  final String? photoUrl;
  final DateTime? lastInspectionDate;
  final DateTime? nextCalibrationDate;
  final DateTime? warrantyExpiry;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const EquipmentItem({
    required this.id,
    required this.companyId,
    required this.name,
    required this.category,
    this.serialNumber,
    this.barcode,
    this.manufacturer,
    this.modelNumber,
    this.purchaseDate,
    this.purchaseCost,
    required this.condition,
    this.currentHolderId,
    this.storageLocation,
    this.photoUrl,
    this.lastInspectionDate,
    this.nextCalibrationDate,
    this.warrantyExpiry,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isCheckedOut => currentHolderId != null;

  bool get needsCalibration {
    if (nextCalibrationDate == null) return false;
    return nextCalibrationDate!.isBefore(DateTime.now().add(const Duration(days: 14)));
  }

  bool get isRetired => condition == EquipmentCondition.retired || !isActive;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      category: EquipmentCategory.fromDb(json['category'] as String?),
      serialNumber: json['serial_number'] as String?,
      barcode: json['barcode'] as String?,
      manufacturer: json['manufacturer'] as String?,
      modelNumber: json['model_number'] as String?,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      purchaseCost: json['purchase_cost'] != null
          ? (json['purchase_cost'] as num).toDouble()
          : null,
      condition: EquipmentCondition.fromDb(json['condition'] as String?),
      currentHolderId: json['current_holder_id'] as String?,
      storageLocation: json['storage_location'] as String?,
      photoUrl: json['photo_url'] as String?,
      lastInspectionDate: json['last_inspection_date'] != null
          ? DateTime.parse(json['last_inspection_date'] as String)
          : null,
      nextCalibrationDate: json['next_calibration_date'] != null
          ? DateTime.parse(json['next_calibration_date'] as String)
          : null,
      warrantyExpiry: json['warranty_expiry'] != null
          ? DateTime.parse(json['warranty_expiry'] as String)
          : null,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'category': category.dbValue,
        'serial_number': serialNumber,
        'barcode': barcode,
        'manufacturer': manufacturer,
        'model_number': modelNumber,
        'purchase_date': purchaseDate?.toIso8601String().split('T').first,
        'purchase_cost': purchaseCost,
        'condition': condition.dbValue,
        'current_holder_id': currentHolderId,
        'storage_location': storageLocation,
        'photo_url': photoUrl,
        'last_inspection_date': lastInspectionDate?.toIso8601String().split('T').first,
        'next_calibration_date': nextCalibrationDate?.toIso8601String().split('T').first,
        'warranty_expiry': warrantyExpiry?.toIso8601String().split('T').first,
        'notes': notes,
        'is_active': isActive,
      };

  EquipmentItem copyWith({
    String? name,
    EquipmentCategory? category,
    String? serialNumber,
    String? barcode,
    String? manufacturer,
    String? modelNumber,
    DateTime? purchaseDate,
    double? purchaseCost,
    EquipmentCondition? condition,
    String? currentHolderId,
    String? storageLocation,
    String? photoUrl,
    DateTime? lastInspectionDate,
    DateTime? nextCalibrationDate,
    DateTime? warrantyExpiry,
    String? notes,
    bool? isActive,
  }) {
    return EquipmentItem(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      barcode: barcode ?? this.barcode,
      manufacturer: manufacturer ?? this.manufacturer,
      modelNumber: modelNumber ?? this.modelNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      condition: condition ?? this.condition,
      currentHolderId: currentHolderId ?? this.currentHolderId,
      storageLocation: storageLocation ?? this.storageLocation,
      photoUrl: photoUrl ?? this.photoUrl,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextCalibrationDate: nextCalibrationDate ?? this.nextCalibrationDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
