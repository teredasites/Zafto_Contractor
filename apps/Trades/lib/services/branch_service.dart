// ZAFTO Branch Service — Supabase Backend
// Providers and service for multi-location branch management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/branch.dart';
import '../repositories/branch_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

final branchServiceProvider = Provider<BranchService>((ref) {
  final repo = ref.watch(branchRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return BranchService(repo, authState);
});

// All branches for the company.
final companyBranchesProvider =
    FutureProvider.autoDispose<List<Branch>>((ref) async {
  final repo = ref.watch(branchRepositoryProvider);
  return repo.getActiveBranches();
});

// Current user's branch (queried from users table).
final currentBranchProvider =
    FutureProvider.autoDispose<Branch?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid;
  if (userId == null) return null;

  final userRow = await supabase
      .from('users')
      .select('branch_id')
      .eq('id', userId)
      .maybeSingle();
  final branchId = userRow?['branch_id'] as String?;
  if (branchId == null || branchId.isEmpty) return null;

  final repo = ref.watch(branchRepositoryProvider);
  return repo.getBranch(branchId);
});

// --- Service ---

class BranchService {
  final BranchRepository _repo;
  final AuthState _authState;

  BranchService(this._repo, this._authState);

  Future<Branch> createBranch({
    required String name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? managerUserId,
    String timezone = 'America/New_York',
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage branches.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final branch = Branch(
      companyId: companyId,
      name: name,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      phone: phone,
      email: email,
      managerUserId: managerUserId,
      timezone: timezone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createBranch(branch);
  }

  Future<List<Branch>> getBranches() => _repo.getBranches();
  Future<List<Branch>> getActiveBranches() => _repo.getActiveBranches();
  Future<Branch?> getBranch(String id) => _repo.getBranch(id);

  Future<Branch> updateBranch(String id, Branch branch) =>
      _repo.updateBranch(id, branch);

  Future<void> deleteBranch(String id) => _repo.deleteBranch(id);
}
