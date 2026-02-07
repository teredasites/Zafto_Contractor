'use client';

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { getSupabase } from '@/lib/supabase';
import { setSentryUser, clearSentryUser } from '@/lib/sentry';
import type { User, AuthChangeEvent, Session } from '@supabase/supabase-js';

interface ClientProfile {
  id: string;
  email: string;
  displayName: string;
  customerId: string | null;
  companyId: string | null;
}

interface AuthContextType {
  user: User | null;
  profile: ClientProfile | null;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  loading: true,
  signOut: async () => {},
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<ClientProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const supabase = getSupabase();

    async function loadUser() {
      const { data: { user: authUser } } = await supabase.auth.getUser();
      setUser(authUser);

      if (authUser) {
        // Try to get client profile from client_portal_users table
        const { data: clientUser } = await supabase
          .from('client_portal_users')
          .select('*')
          .eq('auth_user_id', authUser.id)
          .single();

        if (clientUser) {
          setProfile({
            id: clientUser.id,
            email: authUser.email || '',
            displayName: clientUser.display_name || authUser.email?.split('@')[0] || '',
            customerId: clientUser.customer_id,
            companyId: clientUser.company_id,
          });
          setSentryUser(clientUser.id, clientUser.company_id ?? undefined, 'client');
        } else {
          // Fallback: minimal profile from auth
          setProfile({
            id: authUser.id,
            email: authUser.email || '',
            displayName: authUser.user_metadata?.full_name || authUser.email?.split('@')[0] || '',
            customerId: null,
            companyId: null,
          });
          setSentryUser(authUser.id, undefined, 'client');
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    }

    loadUser();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event: AuthChangeEvent, session: Session | null) => {
      if (session?.user) {
        setUser(session.user);
        loadUser();
      } else {
        setUser(null);
        setProfile(null);
        clearSentryUser();
        setLoading(false);
      }
    });

    return () => { subscription.unsubscribe(); };
  }, []);

  const handleSignOut = async () => {
    const supabase = getSupabase();
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
    clearSentryUser();
  };

  return (
    <AuthContext.Provider value={{ user, profile, loading, signOut: handleSignOut }}>
      {children}
    </AuthContext.Provider>
  );
}
