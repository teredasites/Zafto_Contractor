// ZAFTO Content Pack-out Item Model — Supabase Backend
// Maps to `content_packout_items` table. Sprint REST1.
// Room-by-room contents inventory for fire damage — pack-out, cleaning, return.

enum ContentCategory {
  electronics,
  softGoods,
  hardGoods,
  documents,
  artwork,
  furniture,
  clothing,
  appliances,
  kitchenware,
  personal,
  tools,
  sporting,
  other;

  String get dbValue {
    switch (this) {
      case ContentCategory.softGoods:
        return 'soft_goods';
      case ContentCategory.hardGoods:
        return 'hard_goods';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ContentCategory.electronics:
        return 'Electronics';
      case ContentCategory.softGoods:
        return 'Soft Goods';
      case ContentCategory.hardGoods:
        return 'Hard Goods';
      case ContentCategory.documents:
        return 'Documents';
      case ContentCategory.artwork:
        return 'Artwork';
      case ContentCategory.furniture:
        return 'Furniture';
      case ContentCategory.clothing:
        return 'Clothing';
      case ContentCategory.appliances:
        return 'Appliances';
      case ContentCategory.kitchenware:
        return 'Kitchenware';
      case ContentCategory.personal:
        return 'Personal Items';
      case ContentCategory.tools:
        return 'Tools';
      case ContentCategory.sporting:
        return 'Sporting Goods';
      case ContentCategory.other:
        return 'Other';
    }
  }

  static ContentCategory fromString(String? value) {
    if (value == null) return ContentCategory.other;
    switch (value) {
      case 'soft_goods':
        return ContentCategory.softGoods;
      case 'hard_goods':
        return ContentCategory.hardGoods;
      default:
        return ContentCategory.values.firstWhere(
          (e) => e.name == value,
          orElse: () => ContentCategory.other,
        );
    }
  }
}

enum ContentCondition {
  salvageable,
  nonSalvageable,
  needsCleaning,
  needsRestoration,
  questionable;

  String get dbValue {
    switch (this) {
      case ContentCondition.nonSalvageable:
        return 'non_salvageable';
      case ContentCondition.needsCleaning:
        return 'needs_cleaning';
      case ContentCondition.needsRestoration:
        return 'needs_restoration';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ContentCondition.salvageable:
        return 'Salvageable';
      case ContentCondition.nonSalvageable:
        return 'Non-Salvageable';
      case ContentCondition.needsCleaning:
        return 'Needs Cleaning';
      case ContentCondition.needsRestoration:
        return 'Needs Restoration';
      case ContentCondition.questionable:
        return 'Questionable';
    }
  }

  static ContentCondition fromString(String? value) {
    if (value == null) return ContentCondition.needsCleaning;
    switch (value) {
      case 'non_salvageable':
        return ContentCondition.nonSalvageable;
      case 'needs_cleaning':
        return ContentCondition.needsCleaning;
      case 'needs_restoration':
        return ContentCondition.needsRestoration;
      default:
        return ContentCondition.values.firstWhere(
          (e) => e.name == value,
          orElse: () => ContentCondition.needsCleaning,
        );
    }
  }
}

enum CleaningMethod {
  dryClean,
  wetClean,
  ultrasonic,
  ozone,
  immersion,
  sodaBlast,
  dryIceBlast,
  handWipe,
  laundry,
  none;

  String get dbValue {
    switch (this) {
      case CleaningMethod.dryClean:
        return 'dry_clean';
      case CleaningMethod.wetClean:
        return 'wet_clean';
      case CleaningMethod.dryIceBlast:
        return 'dry_ice_blast';
      case CleaningMethod.sodaBlast:
        return 'soda_blast';
      case CleaningMethod.handWipe:
        return 'hand_wipe';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case CleaningMethod.dryClean:
        return 'Dry Clean';
      case CleaningMethod.wetClean:
        return 'Wet Clean';
      case CleaningMethod.ultrasonic:
        return 'Ultrasonic';
      case CleaningMethod.ozone:
        return 'Ozone';
      case CleaningMethod.immersion:
        return 'Immersion';
      case CleaningMethod.sodaBlast:
        return 'Soda Blast';
      case CleaningMethod.dryIceBlast:
        return 'Dry Ice Blast';
      case CleaningMethod.handWipe:
        return 'Hand Wipe';
      case CleaningMethod.laundry:
        return 'Laundry';
      case CleaningMethod.none:
        return 'None';
    }
  }

  static CleaningMethod fromString(String? value) {
    if (value == null) return CleaningMethod.none;
    switch (value) {
      case 'dry_clean':
        return CleaningMethod.dryClean;
      case 'wet_clean':
        return CleaningMethod.wetClean;
      case 'dry_ice_blast':
        return CleaningMethod.dryIceBlast;
      case 'soda_blast':
        return CleaningMethod.sodaBlast;
      case 'hand_wipe':
        return CleaningMethod.handWipe;
      default:
        return CleaningMethod.values.firstWhere(
          (e) => e.name == value,
          orElse: () => CleaningMethod.none,
        );
    }
  }
}

// =============================================================================
// MAIN MODEL
// =============================================================================

class ContentPackoutItem {
  final String id;
  final String companyId;
  final String fireAssessmentId;
  final String jobId;

  // Item details
  final String itemDescription;
  final String roomOfOrigin;
  final ContentCategory category;
  final ContentCondition condition;
  final CleaningMethod? cleaningMethod;

  // Pack-out tracking
  final String? boxNumber;
  final String? storageLocation;
  final DateTime? packedAt;
  final String? packedByUserId;
  final DateTime? returnedAt;
  final String? returnedTo;

  // Valuation
  final double? estimatedValue;
  final double? replacementCost;
  final double? actualCashValue;

  // Photos
  final List<String> photoUrls;

  // Notes
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentPackoutItem({
    this.id = '',
    this.companyId = '',
    this.fireAssessmentId = '',
    this.jobId = '',
    required this.itemDescription,
    required this.roomOfOrigin,
    this.category = ContentCategory.other,
    this.condition = ContentCondition.needsCleaning,
    this.cleaningMethod,
    this.boxNumber,
    this.storageLocation,
    this.packedAt,
    this.packedByUserId,
    this.returnedAt,
    this.returnedTo,
    this.estimatedValue,
    this.replacementCost,
    this.actualCashValue,
    this.photoUrls = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'fire_assessment_id': fireAssessmentId,
        'job_id': jobId,
        'item_description': itemDescription,
        'room_of_origin': roomOfOrigin,
        'category': category.dbValue,
        'condition': condition.dbValue,
        if (cleaningMethod != null) 'cleaning_method': cleaningMethod!.dbValue,
        if (boxNumber != null) 'box_number': boxNumber,
        if (storageLocation != null) 'storage_location': storageLocation,
        if (packedAt != null) 'packed_at': packedAt!.toUtc().toIso8601String(),
        if (packedByUserId != null) 'packed_by_user_id': packedByUserId,
        if (estimatedValue != null) 'estimated_value': estimatedValue,
        if (replacementCost != null) 'replacement_cost': replacementCost,
        if (actualCashValue != null) 'actual_cash_value': actualCashValue,
        'photo_urls': photoUrls,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'item_description': itemDescription,
        'room_of_origin': roomOfOrigin,
        'category': category.dbValue,
        'condition': condition.dbValue,
        if (cleaningMethod != null) 'cleaning_method': cleaningMethod!.dbValue,
        if (boxNumber != null) 'box_number': boxNumber,
        if (storageLocation != null) 'storage_location': storageLocation,
        if (packedAt != null) 'packed_at': packedAt!.toUtc().toIso8601String(),
        if (returnedAt != null)
          'returned_at': returnedAt!.toUtc().toIso8601String(),
        if (returnedTo != null) 'returned_to': returnedTo,
        if (estimatedValue != null) 'estimated_value': estimatedValue,
        if (replacementCost != null) 'replacement_cost': replacementCost,
        if (actualCashValue != null) 'actual_cash_value': actualCashValue,
        'photo_urls': photoUrls,
        if (notes != null) 'notes': notes,
      };

  factory ContentPackoutItem.fromJson(Map<String, dynamic> json) {
    return ContentPackoutItem(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      fireAssessmentId: json['fire_assessment_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      itemDescription: json['item_description'] as String? ?? '',
      roomOfOrigin: json['room_of_origin'] as String? ?? '',
      category: ContentCategory.fromString(json['category'] as String?),
      condition: ContentCondition.fromString(json['condition'] as String?),
      cleaningMethod: json['cleaning_method'] != null
          ? CleaningMethod.fromString(json['cleaning_method'] as String?)
          : null,
      boxNumber: json['box_number'] as String?,
      storageLocation: json['storage_location'] as String?,
      packedAt: _parseDate(json['packed_at']),
      packedByUserId: json['packed_by_user_id'] as String?,
      returnedAt: _parseDate(json['returned_at']),
      returnedTo: json['returned_to'] as String?,
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
      replacementCost: (json['replacement_cost'] as num?)?.toDouble(),
      actualCashValue: (json['actual_cash_value'] as num?)?.toDouble(),
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  // Computed
  bool get isPacked => packedAt != null;
  bool get isReturned => returnedAt != null;
  bool get isSalvageable =>
      condition == ContentCondition.salvageable ||
      condition == ContentCondition.needsCleaning ||
      condition == ContentCondition.needsRestoration;

  double get depreciationAmount {
    if (replacementCost == null || actualCashValue == null) return 0;
    return replacementCost! - actualCashValue!;
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
