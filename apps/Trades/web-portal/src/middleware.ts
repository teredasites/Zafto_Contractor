// ZAFTO Web CRM — Auth + RBAC + i18n Middleware
// Sprint B4a | Session 48 | RBAC added Session 55 | i18n added U13
//
// Protects /dashboard/* routes. Verifies auth AND role.
// Allowed roles: owner, admin, office_manager, cpa, super_admin
// Sets NEXT_LOCALE cookie from user preferred_locale.

import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

const CRM_ALLOWED_ROLES = ['owner', 'admin', 'office_manager', 'cpa', 'super_admin'];

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({
            request,
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // Refresh the session — this is required to keep the session alive.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Protected routes: /dashboard/*
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) {
      const url = request.nextUrl.clone();
      url.pathname = '/';
      url.searchParams.set('redirect', request.nextUrl.pathname);
      return NextResponse.redirect(url);
    }

    // Verify role + read locale preference from users table (single query)
    const { data: profile, error: profileError } = await supabase
      .from('users')
      .select('role, preferred_locale')
      .eq('id', user.id)
      .single();

    // If the users table query fails (RLS, network, no row), check JWT metadata as fallback
    if (profileError || !profile) {
      const jwtRole = user.app_metadata?.role as string | undefined;
      if (!jwtRole || !CRM_ALLOWED_ROLES.includes(jwtRole)) {
        const url = request.nextUrl.clone();
        url.pathname = '/';
        url.searchParams.set('error', 'unauthorized');
        return NextResponse.redirect(url);
      }
      // JWT role is valid — allow through without locale check
    } else if (!CRM_ALLOWED_ROLES.includes(profile.role)) {
      const url = request.nextUrl.clone();
      url.pathname = '/';
      url.searchParams.set('error', 'unauthorized');
      return NextResponse.redirect(url);
    } else {
      // Role is valid — set locale cookie from user preference
      const userLocale = profile.preferred_locale || 'en';
      const currentLocale = request.cookies.get('NEXT_LOCALE')?.value;
      if (userLocale !== currentLocale) {
        supabaseResponse.cookies.set('NEXT_LOCALE', userLocale, {
          path: '/',
          maxAge: 60 * 60 * 24 * 365,
          sameSite: 'lax',
        });
      }
    }
  }

  // If on login page and already authenticated, redirect to dashboard.
  // But NOT if they were just kicked back for an auth error (prevents redirect loop).
  if (request.nextUrl.pathname === '/' && user && !request.nextUrl.searchParams.has('error')) {
    const url = request.nextUrl.clone();
    url.pathname = '/dashboard';
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}

export const config = {
  matcher: [
    // Match all routes except static files and API routes.
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
