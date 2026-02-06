// ZAFTO Compliance Record Model — Supabase Backend
// Maps to `compliance_records` table in Supabase PostgreSQL.
// Stores safety briefings, incident reports, LOTO logs, confined space entries,
// dead man switch events, and inspections.

enum ComplianceRecordType {
  safetyBriefing,
  incidentReport,
  loto,
  confinedSpace,
  deadManSwitch,
  inspection;

  String get dbValue {
    switch (this) {
      case ComplianceRecordType.safetyBriefing:
        return 'safety_briefing';
      case ComplianceRecordType.incidentReport:
        return 'incident_report';
      case ComplianceRecordType.loto:
        return 'loto';
      case ComplianceRecordType.confinedSpace:
        return 'confined_space';
      case ComplianceRecordType.deadManSwitch:
        return 'dead_man_switch';
      case ComplianceRecordType.inspection:
        return 'inspection';
    }
  }

  String get label {
    switch (this) {
      case ComplianceRecordType.safetyBriefing:
        return 'Safety Briefing';
      case ComplianceRecordType.incidentReport:
        return 'Incident Report';
      case ComplianceRecordType.loto:
        return 'LOTO';
      case ComplianceRecordType.confinedSpace:
        return 'Confined Space';
      case ComplianceRecordType.deadManSwitch:
        return 'Dead Man Switch';
      case ComplianceRecordType.inspection:
        return 'Inspection';
    }
  }

  static ComplianceRecordType fromString(String? value) {
    if (value == null) return ComplianceRecordType.inspection;
    switch (value) {
      case 'safety_briefing':
        return ComplianceRecordType.safetyBriefing;
      case 'incident_report':
        return ComplianceRecordType.incidentReport;
      case 'loto':
        return ComplianceRecordType.loto;
      case 'confined_space':
        return ComplianceRecordType.confinedSpace;
      case 'dead_man_switch':
        return ComplianceRecordType.deadManSwitch;
      case 'inspection':
        return ComplianceRecordType.inspection;
      default:
        return ComplianceRecordType.inspection;
    }
  }
}

class ComplianceRecord {
  final String id;
  final String companyId;
  final String? jobId;
  final String createdByUserId;
  final ComplianceRecordType recordType;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> attachments;
  final List<String> crewMembers;
  final String status;
  final String? severity;
  final double? locationLatitude;
  final double? locationLongitude;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  const ComplianceRecord({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.createdByUserId = '',
    this.recordType = ComplianceRecordType.inspection,
    this.data = const {},
    this.attachments = const [],
    this.crewMembers = const [],
    this.status = 'active',
    this.severity,
    this.locationLatitude,
    this.locationLongitude,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'created_by_user_id': createdByUserId,
        'record_type': recordType.dbValue,
        'data': data,
        'attachments': attachments,
        'crew_members': crewMembers,
        'status': status,
        if (severity != null) 'severity': severity,
        if (locationLatitude != null) 'location_latitude': locationLatitude,
        if (locationLongitude != null) 'location_longitude': locationLongitude,
        if (startedAt != null)
          'started_at': startedAt!.toUtc().toIso8601String(),
        if (endedAt != null) 'ended_at': endedAt!.toUtc().toIso8601String(),
      };

  factory ComplianceRecord.fromJson(Map<String, dynamic> json) {
    return ComplianceRecord(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ??
          json['companyId'] as String? ??
          '',
      jobId: json['job_id'] as String? ?? json['jobId'] as String?,
      createdByUserId: json['created_by_user_id'] as String? ??
          json['createdByUserId'] as String? ??
          '',
      recordType: ComplianceRecordType.fromString(
          json['record_type'] as String? ?? json['recordType'] as String?),
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      attachments: _parseAttachments(json['attachments']),
      crewMembers: (json['crew_members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'active',
      severity: json['severity'] as String?,
      locationLatitude:
          (json['location_latitude'] as num?)?.toDouble() ??
              (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude:
          (json['location_longitude'] as num?)?.toDouble() ??
              (json['locationLongitude'] as num?)?.toDouble(),
      startedAt:
          _parseOptionalDate(json['started_at'] ?? json['startedAt']),
      endedAt: _parseOptionalDate(json['ended_at'] ?? json['endedAt']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  // Computed properties
  bool get hasLocation =>
      locationLatitude != null && locationLongitude != null;
  bool get isIncident =>
      recordType == ComplianceRecordType.incidentReport;
  bool get isSafetyCritical =>
      recordType == ComplianceRecordType.deadManSwitch ||
      (isIncident && (severity == 'serious' || severity == 'critical'));

  static List<Map<String, dynamic>> _parseAttachments(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    }
    return const [];
  }

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
