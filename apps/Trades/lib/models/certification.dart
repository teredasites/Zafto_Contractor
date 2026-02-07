// ZAFTO Certification Model — Supabase Backend
// Maps to `certifications` table. Employee license/cert tracking.

enum CertificationType {
  epa608,
  cpo,
  csia,
  isaArborist,
  rrpCertifiedRenovator,
  rrpFirm,
  nicet,
  osha10,
  osha30,
  firstAidCpr,
  cdl,
  stateContractorLicense,
  stateElectrical,
  statePlumbing,
  stateHvac,
  backflowTester,
  confinedSpace,
  fallProtection,
  forklift,
  hazmat,
  asbestosWorker,
  leadAbatement,
  iicrcWrt,
  iicrcAmrt,
  fireSprinkler,
  other;

  String get dbValue => name;

  String get label {
    switch (this) {
      case CertificationType.epa608:
        return 'EPA 608';
      case CertificationType.cpo:
        return 'Certified Pool Operator (CPO)';
      case CertificationType.csia:
        return 'CSIA Chimney Sweep';
      case CertificationType.isaArborist:
        return 'ISA Certified Arborist';
      case CertificationType.rrpCertifiedRenovator:
        return 'RRP Certified Renovator';
      case CertificationType.rrpFirm:
        return 'RRP Firm Certification';
      case CertificationType.nicet:
        return 'NICET';
      case CertificationType.osha10:
        return 'OSHA 10';
      case CertificationType.osha30:
        return 'OSHA 30';
      case CertificationType.firstAidCpr:
        return 'First Aid / CPR';
      case CertificationType.cdl:
        return 'CDL';
      case CertificationType.stateContractorLicense:
        return 'State Contractor License';
      case CertificationType.stateElectrical:
        return 'State Electrical License';
      case CertificationType.statePlumbing:
        return 'State Plumbing License';
      case CertificationType.stateHvac:
        return 'State HVAC License';
      case CertificationType.backflowTester:
        return 'Backflow Tester';
      case CertificationType.confinedSpace:
        return 'Confined Space';
      case CertificationType.fallProtection:
        return 'Fall Protection';
      case CertificationType.forklift:
        return 'Forklift Operator';
      case CertificationType.hazmat:
        return 'HAZMAT';
      case CertificationType.asbestosWorker:
        return 'Asbestos Worker';
      case CertificationType.leadAbatement:
        return 'Lead Abatement';
      case CertificationType.iicrcWrt:
        return 'IICRC WRT';
      case CertificationType.iicrcAmrt:
        return 'IICRC AMRT';
      case CertificationType.fireSprinkler:
        return 'Fire Sprinkler';
      case CertificationType.other:
        return 'Other';
    }
  }

  static CertificationType fromString(String? value) {
    if (value == null) return CertificationType.other;
    for (final type in CertificationType.values) {
      if (type.dbValue == value) return type;
    }
    return CertificationType.other;
  }
}

enum CertificationStatus {
  active,
  expired,
  pendingRenewal,
  revoked;

  String get dbValue {
    switch (this) {
      case CertificationStatus.active:
        return 'active';
      case CertificationStatus.expired:
        return 'expired';
      case CertificationStatus.pendingRenewal:
        return 'pending_renewal';
      case CertificationStatus.revoked:
        return 'revoked';
    }
  }

  String get label {
    switch (this) {
      case CertificationStatus.active:
        return 'Active';
      case CertificationStatus.expired:
        return 'Expired';
      case CertificationStatus.pendingRenewal:
        return 'Pending Renewal';
      case CertificationStatus.revoked:
        return 'Revoked';
    }
  }

  static CertificationStatus fromString(String? value) {
    if (value == null) return CertificationStatus.active;
    switch (value) {
      case 'active':
        return CertificationStatus.active;
      case 'expired':
        return CertificationStatus.expired;
      case 'pending_renewal':
        return CertificationStatus.pendingRenewal;
      case 'revoked':
        return CertificationStatus.revoked;
      default:
        return CertificationStatus.active;
    }
  }
}

class Certification {
  final String id;
  final String companyId;
  final String userId;
  final String certificationTypeValue;
  final String certificationName;
  final String? issuingAuthority;
  final String? certificationNumber;
  final DateTime? issuedDate;
  final DateTime? expirationDate;
  final bool renewalRequired;
  final int renewalReminderDays;
  final String? documentUrl;
  final CertificationStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Certification({
    this.id = '',
    this.companyId = '',
    this.userId = '',
    this.certificationTypeValue = 'other',
    required this.certificationName,
    this.issuingAuthority,
    this.certificationNumber,
    this.issuedDate,
    this.expirationDate,
    this.renewalRequired = true,
    this.renewalReminderDays = 30,
    this.documentUrl,
    this.status = CertificationStatus.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  CertificationType get certificationType =>
      CertificationType.fromString(certificationTypeValue);

  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntil = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntil > 0 && daysUntil <= renewalReminderDays;
  }

  int? get daysUntilExpiry {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'user_id': userId,
        'certification_type': certificationTypeValue,
        'certification_name': certificationName,
        if (issuingAuthority != null) 'issuing_authority': issuingAuthority,
        if (certificationNumber != null)
          'certification_number': certificationNumber,
        if (issuedDate != null)
          'issued_date': issuedDate!.toIso8601String().split('T').first,
        if (expirationDate != null)
          'expiration_date':
              expirationDate!.toIso8601String().split('T').first,
        'renewal_required': renewalRequired,
        'renewal_reminder_days': renewalReminderDays,
        if (documentUrl != null) 'document_url': documentUrl,
        'status': status.dbValue,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'certification_type': certificationTypeValue,
        'certification_name': certificationName,
        'issuing_authority': issuingAuthority,
        'certification_number': certificationNumber,
        'issued_date': issuedDate?.toIso8601String().split('T').first,
        'expiration_date':
            expirationDate?.toIso8601String().split('T').first,
        'renewal_required': renewalRequired,
        'renewal_reminder_days': renewalReminderDays,
        'document_url': documentUrl,
        'status': status.dbValue,
        'notes': notes,
      };

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      certificationTypeValue:
          json['certification_type'] as String? ?? 'other',
      certificationName: json['certification_name'] as String? ?? '',
      issuingAuthority: json['issuing_authority'] as String?,
      certificationNumber: json['certification_number'] as String?,
      issuedDate: _parseDate(json['issued_date']),
      expirationDate: _parseDate(json['expiration_date']),
      renewalRequired: json['renewal_required'] as bool? ?? true,
      renewalReminderDays: json['renewal_reminder_days'] as int? ?? 30,
      documentUrl: json['document_url'] as String?,
      status: CertificationStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Certification copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? certificationTypeValue,
    String? certificationName,
    String? issuingAuthority,
    String? certificationNumber,
    DateTime? issuedDate,
    DateTime? expirationDate,
    bool? renewalRequired,
    int? renewalReminderDays,
    String? documentUrl,
    CertificationStatus? status,
    String? notes,
  }) {
    return Certification(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      certificationTypeValue:
          certificationTypeValue ?? this.certificationTypeValue,
      certificationName: certificationName ?? this.certificationName,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      issuedDate: issuedDate ?? this.issuedDate,
      expirationDate: expirationDate ?? this.expirationDate,
      renewalRequired: renewalRequired ?? this.renewalRequired,
      renewalReminderDays: renewalReminderDays ?? this.renewalReminderDays,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

// Configurable certification type from certification_types table.
// Replaces hardcoded CertificationType enum for dropdown/display.
class CertificationTypeConfig {
  final String id;
  final String? companyId;
  final String typeKey;
  final String displayName;
  final String category;
  final String? description;
  final String? regulationReference;
  final List<String> applicableTrades;
  final List<String> applicableRegions;
  final bool attachmentRequired;
  final int defaultRenewalDays;
  final bool defaultRenewalRequired;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  const CertificationTypeConfig({
    this.id = '',
    this.companyId,
    required this.typeKey,
    required this.displayName,
    this.category = 'trade',
    this.description,
    this.regulationReference,
    this.applicableTrades = const [],
    this.applicableRegions = const [],
    this.attachmentRequired = false,
    this.defaultRenewalDays = 30,
    this.defaultRenewalRequired = true,
    this.isSystem = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory CertificationTypeConfig.fromJson(Map<String, dynamic> json) {
    return CertificationTypeConfig(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      typeKey: json['type_key'] as String? ?? 'other',
      displayName: json['display_name'] as String? ?? '',
      category: json['category'] as String? ?? 'trade',
      description: json['description'] as String?,
      regulationReference: json['regulation_reference'] as String?,
      applicableTrades: (json['applicable_trades'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      applicableRegions: (json['applicable_regions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      attachmentRequired: json['attachment_required'] as bool? ?? false,
      defaultRenewalDays: json['default_renewal_days'] as int? ?? 30,
      defaultRenewalRequired:
          json['default_renewal_required'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
