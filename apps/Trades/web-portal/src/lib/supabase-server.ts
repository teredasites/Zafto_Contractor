// ZAFTO Web CRM — Supabase Server Client
// Sprint B4a | Session 48
//
// Used by server components and middleware.
// Creates a fresh client per request with cookie handling.

import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createServerSupabase() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Setting cookies in a Server Component is a no-op.
            // This is expected when called from a Server Component.
          }
        },
      },
    }
  );
}
