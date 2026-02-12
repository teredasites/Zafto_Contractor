'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowRight, AlertCircle, Eye, EyeOff, Lock, Shield,
  Fingerprint, Mail, Sun, Moon, CheckCircle2, ExternalLink,
} from 'lucide-react';
import { signIn, onAuthChange } from '@/lib/auth';
import { useTheme } from '@/components/theme-provider';
import Image from 'next/image';

type PortalType = 'team' | 'customer';

const portalConfig: Record<PortalType, { label: string; desc: string }> = {
  team: { label: 'Team', desc: 'Manage bids, jobs, invoices, scheduling & field tools' },
  customer: { label: 'Customer', desc: 'View projects, invoices & communication' },
};

export default function LoginPage() {
  const router = useRouter();
  const { theme, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [selectedPortal, setSelectedPortal] = useState<PortalType>('team');
  const [magicLinkSent, setMagicLinkSent] = useState(false);
  const [magicLinkLoading, setMagicLinkLoading] = useState(false);

  // Check for redirect error param
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const params = new URLSearchParams(window.location.search);
    if (params.get('error') === 'unauthorized') {
      setError('You do not have permission to access that page');
    }
  }, []);

  // After auth, route by role — all same-domain, no cross-subdomain issues
  const routeByRole = async (userId: string) => {
    try {
      const { getSupabase } = await import('@/lib/supabase');
      const supabase = getSupabase();
      const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();

      const role = profile?.role || '';

      if (role === 'cpa') {
        router.push('/dashboard/books');
      } else {
        router.push('/dashboard');
      }
    } catch {
      // Fallback — middleware will handle unauthorized roles
      router.push('/dashboard');
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthChange((user) => {
      if (user) {
        routeByRole(user.id);
      } else {
        setCheckingAuth(false);
      }
    });
    return () => unsubscribe();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [router]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    const { user, error: loginError } = await signIn(email, password);

    if (loginError) {
      setError(loginError);
      setIsLoading(false);
    } else if (user) {
      await routeByRole(user.id);
    }
  };

  const handleMagicLink = async () => {
    if (!email) {
      setError('Enter your email address first');
      return;
    }
    setMagicLinkLoading(true);
    setError('');
    try {
      const { getSupabase } = await import('@/lib/supabase');
      const supabase = getSupabase();
      const { error: otpError } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: `${window.location.origin}/dashboard` },
      });
      if (otpError) throw otpError;
      setMagicLinkSent(true);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to send magic link';
      setError(message);
    } finally {
      setMagicLinkLoading(false);
    }
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg)' }}>
        <div className="w-6 h-6 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <main className="min-h-screen flex flex-col" style={{ background: 'var(--bg-secondary)' }}>
      {/* Hero Image with Diagonal Clip */}
      <div
        className="relative w-full h-[260px] sm:h-[300px] lg:h-[340px] flex-shrink-0"
        style={{ clipPath: 'polygon(0 0, 100% 0, 100% 78%, 0 100%)' }}
      >
        <Image
          src="/login-hero.jpg"
          alt="Professional blueprints"
          fill
          className="object-cover"
          priority
          sizes="100vw"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/40 to-black/70" />

        {/* Header bar */}
        <div className="absolute top-0 left-0 right-0 p-5 sm:p-6 flex items-center justify-between z-10">
          <span className="text-xl font-bold text-white tracking-tight">zafto</span>
          <button
            onClick={toggleTheme}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-white/70 hover:text-white transition-all"
            style={{ background: 'rgba(255,255,255,0.15)' }}
          >
            {theme === 'dark' ? <Sun size={14} /> : <Moon size={14} />}
            <span className="text-[11px] font-medium">{theme === 'dark' ? 'Light' : 'Dark'}</span>
          </button>
        </div>

        {/* Centered tagline */}
        <div className="absolute inset-0 flex items-center justify-center z-10 px-6 pb-8">
          <div className="text-center">
            <h1 className="text-white text-2xl sm:text-3xl font-bold tracking-tight">
              One platform. Every trade.
            </h1>
            <p className="text-white/50 text-sm mt-2 max-w-[360px] mx-auto">
              Bids, jobs, invoices, field tools, and team management — all in one place.
            </p>
          </div>
        </div>
      </div>

      {/* Form Section — overlaps hero */}
      <div className="flex-1 flex justify-center px-4 sm:px-6 -mt-12 sm:-mt-14 pb-8 relative z-20">
        <div className="w-full max-w-[420px]">
          {/* Form Card */}
          <div
            className="rounded-2xl border p-6 sm:p-8"
            style={{
              background: 'var(--surface)',
              borderColor: 'var(--border-light)',
              boxShadow: '0 25px 60px -12px rgba(0,0,0,0.15), 0 0 0 1px var(--border-light)',
            }}
          >
            {/* Header */}
            <div className="text-center mb-6">
              <h2 className="text-xl font-semibold text-main tracking-tight">Welcome back</h2>
              <p className="text-[13px] text-muted mt-1">Sign in to your account</p>
            </div>

            {/* Portal Selector — 2 tabs */}
            <div
              className="grid grid-cols-2 gap-1 p-1 rounded-xl mb-5"
              style={{ background: 'var(--bg-secondary)' }}
            >
              {(Object.keys(portalConfig) as PortalType[]).map((portal) => (
                <button
                  key={portal}
                  onClick={() => setSelectedPortal(portal)}
                  className="relative py-2 px-3 rounded-lg text-xs font-medium transition-all"
                  style={{
                    background: selectedPortal === portal ? 'var(--accent)' : 'transparent',
                    color: selectedPortal === portal ? '#fff' : 'var(--text-muted)',
                    boxShadow: selectedPortal === portal ? '0 2px 8px rgba(16,185,129,0.3)' : 'none',
                  }}
                >
                  {portalConfig[portal].label}
                </button>
              ))}
            </div>

            {/* Portal description */}
            <p className="text-[11px] text-muted text-center mb-5 -mt-1">
              {portalConfig[selectedPortal].desc}
            </p>

            {/* Error */}
            {error && (
              <div
                className="mb-4 px-3.5 py-3 rounded-lg flex items-start gap-2.5 text-[13px]"
                style={{ background: 'rgba(239,68,68,0.08)', color: '#ef4444' }}
              >
                <AlertCircle size={15} className="mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {selectedPortal === 'customer' ? (
              /* Customer Portal — redirect to client.zafto.cloud */
              <div className="text-center py-6">
                <div
                  className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4"
                  style={{ background: 'var(--accent-light)' }}
                >
                  <ExternalLink size={24} className="text-accent" />
                </div>
                <h3 className="text-base font-semibold text-main">Customer Portal</h3>
                <p className="text-[13px] text-muted mt-2 max-w-[280px] mx-auto">
                  Access your projects, invoices, and messages through the customer portal.
                </p>
                <a
                  href="https://client.zafto.cloud"
                  className="mt-5 inline-flex items-center gap-2 h-11 px-6 rounded-lg text-white text-sm font-semibold transition-all hover:brightness-110"
                  style={{ background: 'var(--accent)' }}
                >
                  Go to Customer Portal
                  <ArrowRight size={16} />
                </a>
              </div>
            ) : magicLinkSent ? (
              /* Magic Link Confirmation */
              <div className="text-center py-6">
                <div
                  className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4"
                  style={{ background: 'var(--accent-light)' }}
                >
                  <CheckCircle2 size={26} className="text-accent" />
                </div>
                <h3 className="text-base font-semibold text-main">Check your email</h3>
                <p className="text-[13px] text-muted mt-2 max-w-[280px] mx-auto">
                  We sent a sign-in link to{' '}
                  <strong className="text-main">{email}</strong>
                </p>
                <button
                  onClick={() => setMagicLinkSent(false)}
                  className="mt-5 text-[13px] text-accent font-medium hover:underline"
                >
                  Use password instead
                </button>
              </div>
            ) : (
              <>
                {/* Login Form */}
                <form onSubmit={handleLogin} className="space-y-4">
                  <div className="space-y-1.5">
                    <label htmlFor="email" className="block text-[13px] font-medium text-main">
                      Email address
                    </label>
                    <input
                      id="email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full h-11 px-3.5 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                      style={{ background: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
                      onFocus={(e) => {
                        e.target.style.borderColor = 'var(--accent)';
                        e.target.style.boxShadow = '0 0 0 3px rgba(16,185,129,0.1)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = 'var(--border)';
                        e.target.style.boxShadow = 'none';
                      }}
                      placeholder="you@company.com"
                      required
                      autoComplete="email"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <div className="flex items-center justify-between">
                      <label htmlFor="password" className="block text-[13px] font-medium text-main">
                        Password
                      </label>
                      <button type="button" className="text-[11px] font-medium text-accent hover:underline">
                        Forgot password?
                      </button>
                    </div>
                    <div className="relative">
                      <input
                        id="password"
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full h-11 px-3.5 pr-10 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                        style={{ background: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
                        onFocus={(e) => {
                          e.target.style.borderColor = 'var(--accent)';
                          e.target.style.boxShadow = '0 0 0 3px rgba(16,185,129,0.1)';
                        }}
                        onBlur={(e) => {
                          e.target.style.borderColor = 'var(--border)';
                          e.target.style.boxShadow = 'none';
                        }}
                        placeholder="Enter your password"
                        required
                        autoComplete="current-password"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-main transition-colors"
                      >
                        {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full h-11 rounded-lg text-white text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
                    style={{ background: 'var(--accent)' }}
                  >
                    {isLoading ? (
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    ) : (
                      <>
                        Sign in
                        <ArrowRight size={16} />
                      </>
                    )}
                  </button>
                </form>

                {/* Divider */}
                <div className="flex items-center gap-3 my-5">
                  <div className="flex-1 h-px" style={{ background: 'var(--border-light)' }} />
                  <span className="text-[10px] text-muted uppercase tracking-widest font-medium">or</span>
                  <div className="flex-1 h-px" style={{ background: 'var(--border-light)' }} />
                </div>

                {/* Magic Link */}
                <button
                  onClick={handleMagicLink}
                  disabled={magicLinkLoading}
                  className="w-full h-11 rounded-lg text-sm font-medium flex items-center justify-center gap-2 transition-all border"
                  style={{ borderColor: 'var(--border)', color: 'var(--text)' }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = 'var(--surface-hover)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = 'transparent';
                  }}
                >
                  {magicLinkLoading ? (
                    <div className="w-4 h-4 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
                  ) : (
                    <>
                      <Mail size={16} />
                      Sign in with magic link
                    </>
                  )}
                </button>

                {/* Field employee link */}
                <p className="text-center text-[12px] text-muted mt-5">
                  Field employee?{' '}
                  <a href="https://team.zafto.cloud" className="text-accent font-medium hover:underline">
                    Sign in at team.zafto.cloud
                  </a>
                </p>

                {/* Contact sales */}
                <p className="text-center text-[13px] text-muted mt-3">
                  Need an account?{' '}
                  <a href="mailto:admin@zafto.app" className="text-accent font-medium hover:underline">
                    Contact sales
                  </a>
                </p>
              </>
            )}
          </div>

          {/* Security Badges */}
          <div className="mt-6 flex items-center justify-center gap-5 sm:gap-6">
            <div className="flex items-center gap-1.5">
              <Lock size={13} className="text-accent" />
              <span className="text-[11px] text-muted font-medium">256-bit TLS</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Shield size={13} className="text-accent" />
              <span className="text-[11px] text-muted font-medium">2FA</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Fingerprint size={13} className="text-accent" />
              <span className="text-[11px] text-muted font-medium">Biometric</span>
            </div>
          </div>

          {/* Security Notice */}
          <p className="text-center text-[10px] text-muted/50 mt-4 leading-relaxed max-w-[340px] mx-auto">
            Your connection is encrypted with TLS 1.3 and AES-256.
            All data is encrypted at rest. Multi-factor authentication available.
          </p>

          {/* Footer */}
          <p className="text-center text-[11px] text-muted/40 mt-6">
            &copy; {new Date().getFullYear()} Tereda Software LLC &middot; All rights reserved
          </p>
        </div>
      </div>
    </main>
  );
}
