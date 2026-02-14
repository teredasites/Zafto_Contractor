'use client';

import { Suspense, useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { signIn } from '@/lib/auth';
import { getSupabase } from '@/lib/supabase';
import { ArrowRight, AlertCircle, Eye, EyeOff, Sun, Moon } from 'lucide-react';
import { useTheme } from '@/components/theme-provider';

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { theme, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(true);
  const [resetSent, setResetSent] = useState(false);
  const [resetLoading, setResetLoading] = useState(false);

  useEffect(() => {
    const checkSession = async () => {
      const supabase = getSupabase();
      const errorParam = searchParams.get('error');
      if (errorParam === 'unauthorized') {
        await supabase.auth.signOut();
        setChecking(false);
        return;
      }
      const { data } = await supabase.auth.getUser();
      if (data.user) {
        router.replace('/dashboard');
      } else {
        setChecking(false);
      }
    };
    checkSession();
  }, [router, searchParams]);

  useEffect(() => {
    const errorParam = searchParams.get('error');
    if (errorParam === 'unauthorized') {
      setError('Access denied. This portal requires super_admin privileges.');
    }
  }, [searchParams]);

  const handleForgotPassword = async () => {
    if (!email) { setError('Enter your email first'); return; }
    setResetLoading(true);
    setError('');
    try {
      const { error: err } = await getSupabase().auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/dashboard`,
      });
      if (err) throw err;
      setResetSent(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to send reset email');
    } finally {
      setResetLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await signIn(email, password);
      const redirect = searchParams.get('redirect') || '/dashboard';
      router.replace(redirect);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed');
    } finally {
      setLoading(false);
    }
  };

  if (checking) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-page)' }}>
        <div className="w-6 h-6 border-2 border-[var(--accent)] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden"
      style={{ background: 'var(--bg-page)' }}>

      {/* Grid */}
      <div className="absolute inset-0 opacity-[0.03]"
        style={{ backgroundImage: 'linear-gradient(rgba(128,128,128,.3) 1px, transparent 1px), linear-gradient(90deg, rgba(128,128,128,.3) 1px, transparent 1px)', backgroundSize: '40px 40px' }} />

      {/* Blue glow */}
      <div className="absolute bottom-[-200px] left-[-100px] w-[500px] h-[500px] rounded-full opacity-10 blur-[120px] pointer-events-none"
        style={{ background: 'var(--accent, #5b7bf7)' }} />

      {/* Theme toggle */}
      <button onClick={toggleTheme}
        className="absolute top-5 right-5 z-10 p-2 rounded-lg transition-colors"
        style={{ color: 'var(--text-secondary)' }}
        onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text)'}
        onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}>
        {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
      </button>

      <div className="relative z-10 w-full max-w-[380px] px-6">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center gap-2.5 mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="36" height="36" style={{ color: 'var(--text)' }}>
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/></path>
              </g>
            </svg>
            <span className="text-lg font-semibold tracking-tight" style={{ color: 'var(--text)' }}>Zafto</span>
          </div>
          <h1 className="text-[22px] font-semibold tracking-tight" style={{ color: 'var(--text)' }}>Founder OS</h1>
          <p className="text-sm mt-1" style={{ color: 'var(--text-secondary)' }}>Internal operations portal</p>
        </div>

        {/* Card */}
        <div className="rounded-xl p-6 border"
          style={{ background: 'var(--bg-card)', borderColor: 'var(--border)' }}>

          {error && (
            <div className="mb-4 px-3.5 py-3 rounded-lg flex items-start gap-2.5 text-sm"
              style={{ background: 'rgba(239,68,68,0.08)', color: '#f87171' }}>
              <AlertCircle size={16} className="mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-[13px] font-medium" style={{ color: 'var(--text)' }}>Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)}
                className="w-full h-11 px-3.5 rounded-lg text-sm transition-all outline-none border"
                style={{ background: 'var(--bg-page)', borderColor: 'var(--border)', color: 'var(--text)' }}
                onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(91,123,247,0.12)'; }}
                onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                placeholder="admin@zafto.app" required autoFocus />
            </div>

            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="block text-[13px] font-medium" style={{ color: 'var(--text)' }}>Password</label>
                <button type="button" onClick={handleForgotPassword} disabled={resetLoading}
                  className="text-[11px] font-medium hover:underline disabled:opacity-50"
                  style={{ color: 'var(--accent)' }}>
                  {resetLoading ? 'Sending...' : 'Forgot password?'}
                </button>
              </div>
              <div className="relative">
                <input type={showPassword ? 'text' : 'password'} value={password}
                  onChange={e => setPassword(e.target.value)}
                  className="w-full h-11 px-3.5 pr-10 rounded-lg text-sm transition-all outline-none border"
                  style={{ background: 'var(--bg-page)', borderColor: 'var(--border)', color: 'var(--text)' }}
                  onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(91,123,247,0.12)'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                  placeholder="Enter your password" required />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 transition-colors"
                  style={{ color: 'var(--text-secondary)' }}>
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading}
              className="w-full h-11 rounded-lg text-white text-sm font-medium flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
              style={{ background: 'var(--accent, #5b7bf7)' }}>
              {loading ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  Sign In
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>
        </div>

        {resetSent && (
          <div className="mt-4 px-4 py-3 rounded-lg text-center text-[13px]"
            style={{ background: 'rgba(91,123,247,0.08)', color: 'var(--accent)' }}>
            Password reset link sent to <strong>{email}</strong>
          </div>
        )}
        <p className="text-center text-[12px] mt-6" style={{ color: 'var(--text-secondary)', opacity: 0.5 }}>
          Restricted access &middot; Unauthorized use is prohibited
        </p>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-page)' }}>
          <div className="w-6 h-6 border-2 border-[var(--accent)] border-t-transparent rounded-full animate-spin" />
        </div>
      }
    >
      <LoginForm />
    </Suspense>
  );
}
