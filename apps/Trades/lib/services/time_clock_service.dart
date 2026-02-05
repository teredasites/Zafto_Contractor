/// ZAFTO Time Clock Service - Offline-First with Cloud Sync
/// Session 23 - February 2026
/// Updated Session 28 - Continuous GPS Tracking Integration

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_entry.dart';
import 'auth_service.dart';
import 'location_tracking_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final timeClockServiceProvider = Provider<TimeClockService>((ref) {
  final authState = ref.watch(authStateProvider);
  return TimeClockService(authState);
});

/// Current active time entry (if clocked in)
final activeClockEntryProvider = StateNotifierProvider<ActiveClockEntryNotifier, ClockEntry?>((ref) {
  final service = ref.watch(timeClockServiceProvider);
  return ActiveClockEntryNotifier(service, ref);
});

/// All time entries for current user
final userTimeEntriesProvider = StateNotifierProvider<TimeEntriesNotifier, AsyncValue<List<ClockEntry>>>((ref) {
  final service = ref.watch(timeClockServiceProvider);
  return TimeEntriesNotifier(service, ref, forCurrentUserOnly: true);
});

/// All time entries for company (admin view)
final companyTimeEntriesProvider = StateNotifierProvider<TimeEntriesNotifier, AsyncValue<List<ClockEntry>>>((ref) {
  final service = ref.watch(timeClockServiceProvider);
  return TimeEntriesNotifier(service, ref, forCurrentUserOnly: false);
});

/// Currently clocked in users (for dashboard)
final clockedInUsersProvider = Provider<List<ClockEntry>>((ref) {
  final entries = ref.watch(companyTimeEntriesProvider);
  return entries.maybeWhen(
    data: (list) => list.where((e) => e.isActive).toList(),
    orElse: () => [],
  );
});

/// Time clock stats for dashboard
final timeClockStatsProvider = Provider<TimeClockStats>((ref) {
  final entries = ref.watch(companyTimeEntriesProvider);
  return entries.maybeWhen(
    data: (list) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEntries = list.where((e) => e.clockIn.isAfter(weekStart)).toList();

      return TimeClockStats(
        currentlyClockedIn: list.where((e) => e.isActive).length,
        totalHoursThisWeek: weekEntries.fold(0.0, (sum, e) => sum + (e.totalHours ?? 0)),
        pendingApproval: list.where((e) => e.status == ClockEntryStatus.completed).length,
      );
    },
    orElse: () => TimeClockStats.empty(),
  );
});

/// Sync status for time entries
final timeClockSyncStatusProvider = StateProvider<TimeClockSyncStatus>((ref) => TimeClockSyncStatus.idle);

enum TimeClockSyncStatus { idle, syncing, synced, error, offline }

// ============================================================
// STATS MODEL
// ============================================================

class TimeClockStats {
  final int currentlyClockedIn;
  final double totalHoursThisWeek;
  final int pendingApproval;

  const TimeClockStats({
    required this.currentlyClockedIn,
    required this.totalHoursThisWeek,
    required this.pendingApproval,
  });

  factory TimeClockStats.empty() => const TimeClockStats(
    currentlyClockedIn: 0,
    totalHoursThisWeek: 0,
    pendingApproval: 0,
  );
}

// ============================================================
// ACTIVE TIME ENTRY NOTIFIER
// ============================================================

class ActiveClockEntryNotifier extends StateNotifier<ClockEntry?> {
  final TimeClockService _service;
  final Ref _ref;

  ActiveClockEntryNotifier(this._service, this._ref) : super(null) {
    _loadActiveEntry();
  }

  Future<void> _loadActiveEntry() async {
    try {
      final entry = await _service.getActiveEntry();
      state = entry;

      // Resume location tracking if entry is active
      if (entry != null && entry.isActive && entry.locationTrackingEnabled) {
        _ref.read(locationTrackingServiceProvider).startTracking(
          timeEntryId: entry.id,
          config: entry.trackingConfig,
        );
      }
    } catch (_) {
      state = null;
    }
  }

  /// Clock in - starts GPS tracking
  Future<ClockEntry?> clockIn(
    GpsLocation location, {
    String? jobId,
    String? notes,
    double? hourlyRate,
    LocationTrackingConfig? trackingConfig,
  }) async {
    try {
      final entry = await _service.clockIn(
        location,
        jobId: jobId,
        notes: notes,
        hourlyRate: hourlyRate,
        trackingConfig: trackingConfig,
      );
      state = entry;

      // Start continuous GPS tracking
      if (entry.locationTrackingEnabled) {
        await _ref.read(locationTrackingServiceProvider).startTracking(
          timeEntryId: entry.id,
          config: entry.trackingConfig,
        );
      }

      // Refresh company entries
      _ref.read(companyTimeEntriesProvider.notifier).loadEntries();
      return entry;
    } catch (e) {
      rethrow;
    }
  }

  /// Clock out - stops GPS tracking
  Future<ClockEntry?> clockOut(GpsLocation location, {String? notes}) async {
    if (state == null) return null;

    try {
      // Stop location tracking first
      await _ref.read(locationTrackingServiceProvider).stopTracking();

      final entry = await _service.clockOut(state!, location, notes: notes);
      state = null;

      // Refresh entries
      _ref.read(userTimeEntriesProvider.notifier).loadEntries();
      _ref.read(companyTimeEntriesProvider.notifier).loadEntries();
      return entry;
    } catch (e) {
      rethrow;
    }
  }

  /// Start break - pauses GPS tracking if configured
  Future<void> startBreak({String? reason}) async {
    if (state == null) return;

    final updatedEntry = await _service.startBreak(state!, reason: reason);
    state = updatedEntry;

    // Pause GPS tracking during break
    _ref.read(locationTrackingServiceProvider).pauseForBreak();
  }

  /// End break - resumes GPS tracking
  Future<void> endBreak() async {
    if (state == null) return;

    final updatedEntry = await _service.endBreak(state!);
    state = updatedEntry;

    // Resume GPS tracking after break
    await _ref.read(locationTrackingServiceProvider).resumeAfterBreak(state!.id);
  }

  /// Refresh active entry
  Future<void> refresh() async {
    await _loadActiveEntry();
  }
}

// ============================================================
// TIME ENTRIES NOTIFIER
// ============================================================

class TimeEntriesNotifier extends StateNotifier<AsyncValue<List<ClockEntry>>> {
  final TimeClockService _service;
  final Ref _ref;
  final bool forCurrentUserOnly;

  TimeEntriesNotifier(this._service, this._ref, {required this.forCurrentUserOnly})
      : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = forCurrentUserOnly
          ? await _service.getUserEntries()
          : await _service.getAllEntries();
      state = AsyncValue.data(entries);

      // Sync in background
      _syncInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncInBackground() async {
    try {
      _ref.read(timeClockSyncStatusProvider.notifier).state = TimeClockSyncStatus.syncing;
      await _service.syncWithCloud();

      // Reload after sync
      final entries = forCurrentUserOnly
          ? await _service.getUserEntries()
          : await _service.getAllEntries();
      state = AsyncValue.data(entries);

      _ref.read(timeClockSyncStatusProvider.notifier).state = TimeClockSyncStatus.synced;
    } catch (e) {
      _ref.read(timeClockSyncStatusProvider.notifier).state = TimeClockSyncStatus.error;
    }
  }

  Future<void> approveEntry(String entryId, String approvedBy) async {
    await _service.approveEntry(entryId, approvedBy);
    await loadEntries();
  }

  Future<void> rejectEntry(String entryId, String reason) async {
    await _service.rejectEntry(entryId, reason);
    await loadEntries();
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }
}

// ============================================================
// TIME CLOCK SERVICE
// ============================================================

class TimeClockService {
  static const _boxName = 'time_entries';
  static const _syncMetaBox = 'time_entries_sync_meta';
  static const _activeEntryKey = 'active_entry';

  final AuthState _authState;

  TimeClockService(this._authState);

  bool get _isLoggedIn => _authState.isAuthenticated && _authState.hasCompany;
  String get _userId => _authState.user!.uid;
  String get _companyId => _authState.companyId!;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference get _collection =>
      _firestore.collection('companies').doc(_companyId).collection('timeEntries');

  // ==================== LOCAL STORAGE ====================

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  Future<Box<String>> _getSyncMetaBox() async {
    if (!Hive.isBoxOpen(_syncMetaBox)) {
      return await Hive.openBox<String>(_syncMetaBox);
    }
    return Hive.box<String>(_syncMetaBox);
  }

  // ==================== CLOCK IN/OUT ====================

  /// Get active time entry for current user
  Future<ClockEntry?> getActiveEntry() async {
    final box = await _getBox();
    final json = box.get('${_activeEntryKey}_$_userId');
    if (json == null) return null;
    return ClockEntry.fromJson(jsonDecode(json));
  }

  /// Clock in
  Future<ClockEntry> clockIn(
    GpsLocation location, {
    String? jobId,
    String? notes,
    double? hourlyRate,
    LocationTrackingConfig? trackingConfig,
  }) async {
    // Check if already clocked in
    final existing = await getActiveEntry();
    if (existing != null) {
      throw Exception('Already clocked in');
    }

    final entry = ClockEntry.clockIn(
      companyId: _companyId,
      userId: _userId,
      location: location,
      jobId: jobId,
      notes: notes,
      hourlyRate: hourlyRate,
      trackingConfig: trackingConfig,
    );

    // Save locally
    await _saveEntry(entry);
    await _setActiveEntry(entry);

    // Try cloud sync
    if (_isLoggedIn) {
      _trySyncEntry(entry);
    }

    return entry;
  }

  /// Clock out
  Future<ClockEntry> clockOut(ClockEntry entry, GpsLocation location, {String? notes}) async {
    final updatedEntry = entry.clockOutEntry(location, notes: notes);

    // Save locally
    await _saveEntry(updatedEntry);
    await _clearActiveEntry();

    // Try cloud sync
    if (_isLoggedIn) {
      _trySyncEntry(updatedEntry);
    }

    return updatedEntry;
  }

  /// Start a break
  Future<ClockEntry> startBreak(ClockEntry entry, {String? reason}) async {
    final newBreak = BreakEntry(start: DateTime.now(), reason: reason);
    final updatedEntry = entry.copyWith(
      breaks: [...entry.breaks, newBreak],
      updatedAt: DateTime.now(),
    );

    await _saveEntry(updatedEntry);
    await _setActiveEntry(updatedEntry);

    return updatedEntry;
  }

  /// End a break
  Future<ClockEntry> endBreak(ClockEntry entry) async {
    final breaks = entry.breaks.toList();
    if (breaks.isEmpty || !breaks.last.isActive) {
      return entry; // No active break
    }

    breaks[breaks.length - 1] = breaks.last.endBreak();

    final updatedEntry = entry.copyWith(
      breaks: breaks,
      updatedAt: DateTime.now(),
    );

    await _saveEntry(updatedEntry);
    await _setActiveEntry(updatedEntry);

    return updatedEntry;
  }

  // ==================== ENTRY MANAGEMENT ====================

  /// Save entry to local storage
  Future<void> _saveEntry(ClockEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, jsonEncode(entry.toJson()));
    await _markForSync(entry.id);
  }

  /// Set active entry
  Future<void> _setActiveEntry(ClockEntry entry) async {
    final box = await _getBox();
    await box.put('${_activeEntryKey}_$_userId', jsonEncode(entry.toJson()));
  }

  /// Clear active entry
  Future<void> _clearActiveEntry() async {
    final box = await _getBox();
    await box.delete('${_activeEntryKey}_$_userId');
  }

  /// Get all entries for current user
  Future<List<ClockEntry>> getUserEntries() async {
    final box = await _getBox();
    final entries = <ClockEntry>[];

    for (final key in box.keys) {
      if (key.toString().startsWith('active_entry_')) continue;

      final json = box.get(key);
      if (json != null) {
        try {
          final entry = ClockEntry.fromJson(jsonDecode(json));
          if (entry.userId == _userId) {
            entries.add(entry);
          }
        } catch (_) {}
      }
    }

    entries.sort((a, b) => b.clockIn.compareTo(a.clockIn));
    return entries;
  }

  /// Get all entries for company
  Future<List<ClockEntry>> getAllEntries() async {
    final box = await _getBox();
    final entries = <ClockEntry>[];

    for (final key in box.keys) {
      if (key.toString().startsWith('active_entry_')) continue;

      final json = box.get(key);
      if (json != null) {
        try {
          final entry = ClockEntry.fromJson(jsonDecode(json));
          if (entry.companyId == _companyId) {
            entries.add(entry);
          }
        } catch (_) {}
      }
    }

    entries.sort((a, b) => b.clockIn.compareTo(a.clockIn));
    return entries;
  }

  /// Get entries for a specific date range
  Future<List<ClockEntry>> getEntriesForRange(DateTime start, DateTime end) async {
    final all = await getAllEntries();
    return all.where((e) =>
      e.clockIn.isAfter(start) && e.clockIn.isBefore(end)
    ).toList();
  }

  /// Approve an entry
  Future<void> approveEntry(String entryId, String approvedBy) async {
    final box = await _getBox();
    final json = box.get(entryId);
    if (json == null) return;

    final entry = ClockEntry.fromJson(jsonDecode(json));
    final approved = entry.copyWith(
      status: ClockEntryStatus.approved,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
    );

    await _saveEntry(approved);
  }

  /// Reject an entry
  Future<void> rejectEntry(String entryId, String reason) async {
    final box = await _getBox();
    final json = box.get(entryId);
    if (json == null) return;

    final entry = ClockEntry.fromJson(jsonDecode(json));
    final rejected = entry.copyWith(
      status: ClockEntryStatus.rejected,
      notes: '${entry.notes ?? ''}\nRejected: $reason'.trim(),
    );

    await _saveEntry(rejected);
  }

  /// Create manual entry (admin)
  Future<ClockEntry> createManualEntry({
    required String userId,
    required DateTime clockIn,
    required DateTime clockOut,
    required GpsLocation location,
    String? jobId,
    String? notes,
  }) async {
    final entry = ClockEntry.manual(
      companyId: _companyId,
      userId: userId,
      clockIn: clockIn,
      clockOut: clockOut,
      location: location,
      jobId: jobId,
      notes: notes,
    );

    await _saveEntry(entry);

    if (_isLoggedIn) {
      _trySyncEntry(entry);
    }

    return entry;
  }

  // ==================== SYNC OPERATIONS ====================

  /// Mark an entry for sync
  Future<void> _markForSync(String entryId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$entryId', DateTime.now().toIso8601String());
  }

  /// Try to sync a single entry immediately
  Future<void> _trySyncEntry(ClockEntry entry) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      await _collection.doc(entry.id).set(entry.toMap());

      // Clear sync marker
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_${entry.id}');
    } catch (_) {
      // Sync failed - will retry later
    }
  }

  /// Full sync with cloud
  Future<void> syncWithCloud() async {
    if (!_isLoggedIn) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    final metaBox = await _getSyncMetaBox();
    final localBox = await _getBox();

    // 1. Push pending local changes to cloud
    final pendingKeys = metaBox.keys.where((k) => k.toString().startsWith('pending_'));
    for (final key in pendingKeys) {
      final entryId = key.toString().replaceFirst('pending_', '');
      final localJson = localBox.get(entryId);
      if (localJson != null) {
        try {
          final entry = ClockEntry.fromJson(jsonDecode(localJson));
          await _collection.doc(entryId).set(entry.toMap());
          await metaBox.delete(key);
        } catch (_) {}
      }
    }

    // 2. Pull cloud changes
    final lastSyncStr = metaBox.get('lastSync');
    final lastSync = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final snapshot = await _collection
        .where('updatedAt', isGreaterThan: lastSync.toIso8601String())
        .get();

    for (final doc in snapshot.docs) {
      final cloudEntry = ClockEntry.fromFirestore(doc);
      final localJson = localBox.get(cloudEntry.id);

      if (localJson != null) {
        // Conflict resolution: cloud wins if updated more recently
        final localEntry = ClockEntry.fromJson(jsonDecode(localJson));
        if (cloudEntry.updatedAt.isAfter(localEntry.updatedAt)) {
          await localBox.put(cloudEntry.id, jsonEncode(cloudEntry.toJson()));
        }
      } else {
        // New from cloud
        await localBox.put(cloudEntry.id, jsonEncode(cloudEntry.toJson()));
      }

      // Update active entry if this is it
      if (cloudEntry.isActive && cloudEntry.userId == _userId) {
        await _setActiveEntry(cloudEntry);
      }
    }

    // 3. Update last sync time
    await metaBox.put('lastSync', DateTime.now().toIso8601String());
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final metaBox = await _getSyncMetaBox();
    return metaBox.keys.where((k) => k.toString().startsWith('pending_')).length;
  }

  String generateId() => 'time_${DateTime.now().millisecondsSinceEpoch}';
}
