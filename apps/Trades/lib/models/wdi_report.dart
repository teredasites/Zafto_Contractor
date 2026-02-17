// ZAFTO WDI Report Model (NPMA-33)
// Maps to `wdi_reports` table. Sprint NICHE1 — Pest control module.

enum WdiReportType {
  npma33,
  stateSpecific,
  va,
  fha;

  String get dbValue {
    switch (this) {
      case WdiReportType.npma33:
        return 'npma_33';
      case WdiReportType.stateSpecific:
        return 'state_specific';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case WdiReportType.npma33:
        return 'NPMA-33';
      case WdiReportType.stateSpecific:
        return 'State Specific';
      case WdiReportType.va:
        return 'VA';
      case WdiReportType.fha:
        return 'FHA';
    }
  }

  static WdiReportType fromString(String? value) {
    if (value == null) return WdiReportType.npma33;
    switch (value) {
      case 'npma_33':
        return WdiReportType.npma33;
      case 'state_specific':
        return WdiReportType.stateSpecific;
      default:
        return WdiReportType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => WdiReportType.npma33,
        );
    }
  }
}

enum WdiReportStatus {
  draft,
  complete,
  submitted,
  accepted,
  rejected;

  String get label {
    switch (this) {
      case WdiReportStatus.draft:
        return 'Draft';
      case WdiReportStatus.complete:
        return 'Complete';
      case WdiReportStatus.submitted:
        return 'Submitted';
      case WdiReportStatus.accepted:
        return 'Accepted';
      case WdiReportStatus.rejected:
        return 'Rejected';
    }
  }

  static WdiReportStatus fromString(String? value) {
    if (value == null) return WdiReportStatus.draft;
    return WdiReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WdiReportStatus.draft,
    );
  }
}

class WdiReport {
  final String id;
  final String companyId;
  final String? jobId;
  final String? propertyId;
  final WdiReportType reportType;
  final String? reportNumber;
  final String? propertyAddress;
  final String? propertyCity;
  final String? propertyState;
  final String? propertyZip;
  final String? inspectorName;
  final String? inspectorLicense;
  final String? inspectorCompany;
  final DateTime? inspectionDate;
  final List<Map<String, dynamic>> findings;
  final List<Map<String, dynamic>> diagrams;
  final bool infestationFound;
  final bool damageFound;
  final bool treatmentRecommended;
  final bool liveInsectsFound;
  final bool deadInsectsFound;
  final bool damageVisible;
  final bool frassFound;
  final bool shelterTubesFound;
  final bool exitHolesFound;
  final bool moistureDamage;
  final List<String> insectsIdentified;
  final String? recommendations;
  final String? treatmentPlan;
  final double? estimatedCost;
  final String? reportPdfUrl;
  final WdiReportStatus reportStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WdiReport({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.propertyId,
    this.reportType = WdiReportType.npma33,
    this.reportNumber,
    this.propertyAddress,
    this.propertyCity,
    this.propertyState,
    this.propertyZip,
    this.inspectorName,
    this.inspectorLicense,
    this.inspectorCompany,
    this.inspectionDate,
    this.findings = const [],
    this.diagrams = const [],
    this.infestationFound = false,
    this.damageFound = false,
    this.treatmentRecommended = false,
    this.liveInsectsFound = false,
    this.deadInsectsFound = false,
    this.damageVisible = false,
    this.frassFound = false,
    this.shelterTubesFound = false,
    this.exitHolesFound = false,
    this.moistureDamage = false,
    this.insectsIdentified = const [],
    this.recommendations,
    this.treatmentPlan,
    this.estimatedCost,
    this.reportPdfUrl,
    this.reportStatus = WdiReportStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        if (propertyId != null) 'property_id': propertyId,
        'report_type': reportType.dbValue,
        if (reportNumber != null) 'report_number': reportNumber,
        if (propertyAddress != null) 'property_address': propertyAddress,
        if (propertyCity != null) 'property_city': propertyCity,
        if (propertyState != null) 'property_state': propertyState,
        if (propertyZip != null) 'property_zip': propertyZip,
        if (inspectorName != null) 'inspector_name': inspectorName,
        if (inspectorLicense != null) 'inspector_license': inspectorLicense,
        if (inspectorCompany != null) 'inspector_company': inspectorCompany,
        if (inspectionDate != null)
          'inspection_date':
              inspectionDate!.toIso8601String().split('T')[0],
        'findings': findings,
        'diagrams': diagrams,
        'infestation_found': infestationFound,
        'damage_found': damageFound,
        'treatment_recommended': treatmentRecommended,
        'live_insects_found': liveInsectsFound,
        'dead_insects_found': deadInsectsFound,
        'damage_visible': damageVisible,
        'frass_found': frassFound,
        'shelter_tubes_found': shelterTubesFound,
        'exit_holes_found': exitHolesFound,
        'moisture_damage': moistureDamage,
        'insects_identified': insectsIdentified,
        if (recommendations != null) 'recommendations': recommendations,
        if (treatmentPlan != null) 'treatment_plan': treatmentPlan,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        'report_status': reportStatus.name,
      };

  factory WdiReport.fromJson(Map<String, dynamic> json) {
    return WdiReport(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      propertyId: json['property_id'] as String?,
      reportType: WdiReportType.fromString(json['report_type'] as String?),
      reportNumber: json['report_number'] as String?,
      propertyAddress: json['property_address'] as String?,
      propertyCity: json['property_city'] as String?,
      propertyState: json['property_state'] as String?,
      propertyZip: json['property_zip'] as String?,
      inspectorName: json['inspector_name'] as String?,
      inspectorLicense: json['inspector_license'] as String?,
      inspectorCompany: json['inspector_company'] as String?,
      inspectionDate: _parseDate(json['inspection_date']),
      findings: _parseRaw(json['findings']),
      diagrams: _parseRaw(json['diagrams']),
      infestationFound: json['infestation_found'] as bool? ?? false,
      damageFound: json['damage_found'] as bool? ?? false,
      treatmentRecommended: json['treatment_recommended'] as bool? ?? false,
      liveInsectsFound: json['live_insects_found'] as bool? ?? false,
      deadInsectsFound: json['dead_insects_found'] as bool? ?? false,
      damageVisible: json['damage_visible'] as bool? ?? false,
      frassFound: json['frass_found'] as bool? ?? false,
      shelterTubesFound: json['shelter_tubes_found'] as bool? ?? false,
      exitHolesFound: json['exit_holes_found'] as bool? ?? false,
      moistureDamage: json['moisture_damage'] as bool? ?? false,
      insectsIdentified: (json['insects_identified'] as List?)
              ?.whereType<String>()
              .toList() ??
          [],
      recommendations: json['recommendations'] as String?,
      treatmentPlan: json['treatment_plan'] as String?,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      reportPdfUrl: json['report_pdf_url'] as String?,
      reportStatus:
          WdiReportStatus.fromString(json['report_status'] as String?),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  // Computed
  String get fullAddress =>
      [propertyAddress, propertyCity, propertyState, propertyZip]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');

  bool get hasEvidence =>
      liveInsectsFound ||
      deadInsectsFound ||
      damageVisible ||
      frassFound ||
      shelterTubesFound ||
      exitHolesFound;

  int get evidenceCount => [
        liveInsectsFound,
        deadInsectsFound,
        damageVisible,
        frassFound,
        shelterTubesFound,
        exitHolesFound,
        moistureDamage,
      ].where((b) => b).length;
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
