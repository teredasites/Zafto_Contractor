// ZAFTO Data Privacy Models
// Created: DEPTH33 — Consent management, data export/deletion requests,
// privacy policy versions. GDPR/CCPA compliant.
//
// Tables: user_consent, data_export_requests, data_deletion_requests,
//         privacy_policy_versions

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum ConsentType {
  pricingDataSharing,
  aiTraining,
  analytics,
  marketingEmails,
  pushNotifications;

  String toJson() {
    switch (this) {
      case ConsentType.pricingDataSharing:
        return 'pricing_data_sharing';
      case ConsentType.aiTraining:
        return 'ai_training';
      case ConsentType.analytics:
        return 'analytics';
      case ConsentType.marketingEmails:
        return 'marketing_emails';
      case ConsentType.pushNotifications:
        return 'push_notifications';
    }
  }

  static ConsentType fromJson(String value) {
    switch (value) {
      case 'pricing_data_sharing':
        return ConsentType.pricingDataSharing;
      case 'ai_training':
        return ConsentType.aiTraining;
      case 'analytics':
        return ConsentType.analytics;
      case 'marketing_emails':
        return ConsentType.marketingEmails;
      case 'push_notifications':
        return ConsentType.pushNotifications;
      default:
        return ConsentType.analytics;
    }
  }

  String get displayName {
    switch (this) {
      case ConsentType.pricingDataSharing:
        return 'Pricing Data Sharing';
      case ConsentType.aiTraining:
        return 'AI Training';
      case ConsentType.analytics:
        return 'Analytics';
      case ConsentType.marketingEmails:
        return 'Marketing Emails';
      case ConsentType.pushNotifications:
        return 'Push Notifications';
    }
  }
}

enum ExportStatus {
  pending,
  processing,
  completed,
  failed,
  expired;

  String toJson() => name;

  static ExportStatus fromJson(String value) {
    return ExportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportStatus.pending,
    );
  }
}

enum ExportFormat {
  json,
  csv;

  String toJson() => name;

  static ExportFormat fromJson(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportFormat.json,
    );
  }
}

enum DeletionStatus {
  pending,
  confirmed,
  processing,
  completed,
  cancelled;

  String toJson() => name;

  static DeletionStatus fromJson(String value) {
    return DeletionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeletionStatus.pending,
    );
  }
}

enum DeletionScope {
  userData,
  companyData;

  String toJson() {
    switch (this) {
      case DeletionScope.userData:
        return 'user_data';
      case DeletionScope.companyData:
        return 'company_data';
    }
  }

  static DeletionScope fromJson(String value) {
    switch (value) {
      case 'company_data':
        return DeletionScope.companyData;
      default:
        return DeletionScope.userData;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// USER CONSENT
// ════════════════════════════════════════════════════════════════

class UserConsent extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final ConsentType consentType;
  final bool granted;
  final String? grantedAt;
  final String? revokedAt;
  final String consentVersion;
  final String? ipAddress;
  final String? userAgent;
  final String createdAt;
  final String updatedAt;

  const UserConsent({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.consentType,
    required this.granted,
    this.grantedAt,
    this.revokedAt,
    required this.consentVersion,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserConsent.fromJson(Map<String, dynamic> json) {
    return UserConsent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      consentType: ConsentType.fromJson(json['consent_type'] as String),
      granted: json['granted'] as bool? ?? false,
      grantedAt: json['granted_at'] as String?,
      revokedAt: json['revoked_at'] as String?,
      consentVersion: json['consent_version'] as String? ?? '1.0',
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'company_id': companyId,
        'consent_type': consentType.toJson(),
        'granted': granted,
        'granted_at': grantedAt,
        'revoked_at': revokedAt,
        'consent_version': consentVersion,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      };

  UserConsent copyWith({
    bool? granted,
    String? grantedAt,
    String? revokedAt,
    String? consentVersion,
  }) {
    return UserConsent(
      id: id,
      userId: userId,
      companyId: companyId,
      consentType: consentType,
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      consentVersion: consentVersion ?? this.consentVersion,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, consentType, granted, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// DATA EXPORT REQUEST
// ════════════════════════════════════════════════════════════════

class DataExportRequest extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final ExportStatus status;
  final ExportFormat exportFormat;
  final String? downloadUrl;
  final String? downloadExpires;
  final String requestedAt;
  final String? completedAt;
  final int? fileSizeBytes;
  final String? errorMessage;
  final String createdAt;

  const DataExportRequest({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.status,
    required this.exportFormat,
    this.downloadUrl,
    this.downloadExpires,
    required this.requestedAt,
    this.completedAt,
    this.fileSizeBytes,
    this.errorMessage,
    required this.createdAt,
  });

  factory DataExportRequest.fromJson(Map<String, dynamic> json) {
    return DataExportRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      status: ExportStatus.fromJson(json['status'] as String),
      exportFormat: ExportFormat.fromJson(json['export_format'] as String),
      downloadUrl: json['download_url'] as String?,
      downloadExpires: json['download_expires'] as String?,
      requestedAt: json['requested_at'] as String,
      completedAt: json['completed_at'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'company_id': companyId,
        'export_format': exportFormat.toJson(),
      };

  /// Whether the download link is still valid
  bool get isDownloadAvailable =>
      status == ExportStatus.completed &&
      downloadUrl != null &&
      downloadExpires != null &&
      DateTime.tryParse(downloadExpires!)?.isAfter(DateTime.now()) == true;

  @override
  List<Object?> get props => [id, userId, status, createdAt];
}

// ════════════════════════════════════════════════════════════════
// DATA DELETION REQUEST
// ════════════════════════════════════════════════════════════════

class DataDeletionRequest extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final DeletionStatus status;
  final String? confirmationCode;
  final String? confirmedAt;
  final String? gracePeriodEnds;
  final String? processedAt;
  final DeletionScope scope;
  final String? reason;
  final String createdAt;

  const DataDeletionRequest({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.status,
    this.confirmationCode,
    this.confirmedAt,
    this.gracePeriodEnds,
    this.processedAt,
    required this.scope,
    this.reason,
    required this.createdAt,
  });

  factory DataDeletionRequest.fromJson(Map<String, dynamic> json) {
    return DataDeletionRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      status: DeletionStatus.fromJson(json['status'] as String),
      confirmationCode: json['confirmation_code'] as String?,
      confirmedAt: json['confirmed_at'] as String?,
      gracePeriodEnds: json['grace_period_ends'] as String?,
      processedAt: json['processed_at'] as String?,
      scope: DeletionScope.fromJson(json['scope'] as String),
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'company_id': companyId,
        'scope': scope.toJson(),
        'reason': reason,
      };

  /// Whether the request is within the 30-day grace period
  bool get isInGracePeriod =>
      status == DeletionStatus.confirmed &&
      gracePeriodEnds != null &&
      DateTime.tryParse(gracePeriodEnds!)?.isAfter(DateTime.now()) == true;

  /// Whether the request can be cancelled
  bool get canCancel =>
      status == DeletionStatus.pending || isInGracePeriod;

  @override
  List<Object?> get props => [id, userId, status, scope, createdAt];
}

// ════════════════════════════════════════════════════════════════
// PRIVACY POLICY VERSION
// ════════════════════════════════════════════════════════════════

class PrivacyPolicyVersion extends Equatable {
  final String id;
  final String version;
  final String title;
  final String? summary;
  final String effectiveAt;
  final String? contentUrl;
  final List<String> changes;
  final String createdAt;

  const PrivacyPolicyVersion({
    required this.id,
    required this.version,
    required this.title,
    this.summary,
    required this.effectiveAt,
    this.contentUrl,
    this.changes = const [],
    required this.createdAt,
  });

  factory PrivacyPolicyVersion.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyVersion(
      id: json['id'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      effectiveAt: json['effective_at'] as String,
      contentUrl: json['content_url'] as String?,
      changes: (json['changes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, version, effectiveAt];
}
