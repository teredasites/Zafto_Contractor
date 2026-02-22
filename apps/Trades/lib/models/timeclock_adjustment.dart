import 'package:equatable/equatable.dart';

/// Audit record for every time clock adjustment made by a manager.
class TimeclockAdjustment extends Equatable {
  final String id;
  final String companyId;
  final String timeEntryId;
  final String adjustedBy;
  final String employeeId;
  final DateTime originalClockIn;
  final DateTime? originalClockOut;
  final int? originalBreakMinutes;
  final DateTime adjustedClockIn;
  final DateTime? adjustedClockOut;
  final int? adjustedBreakMinutes;
  final String reason;
  final String adjustmentType;
  final String? ipAddress;
  final String? userAgent;
  final bool employeeNotified;
  final DateTime? employeeAcknowledgedAt;
  final DateTime createdAt;

  const TimeclockAdjustment({
    required this.id,
    required this.companyId,
    required this.timeEntryId,
    required this.adjustedBy,
    required this.employeeId,
    required this.originalClockIn,
    this.originalClockOut,
    this.originalBreakMinutes,
    required this.adjustedClockIn,
    this.adjustedClockOut,
    this.adjustedBreakMinutes,
    required this.reason,
    this.adjustmentType = 'manual',
    this.ipAddress,
    this.userAgent,
    this.employeeNotified = false,
    this.employeeAcknowledgedAt,
    required this.createdAt,
  });

  factory TimeclockAdjustment.fromJson(Map<String, dynamic> json) {
    return TimeclockAdjustment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      timeEntryId: json['time_entry_id'] as String,
      adjustedBy: json['adjusted_by'] as String,
      employeeId: json['employee_id'] as String,
      originalClockIn: DateTime.parse(json['original_clock_in'] as String),
      originalClockOut: json['original_clock_out'] != null
          ? DateTime.parse(json['original_clock_out'] as String)
          : null,
      originalBreakMinutes: json['original_break_minutes'] as int?,
      adjustedClockIn: DateTime.parse(json['adjusted_clock_in'] as String),
      adjustedClockOut: json['adjusted_clock_out'] != null
          ? DateTime.parse(json['adjusted_clock_out'] as String)
          : null,
      adjustedBreakMinutes: json['adjusted_break_minutes'] as int?,
      reason: json['reason'] as String,
      adjustmentType:
          (json['adjustment_type'] as String?) ?? 'manual',
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      employeeNotified:
          (json['employee_notified'] as bool?) ?? false,
      employeeAcknowledgedAt: json['employee_acknowledged_at'] != null
          ? DateTime.parse(json['employee_acknowledged_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'time_entry_id': timeEntryId,
        'adjusted_by': adjustedBy,
        'employee_id': employeeId,
        'original_clock_in': originalClockIn.toIso8601String(),
        'original_clock_out': originalClockOut?.toIso8601String(),
        'original_break_minutes': originalBreakMinutes,
        'adjusted_clock_in': adjustedClockIn.toIso8601String(),
        'adjusted_clock_out': adjustedClockOut?.toIso8601String(),
        'adjusted_break_minutes': adjustedBreakMinutes,
        'reason': reason,
        'adjustment_type': adjustmentType,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'employee_notified': employeeNotified,
        'employee_acknowledged_at':
            employeeAcknowledgedAt?.toIso8601String(),
      };

  TimeclockAdjustment copyWith({
    String? id,
    String? companyId,
    String? timeEntryId,
    String? adjustedBy,
    String? employeeId,
    DateTime? originalClockIn,
    DateTime? originalClockOut,
    int? originalBreakMinutes,
    DateTime? adjustedClockIn,
    DateTime? adjustedClockOut,
    int? adjustedBreakMinutes,
    String? reason,
    String? adjustmentType,
    String? ipAddress,
    String? userAgent,
    bool? employeeNotified,
    DateTime? employeeAcknowledgedAt,
    DateTime? createdAt,
  }) {
    return TimeclockAdjustment(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      timeEntryId: timeEntryId ?? this.timeEntryId,
      adjustedBy: adjustedBy ?? this.adjustedBy,
      employeeId: employeeId ?? this.employeeId,
      originalClockIn: originalClockIn ?? this.originalClockIn,
      originalClockOut: originalClockOut ?? this.originalClockOut,
      originalBreakMinutes:
          originalBreakMinutes ?? this.originalBreakMinutes,
      adjustedClockIn: adjustedClockIn ?? this.adjustedClockIn,
      adjustedClockOut: adjustedClockOut ?? this.adjustedClockOut,
      adjustedBreakMinutes:
          adjustedBreakMinutes ?? this.adjustedBreakMinutes,
      reason: reason ?? this.reason,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      employeeNotified: employeeNotified ?? this.employeeNotified,
      employeeAcknowledgedAt:
          employeeAcknowledgedAt ?? this.employeeAcknowledgedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        timeEntryId,
        adjustedBy,
        employeeId,
        originalClockIn,
        originalClockOut,
        originalBreakMinutes,
        adjustedClockIn,
        adjustedClockOut,
        adjustedBreakMinutes,
        reason,
        adjustmentType,
        employeeNotified,
        employeeAcknowledgedAt,
        createdAt,
      ];
}
