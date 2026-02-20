// Hellhound SEC7 S131 — application-level request filtering
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

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
        setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
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

  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Protect dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) {
      const url = request.nextUrl.clone();
      url.pathname = '/';
      url.searchParams.set('redirect', request.nextUrl.pathname);
      return NextResponse.redirect(url);
    }

    // Check super_admin role from user metadata or users table
    const { data: profile } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (!profile || profile.role !== 'super_admin') {
      const url = request.nextUrl.clone();
      url.pathname = '/';
      url.searchParams.set('error', 'unauthorized');
      return NextResponse.redirect(url);
    }
  }

  return supabaseResponse;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
