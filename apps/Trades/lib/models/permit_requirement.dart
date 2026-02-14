// ZAFTO Permit Requirement Model
// L1: What permits are needed per jurisdiction/work type.

import 'package:equatable/equatable.dart';

class PermitRequirement extends Equatable {
  final String id;
  final String jurisdictionId;
  final String workType;
  final String? tradeType;
  final bool permitRequired;
  final String permitType;
  final double? estimatedFee;
  final List<String> inspectionsRequired;
  final List<String> typicalDocuments;
  final String? exemptions;
  final bool verified;
  final DateTime createdAt;

  const PermitRequirement({
    required this.id,
    required this.jurisdictionId,
    required this.workType,
    this.tradeType,
    required this.permitRequired,
    required this.permitType,
    this.estimatedFee,
    required this.inspectionsRequired,
    required this.typicalDocuments,
    this.exemptions,
    required this.verified,
    required this.createdAt,
  });

  factory PermitRequirement.fromJson(Map<String, dynamic> json) {
    return PermitRequirement(
      id: json['id'] as String,
      jurisdictionId: json['jurisdiction_id'] as String,
      workType: json['work_type'] as String,
      tradeType: json['trade_type'] as String?,
      permitRequired: json['permit_required'] as bool? ?? true,
      permitType: json['permit_type'] as String,
      estimatedFee: (json['estimated_fee'] as num?)?.toDouble(),
      inspectionsRequired: List<String>.from(json['inspections_required'] as List? ?? []),
      typicalDocuments: List<String>.from(json['typical_documents'] as List? ?? []),
      exemptions: json['exemptions'] as String?,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jurisdiction_id': jurisdictionId,
    'work_type': workType,
    'trade_type': tradeType,
    'permit_required': permitRequired,
    'permit_type': permitType,
    'estimated_fee': estimatedFee,
    'inspections_required': inspectionsRequired,
    'typical_documents': typicalDocuments,
    'exemptions': exemptions,
    'verified': verified,
  };

  PermitRequirement copyWith({
    String? id,
    String? jurisdictionId,
    String? workType,
    String? tradeType,
    bool? permitRequired,
    String? permitType,
    double? estimatedFee,
    List<String>? inspectionsRequired,
    List<String>? typicalDocuments,
    String? exemptions,
    bool? verified,
    DateTime? createdAt,
  }) {
    return PermitRequirement(
      id: id ?? this.id,
      jurisdictionId: jurisdictionId ?? this.jurisdictionId,
      workType: workType ?? this.workType,
      tradeType: tradeType ?? this.tradeType,
      permitRequired: permitRequired ?? this.permitRequired,
      permitType: permitType ?? this.permitType,
      estimatedFee: estimatedFee ?? this.estimatedFee,
      inspectionsRequired: inspectionsRequired ?? this.inspectionsRequired,
      typicalDocuments: typicalDocuments ?? this.typicalDocuments,
      exemptions: exemptions ?? this.exemptions,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, jurisdictionId, workType, permitType];
}
