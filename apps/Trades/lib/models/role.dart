import 'package:equatable/equatable.dart';

// ============================================================
// PERMISSION CONSTANTS
// ============================================================

/// Jobs permissions
const permJobsViewOwn = 'jobs.view.own';
const permJobsViewAll = 'jobs.view.all';
const permJobsCreate = 'jobs.create';
const permJobsEditOwn = 'jobs.edit.own';
const permJobsEditAll = 'jobs.edit.all';
const permJobsDelete = 'jobs.delete';
const permJobsAssign = 'jobs.assign';

/// Invoices permissions
const permInvoicesViewOwn = 'invoices.view.own';
const permInvoicesViewAll = 'invoices.view.all';
const permInvoicesCreate = 'invoices.create';
const permInvoicesEdit = 'invoices.edit';
const permInvoicesSend = 'invoices.send';
const permInvoicesApprove = 'invoices.approve';
const permInvoicesVoid = 'invoices.void';

/// Customers permissions
const permCustomersViewOwn = 'customers.view.own';
const permCustomersViewAll = 'customers.view.all';
const permCustomersCreate = 'customers.create';
const permCustomersEdit = 'customers.edit';
const permCustomersDelete = 'customers.delete';

/// Photos permissions
const permPhotosView = 'photos.view';
const permPhotosUpload = 'photos.upload';
const permPhotosDelete = 'photos.delete';

/// Team permissions (Team+ tiers)
const permTeamView = 'team.view';
const permTeamInvite = 'team.invite';
const permTeamEdit = 'team.edit';
const permTeamRemove = 'team.remove';

/// Dispatch permissions (Growing+ tiers)
const permDispatchView = 'dispatch.view';
const permDispatchManage = 'dispatch.manage';

/// Reports permissions (Growing+ tiers)
const permReportsView = 'reports.view';
const permReportsExport = 'reports.export';

/// Admin permissions
const permCompanySettings = 'company.settings';
const permBillingManage = 'billing.manage';
const permRolesManage = 'roles.manage';
const permAuditView = 'audit.view';

/// Time Clock permissions (Session 23)
const permTimeClockOwn = 'timeclock.own';         // Clock self in/out
const permTimeClockViewAll = 'timeclock.view.all'; // View all time entries
const permTimeClockManage = 'timeclock.manage';    // Edit/approve time entries

/// All available permissions
const allPermissions = [
  // Jobs
  permJobsViewOwn,
  permJobsViewAll,
  permJobsCreate,
  permJobsEditOwn,
  permJobsEditAll,
  permJobsDelete,
  permJobsAssign,
  // Invoices
  permInvoicesViewOwn,
  permInvoicesViewAll,
  permInvoicesCreate,
  permInvoicesEdit,
  permInvoicesSend,
  permInvoicesApprove,
  permInvoicesVoid,
  // Customers
  permCustomersViewOwn,
  permCustomersViewAll,
  permCustomersCreate,
  permCustomersEdit,
  permCustomersDelete,
  // Photos
  permPhotosView,
  permPhotosUpload,
  permPhotosDelete,
  // Team
  permTeamView,
  permTeamInvite,
  permTeamEdit,
  permTeamRemove,
  // Dispatch
  permDispatchView,
  permDispatchManage,
  // Reports
  permReportsView,
  permReportsExport,
  // Admin
  permCompanySettings,
  permBillingManage,
  permRolesManage,
  permAuditView,
  // Time Clock
  permTimeClockOwn,
  permTimeClockViewAll,
  permTimeClockManage,
];

// ============================================================
// ROLE MODEL
// ============================================================

/// Role with granular permissions for RBAC
class Role extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final bool isSystemRole;    // true = can't delete (Owner, Admin, etc.)
  final bool isDefault;       // Assigned to new users

  /// Permission map: permission key -> enabled
  final Map<String, bool> permissions;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Role({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.isSystemRole = false,
    this.isDefault = false,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, companyId, name, permissions, updatedAt];

  /// Check if role has a specific permission
  bool hasPermission(String permission) => permissions[permission] == true;

  /// Check if role has ALL of the specified permissions
  bool hasAllPermissions(List<String> perms) =>
      perms.every((p) => hasPermission(p));

  /// Check if role has ANY of the specified permissions
  bool hasAnyPermission(List<String> perms) =>
      perms.any((p) => hasPermission(p));

  /// Get list of granted permissions
  List<String> get grantedPermissions =>
      permissions.entries.where((e) => e.value).map((e) => e.key).toList();

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'isSystemRole': isSystemRole,
      'isDefault': isDefault,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isSystemRole: map['isSystemRole'] as bool? ?? false,
      isDefault: map['isDefault'] as bool? ?? false,
      permissions: Map<String, bool>.from(map['permissions'] ?? {}),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Role copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    bool? isSystemRole,
    bool? isDefault,
    Map<String, bool>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isDefault: isDefault ?? this.isDefault,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  // DEFAULT ROLE TEMPLATES
  // ============================================================

  /// Owner role - ALL permissions (for solo tier)
  static Role ownerTemplate({
    required String id,
    required String companyId,
  }) {
    final now = DateTime.now();
    return Role(
      id: id,
      companyId: companyId,
      name: 'Owner',
      description: 'Full access to all features',
      isSystemRole: true,
      isDefault: false,
      permissions: {for (var p in allPermissions) p: true},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Admin role - All except billing (for team+ tiers)
  static Role adminTemplate({
    required String id,
    required String companyId,
  }) {
    final now = DateTime.now();
    final perms = {for (var p in allPermissions) p: true};
    perms[permBillingManage] = false; // Only owner manages billing
    return Role(
      id: id,
      companyId: companyId,
      name: 'Admin',
      description: 'Full access except billing',
      isSystemRole: true,
      isDefault: false,
      permissions: perms,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Manager role - Operations without admin (for business+ tiers)
  static Role managerTemplate({
    required String id,
    required String companyId,
  }) {
    final now = DateTime.now();
    return Role(
      id: id,
      companyId: companyId,
      name: 'Manager',
      description: 'Manage jobs, customers, invoices, and view reports',
      isSystemRole: true,
      isDefault: false,
      permissions: {
        // Jobs - full access
        permJobsViewOwn: true,
        permJobsViewAll: true,
        permJobsCreate: true,
        permJobsEditOwn: true,
        permJobsEditAll: true,
        permJobsDelete: true,
        permJobsAssign: true,
        // Invoices - full access
        permInvoicesViewOwn: true,
        permInvoicesViewAll: true,
        permInvoicesCreate: true,
        permInvoicesEdit: true,
        permInvoicesSend: true,
        permInvoicesApprove: true,
        permInvoicesVoid: false,
        // Customers - full access
        permCustomersViewOwn: true,
        permCustomersViewAll: true,
        permCustomersCreate: true,
        permCustomersEdit: true,
        permCustomersDelete: false,
        // Photos - full access
        permPhotosView: true,
        permPhotosUpload: true,
        permPhotosDelete: true,
        // Team - view and invite
        permTeamView: true,
        permTeamInvite: true,
        permTeamEdit: false,
        permTeamRemove: false,
        // Dispatch - full access
        permDispatchView: true,
        permDispatchManage: true,
        // Reports - view and export
        permReportsView: true,
        permReportsExport: true,
        // Admin - none
        permCompanySettings: false,
        permBillingManage: false,
        permRolesManage: false,
        permAuditView: false,
        // Time Clock - full access for managers
        permTimeClockOwn: true,
        permTimeClockViewAll: true,
        permTimeClockManage: true,
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Technician role - Field work only (default for new team members)
  static Role technicianTemplate({
    required String id,
    required String companyId,
  }) {
    final now = DateTime.now();
    return Role(
      id: id,
      companyId: companyId,
      name: 'Technician',
      description: 'View and edit assigned jobs',
      isSystemRole: true,
      isDefault: true, // New users get this role
      permissions: {
        // Jobs - own only
        permJobsViewOwn: true,
        permJobsViewAll: false,
        permJobsCreate: false,
        permJobsEditOwn: true,
        permJobsEditAll: false,
        permJobsDelete: false,
        permJobsAssign: false,
        // Invoices - view own only
        permInvoicesViewOwn: true,
        permInvoicesViewAll: false,
        permInvoicesCreate: false,
        permInvoicesEdit: false,
        permInvoicesSend: false,
        permInvoicesApprove: false,
        permInvoicesVoid: false,
        // Customers - view only
        permCustomersViewOwn: true,
        permCustomersViewAll: false,
        permCustomersCreate: false,
        permCustomersEdit: false,
        permCustomersDelete: false,
        // Photos - upload only
        permPhotosView: true,
        permPhotosUpload: true,
        permPhotosDelete: false,
        // Team - none
        permTeamView: false,
        permTeamInvite: false,
        permTeamEdit: false,
        permTeamRemove: false,
        // Dispatch - view own schedule
        permDispatchView: true,
        permDispatchManage: false,
        // Reports - none
        permReportsView: false,
        permReportsExport: false,
        // Admin - none
        permCompanySettings: false,
        permBillingManage: false,
        permRolesManage: false,
        permAuditView: false,
        // Time Clock - own only
        permTimeClockOwn: true,
        permTimeClockViewAll: false,
        permTimeClockManage: false,
      },
      createdAt: now,
      updatedAt: now,
    );
  }
}
