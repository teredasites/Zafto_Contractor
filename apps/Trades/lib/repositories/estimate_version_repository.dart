// ZAFTO Estimate Version Repository — Supabase Backend
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Manages estimate version snapshots and change orders.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/estimate_version.dart';

class EstimateVersionRepository {
  static const _versionsTable = 'estimate_versions';
  static const _changeOrdersTable = 'estimate_change_orders';

  // ==================== VERSIONS ====================

  /// Get all versions for an estimate, newest first
  Future<List<EstimateVersion>> getVersions(String estimateId) async {
    try {
      final response = await supabase
          .from(_versionsTable)
          .select()
          .eq('estimate_id', estimateId)
          .order('version_number', ascending: false);

      return (response as List)
          .map((row) => EstimateVersion.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load estimate versions',
        userMessage: 'Could not load version history.',
        cause: e,
      );
    }
  }

  /// Create a version snapshot
  Future<EstimateVersion> createVersion(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_versionsTable)
          .insert(data)
          .select()
          .single();

      return EstimateVersion.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create version',
        userMessage: 'Could not save version. Please try again.',
        cause: e,
      );
    }
  }

  // ==================== CHANGE ORDERS ====================

  /// Get all change orders for an estimate
  Future<List<EstimateChangeOrder>> getChangeOrders(String estimateId) async {
    try {
      final response = await supabase
          .from(_changeOrdersTable)
          .select()
          .eq('estimate_id', estimateId)
          .is_('deleted_at', null)
          .order('change_order_number');

      return (response as List)
          .map((row) => EstimateChangeOrder.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load change orders',
        userMessage: 'Could not load change orders.',
        cause: e,
      );
    }
  }

  /// Create a change order
  Future<EstimateChangeOrder> createChangeOrder(
      Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_changeOrdersTable)
          .insert(data)
          .select()
          .single();

      return EstimateChangeOrder.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create change order',
        userMessage: 'Could not create change order. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a change order (status, approval, etc.)
  Future<EstimateChangeOrder> updateChangeOrder(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_changeOrdersTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return EstimateChangeOrder.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update change order',
        userMessage: 'Could not update change order. Please try again.',
        cause: e,
      );
    }
  }

  /// Approve a change order
  Future<EstimateChangeOrder> approveChangeOrder(String id) async {
    return updateChangeOrder(id, {
      'status': 'approved',
      'approved_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Reject a change order
  Future<EstimateChangeOrder> rejectChangeOrder(String id) async {
    return updateChangeOrder(id, {
      'status': 'rejected',
    });
  }

  /// Soft delete a change order
  Future<void> deleteChangeOrder(String id) async {
    try {
      await supabase
          .from(_changeOrdersTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete change order',
        userMessage: 'Could not remove change order.',
        cause: e,
      );
    }
  }
}
