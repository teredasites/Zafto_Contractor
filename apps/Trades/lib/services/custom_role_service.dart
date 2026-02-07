// ZAFTO Custom Role Service — Supabase Backend
// Providers and service for company-defined permission roles.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/custom_role.dart';
import '../repositories/custom_role_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final customRoleRepositoryProvider = Provider<CustomRoleRepository>((ref) {
  return CustomRoleRepository();
});

final customRoleServiceProvider = Provider<CustomRoleService>((ref) {
  final repo = ref.watch(customRoleRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return CustomRoleService(repo, authState);
});

// All custom roles for the company.
final companyRolesProvider =
    FutureProvider.autoDispose<List<CustomRole>>((ref) async {
  final repo = ref.watch(customRoleRepositoryProvider);
  return repo.getRoles();
});

// --- Service ---

class CustomRoleService {
  final CustomRoleRepository _repo;
  final AuthState _authState;

  CustomRoleService(this._repo, this._authState);

  Future<CustomRole> createRole({
    required String name,
    String? description,
    String baseRole = 'technician',
    Map<String, dynamic> permissions = const {},
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage roles.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final role = CustomRole(
      companyId: companyId,
      name: name,
      description: description,
      baseRole: baseRole,
      permissions: permissions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createRole(role);
  }

  Future<List<CustomRole>> getRoles() => _repo.getRoles();
  Future<CustomRole?> getRole(String id) => _repo.getRole(id);

  Future<CustomRole> updateRole(String id, CustomRole role) =>
      _repo.updateRole(id, role);

  Future<void> deleteRole(String id) => _repo.deleteRole(id);
}
