// ZAFTO Punch List Repository — Supabase Backend
// CRUD for the punch_list_items table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/punch_list_item.dart';

class PunchListRepository {
  static const _table = 'punch_list_items';

  // Create a new punch list item.
  Future<PunchListItem> createItem(PunchListItem item) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(item.toInsertJson())
          .select()
          .single();

      return PunchListItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create punch list item',
        userMessage: 'Could not save task. Please try again.',
        cause: e,
      );
    }
  }

  // Get all punch list items for a job (ordered by sort_order).
  Future<List<PunchListItem>> getItemsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => PunchListItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load punch list for job $jobId',
        userMessage: 'Could not load punch list.',
        cause: e,
      );
    }
  }

  // Get items by status.
  Future<List<PunchListItem>> getItemsByStatus(
      String jobId, PunchListStatus status) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('status', status.dbValue)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((row) => PunchListItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${status.label} items',
        userMessage: 'Could not load punch list.',
        cause: e,
      );
    }
  }

  // Update a punch list item.
  Future<PunchListItem> updateItem(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PunchListItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update punch list item',
        userMessage: 'Could not update task.',
        cause: e,
      );
    }
  }

  // Mark item as completed.
  Future<PunchListItem> completeItem(String id, String userId) async {
    try {
      final response = await supabase
          .from(_table)
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'completed_by_user_id': userId,
          })
          .eq('id', id)
          .select()
          .single();

      return PunchListItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to complete punch list item',
        userMessage: 'Could not mark task as completed.',
        cause: e,
      );
    }
  }

  // Reopen a completed/skipped item.
  Future<PunchListItem> reopenItem(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .update({
            'status': 'open',
            'completed_at': null,
            'completed_by_user_id': null,
          })
          .eq('id', id)
          .select()
          .single();

      return PunchListItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to reopen punch list item',
        userMessage: 'Could not reopen task.',
        cause: e,
      );
    }
  }

  // Delete a punch list item (hard delete — not soft).
  Future<void> deleteItem(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete punch list item',
        userMessage: 'Could not delete task.',
        cause: e,
      );
    }
  }

  // Count completed vs total for a job.
  Future<({int total, int completed})> getProgress(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('id, status')
          .eq('job_id', jobId);

      final items = response as List;
      final completed = items
          .where((r) =>
              r['status'] == 'completed' || r['status'] == 'skipped')
          .length;

      return (total: items.length, completed: completed);
    } catch (e) {
      throw DatabaseError(
        'Failed to get punch list progress',
        userMessage: 'Could not load progress.',
        cause: e,
      );
    }
  }
}
