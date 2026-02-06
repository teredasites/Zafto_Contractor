// ZAFTO Auth Repository
// Created: Sprint B1a (Session 40)
//
// Pure Supabase auth operations. No UI, no state management.
// Used by AuthNotifier in auth_service.dart.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../core/supabase_client.dart';

class AuthRepository {
  SupabaseClient get _client => supabase;
  GoTrueClient get _auth => _client.auth;

  // ============================================================
  // AUTH OPERATIONS
  // ============================================================

  /// Register a new user with Supabase Auth.
  /// Returns the auth user. Company + user row created separately in onboarding.
  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signUp(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw AuthError('Registration failed: $e', cause: e);
    }
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw AuthError('Sign in failed: $e', cause: e);
    }
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Refresh the current session (gets fresh JWT with updated claims).
  Future<AuthResponse> refreshSession() async {
    try {
      return await _auth.refreshSession();
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Get the current session (null if not logged in).
  Session? get currentSession => _auth.currentSession;

  /// Get the current auth user (null if not logged in).
  User? get currentAuthUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // ============================================================
  // USER PROFILE (from public.users table)
  // ============================================================

  /// Fetch user profile from the users table.
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw DatabaseError('Failed to fetch user profile: $e', cause: e);
    }
  }

  /// Create company + user row during onboarding.
  /// This is a multi-step operation:
  /// 1. Create company row
  /// 2. Create user row (triggers JWT claims update via handle_new_user)
  /// 3. Refresh session to get updated JWT with company_id + role
  Future<({String companyId, Map<String, dynamic> userProfile})>
      createCompanyAndUser({
    required String authUserId,
    required String email,
    required String fullName,
    required String companyName,
    required String trade,
  }) async {
    try {
      // 1. Create company
      final companyResponse = await _client
          .from('companies')
          .insert({
            'name': companyName,
            'trade': trade,
            'trades': [trade],
            'email': email,
          })
          .select()
          .single();

      final companyId = companyResponse['id'] as String;

      // 2. Create user row (triggers handle_new_user which sets JWT claims)
      final userResponse = await _client
          .from('users')
          .insert({
            'id': authUserId,
            'company_id': companyId,
            'email': email,
            'full_name': fullName,
            'role': 'owner',
            'trade': trade,
          })
          .select()
          .single();

      // 3. Update company with owner_user_id
      await _client
          .from('companies')
          .update({'owner_user_id': authUserId})
          .eq('id', companyId);

      // 4. Refresh session to get JWT with company_id + role
      await _auth.refreshSession();

      return (companyId: companyId, userProfile: userResponse);
    } catch (e) {
      throw DatabaseError(
        'Failed to create company: $e',
        userMessage: 'Could not set up your company. Please try again.',
        cause: e,
      );
    }
  }

  /// Record a login attempt for security auditing.
  Future<void> recordLoginAttempt({
    required String email,
    required bool success,
    String? failureReason,
  }) async {
    try {
      await _client.from('login_attempts').insert({
        'email': email.trim(),
        'success': success,
        'failure_reason': failureReason,
      });
    } catch (_) {
      // Don't throw — login attempt logging is non-critical
    }
  }

  // ============================================================
  // ERROR MAPPING
  // ============================================================

  AuthError _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.invalidCredentials,
        userMessage: 'Invalid email or password.',
        cause: e,
      );
    }
    if (msg.contains('already registered') ||
        msg.contains('user_already_exists')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.emailAlreadyInUse,
        userMessage: 'An account already exists with this email.',
        cause: e,
      );
    }
    if (msg.contains('weak_password') || msg.contains('password')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.weakPassword,
        userMessage: 'Password must be at least 6 characters.',
        cause: e,
      );
    }
    if (msg.contains('invalid_email') || msg.contains('invalid email')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.invalidEmail,
        userMessage: 'Please enter a valid email address.',
        cause: e,
      );
    }
    if (msg.contains('too_many_requests') ||
        msg.contains('rate_limit')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.tooManyRequests,
        userMessage: 'Too many attempts. Please try again later.',
        cause: e,
      );
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.networkError,
        userMessage: 'Network error. Check your connection.',
        cause: e,
      );
    }
    if (msg.contains('user_banned') || msg.contains('disabled')) {
      return AuthError(
        e.message,
        code: AuthErrorCode.userDisabled,
        userMessage: 'This account has been disabled. Contact support.',
        cause: e,
      );
    }

    return AuthError(
      e.message,
      code: AuthErrorCode.unknown,
      userMessage: 'Authentication failed. Please try again.',
      cause: e,
    );
  }
}
