// ZAFTO Web CRM — Supabase Auth

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

export async function signUp(email: string, password: string, fullName: string) {
  try {
    const supabase = getSupabase();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: fullName },
        emailRedirectTo: `${typeof window !== 'undefined' ? window.location.origin : ''}/dashboard`,
      },
    });

    if (error) {
      let message = 'An error occurred during sign up';

      if (error.message.includes('already registered')) {
        message = 'An account with this email already exists';
      } else if (error.message.includes('password')) {
        message = 'Password must be at least 6 characters';
      } else if (error.message.includes('too many requests')) {
        message = 'Too many attempts. Please try again later';
      }

      return { user: null, error: message };
    }

    return { user: data.user, error: null };
  } catch {
    return { user: null, error: 'An error occurred during sign up' };
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
