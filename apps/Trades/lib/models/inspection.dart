// Inspection Models — All Inspector Types
// Maps to `pm_inspections`, `pm_inspection_items`, `inspection_deficiencies`,
// `inspection_templates` tables in Supabase PostgreSQL.
// Supports 13+ inspector types: building/code, property, insurance/restoration,
// QC, safety/OSHA, environmental, permit, ADA, roofing, fire/life safety,
// electrical, plumbing, HVAC.

// ============================================================
// ENUMS
// ============================================================

enum InspectionType {
  // Property Management (original)
  moveIn,
  moveOut,
  routine,
  annual,
  maintenance,
  safety,
  // Building / Code
  roughIn,
  framing,
  foundation,
  finalInspection,
  permit,
  codeCompliance,
  // Quality Control
  qcHoldPoint,
  // Re-inspection
  reInspection,
  // Environmental
  swppp,
  environmental,
  // ADA
  ada,
  // Insurance / Restoration
  insuranceDamage,
  tpi,
  // Pre-construction
  preConstruction,
  // Trade-specific
  roofing,
  fireLifeSafety,
  electrical,
  plumbing,
  hvac,
}

enum InspectionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum ItemCondition {
  excellent,
  good,
  fair,
  poor,
  damaged,
  missing,
}

enum DeficiencySeverity {
  critical,
  major,
  minor,
  info,
}

enum DeficiencyStatus {
  open,
  assigned,
  inProgress,
  corrected,
  verified,
  closed,
}

// ============================================================
// PM INSPECTION
// ============================================================

class PmInspection {
  final String id;
  final String companyId;
  final String propertyId;
  final String? unitId;
  final String? inspectorId;
  final InspectionType inspectionType;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final ItemCondition? overallCondition;
  final int? score;
  final String? notes;
  final List<String> photos;
  final InspectionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // INS1 — New fields
  final String? permitId;
  final String? parentInspectionId;
  final double? gpsLat;
  final double? gpsLng;
  final double? gpsCheckoutLat;
  final double? gpsCheckoutLng;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final String? signatureInspector;
  final String? signatureContact;
  final List<String> codeCitations;
  final int? deficiencyCount;
  final String? reportUrl;
  final String? templateId;
  final String? trade;
  final DeficiencySeverity? severity;
  final String? weatherConditions;
  final bool? stormEvent;

  const PmInspection({
    this.id = '',
    this.companyId = '',
    this.propertyId = '',
    this.unitId,
    this.inspectorId,
    this.inspectionType = InspectionType.routine,
    this.scheduledDate,
    this.completedDate,
    this.overallCondition,
    this.score,
    this.notes,
    this.photos = const [],
    this.status = InspectionStatus.scheduled,
    required this.createdAt,
    required this.updatedAt,
    // INS1 — New fields
    this.permitId,
    this.parentInspectionId,
    this.gpsLat,
    this.gpsLng,
    this.gpsCheckoutLat,
    this.gpsCheckoutLng,
    this.checkinAt,
    this.checkoutAt,
    this.signatureInspector,
    this.signatureContact,
    this.codeCitations = const [],
    this.deficiencyCount,
    this.reportUrl,
    this.templateId,
    this.trade,
    this.severity,
    this.weatherConditions,
    this.stormEvent,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        if (unitId != null) 'unit_id': unitId,
        if (inspectorId != null) 'inspector_id': inspectorId,
        'inspection_type': enumToDb(inspectionType),
        if (scheduledDate != null)
          'scheduled_date': scheduledDate!.toUtc().toIso8601String(),
        if (completedDate != null)
          'completed_date': completedDate!.toUtc().toIso8601String(),
        if (overallCondition != null)
          'overall_condition': enumToDb(overallCondition!),
        if (score != null) 'score': score,
        if (notes != null) 'notes': notes,
        'photos': photos,
        'status': enumToDb(status),
        // INS1 — New fields
        if (permitId != null) 'permit_id': permitId,
        if (parentInspectionId != null)
          'parent_inspection_id': parentInspectionId,
        if (gpsLat != null) 'gps_lat': gpsLat,
        if (gpsLng != null) 'gps_lng': gpsLng,
        if (gpsCheckoutLat != null) 'gps_checkout_lat': gpsCheckoutLat,
        if (gpsCheckoutLng != null) 'gps_checkout_lng': gpsCheckoutLng,
        if (checkinAt != null)
          'checkin_at': checkinAt!.toUtc().toIso8601String(),
        if (checkoutAt != null)
          'checkout_at': checkoutAt!.toUtc().toIso8601String(),
        if (signatureInspector != null)
          'signature_inspector': signatureInspector,
        if (signatureContact != null) 'signature_contact': signatureContact,
        if (codeCitations.isNotEmpty) 'code_citations': codeCitations,
        if (reportUrl != null) 'report_url': reportUrl,
        if (templateId != null) 'template_id': templateId,
        if (trade != null) 'trade': trade,
        if (severity != null) 'severity': enumToDb(severity!),
        if (weatherConditions != null) 'weather_conditions': weatherConditions,
        if (stormEvent != null) 'storm_event': stormEvent,
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_id': unitId,
        'inspector_id': inspectorId,
        'inspection_type': enumToDb(inspectionType),
        'scheduled_date': scheduledDate?.toUtc().toIso8601String(),
        'completed_date': completedDate?.toUtc().toIso8601String(),
        'overall_condition':
            overallCondition != null ? enumToDb(overallCondition!) : null,
        'score': score,
        'notes': notes,
        'photos': photos,
        'status': enumToDb(status),
        // INS1 — New fields
        'permit_id': permitId,
        'parent_inspection_id': parentInspectionId,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'gps_checkout_lat': gpsCheckoutLat,
        'gps_checkout_lng': gpsCheckoutLng,
        'checkin_at': checkinAt?.toUtc().toIso8601String(),
        'checkout_at': checkoutAt?.toUtc().toIso8601String(),
        'signature_inspector': signatureInspector,
        'signature_contact': signatureContact,
        'code_citations': codeCitations,
        'report_url': reportUrl,
        'template_id': templateId,
        'trade': trade,
        'severity': severity != null ? enumToDb(severity!) : null,
        'weather_conditions': weatherConditions,
        'storm_event': stormEvent,
      };

  factory PmInspection.fromJson(Map<String, dynamic> json) {
    return PmInspection(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String?,
      inspectorId:
          (json['inspector_id'] ?? json['inspectorId']) as String?,
      inspectionType: _parseEnum(
        (json['inspection_type'] ?? json['inspectionType']) as String?,
        InspectionType.values,
        InspectionType.routine,
      ),
      scheduledDate: _parseDate(
          json['scheduled_date'] ?? json['scheduledDate']),
      completedDate: _parseDate(
          json['completed_date'] ?? json['completedDate']),
      overallCondition: json['overall_condition'] != null ||
              json['overallCondition'] != null
          ? _parseEnum(
              (json['overall_condition'] ?? json['overallCondition'])
                  as String?,
              ItemCondition.values,
              ItemCondition.good,
            )
          : null,
      score: (json['score'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: _parseEnum(
        json['status'] as String?,
        InspectionStatus.values,
        InspectionStatus.scheduled,
      ),
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
      // INS1 — New fields
      permitId: (json['permit_id'] ?? json['permitId']) as String?,
      parentInspectionId:
          (json['parent_inspection_id'] ?? json['parentInspectionId'])
              as String?,
      gpsLat: (json['gps_lat'] as num?)?.toDouble(),
      gpsLng: (json['gps_lng'] as num?)?.toDouble(),
      gpsCheckoutLat: (json['gps_checkout_lat'] as num?)?.toDouble(),
      gpsCheckoutLng: (json['gps_checkout_lng'] as num?)?.toDouble(),
      checkinAt: _parseDate(json['checkin_at'] ?? json['checkinAt']),
      checkoutAt: _parseDate(json['checkout_at'] ?? json['checkoutAt']),
      signatureInspector:
          (json['signature_inspector'] ?? json['signatureInspector'])
              as String?,
      signatureContact:
          (json['signature_contact'] ?? json['signatureContact'])
              as String?,
      codeCitations: (json['code_citations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      deficiencyCount:
          (json['deficiency_count'] as num?)?.toInt(),
      reportUrl: (json['report_url'] ?? json['reportUrl']) as String?,
      templateId:
          (json['template_id'] ?? json['templateId']) as String?,
      trade: json['trade'] as String?,
      severity: json['severity'] != null
          ? _parseEnum(
              json['severity'] as String?,
              DeficiencySeverity.values,
              DeficiencySeverity.info,
            )
          : null,
      weatherConditions:
          (json['weather_conditions'] ?? json['weatherConditions'])
              as String?,
      stormEvent: json['storm_event'] as bool?,
    );
  }

  PmInspection copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? unitId,
    String? inspectorId,
    InspectionType? inspectionType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    ItemCondition? overallCondition,
    int? score,
    String? notes,
    List<String>? photos,
    InspectionStatus? status,
    String? permitId,
    String? parentInspectionId,
    double? gpsLat,
    double? gpsLng,
    double? gpsCheckoutLat,
    double? gpsCheckoutLng,
    DateTime? checkinAt,
    DateTime? checkoutAt,
    String? signatureInspector,
    String? signatureContact,
    List<String>? codeCitations,
    int? deficiencyCount,
    String? reportUrl,
    String? templateId,
    String? trade,
    DeficiencySeverity? severity,
    String? weatherConditions,
    bool? stormEvent,
  }) {
    return PmInspection(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectionType: inspectionType ?? this.inspectionType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      overallCondition: overallCondition ?? this.overallCondition,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      permitId: permitId ?? this.permitId,
      parentInspectionId: parentInspectionId ?? this.parentInspectionId,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      gpsCheckoutLat: gpsCheckoutLat ?? this.gpsCheckoutLat,
      gpsCheckoutLng: gpsCheckoutLng ?? this.gpsCheckoutLng,
      checkinAt: checkinAt ?? this.checkinAt,
      checkoutAt: checkoutAt ?? this.checkoutAt,
      signatureInspector: signatureInspector ?? this.signatureInspector,
      signatureContact: signatureContact ?? this.signatureContact,
      codeCitations: codeCitations ?? this.codeCitations,
      deficiencyCount: deficiencyCount ?? this.deficiencyCount,
      reportUrl: reportUrl ?? this.reportUrl,
      templateId: templateId ?? this.templateId,
      trade: trade ?? this.trade,
      severity: severity ?? this.severity,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      stormEvent: stormEvent ?? this.stormEvent,
    );
  }

  // Computed getters
  bool get isReInspection => parentInspectionId != null;
  bool get hasGps => gpsLat != null && gpsLng != null;
  bool get hasReport => reportUrl != null;
  bool get hasSignatures =>
      signatureInspector != null && signatureContact != null;
  bool get passed => (score ?? 0) >= 70;
  Duration? get duration =>
      checkinAt != null && checkoutAt != null
          ? checkoutAt!.difference(checkinAt!)
          : null;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static T _parseEnum<T extends Enum>(
    String? value,
    List<T> values,
    T defaultValue,
  ) {
    if (value == null || value.isEmpty) return defaultValue;
    for (final v in values) {
      if (v.name == value) return v;
    }
    final camel = _snakeToCamel(value);
    for (final v in values) {
      if (v.name == camel) return v;
    }
    return defaultValue;
  }

  static String _snakeToCamel(String value) {
    final parts = value.split('_');
    if (parts.length <= 1) return value;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty
            ? ''
            : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }

  static String enumToDb<T extends Enum>(T value) {
    return value.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

// ============================================================
// PM INSPECTION ITEM
// ============================================================

class PmInspectionItem {
  final String id;
  final String inspectionId;
  final String area;
  final String itemName;
  final ItemCondition condition;
  final String? notes;
  final List<String> photos;
  final List<String> codeRefs;
  final int sortOrder;
  final DateTime createdAt;

  const PmInspectionItem({
    this.id = '',
    this.inspectionId = '',
    required this.area,
    required this.itemName,
    this.condition = ItemCondition.good,
    this.notes,
    this.photos = const [],
    this.codeRefs = const [],
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'inspection_id': inspectionId,
        'area': area,
        'item_name': itemName,
        'condition': PmInspection.enumToDb(condition),
        if (notes != null) 'notes': notes,
        'photos': photos,
        if (codeRefs.isNotEmpty) 'code_refs': codeRefs,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'area': area,
        'item_name': itemName,
        'condition': PmInspection.enumToDb(condition),
        'notes': notes,
        'photos': photos,
        'code_refs': codeRefs,
        'sort_order': sortOrder,
      };

  factory PmInspectionItem.fromJson(Map<String, dynamic> json) {
    return PmInspectionItem(
      id: json['id'] as String? ?? '',
      inspectionId:
          (json['inspection_id'] ?? json['inspectionId']) as String? ?? '',
      area: (json['area'] as String?) ?? '',
      itemName:
          (json['item_name'] ?? json['itemName']) as String? ?? '',
      condition: PmInspection._parseEnum(
        json['condition'] as String?,
        ItemCondition.values,
        ItemCondition.good,
      ),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      codeRefs: (json['code_refs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sortOrder:
          (json['sort_order'] ?? json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          PmInspection._parseDate(
              json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  PmInspectionItem copyWith({
    String? id,
    String? inspectionId,
    String? area,
    String? itemName,
    ItemCondition? condition,
    String? notes,
    List<String>? photos,
    List<String>? codeRefs,
    int? sortOrder,
  }) {
    return PmInspectionItem(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      area: area ?? this.area,
      itemName: itemName ?? this.itemName,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      codeRefs: codeRefs ?? this.codeRefs,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}

// ============================================================
// INSPECTION DEFICIENCY
// ============================================================

class InspectionDeficiency {
  final String id;
  final String companyId;
  final String inspectionId;
  final String? itemId;
  final String? codeSection;
  final String? codeTitle;
  final DeficiencySeverity severity;
  final String description;
  final String? remediation;
  final DateTime? deadline;
  final DeficiencyStatus status;
  final List<String> photos;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InspectionDeficiency({
    this.id = '',
    this.companyId = '',
    required this.inspectionId,
    this.itemId,
    this.codeSection,
    this.codeTitle,
    this.severity = DeficiencySeverity.major,
    required this.description,
    this.remediation,
    this.deadline,
    this.status = DeficiencyStatus.open,
    this.photos = const [],
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'inspection_id': inspectionId,
        if (itemId != null) 'item_id': itemId,
        if (codeSection != null) 'code_section': codeSection,
        if (codeTitle != null) 'code_title': codeTitle,
        'severity': PmInspection.enumToDb(severity),
        'description': description,
        if (remediation != null) 'remediation': remediation,
        if (deadline != null)
          'deadline': deadline!.toUtc().toIso8601String(),
        'status': PmInspection.enumToDb(status),
        'photos': photos,
        if (assignedTo != null) 'assigned_to': assignedTo,
      };

  Map<String, dynamic> toUpdateJson() => {
        'item_id': itemId,
        'code_section': codeSection,
        'code_title': codeTitle,
        'severity': PmInspection.enumToDb(severity),
        'description': description,
        'remediation': remediation,
        'deadline': deadline?.toUtc().toIso8601String(),
        'status': PmInspection.enumToDb(status),
        'photos': photos,
        'assigned_to': assignedTo,
      };

  factory InspectionDeficiency.fromJson(Map<String, dynamic> json) {
    return InspectionDeficiency(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      inspectionId:
          (json['inspection_id'] ?? json['inspectionId']) as String? ?? '',
      itemId: (json['item_id'] ?? json['itemId']) as String?,
      codeSection:
          (json['code_section'] ?? json['codeSection']) as String?,
      codeTitle:
          (json['code_title'] ?? json['codeTitle']) as String?,
      severity: PmInspection._parseEnum(
        json['severity'] as String?,
        DeficiencySeverity.values,
        DeficiencySeverity.major,
      ),
      description: json['description'] as String? ?? '',
      remediation: json['remediation'] as String?,
      deadline: PmInspection._parseDate(json['deadline']),
      status: PmInspection._parseEnum(
        json['status'] as String?,
        DeficiencyStatus.values,
        DeficiencyStatus.open,
      ),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      assignedTo:
          (json['assigned_to'] ?? json['assignedTo']) as String?,
      createdAt:
          PmInspection._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          PmInspection._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  InspectionDeficiency copyWith({
    String? id,
    String? companyId,
    String? inspectionId,
    String? itemId,
    String? codeSection,
    String? codeTitle,
    DeficiencySeverity? severity,
    String? description,
    String? remediation,
    DateTime? deadline,
    DeficiencyStatus? status,
    List<String>? photos,
    String? assignedTo,
  }) {
    return InspectionDeficiency(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      inspectionId: inspectionId ?? this.inspectionId,
      itemId: itemId ?? this.itemId,
      codeSection: codeSection ?? this.codeSection,
      codeTitle: codeTitle ?? this.codeTitle,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      remediation: remediation ?? this.remediation,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isOpen => status == DeficiencyStatus.open;
  bool get isCritical => severity == DeficiencySeverity.critical;
  bool get isOverdue =>
      deadline != null && DateTime.now().isAfter(deadline!) && !isClosed;
  bool get isClosed => status == DeficiencyStatus.closed;
  bool get hasCodeCitation => codeSection != null;
}

// ============================================================
// INSPECTION TEMPLATE
// ============================================================

class InspectionTemplate {
  final String id;
  final String companyId;
  final String name;
  final String? trade;
  final InspectionType inspectionType;
  final List<TemplateSection> sections;
  final bool isSystem;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InspectionTemplate({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.trade,
    this.inspectionType = InspectionType.routine,
    this.sections = const [],
    this.isSystem = false,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (trade != null) 'trade': trade,
        'inspection_type': PmInspection.enumToDb(inspectionType),
        'sections': sections.map((s) => s.toJson()).toList(),
        'is_system': isSystem,
        'version': version,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'trade': trade,
        'inspection_type': PmInspection.enumToDb(inspectionType),
        'sections': sections.map((s) => s.toJson()).toList(),
        'version': version,
      };

  factory InspectionTemplate.fromJson(Map<String, dynamic> json) {
    return InspectionTemplate(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      name: json['name'] as String? ?? '',
      trade: json['trade'] as String?,
      inspectionType: PmInspection._parseEnum(
        (json['inspection_type'] ?? json['inspectionType']) as String?,
        InspectionType.values,
        InspectionType.routine,
      ),
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) =>
                  TemplateSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      isSystem: json['is_system'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt:
          PmInspection._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          PmInspection._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  InspectionTemplate copyWith({
    String? id,
    String? companyId,
    String? name,
    String? trade,
    InspectionType? inspectionType,
    List<TemplateSection>? sections,
    bool? isSystem,
    int? version,
  }) {
    return InspectionTemplate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      trade: trade ?? this.trade,
      inspectionType: inspectionType ?? this.inspectionType,
      sections: sections ?? this.sections,
      isSystem: isSystem ?? this.isSystem,
      version: version ?? this.version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  int get totalItems =>
      sections.fold(0, (sum, s) => sum + s.items.length);
}

// ============================================================
// TEMPLATE SECTION + ITEM (embedded JSON in template)
// ============================================================

class TemplateSection {
  final String name;
  final int sortOrder;
  final List<TemplateItem> items;

  const TemplateSection({
    required this.name,
    this.sortOrder = 0,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sort_order': sortOrder,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      name: json['name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (i) => TemplateItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class TemplateItem {
  final String name;
  final int sortOrder;
  final int weight;
  final bool required;

  const TemplateItem({
    required this.name,
    this.sortOrder = 0,
    this.weight = 1,
    this.required = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sort_order': sortOrder,
        'weight': weight,
        'required': required,
      };

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      name: json['name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      required: json['required'] as bool? ?? true,
    );
  }
}
