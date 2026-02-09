'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ArrowRight, AlertCircle, Eye, EyeOff, Sun, Moon } from 'lucide-react';
import { signIn, onAuthChange } from '@/lib/auth';
import { useTheme } from '@/components/theme-provider';

export default function Home() {
  const router = useRouter();
  const { theme, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [checkingAuth, setCheckingAuth] = useState(true);

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

    const { user, error } = await signIn(email, password);

    if (error) {
      setError(error);
      setIsLoading(false);
    } else if (user) {
      router.push('/dashboard');
    }
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-page, var(--bg))' }}>
        <div className="w-6 h-6 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <main className="min-h-screen flex">
      {/* Left panel — branding */}
      <div className="hidden lg:flex lg:w-[480px] xl:w-[520px] relative overflow-hidden flex-col justify-between p-10"
        style={{ background: 'linear-gradient(135deg, #0a0a0a 0%, #111 50%, #0a0a0a 100%)' }}>
        {/* Subtle grid */}
        <div className="absolute inset-0 opacity-[0.03]"
          style={{ backgroundImage: 'linear-gradient(rgba(255,255,255,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.1) 1px, transparent 1px)', backgroundSize: '48px 48px' }} />

        {/* Glow orb */}
        <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full opacity-20 blur-[100px]"
          style={{ background: 'var(--accent)' }} />

        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="36" height="36" className="text-white">
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/></path>
              </g>
            </svg>
            <span className="text-lg font-semibold text-white tracking-tight">Zafto</span>
          </div>
        </div>

        <div className="relative z-10 space-y-6">
          <h1 className="text-[40px] font-bold leading-[1.1] text-white tracking-tight">
            Run your trades<br />business smarter.
          </h1>
          <p className="text-[15px] text-white/50 leading-relaxed max-w-[340px]">
            Bids, jobs, invoices, scheduling, and team management — unified in one platform built for contractors.
          </p>

          <div className="grid grid-cols-2 gap-3 pt-2">
            {[
              { label: 'Bids & Estimates', value: 'Create & win' },
              { label: 'Job Tracking', value: 'Real-time status' },
              { label: 'Invoicing', value: 'Get paid faster' },
              { label: 'Team Dispatch', value: 'Field coordination' },
            ].map((item) => (
              <div key={item.label} className="px-4 py-3 rounded-lg border border-white/[0.06] bg-white/[0.02]">
                <div className="text-[13px] font-medium text-white/80">{item.label}</div>
                <div className="text-[12px] text-white/35 mt-0.5">{item.value}</div>
              </div>
            ))}
          </div>
        </div>

        <p className="relative z-10 text-[12px] text-white/25">
          Built for trades professionals
        </p>
      </div>

      {/* Right panel — login form */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-8 relative" style={{ background: 'var(--bg-page, var(--bg))' }}>
        {/* Theme toggle */}
        <button onClick={toggleTheme}
          className="absolute top-5 right-5 p-2 rounded-lg transition-colors text-muted hover:text-main hover:bg-surface-hover">
          {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        <div className="w-full max-w-[380px]">
          {/* Mobile logo */}
          <div className="lg:hidden mb-8 flex items-center justify-center gap-2.5">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="32" height="32" className="text-main">
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/></path>
              </g>
            </svg>
            <span className="text-xl font-semibold text-main tracking-tight">Zafto</span>
          </div>

          <div className="space-y-6">
            <div>
              <h2 className="text-[22px] font-semibold text-main tracking-tight">Welcome back</h2>
              <p className="text-sm text-muted mt-1">Sign in to your dashboard</p>
            </div>

            {error && (
              <div className="px-3.5 py-3 rounded-lg flex items-start gap-2.5 text-sm"
                style={{ background: 'var(--error-light, rgba(239,68,68,0.08))', color: 'var(--error, #ef4444)' }}>
                <AlertCircle size={16} className="mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor="email" className="block text-[13px] font-medium text-main">Email</label>
                <input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                  className="w-full h-11 px-3.5 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                  style={{ background: 'var(--bg-secondary, var(--surface))', borderColor: 'var(--border)' }}
                  onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px var(--accent-glow, rgba(16,185,129,0.1))'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                  placeholder="you@company.com" required />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="password" className="block text-[13px] font-medium text-main">Password</label>
                <div className="relative">
                  <input id="password" type={showPassword ? 'text' : 'password'} value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full h-11 px-3.5 pr-10 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                    style={{ background: 'var(--bg-secondary, var(--surface))', borderColor: 'var(--border)' }}
                    onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px var(--accent-glow, rgba(16,185,129,0.1))'; }}
                    onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                    placeholder="Enter your password" required />
                  <button type="button" onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-main transition-colors">
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-end">
                <button type="button" className="text-[13px] font-medium text-accent hover:underline">
                  Forgot password?
                </button>
              </div>

              <button type="submit" disabled={isLoading}
                className="w-full h-11 rounded-lg text-white text-sm font-medium flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
                style={{ background: 'var(--accent)' }}>
                {isLoading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    Continue
                    <ArrowRight size={16} />
                  </>
                )}
              </button>
            </form>

            <p className="text-center text-[13px] text-muted pt-2">
              Need an account?{' '}
              <span className="text-accent font-medium">Contact sales</span>
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
