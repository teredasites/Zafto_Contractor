// ZAFTO Expense Repository — Supabase Backend
// CRUD for the expense_records table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/expense_record.dart';

class ExpenseRepository {
  static const _table = 'expense_records';

  // Create a new expense record.
  Future<ExpenseRecord> createExpense(ExpenseRecord expense) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(expense.toInsertJson())
          .select()
          .single();

      return ExpenseRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create expense record',
        userMessage: 'Could not save expense. Please try again.',
        cause: e,
      );
    }
  }

  // Get all expenses for a company with optional status filter.
  Future<List<ExpenseRecord>> getExpensesByCompany({
    int limit = 100,
    ExpenseStatus? status,
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null);

      if (status != null) {
        query = query.eq('status', status.dbValue);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => ExpenseRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load expenses',
        userMessage: 'Could not load expenses.',
        cause: e,
      );
    }
  }

  // Get all expenses for a specific job.
  Future<List<ExpenseRecord>> getExpensesByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ExpenseRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load expenses for job $jobId',
        userMessage: 'Could not load expenses.',
        cause: e,
      );
    }
  }

  // Get a single expense by ID.
  Future<ExpenseRecord?> getExpense(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ExpenseRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load expense $id',
        userMessage: 'Could not load expense.',
        cause: e,
      );
    }
  }

  // Update an expense record.
  Future<ExpenseRecord> updateExpense(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return ExpenseRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update expense',
        userMessage: 'Could not update expense.',
        cause: e,
      );
    }
  }

  // Soft delete an expense record.
  Future<void> deleteExpense(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete expense',
        userMessage: 'Could not delete expense.',
        cause: e,
      );
    }
  }
}
