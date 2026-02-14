// ZAFTO Job Cost Autopsy Model
// J1: Per-job actual vs estimated cost breakdown and profitability analysis.

import 'package:equatable/equatable.dart';

class JobCostAutopsy extends Equatable {
  final String id;
  final String companyId;
  final String jobId;

  // Estimated (from original estimate)
  final double? estimatedLaborHours;
  final double? estimatedLaborCost;
  final double? estimatedMaterialCost;
  final double? estimatedTotal;

  // Actual (calculated from time entries, receipts, mileage)
  final double? actualLaborHours;
  final double? actualLaborCost;
  final double? actualMaterialCost;
  final double actualDriveTimeHours;
  final double actualDriveCost;
  final int actualCallbacks;
  final double actualChangeOrderCost;
  final double? actualTotal;

  // Profitability
  final double? revenue;
  final double? grossProfit;
  final double? grossMarginPct;
  final double? variancePct;

  // Metadata
  final String? jobType;
  final String? tradeType;
  final String? primaryTechId;
  final DateTime? completedAt;
  final DateTime createdAt;

  const JobCostAutopsy({
    required this.id,
    required this.companyId,
    required this.jobId,
    this.estimatedLaborHours,
    this.estimatedLaborCost,
    this.estimatedMaterialCost,
    this.estimatedTotal,
    this.actualLaborHours,
    this.actualLaborCost,
    this.actualMaterialCost,
    this.actualDriveTimeHours = 0,
    this.actualDriveCost = 0,
    this.actualCallbacks = 0,
    this.actualChangeOrderCost = 0,
    this.actualTotal,
    this.revenue,
    this.grossProfit,
    this.grossMarginPct,
    this.variancePct,
    this.jobType,
    this.tradeType,
    this.primaryTechId,
    this.completedAt,
    required this.createdAt,
  });

  factory JobCostAutopsy.fromJson(Map<String, dynamic> json) {
    return JobCostAutopsy(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String,
      estimatedLaborHours: (json['estimated_labor_hours'] as num?)?.toDouble(),
      estimatedLaborCost: (json['estimated_labor_cost'] as num?)?.toDouble(),
      estimatedMaterialCost: (json['estimated_material_cost'] as num?)?.toDouble(),
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble(),
      actualLaborHours: (json['actual_labor_hours'] as num?)?.toDouble(),
      actualLaborCost: (json['actual_labor_cost'] as num?)?.toDouble(),
      actualMaterialCost: (json['actual_material_cost'] as num?)?.toDouble(),
      actualDriveTimeHours: (json['actual_drive_time_hours'] as num?)?.toDouble() ?? 0,
      actualDriveCost: (json['actual_drive_cost'] as num?)?.toDouble() ?? 0,
      actualCallbacks: json['actual_callbacks'] as int? ?? 0,
      actualChangeOrderCost: (json['actual_change_order_cost'] as num?)?.toDouble() ?? 0,
      actualTotal: (json['actual_total'] as num?)?.toDouble(),
      revenue: (json['revenue'] as num?)?.toDouble(),
      grossProfit: (json['gross_profit'] as num?)?.toDouble(),
      grossMarginPct: (json['gross_margin_pct'] as num?)?.toDouble(),
      variancePct: (json['variance_pct'] as num?)?.toDouble(),
      jobType: json['job_type'] as String?,
      tradeType: json['trade_type'] as String?,
      primaryTechId: json['primary_tech_id'] as String?,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'job_id': jobId,
    'estimated_labor_hours': estimatedLaborHours,
    'estimated_labor_cost': estimatedLaborCost,
    'estimated_material_cost': estimatedMaterialCost,
    'estimated_total': estimatedTotal,
    'actual_labor_hours': actualLaborHours,
    'actual_labor_cost': actualLaborCost,
    'actual_material_cost': actualMaterialCost,
    'actual_drive_time_hours': actualDriveTimeHours,
    'actual_drive_cost': actualDriveCost,
    'actual_callbacks': actualCallbacks,
    'actual_change_order_cost': actualChangeOrderCost,
    'actual_total': actualTotal,
    'revenue': revenue,
    'gross_profit': grossProfit,
    'gross_margin_pct': grossMarginPct,
    'variance_pct': variancePct,
    'job_type': jobType,
    'trade_type': tradeType,
    'primary_tech_id': primaryTechId,
    'completed_at': completedAt?.toIso8601String(),
  };

  JobCostAutopsy copyWith({
    String? id,
    String? companyId,
    String? jobId,
    double? estimatedLaborHours,
    double? estimatedLaborCost,
    double? estimatedMaterialCost,
    double? estimatedTotal,
    double? actualLaborHours,
    double? actualLaborCost,
    double? actualMaterialCost,
    double? actualDriveTimeHours,
    double? actualDriveCost,
    int? actualCallbacks,
    double? actualChangeOrderCost,
    double? actualTotal,
    double? revenue,
    double? grossProfit,
    double? grossMarginPct,
    double? variancePct,
    String? jobType,
    String? tradeType,
    String? primaryTechId,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return JobCostAutopsy(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      estimatedLaborHours: estimatedLaborHours ?? this.estimatedLaborHours,
      estimatedLaborCost: estimatedLaborCost ?? this.estimatedLaborCost,
      estimatedMaterialCost: estimatedMaterialCost ?? this.estimatedMaterialCost,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      actualLaborHours: actualLaborHours ?? this.actualLaborHours,
      actualLaborCost: actualLaborCost ?? this.actualLaborCost,
      actualMaterialCost: actualMaterialCost ?? this.actualMaterialCost,
      actualDriveTimeHours: actualDriveTimeHours ?? this.actualDriveTimeHours,
      actualDriveCost: actualDriveCost ?? this.actualDriveCost,
      actualCallbacks: actualCallbacks ?? this.actualCallbacks,
      actualChangeOrderCost: actualChangeOrderCost ?? this.actualChangeOrderCost,
      actualTotal: actualTotal ?? this.actualTotal,
      revenue: revenue ?? this.revenue,
      grossProfit: grossProfit ?? this.grossProfit,
      grossMarginPct: grossMarginPct ?? this.grossMarginPct,
      variancePct: variancePct ?? this.variancePct,
      jobType: jobType ?? this.jobType,
      tradeType: tradeType ?? this.tradeType,
      primaryTechId: primaryTechId ?? this.primaryTechId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Is this job profitable?
  bool get isProfitable => (grossProfit ?? 0) > 0;

  /// Was actual cost higher than estimated?
  bool get wasOverBudget => (variancePct ?? 0) > 0;

  /// Labor variance in hours
  double get laborHoursVariance =>
      (actualLaborHours ?? 0) - (estimatedLaborHours ?? 0);

  @override
  List<Object?> get props => [id, jobId, grossMarginPct];
}
