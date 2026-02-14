// ZAFTO Autopsy Insight Model
// J1: Aggregated intelligence from job cost autopsies.

import 'package:equatable/equatable.dart';

enum InsightType {
  profitabilityByJobType,
  profitabilityByTech,
  profitabilityBySeason,
  varianceTrend,
  callbackRate,
  topPerformers,
  underperformingTypes,
  materialOverrunPattern,
  laborOverrunPattern;

  String get dbValue {
    switch (this) {
      case InsightType.profitabilityByJobType: return 'profitability_by_job_type';
      case InsightType.profitabilityByTech: return 'profitability_by_tech';
      case InsightType.profitabilityBySeason: return 'profitability_by_season';
      case InsightType.varianceTrend: return 'variance_trend';
      case InsightType.callbackRate: return 'callback_rate';
      case InsightType.topPerformers: return 'top_performers';
      case InsightType.underperformingTypes: return 'underperforming_types';
      case InsightType.materialOverrunPattern: return 'material_overrun_pattern';
      case InsightType.laborOverrunPattern: return 'labor_overrun_pattern';
    }
  }

  static InsightType fromDb(String? value) {
    switch (value) {
      case 'profitability_by_job_type': return InsightType.profitabilityByJobType;
      case 'profitability_by_tech': return InsightType.profitabilityByTech;
      case 'profitability_by_season': return InsightType.profitabilityBySeason;
      case 'variance_trend': return InsightType.varianceTrend;
      case 'callback_rate': return InsightType.callbackRate;
      case 'top_performers': return InsightType.topPerformers;
      case 'underperforming_types': return InsightType.underperformingTypes;
      case 'material_overrun_pattern': return InsightType.materialOverrunPattern;
      case 'labor_overrun_pattern': return InsightType.laborOverrunPattern;
      default: return InsightType.profitabilityByJobType;
    }
  }

  String get label {
    switch (this) {
      case InsightType.profitabilityByJobType: return 'Profitability by Job Type';
      case InsightType.profitabilityByTech: return 'Profitability by Tech';
      case InsightType.profitabilityBySeason: return 'Profitability by Season';
      case InsightType.varianceTrend: return 'Variance Trend';
      case InsightType.callbackRate: return 'Callback Rate';
      case InsightType.topPerformers: return 'Top Performers';
      case InsightType.underperformingTypes: return 'Underperforming Types';
      case InsightType.materialOverrunPattern: return 'Material Overrun';
      case InsightType.laborOverrunPattern: return 'Labor Overrun';
    }
  }
}

class AutopsyInsight extends Equatable {
  final String id;
  final String companyId;
  final InsightType insightType;
  final String insightKey;
  final Map<String, dynamic> insightData;
  final int sampleSize;
  final double confidenceScore;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime createdAt;

  const AutopsyInsight({
    required this.id,
    required this.companyId,
    required this.insightType,
    required this.insightKey,
    required this.insightData,
    required this.sampleSize,
    required this.confidenceScore,
    this.periodStart,
    this.periodEnd,
    required this.createdAt,
  });

  factory AutopsyInsight.fromJson(Map<String, dynamic> json) {
    return AutopsyInsight(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      insightType: InsightType.fromDb(json['insight_type'] as String?),
      insightKey: json['insight_key'] as String,
      insightData: Map<String, dynamic>.from(json['insight_data'] as Map? ?? {}),
      sampleSize: json['sample_size'] as int? ?? 0,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start'] as String) : null,
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'insight_type': insightType.dbValue,
    'insight_key': insightKey,
    'insight_data': insightData,
    'sample_size': sampleSize,
    'confidence_score': confidenceScore,
    'period_start': periodStart?.toIso8601String().split('T').first,
    'period_end': periodEnd?.toIso8601String().split('T').first,
  };

  AutopsyInsight copyWith({
    String? id,
    String? companyId,
    InsightType? insightType,
    String? insightKey,
    Map<String, dynamic>? insightData,
    int? sampleSize,
    double? confidenceScore,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? createdAt,
  }) {
    return AutopsyInsight(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      insightType: insightType ?? this.insightType,
      insightKey: insightKey ?? this.insightKey,
      insightData: insightData ?? this.insightData,
      sampleSize: sampleSize ?? this.sampleSize,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isHighConfidence => confidenceScore >= 0.7;

  @override
  List<Object?> get props => [id, insightType, insightKey];
}
