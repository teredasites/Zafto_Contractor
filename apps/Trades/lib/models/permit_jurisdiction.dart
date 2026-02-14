// ZAFTO Permit Jurisdiction Model
// L1: Building department data by locality — reference data.

import 'package:equatable/equatable.dart';

class PermitJurisdiction extends Equatable {
  final String id;
  final String jurisdictionName;
  final String jurisdictionType;
  final String stateCode;
  final String? countyFips;
  final String? cityName;
  final String? buildingDeptName;
  final String? buildingDeptPhone;
  final String? buildingDeptUrl;
  final String? onlineSubmissionUrl;
  final int? avgTurnaroundDays;
  final String? notes;
  final bool verified;
  final DateTime createdAt;

  const PermitJurisdiction({
    required this.id,
    required this.jurisdictionName,
    required this.jurisdictionType,
    required this.stateCode,
    this.countyFips,
    this.cityName,
    this.buildingDeptName,
    this.buildingDeptPhone,
    this.buildingDeptUrl,
    this.onlineSubmissionUrl,
    this.avgTurnaroundDays,
    this.notes,
    required this.verified,
    required this.createdAt,
  });

  factory PermitJurisdiction.fromJson(Map<String, dynamic> json) {
    return PermitJurisdiction(
      id: json['id'] as String,
      jurisdictionName: json['jurisdiction_name'] as String,
      jurisdictionType: json['jurisdiction_type'] as String,
      stateCode: json['state_code'] as String,
      countyFips: json['county_fips'] as String?,
      cityName: json['city_name'] as String?,
      buildingDeptName: json['building_dept_name'] as String?,
      buildingDeptPhone: json['building_dept_phone'] as String?,
      buildingDeptUrl: json['building_dept_url'] as String?,
      onlineSubmissionUrl: json['online_submission_url'] as String?,
      avgTurnaroundDays: json['avg_turnaround_days'] as int?,
      notes: json['notes'] as String?,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jurisdiction_name': jurisdictionName,
    'jurisdiction_type': jurisdictionType,
    'state_code': stateCode,
    'county_fips': countyFips,
    'city_name': cityName,
    'building_dept_name': buildingDeptName,
    'building_dept_phone': buildingDeptPhone,
    'building_dept_url': buildingDeptUrl,
    'online_submission_url': onlineSubmissionUrl,
    'avg_turnaround_days': avgTurnaroundDays,
    'notes': notes,
    'verified': verified,
  };

  PermitJurisdiction copyWith({
    String? id,
    String? jurisdictionName,
    String? jurisdictionType,
    String? stateCode,
    String? countyFips,
    String? cityName,
    String? buildingDeptName,
    String? buildingDeptPhone,
    String? buildingDeptUrl,
    String? onlineSubmissionUrl,
    int? avgTurnaroundDays,
    String? notes,
    bool? verified,
    DateTime? createdAt,
  }) {
    return PermitJurisdiction(
      id: id ?? this.id,
      jurisdictionName: jurisdictionName ?? this.jurisdictionName,
      jurisdictionType: jurisdictionType ?? this.jurisdictionType,
      stateCode: stateCode ?? this.stateCode,
      countyFips: countyFips ?? this.countyFips,
      cityName: cityName ?? this.cityName,
      buildingDeptName: buildingDeptName ?? this.buildingDeptName,
      buildingDeptPhone: buildingDeptPhone ?? this.buildingDeptPhone,
      buildingDeptUrl: buildingDeptUrl ?? this.buildingDeptUrl,
      onlineSubmissionUrl: onlineSubmissionUrl ?? this.onlineSubmissionUrl,
      avgTurnaroundDays: avgTurnaroundDays ?? this.avgTurnaroundDays,
      notes: notes ?? this.notes,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, jurisdictionName, stateCode];
}
