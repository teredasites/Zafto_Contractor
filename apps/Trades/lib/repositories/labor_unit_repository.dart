// ZAFTO Labor Unit Repository — Supabase Backend
// Created: DEPTH29 — Estimate Engine Overhaul
//
// CRUD for labor_units and crew_performance_log tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/labor_unit.dart';

class LaborUnitRepository {
  static const _table = 'labor_units';
  static const _perfTable = 'crew_performance_log';

  /// Fetch all active labor units, optionally filtered by trade
  Future<List<LaborUnit>> getUnits({String? trade}) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('trade')
          .order('category')
          .order('task_name');

      if (trade != null) {
        query = supabase
            .from(_table)
            .select()
            .is_('deleted_at', null)
            .eq('trade', trade)
            .order('trade')
            .order('category')
            .order('task_name');
      }

      final response = await query;
      return (response as List)
          .map((row) => LaborUnit.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load labor units',
        userMessage: 'Could not load labor database.',
        cause: e,
      );
    }
  }

  /// Get a single labor unit by ID
  Future<LaborUnit> getUnit(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .single();

      return LaborUnit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load labor unit $id',
        userMessage: 'Could not load labor unit details.',
        cause: e,
      );
    }
  }

  /// Add a company-specific labor unit
  Future<LaborUnit> addUnit(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(data)
          .select()
          .single();

      return LaborUnit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add labor unit',
        userMessage: 'Could not add labor unit. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a labor unit
  Future<LaborUnit> updateUnit(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return LaborUnit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update labor unit',
        userMessage: 'Could not update labor unit. Please try again.',
        cause: e,
      );
    }
  }

  /// Soft delete a labor unit
  Future<void> deleteUnit(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete labor unit',
        userMessage: 'Could not remove labor unit.',
        cause: e,
      );
    }
  }

  // ==================== CREW PERFORMANCE ====================

  /// Log a crew performance entry
  Future<CrewPerformanceEntry> logPerformance(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_perfTable)
          .insert(data)
          .select()
          .single();

      return CrewPerformanceEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to log performance',
        userMessage: 'Could not save performance data.',
        cause: e,
      );
    }
  }

  /// Get performance history, optionally filtered by trade
  Future<List<CrewPerformanceEntry>> getPerformance({
    String? trade,
    int limit = 100,
  }) async {
    try {
      var query = supabase
          .from(_perfTable)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (trade != null) {
        query = supabase
            .from(_perfTable)
            .select()
            .eq('trade', trade)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((row) => CrewPerformanceEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load performance data',
        userMessage: 'Could not load crew performance history.',
        cause: e,
      );
    }
  }

  /// Get crew performance multiplier via RPC
  Future<double> getPerformanceMultiplier(String companyId, String trade) async {
    try {
      final response = await supabase.rpc('fn_crew_performance_multiplier', params: {
        'p_company_id': companyId,
        'p_trade': trade,
      });

      return (response as num?)?.toDouble() ?? 1.0;
    } catch (e) {
      // Default to 1.0 on error — graceful degradation
      return 1.0;
    }
  }
}
