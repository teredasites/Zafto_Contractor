import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zafto/core/user_role.dart';
import 'package:zafto/services/auth_service.dart';

// Manual role override — null means "use auth role"
// Only set by RoleSwitcherScreen for dev/testing
final roleOverrideProvider = StateProvider<UserRole?>((ref) => null);

// Effective role: manual override > JWT auth role > fallback to owner
final currentRoleProvider = Provider<UserRole>((ref) {
  final override = ref.watch(roleOverrideProvider);
  if (override != null) return override;

  final authState = ref.watch(authStateProvider);
  final roleId = authState.roleId;
  if (roleId != null && roleId.isNotEmpty) {
    return UserRoleExtension.fromString(roleId);
  }
  return UserRole.owner;
});
