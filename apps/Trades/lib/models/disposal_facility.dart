// ZAFTO Disposal & Dump Finder Models
// Created: DEPTH36 — Facility database, dump receipts, scrap prices,
// waste type reference.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// DISPOSAL FACILITY
// ════════════════════════════════════════════════════════════════

class DisposalFacility extends Equatable {
  final String id;
  final String? companyId;
  final String name;
  final String? address;
  final String? city;
  final String? stateCode;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;
  final Map<String, dynamic> hoursJson;
  final String facilityType;
  final List<dynamic> acceptedWasteTypes;
  final List<dynamic> pricingJson;
  final double? weightLimitTons;
  final bool permitRequired;
  final String? permitDetails;
  final String? specialInstructions;
  final String? dataSource;
  final String? externalId;
  final bool verified;
  final String? verifiedAt;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const DisposalFacility({
    required this.id,
    this.companyId,
    required this.name,
    this.address,
    this.city,
    this.stateCode,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.hoursJson = const {},
    required this.facilityType,
    this.acceptedWasteTypes = const [],
    this.pricingJson = const [],
    this.weightLimitTons,
    this.permitRequired = false,
    this.permitDetails,
    this.specialInstructions,
    this.dataSource,
    this.externalId,
    this.verified = false,
    this.verifiedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisposalFacility.fromJson(Map<String, dynamic> json) {
    return DisposalFacility(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      stateCode: json['state_code'] as String?,
      zipCode: json['zip_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      hoursJson: json['hours_json'] is Map ? Map<String, dynamic>.from(json['hours_json'] as Map) : {},
      facilityType: json['facility_type'] as String,
      acceptedWasteTypes: json['accepted_waste_types'] is List ? json['accepted_waste_types'] as List : [],
      pricingJson: json['pricing_json'] is List ? json['pricing_json'] as List : [],
      weightLimitTons: (json['weight_limit_tons'] as num?)?.toDouble(),
      permitRequired: json['permit_required'] as bool? ?? false,
      permitDetails: json['permit_details'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      dataSource: json['data_source'] as String?,
      externalId: json['external_id'] as String?,
      verified: json['verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'address': address,
    'city': city,
    'state_code': stateCode,
    'zip_code': zipCode,
    'latitude': latitude,
    'longitude': longitude,
    'phone': phone,
    'website': website,
    'hours_json': hoursJson,
    'facility_type': facilityType,
    'accepted_waste_types': acceptedWasteTypes,
    'pricing_json': pricingJson,
    'weight_limit_tons': weightLimitTons,
    'permit_required': permitRequired,
    'permit_details': permitDetails,
    'special_instructions': specialInstructions,
    'data_source': dataSource,
    'external_id': externalId,
    'verified': verified,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, name, facilityType, stateCode, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// DUMP RECEIPT
// ════════════════════════════════════════════════════════════════

class DumpReceipt extends Equatable {
  final String id;
  final String companyId;
  final String? facilityId;
  final String? jobId;
  final String? workOrderId;
  final String? capturedBy;
  final String receiptDate;
  final String? facilityName;
  final String? wasteType;
  final double? weightTons;
  final double? volumeYards;
  final double? cost;
  final double? tax;
  final double? totalCost;
  final String? paymentMethod;
  final String? receiptPhotoUrl;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const DumpReceipt({
    required this.id,
    required this.companyId,
    this.facilityId,
    this.jobId,
    this.workOrderId,
    this.capturedBy,
    required this.receiptDate,
    this.facilityName,
    this.wasteType,
    this.weightTons,
    this.volumeYards,
    this.cost,
    this.tax,
    this.totalCost,
    this.paymentMethod,
    this.receiptPhotoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DumpReceipt.fromJson(Map<String, dynamic> json) {
    return DumpReceipt(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      facilityId: json['facility_id'] as String?,
      jobId: json['job_id'] as String?,
      workOrderId: json['work_order_id'] as String?,
      capturedBy: json['captured_by'] as String?,
      receiptDate: json['receipt_date'] as String,
      facilityName: json['facility_name'] as String?,
      wasteType: json['waste_type'] as String?,
      weightTons: (json['weight_tons'] as num?)?.toDouble(),
      volumeYards: (json['volume_yards'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      receiptPhotoUrl: json['receipt_photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'facility_id': facilityId,
    'job_id': jobId,
    'work_order_id': workOrderId,
    'captured_by': capturedBy,
    'receipt_date': receiptDate,
    'facility_name': facilityName,
    'waste_type': wasteType,
    'weight_tons': weightTons,
    'volume_yards': volumeYards,
    'cost': cost,
    'tax': tax,
    'total_cost': totalCost,
    'payment_method': paymentMethod,
    'receipt_photo_url': receiptPhotoUrl,
    'notes': notes,
  };

  @override
  List<Object?> get props => [id, companyId, receiptDate, facilityName, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// SCRAP PRICE INDEX
// ════════════════════════════════════════════════════════════════

class ScrapPriceIndex extends Equatable {
  final String id;
  final String material;
  final String? grade;
  final double? pricePerLb;
  final double? pricePerTon;
  final String unit;
  final String region;
  final String? source;
  final String effectiveDate;
  final String createdAt;

  const ScrapPriceIndex({
    required this.id,
    required this.material,
    this.grade,
    this.pricePerLb,
    this.pricePerTon,
    this.unit = 'lb',
    this.region = 'national',
    this.source,
    required this.effectiveDate,
    required this.createdAt,
  });

  factory ScrapPriceIndex.fromJson(Map<String, dynamic> json) {
    return ScrapPriceIndex(
      id: json['id'] as String,
      material: json['material'] as String,
      grade: json['grade'] as String?,
      pricePerLb: (json['price_per_lb'] as num?)?.toDouble(),
      pricePerTon: (json['price_per_ton'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'lb',
      region: json['region'] as String? ?? 'national',
      source: json['source'] as String?,
      effectiveDate: json['effective_date'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, material, grade, effectiveDate];
}

// ════════════════════════════════════════════════════════════════
// WASTE TYPE REFERENCE
// ════════════════════════════════════════════════════════════════

class WasteTypeReference extends Equatable {
  final String id;
  final String code;
  final String label;
  final String category;
  final List<dynamic> trades;
  final String? disposalNotes;
  final bool requiresPermit;
  final String createdAt;

  const WasteTypeReference({
    required this.id,
    required this.code,
    required this.label,
    required this.category,
    this.trades = const [],
    this.disposalNotes,
    this.requiresPermit = false,
    required this.createdAt,
  });

  factory WasteTypeReference.fromJson(Map<String, dynamic> json) {
    return WasteTypeReference(
      id: json['id'] as String,
      code: json['code'] as String,
      label: json['label'] as String,
      category: json['category'] as String,
      trades: json['trades'] is List ? json['trades'] as List : [],
      disposalNotes: json['disposal_notes'] as String?,
      requiresPermit: json['requires_permit'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, code, label, category];
}
