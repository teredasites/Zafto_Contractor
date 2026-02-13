// ZAFTO Floor Plan Snapshot Service — SK7
// Auto-snapshot plan_data JSONB on:
//   1. First edit of each session
//   2. Before change order applied
//   3. Manual "Save Version" button
// Max 50 snapshots per plan (oldest auto-pruned by repository).
// Debounce: no more than 1 auto-snapshot per 10 minutes.

import 'package:flutter/widgets.dart';

import '../models/floor_plan_elements.dart';
import '../repositories/floor_plan_repository.dart';

class FloorPlanSnapshotService {
  static const Duration _debounceInterval = Duration(minutes: 10);

  final FloorPlanRepository _repo;

  // Track last auto-snapshot per plan to enforce debounce
  final Map<String, DateTime> _lastAutoSnapshot = {};
  // Track session-first-edit per plan
  final Set<String> _sessionFirstEditDone = {};

  FloorPlanSnapshotService({FloorPlanRepository? repo})
      : _repo = repo ?? FloorPlanRepository();

  // ===========================================================================
  // AUTO-SNAPSHOT — called on first edit of session
  // ===========================================================================

  /// Call on every edit. Handles session-first-edit auto-snapshot + debounce.
  /// Non-blocking — failures are logged, not thrown.
  Future<void> onEdit({
    required String planId,
    required String companyId,
    required FloorPlanData currentData,
  }) async {
    // Session-first-edit: snapshot the BEFORE state
    if (!_sessionFirstEditDone.contains(planId)) {
      _sessionFirstEditDone.add(planId);
      await _createAutoSnapshot(
        planId: planId,
        companyId: companyId,
        data: currentData,
        reason: 'session_start',
        label: 'Session start',
      );
      return;
    }

    // Debounce: only auto-snapshot every 10 minutes
    final lastTime = _lastAutoSnapshot[planId];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < _debounceInterval) {
      return;
    }

    await _createAutoSnapshot(
      planId: planId,
      companyId: companyId,
      data: currentData,
      reason: 'auto',
    );
  }

  // ===========================================================================
  // MANUAL SNAPSHOT — user clicks "Save Version"
  // ===========================================================================

  /// Create a named snapshot (user-initiated).
  Future<FloorPlanSnapshot?> createManualSnapshot({
    required String planId,
    required String companyId,
    required FloorPlanData currentData,
    String? label,
  }) async {
    try {
      return await _repo.createSnapshot(
        floorPlanId: planId,
        companyId: companyId,
        planData: currentData,
        reason: 'manual',
        label: label ?? 'Manual save',
      );
    } catch (e) {
      debugPrint('Manual snapshot failed: $e');
      return null;
    }
  }

  // ===========================================================================
  // CHANGE ORDER SNAPSHOT — before applying a change order
  // ===========================================================================

  /// Snapshot before change order overwrites plan data.
  Future<FloorPlanSnapshot?> snapshotBeforeChangeOrder({
    required String planId,
    required String companyId,
    required FloorPlanData currentData,
    String? changeOrderId,
  }) async {
    try {
      return await _repo.createSnapshot(
        floorPlanId: planId,
        companyId: companyId,
        planData: currentData,
        reason: 'before_change_order',
        label: changeOrderId != null
            ? 'Before CO $changeOrderId'
            : 'Before change order',
      );
    } catch (e) {
      debugPrint('Change order snapshot failed: $e');
      return null;
    }
  }

  // ===========================================================================
  // RESTORE — overwrite current plan with snapshot
  // ===========================================================================

  /// Restore plan data from a snapshot. Creates a safety snapshot of current
  /// state before overwriting.
  Future<bool> restoreSnapshot({
    required String planId,
    required String companyId,
    required FloorPlanData currentData,
    required FloorPlanSnapshot snapshot,
  }) async {
    try {
      // Safety net: snapshot current state before overwrite
      await _repo.createSnapshot(
        floorPlanId: planId,
        companyId: companyId,
        planData: currentData,
        reason: 'before_restore',
        label: 'Before restore',
      );

      // Overwrite plan data with snapshot data
      await _repo.updatePlanData(
        planId: planId,
        data: snapshot.planData,
        syncVersion: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      return true;
    } catch (e) {
      debugPrint('Snapshot restore failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // QUERY
  // ===========================================================================

  /// Get all snapshots for a plan (newest first).
  Future<List<FloorPlanSnapshot>> getSnapshots(String planId) async {
    try {
      return await _repo.getSnapshots(planId);
    } catch (e) {
      debugPrint('Failed to fetch snapshots: $e');
      return [];
    }
  }

  /// Delete a specific snapshot.
  Future<void> deleteSnapshot(String snapshotId) async {
    try {
      await _repo.deleteSnapshot(snapshotId);
    } catch (e) {
      debugPrint('Failed to delete snapshot: $e');
    }
  }

  // ===========================================================================
  // INTERNAL
  // ===========================================================================

  Future<void> _createAutoSnapshot({
    required String planId,
    required String companyId,
    required FloorPlanData data,
    required String reason,
    String? label,
  }) async {
    try {
      await _repo.createSnapshot(
        floorPlanId: planId,
        companyId: companyId,
        planData: data,
        reason: reason,
        label: label,
      );
      _lastAutoSnapshot[planId] = DateTime.now();
    } catch (e) {
      debugPrint('Auto-snapshot failed ($reason): $e');
    }
  }

  /// Reset session tracking (call when app resumes or new session starts).
  void resetSession() {
    _sessionFirstEditDone.clear();
  }
}
