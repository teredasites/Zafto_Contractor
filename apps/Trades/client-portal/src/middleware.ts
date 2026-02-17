// ZAFTO Client Portal — Auth + RBAC Middleware
// Sprint B6 | RBAC added Session 55 | Hellhound SEC7 S131
//
// Protects all routes except / and /auth/*.
// Verifies auth AND checks client_portal_users table.
// Also allows super_admin from users table (for testing).
// Hellhound: blocks common attack paths and malicious user-agents.

import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

// Hellhound — application-level request filtering
const BLOCKED_PATHS = [
  '/.env', '/.git', '/.svn', '/.htaccess', '/.htpasswd',
  '/wp-admin', '/wp-login.php', '/wp-content', '/xmlrpc.php',
  '/phpmyadmin', '/admin.php', '/server-status', '/server-info',
  '/cgi-bin', '/config.php', '/debug', '/trace',
];
const BLOCKED_UA_PATTERNS = /sqlmap|nikto|dirbuster|gobuster|nmap|nuclei|masscan|zgrab|httpx|subfinder|amass|wpscan/i;

export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname.toLowerCase();
  if (BLOCKED_PATHS.some(p => pathname.startsWith(p))) {
    return new NextResponse(null, { status: 403 });
  }
  const ua = request.headers.get('user-agent') || '';
  if (BLOCKED_UA_PATTERNS.test(ua)) {
    return new NextResponse(null, { status: 403 });
  }

  let response = NextResponse.next({ request: { headers: request.headers } });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value);
            response = NextResponse.next({ request: { headers: request.headers } });
            response.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  // pathname already defined above (line 22) for Hellhound checks

  // Public routes: login, auth callback
  const isPublicRoute = pathname === '/' || pathname.startsWith('/auth/');

  if (!user && !isPublicRoute) {
    return NextResponse.redirect(new URL('/', request.url));
  }

  // Role check for authenticated users on protected routes
  if (user && !isPublicRoute) {
    // Check if user has a client_portal_users record
    const { data: clientProfile } = await supabase
      .from('client_portal_users')
      .select('id, preferred_locale')
      .eq('auth_user_id', user.id)
      .single();

    if (!clientProfile) {
      // Fallback: allow super_admin from users table (for testing)
      const { data: adminProfile } = await supabase
        .from('users')
        .select('role, preferred_locale')
        .eq('id', user.id)
        .single();

      if (!adminProfile || adminProfile.role !== 'super_admin') {
        const redirectUrl = new URL('/', request.url);
        redirectUrl.searchParams.set('error', 'unauthorized');
        return NextResponse.redirect(redirectUrl);
      }

      // Set locale from admin profile
      const adminLocale = adminProfile.preferred_locale || 'en';
      const currentLocale = request.cookies.get('NEXT_LOCALE')?.value;
      if (adminLocale !== currentLocale) {
        response.cookies.set('NEXT_LOCALE', adminLocale, { path: '/', maxAge: 60 * 60 * 24 * 365, sameSite: 'lax' });
      }
    } else {
      // Set locale from client profile
      const clientLocale = clientProfile.preferred_locale || 'en';
      const currentLocale = request.cookies.get('NEXT_LOCALE')?.value;
      if (clientLocale !== currentLocale) {
        response.cookies.set('NEXT_LOCALE', clientLocale, { path: '/', maxAge: 60 * 60 * 24 * 365, sameSite: 'lax' });
      }
    }
  }

  if (user && pathname === '/' && !request.nextUrl.searchParams.has('error')) {
    return NextResponse.redirect(new URL('/home', request.url));
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|logo.svg|manifest.json|.*\\.png$).*)'],
};
