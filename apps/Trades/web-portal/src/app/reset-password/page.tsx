'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, Eye, EyeOff, CheckCircle2, AlertCircle, ArrowRight } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';
import type { AuthChangeEvent } from '@supabase/supabase-js';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [sessionReady, setSessionReady] = useState(false);
  const [checking, setChecking] = useState(true);

  // Wait for the Supabase client to pick up the recovery session
  useEffect(() => {
    const supabase = getSupabase();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event: AuthChangeEvent) => {
      if (event === 'PASSWORD_RECOVERY') {
        setSessionReady(true);
        setChecking(false);
      } else if (event === 'SIGNED_IN') {
        // Could be recovery or normal sign-in via the code exchange
        setSessionReady(true);
        setChecking(false);
      }
    });

    // Also check if there's already a session (code was exchanged via callback route)
    supabase.auth.getSession().then(({ data }: { data: { session: unknown } }) => {
      const session = data.session;
      if (session) {
        setSessionReady(true);
      }
      setChecking(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (password.length < 8) {
      setError('Password must be at least 8 characters');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);

    try {
      const supabase = getSupabase();
      const { error: updateError } = await supabase.auth.updateUser({ password });

      if (updateError) {
        if (updateError.message.includes('same as')) {
          setError('New password must be different from your current password');
        } else {
          setError(updateError.message);
        }
        return;
      }

      setSuccess(true);

      // Sign out so they can log in fresh with new password
      await supabase.auth.signOut();

      // Redirect to login after 2 seconds
      setTimeout(() => router.push('/'), 2000);
    } catch {
      setError('Failed to update password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (checking) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg)' }}>
        <div className="w-6 h-6 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <main className="min-h-screen flex items-center justify-center px-4" style={{ background: 'var(--bg-secondary)' }}>
      <div className="w-full max-w-[420px]">
        <div
          className="rounded-2xl border p-6 sm:p-8"
          style={{
            background: 'var(--surface)',
            borderColor: 'var(--border-light)',
            boxShadow: '0 25px 60px -12px rgba(0,0,0,0.15), 0 0 0 1px var(--border-light)',
          }}
        >
          {success ? (
            <div className="text-center py-6">
              <div
                className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4"
                style={{ background: 'var(--accent-light)' }}
              >
                <CheckCircle2 size={26} className="text-accent" />
              </div>
              <h3 className="text-base font-semibold text-main">Password updated</h3>
              <p className="text-[13px] text-muted mt-2 max-w-[280px] mx-auto">
                Your password has been changed. Redirecting to sign in...
              </p>
            </div>
          ) : !sessionReady ? (
            <div className="text-center py-6">
              <div
                className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4"
                style={{ background: 'rgba(239,68,68,0.1)' }}
              >
                <AlertCircle size={26} className="text-red-400" />
              </div>
              <h3 className="text-base font-semibold text-main">Invalid or expired link</h3>
              <p className="text-[13px] text-muted mt-2 max-w-[280px] mx-auto">
                This password reset link is invalid or has expired. Please request a new one.
              </p>
              <button
                onClick={() => router.push('/')}
                className="mt-5 inline-flex items-center gap-2 h-11 px-6 rounded-lg text-white text-sm font-semibold transition-all hover:brightness-110"
                style={{ background: 'var(--accent)' }}
              >
                Back to sign in
                <ArrowRight size={16} />
              </button>
            </div>
          ) : (
            <>
              <div className="text-center mb-6">
                <div
                  className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3"
                  style={{ background: 'var(--accent-light)' }}
                >
                  <Lock size={20} className="text-accent" />
                </div>
                <h2 className="text-xl font-semibold text-main tracking-tight">Set new password</h2>
                <p className="text-[13px] text-muted mt-1">Enter your new password below</p>
              </div>

              {error && (
                <div
                  className="mb-4 px-3.5 py-3 rounded-lg flex items-start gap-2.5 text-[13px]"
                  style={{ background: 'rgba(239,68,68,0.08)', color: '#ef4444' }}
                >
                  <AlertCircle size={15} className="mt-0.5 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1.5">
                  <label htmlFor="new-password" className="block text-[13px] font-medium text-main">
                    New password
                  </label>
                  <div className="relative">
                    <input
                      id="new-password"
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
                      placeholder="Min 8 characters"
                      required
                      autoComplete="new-password"
                      minLength={8}
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

                <div className="space-y-1.5">
                  <label htmlFor="confirm-password" className="block text-[13px] font-medium text-main">
                    Confirm password
                  </label>
                  <input
                    id="confirm-password"
                    type={showPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
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
                    placeholder="Re-enter password"
                    required
                    autoComplete="new-password"
                    minLength={8}
                  />
                </div>

                {/* Password strength hints */}
                <div className="space-y-1.5 pt-1">
                  {[
                    { label: 'At least 8 characters', met: password.length >= 8 },
                    { label: 'Contains a number', met: /\d/.test(password) },
                    { label: 'Contains uppercase & lowercase', met: /[a-z]/.test(password) && /[A-Z]/.test(password) },
                    { label: 'Passwords match', met: password.length > 0 && password === confirmPassword },
                  ].map((hint) => (
                    <div key={hint.label} className="flex items-center gap-2">
                      <div
                        className="w-3.5 h-3.5 rounded-full flex items-center justify-center"
                        style={{ background: hint.met ? 'var(--accent)' : 'var(--border)' }}
                      >
                        {hint.met && <CheckCircle2 size={10} className="text-white" />}
                      </div>
                      <span className="text-[11px]" style={{ color: hint.met ? 'var(--accent)' : 'var(--text-muted)' }}>
                        {hint.label}
                      </span>
                    </div>
                  ))}
                </div>

                <button
                  type="submit"
                  disabled={loading || password.length < 8 || password !== confirmPassword}
                  className="w-full h-11 rounded-lg text-white text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
                  style={{ background: 'var(--accent)' }}
                >
                  {loading ? (
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    'Update password'
                  )}
                </button>
              </form>
            </>
          )}
        </div>

        <p className="text-center text-[11px] text-muted/40 mt-6">
          &copy; {new Date().getFullYear()} Zafto &middot; All rights reserved
        </p>
      </div>
    </main>
  );
}
