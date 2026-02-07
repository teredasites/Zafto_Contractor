import { getSupabase } from './supabase';
import type { User, AuthChangeEvent, Session } from '@supabase/supabase-js';

export async function signIn(email: string, password: string) {
  const supabase = getSupabase();
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data;
}

export async function signOut() {
  const supabase = getSupabase();
  const { error } = await supabase.auth.signOut();
  if (error) {
    throw new Error(error.message);
  }
}

export function onAuthChange(
  callback: (event: AuthChangeEvent, session: Session | null) => void
) {
  const supabase = getSupabase();
  const { data } = supabase.auth.onAuthStateChange(callback);
  return data.subscription;
}

export async function getCurrentUser(): Promise<User | null> {
  const supabase = getSupabase();
  const { data } = await supabase.auth.getUser();
  return data.user;
}

export async function isSuperAdmin(userId: string): Promise<boolean> {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single();

  if (error || !data) {
    return false;
  }

  return data.role === 'super_admin';
}
