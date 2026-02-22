// ZAFTO Realtor Team Repository — Supabase Backend
// CRUD for realtor_teams and realtor_team_members tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/realtor_team.dart';
import '../models/realtor_team_member.dart';

class RealtorTeamRepository {
  static const _teamsTable = 'realtor_teams';
  static const _membersTable = 'realtor_team_members';

  // ====== TEAMS ======

  Future<RealtorTeam> createTeam(RealtorTeam team) async {
    try {
      final response = await supabase
          .from(_teamsTable)
          .insert(team.toInsertJson())
          .select()
          .single();
      return RealtorTeam.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create team',
        userMessage: 'Could not create team. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<RealtorTeam>> getTeams() async {
    try {
      final response = await supabase
          .from(_teamsTable)
          .select()
          .isFilter('deleted_at', null)
          .order('name');
      return (response as List)
          .map((row) => RealtorTeam.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load teams',
        userMessage: 'Could not load teams.',
        cause: e,
      );
    }
  }

  Future<RealtorTeam?> getTeam(String id) async {
    try {
      final response = await supabase
          .from(_teamsTable)
          .select()
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (response == null) return null;
      return RealtorTeam.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load team $id',
        userMessage: 'Could not load team.',
        cause: e,
      );
    }
  }

  Future<RealtorTeam> updateTeam(String id, RealtorTeam team) async {
    try {
      final response = await supabase
          .from(_teamsTable)
          .update(team.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return RealtorTeam.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update team',
        userMessage: 'Could not update team. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> softDeleteTeam(String id) async {
    try {
      await supabase.from(_teamsTable).update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete team $id',
        userMessage: 'Could not delete team.',
        cause: e,
      );
    }
  }

  // ====== MEMBERS ======

  Future<RealtorTeamMember> addMember(RealtorTeamMember member) async {
    try {
      final response = await supabase
          .from(_membersTable)
          .insert(member.toInsertJson())
          .select()
          .single();
      return RealtorTeamMember.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add team member',
        userMessage: 'Could not add member. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<RealtorTeamMember>> getTeamMembers(String teamId) async {
    try {
      final response = await supabase
          .from(_membersTable)
          .select()
          .eq('team_id', teamId)
          .isFilter('deleted_at', null)
          .order('joined_at');
      return (response as List)
          .map((row) => RealtorTeamMember.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load team members',
        userMessage: 'Could not load team members.',
        cause: e,
      );
    }
  }

  Future<RealtorTeamMember?> getUserTeam(String userId) async {
    try {
      final response = await supabase
          .from(_membersTable)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (response == null) return null;
      return RealtorTeamMember.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load user team membership',
        userMessage: 'Could not load team membership.',
        cause: e,
      );
    }
  }

  Future<RealtorTeamMember> updateMember(
      String id, RealtorTeamMember member) async {
    try {
      final response = await supabase
          .from(_membersTable)
          .update(member.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return RealtorTeamMember.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update team member',
        userMessage: 'Could not update member. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> removeMember(String id) async {
    try {
      await supabase.from(_membersTable).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_active': false,
        'left_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to remove team member',
        userMessage: 'Could not remove member.',
        cause: e,
      );
    }
  }
}
