// ZAFTO Auth Service — Supabase Auth
// Rewritten: Sprint B1a (Session 40)
//
// Replaces Firebase Auth. Same API surface so all consumers
// (15 files) continue to work without changes.
//
// Providers: authServiceProvider, authStateProvider
// Models: AuthStatus, AuthState, ZaftoUser

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../core/errors.dart';
import '../core/sentry_service.dart';
import '../repositories/auth_repository.dart';

// ============================================================
// ENUMS
// ============================================================

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  needsOnboarding,
}

// ============================================================
// USER MODEL
// ============================================================

class ZaftoUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phone;
  final String? companyId;
  final String? role;
  final String? trade;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  const ZaftoUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phone,
    this.companyId,
    this.role,
    this.trade,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  /// Create from Supabase auth user (minimal — no profile data yet).
  factory ZaftoUser.fromAuthUser(supa.User user) {
    return ZaftoUser(
      uid: user.id,
      email: user.email,
      displayName: user.userMetadata?['full_name'] as String?,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  /// Create from users table row (full profile).
  factory ZaftoUser.fromProfile(Map<String, dynamic> json) {
    return ZaftoUser(
      uid: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      companyId: json['company_id'] as String?,
      role: json['role'] as String?,
      trade: json['trade'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasCompany => companyId != null && companyId!.isNotEmpty;
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';

  // Kept for backward compatibility with existing screens
  bool get isAnonymous => false;

  String get displayIdentifier {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'User';
  }
}

// ============================================================
// AUTH STATE
// ============================================================

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

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isGuest => false;
  bool get hasCompany => companyId != null && companyId!.isNotEmpty;
  bool get needsOnboarding => status == AuthStatus.needsOnboarding;
}

// ============================================================
// PROVIDERS
// ============================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authRepositoryProvider));
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// ============================================================
// AUTH NOTIFIER (state management)
// ============================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  StreamSubscription<supa.AuthState>? _authSubscription;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authSubscription =
        _repo.onAuthStateChange.listen((authState) async {
      final event = authState.event;
      final session = authState.session;

      if (event == supa.AuthChangeEvent.signedIn ||
          event == supa.AuthChangeEvent.tokenRefreshed ||
          event == supa.AuthChangeEvent.initialSession) {
        if (session?.user != null) {
          await _loadUserProfile(session!.user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      } else if (event == supa.AuthChangeEvent.signedOut) {
        // Clear Sentry user context on logout
        SentryService.configureScope(null, null, null);
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Load full user profile from users table after auth.
  Future<void> _loadUserProfile(supa.User authUser) async {
    try {
      final profile = await _repo.fetchUserProfile(authUser.id);

      if (profile == null) {
        // Auth user exists but no profile row → needs onboarding
        state = AuthState(
          status: AuthStatus.needsOnboarding,
          user: ZaftoUser.fromAuthUser(authUser),
        );
        return;
      }

      final zaftoUser = ZaftoUser.fromProfile(profile);

      // Set Sentry user context for error attribution
      SentryService.configureScope(
        zaftoUser.uid,
        zaftoUser.companyId,
        zaftoUser.role,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: zaftoUser,
        companyId: zaftoUser.companyId,
        roleId: zaftoUser.role,
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Auth succeeded but profile fetch failed — still let them in
      // with minimal data. Profile will load on retry.
      state = AuthState(
        status: AuthStatus.authenticated,
        user: ZaftoUser.fromAuthUser(authUser),
      );
    }
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.signIn(email: email, password: password);
      await _repo.recordLoginAttempt(email: email, success: true);
      // Auth state listener handles the rest
    } on AuthError catch (e) {
      await _repo.recordLoginAttempt(
        email: email,
        success: false,
        failureReason: e.code.name,
      );
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.userMessage ?? e.message,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Sign in failed. Please try again.',
      );
    }
  }

  /// Create a new account (auth user only — company created in onboarding).
  Future<void> createAccount(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repo.register(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Will trigger needsOnboarding since no profile row exists yet
        state = AuthState(
          status: AuthStatus.needsOnboarding,
          user: ZaftoUser.fromAuthUser(response.user!),
        );
      }
    } on AuthError catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.userMessage ?? e.message,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Account creation failed. Please try again.',
      );
    }
  }

  /// Complete onboarding — create company + user row.
  Future<bool> completeOnboarding({
    required String fullName,
    required String companyName,
    required String trade,
  }) async {
    final authUser = _repo.currentAuthUser;
    if (authUser == null) return false;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.createCompanyAndUser(
        authUserId: authUser.id,
        email: authUser.email ?? '',
        fullName: fullName,
        companyName: companyName,
        trade: trade,
      );

      final zaftoUser = ZaftoUser.fromProfile(result.userProfile);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: zaftoUser,
        companyId: result.companyId,
        roleId: 'owner',
      );
      return true;
    } on AppError catch (e) {
      state = AuthState(
        status: AuthStatus.needsOnboarding,
        user: state.user,
        errorMessage: e.userMessage ?? e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.needsOnboarding,
        user: state.user,
        errorMessage: 'Setup failed. Please try again.',
      );
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _repo.signOut();
      // Auth state listener handles the rest
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Sign out failed.',
      );
    }
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _repo.resetPassword(email);
    } on AuthError catch (e) {
      state = state.copyWith(
        errorMessage: e.userMessage ?? e.message,
      );
    }
  }

  /// Kept for backward compatibility — guest mode removed.
  /// Business app requires authentication.
  Future<void> continueAsGuest() async {
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Guest mode is not available. Please create an account.',
    );
  }

  /// Kept for backward compatibility.
  Future<void> deleteAccount() async {
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Contact support to delete your account.',
    );
  }

  /// Set company after onboarding (backward compat for company_service.dart).
  Future<void> setCompany(String companyId, String roleId) async {
    state = state.copyWith(companyId: companyId, roleId: roleId);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// AUTH SERVICE (convenience wrapper)
// ============================================================

class AuthService {
  final AuthRepository _repo;

  AuthService(this._repo);

  supa.User? get currentUser => _repo.currentAuthUser;
  supa.Session? get currentSession => _repo.currentSession;
  Stream<supa.AuthState> get authStateChanges => _repo.onAuthStateChange;

  Future<void> signInWithEmail(String email, String password) =>
      _repo.signIn(email: email, password: password);

  Future<void> createAccount(String email, String password) =>
      _repo.register(email: email, password: password);

  Future<void> signOut() => _repo.signOut();

  Future<void> resetPassword(String email) => _repo.resetPassword(email);

  bool needsReauth() {
    final session = _repo.currentSession;
    if (session == null) return true;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    return DateTime.now().isAfter(expiresAt);
  }
}
