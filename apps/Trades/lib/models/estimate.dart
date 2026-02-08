// ZAFTO Estimate Model — Supabase Schema
// Created: Sprint D8c (Session 86)
//
// Matches public.estimates + estimate_areas + estimate_line_items +
// estimate_photos tables.
// Two-mode: regular bids + insurance claims.
// Line items are separate DB rows (not JSONB like bids).

enum EstimateType {
  regular,
  insurance;

  String get dbValue => name;
  String get label => switch (this) {
        EstimateType.regular => 'Regular',
        EstimateType.insurance => 'Insurance',
      };
}

enum EstimateStatus {
  draft,
  sent,
  viewed,
  approved,
  rejected,
  expired,
  converted;

  String get dbValue => name;
  String get label => switch (this) {
        EstimateStatus.draft => 'Draft',
        EstimateStatus.sent => 'Sent',
        EstimateStatus.viewed => 'Viewed',
        EstimateStatus.approved => 'Approved',
        EstimateStatus.rejected => 'Rejected',
        EstimateStatus.expired => 'Expired',
        EstimateStatus.converted => 'Converted',
      };
}

enum ActionType {
  add,
  remove,
  replace,
  repair,
  clean,
  detachReset,
  minimumCharge;

  String get dbValue => switch (this) {
        ActionType.detachReset => 'detach_reset',
        ActionType.minimumCharge => 'minimum_charge',
        _ => name,
      };

  String get label => switch (this) {
        ActionType.add => 'Add',
        ActionType.remove => 'Remove',
        ActionType.replace => 'Replace',
        ActionType.repair => 'Repair',
        ActionType.clean => 'Clean',
        ActionType.detachReset => 'Detach & Reset',
        ActionType.minimumCharge => 'Minimum Charge',
      };

  static ActionType fromDb(String? value) {
    if (value == null) return ActionType.add;
    if (value == 'detach_reset') return ActionType.detachReset;
    if (value == 'minimum_charge') return ActionType.minimumCharge;
    return ActionType.values.firstWhere(
      (a) => a.name == value,
      orElse: () => ActionType.add,
    );
  }
}

enum CoverageGroup {
  structural,
  contents,
  other;

  String get dbValue => name;
}

// ============================================================
// ESTIMATE AREA (room-by-room measurement)
// ============================================================

class EstimateArea {
  final String id;
  final String estimateId;
  final String name;
  final int floorNumber;
  final double? lengthFt;
  final double? widthFt;
  final double? heightFt;
  final double? perimeterFt;
  final double? areaSf;
  final int windowCount;
  final int doorCount;
  final String? notes;
  final Map<String, dynamic>? lidarData;
  final int sortOrder;
  final DateTime createdAt;

  const EstimateArea({
    this.id = '',
    this.estimateId = '',
    required this.name,
    this.floorNumber = 1,
    this.lengthFt,
    this.widthFt,
    this.heightFt = 8,
    this.perimeterFt,
    this.areaSf,
    this.windowCount = 0,
    this.doorCount = 0,
    this.notes,
    this.lidarData,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'estimate_id': estimateId,
        'name': name,
        'floor_number': floorNumber,
        'length_ft': lengthFt,
        'width_ft': widthFt,
        'height_ft': heightFt,
        'perimeter_ft': perimeterFt,
        'area_sf': areaSf,
        'window_count': windowCount,
        'door_count': doorCount,
        'notes': notes,
        'lidar_data': lidarData,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'floor_number': floorNumber,
        'length_ft': lengthFt,
        'width_ft': widthFt,
        'height_ft': heightFt,
        'perimeter_ft': perimeterFt,
        'area_sf': areaSf,
        'window_count': windowCount,
        'door_count': doorCount,
        'notes': notes,
        'lidar_data': lidarData,
        'sort_order': sortOrder,
      };

  factory EstimateArea.fromJson(Map<String, dynamic> json) => EstimateArea(
        id: json['id'] as String? ?? '',
        estimateId: json['estimate_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        floorNumber: json['floor_number'] as int? ?? 1,
        lengthFt: (json['length_ft'] as num?)?.toDouble(),
        widthFt: (json['width_ft'] as num?)?.toDouble(),
        heightFt: (json['height_ft'] as num?)?.toDouble() ?? 8,
        perimeterFt: (json['perimeter_ft'] as num?)?.toDouble(),
        areaSf: (json['area_sf'] as num?)?.toDouble(),
        windowCount: json['window_count'] as int? ?? 0,
        doorCount: json['door_count'] as int? ?? 0,
        notes: json['notes'] as String?,
        lidarData: json['lidar_data'] as Map<String, dynamic>?,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: _parseDate(json['created_at']),
      );

  EstimateArea copyWith({
    String? id,
    String? estimateId,
    String? name,
    int? floorNumber,
    double? lengthFt,
    double? widthFt,
    double? heightFt,
    double? perimeterFt,
    double? areaSf,
    int? windowCount,
    int? doorCount,
    String? notes,
    Map<String, dynamic>? lidarData,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EstimateArea(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      floorNumber: floorNumber ?? this.floorNumber,
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      heightFt: heightFt ?? this.heightFt,
      perimeterFt: perimeterFt ?? this.perimeterFt,
      areaSf: areaSf ?? this.areaSf,
      windowCount: windowCount ?? this.windowCount,
      doorCount: doorCount ?? this.doorCount,
      notes: notes ?? this.notes,
      lidarData: lidarData ?? this.lidarData,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get calculatedArea {
    if (areaSf != null) return areaSf!;
    if (lengthFt != null && widthFt != null) return lengthFt! * widthFt!;
    return 0;
  }

  double get calculatedPerimeter {
    if (perimeterFt != null) return perimeterFt!;
    if (lengthFt != null && widthFt != null) {
      return 2 * (lengthFt! + widthFt!);
    }
    return 0;
  }

  double get wallArea {
    final p = calculatedPerimeter;
    final h = heightFt ?? 8;
    if (p <= 0 || h <= 0) return 0;
    return p * h;
  }
}

// ============================================================
// ESTIMATE LINE ITEM (scope item per area)
// ============================================================

class EstimateLineItem {
  final String id;
  final String estimateId;
  final String? areaId;
  final String? itemId;
  final String? industryCode;
  final String? industrySelector;
  final String description;
  final ActionType actionType;
  final double quantity;
  final String unitCode;
  final double laborRate;
  final double materialCost;
  final double equipmentCost;
  final double lineTotal;
  // Insurance-specific
  final double depreciationPct;
  final double rcv;
  final double acv;
  final CoverageGroup coverageGroup;
  final int phase;
  final bool isSupplement;
  // Metadata
  final String? notes;
  final bool aiSuggested;
  final int sortOrder;
  final DateTime createdAt;

  const EstimateLineItem({
    this.id = '',
    this.estimateId = '',
    this.areaId,
    this.itemId,
    this.industryCode,
    this.industrySelector,
    required this.description,
    this.actionType = ActionType.add,
    this.quantity = 1,
    this.unitCode = 'EA',
    this.laborRate = 0,
    this.materialCost = 0,
    this.equipmentCost = 0,
    this.lineTotal = 0,
    this.depreciationPct = 0,
    this.rcv = 0,
    this.acv = 0,
    this.coverageGroup = CoverageGroup.structural,
    this.phase = 1,
    this.isSupplement = false,
    this.notes,
    this.aiSuggested = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'estimate_id': estimateId,
        'area_id': areaId,
        'item_id': itemId,
        'industry_code': industryCode,
        'industry_selector': industrySelector,
        'description': description,
        'action_type': actionType.dbValue,
        'quantity': quantity,
        'unit_code': unitCode,
        'labor_rate': laborRate,
        'material_cost': materialCost,
        'equipment_cost': equipmentCost,
        'line_total': lineTotal,
        'depreciation_pct': depreciationPct,
        'rcv': rcv,
        'acv': acv,
        'coverage_group': coverageGroup.dbValue,
        'phase': phase,
        'is_supplement': isSupplement,
        'notes': notes,
        'ai_suggested': aiSuggested,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'area_id': areaId,
        'item_id': itemId,
        'industry_code': industryCode,
        'industry_selector': industrySelector,
        'description': description,
        'action_type': actionType.dbValue,
        'quantity': quantity,
        'unit_code': unitCode,
        'labor_rate': laborRate,
        'material_cost': materialCost,
        'equipment_cost': equipmentCost,
        'line_total': lineTotal,
        'depreciation_pct': depreciationPct,
        'rcv': rcv,
        'acv': acv,
        'coverage_group': coverageGroup.dbValue,
        'phase': phase,
        'is_supplement': isSupplement,
        'notes': notes,
        'ai_suggested': aiSuggested,
        'sort_order': sortOrder,
      };

  factory EstimateLineItem.fromJson(Map<String, dynamic> json) =>
      EstimateLineItem(
        id: json['id'] as String? ?? '',
        estimateId: json['estimate_id'] as String? ?? '',
        areaId: json['area_id'] as String?,
        itemId: json['item_id'] as String?,
        industryCode: json['industry_code'] as String?,
        industrySelector: json['industry_selector'] as String?,
        description: json['description'] as String? ?? '',
        actionType: ActionType.fromDb(json['action_type'] as String?),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unitCode: json['unit_code'] as String? ?? 'EA',
        laborRate: (json['labor_rate'] as num?)?.toDouble() ?? 0,
        materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
        equipmentCost: (json['equipment_cost'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
        depreciationPct:
            (json['depreciation_pct'] as num?)?.toDouble() ?? 0,
        rcv: (json['rcv'] as num?)?.toDouble() ?? 0,
        acv: (json['acv'] as num?)?.toDouble() ?? 0,
        coverageGroup: CoverageGroup.values.firstWhere(
          (c) => c.name == json['coverage_group'],
          orElse: () => CoverageGroup.structural,
        ),
        phase: json['phase'] as int? ?? 1,
        isSupplement: json['is_supplement'] as bool? ?? false,
        notes: json['notes'] as String?,
        aiSuggested: json['ai_suggested'] as bool? ?? false,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: _parseDate(json['created_at']),
      );

  EstimateLineItem copyWith({
    String? id,
    String? estimateId,
    String? areaId,
    String? itemId,
    String? industryCode,
    String? industrySelector,
    String? description,
    ActionType? actionType,
    double? quantity,
    String? unitCode,
    double? laborRate,
    double? materialCost,
    double? equipmentCost,
    double? lineTotal,
    double? depreciationPct,
    double? rcv,
    double? acv,
    CoverageGroup? coverageGroup,
    int? phase,
    bool? isSupplement,
    String? notes,
    bool? aiSuggested,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EstimateLineItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      areaId: areaId ?? this.areaId,
      itemId: itemId ?? this.itemId,
      industryCode: industryCode ?? this.industryCode,
      industrySelector: industrySelector ?? this.industrySelector,
      description: description ?? this.description,
      actionType: actionType ?? this.actionType,
      quantity: quantity ?? this.quantity,
      unitCode: unitCode ?? this.unitCode,
      laborRate: laborRate ?? this.laborRate,
      materialCost: materialCost ?? this.materialCost,
      equipmentCost: equipmentCost ?? this.equipmentCost,
      lineTotal: lineTotal ?? this.lineTotal,
      depreciationPct: depreciationPct ?? this.depreciationPct,
      rcv: rcv ?? this.rcv,
      acv: acv ?? this.acv,
      coverageGroup: coverageGroup ?? this.coverageGroup,
      phase: phase ?? this.phase,
      isSupplement: isSupplement ?? this.isSupplement,
      notes: notes ?? this.notes,
      aiSuggested: aiSuggested ?? this.aiSuggested,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  EstimateLineItem recalculate() {
    final total = quantity * (laborRate + materialCost + equipmentCost);
    final newRcv = total;
    final newAcv = total * (1 - depreciationPct / 100);
    return copyWith(lineTotal: total, rcv: newRcv, acv: newAcv);
  }
}

// ============================================================
// ESTIMATE PHOTO (evidence linked to estimates/areas/items)
// ============================================================

class EstimatePhoto {
  final String id;
  final String estimateId;
  final String? areaId;
  final String? lineItemId;
  final String storagePath;
  final String? caption;
  final Map<String, dynamic>? aiAnalysis;
  final DateTime? takenAt;
  final DateTime createdAt;

  const EstimatePhoto({
    this.id = '',
    this.estimateId = '',
    this.areaId,
    this.lineItemId,
    required this.storagePath,
    this.caption,
    this.aiAnalysis,
    this.takenAt,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'estimate_id': estimateId,
        'area_id': areaId,
        'line_item_id': lineItemId,
        'storage_path': storagePath,
        'caption': caption,
        'ai_analysis': aiAnalysis,
        'taken_at': takenAt?.toUtc().toIso8601String(),
      };

  factory EstimatePhoto.fromJson(Map<String, dynamic> json) => EstimatePhoto(
        id: json['id'] as String? ?? '',
        estimateId: json['estimate_id'] as String? ?? '',
        areaId: json['area_id'] as String?,
        lineItemId: json['line_item_id'] as String?,
        storagePath: json['storage_path'] as String? ?? '',
        caption: json['caption'] as String?,
        aiAnalysis: json['ai_analysis'] as Map<String, dynamic>?,
        takenAt: _parseOptionalDate(json['taken_at']),
        createdAt: _parseDate(json['created_at']),
      );

  EstimatePhoto copyWith({
    String? id,
    String? estimateId,
    String? areaId,
    String? lineItemId,
    String? storagePath,
    String? caption,
    Map<String, dynamic>? aiAnalysis,
    DateTime? takenAt,
    DateTime? createdAt,
  }) {
    return EstimatePhoto(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      areaId: areaId ?? this.areaId,
      lineItemId: lineItemId ?? this.lineItemId,
      storagePath: storagePath ?? this.storagePath,
      caption: caption ?? this.caption,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ============================================================
// MAIN ESTIMATE MODEL
// ============================================================

class Estimate {
  final String id;
  final String companyId;
  final String? jobId;
  final String? customerId;
  final String createdBy;
  final String estimateNumber;
  final String? title;

  // Property address
  final String? propertyAddress;
  final String? propertyCity;
  final String? propertyState;
  final String? propertyZip;

  // Type & status
  final EstimateType estimateType;
  final EstimateStatus status;

  // Pricing
  final double subtotal;
  final double overheadPct;
  final double profitPct;
  final double taxPct;
  final double taxAmount;
  final double overheadAmount;
  final double profitAmount;
  final double grandTotal;

  // Insurance-specific
  final double? deductible;
  final String? claimNumber;
  final String? policyNumber;
  final DateTime? dateOfLoss;
  final String? insuranceCarrier;
  final String? adjusterName;
  final String? adjusterEmail;
  final String? adjusterPhone;

  // Notes
  final String? notes;
  final String? internalNotes;

  // Lifecycle
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? expiredAt;
  final String? convertedJobId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested children (loaded separately)
  final List<EstimateArea> areas;
  final List<EstimateLineItem> lineItems;
  final List<EstimatePhoto> photos;

  const Estimate({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.customerId,
    this.createdBy = '',
    this.estimateNumber = '',
    this.title,
    this.propertyAddress,
    this.propertyCity,
    this.propertyState,
    this.propertyZip,
    this.estimateType = EstimateType.regular,
    this.status = EstimateStatus.draft,
    this.subtotal = 0,
    this.overheadPct = 10,
    this.profitPct = 10,
    this.taxPct = 0,
    this.taxAmount = 0,
    this.overheadAmount = 0,
    this.profitAmount = 0,
    this.grandTotal = 0,
    this.deductible,
    this.claimNumber,
    this.policyNumber,
    this.dateOfLoss,
    this.insuranceCarrier,
    this.adjusterName,
    this.adjusterEmail,
    this.adjusterPhone,
    this.notes,
    this.internalNotes,
    this.sentAt,
    this.viewedAt,
    this.approvedAt,
    this.rejectedAt,
    this.expiredAt,
    this.convertedJobId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.areas = const [],
    this.lineItems = const [],
    this.photos = const [],
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'customer_id': customerId,
        'created_by': createdBy,
        'estimate_number': estimateNumber,
        'title': title,
        'property_address': propertyAddress,
        'property_city': propertyCity,
        'property_state': propertyState,
        'property_zip': propertyZip,
        'estimate_type': estimateType.dbValue,
        'status': status.dbValue,
        'subtotal': subtotal,
        'overhead_pct': overheadPct,
        'profit_pct': profitPct,
        'tax_pct': taxPct,
        'tax_amount': taxAmount,
        'overhead_amount': overheadAmount,
        'profit_amount': profitAmount,
        'grand_total': grandTotal,
        'deductible': deductible,
        'claim_number': claimNumber,
        'policy_number': policyNumber,
        'date_of_loss': dateOfLoss?.toIso8601String().split('T').first,
        'insurance_carrier': insuranceCarrier,
        'adjuster_name': adjusterName,
        'adjuster_email': adjusterEmail,
        'adjuster_phone': adjusterPhone,
        'notes': notes,
        'internal_notes': internalNotes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'job_id': jobId,
        'customer_id': customerId,
        'title': title,
        'property_address': propertyAddress,
        'property_city': propertyCity,
        'property_state': propertyState,
        'property_zip': propertyZip,
        'estimate_type': estimateType.dbValue,
        'status': status.dbValue,
        'subtotal': subtotal,
        'overhead_pct': overheadPct,
        'profit_pct': profitPct,
        'tax_pct': taxPct,
        'tax_amount': taxAmount,
        'overhead_amount': overheadAmount,
        'profit_amount': profitAmount,
        'grand_total': grandTotal,
        'deductible': deductible,
        'claim_number': claimNumber,
        'policy_number': policyNumber,
        'date_of_loss': dateOfLoss?.toIso8601String().split('T').first,
        'insurance_carrier': insuranceCarrier,
        'adjuster_name': adjusterName,
        'adjuster_email': adjusterEmail,
        'adjuster_phone': adjusterPhone,
        'notes': notes,
        'internal_notes': internalNotes,
        'sent_at': sentAt?.toUtc().toIso8601String(),
        'viewed_at': viewedAt?.toUtc().toIso8601String(),
        'approved_at': approvedAt?.toUtc().toIso8601String(),
        'rejected_at': rejectedAt?.toUtc().toIso8601String(),
        'expired_at': expiredAt?.toUtc().toIso8601String(),
        'converted_job_id': convertedJobId,
      };

  factory Estimate.fromJson(Map<String, dynamic> json) {
    // Parse nested areas if joined
    List<EstimateArea> areas = const [];
    if (json['estimate_areas'] is List) {
      areas = (json['estimate_areas'] as List)
          .map((e) => EstimateArea.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse nested line items if joined
    List<EstimateLineItem> lineItems = const [];
    if (json['estimate_line_items'] is List) {
      lineItems = (json['estimate_line_items'] as List)
          .map((e) =>
              EstimateLineItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse nested photos if joined
    List<EstimatePhoto> photos = const [];
    if (json['estimate_photos'] is List) {
      photos = (json['estimate_photos'] as List)
          .map((e) => EstimatePhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Estimate(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      customerId: json['customer_id'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      estimateNumber: json['estimate_number'] as String? ?? '',
      title: json['title'] as String?,
      propertyAddress: json['property_address'] as String?,
      propertyCity: json['property_city'] as String?,
      propertyState: json['property_state'] as String?,
      propertyZip: json['property_zip'] as String?,
      estimateType: EstimateType.values.firstWhere(
        (t) => t.name == json['estimate_type'],
        orElse: () => EstimateType.regular,
      ),
      status: EstimateStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EstimateStatus.draft,
      ),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      overheadPct: (json['overhead_pct'] as num?)?.toDouble() ?? 10,
      profitPct: (json['profit_pct'] as num?)?.toDouble() ?? 10,
      taxPct: (json['tax_pct'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      overheadAmount: (json['overhead_amount'] as num?)?.toDouble() ?? 0,
      profitAmount: (json['profit_amount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      deductible: (json['deductible'] as num?)?.toDouble(),
      claimNumber: json['claim_number'] as String?,
      policyNumber: json['policy_number'] as String?,
      dateOfLoss: _parseOptionalDate(json['date_of_loss']),
      insuranceCarrier: json['insurance_carrier'] as String?,
      adjusterName: json['adjuster_name'] as String?,
      adjusterEmail: json['adjuster_email'] as String?,
      adjusterPhone: json['adjuster_phone'] as String?,
      notes: json['notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      sentAt: _parseOptionalDate(json['sent_at']),
      viewedAt: _parseOptionalDate(json['viewed_at']),
      approvedAt: _parseOptionalDate(json['approved_at']),
      rejectedAt: _parseOptionalDate(json['rejected_at']),
      expiredAt: _parseOptionalDate(json['expired_at']),
      convertedJobId: json['converted_job_id'] as String?,
      deletedAt: _parseOptionalDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      areas: areas,
      lineItems: lineItems,
      photos: photos,
    );
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  String get displayTitle => title ?? estimateNumber;

  bool get isInsurance => estimateType == EstimateType.insurance;

  bool get isEditable =>
      status == EstimateStatus.draft || status == EstimateStatus.rejected;

  bool get canSend => status == EstimateStatus.draft && lineItems.isNotEmpty;

  bool get isPending =>
      status == EstimateStatus.sent || status == EstimateStatus.viewed;

  String get fullPropertyAddress {
    final parts = <String>[];
    if (propertyAddress != null) parts.add(propertyAddress!);
    if (propertyCity != null) parts.add(propertyCity!);
    if (propertyState != null) parts.add(propertyState!);
    if (propertyZip != null) parts.add(propertyZip!);
    return parts.join(', ');
  }

  String get grandTotalDisplay => '\$${grandTotal.toStringAsFixed(2)}';

  double get totalRcv =>
      lineItems.fold<double>(0.0, (sum, item) => sum + item.rcv);

  double get totalAcv =>
      lineItems.fold<double>(0.0, (sum, item) => sum + item.acv);

  double get totalDepreciation => totalRcv - totalAcv;

  double get netClaimAmount {
    if (!isInsurance) return grandTotal;
    return totalAcv - (deductible ?? 0);
  }

  int get lineItemCount => lineItems.length;

  int get areaCount => areas.length;

  // ============================================================
  // CALCULATIONS
  // ============================================================

  Estimate recalculate() {
    final newSubtotal =
        lineItems.fold<double>(0.0, (sum, item) => sum + item.lineTotal);
    final newOverhead = newSubtotal * (overheadPct / 100);
    final newProfit = newSubtotal * (profitPct / 100);
    final afterMarkup = newSubtotal + newOverhead + newProfit;
    final newTax = afterMarkup * (taxPct / 100);
    final newTotal = afterMarkup + newTax;

    return copyWith(
      subtotal: newSubtotal,
      overheadAmount: newOverhead,
      profitAmount: newProfit,
      taxAmount: newTax,
      grandTotal: newTotal,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Estimate copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? customerId,
    String? createdBy,
    String? estimateNumber,
    String? title,
    String? propertyAddress,
    String? propertyCity,
    String? propertyState,
    String? propertyZip,
    EstimateType? estimateType,
    EstimateStatus? status,
    double? subtotal,
    double? overheadPct,
    double? profitPct,
    double? taxPct,
    double? taxAmount,
    double? overheadAmount,
    double? profitAmount,
    double? grandTotal,
    double? deductible,
    String? claimNumber,
    String? policyNumber,
    DateTime? dateOfLoss,
    String? insuranceCarrier,
    String? adjusterName,
    String? adjusterEmail,
    String? adjusterPhone,
    String? notes,
    String? internalNotes,
    DateTime? sentAt,
    DateTime? viewedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? expiredAt,
    String? convertedJobId,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EstimateArea>? areas,
    List<EstimateLineItem>? lineItems,
    List<EstimatePhoto>? photos,
  }) {
    return Estimate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      createdBy: createdBy ?? this.createdBy,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      title: title ?? this.title,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyCity: propertyCity ?? this.propertyCity,
      propertyState: propertyState ?? this.propertyState,
      propertyZip: propertyZip ?? this.propertyZip,
      estimateType: estimateType ?? this.estimateType,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      overheadPct: overheadPct ?? this.overheadPct,
      profitPct: profitPct ?? this.profitPct,
      taxPct: taxPct ?? this.taxPct,
      taxAmount: taxAmount ?? this.taxAmount,
      overheadAmount: overheadAmount ?? this.overheadAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      deductible: deductible ?? this.deductible,
      claimNumber: claimNumber ?? this.claimNumber,
      policyNumber: policyNumber ?? this.policyNumber,
      dateOfLoss: dateOfLoss ?? this.dateOfLoss,
      insuranceCarrier: insuranceCarrier ?? this.insuranceCarrier,
      adjusterName: adjusterName ?? this.adjusterName,
      adjusterEmail: adjusterEmail ?? this.adjusterEmail,
      adjusterPhone: adjusterPhone ?? this.adjusterPhone,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      convertedJobId: convertedJobId ?? this.convertedJobId,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      areas: areas ?? this.areas,
      lineItems: lineItems ?? this.lineItems,
      photos: photos ?? this.photos,
    );
  }
}

// ============================================================
// DATE HELPERS
// ============================================================

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  return null;
}
