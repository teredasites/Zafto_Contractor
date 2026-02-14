// ZAFTO Permit Inspection Model
// L1: Inspection results per permit.

import 'package:equatable/equatable.dart';

enum InspectionResult {
  pass,
  fail,
  partial,
  cancelled,
  rescheduled;

  String get dbValue => name;

  static InspectionResult fromDb(String? value) {
    switch (value) {
      case 'pass': return InspectionResult.pass;
      case 'fail': return InspectionResult.fail;
      case 'partial': return InspectionResult.partial;
      case 'cancelled': return InspectionResult.cancelled;
      case 'rescheduled': return InspectionResult.rescheduled;
      default: return InspectionResult.pass;
    }
  }

  String get label {
    switch (this) {
      case InspectionResult.pass: return 'Pass';
      case InspectionResult.fail: return 'Fail';
      case InspectionResult.partial: return 'Partial';
      case InspectionResult.cancelled: return 'Cancelled';
      case InspectionResult.rescheduled: return 'Rescheduled';
    }
  }
}

class InspectionPhoto {
  final String path;
  final String? caption;

  const InspectionPhoto({required this.path, this.caption});

  factory InspectionPhoto.fromJson(Map<String, dynamic> json) {
    return InspectionPhoto(
      path: json['path'] as String? ?? '',
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'caption': caption,
  };
}

class PermitInspection extends Equatable {
  final String id;
  final String companyId;
  final String jobPermitId;
  final String inspectionType;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String? inspectorName;
  final String? inspectorPhone;
  final InspectionResult? result;
  final String? failureReason;
  final String? correctionNotes;
  final DateTime? correctionDeadline;
  final List<InspectionPhoto> photos;
  final bool reinspectionNeeded;
  final DateTime? reinspectionDate;
  final DateTime createdAt;

  const PermitInspection({
    required this.id,
    required this.companyId,
    required this.jobPermitId,
    required this.inspectionType,
    this.scheduledDate,
    this.completedDate,
    this.inspectorName,
    this.inspectorPhone,
    this.result,
    this.failureReason,
    this.correctionNotes,
    this.correctionDeadline,
    required this.photos,
    required this.reinspectionNeeded,
    this.reinspectionDate,
    required this.createdAt,
  });

  factory PermitInspection.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'] as List? ?? [];
    return PermitInspection(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobPermitId: json['job_permit_id'] as String,
      inspectionType: json['inspection_type'] as String,
      scheduledDate: json['scheduled_date'] != null ? DateTime.parse(json['scheduled_date'] as String) : null,
      completedDate: json['completed_date'] != null ? DateTime.parse(json['completed_date'] as String) : null,
      inspectorName: json['inspector_name'] as String?,
      inspectorPhone: json['inspector_phone'] as String?,
      result: json['result'] != null ? InspectionResult.fromDb(json['result'] as String?) : null,
      failureReason: json['failure_reason'] as String?,
      correctionNotes: json['correction_notes'] as String?,
      correctionDeadline: json['correction_deadline'] != null ? DateTime.parse(json['correction_deadline'] as String) : null,
      photos: photosRaw.map((p) => InspectionPhoto.fromJson(p as Map<String, dynamic>)).toList(),
      reinspectionNeeded: json['reinspection_needed'] as bool? ?? false,
      reinspectionDate: json['reinspection_date'] != null ? DateTime.parse(json['reinspection_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'job_permit_id': jobPermitId,
    'inspection_type': inspectionType,
    'scheduled_date': scheduledDate?.toIso8601String().split('T').first,
    'completed_date': completedDate?.toIso8601String().split('T').first,
    'inspector_name': inspectorName,
    'inspector_phone': inspectorPhone,
    'result': result?.dbValue,
    'failure_reason': failureReason,
    'correction_notes': correctionNotes,
    'correction_deadline': correctionDeadline?.toIso8601String().split('T').first,
    'photos': photos.map((p) => p.toJson()).toList(),
    'reinspection_needed': reinspectionNeeded,
    'reinspection_date': reinspectionDate?.toIso8601String().split('T').first,
  };

  PermitInspection copyWith({
    String? id,
    String? companyId,
    String? jobPermitId,
    String? inspectionType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? inspectorName,
    String? inspectorPhone,
    InspectionResult? result,
    String? failureReason,
    String? correctionNotes,
    DateTime? correctionDeadline,
    List<InspectionPhoto>? photos,
    bool? reinspectionNeeded,
    DateTime? reinspectionDate,
    DateTime? createdAt,
  }) {
    return PermitInspection(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobPermitId: jobPermitId ?? this.jobPermitId,
      inspectionType: inspectionType ?? this.inspectionType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorPhone: inspectorPhone ?? this.inspectorPhone,
      result: result ?? this.result,
      failureReason: failureReason ?? this.failureReason,
      correctionNotes: correctionNotes ?? this.correctionNotes,
      correctionDeadline: correctionDeadline ?? this.correctionDeadline,
      photos: photos ?? this.photos,
      reinspectionNeeded: reinspectionNeeded ?? this.reinspectionNeeded,
      reinspectionDate: reinspectionDate ?? this.reinspectionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPassed => result == InspectionResult.pass;
  bool get isFailed => result == InspectionResult.fail;
  bool get needsCorrection => isFailed && correctionDeadline != null;

  @override
  List<Object?> get props => [id, jobPermitId, inspectionType, result];
}
