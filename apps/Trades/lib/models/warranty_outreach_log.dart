// ZAFTO Warranty Outreach Log Model — Supabase Backend
// Maps to `warranty_outreach_log` table. Tracks outreach to customers about warranties.

import 'package:equatable/equatable.dart';

enum OutreachType {
  warrantyExpiring,
  maintenanceReminder,
  recallNotice,
  upsellExtended,
  seasonalCheck;

  String get dbValue {
    switch (this) {
      case OutreachType.warrantyExpiring:
        return 'warranty_expiring';
      case OutreachType.maintenanceReminder:
        return 'maintenance_reminder';
      case OutreachType.recallNotice:
        return 'recall_notice';
      case OutreachType.upsellExtended:
        return 'upsell_extended';
      case OutreachType.seasonalCheck:
        return 'seasonal_check';
    }
  }

  static OutreachType fromDb(String? value) {
    switch (value) {
      case 'warranty_expiring':
        return OutreachType.warrantyExpiring;
      case 'maintenance_reminder':
        return OutreachType.maintenanceReminder;
      case 'recall_notice':
        return OutreachType.recallNotice;
      case 'upsell_extended':
        return OutreachType.upsellExtended;
      case 'seasonal_check':
        return OutreachType.seasonalCheck;
      default:
        return OutreachType.warrantyExpiring;
    }
  }

  String get label {
    switch (this) {
      case OutreachType.warrantyExpiring:
        return 'Warranty Expiring';
      case OutreachType.maintenanceReminder:
        return 'Maintenance Reminder';
      case OutreachType.recallNotice:
        return 'Recall Notice';
      case OutreachType.upsellExtended:
        return 'Extended Warranty Upsell';
      case OutreachType.seasonalCheck:
        return 'Seasonal Check';
    }
  }
}

enum ResponseStatus {
  pending,
  opened,
  clicked,
  booked,
  declined,
  noResponse;

  String get dbValue {
    switch (this) {
      case ResponseStatus.pending:
        return 'pending';
      case ResponseStatus.opened:
        return 'opened';
      case ResponseStatus.clicked:
        return 'clicked';
      case ResponseStatus.booked:
        return 'booked';
      case ResponseStatus.declined:
        return 'declined';
      case ResponseStatus.noResponse:
        return 'no_response';
    }
  }

  static ResponseStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return ResponseStatus.pending;
      case 'opened':
        return ResponseStatus.opened;
      case 'clicked':
        return ResponseStatus.clicked;
      case 'booked':
        return ResponseStatus.booked;
      case 'declined':
        return ResponseStatus.declined;
      case 'no_response':
        return ResponseStatus.noResponse;
      default:
        return ResponseStatus.pending;
    }
  }
}

class WarrantyOutreachLog extends Equatable {
  final String id;
  final String companyId;
  final String equipmentId;
  final String? customerId;
  final OutreachType outreachType;
  final String? outreachTrigger;
  final String? messageContent;
  final DateTime? sentAt;
  final ResponseStatus? responseStatus;
  final String? resultingJobId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WarrantyOutreachLog({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    this.customerId,
    required this.outreachType,
    this.outreachTrigger,
    this.messageContent,
    this.sentAt,
    this.responseStatus,
    this.resultingJobId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarrantyOutreachLog.fromJson(Map<String, dynamic> json) {
    return WarrantyOutreachLog(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      equipmentId: json['equipment_id'] as String,
      customerId: json['customer_id'] as String?,
      outreachType: OutreachType.fromDb(json['outreach_type'] as String?),
      outreachTrigger: json['outreach_trigger'] as String?,
      messageContent: json['message_content'] as String?,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      responseStatus: json['response_status'] != null ? ResponseStatus.fromDb(json['response_status'] as String?) : null,
      resultingJobId: json['resulting_job_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'equipment_id': equipmentId,
      'customer_id': customerId,
      'outreach_type': outreachType.dbValue,
      'outreach_trigger': outreachTrigger,
      'message_content': messageContent,
      'sent_at': sentAt?.toIso8601String(),
      'response_status': responseStatus?.dbValue,
      'resulting_job_id': resultingJobId,
      'created_by': createdBy,
    };
  }

  WarrantyOutreachLog copyWith({
    String? id,
    String? companyId,
    String? equipmentId,
    String? customerId,
    OutreachType? outreachType,
    String? outreachTrigger,
    String? messageContent,
    DateTime? sentAt,
    ResponseStatus? responseStatus,
    String? resultingJobId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarrantyOutreachLog(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      equipmentId: equipmentId ?? this.equipmentId,
      customerId: customerId ?? this.customerId,
      outreachType: outreachType ?? this.outreachType,
      outreachTrigger: outreachTrigger ?? this.outreachTrigger,
      messageContent: messageContent ?? this.messageContent,
      sentAt: sentAt ?? this.sentAt,
      responseStatus: responseStatus ?? this.responseStatus,
      resultingJobId: resultingJobId ?? this.resultingJobId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, equipmentId, outreachType, responseStatus];
}
