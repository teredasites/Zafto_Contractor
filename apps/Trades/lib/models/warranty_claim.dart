// ZAFTO Warranty Claim Model — Supabase Backend
// Maps to `warranty_claims` table. Tracks warranty claims against manufacturers.

import 'package:equatable/equatable.dart';

enum ClaimStatus {
  submitted,
  underReview,
  approved,
  denied,
  resolved,
  closed;

  String get dbValue {
    switch (this) {
      case ClaimStatus.submitted:
        return 'submitted';
      case ClaimStatus.underReview:
        return 'under_review';
      case ClaimStatus.approved:
        return 'approved';
      case ClaimStatus.denied:
        return 'denied';
      case ClaimStatus.resolved:
        return 'resolved';
      case ClaimStatus.closed:
        return 'closed';
    }
  }

  static ClaimStatus fromDb(String? value) {
    switch (value) {
      case 'submitted':
        return ClaimStatus.submitted;
      case 'under_review':
        return ClaimStatus.underReview;
      case 'approved':
        return ClaimStatus.approved;
      case 'denied':
        return ClaimStatus.denied;
      case 'resolved':
        return ClaimStatus.resolved;
      case 'closed':
        return ClaimStatus.closed;
      default:
        return ClaimStatus.submitted;
    }
  }

  String get label {
    switch (this) {
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.denied:
        return 'Denied';
      case ClaimStatus.resolved:
        return 'Resolved';
      case ClaimStatus.closed:
        return 'Closed';
    }
  }
}

class WarrantyClaim extends Equatable {
  final String id;
  final String companyId;
  final String equipmentId;
  final String? jobId;
  final String? customerId;
  final DateTime claimDate;
  final String claimReason;
  final ClaimStatus claimStatus;
  final String? manufacturerClaimNumber;
  final String? resolutionNotes;
  final String? replacementEquipmentId;
  final double? amountClaimed;
  final double? amountApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WarrantyClaim({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    this.jobId,
    this.customerId,
    required this.claimDate,
    required this.claimReason,
    required this.claimStatus,
    this.manufacturerClaimNumber,
    this.resolutionNotes,
    this.replacementEquipmentId,
    this.amountClaimed,
    this.amountApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) {
    return WarrantyClaim(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      equipmentId: json['equipment_id'] as String,
      jobId: json['job_id'] as String?,
      customerId: json['customer_id'] as String?,
      claimDate: DateTime.parse(json['claim_date'] as String),
      claimReason: json['claim_reason'] as String,
      claimStatus: ClaimStatus.fromDb(json['claim_status'] as String?),
      manufacturerClaimNumber: json['manufacturer_claim_number'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      replacementEquipmentId: json['replacement_equipment_id'] as String?,
      amountClaimed: json['amount_claimed'] != null ? (json['amount_claimed'] as num).toDouble() : null,
      amountApproved: json['amount_approved'] != null ? (json['amount_approved'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'equipment_id': equipmentId,
      'job_id': jobId,
      'customer_id': customerId,
      'claim_date': claimDate.toIso8601String().split('T').first,
      'claim_reason': claimReason,
      'claim_status': claimStatus.dbValue,
      'manufacturer_claim_number': manufacturerClaimNumber,
      'resolution_notes': resolutionNotes,
      'replacement_equipment_id': replacementEquipmentId,
      'amount_claimed': amountClaimed,
      'amount_approved': amountApproved,
    };
  }

  WarrantyClaim copyWith({
    String? id,
    String? companyId,
    String? equipmentId,
    String? jobId,
    String? customerId,
    DateTime? claimDate,
    String? claimReason,
    ClaimStatus? claimStatus,
    String? manufacturerClaimNumber,
    String? resolutionNotes,
    String? replacementEquipmentId,
    double? amountClaimed,
    double? amountApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarrantyClaim(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      equipmentId: equipmentId ?? this.equipmentId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      claimDate: claimDate ?? this.claimDate,
      claimReason: claimReason ?? this.claimReason,
      claimStatus: claimStatus ?? this.claimStatus,
      manufacturerClaimNumber: manufacturerClaimNumber ?? this.manufacturerClaimNumber,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      replacementEquipmentId: replacementEquipmentId ?? this.replacementEquipmentId,
      amountClaimed: amountClaimed ?? this.amountClaimed,
      amountApproved: amountApproved ?? this.amountApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOpen => claimStatus != ClaimStatus.closed && claimStatus != ClaimStatus.denied;
  bool get isApproved => claimStatus == ClaimStatus.approved || claimStatus == ClaimStatus.resolved;

  @override
  List<Object?> get props => [id, companyId, equipmentId, claimStatus];
}
