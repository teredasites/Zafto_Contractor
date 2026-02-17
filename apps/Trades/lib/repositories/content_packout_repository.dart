// ZAFTO Content Pack-out Repository — Supabase Backend
// CRUD for content_packout_items table. Sprint REST1.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/content_packout_item.dart';

class ContentPackoutRepository {
  static const _table = 'content_packout_items';

  Future<ContentPackoutItem> create(ContentPackoutItem item) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(item.toInsertJson())
          .select()
          .single();

      return ContentPackoutItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create packout item',
        userMessage: 'Could not save item. Please try again.',
        cause: e,
      );
    }
  }

  Future<ContentPackoutItem> update(
      String id, ContentPackoutItem item) async {
    try {
      final response = await supabase
          .from(_table)
          .update(item.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return ContentPackoutItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update packout item',
        userMessage: 'Could not update item. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<ContentPackoutItem>> getByAssessment(
      String assessmentId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('fire_assessment_id', assessmentId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ContentPackoutItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load packout items',
        userMessage: 'Could not load items.',
        cause: e,
      );
    }
  }

  Future<List<ContentPackoutItem>> getByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ContentPackoutItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load packout items for job $jobId',
        userMessage: 'Could not load items.',
        cause: e,
      );
    }
  }

  Future<List<ContentPackoutItem>> getByBox(String boxNumber) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('box_number', boxNumber)
          .is_('deleted_at', null)
          .order('room_of_origin');

      return (response as List)
          .map((row) => ContentPackoutItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load items for box $boxNumber',
        userMessage: 'Could not load items.',
        cause: e,
      );
    }
  }

  Future<void> markReturned(String id, String returnedTo) async {
    try {
      await supabase.from(_table).update({
        'returned_at': DateTime.now().toUtc().toIso8601String(),
        'returned_to': returnedTo,
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to mark item as returned',
        userMessage: 'Could not update item.',
        cause: e,
      );
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete packout item',
        userMessage: 'Could not delete item.',
        cause: e,
      );
    }
  }

  /// Summary stats for a fire assessment
  Future<Map<String, dynamic>> getStats(String assessmentId) async {
    try {
      final items = await getByAssessment(assessmentId);
      final totalItems = items.length;
      final packed = items.where((i) => i.isPacked).length;
      final returned = items.where((i) => i.isReturned).length;
      final salvageable = items.where((i) => i.isSalvageable).length;
      final totalEstValue = items.fold<double>(
          0, (sum, i) => sum + (i.estimatedValue ?? 0));
      final totalReplacement = items.fold<double>(
          0, (sum, i) => sum + (i.replacementCost ?? 0));

      final byCategory = <String, int>{};
      for (final item in items) {
        byCategory[item.category.label] =
            (byCategory[item.category.label] ?? 0) + 1;
      }

      final byCondition = <String, int>{};
      for (final item in items) {
        byCondition[item.condition.label] =
            (byCondition[item.condition.label] ?? 0) + 1;
      }

      return {
        'total_items': totalItems,
        'packed': packed,
        'returned': returned,
        'salvageable': salvageable,
        'non_salvageable': totalItems - salvageable,
        'total_estimated_value': totalEstValue,
        'total_replacement_cost': totalReplacement,
        'by_category': byCategory,
        'by_condition': byCondition,
      };
    } catch (e) {
      throw DatabaseError(
        'Failed to compute packout stats',
        userMessage: 'Could not load stats.',
        cause: e,
      );
    }
  }
}
