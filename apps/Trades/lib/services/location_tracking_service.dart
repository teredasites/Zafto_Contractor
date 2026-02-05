/// ZAFTO Background Location Tracking Service
/// Continuous GPS tracking for field technicians during active shifts
/// Session 28 - February 2026
///
/// PRIVACY NOTICE: This service tracks employee location ONLY while clocked in.
/// - Tracking starts on clock-in, stops on clock-out
/// - Employees are notified via persistent notification
/// - Location data is company-scoped and only visible to authorized managers
/// - Data retention policy applies (configurable by company)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:battery_plus/battery_plus.dart';

import '../models/time_entry.dart';
import 'time_clock_service.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  final authState = ref.watch(authStateProvider);
  final timeClockService = ref.watch(timeClockServiceProvider);
  return LocationTrackingService(authState, timeClockService);
});

/// Whether location tracking is currently active
final isTrackingActiveProvider = StateProvider<bool>((ref) => false);

/// Last known location
final lastKnownLocationProvider = StateProvider<LocationPing?>((ref) => null);

/// Tracking error state
final trackingErrorProvider = StateProvider<String?>((ref) => null);

/// Pending pings count (not yet synced)
final pendingPingsCountProvider = StateProvider<int>((ref) => 0);

// ============================================================
// SERVICE
// ============================================================

class LocationTrackingService {
  static const _pingsBoxName = 'location_pings';
  static const _syncMetaBox = 'location_pings_sync_meta';

  final AuthState _authState;
  final TimeClockService _timeClockService;
  final Battery _battery = Battery();

  Timer? _pingTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  LocationTrackingConfig _config = const LocationTrackingConfig();

  LocationTrackingService(this._authState, this._timeClockService);

  bool get isTracking => _isTracking;
  bool get _isLoggedIn => _authState.isAuthenticated && _authState.hasCompany;
  String get _userId => _authState.user!.uid;
  String get _companyId => _authState.companyId!;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ==================== LIFECYCLE ====================

  /// Start continuous GPS tracking for an active time entry
  Future<void> startTracking({
    required String timeEntryId,
    LocationTrackingConfig? config,
  }) async {
    if (_isTracking) {
      debugPrint('[LocationTracking] Already tracking, ignoring start request');
      return;
    }

    _config = config ?? const LocationTrackingConfig();

    // Check permissions
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Verify we have an active time entry
    final activeEntry = await _timeClockService.getActiveEntry();
    if (activeEntry == null || activeEntry.id != timeEntryId) {
      throw Exception('No matching active time entry');
    }

    _isTracking = true;
    debugPrint('[LocationTracking] Starting continuous tracking for entry: $timeEntryId');

    // Initial ping immediately
    await _captureAndStorePing(timeEntryId);

    // Set up periodic timer based on config
    _pingTimer = Timer.periodic(
      Duration(seconds: _config.pingIntervalSeconds),
      (_) => _captureAndStorePing(timeEntryId),
    );

    // Also listen to significant location changes (movement-based)
    _startPositionStream(timeEntryId);
  }

  /// Stop GPS tracking (called on clock-out)
  Future<void> stopTracking() async {
    debugPrint('[LocationTracking] Stopping continuous tracking');

    _pingTimer?.cancel();
    _pingTimer = null;

    await _positionStream?.cancel();
    _positionStream = null;

    _isTracking = false;

    // Final sync attempt
    await syncPings();
  }

  /// Pause tracking during breaks (if config says to)
  void pauseForBreak() {
    if (!_config.trackDuringBreaks) {
      _pingTimer?.cancel();
      _positionStream?.cancel();
      debugPrint('[LocationTracking] Paused for break');
    }
  }

  /// Resume tracking after break
  Future<void> resumeAfterBreak(String timeEntryId) async {
    if (!_config.trackDuringBreaks && _isTracking) {
      _pingTimer = Timer.periodic(
        Duration(seconds: _config.pingIntervalSeconds),
        (_) => _captureAndStorePing(timeEntryId),
      );
      _startPositionStream(timeEntryId);
      debugPrint('[LocationTracking] Resumed after break');
    }
  }

  // ==================== PERMISSIONS ====================

  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationTracking] Location services disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationTracking] Permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationTracking] Permission permanently denied');
      return false;
    }

    // For continuous tracking, we need "always" permission on mobile
    // "whileInUse" works but may be less reliable when app is backgrounded
    return true;
  }

  // ==================== POSITION CAPTURE ====================

  void _startPositionStream(String timeEntryId) {
    final accuracy = _config.accuracyLevel == 'high'
        ? LocationAccuracy.high
        : _config.accuracyLevel == 'low'
            ? LocationAccuracy.low
            : LocationAccuracy.medium;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: _config.distanceFilterMeters.round(),
      ),
    ).listen(
      (Position position) {
        _onPositionUpdate(timeEntryId, position);
      },
      onError: (error) {
        debugPrint('[LocationTracking] Stream error: $error');
      },
    );
  }

  void _onPositionUpdate(String timeEntryId, Position position) {
    // Movement detected - capture a ping
    _captureAndStorePing(timeEntryId, position: position);
  }

  Future<void> _captureAndStorePing(String timeEntryId, {Position? position}) async {
    try {
      // Get current position if not provided
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      // Get battery info
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      // Determine activity (simplified - could use activity_recognition package)
      String? activity;
      if (position.speed < 0.5) {
        activity = 'stationary';
      } else if (position.speed < 2.0) {
        activity = 'walking';
      } else {
        activity = 'driving';
      }

      final ping = LocationPing(
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        activity: activity,
        batteryLevel: batteryLevel,
        isCharging: batteryState == BatteryState.charging,
      );

      // Store locally
      await _storePingLocally(timeEntryId, ping);

      debugPrint('[LocationTracking] Captured ping: ${ping.latitude}, ${ping.longitude} ($activity)');

      // Try to sync if connected
      _trySyncPing(timeEntryId, ping);
    } catch (e) {
      debugPrint('[LocationTracking] Failed to capture ping: $e');
    }
  }

  // ==================== LOCAL STORAGE ====================

  Future<Box<String>> _getPingsBox() async {
    if (!Hive.isBoxOpen(_pingsBoxName)) {
      return await Hive.openBox<String>(_pingsBoxName);
    }
    return Hive.box<String>(_pingsBoxName);
  }

  Future<Box<String>> _getSyncMetaBox() async {
    if (!Hive.isBoxOpen(_syncMetaBox)) {
      return await Hive.openBox<String>(_syncMetaBox);
    }
    return Hive.box<String>(_syncMetaBox);
  }

  Future<void> _storePingLocally(String timeEntryId, LocationPing ping) async {
    final box = await _getPingsBox();

    // Key format: entryId_timestamp
    final key = '${timeEntryId}_${ping.timestamp.millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(ping.toMap()));

    // Mark for sync
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$key', DateTime.now().toIso8601String());

    // Prune old pings if we're over the limit
    await _pruneOldPings(timeEntryId);
  }

  Future<void> _pruneOldPings(String timeEntryId) async {
    final box = await _getPingsBox();
    final keys = box.keys
        .where((k) => k.toString().startsWith(timeEntryId))
        .toList()
      ..sort();

    // Keep only the most recent pings per config
    if (keys.length > _config.maxLocalPings) {
      final toDelete = keys.sublist(0, keys.length - _config.maxLocalPings);
      for (final key in toDelete) {
        await box.delete(key);
      }
      debugPrint('[LocationTracking] Pruned ${toDelete.length} old pings');
    }
  }

  /// Get all locally stored pings for an entry
  Future<List<LocationPing>> getLocalPings(String timeEntryId) async {
    final box = await _getPingsBox();
    final pings = <LocationPing>[];

    for (final key in box.keys) {
      if (key.toString().startsWith(timeEntryId)) {
        final json = box.get(key);
        if (json != null) {
          try {
            pings.add(LocationPing.fromMap(jsonDecode(json)));
          } catch (_) {}
        }
      }
    }

    pings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return pings;
  }

  /// Get count of pending (unsynced) pings
  Future<int> getPendingPingsCount() async {
    final metaBox = await _getSyncMetaBox();
    return metaBox.keys.where((k) => k.toString().startsWith('pending_')).length;
  }

  // ==================== CLOUD SYNC ====================

  Future<void> _trySyncPing(String timeEntryId, LocationPing ping) async {
    if (!_isLoggedIn) return;

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      // Add to the time entry's locationPings array in Firestore
      final docRef = _firestore
          .collection('companies')
          .doc(_companyId)
          .collection('timeEntries')
          .doc(timeEntryId);

      await docRef.update({
        'locationPings': FieldValue.arrayUnion([ping.toMap()]),
        'lastPingAt': ping.timestamp.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clear sync marker
      final key = '${timeEntryId}_${ping.timestamp.millisecondsSinceEpoch}';
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_$key');
    } catch (e) {
      debugPrint('[LocationTracking] Sync failed, will retry: $e');
    }
  }

  /// Full sync of all pending pings
  Future<void> syncPings() async {
    if (!_isLoggedIn) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    final metaBox = await _getSyncMetaBox();
    final pingsBox = await _getPingsBox();

    final pendingKeys = metaBox.keys
        .where((k) => k.toString().startsWith('pending_'))
        .toList();

    debugPrint('[LocationTracking] Syncing ${pendingKeys.length} pending pings');

    // Group pings by time entry ID for batch updates
    final pingsByEntry = <String, List<LocationPing>>{};

    for (final metaKey in pendingKeys) {
      final pingKey = metaKey.toString().replaceFirst('pending_', '');
      final entryId = pingKey.split('_').first;

      final json = pingsBox.get(pingKey);
      if (json != null) {
        try {
          final ping = LocationPing.fromMap(jsonDecode(json));
          pingsByEntry.putIfAbsent(entryId, () => []).add(ping);
        } catch (_) {}
      }
    }

    // Batch update each entry
    for (final entry in pingsByEntry.entries) {
      try {
        final docRef = _firestore
            .collection('companies')
            .doc(_companyId)
            .collection('timeEntries')
            .doc(entry.key);

        await docRef.update({
          'locationPings': FieldValue.arrayUnion(
            entry.value.map((p) => p.toMap()).toList(),
          ),
          'lastPingAt': entry.value.last.timestamp.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Clear sync markers for these pings
        for (final ping in entry.value) {
          final key = '${entry.key}_${ping.timestamp.millisecondsSinceEpoch}';
          await metaBox.delete('pending_$key');
        }
      } catch (e) {
        debugPrint('[LocationTracking] Batch sync failed for ${entry.key}: $e');
      }
    }

    debugPrint('[LocationTracking] Sync complete');
  }

  // ==================== CLEANUP ====================

  /// Clear all local pings for a completed entry
  Future<void> clearPingsForEntry(String timeEntryId) async {
    final box = await _getPingsBox();
    final metaBox = await _getSyncMetaBox();

    final keysToDelete = box.keys
        .where((k) => k.toString().startsWith(timeEntryId))
        .toList();

    for (final key in keysToDelete) {
      await box.delete(key);
      await metaBox.delete('pending_$key');
    }

    debugPrint('[LocationTracking] Cleared ${keysToDelete.length} pings for $timeEntryId');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
