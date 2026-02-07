'use client';

// ZAFTO Auth Provider — Supabase Auth
// Sprint B4a | Session 48
//
// Replaces Firebase auth listener with Supabase onAuthStateChange.
// Provides user + company + role from users table.

import { createContext, useContext, useEffect, useState } from 'react';
import { onAuthChange } from '@/lib/auth';
import { getSupabase } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';

interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  companyId: string | null;
  role: string | null;
  trade: string | null;
  avatarUrl: string | null;
}

interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  loading: true,
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthChange(async (authUser) => {
      setUser(authUser);

      if (authUser) {
        // Fetch user profile from users table.
        try {
          const supabase = getSupabase();
          const { data } = await supabase
            .from('users')
            .select('id, email, display_name, company_id, role, trade, avatar_url')
            .eq('id', authUser.id)
            .single();

          if (data) {
            setProfile({
              uid: data.id,
              email: data.email,
              displayName: data.display_name,
              companyId: data.company_id,
              role: data.role,
              trade: data.trade,
              avatarUrl: data.avatar_url,
            });
          } else {
            setProfile(null);
          }
        } catch {
          setProfile(null);
        }
      } else {
        setProfile(null);
      }

      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
