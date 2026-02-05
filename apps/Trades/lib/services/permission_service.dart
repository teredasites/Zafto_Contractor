import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/user.dart';
import '../models/role.dart';
import 'auth_service.dart';

/// Central permission checking service
///
/// Usage:
/// ```dart
/// final permService = ref.watch(permissionServiceProvider);
/// if (permService.can(permJobsCreate)) {
///   // Show create button
/// }
/// ```
class PermissionService {
  final User? currentUser;
  final Company? currentCompany;
  final Role? currentRole;

  PermissionService({
    this.currentUser,
    this.currentCompany,
    this.currentRole,
  });

  /// Check if current user has a specific permission
  bool can(String permission) {
    // No user = no permissions (except public features)
    if (currentUser == null || currentRole == null) return false;

    // Check if the permission is granted in the role
    return currentRole!.hasPermission(permission);
  }

  /// Check if user has ALL specified permissions
  bool canAll(List<String> permissions) {
    if (currentUser == null || currentRole == null) return false;
    return permissions.every((p) => can(p));
  }

  /// Check if user has ANY of the specified permissions
  bool canAny(List<String> permissions) {
    if (currentUser == null || currentRole == null) return false;
    return permissions.any((p) => can(p));
  }

  /// Get all granted permissions
  List<String> get grantedPermissions {
    if (currentRole == null) return [];
    return currentRole!.grantedPermissions;
  }

  // ============================================================
  // TIER CHECKS
  // ============================================================

  /// Check if a tier feature is available
  bool isTierFeatureAvailable(String feature) {
    if (currentCompany == null) return false;

    switch (feature) {
      case 'team':
        return currentCompany!.hasTeamFeatures;
      case 'dispatch':
        return currentCompany!.hasDispatch;
      case 'approval_workflows':
        return currentCompany!.hasApprovalWorkflows;
      case 'reporting':
        return currentCompany!.hasReporting;
      case 'api_access':
        return currentCompany!.hasApiAccess;
      case 'audit_logs':
        return currentCompany!.hasAuditLogs;
      case 'custom_roles':
        return currentCompany!.hasCustomRoles;
      case 'sso':
        return currentCompany!.hasSso;
      default:
        return true; // Unknown features default to available
    }
  }

  /// Get current company tier
  CompanyTier? get tier => currentCompany?.tier;

  /// Check if user is solo tier (simplest UI)
  bool get isSolo => tier == CompanyTier.solo;

  /// Check if user is team+ tier
  bool get isTeamOrHigher =>
      tier == CompanyTier.team ||
      tier == CompanyTier.business ||
      tier == CompanyTier.enterprise;

  /// Check if user is business+ tier
  bool get isBusinessOrHigher =>
      tier == CompanyTier.business || tier == CompanyTier.enterprise;

  /// Check if user is enterprise tier
  bool get isEnterprise => tier == CompanyTier.enterprise;

  // ============================================================
  // OWNERSHIP CHECKS
  // ============================================================

  /// Check if current user is the company owner
  bool get isOwner {
    if (currentUser == null || currentCompany == null) return false;
    return currentUser!.id == currentCompany!.ownerUserId;
  }

  /// Check if user owns a specific resource
  bool isResourceOwner(String? createdByUserId) {
    if (currentUser == null) return false;
    return currentUser!.id == createdByUserId;
  }

  /// Check if user is assigned to a job
  bool isAssignedTo(String? assignedToUserId, List<String>? assignedUserIds) {
    if (currentUser == null) return false;
    if (assignedToUserId == currentUser!.id) return true;
    if (assignedUserIds?.contains(currentUser!.id) ?? false) return true;
    return false;
  }

  // ============================================================
  // CONVENIENCE METHODS FOR COMMON CHECKS
  // ============================================================

  /// Can create jobs?
  bool get canCreateJobs => can(permJobsCreate);

  /// Can view all jobs (not just own)?
  bool get canViewAllJobs => can(permJobsViewAll);

  /// Can assign jobs to others?
  bool get canAssignJobs => can(permJobsAssign) && isTeamOrHigher;

  /// Can create invoices?
  bool get canCreateInvoices => can(permInvoicesCreate);

  /// Can approve invoices?
  bool get canApproveInvoices =>
      can(permInvoicesApprove) && isBusinessOrHigher;

  /// Can manage team?
  bool get canManageTeam =>
      canAny([permTeamInvite, permTeamEdit, permTeamRemove]) && isTeamOrHigher;

  /// Can view reports?
  bool get canViewReports => can(permReportsView) && isBusinessOrHigher;

  /// Can access dispatch?
  bool get canAccessDispatch => can(permDispatchView) && isBusinessOrHigher;

  /// Can manage company settings?
  bool get canManageSettings => can(permCompanySettings);

  /// Can manage billing?
  bool get canManageBilling => can(permBillingManage);

  // ============================================================
  // JOB-SPECIFIC PERMISSION CHECKS
  // ============================================================

  /// Can view this specific job?
  bool canViewJob({
    String? assignedToUserId,
    List<String>? assignedUserIds,
  }) {
    if (can(permJobsViewAll)) return true;
    if (can(permJobsViewOwn)) {
      return isAssignedTo(assignedToUserId, assignedUserIds);
    }
    return false;
  }

  /// Can edit this specific job?
  bool canEditJob({
    String? assignedToUserId,
    List<String>? assignedUserIds,
  }) {
    if (can(permJobsEditAll)) return true;
    if (can(permJobsEditOwn)) {
      return isAssignedTo(assignedToUserId, assignedUserIds);
    }
    return false;
  }

  // ============================================================
  // INVOICE-SPECIFIC PERMISSION CHECKS
  // ============================================================

  /// Can view this specific invoice?
  bool canViewInvoice({String? createdByUserId}) {
    if (can(permInvoicesViewAll)) return true;
    if (can(permInvoicesViewOwn)) {
      return isResourceOwner(createdByUserId);
    }
    return false;
  }
}

// ============================================================
// PROVIDER
// ============================================================

/// Current user's company provider (uses models/company.dart Company)
final permissionCompanyProvider = StreamProvider<Company?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.companyId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(authState.companyId)
      .snapshots()
      .map((doc) => doc.exists ? Company.fromFirestore(doc) : null);
});

/// Current user's role provider
final currentUserRoleProvider = StreamProvider<Role?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.companyId == null || authState.roleId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(authState.companyId)
      .collection('roles')
      .doc(authState.roleId)
      .snapshots()
      .map((doc) => doc.exists ? Role.fromFirestore(doc) : null);
});

/// Provider for permission service - properly wired with auth data
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final authState = ref.watch(authStateProvider);
  final companyAsync = ref.watch(permissionCompanyProvider);
  final roleAsync = ref.watch(currentUserRoleProvider);

  // Get company and role from async providers
  final company = companyAsync.valueOrNull;
  final role = roleAsync.valueOrNull;

  // Create User model from ZaftoUser if authenticated
  User? user;
  if (authState.user != null) {
    user = User(
      id: authState.user!.uid,
      companyId: authState.companyId ?? '',
      email: authState.user!.email ?? '',
      displayName: authState.user!.displayName ?? 'User',
      roleId: authState.roleId ?? '',
      status: UserStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  return PermissionService(
    currentUser: user,
    currentCompany: company,
    currentRole: role,
  );
});

/// Provider that exposes just the permission check function
/// for simpler widget usage
final canProvider = Provider.family<bool, String>((ref, permission) {
  return ref.watch(permissionServiceProvider).can(permission);
});

/// Provider for tier feature availability
final tierFeatureProvider = Provider.family<bool, String>((ref, feature) {
  return ref.watch(permissionServiceProvider).isTierFeatureAvailable(feature);
});
