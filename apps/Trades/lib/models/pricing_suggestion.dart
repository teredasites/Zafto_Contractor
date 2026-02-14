// ZAFTO Pricing Suggestion Model
// J3: Per-estimate suggested pricing with factor breakdown.

import 'package:equatable/equatable.dart';

class PricingFactor {
  final String ruleType;
  final String label;
  final double adjustmentPct;
  final double amount;

  const PricingFactor({
    required this.ruleType,
    required this.label,
    required this.adjustmentPct,
    required this.amount,
  });

  factory PricingFactor.fromJson(Map<String, dynamic> json) {
    return PricingFactor(
      ruleType: json['rule_type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      adjustmentPct: (json['adjustment_pct'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'rule_type': ruleType,
    'label': label,
    'adjustment_pct': adjustmentPct,
    'amount': amount,
  };

  bool get isIncrease => amount > 0;
}

class PricingSuggestion extends Equatable {
  final String id;
  final String companyId;
  final String? estimateId;
  final String? jobId;
  final double basePrice;
  final double suggestedPrice;
  final List<PricingFactor> factorsApplied;
  final double? finalPrice;
  final bool? accepted;
  final bool? jobWon;
  final DateTime createdAt;

  const PricingSuggestion({
    required this.id,
    required this.companyId,
    this.estimateId,
    this.jobId,
    required this.basePrice,
    required this.suggestedPrice,
    required this.factorsApplied,
    this.finalPrice,
    this.accepted,
    this.jobWon,
    required this.createdAt,
  });

  factory PricingSuggestion.fromJson(Map<String, dynamic> json) {
    final factorsRaw = json['factors_applied'] as List? ?? [];
    return PricingSuggestion(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      estimateId: json['estimate_id'] as String?,
      jobId: json['job_id'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      suggestedPrice: (json['suggested_price'] as num?)?.toDouble() ?? 0,
      factorsApplied: factorsRaw.map((f) => PricingFactor.fromJson(f as Map<String, dynamic>)).toList(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      accepted: json['accepted'] as bool?,
      jobWon: json['job_won'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'estimate_id': estimateId,
    'job_id': jobId,
    'base_price': basePrice,
    'suggested_price': suggestedPrice,
    'factors_applied': factorsApplied.map((f) => f.toJson()).toList(),
    'final_price': finalPrice,
    'accepted': accepted,
    'job_won': jobWon,
  };

  PricingSuggestion copyWith({
    String? id,
    String? companyId,
    String? estimateId,
    String? jobId,
    double? basePrice,
    double? suggestedPrice,
    List<PricingFactor>? factorsApplied,
    double? finalPrice,
    bool? accepted,
    bool? jobWon,
    DateTime? createdAt,
  }) {
    return PricingSuggestion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      estimateId: estimateId ?? this.estimateId,
      jobId: jobId ?? this.jobId,
      basePrice: basePrice ?? this.basePrice,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      factorsApplied: factorsApplied ?? this.factorsApplied,
      finalPrice: finalPrice ?? this.finalPrice,
      accepted: accepted ?? this.accepted,
      jobWon: jobWon ?? this.jobWon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Total adjustment amount (sum of all factors)
  double get totalAdjustment => suggestedPrice - basePrice;

  /// Total adjustment as percentage
  double get totalAdjustmentPct => basePrice > 0 ? (totalAdjustment / basePrice) * 100 : 0;

  /// Whether the suggestion increased the price
  bool get isIncrease => suggestedPrice > basePrice;

  /// Whether the user accepted and won the job
  bool get wasSuccessful => accepted == true && jobWon == true;

  @override
  List<Object?> get props => [id, estimateId, suggestedPrice, accepted];
}
