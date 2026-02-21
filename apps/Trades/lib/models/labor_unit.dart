// ZAFTO Labor Unit Model
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Trade-specific labor hour database with difficulty multipliers
// and crew performance tracking.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// LABOR DIFFICULTY ENUM
// ════════════════════════════════════════════════════════════════

enum LaborDifficulty { normal, difficult, veryDifficult }

LaborDifficulty parseLaborDifficulty(String? value) {
  switch (value) {
    case 'difficult':
      return LaborDifficulty.difficult;
    case 'very_difficult':
      return LaborDifficulty.veryDifficult;
    default:
      return LaborDifficulty.normal;
  }
}

String laborDifficultyToString(LaborDifficulty d) {
  switch (d) {
    case LaborDifficulty.normal:
      return 'normal';
    case LaborDifficulty.difficult:
      return 'difficult';
    case LaborDifficulty.veryDifficult:
      return 'very_difficult';
  }
}

String laborDifficultyLabel(LaborDifficulty d) {
  switch (d) {
    case LaborDifficulty.normal:
      return 'Normal';
    case LaborDifficulty.difficult:
      return 'Difficult';
    case LaborDifficulty.veryDifficult:
      return 'Very Difficult';
  }
}

// ════════════════════════════════════════════════════════════════
// LABOR UNIT
// ════════════════════════════════════════════════════════════════

class LaborUnit extends Equatable {
  final String id;
  final String? companyId;
  final String trade;
  final String category;
  final String taskName;
  final String? description;
  final String unit;
  final double hoursNormal;
  final double hoursDifficult;
  final double hoursVeryDifficult;
  final int crewSizeDefault;
  final String? notes;
  final String source; // 'system' | 'company'
  final DateTime createdAt;
  final DateTime updatedAt;

  const LaborUnit({
    required this.id,
    this.companyId,
    required this.trade,
    required this.category,
    required this.taskName,
    this.description,
    required this.unit,
    required this.hoursNormal,
    required this.hoursDifficult,
    required this.hoursVeryDifficult,
    required this.crewSizeDefault,
    this.notes,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSystemDefault => companyId == null;

  /// Get hours for a given difficulty level
  double hoursFor(LaborDifficulty difficulty) {
    switch (difficulty) {
      case LaborDifficulty.normal:
        return hoursNormal;
      case LaborDifficulty.difficult:
        return hoursDifficult;
      case LaborDifficulty.veryDifficult:
        return hoursVeryDifficult;
    }
  }

  /// Total hours for a quantity at a given difficulty
  double totalHours(double quantity, {LaborDifficulty difficulty = LaborDifficulty.normal}) {
    return hoursFor(difficulty) * quantity;
  }

  /// Estimated crew-days for a quantity
  double crewDays(double quantity, {LaborDifficulty difficulty = LaborDifficulty.normal, double hoursPerDay = 8.0}) {
    final total = totalHours(quantity, difficulty: difficulty);
    return total / (crewSizeDefault * hoursPerDay);
  }

  factory LaborUnit.fromJson(Map<String, dynamic> json) {
    return LaborUnit(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      trade: json['trade'] as String,
      category: json['category'] as String,
      taskName: json['task_name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String,
      hoursNormal: (json['hours_normal'] as num?)?.toDouble() ?? 0,
      hoursDifficult: (json['hours_difficult'] as num?)?.toDouble() ?? 0,
      hoursVeryDifficult: (json['hours_very_difficult'] as num?)?.toDouble() ?? 0,
      crewSizeDefault: (json['crew_size_default'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'system',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'trade': trade,
        'category': category,
        'task_name': taskName,
        'description': description,
        'unit': unit,
        'hours_normal': hoursNormal,
        'hours_difficult': hoursDifficult,
        'hours_very_difficult': hoursVeryDifficult,
        'crew_size_default': crewSizeDefault,
        'notes': notes,
        'source': source,
      };

  LaborUnit copyWith({
    String? id,
    String? companyId,
    String? trade,
    String? category,
    String? taskName,
    String? description,
    String? unit,
    double? hoursNormal,
    double? hoursDifficult,
    double? hoursVeryDifficult,
    int? crewSizeDefault,
    String? notes,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LaborUnit(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      trade: trade ?? this.trade,
      category: category ?? this.category,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      hoursNormal: hoursNormal ?? this.hoursNormal,
      hoursDifficult: hoursDifficult ?? this.hoursDifficult,
      hoursVeryDifficult: hoursVeryDifficult ?? this.hoursVeryDifficult,
      crewSizeDefault: crewSizeDefault ?? this.crewSizeDefault,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        trade,
        category,
        taskName,
        unit,
        hoursNormal,
        hoursDifficult,
        hoursVeryDifficult,
        crewSizeDefault,
        source,
      ];
}

// ════════════════════════════════════════════════════════════════
// CREW PERFORMANCE ENTRY
// ════════════════════════════════════════════════════════════════

class CrewPerformanceEntry extends Equatable {
  final String id;
  final String companyId;
  final String? laborUnitId;
  final String taskName;
  final String trade;
  final double estimatedHours;
  final double actualHours;
  final int crewSize;
  final LaborDifficulty difficulty;
  final String? jobId;
  final String? notes;
  final DateTime createdAt;

  const CrewPerformanceEntry({
    required this.id,
    required this.companyId,
    this.laborUnitId,
    required this.taskName,
    required this.trade,
    required this.estimatedHours,
    required this.actualHours,
    required this.crewSize,
    required this.difficulty,
    this.jobId,
    this.notes,
    required this.createdAt,
  });

  /// Performance ratio: < 1.0 means faster than estimated, > 1.0 means slower
  double get performanceRatio {
    if (estimatedHours <= 0) return 1.0;
    return actualHours / estimatedHours;
  }

  /// Hours saved (positive) or lost (negative)
  double get hoursDelta => estimatedHours - actualHours;

  factory CrewPerformanceEntry.fromJson(Map<String, dynamic> json) {
    return CrewPerformanceEntry(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      laborUnitId: json['labor_unit_id'] as String?,
      taskName: json['task_name'] as String,
      trade: json['trade'] as String,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0,
      crewSize: (json['crew_size'] as num?)?.toInt() ?? 1,
      difficulty: parseLaborDifficulty(json['difficulty'] as String?),
      jobId: json['job_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'labor_unit_id': laborUnitId,
        'task_name': taskName,
        'trade': trade,
        'estimated_hours': estimatedHours,
        'actual_hours': actualHours,
        'crew_size': crewSize,
        'difficulty': laborDifficultyToString(difficulty),
        'job_id': jobId,
        'notes': notes,
      };

  CrewPerformanceEntry copyWith({
    String? id,
    String? companyId,
    String? laborUnitId,
    String? taskName,
    String? trade,
    double? estimatedHours,
    double? actualHours,
    int? crewSize,
    LaborDifficulty? difficulty,
    String? jobId,
    String? notes,
    DateTime? createdAt,
  }) {
    return CrewPerformanceEntry(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      laborUnitId: laborUnitId ?? this.laborUnitId,
      taskName: taskName ?? this.taskName,
      trade: trade ?? this.trade,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      crewSize: crewSize ?? this.crewSize,
      difficulty: difficulty ?? this.difficulty,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        laborUnitId,
        taskName,
        trade,
        estimatedHours,
        actualHours,
        crewSize,
        difficulty,
      ];
}
