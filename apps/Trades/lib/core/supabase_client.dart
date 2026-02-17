// ZAFTO Supabase Client
// Created: Sprint A3a (Session 39)
//
// Initialize in main() before runApp().
// Usage: import 'package:zafto/core/supabase_client.dart';
//        final client = supabase;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

late final EnvConfig _envConfig;

/// Initialize Supabase with the given environment config.
/// Must be called once in main() before runApp().
Future<void> initSupabase(EnvConfig config) async {
  _envConfig = config;
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
    debug: config.enableDebug,
    headers: {
      'X-Requested-With': 'ZaftoMobile',
    },
  );
}

/// The Supabase client instance. Only use after initSupabase() completes.
SupabaseClient get supabase => Supabase.instance.client;

/// The current environment config.
EnvConfig get envConfig => _envConfig;

/// Convenience: current authenticated user (null if not logged in).
User? get currentUser => supabase.auth.currentUser;

/// Convenience: current session (null if not logged in).
Session? get currentSession => supabase.auth.currentSession;

/// Convenience: auth state change stream.
Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;
