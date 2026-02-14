// ZAFTO Maintenance Prediction Model
// W6: Predicted maintenance events for customer equipment.

import 'package:equatable/equatable.dart';

enum PredictionType {
  maintenanceDue,
  endOfLife,
  seasonalCheck,
  filterReplacement,
  inspectionRecommended;

  String get dbValue {
    switch (this) {
      case PredictionType.maintenanceDue:
        return 'maintenance_due';
      case PredictionType.endOfLife:
        return 'end_of_life';
      case PredictionType.seasonalCheck:
        return 'seasonal_check';
      case PredictionType.filterReplacement:
        return 'filter_replacement';
      case PredictionType.inspectionRecommended:
        return 'inspection_recommended';
    }
  }

  static PredictionType fromDb(String? value) {
    switch (value) {
      case 'maintenance_due':
        return PredictionType.maintenanceDue;
      case 'end_of_life':
        return PredictionType.endOfLife;
      case 'seasonal_check':
        return PredictionType.seasonalCheck;
      case 'filter_replacement':
        return PredictionType.filterReplacement;
      case 'inspection_recommended':
        return PredictionType.inspectionRecommended;
      default:
        return PredictionType.maintenanceDue;
    }
  }

  String get label {
    switch (this) {
      case PredictionType.maintenanceDue:
        return 'Maintenance Due';
      case PredictionType.endOfLife:
        return 'End of Life';
      case PredictionType.seasonalCheck:
        return 'Seasonal Check';
      case PredictionType.filterReplacement:
        return 'Filter Replacement';
      case PredictionType.inspectionRecommended:
        return 'Inspection Recommended';
    }
  }
}

enum OutreachStatus {
  pending,
  sent,
  booked,
  declined,
  completed;

  String get dbValue => name;

  static OutreachStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return OutreachStatus.pending;
      case 'sent':
        return OutreachStatus.sent;
      case 'booked':
        return OutreachStatus.booked;
      case 'declined':
        return OutreachStatus.declined;
      case 'completed':
        return OutreachStatus.completed;
      default:
        return OutreachStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OutreachStatus.pending:
        return 'Pending';
      case OutreachStatus.sent:
        return 'Sent';
      case OutreachStatus.booked:
        return 'Booked';
      case OutreachStatus.declined:
        return 'Declined';
      case OutreachStatus.completed:
        return 'Completed';
    }
  }
}

class MaintenancePrediction extends Equatable {
  final String id;
  final String companyId;
  final String equipmentId;
  final String? customerId;
  final PredictionType predictionType;
  final DateTime predictedDate;
  final double confidenceScore;
  final String recommendedAction;
  final double? estimatedCost;
  final OutreachStatus outreachStatus;
  final String? resultingJobId;
  final String? notes;
  final DateTime createdAt;

  const MaintenancePrediction({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    this.customerId,
    required this.predictionType,
    required this.predictedDate,
    required this.confidenceScore,
    required this.recommendedAction,
    this.estimatedCost,
    required this.outreachStatus,
    this.resultingJobId,
    this.notes,
    required this.createdAt,
  });

  factory MaintenancePrediction.fromJson(Map<String, dynamic> json) {
    return MaintenancePrediction(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      equipmentId: json['equipment_id'] as String,
      customerId: json['customer_id'] as String?,
      predictionType: PredictionType.fromDb(json['prediction_type'] as String?),
      predictedDate: DateTime.parse(json['predicted_date'] as String),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      recommendedAction: json['recommended_action'] as String,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      outreachStatus: OutreachStatus.fromDb(json['outreach_status'] as String?),
      resultingJobId: json['resulting_job_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'equipment_id': equipmentId,
    'customer_id': customerId,
    'prediction_type': predictionType.dbValue,
    'predicted_date': predictedDate.toIso8601String().split('T').first,
    'confidence_score': confidenceScore,
    'recommended_action': recommendedAction,
    'estimated_cost': estimatedCost,
    'outreach_status': outreachStatus.dbValue,
    'resulting_job_id': resultingJobId,
    'notes': notes,
  };

  MaintenancePrediction copyWith({
    String? id,
    String? companyId,
    String? equipmentId,
    String? customerId,
    PredictionType? predictionType,
    DateTime? predictedDate,
    double? confidenceScore,
    String? recommendedAction,
    double? estimatedCost,
    OutreachStatus? outreachStatus,
    String? resultingJobId,
    String? notes,
    DateTime? createdAt,
  }) {
    return MaintenancePrediction(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      equipmentId: equipmentId ?? this.equipmentId,
      customerId: customerId ?? this.customerId,
      predictionType: predictionType ?? this.predictionType,
      predictedDate: predictedDate ?? this.predictedDate,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      outreachStatus: outreachStatus ?? this.outreachStatus,
      resultingJobId: resultingJobId ?? this.resultingJobId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Is this prediction for the future?
  bool get isUpcoming => predictedDate.isAfter(DateTime.now());

  /// Is this prediction overdue?
  bool get isOverdue => predictedDate.isBefore(DateTime.now()) && outreachStatus != OutreachStatus.completed;

  /// Days until predicted date (negative = overdue)
  int get daysUntil => predictedDate.difference(DateTime.now()).inDays;

  /// Confidence as percentage string
  String get confidencePercent => '${(confidenceScore * 100).round()}%';

  @override
  List<Object?> get props => [id, equipmentId, predictionType, predictedDate];
}
