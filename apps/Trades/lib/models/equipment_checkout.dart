// ZAFTO Equipment Checkout Model
// Created: Sprint FIELD2 (Session 131)

import 'package:equatable/equatable.dart';
import 'equipment_item.dart';

class EquipmentCheckout extends Equatable {
  final String id;
  final String companyId;
  final String equipmentItemId;
  final String checkedOutBy;
  final DateTime checkedOutAt;
  final DateTime? expectedReturnDate;
  final DateTime? checkedInAt;
  final String? checkedInBy;
  final EquipmentCondition checkoutCondition;
  final EquipmentCondition? checkinCondition;
  final String? jobId;
  final String? notes;
  final String? photoOutUrl;
  final String? photoInUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Joined fields (from related tables)
  final String? equipmentName;
  final String? checkedOutByName;
  final String? checkedInByName;
  final String? jobTitle;

  const EquipmentCheckout({
    required this.id,
    required this.companyId,
    required this.equipmentItemId,
    required this.checkedOutBy,
    required this.checkedOutAt,
    this.expectedReturnDate,
    this.checkedInAt,
    this.checkedInBy,
    required this.checkoutCondition,
    this.checkinCondition,
    this.jobId,
    this.notes,
    this.photoOutUrl,
    this.photoInUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.equipmentName,
    this.checkedOutByName,
    this.checkedInByName,
    this.jobTitle,
  });

  bool get isActive => checkedInAt == null;

  bool get isOverdue {
    if (!isActive || expectedReturnDate == null) return false;
    return DateTime.now().isAfter(
      DateTime(expectedReturnDate!.year, expectedReturnDate!.month, expectedReturnDate!.day)
          .add(const Duration(days: 1)),
    );
  }

  Duration? get duration {
    final end = checkedInAt ?? DateTime.now();
    return end.difference(checkedOutAt);
  }

  factory EquipmentCheckout.fromJson(Map<String, dynamic> json) {
    return EquipmentCheckout(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      equipmentItemId: json['equipment_item_id'] as String,
      checkedOutBy: json['checked_out_by'] as String,
      checkedOutAt: DateTime.parse(json['checked_out_at'] as String),
      expectedReturnDate: json['expected_return_date'] != null
          ? DateTime.parse(json['expected_return_date'] as String)
          : null,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      checkedInBy: json['checked_in_by'] as String?,
      checkoutCondition: EquipmentCondition.fromDb(json['checkout_condition'] as String?),
      checkinCondition: json['checkin_condition'] != null
          ? EquipmentCondition.fromDb(json['checkin_condition'] as String?)
          : null,
      jobId: json['job_id'] as String?,
      notes: json['notes'] as String?,
      photoOutUrl: json['photo_out_url'] as String?,
      photoInUrl: json['photo_in_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      // Joined fields — handle nested objects
      equipmentName: _extractNestedString(json, 'equipment_items', 'name'),
      checkedOutByName: _extractUserName(json, 'checked_out_by_user'),
      checkedInByName: _extractUserName(json, 'checked_in_by_user'),
      jobTitle: _extractNestedString(json, 'jobs', 'title'),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'equipment_item_id': equipmentItemId,
        'checked_out_by': checkedOutBy,
        'checked_out_at': checkedOutAt.toIso8601String(),
        'expected_return_date': expectedReturnDate?.toIso8601String().split('T').first,
        'checked_in_at': checkedInAt?.toIso8601String(),
        'checked_in_by': checkedInBy,
        'checkout_condition': checkoutCondition.dbValue,
        'checkin_condition': checkinCondition?.dbValue,
        'job_id': jobId,
        'notes': notes,
        'photo_out_url': photoOutUrl,
        'photo_in_url': photoInUrl,
      };

  EquipmentCheckout copyWith({
    DateTime? expectedReturnDate,
    DateTime? checkedInAt,
    String? checkedInBy,
    EquipmentCondition? checkinCondition,
    String? notes,
    String? photoOutUrl,
    String? photoInUrl,
  }) {
    return EquipmentCheckout(
      id: id,
      companyId: companyId,
      equipmentItemId: equipmentItemId,
      checkedOutBy: checkedOutBy,
      checkedOutAt: checkedOutAt,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      checkoutCondition: checkoutCondition,
      checkinCondition: checkinCondition ?? this.checkinCondition,
      jobId: jobId,
      notes: notes ?? this.notes,
      photoOutUrl: photoOutUrl ?? this.photoOutUrl,
      photoInUrl: photoInUrl ?? this.photoInUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      equipmentName: equipmentName,
      checkedOutByName: checkedOutByName,
      checkedInByName: checkedInByName,
      jobTitle: jobTitle,
    );
  }

  @override
  List<Object?> get props => [id];
}

// Helpers for extracting joined data from Supabase select
String? _extractNestedString(Map<String, dynamic> json, String table, String field) {
  final nested = json[table];
  if (nested is Map<String, dynamic>) return nested[field] as String?;
  return null;
}

String? _extractUserName(Map<String, dynamic> json, String key) {
  final nested = json[key];
  if (nested is Map<String, dynamic>) {
    final first = nested['first_name'] as String? ?? '';
    final last = nested['last_name'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? null : name;
  }
  return null;
}
