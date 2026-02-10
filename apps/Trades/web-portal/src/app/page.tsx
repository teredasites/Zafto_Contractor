'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowRight, AlertCircle, Eye, EyeOff, Lock, Shield,
  Fingerprint, Mail, Sun, Moon, CheckCircle2,
} from 'lucide-react';
import { signIn, onAuthChange } from '@/lib/auth';
import { useTheme } from '@/components/theme-provider';
import Image from 'next/image';

type PortalType = 'contractor' | 'employee' | 'customer' | 'cpa';

const portalConfig: Record<PortalType, { label: string; desc: string }> = {
  contractor: { label: 'Contractor', desc: 'Manage bids, jobs, invoices & team' },
  employee: { label: 'Employee', desc: 'Schedule, time clock & field tools' },
  customer: { label: 'Customer', desc: 'Projects, invoices & communication' },
  cpa: { label: 'CPA', desc: 'Financial reports & accounting access' },
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
  const [selectedPortal, setSelectedPortal] = useState<PortalType>('contractor');
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

  useEffect(() => {
    const unsubscribe = onAuthChange((user) => {
      if (user) {
        router.push('/dashboard');
      } else {
        setCheckingAuth(false);
      }
    });
    return () => unsubscribe();
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
      router.push('/dashboard');
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
        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/40 to-black/70" />

        {/* Header bar */}
        <div className="absolute top-0 left-0 right-0 p-5 sm:p-6 flex items-center justify-between z-10">
          <div className="flex items-center gap-2.5">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="32" height="32" className="text-white">
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)">
                  <animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/>
                </path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)">
                  <animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/>
                </path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round">
                  <animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/>
                </path>
              </g>
            </svg>
            <span className="text-lg font-semibold text-white tracking-tight">Zafto</span>
          </div>
          <button
            onClick={toggleTheme}
            className="p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-colors"
          >
            {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
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

            {/* Portal Selector */}
            <div
              className="grid grid-cols-4 gap-1 p-1 rounded-xl mb-5"
              style={{ background: 'var(--bg-secondary)' }}
            >
              {(Object.keys(portalConfig) as PortalType[]).map((portal) => (
                <button
                  key={portal}
                  onClick={() => setSelectedPortal(portal)}
                  className="relative py-2 px-1 rounded-lg text-[11px] sm:text-xs font-medium transition-all"
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

            {magicLinkSent ? (
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

                {/* Contact sales */}
                <p className="text-center text-[13px] text-muted mt-5">
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
