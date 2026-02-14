// ZAFTO Estimate Adjustment Model
// J1: Suggested pricing corrections based on autopsy data.

import 'package:equatable/equatable.dart';

enum AdjustmentType {
  laborHoursMultiplier,
  materialCostMultiplier,
  totalCostMultiplier,
  flatAddLabor,
  flatAddMaterial,
  driveTimeAdd;

  String get dbValue {
    switch (this) {
      case AdjustmentType.laborHoursMultiplier: return 'labor_hours_multiplier';
      case AdjustmentType.materialCostMultiplier: return 'material_cost_multiplier';
      case AdjustmentType.totalCostMultiplier: return 'total_cost_multiplier';
      case AdjustmentType.flatAddLabor: return 'flat_add_labor';
      case AdjustmentType.flatAddMaterial: return 'flat_add_material';
      case AdjustmentType.driveTimeAdd: return 'drive_time_add';
    }
  }

  static AdjustmentType fromDb(String? value) {
    switch (value) {
      case 'labor_hours_multiplier': return AdjustmentType.laborHoursMultiplier;
      case 'material_cost_multiplier': return AdjustmentType.materialCostMultiplier;
      case 'total_cost_multiplier': return AdjustmentType.totalCostMultiplier;
      case 'flat_add_labor': return AdjustmentType.flatAddLabor;
      case 'flat_add_material': return AdjustmentType.flatAddMaterial;
      case 'drive_time_add': return AdjustmentType.driveTimeAdd;
      default: return AdjustmentType.totalCostMultiplier;
    }
  }

  String get label {
    switch (this) {
      case AdjustmentType.laborHoursMultiplier: return 'Labor Hours Multiplier';
      case AdjustmentType.materialCostMultiplier: return 'Material Cost Multiplier';
      case AdjustmentType.totalCostMultiplier: return 'Total Cost Multiplier';
      case AdjustmentType.flatAddLabor: return 'Flat Labor Add';
      case AdjustmentType.flatAddMaterial: return 'Flat Material Add';
      case AdjustmentType.driveTimeAdd: return 'Drive Time Add';
    }
  }

  bool get isMultiplier => this == AdjustmentType.laborHoursMultiplier ||
      this == AdjustmentType.materialCostMultiplier ||
      this == AdjustmentType.totalCostMultiplier;
}

enum AdjustmentStatus {
  pending,
  accepted,
  dismissed,
  applied;

  String get dbValue => name;

  static AdjustmentStatus fromDb(String? value) {
    switch (value) {
      case 'pending': return AdjustmentStatus.pending;
      case 'accepted': return AdjustmentStatus.accepted;
      case 'dismissed': return AdjustmentStatus.dismissed;
      case 'applied': return AdjustmentStatus.applied;
      default: return AdjustmentStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case AdjustmentStatus.pending: return 'Pending';
      case AdjustmentStatus.accepted: return 'Accepted';
      case AdjustmentStatus.dismissed: return 'Dismissed';
      case AdjustmentStatus.applied: return 'Applied';
    }
  }
}

class EstimateAdjustment extends Equatable {
  final String id;
  final String companyId;
  final String jobType;
  final String? tradeType;
  final AdjustmentType adjustmentType;
  final double? suggestedMultiplier;
  final double? suggestedFlatAmount;
  final int basedOnJobs;
  final double? avgVariancePct;
  final AdjustmentStatus status;
  final DateTime? appliedAt;
  final DateTime createdAt;

  const EstimateAdjustment({
    required this.id,
    required this.companyId,
    required this.jobType,
    this.tradeType,
    required this.adjustmentType,
    this.suggestedMultiplier,
    this.suggestedFlatAmount,
    required this.basedOnJobs,
    this.avgVariancePct,
    required this.status,
    this.appliedAt,
    required this.createdAt,
  });

  factory EstimateAdjustment.fromJson(Map<String, dynamic> json) {
    return EstimateAdjustment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobType: json['job_type'] as String,
      tradeType: json['trade_type'] as String?,
      adjustmentType: AdjustmentType.fromDb(json['adjustment_type'] as String?),
      suggestedMultiplier: (json['suggested_multiplier'] as num?)?.toDouble(),
      suggestedFlatAmount: (json['suggested_flat_amount'] as num?)?.toDouble(),
      basedOnJobs: json['based_on_jobs'] as int? ?? 0,
      avgVariancePct: (json['avg_variance_pct'] as num?)?.toDouble(),
      status: AdjustmentStatus.fromDb(json['status'] as String?),
      appliedAt: json['applied_at'] != null ? DateTime.parse(json['applied_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'job_type': jobType,
    'trade_type': tradeType,
    'adjustment_type': adjustmentType.dbValue,
    'suggested_multiplier': suggestedMultiplier,
    'suggested_flat_amount': suggestedFlatAmount,
    'based_on_jobs': basedOnJobs,
    'avg_variance_pct': avgVariancePct,
    'status': status.dbValue,
    'applied_at': appliedAt?.toIso8601String(),
  };

  EstimateAdjustment copyWith({
    String? id,
    String? companyId,
    String? jobType,
    String? tradeType,
    AdjustmentType? adjustmentType,
    double? suggestedMultiplier,
    double? suggestedFlatAmount,
    int? basedOnJobs,
    double? avgVariancePct,
    AdjustmentStatus? status,
    DateTime? appliedAt,
    DateTime? createdAt,
  }) {
    return EstimateAdjustment(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobType: jobType ?? this.jobType,
      tradeType: tradeType ?? this.tradeType,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      suggestedMultiplier: suggestedMultiplier ?? this.suggestedMultiplier,
      suggestedFlatAmount: suggestedFlatAmount ?? this.suggestedFlatAmount,
      basedOnJobs: basedOnJobs ?? this.basedOnJobs,
      avgVariancePct: avgVariancePct ?? this.avgVariancePct,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-readable adjustment description
  String get description {
    if (adjustmentType.isMultiplier && suggestedMultiplier != null) {
      final pct = ((suggestedMultiplier! - 1) * 100).toStringAsFixed(0);
      return '${int.parse(pct) >= 0 ? '+' : ''}$pct% ${adjustmentType.label.toLowerCase()}';
    }
    if (suggestedFlatAmount != null) {
      return '+\$${suggestedFlatAmount!.toStringAsFixed(2)} ${adjustmentType.label.toLowerCase()}';
    }
    return adjustmentType.label;
  }

  bool get isPending => status == AdjustmentStatus.pending;

  @override
  List<Object?> get props => [id, jobType, adjustmentType, status];
}
