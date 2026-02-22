import 'package:equatable/equatable.dart';

/// Multi-party signing workflow.
class SigningWorkflow extends Equatable {
  final String id;
  final String companyId;
  final String renderId;
  final String name;
  final String signingMode; // sequential, parallel, any_one
  final String status; // draft, active, completed, voided, expired
  final DateTime? completedAt;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidedReason;
  final DateTime? expiresAt;
  final bool sendReminders;
  final int reminderIntervalHours;
  final int maxReminders;
  final List<Map<String, dynamic>> onCompleteNotify;
  final String? onCompleteWebhook;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SigningWorkflow({
    required this.id,
    required this.companyId,
    required this.renderId,
    required this.name,
    this.signingMode = 'sequential',
    this.status = 'draft',
    this.completedAt,
    this.voidedAt,
    this.voidedBy,
    this.voidedReason,
    this.expiresAt,
    this.sendReminders = true,
    this.reminderIntervalHours = 48,
    this.maxReminders = 3,
    this.onCompleteNotify = const [],
    this.onCompleteWebhook,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SigningWorkflow.fromJson(Map<String, dynamic> json) {
    return SigningWorkflow(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      renderId: json['render_id'] as String,
      name: json['name'] as String,
      signingMode: (json['signing_mode'] as String?) ?? 'sequential',
      status: (json['status'] as String?) ?? 'draft',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      voidedAt: json['voided_at'] != null
          ? DateTime.parse(json['voided_at'] as String)
          : null,
      voidedBy: json['voided_by'] as String?,
      voidedReason: json['voided_reason'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      sendReminders: (json['send_reminders'] as bool?) ?? true,
      reminderIntervalHours:
          (json['reminder_interval_hours'] as int?) ?? 48,
      maxReminders: (json['max_reminders'] as int?) ?? 3,
      onCompleteNotify: json['on_complete_notify'] != null
          ? List<Map<String, dynamic>>.from(
              (json['on_complete_notify'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map)),
            )
          : [],
      onCompleteWebhook: json['on_complete_webhook'] as String?,
      createdBy: json['created_by'] as String,
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
        'render_id': renderId,
        'name': name,
        'signing_mode': signingMode,
        'status': status,
        'completed_at': completedAt?.toIso8601String(),
        'voided_at': voidedAt?.toIso8601String(),
        'voided_by': voidedBy,
        'voided_reason': voidedReason,
        'expires_at': expiresAt?.toIso8601String(),
        'send_reminders': sendReminders,
        'reminder_interval_hours': reminderIntervalHours,
        'max_reminders': maxReminders,
        'on_complete_notify': onCompleteNotify,
        'on_complete_webhook': onCompleteWebhook,
        'created_by': createdBy,
      };

  SigningWorkflow copyWith({
    String? id,
    String? companyId,
    String? renderId,
    String? name,
    String? signingMode,
    String? status,
    DateTime? completedAt,
    DateTime? voidedAt,
    String? voidedBy,
    String? voidedReason,
    DateTime? expiresAt,
    bool? sendReminders,
    int? reminderIntervalHours,
    int? maxReminders,
    List<Map<String, dynamic>>? onCompleteNotify,
    String? onCompleteWebhook,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SigningWorkflow(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      renderId: renderId ?? this.renderId,
      name: name ?? this.name,
      signingMode: signingMode ?? this.signingMode,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      voidedAt: voidedAt ?? this.voidedAt,
      voidedBy: voidedBy ?? this.voidedBy,
      voidedReason: voidedReason ?? this.voidedReason,
      expiresAt: expiresAt ?? this.expiresAt,
      sendReminders: sendReminders ?? this.sendReminders,
      reminderIntervalHours:
          reminderIntervalHours ?? this.reminderIntervalHours,
      maxReminders: maxReminders ?? this.maxReminders,
      onCompleteNotify: onCompleteNotify ?? this.onCompleteNotify,
      onCompleteWebhook: onCompleteWebhook ?? this.onCompleteWebhook,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isVoided => status == 'voided';
  bool get isExpired =>
      status == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  @override
  List<Object?> get props => [
        id, companyId, renderId, name, signingMode, status,
        completedAt, voidedAt, expiresAt, sendReminders,
        createdBy, createdAt, updatedAt, deletedAt,
      ];
}

/// Audit event for signature actions.
class SignatureAuditEvent extends Equatable {
  final String id;
  final String companyId;
  final String? signatureRequestId;
  final String? signatureId;
  final String? renderId;
  final String eventType;
  final String actorType;
  final String? actorId;
  final String? actorName;
  final String? actorEmail;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceInfo;
  final Map<String, dynamic>? geolocation;
  final String? documentHash;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SignatureAuditEvent({
    required this.id,
    required this.companyId,
    this.signatureRequestId,
    this.signatureId,
    this.renderId,
    required this.eventType,
    this.actorType = 'user',
    this.actorId,
    this.actorName,
    this.actorEmail,
    this.ipAddress,
    this.userAgent,
    this.deviceInfo,
    this.geolocation,
    this.documentHash,
    this.metadata = const {},
    required this.createdAt,
  });

  factory SignatureAuditEvent.fromJson(Map<String, dynamic> json) {
    return SignatureAuditEvent(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      signatureRequestId: json['signature_request_id'] as String?,
      signatureId: json['signature_id'] as String?,
      renderId: json['render_id'] as String?,
      eventType: json['event_type'] as String,
      actorType: (json['actor_type'] as String?) ?? 'user',
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      actorEmail: json['actor_email'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      deviceInfo: json['device_info'] as String?,
      geolocation: json['geolocation'] != null
          ? Map<String, dynamic>.from(json['geolocation'] as Map)
          : null,
      documentHash: json['document_hash'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'signature_request_id': signatureRequestId,
        'signature_id': signatureId,
        'render_id': renderId,
        'event_type': eventType,
        'actor_type': actorType,
        'actor_id': actorId,
        'actor_name': actorName,
        'actor_email': actorEmail,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'device_info': deviceInfo,
        'geolocation': geolocation,
        'document_hash': documentHash,
        'metadata': metadata,
      };

  @override
  List<Object?> get props => [
        id, companyId, signatureRequestId, signatureId,
        renderId, eventType, actorType, actorId, createdAt,
      ];
}
