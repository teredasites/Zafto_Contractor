import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/role.dart';
import '../models/company.dart';

/// Service for managing roles and permissions
class RoleService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  RoleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _companiesRef =>
      _firestore.collection('companies');

  CollectionReference<Map<String, dynamic>> _rolesRef(String companyId) =>
      _companiesRef.doc(companyId).collection('roles');

  // ============================================================
  // ROLE CRUD
  // ============================================================

  /// Get role by ID
  Future<Role?> getRole(String companyId, String roleId) async {
    final doc = await _rolesRef(companyId).doc(roleId).get();
    if (!doc.exists) return null;
    return Role.fromFirestore(doc);
  }

  /// Get all roles for a company
  Future<List<Role>> getCompanyRoles(String companyId) async {
    final snapshot = await _rolesRef(companyId).orderBy('name').get();
    return snapshot.docs.map((doc) => Role.fromFirestore(doc)).toList();
  }

  /// Stream roles for a company
  Stream<List<Role>> watchCompanyRoles(String companyId) {
    return _rolesRef(companyId).orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Role.fromFirestore(doc)).toList());
  }

  /// Get system roles only
  Future<List<Role>> getSystemRoles(String companyId) async {
    final snapshot = await _rolesRef(companyId)
        .where('isSystemRole', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Role.fromFirestore(doc)).toList();
  }

  /// Get custom roles only
  Future<List<Role>> getCustomRoles(String companyId) async {
    final snapshot = await _rolesRef(companyId)
        .where('isSystemRole', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => Role.fromFirestore(doc)).toList();
  }

  /// Get default role for new users
  Future<Role?> getDefaultRole(String companyId) async {
    final snapshot = await _rolesRef(companyId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      // Fallback to technician role
      final techSnapshot = await _rolesRef(companyId)
          .where('name', isEqualTo: 'Technician')
          .limit(1)
          .get();
      if (techSnapshot.docs.isEmpty) return null;
      return Role.fromFirestore(techSnapshot.docs.first);
    }
    return Role.fromFirestore(snapshot.docs.first);
  }

  /// Get role by name
  Future<Role?> getRoleByName(String companyId, String name) async {
    final snapshot = await _rolesRef(companyId)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Role.fromFirestore(snapshot.docs.first);
  }

  // ============================================================
  // CUSTOM ROLE MANAGEMENT
  // ============================================================

  /// Create a custom role (Enterprise tier only)
  Future<Role> createRole({
    required String companyId,
    required String name,
    String? description,
    required Map<String, bool> permissions,
    bool isDefault = false,
  }) async {
    // Verify company can create custom roles
    final company = await _getCompany(companyId);
    if (company == null) throw Exception('Company not found');
    if (!company.hasCustomRoles) {
      throw Exception('Custom roles require Enterprise tier');
    }

    // Check for duplicate name
    final existing = await getRoleByName(companyId, name);
    if (existing != null) {
      throw Exception('Role with this name already exists');
    }

    // If setting as default, unset current default
    if (isDefault) {
      await _clearDefaultRole(companyId);
    }

    final roleId = _uuid.v4();
    final now = DateTime.now();
    final role = Role(
      id: roleId,
      companyId: companyId,
      name: name,
      description: description,
      isSystemRole: false,
      isDefault: isDefault,
      permissions: _sanitizePermissions(permissions),
      createdAt: now,
      updatedAt: now,
    );

    await _rolesRef(companyId).doc(roleId).set(role.toMap());
    return role;
  }

  /// Update a custom role
  Future<void> updateRole({
    required String companyId,
    required String roleId,
    String? name,
    String? description,
    Map<String, bool>? permissions,
    bool? isDefault,
  }) async {
    final role = await getRole(companyId, roleId);
    if (role == null) throw Exception('Role not found');
    if (role.isSystemRole) {
      throw Exception('Cannot modify system roles');
    }

    // Check for duplicate name if changing
    if (name != null && name != role.name) {
      final existing = await getRoleByName(companyId, name);
      if (existing != null) {
        throw Exception('Role with this name already exists');
      }
    }

    // If setting as default, unset current default
    if (isDefault == true && !role.isDefault) {
      await _clearDefaultRole(companyId);
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (permissions != null) updates['permissions'] = _sanitizePermissions(permissions);
    if (isDefault != null) updates['isDefault'] = isDefault;

    await _rolesRef(companyId).doc(roleId).update(updates);
  }

  /// Delete a custom role
  Future<void> deleteRole(String companyId, String roleId) async {
    final role = await getRole(companyId, roleId);
    if (role == null) return;
    if (role.isSystemRole) {
      throw Exception('Cannot delete system roles');
    }

    // Check if any users have this role
    final usersSnapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('roleId', isEqualTo: roleId)
        .limit(1)
        .get();

    if (usersSnapshot.docs.isNotEmpty) {
      throw Exception('Cannot delete role while users are assigned to it');
    }

    await _rolesRef(companyId).doc(roleId).delete();
  }

  // ============================================================
  // PERMISSION MANAGEMENT
  // ============================================================

  /// Update a single permission for a role
  Future<void> setPermission({
    required String companyId,
    required String roleId,
    required String permission,
    required bool enabled,
  }) async {
    final role = await getRole(companyId, roleId);
    if (role == null) throw Exception('Role not found');
    if (role.isSystemRole) {
      throw Exception('Cannot modify system role permissions');
    }

    await _rolesRef(companyId).doc(roleId).update({
      'permissions.$permission': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bulk update permissions for a role
  Future<void> setPermissions({
    required String companyId,
    required String roleId,
    required Map<String, bool> permissions,
  }) async {
    final role = await getRole(companyId, roleId);
    if (role == null) throw Exception('Role not found');
    if (role.isSystemRole) {
      throw Exception('Cannot modify system role permissions');
    }

    await _rolesRef(companyId).doc(roleId).update({
      'permissions': _sanitizePermissions(permissions),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clone a role as a starting point for a new custom role
  Future<Role> cloneRole({
    required String companyId,
    required String sourceRoleId,
    required String newName,
    String? description,
  }) async {
    final sourceRole = await getRole(companyId, sourceRoleId);
    if (sourceRole == null) throw Exception('Source role not found');

    return createRole(
      companyId: companyId,
      name: newName,
      description: description ?? 'Cloned from ${sourceRole.name}',
      permissions: Map<String, bool>.from(sourceRole.permissions),
    );
  }

  // ============================================================
  // DEFAULT ROLE MANAGEMENT
  // ============================================================

  /// Set a role as the default for new users
  Future<void> setDefaultRole(String companyId, String roleId) async {
    final role = await getRole(companyId, roleId);
    if (role == null) throw Exception('Role not found');

    await _clearDefaultRole(companyId);

    await _rolesRef(companyId).doc(roleId).update({
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clear default flag from all roles
  Future<void> _clearDefaultRole(String companyId) async {
    final snapshot = await _rolesRef(companyId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ============================================================
  // SYSTEM ROLE INITIALIZATION
  // ============================================================

  /// Initialize system roles for a new company
  /// Called during company creation
  Future<Map<String, Role>> initializeSystemRoles({
    required String companyId,
    required CompanyTier tier,
  }) async {
    final roles = <String, Role>{};
    final batch = _firestore.batch();

    // Owner role (always created)
    final ownerRoleId = _uuid.v4();
    final ownerRole = Role.ownerTemplate(id: ownerRoleId, companyId: companyId);
    batch.set(_rolesRef(companyId).doc(ownerRoleId), ownerRole.toMap());
    roles['owner'] = ownerRole;

    // Team+ tiers get Technician and Admin
    if (tier != CompanyTier.solo) {
      final techRoleId = _uuid.v4();
      final techRole = Role.technicianTemplate(id: techRoleId, companyId: companyId);
      batch.set(_rolesRef(companyId).doc(techRoleId), techRole.toMap());
      roles['technician'] = techRole;

      final adminRoleId = _uuid.v4();
      final adminRole = Role.adminTemplate(id: adminRoleId, companyId: companyId);
      batch.set(_rolesRef(companyId).doc(adminRoleId), adminRole.toMap());
      roles['admin'] = adminRole;
    }

    // Business+ tiers get Manager
    if (tier == CompanyTier.business || tier == CompanyTier.enterprise) {
      final managerRoleId = _uuid.v4();
      final managerRole = Role.managerTemplate(id: managerRoleId, companyId: companyId);
      batch.set(_rolesRef(companyId).doc(managerRoleId), managerRole.toMap());
      roles['manager'] = managerRole;
    }

    await batch.commit();
    return roles;
  }

  /// Add missing system roles when upgrading tier
  Future<void> addTierRoles(String companyId, CompanyTier newTier) async {
    final existingRoles = await getSystemRoles(companyId);
    final existingNames = existingRoles.map((r) => r.name).toSet();
    final batch = _firestore.batch();

    // Team tier needs Technician and Admin
    if (newTier != CompanyTier.solo) {
      if (!existingNames.contains('Technician')) {
        final techRoleId = _uuid.v4();
        final techRole = Role.technicianTemplate(id: techRoleId, companyId: companyId);
        batch.set(_rolesRef(companyId).doc(techRoleId), techRole.toMap());
      }

      if (!existingNames.contains('Admin')) {
        final adminRoleId = _uuid.v4();
        final adminRole = Role.adminTemplate(id: adminRoleId, companyId: companyId);
        batch.set(_rolesRef(companyId).doc(adminRoleId), adminRole.toMap());
      }
    }

    // Business+ needs Manager
    if (newTier == CompanyTier.business || newTier == CompanyTier.enterprise) {
      if (!existingNames.contains('Manager')) {
        final managerRoleId = _uuid.v4();
        final managerRole = Role.managerTemplate(id: managerRoleId, companyId: companyId);
        batch.set(_rolesRef(companyId).doc(managerRoleId), managerRole.toMap());
      }
    }

    await batch.commit();
  }

  // ============================================================
  // VALIDATION & HELPERS
  // ============================================================

  /// Ensure permissions map only contains valid permission keys
  Map<String, bool> _sanitizePermissions(Map<String, bool> permissions) {
    final sanitized = <String, bool>{};
    for (final perm in allPermissions) {
      sanitized[perm] = permissions[perm] ?? false;
    }
    return sanitized;
  }

  /// Get permission categories for UI grouping
  Map<String, List<String>> get permissionCategories => {
    'Jobs': [
      permJobsViewOwn,
      permJobsViewAll,
      permJobsCreate,
      permJobsEditOwn,
      permJobsEditAll,
      permJobsDelete,
      permJobsAssign,
    ],
    'Invoices': [
      permInvoicesViewOwn,
      permInvoicesViewAll,
      permInvoicesCreate,
      permInvoicesEdit,
      permInvoicesSend,
      permInvoicesApprove,
      permInvoicesVoid,
    ],
    'Customers': [
      permCustomersViewOwn,
      permCustomersViewAll,
      permCustomersCreate,
      permCustomersEdit,
      permCustomersDelete,
    ],
    'Team': [
      permTeamView,
      permTeamInvite,
      permTeamEdit,
      permTeamRemove,
    ],
    'Dispatch': [
      permDispatchView,
      permDispatchManage,
    ],
    'Reports': [
      permReportsView,
      permReportsExport,
    ],
    'Admin': [
      permCompanySettings,
      permBillingManage,
      permRolesManage,
      permAuditView,
    ],
    'Time Clock': [
      permTimeClockOwn,
      permTimeClockViewAll,
      permTimeClockManage,
    ],
  };

  /// Get human-readable permission name
  String getPermissionLabel(String permission) {
    final labels = {
      permJobsViewOwn: 'View own jobs',
      permJobsViewAll: 'View all jobs',
      permJobsCreate: 'Create jobs',
      permJobsEditOwn: 'Edit own jobs',
      permJobsEditAll: 'Edit all jobs',
      permJobsDelete: 'Delete jobs',
      permJobsAssign: 'Assign jobs',
      permInvoicesViewOwn: 'View own invoices',
      permInvoicesViewAll: 'View all invoices',
      permInvoicesCreate: 'Create invoices',
      permInvoicesEdit: 'Edit invoices',
      permInvoicesSend: 'Send invoices',
      permInvoicesApprove: 'Approve invoices',
      permInvoicesVoid: 'Void invoices',
      permCustomersViewOwn: 'View own customers',
      permCustomersViewAll: 'View all customers',
      permCustomersCreate: 'Create customers',
      permCustomersEdit: 'Edit customers',
      permCustomersDelete: 'Delete customers',
      permTeamView: 'View team',
      permTeamInvite: 'Invite users',
      permTeamEdit: 'Edit users',
      permTeamRemove: 'Remove users',
      permDispatchView: 'View dispatch',
      permDispatchManage: 'Manage dispatch',
      permReportsView: 'View reports',
      permReportsExport: 'Export reports',
      permCompanySettings: 'Company settings',
      permBillingManage: 'Manage billing',
      permRolesManage: 'Manage roles',
      permAuditView: 'View audit logs',
      // Time Clock
      permTimeClockOwn: 'Clock in/out self',
      permTimeClockViewAll: 'View all time entries',
      permTimeClockManage: 'Manage time entries',
    };
    return labels[permission] ?? permission;
  }

  Future<Company?> _getCompany(String companyId) async {
    final doc = await _companiesRef.doc(companyId).get();
    if (!doc.exists) return null;
    return Company.fromFirestore(doc);
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for RoleService
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService();
});

/// Provider for company roles
final companyRolesProvider = StreamProvider.family<List<Role>, String>((ref, companyId) {
  return ref.watch(roleServiceProvider).watchCompanyRoles(companyId);
});

/// Provider for a single role
final roleProvider = FutureProvider.family<Role?, ({String companyId, String roleId})>((ref, params) {
  return ref.watch(roleServiceProvider).getRole(params.companyId, params.roleId);
});

/// Provider for default role
final defaultRoleProvider = FutureProvider.family<Role?, String>((ref, companyId) {
  return ref.watch(roleServiceProvider).getDefaultRole(companyId);
});

/// Provider for permission categories (for role editor UI)
final permissionCategoriesProvider = Provider<Map<String, List<String>>>((ref) {
  return ref.watch(roleServiceProvider).permissionCategories;
});
