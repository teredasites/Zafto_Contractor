/// ZAFTO Time Entry Model
/// Time Clock System for tracking employee hours
/// Session 23 - February 2026
/// Updated Session 28 - Continuous GPS Tracking

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a time entry
enum ClockEntryStatus {
  active,     // Currently clocked in
  completed,  // Clocked out, awaiting approval
  approved,   // Approved by admin
  rejected,   // Rejected (needs correction)
}

/// GPS location data
class GpsLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;  // Reverse geocoded address

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude];

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

  factory GpsLocation.fromGeoPoint(GeoPoint point) {
    return GpsLocation(
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);

  /// Calculate distance to another location in meters (Haversine formula)
  double distanceTo(GpsLocation other) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) * _cos(_toRadians(other.latitude)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * 3.14159265359 / 180;
  static double _sin(double x) => _sinTable(x);
  static double _cos(double x) => _sinTable(x + 1.5707963267949);
  static double _sqrt(double x) => x <= 0 ? 0 : _newtonSqrt(x);
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 1.5707963267949;
    if (x == 0 && y < 0) return -1.5707963267949;
    return 0;
  }
  static double _atan(double x) => x - (x*x*x)/3 + (x*x*x*x*x)/5;
  static double _sinTable(double x) {
    x = x % (2 * 3.14159265359);
    return x - (x*x*x)/6 + (x*x*x*x*x)/120 - (x*x*x*x*x*x*x)/5040;
  }
  static double _newtonSqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

// ============================================================
// CONTINUOUS GPS TRACKING
// ============================================================

/// A single GPS ping during an active time entry
/// Captured by background location service while clocked in
class LocationPing extends Equatable {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;       // GPS accuracy in meters
  final double? speed;          // Speed in m/s (if moving)
  final double? heading;        // Direction of travel in degrees
  final double? altitude;       // Altitude in meters
  final String? activity;       // 'stationary', 'walking', 'driving', 'unknown'
  final int? batteryLevel;      // Device battery % at time of ping
  final bool isCharging;        // Was device charging

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

  @override
  List<Object?> get props => [timestamp, latitude, longitude];

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

  /// Create from Geolocator Position
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

/// Configuration for GPS tracking behavior
class LocationTrackingConfig {
  /// Ping interval in seconds (default: 5 minutes = 300 seconds)
  final int pingIntervalSeconds;

  /// Minimum distance moved before recording a ping (meters)
  final double distanceFilterMeters;

  /// Accuracy level for GPS
  final String accuracyLevel; // 'high', 'balanced', 'low'

  /// Whether to track during breaks
  final bool trackDuringBreaks;

  /// Whether to show persistent notification
  final bool showNotification;

  /// Maximum pings to store locally before sync
  final int maxLocalPings;

  const LocationTrackingConfig({
    this.pingIntervalSeconds = 300,    // 5 minutes
    this.distanceFilterMeters = 50,    // 50 meters
    this.accuracyLevel = 'balanced',
    this.trackDuringBreaks = false,
    this.showNotification = true,
    this.maxLocalPings = 500,
  });

  /// Battery-friendly preset (15 min intervals, 100m filter)
  static const batterySaver = LocationTrackingConfig(
    pingIntervalSeconds: 900,
    distanceFilterMeters: 100,
    accuracyLevel: 'low',
  );

  /// Precision preset for fleet tracking (2 min intervals, 25m filter)
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
      distanceFilterMeters: (map['distanceFilterMeters'] as num?)?.toDouble() ?? 50,
      accuracyLevel: map['accuracyLevel'] as String? ?? 'balanced',
      trackDuringBreaks: map['trackDuringBreaks'] as bool? ?? false,
      showNotification: map['showNotification'] as bool? ?? true,
      maxLocalPings: map['maxLocalPings'] as int? ?? 500,
    );
  }
}

/// Time entry model for clock in/out tracking
class ClockEntry extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String? jobId;           // Optional - clocked into specific job

  // Clock times
  final DateTime clockIn;
  final DateTime? clockOut;

  // Locations
  final GpsLocation clockInLocation;
  final GpsLocation? clockOutLocation;

  // Continuous GPS Tracking (Session 28)
  final List<LocationPing> locationPings;  // Background GPS pings during shift
  final bool locationTrackingEnabled;       // Is tracking active for this entry
  final DateTime? lastPingAt;               // Last successful ping time
  final LocationTrackingConfig? trackingConfig;  // Tracking settings

  // Labor & Payroll (for ZAFTO Books integration)
  final double? hourlyRate;       // Employee's hourly rate for this entry
  final double? laborCost;        // Calculated: totalHours * hourlyRate
  final double? overtimeHours;    // Hours beyond 8hr/day or 40hr/week
  final double? overtimeRate;     // Overtime multiplier (1.5x, 2x, etc.)

  // Metadata
  final String? notes;
  final double? totalHours;       // Calculated on clock out
  final bool isManualEntry;       // Admin-created entry
  final String? approvedBy;       // User who approved
  final DateTime? approvedAt;
  final ClockEntryStatus status;

  // Break tracking
  final List<BreakEntry> breaks;

  // Mileage tracking (calculated from location pings)
  final double? totalMilesDriven;  // Calculated from pings where activity='driving'

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClockEntry({
    required this.id,
    required this.companyId,
    required this.userId,
    this.jobId,
    required this.clockIn,
    this.clockOut,
    required this.clockInLocation,
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

  @override
  List<Object?> get props => [id, companyId, userId, clockIn, clockOut, status, updatedAt];

  /// Check if currently clocked in
  bool get isActive => status == ClockEntryStatus.active && clockOut == null;

  /// Calculate elapsed time (for active entries)
  Duration get elapsed {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn);
  }

  /// Calculate total break time
  Duration get totalBreakTime {
    return breaks.fold(Duration.zero, (total, b) => total + b.duration);
  }

  /// Calculate worked time (elapsed minus breaks)
  Duration get workedTime {
    return elapsed - totalBreakTime;
  }

  /// Format elapsed time as string (e.g., "2h 30m")
  String get elapsedFormatted {
    final d = elapsed;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }

  /// Format worked time as string
  String get workedTimeFormatted {
    final d = workedTime;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }

  // ============================================================
  // GPS TRACKING HELPERS
  // ============================================================

  /// Get the most recent location (last ping, or clock out, or clock in)
  GpsLocation get currentLocation {
    if (locationPings.isNotEmpty) {
      return locationPings.last.toGpsLocation();
    }
    return clockOutLocation ?? clockInLocation;
  }

  /// Check if GPS tracking is stale (no ping in last 10 minutes)
  bool get isTrackingStale {
    if (!isActive || !locationTrackingEnabled) return false;
    final lastPing = lastPingAt ?? clockIn;
    return DateTime.now().difference(lastPing).inMinutes > 10;
  }

  /// Calculate total distance traveled from pings (in meters)
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

  /// Calculate total distance in miles
  double get totalDistanceMiles => totalDistanceMeters / 1609.34;

  /// Get ping count
  int get pingCount => locationPings.length;

  /// Check if currently on a break
  bool get isOnBreak => breaks.isNotEmpty && breaks.last.isActive;

  /// Calculate labor cost (if hourly rate is set)
  double? get calculatedLaborCost {
    if (hourlyRate == null || totalHours == null) return null;
    final regularHours = (totalHours! - (overtimeHours ?? 0)).clamp(0, double.infinity);
    final otHours = overtimeHours ?? 0;
    final otMultiplier = overtimeRate ?? 1.5;
    return (regularHours * hourlyRate!) + (otHours * hourlyRate! * otMultiplier);
  }

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'jobId': jobId,
      'clockIn': clockIn.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'clockInLocation': clockInLocation.toMap(),
      'clockOutLocation': clockOutLocation?.toMap(),
      // GPS tracking fields
      'locationPings': locationPings.map((p) => p.toMap()).toList(),
      'locationTrackingEnabled': locationTrackingEnabled,
      'lastPingAt': lastPingAt?.toIso8601String(),
      'trackingConfig': trackingConfig?.toMap(),
      // Labor fields
      'hourlyRate': hourlyRate,
      'laborCost': laborCost ?? calculatedLaborCost,
      'overtimeHours': overtimeHours,
      'overtimeRate': overtimeRate,
      // Original fields
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

  Map<String, dynamic> toJson() => toMap();

  factory ClockEntry.fromMap(Map<String, dynamic> map) {
    return ClockEntry(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      userId: map['userId'] as String,
      jobId: map['jobId'] as String?,
      clockIn: _parseDateTime(map['clockIn']),
      clockOut: map['clockOut'] != null ? _parseDateTime(map['clockOut']) : null,
      clockInLocation: GpsLocation.fromMap(map['clockInLocation'] as Map<String, dynamic>),
      clockOutLocation: map['clockOutLocation'] != null
          ? GpsLocation.fromMap(map['clockOutLocation'] as Map<String, dynamic>)
          : null,
      // GPS tracking fields
      locationPings: (map['locationPings'] as List<dynamic>?)
          ?.map((p) => LocationPing.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      locationTrackingEnabled: map['locationTrackingEnabled'] as bool? ?? true,
      lastPingAt: map['lastPingAt'] != null ? _parseDateTime(map['lastPingAt']) : null,
      trackingConfig: map['trackingConfig'] != null
          ? LocationTrackingConfig.fromMap(map['trackingConfig'] as Map<String, dynamic>)
          : null,
      // Labor fields
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      laborCost: (map['laborCost'] as num?)?.toDouble(),
      overtimeHours: (map['overtimeHours'] as num?)?.toDouble(),
      overtimeRate: (map['overtimeRate'] as num?)?.toDouble(),
      // Original fields
      notes: map['notes'] as String?,
      totalHours: (map['totalHours'] as num?)?.toDouble(),
      isManualEntry: map['isManualEntry'] as bool? ?? false,
      approvedBy: map['approvedBy'] as String?,
      approvedAt: map['approvedAt'] != null ? _parseDateTime(map['approvedAt']) : null,
      status: ClockEntryStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ClockEntryStatus.active,
      ),
      breaks: (map['breaks'] as List<dynamic>?)
          ?.map((b) => BreakEntry.fromMap(b as Map<String, dynamic>))
          .toList() ?? [],
      totalMilesDriven: (map['totalMilesDriven'] as num?)?.toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory ClockEntry.fromJson(Map<String, dynamic> json) => ClockEntry.fromMap(json);

  factory ClockEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClockEntry.fromMap({...data, 'id': doc.id});
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
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
      locationTrackingEnabled: locationTrackingEnabled ?? this.locationTrackingEnabled,
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

  /// Create a new clock-in entry
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
      id: 'time_${now.millisecondsSinceEpoch}',
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

  /// Add a location ping to the entry
  ClockEntry addPing(LocationPing ping) {
    return copyWith(
      locationPings: [...locationPings, ping],
      lastPingAt: ping.timestamp,
      updatedAt: DateTime.now(),
    );
  }

  /// Clock out an active entry
  ClockEntry clockOutEntry(GpsLocation location, {String? notes}) {
    final now = DateTime.now();
    final hours = now.difference(clockIn).inMinutes / 60.0;
    final breakHours = totalBreakTime.inMinutes / 60.0;
    final workedHours = hours - breakHours;

    return copyWith(
      clockOut: now,
      clockOutLocation: location,
      totalHours: workedHours,
      laborCost: hourlyRate != null ? workedHours * hourlyRate! : null,
      totalMilesDriven: totalDistanceMiles,
      status: ClockEntryStatus.completed,
      notes: notes ?? this.notes,
      updatedAt: now,
    );
  }

  /// Create a manual entry (admin)
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
      id: 'time_${now.millisecondsSinceEpoch}',
      companyId: companyId,
      userId: userId,
      jobId: jobId,
      clockIn: clockIn,
      clockOut: clockOut,
      clockInLocation: location,
      clockOutLocation: location,
      locationTrackingEnabled: false,  // Manual entries don't have GPS tracking
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

/// Break entry within a time entry
class BreakEntry extends Equatable {
  final DateTime start;
  final DateTime? end;
  final String? reason;  // 'lunch', 'personal', etc.

  const BreakEntry({
    required this.start,
    this.end,
    this.reason,
  });

  @override
  List<Object?> get props => [start, end];

  Duration get duration {
    if (end == null) return Duration.zero;
    return end!.difference(start);
  }

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

  BreakEntry endBreak() => BreakEntry(
    start: start,
    end: DateTime.now(),
    reason: reason,
  );
}
