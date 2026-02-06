// ZAFTO Time Entry Model — Supabase Schema
// Rewritten: Sprint B1e (Session 43)
//
// Matches public.time_entries table (core columns).
// Extra GPS/tracking data stored in location_pings JSONB.
// Replaces old ClockEntry (Firebase/Equatable/Hive).

import 'dart:math' as math;

// ============================================================
// ENUMS
// ============================================================

enum ClockEntryStatus {
  active,
  completed,
  approved,
  rejected;
}

// ============================================================
// GPS LOCATION
// ============================================================

class GpsLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'address': address,
      };

  factory GpsLocation.fromMap(Map<String, dynamic> map) {
    return GpsLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      address: map['address'] as String?,
    );
  }

  // Haversine distance in meters
  double distanceTo(GpsLocation other) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(other.latitude - latitude);
    final dLon = _toRad(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(latitude)) *
            math.cos(_toRad(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

// ============================================================
// LOCATION PING
// ============================================================

class LocationPing {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final String? activity;
  final int? batteryLevel;
  final bool isCharging;

  const LocationPing({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.activity,
    this.batteryLevel,
    this.isCharging = false,
  });

  GpsLocation toGpsLocation() => GpsLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'altitude': altitude,
        'activity': activity,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
      };

  factory LocationPing.fromMap(Map<String, dynamic> map) {
    return LocationPing(
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      activity: map['activity'] as String?,
      batteryLevel: map['batteryLevel'] as int?,
      isCharging: map['isCharging'] as bool? ?? false,
    );
  }

  factory LocationPing.now({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    String? activity,
    int? batteryLevel,
    bool isCharging = false,
  }) {
    return LocationPing(
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      altitude: altitude,
      activity: activity,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
  }
}

// ============================================================
// LOCATION TRACKING CONFIG
// ============================================================

class LocationTrackingConfig {
  final int pingIntervalSeconds;
  final double distanceFilterMeters;
  final String accuracyLevel;
  final bool trackDuringBreaks;
  final bool showNotification;
  final int maxLocalPings;

  const LocationTrackingConfig({
    this.pingIntervalSeconds = 300,
    this.distanceFilterMeters = 50,
    this.accuracyLevel = 'balanced',
    this.trackDuringBreaks = false,
    this.showNotification = true,
    this.maxLocalPings = 500,
  });

  static const batterySaver = LocationTrackingConfig(
    pingIntervalSeconds: 900,
    distanceFilterMeters: 100,
    accuracyLevel: 'low',
  );

  static const precision = LocationTrackingConfig(
    pingIntervalSeconds: 120,
    distanceFilterMeters: 25,
    accuracyLevel: 'high',
  );

  Map<String, dynamic> toMap() => {
        'pingIntervalSeconds': pingIntervalSeconds,
        'distanceFilterMeters': distanceFilterMeters,
        'accuracyLevel': accuracyLevel,
        'trackDuringBreaks': trackDuringBreaks,
        'showNotification': showNotification,
        'maxLocalPings': maxLocalPings,
      };

  factory LocationTrackingConfig.fromMap(Map<String, dynamic> map) {
    return LocationTrackingConfig(
      pingIntervalSeconds: map['pingIntervalSeconds'] as int? ?? 300,
      distanceFilterMeters:
          (map['distanceFilterMeters'] as num?)?.toDouble() ?? 50,
      accuracyLevel: map['accuracyLevel'] as String? ?? 'balanced',
      trackDuringBreaks: map['trackDuringBreaks'] as bool? ?? false,
      showNotification: map['showNotification'] as bool? ?? true,
      maxLocalPings: map['maxLocalPings'] as int? ?? 500,
    );
  }
}

// ============================================================
// BREAK ENTRY
// ============================================================

class BreakEntry {
  final DateTime start;
  final DateTime? end;
  final String? reason;

  const BreakEntry({required this.start, this.end, this.reason});

  Duration get duration => end != null ? end!.difference(start) : Duration.zero;
  bool get isActive => end == null;

  Map<String, dynamic> toMap() => {
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'reason': reason,
      };

  factory BreakEntry.fromMap(Map<String, dynamic> map) {
    return BreakEntry(
      start: DateTime.parse(map['start'] as String),
      end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
      reason: map['reason'] as String?,
    );
  }

  BreakEntry endBreak() =>
      BreakEntry(start: start, end: DateTime.now(), reason: reason);
}

// ============================================================
// CLOCK ENTRY (TIME ENTRY)
// ============================================================

class ClockEntry {
  final String id;
  final String companyId;
  final String userId;
  final String? jobId;

  // Clock times
  final DateTime clockIn;
  final DateTime? clockOut;

  // Locations (stored in location_pings JSONB)
  final GpsLocation? clockInLocation;
  final GpsLocation? clockOutLocation;

  // GPS tracking (pings stored in location_pings JSONB)
  final List<LocationPing> locationPings;
  final bool locationTrackingEnabled;
  final DateTime? lastPingAt;
  final LocationTrackingConfig? trackingConfig;

  // Labor & Payroll
  final double? hourlyRate;
  final double? laborCost;
  final double? overtimeHours;
  final double? overtimeRate;

  // Metadata
  final String? notes;
  final double? totalHours;
  final bool isManualEntry;
  final String? approvedBy;
  final DateTime? approvedAt;
  final ClockEntryStatus status;

  // Break tracking (stored in location_pings JSONB)
  final List<BreakEntry> breaks;

  // Mileage
  final double? totalMilesDriven;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClockEntry({
    this.id = '',
    this.companyId = '',
    this.userId = '',
    this.jobId,
    required this.clockIn,
    this.clockOut,
    this.clockInLocation,
    this.clockOutLocation,
    this.locationPings = const [],
    this.locationTrackingEnabled = true,
    this.lastPingAt,
    this.trackingConfig,
    this.hourlyRate,
    this.laborCost,
    this.overtimeHours,
    this.overtimeRate,
    this.notes,
    this.totalHours,
    this.isManualEntry = false,
    this.approvedBy,
    this.approvedAt,
    this.status = ClockEntryStatus.active,
    this.breaks = const [],
    this.totalMilesDriven,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  bool get isActive => status == ClockEntryStatus.active && clockOut == null;

  Duration get elapsed {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn);
  }

  Duration get totalBreakTime =>
      breaks.fold(Duration.zero, (total, b) => total + b.duration);

  Duration get workedTime => elapsed - totalBreakTime;

  String get elapsedFormatted {
    final d = elapsed;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String get workedTimeFormatted {
    final d = workedTime;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  GpsLocation? get currentLocation {
    if (locationPings.isNotEmpty) return locationPings.last.toGpsLocation();
    return clockOutLocation ?? clockInLocation;
  }

  bool get isTrackingStale {
    if (!isActive || !locationTrackingEnabled) return false;
    final lastPing = lastPingAt ?? clockIn;
    return DateTime.now().difference(lastPing).inMinutes > 10;
  }

  double get totalDistanceMeters {
    if (locationPings.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < locationPings.length; i++) {
      final prev = locationPings[i - 1].toGpsLocation();
      final curr = locationPings[i].toGpsLocation();
      total += prev.distanceTo(curr);
    }
    return total;
  }

  double get totalDistanceMiles => totalDistanceMeters / 1609.34;
  int get pingCount => locationPings.length;
  bool get isOnBreak => breaks.isNotEmpty && breaks.last.isActive;

  double? get calculatedLaborCost {
    if (hourlyRate == null || totalHours == null) return null;
    final regularHours =
        (totalHours! - (overtimeHours ?? 0)).clamp(0, double.infinity);
    final otHours = overtimeHours ?? 0;
    final otMultiplier = overtimeRate ?? 1.5;
    return (regularHours * hourlyRate!) + (otHours * hourlyRate! * otMultiplier);
  }

  // ============================================================
  // SERIALIZATION — Supabase (snake_case)
  // ============================================================

  // Build the JSONB payload for location_pings column.
  // Stores pings + all extra fields that don't have dedicated DB columns.
  Map<String, dynamic> buildLocationPingsPayload() {
    return {
      'pings': locationPings.map((p) => p.toMap()).toList(),
      'clockInLocation': clockInLocation?.toMap(),
      'clockOutLocation': clockOutLocation?.toMap(),
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'trackingConfig': trackingConfig?.toMap(),
      'locationTrackingEnabled': locationTrackingEnabled,
      'lastPingAt': lastPingAt?.toIso8601String(),
      'isManualEntry': isManualEntry,
      'overtimeRate': overtimeRate,
      'totalMilesDriven': totalMilesDriven ?? totalDistanceMiles,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'user_id': userId,
      'job_id': jobId,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'break_minutes': totalBreakTime.inMinutes,
      'total_minutes':
          totalHours != null ? (totalHours! * 60).round() : null,
      'hourly_rate': hourlyRate,
      'labor_cost': laborCost ?? calculatedLaborCost,
      'overtime_minutes':
          overtimeHours != null ? (overtimeHours! * 60).round() : 0,
      'notes': notes,
      'location_pings': buildLocationPingsPayload(),
      'status': status.name,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'job_id': jobId,
      'clock_out': clockOut?.toIso8601String(),
      'break_minutes': totalBreakTime.inMinutes,
      'total_minutes':
          totalHours != null ? (totalHours! * 60).round() : null,
      'hourly_rate': hourlyRate,
      'labor_cost': laborCost ?? calculatedLaborCost,
      'overtime_minutes':
          overtimeHours != null ? (overtimeHours! * 60).round() : 0,
      'notes': notes,
      'location_pings': buildLocationPingsPayload(),
      'status': status.name,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  // Legacy camelCase JSON (for backward compat)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'jobId': jobId,
      'clockIn': clockIn.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'clockInLocation': clockInLocation?.toMap(),
      'clockOutLocation': clockOutLocation?.toMap(),
      'locationPings': locationPings.map((p) => p.toMap()).toList(),
      'locationTrackingEnabled': locationTrackingEnabled,
      'lastPingAt': lastPingAt?.toIso8601String(),
      'trackingConfig': trackingConfig?.toMap(),
      'hourlyRate': hourlyRate,
      'laborCost': laborCost ?? calculatedLaborCost,
      'overtimeHours': overtimeHours,
      'overtimeRate': overtimeRate,
      'notes': notes,
      'totalHours': totalHours,
      'isManualEntry': isManualEntry,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'status': status.name,
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'totalMilesDriven': totalMilesDriven ?? totalDistanceMiles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // ============================================================
  // DESERIALIZATION — dual format (snake_case + camelCase)
  // ============================================================

  factory ClockEntry.fromJson(Map<String, dynamic> json) {
    // Parse location_pings JSONB — could be structured object (Supabase)
    // or a simple list (legacy).
    final rawPings = json['location_pings'] ?? json['locationPings'];
    List<LocationPing> pings = [];
    GpsLocation? clockInLoc;
    GpsLocation? clockOutLoc;
    List<BreakEntry> breaksList = [];
    LocationTrackingConfig? trackingCfg;
    bool trackingEnabled = true;
    DateTime? lastPing;
    bool manualEntry = false;
    double? otRate;
    double? milesDriven;

    if (rawPings is Map<String, dynamic>) {
      // Structured JSONB from Supabase
      final pingList = rawPings['pings'] as List<dynamic>?;
      if (pingList != null) {
        pings = pingList
            .map((p) => LocationPing.fromMap(p as Map<String, dynamic>))
            .toList();
      }
      if (rawPings['clockInLocation'] != null) {
        clockInLoc =
            GpsLocation.fromMap(rawPings['clockInLocation'] as Map<String, dynamic>);
      }
      if (rawPings['clockOutLocation'] != null) {
        clockOutLoc =
            GpsLocation.fromMap(rawPings['clockOutLocation'] as Map<String, dynamic>);
      }
      final breakList = rawPings['breaks'] as List<dynamic>?;
      if (breakList != null) {
        breaksList = breakList
            .map((b) => BreakEntry.fromMap(b as Map<String, dynamic>))
            .toList();
      }
      if (rawPings['trackingConfig'] != null) {
        trackingCfg = LocationTrackingConfig.fromMap(
            rawPings['trackingConfig'] as Map<String, dynamic>);
      }
      trackingEnabled = rawPings['locationTrackingEnabled'] as bool? ?? true;
      if (rawPings['lastPingAt'] != null) {
        lastPing = DateTime.parse(rawPings['lastPingAt'] as String);
      }
      manualEntry = rawPings['isManualEntry'] as bool? ?? false;
      otRate = (rawPings['overtimeRate'] as num?)?.toDouble();
      milesDriven = (rawPings['totalMilesDriven'] as num?)?.toDouble();
    } else if (rawPings is List) {
      // Legacy format: plain array of pings
      pings = rawPings
          .map((p) => LocationPing.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    // Fall back to top-level fields for legacy camelCase format
    if (clockInLoc == null && json['clockInLocation'] != null) {
      clockInLoc =
          GpsLocation.fromMap(json['clockInLocation'] as Map<String, dynamic>);
    }
    if (clockOutLoc == null && json['clockOutLocation'] != null) {
      clockOutLoc =
          GpsLocation.fromMap(json['clockOutLocation'] as Map<String, dynamic>);
    }
    if (breaksList.isEmpty && json['breaks'] != null) {
      breaksList = (json['breaks'] as List<dynamic>)
          .map((b) => BreakEntry.fromMap(b as Map<String, dynamic>))
          .toList();
    }
    if (trackingCfg == null && json['trackingConfig'] != null) {
      trackingCfg = LocationTrackingConfig.fromMap(
          json['trackingConfig'] as Map<String, dynamic>);
    }

    // Parse total hours from total_minutes (DB) or totalHours (legacy)
    final totalMinutesRaw = json['total_minutes'] ?? json['totalMinutes'];
    final totalHoursLegacy = json['totalHours'];
    double? totalHrs;
    if (totalMinutesRaw != null) {
      totalHrs = (totalMinutesRaw as num).toDouble() / 60.0;
    } else if (totalHoursLegacy != null) {
      totalHrs = (totalHoursLegacy as num).toDouble();
    }

    // Parse overtime
    final otMinutesRaw = json['overtime_minutes'] ?? json['overtimeMinutes'];
    double? otHours;
    if (otMinutesRaw != null) {
      otHours = (otMinutesRaw as num).toDouble() / 60.0;
    } else if (json['overtimeHours'] != null) {
      otHours = (json['overtimeHours'] as num).toDouble();
    }

    return ClockEntry(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      jobId: (json['job_id'] ?? json['jobId']) as String?,
      clockIn: _parseDate(json['clock_in'] ?? json['clockIn']),
      clockOut: _parseOptionalDate(json['clock_out'] ?? json['clockOut']),
      clockInLocation: clockInLoc,
      clockOutLocation: clockOutLoc,
      locationPings: pings,
      locationTrackingEnabled:
          json['locationTrackingEnabled'] as bool? ?? trackingEnabled,
      lastPingAt: json['lastPingAt'] != null
          ? _parseDate(json['lastPingAt'])
          : lastPing,
      trackingConfig: trackingCfg,
      hourlyRate:
          ((json['hourly_rate'] ?? json['hourlyRate']) as num?)?.toDouble(),
      laborCost:
          ((json['labor_cost'] ?? json['laborCost']) as num?)?.toDouble(),
      overtimeHours: otHours,
      overtimeRate:
          json['overtimeRate'] != null
              ? (json['overtimeRate'] as num).toDouble()
              : otRate,
      notes: json['notes'] as String?,
      totalHours: totalHrs,
      isManualEntry: json['isManualEntry'] as bool? ?? manualEntry,
      approvedBy:
          (json['approved_by'] ?? json['approvedBy']) as String?,
      approvedAt: _parseOptionalDate(
          json['approved_at'] ?? json['approvedAt']),
      status: _parseStatus(json['status'] as String?),
      breaks: breaksList,
      totalMilesDriven:
          (json['totalMilesDriven'] as num?)?.toDouble() ?? milesDriven,
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  factory ClockEntry.fromMap(Map<String, dynamic> map) =>
      ClockEntry.fromJson(map);

  static ClockEntryStatus _parseStatus(String? s) {
    if (s == null) return ClockEntryStatus.active;
    return ClockEntryStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ClockEntryStatus.active,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ClockEntry copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? jobId,
    DateTime? clockIn,
    DateTime? clockOut,
    GpsLocation? clockInLocation,
    GpsLocation? clockOutLocation,
    List<LocationPing>? locationPings,
    bool? locationTrackingEnabled,
    DateTime? lastPingAt,
    LocationTrackingConfig? trackingConfig,
    double? hourlyRate,
    double? laborCost,
    double? overtimeHours,
    double? overtimeRate,
    String? notes,
    double? totalHours,
    bool? isManualEntry,
    String? approvedBy,
    DateTime? approvedAt,
    ClockEntryStatus? status,
    List<BreakEntry>? breaks,
    double? totalMilesDriven,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClockEntry(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      clockInLocation: clockInLocation ?? this.clockInLocation,
      clockOutLocation: clockOutLocation ?? this.clockOutLocation,
      locationPings: locationPings ?? this.locationPings,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      trackingConfig: trackingConfig ?? this.trackingConfig,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      laborCost: laborCost ?? this.laborCost,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      notes: notes ?? this.notes,
      totalHours: totalHours ?? this.totalHours,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
      breaks: breaks ?? this.breaks,
      totalMilesDriven: totalMilesDriven ?? this.totalMilesDriven,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  factory ClockEntry.clockIn({
    required String companyId,
    required String userId,
    required GpsLocation location,
    String? jobId,
    String? notes,
    double? hourlyRate,
    LocationTrackingConfig? trackingConfig,
  }) {
    final now = DateTime.now();
    return ClockEntry(
      companyId: companyId,
      userId: userId,
      jobId: jobId,
      clockIn: now,
      clockInLocation: location,
      locationTrackingEnabled: true,
      lastPingAt: now,
      trackingConfig: trackingConfig ?? const LocationTrackingConfig(),
      hourlyRate: hourlyRate,
      notes: notes,
      status: ClockEntryStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  ClockEntry addPing(LocationPing ping) {
    return copyWith(
      locationPings: [...locationPings, ping],
      lastPingAt: ping.timestamp,
      updatedAt: DateTime.now(),
    );
  }

  ClockEntry clockOutEntry(GpsLocation location, {String? notes}) {
    final now = DateTime.now();
    final hours = now.difference(clockIn).inMinutes / 60.0;
    final breakHours = totalBreakTime.inMinutes / 60.0;
    final workedHrs = hours - breakHours;

    return copyWith(
      clockOut: now,
      clockOutLocation: location,
      totalHours: workedHrs,
      laborCost: hourlyRate != null ? workedHrs * hourlyRate! : null,
      totalMilesDriven: totalDistanceMiles,
      status: ClockEntryStatus.completed,
      notes: notes ?? this.notes,
      updatedAt: now,
    );
  }

  factory ClockEntry.manual({
    required String companyId,
    required String userId,
    required DateTime clockIn,
    required DateTime clockOut,
    required GpsLocation location,
    String? jobId,
    String? notes,
    double? hourlyRate,
  }) {
    final now = DateTime.now();
    final hours = clockOut.difference(clockIn).inMinutes / 60.0;

    return ClockEntry(
      companyId: companyId,
      userId: userId,
      jobId: jobId,
      clockIn: clockIn,
      clockOut: clockOut,
      clockInLocation: location,
      clockOutLocation: location,
      locationTrackingEnabled: false,
      totalHours: hours,
      hourlyRate: hourlyRate,
      laborCost: hourlyRate != null ? hours * hourlyRate : null,
      isManualEntry: true,
      status: ClockEntryStatus.completed,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
