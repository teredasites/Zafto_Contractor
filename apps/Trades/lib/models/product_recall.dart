// ZAFTO Product Recall Model — Supabase Backend
// Maps to `product_recalls` table. Manufacturer recall tracking.

import 'package:equatable/equatable.dart';

enum RecallSeverity {
  low,
  medium,
  high,
  critical;

  String get dbValue => name;

  static RecallSeverity fromDb(String? value) {
    switch (value) {
      case 'low':
        return RecallSeverity.low;
      case 'medium':
        return RecallSeverity.medium;
      case 'high':
        return RecallSeverity.high;
      case 'critical':
        return RecallSeverity.critical;
      default:
        return RecallSeverity.medium;
    }
  }

  String get label {
    switch (this) {
      case RecallSeverity.low:
        return 'Low';
      case RecallSeverity.medium:
        return 'Medium';
      case RecallSeverity.high:
        return 'High';
      case RecallSeverity.critical:
        return 'Critical';
    }
  }
}

class ProductRecall extends Equatable {
  final String id;
  final String manufacturer;
  final String? modelPattern;
  final String recallTitle;
  final String? recallDescription;
  final DateTime recallDate;
  final RecallSeverity severity;
  final String? sourceUrl;
  final String? affectedSerialRange;
  final bool isActive;
  final DateTime createdAt;

  const ProductRecall({
    required this.id,
    required this.manufacturer,
    this.modelPattern,
    required this.recallTitle,
    this.recallDescription,
    required this.recallDate,
    required this.severity,
    this.sourceUrl,
    this.affectedSerialRange,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductRecall.fromJson(Map<String, dynamic> json) {
    return ProductRecall(
      id: json['id'] as String,
      manufacturer: json['manufacturer'] as String,
      modelPattern: json['model_pattern'] as String?,
      recallTitle: json['recall_title'] as String,
      recallDescription: json['recall_description'] as String?,
      recallDate: DateTime.parse(json['recall_date'] as String),
      severity: RecallSeverity.fromDb(json['severity'] as String?),
      sourceUrl: json['source_url'] as String?,
      affectedSerialRange: json['affected_serial_range'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'model_pattern': modelPattern,
      'recall_title': recallTitle,
      'recall_description': recallDescription,
      'recall_date': recallDate.toIso8601String().split('T').first,
      'severity': severity.dbValue,
      'source_url': sourceUrl,
      'affected_serial_range': affectedSerialRange,
      'is_active': isActive,
    };
  }

  ProductRecall copyWith({
    String? id,
    String? manufacturer,
    String? modelPattern,
    String? recallTitle,
    String? recallDescription,
    DateTime? recallDate,
    RecallSeverity? severity,
    String? sourceUrl,
    String? affectedSerialRange,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductRecall(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      modelPattern: modelPattern ?? this.modelPattern,
      recallTitle: recallTitle ?? this.recallTitle,
      recallDescription: recallDescription ?? this.recallDescription,
      recallDate: recallDate ?? this.recallDate,
      severity: severity ?? this.severity,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      affectedSerialRange: affectedSerialRange ?? this.affectedSerialRange,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCritical => severity == RecallSeverity.critical || severity == RecallSeverity.high;

  @override
  List<Object?> get props => [id, manufacturer, recallTitle, severity];
}
