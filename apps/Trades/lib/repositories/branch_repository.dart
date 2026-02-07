// ZAFTO Branch Repository — Supabase Backend
// CRUD for the branches table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/branch.dart';

class BranchRepository {
  static const _table = 'branches';

  Future<Branch> createBranch(Branch branch) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(branch.toInsertJson())
          .select()
          .single();
      return Branch.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create branch',
        userMessage: 'Could not create branch. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<Branch>> getBranches() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .order('name');
      return (response as List).map((row) => Branch.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load branches',
        userMessage: 'Could not load branches.',
        cause: e,
      );
    }
  }

  Future<List<Branch>> getActiveBranches() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('name');
      return (response as List).map((row) => Branch.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load active branches',
        userMessage: 'Could not load branches.',
        cause: e,
      );
    }
  }

  Future<Branch?> getBranch(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Branch.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load branch $id',
        userMessage: 'Could not load branch.',
        cause: e,
      );
    }
  }

  Future<Branch> updateBranch(String id, Branch branch) async {
    try {
      final response = await supabase
          .from(_table)
          .update(branch.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Branch.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update branch',
        userMessage: 'Could not update branch. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete branch $id',
        userMessage: 'Could not delete branch.',
        cause: e,
      );
    }
  }
}
