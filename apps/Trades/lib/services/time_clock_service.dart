// ZAFTO Time Clock Service — Supabase Backend
// Rewritten: Sprint B1e (Session 43)
//
// Replaced Hive/Firestore offline-first with direct Supabase.
// Same provider names preserved for consumer compatibility.
// GPS tracking integration preserved via location_tracking_service.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_entry.dart';
import '../repositories/time_entry_repository.dart';
import 'auth_service.dart';
import 'location_tracking_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final timeEntryRepositoryProvider = Provider<TimeEntryRepository>((ref) {
  return TimeEntryRepository();
});

final timeClockServiceProvider = Provider<TimeClockService>((ref) {
  final repo = ref.watch(timeEntryRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return TimeClockService(repo, authState);
});

// Current active time entry (if clocked in)
final activeClockEntryProvider =
    StateNotifierProvider<ActiveClockEntryNotifier, ClockEntry?>((ref) {
  final service = ref.watch(timeClockServiceProvider);
  return ActiveClockEntryNotifier(service, ref);
});

// All time entries for current user
final userTimeEntriesProvider =
    StateNotifierProvider<TimeEntriesNotifier, AsyncValue<List<ClockEntry>>>(
        (ref) {
  final service = ref.watch(timeClockServiceProvider);
  return TimeEntriesNotifier(service, ref, forCurrentUserOnly: true);
});

// All time entries for company (admin view)
final companyTimeEntriesProvider =
    StateNotifierProvider<TimeEntriesNotifier, AsyncValue<List<ClockEntry>>>(
        (ref) {
  final service = ref.watch(timeClockServiceProvider);
  return TimeEntriesNotifier(service, ref, forCurrentUserOnly: false);
});

// Currently clocked in users (for dashboard)
final clockedInUsersProvider = Provider<List<ClockEntry>>((ref) {
  final entries = ref.watch(companyTimeEntriesProvider);
  return entries.maybeWhen(
    data: (list) => list.where((e) => e.isActive).toList(),
    orElse: () => [],
  );
});

// Time clock stats for dashboard
final timeClockStatsProvider = Provider<TimeClockStats>((ref) {
  final entries = ref.watch(companyTimeEntriesProvider);
  return entries.maybeWhen(
    data: (list) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEntries =
          list.where((e) => e.clockIn.isAfter(weekStart)).toList();

      return TimeClockStats(
        currentlyClockedIn: list.where((e) => e.isActive).length,
        totalHoursThisWeek:
            weekEntries.fold(0.0, (sum, e) => sum + (e.totalHours ?? 0)),
        pendingApproval:
            list.where((e) => e.status == ClockEntryStatus.completed).length,
      );
    },
    orElse: () => TimeClockStats.empty(),
  );
});

// Time entry count (for dashboard)
final timeEntryCountProvider = Provider<int>((ref) {
  final entries = ref.watch(companyTimeEntriesProvider);
  return entries.maybeWhen(data: (list) => list.length, orElse: () => 0);
});

// Kept for backward compat (sync is now a no-op with Supabase)
final timeClockSyncStatusProvider =
    StateProvider<TimeClockSyncStatus>((ref) => TimeClockSyncStatus.synced);

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

      if (entry.locationTrackingEnabled) {
        await _ref.read(locationTrackingServiceProvider).startTracking(
              timeEntryId: entry.id,
              config: entry.trackingConfig,
            );
      }

      _ref.read(companyTimeEntriesProvider.notifier).loadEntries();
      return entry;
    } catch (e) {
      rethrow;
    }
  }

  Future<ClockEntry?> clockOut(GpsLocation location, {String? notes}) async {
    if (state == null) return null;

    try {
      await _ref.read(locationTrackingServiceProvider).stopTracking();

      final entry = await _service.clockOut(state!, location, notes: notes);
      state = null;

      _ref.read(userTimeEntriesProvider.notifier).loadEntries();
      _ref.read(companyTimeEntriesProvider.notifier).loadEntries();
      return entry;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startBreak({String? reason}) async {
    if (state == null) return;

    final updatedEntry = await _service.startBreak(state!, reason: reason);
    state = updatedEntry;

    _ref.read(locationTrackingServiceProvider).pauseForBreak();
  }

  Future<void> endBreak() async {
    if (state == null) return;

    final updatedEntry = await _service.endBreak(state!);
    state = updatedEntry;

    await _ref
        .read(locationTrackingServiceProvider)
        .resumeAfterBreak(state!.id);
  }

  Future<void> refresh() async => _loadActiveEntry();
}

// ============================================================
// TIME ENTRIES NOTIFIER
// ============================================================

class TimeEntriesNotifier
    extends StateNotifier<AsyncValue<List<ClockEntry>>> {
  final TimeClockService _service;
  final Ref _ref;
  final bool forCurrentUserOnly;

  TimeEntriesNotifier(this._service, this._ref,
      {required this.forCurrentUserOnly})
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
}

// ============================================================
// TIME CLOCK SERVICE
// ============================================================

class TimeClockService {
  final TimeEntryRepository _repo;
  final AuthState _authState;

  TimeClockService(this._repo, this._authState);

  bool get _isLoggedIn =>
      _authState.isAuthenticated && _authState.hasCompany;
  String get _userId => _authState.user!.uid;
  String get _companyId => _authState.companyId!;

  // ==================== CLOCK IN/OUT ====================

  Future<ClockEntry?> getActiveEntry() async {
    if (!_isLoggedIn) return null;
    return _repo.getActiveEntry(_userId);
  }

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

    return _repo.createEntry(entry);
  }

  Future<ClockEntry> clockOut(
    ClockEntry entry,
    GpsLocation location, {
    String? notes,
  }) async {
    final updated = entry.clockOutEntry(location, notes: notes);
    return _repo.clockOut(entry.id, updated);
  }

  Future<ClockEntry> startBreak(ClockEntry entry, {String? reason}) async {
    final newBreak = BreakEntry(start: DateTime.now(), reason: reason);
    final updated = entry.copyWith(
      breaks: [...entry.breaks, newBreak],
      updatedAt: DateTime.now(),
    );
    return _repo.updateEntry(updated);
  }

  Future<ClockEntry> endBreak(ClockEntry entry) async {
    final breaks = entry.breaks.toList();
    if (breaks.isEmpty || !breaks.last.isActive) return entry;

    breaks[breaks.length - 1] = breaks.last.endBreak();

    final updated = entry.copyWith(
      breaks: breaks,
      updatedAt: DateTime.now(),
    );
    return _repo.updateEntry(updated);
  }

  // ==================== ENTRY MANAGEMENT ====================

  Future<List<ClockEntry>> getUserEntries() async {
    if (!_isLoggedIn) return [];
    return _repo.getEntriesForUser(_userId);
  }

  Future<List<ClockEntry>> getAllEntries() async {
    if (!_isLoggedIn) return [];
    return _repo.getEntries();
  }

  Future<List<ClockEntry>> getEntriesForRange(
      DateTime start, DateTime end) async {
    return _repo.getEntriesForRange(start, end);
  }

  Future<List<ClockEntry>> getEntriesForJob(String jobId) async {
    return _repo.getEntriesForJob(jobId);
  }

  Future<void> approveEntry(String entryId, String approvedBy) async {
    await _repo.updateStatus(
      entryId,
      status: ClockEntryStatus.approved,
      approvedBy: approvedBy,
    );
  }

  Future<void> rejectEntry(String entryId, String reason) async {
    // Get current entry to append rejection reason
    final entry = await _repo.getEntry(entryId);
    if (entry != null) {
      final updated = entry.copyWith(
        notes: '${entry.notes ?? ''}\nRejected: $reason'.trim(),
      );
      await _repo.updateEntry(updated);
    }
    await _repo.updateStatus(entryId, status: ClockEntryStatus.rejected);
  }

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
    return _repo.createEntry(entry);
  }

  /// Update location pings for an active entry
  Future<void> updatePings(ClockEntry entry) async {
    await _repo.updateLocationPings(
        entry.id, entry.buildLocationPingsPayload());
  }

  String generateId() => 'time_${DateTime.now().millisecondsSinceEpoch}';
}
