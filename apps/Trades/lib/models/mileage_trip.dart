// ZAFTO Mileage Trip Model — Supabase Backend
// Maps to `mileage_trips` table in Supabase PostgreSQL.
// Stores GPS-tracked trips for tax deduction / reimbursement.

class MileageTrip {
  final String id;
  final String companyId;
  final String? jobId;
  final String userId;
  final String? startAddress;
  final String? endAddress;
  final double distanceMiles;
  final double? startOdometer;
  final double? endOdometer;
  final String? purpose;
  final Map<String, dynamic> routeData;
  final DateTime tripDate;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final int? durationSeconds;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const MileageTrip({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.userId = '',
    this.startAddress,
    this.endAddress,
    this.distanceMiles = 0,
    this.startOdometer,
    this.endOdometer,
    this.purpose,
    this.routeData = const {},
    required this.tripDate,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.durationSeconds,
    this.deletedAt,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'user_id': userId,
        if (startAddress != null) 'start_address': startAddress,
        if (endAddress != null) 'end_address': endAddress,
        'distance_miles': distanceMiles,
        if (startOdometer != null) 'start_odometer': startOdometer,
        if (endOdometer != null) 'end_odometer': endOdometer,
        if (purpose != null) 'purpose': purpose,
        'route_data': routeData,
        'trip_date': tripDate.toUtc().toIso8601String(),
        if (startLatitude != null) 'start_latitude': startLatitude,
        if (startLongitude != null) 'start_longitude': startLongitude,
        if (endLatitude != null) 'end_latitude': endLatitude,
        if (endLongitude != null) 'end_longitude': endLongitude,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      };

  factory MileageTrip.fromJson(Map<String, dynamic> json) {
    return MileageTrip(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      startAddress: json['start_address'] as String?,
      endAddress: json['end_address'] as String?,
      distanceMiles: (json['distance_miles'] as num?)?.toDouble() ?? 0,
      startOdometer: (json['start_odometer'] as num?)?.toDouble(),
      endOdometer: (json['end_odometer'] as num?)?.toDouble(),
      purpose: json['purpose'] as String?,
      routeData: (json['route_data'] as Map<String, dynamic>?) ?? const {},
      tripDate: _parseDate(json['trip_date']),
      startLatitude: (json['start_latitude'] as num?)?.toDouble(),
      startLongitude: (json['start_longitude'] as num?)?.toDouble(),
      endLatitude: (json['end_latitude'] as num?)?.toDouble(),
      endLongitude: (json['end_longitude'] as num?)?.toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      deletedAt: _parseOptionalDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  // IRS 2024 standard mileage rate
  static const double irsRate = 0.67;

  double get deductionAmount => distanceMiles * irsRate;

  Duration get duration => Duration(seconds: durationSeconds ?? 0);

  bool get hasStartLocation =>
      startLatitude != null && startLongitude != null;
  bool get hasEndLocation =>
      endLatitude != null && endLongitude != null;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
