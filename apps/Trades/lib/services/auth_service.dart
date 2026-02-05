import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Authentication state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// User model for app use
class ZaftoUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final DateTime? createdAt;

  const ZaftoUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isAnonymous,
    this.createdAt,
  });

  factory ZaftoUser.fromFirebaseUser(User user) {
    return ZaftoUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
    );
  }

  bool get hasEmail => email != null && email!.isNotEmpty;
  
  String get displayIdentifier {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'Guest User';
  }
}

/// Auth state for Riverpod
class AuthState {
  final AuthStatus status;
  final ZaftoUser? user;
  final String? companyId;
  final String? roleId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.companyId,
    this.roleId,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    ZaftoUser? user,
    String? companyId,
    String? roleId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      companyId: companyId ?? this.companyId,
      roleId: roleId ?? this.roleId,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isGuest => user?.isAnonymous ?? false;
  bool get hasCompany => companyId != null && companyId!.isNotEmpty;
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state notifier provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        // Fetch user's company info from Firestore
        String? companyId;
        String? roleId;
        
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            companyId = userDoc.data()?['companyId'] as String?;
            roleId = userDoc.data()?['roleId'] as String?;
          }
        } catch (e) {
          // Firestore fetch failed - user might be offline or new
          // Continue with null companyId, will be set during onboarding
        }
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: ZaftoUser.fromFirebaseUser(user),
          companyId: companyId,
          roleId: roleId,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Set company after user creates/joins one
  Future<void> setCompany(String companyId, String roleId) async {
    if (state.user == null) return;
    
    // Update Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(state.user!.uid)
        .set({
      'companyId': companyId,
      'roleId': roleId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Update local state
    state = state.copyWith(companyId: companyId, roleId: roleId);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.signInWithEmail(email, password);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> createAccount(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.createAccount(email, password);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.signInAnonymously();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.deleteAccount();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<bool> upgradeGuestAccount(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.linkEmailToAnonymous(email, password);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e),
      );
      return false;
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    return e.toString();
  }
}

/// Core auth service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email/password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create account with email/password
  Future<UserCredential> createAccount(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in anonymously (guest mode)
  Future<UserCredential> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    
    // Store guest login timestamp
    final box = Hive.box('app_state');
    await box.put('guest_login_time', DateTime.now().toIso8601String());
    
    return credential;
  }

  /// Link email to anonymous account (upgrade guest)
  Future<UserCredential> linkEmailToAnonymous(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw Exception('No guest account to upgrade.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    return await user.linkWithCredential(credential);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    
    // Clear guest flag
    final box = Hive.box('app_state');
    await box.delete('guest_login_time');
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in.');
    }
    
    // TODO: Delete user data from Firestore before deleting auth account
    await user.delete();
    
    // Clear local data
    final box = Hive.box('app_state');
    await box.delete('guest_login_time');
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Check if user needs re-authentication for sensitive operations
  bool needsReauth() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null) return true;
    
    // Require re-auth if last sign-in was over 5 minutes ago
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return lastSignIn.isBefore(fiveMinutesAgo);
  }
}
