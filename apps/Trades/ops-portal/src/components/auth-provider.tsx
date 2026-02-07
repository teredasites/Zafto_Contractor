'use client';

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from 'react';
import { useRouter } from 'next/navigation';
import { getSupabase } from '@/lib/supabase';
import { signOut as authSignOut, onAuthChange } from '@/lib/auth';
import { setSentryUser, clearSentryUser } from '@/lib/sentry';
import type { User } from '@supabase/supabase-js';

interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  company_id: string | null;
  avatar_url: string | null;
}

interface AuthContextValue {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  profile: null,
  loading: true,
  signOut: async () => {},
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchProfile = useCallback(async (userId: string, email: string) => {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('users')
      .select('id, full_name, email, role, company_id, avatar_url')
      .eq('id', userId)
      .single();

    if (error || !data) {
      return null;
    }

    if (data.role !== 'super_admin') {
      return null;
    }

    const userProfile: UserProfile = {
      id: data.id,
      name: data.full_name || email,
      email: data.email || email,
      role: data.role,
      company_id: data.company_id || null,
      avatar_url: data.avatar_url || null,
    };

    setSentryUser({ id: userProfile.id, email: userProfile.email, role: userProfile.role });

    return userProfile;
  }, []);

  useEffect(() => {
    const initAuth = async () => {
      const supabase = getSupabase();
      const { data } = await supabase.auth.getUser();

      if (data.user) {
        setUser(data.user);
        const prof = await fetchProfile(data.user.id, data.user.email || '');
        if (prof) {
          setProfile(prof);
        } else {
          // Not super_admin — sign out and redirect
          await authSignOut();
          router.replace('/?error=unauthorized');
        }
      }

      setLoading(false);
    };

    initAuth();

    const subscription = onAuthChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        setUser(session.user);
        const prof = await fetchProfile(session.user.id, session.user.email || '');
        if (prof) {
          setProfile(prof);
        }
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setProfile(null);
        clearSentryUser();
        router.replace('/');
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [router, fetchProfile]);

  const handleSignOut = async () => {
    clearSentryUser();
    await authSignOut();
    setUser(null);
    setProfile(null);
    router.replace('/');
  };

  return (
    <AuthContext.Provider
      value={{ user, profile, loading, signOut: handleSignOut }}
    >
      {children}
    </AuthContext.Provider>
  );
}
