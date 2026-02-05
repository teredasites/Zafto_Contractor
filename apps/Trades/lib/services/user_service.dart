import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../models/company.dart';

/// Service for managing user operations with RBAC
class UserService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _companiesRef =>
      _firestore.collection('companies');

  CollectionReference<Map<String, dynamic>> _rolesRef(String companyId) =>
      _companiesRef.doc(companyId).collection('roles');

  // ============================================================
  // USER CRUD
  // ============================================================

  /// Get user by ID
  Future<User?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    final snapshot = await _usersRef
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return User.fromFirestore(snapshot.docs.first);
  }

  /// Update user
  Future<void> updateUser(User user) async {
    await _usersRef.doc(user.id).update({
      ...user.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update specific user fields
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    await _usersRef.doc(userId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream user changes
  Stream<User?> watchUser(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    });
  }

  // ============================================================
  // COMPANY USER QUERIES
  // ============================================================

  /// Get all users for a company
  Future<List<User>> getCompanyUsers(String companyId) async {
    final snapshot = await _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('status', whereIn: [UserStatus.active.name, UserStatus.invited.name])
        .orderBy('displayName')
        .get();
    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  /// Get active users for a company
  Future<List<User>> getActiveCompanyUsers(String companyId) async {
    final snapshot = await _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: UserStatus.active.name)
        .orderBy('displayName')
        .get();
    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  /// Stream company users
  Stream<List<User>> watchCompanyUsers(String companyId) {
    return _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('status', whereIn: [UserStatus.active.name, UserStatus.invited.name])
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  /// Get users by team
  Future<List<User>> getTeamUsers(String companyId, String teamId) async {
    final snapshot = await _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: UserStatus.active.name)
        .get();
    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(String companyId, String roleId) async {
    final snapshot = await _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('roleId', isEqualTo: roleId)
        .where('status', isEqualTo: UserStatus.active.name)
        .get();
    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  // ============================================================
  // USER INVITE FLOW
  // ============================================================

  /// Invite a new user to the company
  /// Returns the created user with 'invited' status
  Future<User> inviteUser({
    required String companyId,
    required String email,
    required String roleId,
    required String invitedByUserId,
    String? displayName,
    String? teamId,
  }) async {
    // Check if user already exists
    final existing = await getUserByEmail(email);
    if (existing != null) {
      if (existing.companyId == companyId) {
        throw Exception('User already belongs to this company');
      }
      throw Exception('Email already registered with another company');
    }

    // Check company user limit
    final canAdd = await _canAddUser(companyId);
    if (!canAdd) {
      throw Exception('Company has reached maximum user limit. Upgrade to add more users.');
    }

    // Create invited user with temporary ID (will be replaced on signup)
    final userId = _uuid.v4();
    final user = User.createInvited(
      id: userId,
      companyId: companyId,
      roleId: roleId,
      email: email.toLowerCase().trim(),
      invitedBy: invitedByUserId,
    ).copyWith(
      displayName: displayName ?? email.split('@').first,
      teamId: teamId,
    );

    await _usersRef.doc(userId).set(user.toMap());
    return user;
  }

  /// Accept invite and link to Firebase Auth user
  Future<User> acceptInvite({
    required String inviteUserId,
    required String firebaseAuthUid,
    required String displayName,
  }) async {
    final invitedUser = await getUser(inviteUserId);
    if (invitedUser == null) {
      throw Exception('Invite not found');
    }
    if (invitedUser.status != UserStatus.invited) {
      throw Exception('Invite already accepted or expired');
    }

    // Update with real Firebase Auth UID
    final now = DateTime.now();
    final activatedUser = invitedUser.copyWith(
      id: firebaseAuthUid,
      displayName: displayName,
      status: UserStatus.active,
      updatedAt: now,
    );

    // Delete old invite doc and create new one with correct ID
    final batch = _firestore.batch();
    batch.delete(_usersRef.doc(inviteUserId));
    batch.set(_usersRef.doc(firebaseAuthUid), activatedUser.toMap());
    await batch.commit();

    return activatedUser;
  }

  /// Cancel a pending invite
  Future<void> cancelInvite(String userId) async {
    final user = await getUser(userId);
    if (user == null) return;
    if (user.status != UserStatus.invited) {
      throw Exception('Can only cancel pending invites');
    }
    await _usersRef.doc(userId).delete();
  }

  /// Resend invite (update timestamp for tracking)
  Future<void> resendInvite(String userId) async {
    await updateUserFields(userId, {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Note: Actual email sending handled by calling code or Cloud Function
  }

  // ============================================================
  // USER STATUS MANAGEMENT
  // ============================================================

  /// Suspend a user (temporary disable)
  Future<void> suspendUser(String userId) async {
    final user = await getUser(userId);
    if (user == null) throw Exception('User not found');

    // Can't suspend company owner
    final company = await _getCompany(user.companyId);
    if (company?.ownerUserId == userId) {
      throw Exception('Cannot suspend company owner');
    }

    await updateUserFields(userId, {
      'status': UserStatus.suspended.name,
    });
  }

  /// Reactivate a suspended user
  Future<void> reactivateUser(String userId) async {
    final user = await getUser(userId);
    if (user == null) throw Exception('User not found');
    if (user.status != UserStatus.suspended) {
      throw Exception('User is not suspended');
    }

    await updateUserFields(userId, {
      'status': UserStatus.active.name,
    });
  }

  /// Soft delete a user (mark as deleted but keep data)
  Future<void> deleteUser(String userId) async {
    final user = await getUser(userId);
    if (user == null) throw Exception('User not found');

    // Can't delete company owner
    final company = await _getCompany(user.companyId);
    if (company?.ownerUserId == userId) {
      throw Exception('Cannot delete company owner. Transfer ownership first.');
    }

    await updateUserFields(userId, {
      'status': UserStatus.deleted.name,
    });
  }

  // ============================================================
  // ROLE MANAGEMENT
  // ============================================================

  /// Change user's role
  Future<void> changeUserRole(String userId, String newRoleId) async {
    final user = await getUser(userId);
    if (user == null) throw Exception('User not found');

    // Verify role exists in same company
    final roleDoc = await _rolesRef(user.companyId).doc(newRoleId).get();
    if (!roleDoc.exists) {
      throw Exception('Role not found');
    }

    await updateUserFields(userId, {
      'roleId': newRoleId,
    });
  }

  /// Get user's role
  Future<Role?> getUserRole(String userId) async {
    final user = await getUser(userId);
    if (user == null) return null;

    final roleDoc = await _rolesRef(user.companyId).doc(user.roleId).get();
    if (!roleDoc.exists) return null;
    return Role.fromFirestore(roleDoc);
  }

  // ============================================================
  // TEAM MANAGEMENT
  // ============================================================

  /// Assign user to team
  Future<void> assignToTeam(String userId, String? teamId) async {
    await updateUserFields(userId, {
      'teamId': teamId,
    });
  }

  /// Remove user from team
  Future<void> removeFromTeam(String userId) async {
    await assignToTeam(userId, null);
  }

  // ============================================================
  // PROFILE MANAGEMENT
  // ============================================================

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? title,
    List<String>? trades,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (title != null) updates['title'] = title;
    if (trades != null) updates['trades'] = trades;

    if (updates.isNotEmpty) {
      await updateUserFields(userId, updates);
    }
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String userId,
    String? preferredNecYear,
    bool? darkMode,
    bool? hapticFeedback,
  }) async {
    final updates = <String, dynamic>{};
    if (preferredNecYear != null) updates['preferredNecYear'] = preferredNecYear;
    if (darkMode != null) updates['darkMode'] = darkMode;
    if (hapticFeedback != null) updates['hapticFeedback'] = hapticFeedback;

    if (updates.isNotEmpty) {
      await updateUserFields(userId, updates);
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String userId, String? token) async {
    await updateUserFields(userId, {
      'fcmToken': token,
    });
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    await updateUserFields(userId, {
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // OWNERSHIP TRANSFER
  // ============================================================

  /// Transfer company ownership to another user
  Future<void> transferOwnership({
    required String companyId,
    required String currentOwnerId,
    required String newOwnerId,
  }) async {
    final company = await _getCompany(companyId);
    if (company == null) throw Exception('Company not found');
    if (company.ownerUserId != currentOwnerId) {
      throw Exception('Only current owner can transfer ownership');
    }

    final newOwner = await getUser(newOwnerId);
    if (newOwner == null) throw Exception('New owner not found');
    if (newOwner.companyId != companyId) {
      throw Exception('New owner must be in same company');
    }
    if (newOwner.status != UserStatus.active) {
      throw Exception('New owner must be an active user');
    }

    // Get or create owner role for new owner
    final rolesSnapshot = await _rolesRef(companyId)
        .where('isSystemRole', isEqualTo: true)
        .where('name', isEqualTo: 'Owner')
        .limit(1)
        .get();

    String ownerRoleId;
    if (rolesSnapshot.docs.isNotEmpty) {
      ownerRoleId = rolesSnapshot.docs.first.id;
    } else {
      // Create owner role if missing
      ownerRoleId = _uuid.v4();
      final ownerRole = Role.ownerTemplate(id: ownerRoleId, companyId: companyId);
      await _rolesRef(companyId).doc(ownerRoleId).set(ownerRole.toMap());
    }

    // Get admin role for old owner
    final adminRolesSnapshot = await _rolesRef(companyId)
        .where('isSystemRole', isEqualTo: true)
        .where('name', isEqualTo: 'Admin')
        .limit(1)
        .get();

    String adminRoleId;
    if (adminRolesSnapshot.docs.isNotEmpty) {
      adminRoleId = adminRolesSnapshot.docs.first.id;
    } else {
      adminRoleId = _uuid.v4();
      final adminRole = Role.adminTemplate(id: adminRoleId, companyId: companyId);
      await _rolesRef(companyId).doc(adminRoleId).set(adminRole.toMap());
    }

    // Perform transfer in batch
    final batch = _firestore.batch();

    // Update company owner
    batch.update(_companiesRef.doc(companyId), {
      'ownerUserId': newOwnerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update new owner's role
    batch.update(_usersRef.doc(newOwnerId), {
      'roleId': ownerRoleId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Demote old owner to admin
    batch.update(_usersRef.doc(currentOwnerId), {
      'roleId': adminRoleId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<Company?> _getCompany(String companyId) async {
    final doc = await _companiesRef.doc(companyId).get();
    if (!doc.exists) return null;
    return Company.fromFirestore(doc);
  }

  Future<bool> _canAddUser(String companyId) async {
    final company = await _getCompany(companyId);
    if (company == null) return false;

    final snapshot = await _usersRef
        .where('companyId', isEqualTo: companyId)
        .where('status', whereIn: [UserStatus.active.name, UserStatus.invited.name])
        .count()
        .get();

    final currentCount = snapshot.count ?? 0;
    return currentCount < company.maxUsers;
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Provider for current user
final currentUserProvider = StreamProvider.family<User?, String>((ref, userId) {
  return ref.watch(userServiceProvider).watchUser(userId);
});

/// Provider for company users list
final companyUsersProvider = StreamProvider.family<List<User>, String>((ref, companyId) {
  return ref.watch(userServiceProvider).watchCompanyUsers(companyId);
});

/// Provider for user by ID (one-time fetch)
final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) {
  return ref.watch(userServiceProvider).getUser(userId);
});
