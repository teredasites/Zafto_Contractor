// ZAFTO Realtor Team Provider — Riverpod providers for team management
// Connects realtor_team_repository to Flutter UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/realtor_team_repository.dart';
import '../models/realtor_team.dart';
import '../models/realtor_team_member.dart';

final realtorTeamRepoProvider =
    Provider((ref) => RealtorTeamRepository());

final realtorTeamsProvider =
    FutureProvider.autoDispose<List<RealtorTeam>>((ref) async {
  final repo = ref.watch(realtorTeamRepoProvider);
  return repo.getTeams();
});

final realtorTeamProvider =
    FutureProvider.autoDispose.family<RealtorTeam?, String>(
  (ref, teamId) async {
    final repo = ref.watch(realtorTeamRepoProvider);
    return repo.getTeam(teamId);
  },
);

final realtorTeamMembersProvider =
    FutureProvider.autoDispose.family<List<RealtorTeamMember>, String>(
  (ref, teamId) async {
    final repo = ref.watch(realtorTeamRepoProvider);
    return repo.getTeamMembers(teamId);
  },
);

final userTeamMembershipProvider =
    FutureProvider.autoDispose.family<RealtorTeamMember?, String>(
  (ref, userId) async {
    final repo = ref.watch(realtorTeamRepoProvider);
    return repo.getUserTeam(userId);
  },
);
