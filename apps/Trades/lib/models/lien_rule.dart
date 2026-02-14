// ZAFTO Lien Rule Model
// L5: State-specific mechanic's lien rules from public statutes.

import 'package:equatable/equatable.dart';

class LienRule extends Equatable {
  final String id;
  final String stateCode;
  final String stateName;
  final bool preliminaryNoticeRequired;
  final int? preliminaryNoticeDeadlineDays;
  final String? preliminaryNoticeFrom;
  final List<String> preliminaryNoticeRecipients;
  final int lienFilingDeadlineDays;
  final String lienFilingFrom;
  final int? lienEnforcementDeadlineDays;
  final String? lienEnforcementFrom;
  final bool noticeOfIntentRequired;
  final int? noticeOfIntentDeadlineDays;
  final bool notarizationRequired;
  final List<Map<String, dynamic>> specialRules;
  final bool residentialDifferent;
  final Map<String, dynamic>? residentialRules;
  final String? statutoryReference;
  final String? notes;
  final DateTime createdAt;

  const LienRule({
    required this.id,
    required this.stateCode,
    required this.stateName,
    required this.preliminaryNoticeRequired,
    this.preliminaryNoticeDeadlineDays,
    this.preliminaryNoticeFrom,
    required this.preliminaryNoticeRecipients,
    required this.lienFilingDeadlineDays,
    required this.lienFilingFrom,
    this.lienEnforcementDeadlineDays,
    this.lienEnforcementFrom,
    required this.noticeOfIntentRequired,
    this.noticeOfIntentDeadlineDays,
    required this.notarizationRequired,
    required this.specialRules,
    required this.residentialDifferent,
    this.residentialRules,
    this.statutoryReference,
    this.notes,
    required this.createdAt,
  });

  factory LienRule.fromJson(Map<String, dynamic> json) {
    return LienRule(
      id: json['id'] as String,
      stateCode: json['state_code'] as String,
      stateName: json['state_name'] as String,
      preliminaryNoticeRequired: json['preliminary_notice_required'] as bool? ?? false,
      preliminaryNoticeDeadlineDays: json['preliminary_notice_deadline_days'] as int?,
      preliminaryNoticeFrom: json['preliminary_notice_from'] as String?,
      preliminaryNoticeRecipients: List<String>.from(json['preliminary_notice_recipients'] as List? ?? []),
      lienFilingDeadlineDays: json['lien_filing_deadline_days'] as int? ?? 90,
      lienFilingFrom: json['lien_filing_from'] as String? ?? 'last_work',
      lienEnforcementDeadlineDays: json['lien_enforcement_deadline_days'] as int?,
      lienEnforcementFrom: json['lien_enforcement_from'] as String?,
      noticeOfIntentRequired: json['notice_of_intent_required'] as bool? ?? false,
      noticeOfIntentDeadlineDays: json['notice_of_intent_deadline_days'] as int?,
      notarizationRequired: json['notarization_required'] as bool? ?? false,
      specialRules: (json['special_rules'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      residentialDifferent: json['residential_different'] as bool? ?? false,
      residentialRules: json['residential_rules'] as Map<String, dynamic>?,
      statutoryReference: json['statutory_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'state_code': stateCode,
    'state_name': stateName,
    'preliminary_notice_required': preliminaryNoticeRequired,
    'preliminary_notice_deadline_days': preliminaryNoticeDeadlineDays,
    'preliminary_notice_from': preliminaryNoticeFrom,
    'preliminary_notice_recipients': preliminaryNoticeRecipients,
    'lien_filing_deadline_days': lienFilingDeadlineDays,
    'lien_filing_from': lienFilingFrom,
    'lien_enforcement_deadline_days': lienEnforcementDeadlineDays,
    'lien_enforcement_from': lienEnforcementFrom,
    'notice_of_intent_required': noticeOfIntentRequired,
    'notice_of_intent_deadline_days': noticeOfIntentDeadlineDays,
    'notarization_required': notarizationRequired,
    'special_rules': specialRules,
    'residential_different': residentialDifferent,
    'residential_rules': residentialRules,
    'statutory_reference': statutoryReference,
    'notes': notes,
  };

  LienRule copyWith({
    String? id,
    String? stateCode,
    String? stateName,
    bool? preliminaryNoticeRequired,
    int? preliminaryNoticeDeadlineDays,
    String? preliminaryNoticeFrom,
    List<String>? preliminaryNoticeRecipients,
    int? lienFilingDeadlineDays,
    String? lienFilingFrom,
    int? lienEnforcementDeadlineDays,
    String? lienEnforcementFrom,
    bool? noticeOfIntentRequired,
    int? noticeOfIntentDeadlineDays,
    bool? notarizationRequired,
    List<Map<String, dynamic>>? specialRules,
    bool? residentialDifferent,
    Map<String, dynamic>? residentialRules,
    String? statutoryReference,
    String? notes,
    DateTime? createdAt,
  }) {
    return LienRule(
      id: id ?? this.id,
      stateCode: stateCode ?? this.stateCode,
      stateName: stateName ?? this.stateName,
      preliminaryNoticeRequired: preliminaryNoticeRequired ?? this.preliminaryNoticeRequired,
      preliminaryNoticeDeadlineDays: preliminaryNoticeDeadlineDays ?? this.preliminaryNoticeDeadlineDays,
      preliminaryNoticeFrom: preliminaryNoticeFrom ?? this.preliminaryNoticeFrom,
      preliminaryNoticeRecipients: preliminaryNoticeRecipients ?? this.preliminaryNoticeRecipients,
      lienFilingDeadlineDays: lienFilingDeadlineDays ?? this.lienFilingDeadlineDays,
      lienFilingFrom: lienFilingFrom ?? this.lienFilingFrom,
      lienEnforcementDeadlineDays: lienEnforcementDeadlineDays ?? this.lienEnforcementDeadlineDays,
      lienEnforcementFrom: lienEnforcementFrom ?? this.lienEnforcementFrom,
      noticeOfIntentRequired: noticeOfIntentRequired ?? this.noticeOfIntentRequired,
      noticeOfIntentDeadlineDays: noticeOfIntentDeadlineDays ?? this.noticeOfIntentDeadlineDays,
      notarizationRequired: notarizationRequired ?? this.notarizationRequired,
      specialRules: specialRules ?? this.specialRules,
      residentialDifferent: residentialDifferent ?? this.residentialDifferent,
      residentialRules: residentialRules ?? this.residentialRules,
      statutoryReference: statutoryReference ?? this.statutoryReference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, stateCode];
}
