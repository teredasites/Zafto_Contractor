// ZAFTO Floor Plan Sync Service — Offline-First (SK7)
// Every edit saves to Hive immediately (zero-latency UX).
// Background sync pushes to Supabase when connectivity available.
// Conflict detection via sync_version. Queue pending changes while offline.

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/supabase_client.dart';
import '../models/floor_plan_elements.dart';
import '../repositories/floor_plan_repository.dart';

// =============================================================================
// SYNC STATUS
// =============================================================================

enum FloorPlanSyncState { idle, syncing, synced, error, offline }

class FloorPlanSyncStatus {
  final FloorPlanSyncState state;
  final int pendingChanges;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const FloorPlanSyncStatus({
    this.state = FloorPlanSyncState.idle,
    this.pendingChanges = 0,
    this.errorMessage,
    this.lastSyncTime,
  });
}

// =============================================================================
// PENDING OPERATION
// =============================================================================

class _PendingOp {
  final String planId;
  final Map<String, dynamic> planDataJson;
  final int syncVersion;
  final DateTime queuedAt;
  final int retryCount;

  const _PendingOp({
    required this.planId,
    required this.planDataJson,
    required this.syncVersion,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'plan_data': planDataJson,
        'sync_version': syncVersion,
        'queued_at': queuedAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory _PendingOp.fromJson(Map<String, dynamic> json) => _PendingOp(
        planId: json['plan_id'] as String,
        planDataJson: json['plan_data'] as Map<String, dynamic>,
        syncVersion: json['sync_version'] as int,
        queuedAt: DateTime.parse(json['queued_at'] as String),
        retryCount: (json['retry_count'] as int?) ?? 0,
      );

  _PendingOp incrementRetry() => _PendingOp(
        planId: planId,
        planDataJson: planDataJson,
        syncVersion: syncVersion,
        queuedAt: queuedAt,
        retryCount: retryCount + 1,
      );
}

// =============================================================================
// SERVICE
// =============================================================================

class FloorPlanSyncService {
  static const String _cacheBox = 'floor_plans_cache';
  static const String _metaBox = 'floor_plans_sync_meta';
  static const int _maxRetries = 3;

  final FloorPlanRepository _repo;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final _statusController =
      StreamController<FloorPlanSyncStatus>.broadcast();
  bool _isOnline = true;

  FloorPlanSyncService({FloorPlanRepository? repo})
      : _repo = repo ?? FloorPlanRepository();

  Stream<FloorPlanSyncStatus> get statusStream => _statusController.stream;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  void initialize() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (_isOnline && wasOffline) {
      _flushPendingOperations();
    }

    if (!_isOnline) {
      _emitStatus(FloorPlanSyncState.offline);
    }
  }

  // =========================================================================
  // LOCAL CACHE (Hive)
  // =========================================================================

  /// Save plan data to local cache immediately (zero latency).
  Future<void> saveLocally({
    required String planId,
    required FloorPlanData data,
    required int syncVersion,
  }) async {
    final box = Hive.box<String>(_cacheBox);
    final entry = {
      'plan_data': data.toJson(),
      'sync_version': syncVersion,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    };
    await box.put(planId, jsonEncode(entry));
  }

  /// Load plan data from local cache.
  FloorPlanData? loadFromCache(String planId) {
    final box = Hive.box<String>(_cacheBox);
    final raw = box.get(planId);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FloorPlanData.fromJson(
          json['plan_data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Get cached sync version for conflict detection.
  int getCachedSyncVersion(String planId) {
    final box = Hive.box<String>(_cacheBox);
    final raw = box.get(planId);
    if (raw == null) return 0;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (json['sync_version'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // =========================================================================
  // SYNC TO SERVER
  // =========================================================================

  /// Save to cache + queue for server sync. Returns immediately.
  Future<void> saveAndSync({
    required String planId,
    required FloorPlanData data,
    required int syncVersion,
  }) async {
    // 1. Save locally (instant UX)
    await saveLocally(planId: planId, data: data, syncVersion: syncVersion);

    // 2. Queue for server push
    await _queueOperation(planId, data, syncVersion);

    // 3. Try to push immediately if online
    if (_isOnline) {
      await _flushPendingOperations();
    } else {
      _emitStatus(FloorPlanSyncState.offline);
    }
  }

  Future<void> _queueOperation(
      String planId, FloorPlanData data, int syncVersion) async {
    final metaBox = Hive.box<String>(_metaBox);
    final op = _PendingOp(
      planId: planId,
      planDataJson: data.toJson(),
      syncVersion: syncVersion,
      queuedAt: DateTime.now().toUtc(),
    );
    // Use planId as key — later ops overwrite earlier ones (last write wins)
    await metaBox.put('pending_$planId', jsonEncode(op.toJson()));
    _emitPendingCount();
  }

  Future<void> _flushPendingOperations() async {
    final metaBox = Hive.box<String>(_metaBox);
    final pendingKeys =
        metaBox.keys.where((k) => k.toString().startsWith('pending_')).toList();

    if (pendingKeys.isEmpty) {
      _emitStatus(FloorPlanSyncState.synced);
      return;
    }

    _emitStatus(FloorPlanSyncState.syncing);

    for (final key in pendingKeys) {
      final raw = metaBox.get(key);
      if (raw == null) continue;

      try {
        final op = _PendingOp.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);

        // Check for conflict: fetch server version
        final serverPlan = await _repo.getPlan(op.planId);
        if (serverPlan != null && serverPlan.syncVersion > op.syncVersion) {
          // Server has newer data — conflict
          // Strategy: server wins, discard local pending op
          // Update local cache with server data
          await saveLocally(
            planId: op.planId,
            data: serverPlan.planData,
            syncVersion: serverPlan.syncVersion,
          );
          await metaBox.delete(key);
          continue;
        }

        // Push to server
        await _repo.updatePlanData(
          planId: op.planId,
          data: FloorPlanData.fromJson(op.planDataJson),
          syncVersion: op.syncVersion,
        );

        // Success — remove from queue
        await metaBox.delete(key);
        _emitStatus(FloorPlanSyncState.synced);
      } catch (e) {
        final op = _PendingOp.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        if (op.retryCount >= _maxRetries) {
          // Give up on this op
          await metaBox.delete(key);
          _emitStatus(FloorPlanSyncState.error,
              error: 'Sync failed after $_maxRetries retries');
        } else {
          // Increment retry count
          final updated = op.incrementRetry();
          await metaBox.put(key, jsonEncode(updated.toJson()));
        }
      }
    }

    _emitPendingCount();
  }

  // =========================================================================
  // STATUS HELPERS
  // =========================================================================

  void _emitStatus(FloorPlanSyncState state, {String? error}) {
    final metaBox = Hive.box<String>(_metaBox);
    final pendingCount =
        metaBox.keys.where((k) => k.toString().startsWith('pending_')).length;

    _statusController.add(FloorPlanSyncStatus(
      state: state,
      pendingChanges: pendingCount,
      errorMessage: error,
      lastSyncTime:
          state == FloorPlanSyncState.synced ? DateTime.now() : null,
    ));
  }

  void _emitPendingCount() {
    final metaBox = Hive.box<String>(_metaBox);
    final pendingCount =
        metaBox.keys.where((k) => k.toString().startsWith('pending_')).length;

    _statusController.add(FloorPlanSyncStatus(
      state: pendingCount > 0
          ? (_isOnline
              ? FloorPlanSyncState.syncing
              : FloorPlanSyncState.offline)
          : FloorPlanSyncState.synced,
      pendingChanges: pendingCount,
    ));
  }
}
