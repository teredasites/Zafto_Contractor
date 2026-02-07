// ZAFTO Change Order Repository — Supabase Backend
// CRUD for the change_orders table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/change_order.dart';

class ChangeOrderRepository {
  static const _table = 'change_orders';

  // Create a new change order.
  Future<ChangeOrder> createChangeOrder(ChangeOrder order) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(order.toInsertJson())
          .select()
          .single();

      return ChangeOrder.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create change order',
        userMessage: 'Could not save change order. Please try again.',
        cause: e,
      );
    }
  }

  // Get all change orders for a job.
  Future<List<ChangeOrder>> getChangeOrdersByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ChangeOrder.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load change orders for job $jobId',
        userMessage: 'Could not load change orders.',
        cause: e,
      );
    }
  }

  // Get next change order number for a job (CO-001, CO-002, etc.).
  Future<String> getNextNumber(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('change_order_number')
          .eq('job_id', jobId)
          .order('created_at', ascending: false)
          .limit(1);

      final items = response as List;
      if (items.isEmpty) return 'CO-001';

      final lastNum = items.first['change_order_number'] as String? ?? 'CO-000';
      final numPart = int.tryParse(lastNum.replaceFirst('CO-', '')) ?? 0;
      return 'CO-${(numPart + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      // Fall back to CO-001 on error.
      return 'CO-001';
    }
  }

  // Update a change order.
  Future<ChangeOrder> updateChangeOrder(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return ChangeOrder.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update change order',
        userMessage: 'Could not update change order.',
        cause: e,
      );
    }
  }

  // Submit for approval (draft → pending_approval).
  Future<ChangeOrder> submitForApproval(String id) async {
    return updateChangeOrder(id, {'status': 'pending_approval'});
  }

  // Approve a change order.
  Future<ChangeOrder> approve(
      String id, String approvedByName, String? signatureId) async {
    final updates = <String, dynamic>{
      'status': 'approved',
      'approved_by_name': approvedByName,
      'approved_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (signatureId != null) updates['signature_id'] = signatureId;
    return updateChangeOrder(id, updates);
  }

  // Reject a change order.
  Future<ChangeOrder> reject(String id) async {
    return updateChangeOrder(id, {'status': 'rejected'});
  }

  // Void a change order.
  Future<ChangeOrder> voidOrder(String id) async {
    return updateChangeOrder(id, {'status': 'voided'});
  }

  // Delete a change order (hard delete — only drafts).
  Future<void> deleteChangeOrder(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete change order',
        userMessage: 'Could not delete change order.',
        cause: e,
      );
    }
  }

  // Count unresolved change orders for a job.
  Future<int> getUnresolvedCount(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('id')
          .eq('job_id', jobId)
          .inFilter('status', ['draft', 'pending_approval']);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Total approved amount for a job.
  Future<double> getApprovedTotal(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('amount')
          .eq('job_id', jobId)
          .eq('status', 'approved');

      final items = response as List;
      return items.fold<double>(
          0.0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));
    } catch (e) {
      return 0;
    }
  }
}
