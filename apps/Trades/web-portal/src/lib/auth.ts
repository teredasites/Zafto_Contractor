// ZAFTO Web CRM — Supabase Auth
// Sprint B4a | Session 48
//
// Replaces Firebase Auth. Same API surface (signIn, signOut, onAuthChange)
// so consumers migrate with minimal changes.

import { getSupabase } from './supabase';
import type { User, AuthChangeEvent, Session } from '@supabase/supabase-js';

export type { User };

export async function signIn(email: string, password: string) {
  try {
    const supabase = getSupabase();
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      let message = 'An error occurred during sign in';

      if (error.message.includes('Invalid login credentials')) {
        message = 'Invalid email or password';
      } else if (error.message.includes('Email not confirmed')) {
        message = 'Please verify your email address';
      } else if (error.message.includes('too many requests')) {
        message = 'Too many attempts. Please try again later';
      } else if (error.message.includes('User not found')) {
        message = 'No account found with this email';
      }

      return { user: null, error: message };
    }

    return { user: data.user, error: null };
  } catch {
    return { user: null, error: 'An error occurred during sign in' };
  }
}

export async function signOut() {
  try {
    const supabase = getSupabase();
    await supabase.auth.signOut();
    return { error: null };
  } catch {
    return { error: 'Failed to sign out' };
  }
}

export function onAuthChange(callback: (user: User | null) => void) {
  const supabase = getSupabase();
  const {
    data: { subscription },
  } = supabase.auth.onAuthStateChange((_event: AuthChangeEvent, session: Session | null) => {
    callback(session?.user ?? null);
  });

  // Check current user immediately (getUser() is server-verified, unlike getSession()).
  void (async () => {
    const { data } = await supabase.auth.getUser();
    callback(data.user ?? null);
  })();

  return () => subscription.unsubscribe();
}
