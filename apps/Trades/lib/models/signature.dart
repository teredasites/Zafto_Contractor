// ZAFTO Signature Model — Supabase Backend
// Maps to `signatures` table in Supabase PostgreSQL.
// Stores client/tech signatures for approvals, completions, change orders.

enum SignaturePurpose {
  jobCompletion,
  invoiceApproval,
  changeOrder,
  inspection,
  safetyBriefing,
  workApproval,
  liabilityWaiver;

  String get dbValue {
    switch (this) {
      case SignaturePurpose.jobCompletion:
        return 'job_completion';
      case SignaturePurpose.invoiceApproval:
        return 'invoice_approval';
      case SignaturePurpose.changeOrder:
        return 'change_order';
      case SignaturePurpose.inspection:
        return 'inspection';
      case SignaturePurpose.safetyBriefing:
        return 'safety_briefing';
      case SignaturePurpose.workApproval:
        return 'work_approval';
      case SignaturePurpose.liabilityWaiver:
        return 'liability_waiver';
    }
  }

  String get label {
    switch (this) {
      case SignaturePurpose.jobCompletion:
        return 'Job Completion';
      case SignaturePurpose.invoiceApproval:
        return 'Invoice Approval';
      case SignaturePurpose.changeOrder:
        return 'Change Order';
      case SignaturePurpose.inspection:
        return 'Inspection';
      case SignaturePurpose.safetyBriefing:
        return 'Safety Briefing';
      case SignaturePurpose.workApproval:
        return 'Work Approval';
      case SignaturePurpose.liabilityWaiver:
        return 'Liability Waiver';
    }
  }

  static SignaturePurpose fromString(String? value) {
    if (value == null) return SignaturePurpose.workApproval;
    switch (value) {
      case 'job_completion':
        return SignaturePurpose.jobCompletion;
      case 'invoice_approval':
        return SignaturePurpose.invoiceApproval;
      case 'change_order':
        return SignaturePurpose.changeOrder;
      case 'inspection':
        return SignaturePurpose.inspection;
      case 'safety_briefing':
        return SignaturePurpose.safetyBriefing;
      case 'work_approval':
        return SignaturePurpose.workApproval;
      case 'liability_waiver':
        return SignaturePurpose.liabilityWaiver;
      default:
        // Also handle enum .name values (camelCase)
        return SignaturePurpose.values.firstWhere(
          (p) => p.name == value,
          orElse: () => SignaturePurpose.workApproval,
        );
    }
  }
}

class Signature {
  final String id;
  final String companyId;
  final String? jobId;
  final String? invoiceId;
  final String signerName;
  final String? signerRole;
  final String? signatureData; // base64 PNG (kept for backward compat)
  final String? storagePath;
  final SignaturePurpose purpose;
  final String? notes;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;
  final DateTime createdAt;

  const Signature({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.invoiceId,
    this.signerName = '',
    this.signerRole,
    this.signatureData,
    this.storagePath,
    this.purpose = SignaturePurpose.workApproval,
    this.notes,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        if (invoiceId != null) 'invoice_id': invoiceId,
        'signer_name': signerName,
        if (signerRole != null) 'signer_role': signerRole,
        if (signatureData != null) 'signature_data': signatureData,
        if (storagePath != null) 'storage_path': storagePath,
        'purpose': purpose.dbValue,
        if (notes != null) 'notes': notes,
        if (locationLatitude != null) 'location_latitude': locationLatitude,
        if (locationLongitude != null) 'location_longitude': locationLongitude,
        if (locationAddress != null) 'location_address': locationAddress,
      };

  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      invoiceId: json['invoice_id'] as String?,
      signerName: json['signer_name'] as String? ?? '',
      signerRole: json['signer_role'] as String?,
      signatureData: json['signature_data'] as String?,
      storagePath: json['storage_path'] as String?,
      purpose: SignaturePurpose.fromString(json['purpose'] as String?),
      notes: json['notes'] as String?,
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      locationAddress: json['location_address'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  bool get hasLocation => locationLatitude != null && locationLongitude != null;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
