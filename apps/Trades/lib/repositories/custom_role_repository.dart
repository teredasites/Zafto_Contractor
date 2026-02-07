// ZAFTO Custom Role Repository — Supabase Backend
// CRUD for the custom_roles table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/custom_role.dart';

class CustomRoleRepository {
  static const _table = 'custom_roles';

  Future<CustomRole> createRole(CustomRole role) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(role.toInsertJson())
          .select()
          .single();
      return CustomRole.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create custom role',
        userMessage: 'Could not create role. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<CustomRole>> getRoles() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .order('name');
      return (response as List)
          .map((row) => CustomRole.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load custom roles',
        userMessage: 'Could not load roles.',
        cause: e,
      );
    }
  }

  Future<CustomRole?> getRole(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CustomRole.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load role $id',
        userMessage: 'Could not load role.',
        cause: e,
      );
    }
  }

  Future<CustomRole> updateRole(String id, CustomRole role) async {
    try {
      final response = await supabase
          .from(_table)
          .update(role.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return CustomRole.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update role',
        userMessage: 'Could not update role. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete role $id',
        userMessage: 'Could not delete role.',
        cause: e,
      );
    }
  }
}
