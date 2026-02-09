'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { signIn } from '@/lib/auth';
import { ArrowRight, AlertCircle, Eye, EyeOff, Sun, Moon } from 'lucide-react';
import { useTheme } from '@/components/theme-provider';

export default function LoginPage() {
  const router = useRouter();
  const { theme, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const { error: authError } = await signIn(email, password);
    if (authError) {
      setError(authError);
      setLoading(false);
    } else {
      router.push('/dashboard');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden"
      style={{ background: 'var(--bg-page, var(--bg))' }}>

      {/* Subtle grid */}
      <div className="absolute inset-0 opacity-[0.02] dark:opacity-[0.03]"
        style={{ backgroundImage: 'linear-gradient(rgba(128,128,128,.3) 1px, transparent 1px), linear-gradient(90deg, rgba(128,128,128,.3) 1px, transparent 1px)', backgroundSize: '40px 40px' }} />

      {/* Accent glow */}
      <div className="absolute top-[-200px] right-[-100px] w-[500px] h-[500px] rounded-full opacity-10 blur-[120px] pointer-events-none"
        style={{ background: 'var(--accent, #10b981)' }} />

      {/* Theme toggle */}
      <button onClick={toggleTheme}
        className="absolute top-5 right-5 z-10 p-2 rounded-lg transition-colors text-muted hover:text-main hover:bg-surface-hover">
        {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
      </button>

      <div className="relative z-10 w-full max-w-[380px] px-6">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center gap-2.5 mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="36" height="36" className="text-main">
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/></path>
              </g>
            </svg>
            <span className="text-xl font-semibold text-main tracking-tight">Zafto</span>
          </div>
          <h1 className="text-[22px] font-semibold text-main tracking-tight">Team Portal</h1>
          <p className="text-sm text-muted mt-1">Sign in to access field operations</p>
        </div>

        {/* Card */}
        <div className="rounded-xl p-6 border transition-colors"
          style={{ background: 'var(--surface, var(--bg-secondary))', borderColor: 'var(--border)' }}>

          {error && (
            <div className="mb-4 px-3.5 py-3 rounded-lg flex items-start gap-2.5 text-sm"
              style={{ background: 'rgba(239,68,68,0.08)', color: '#ef4444' }}>
              <AlertCircle size={16} className="mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-[13px] font-medium text-main">Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)}
                className="w-full h-11 px-3.5 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                style={{ background: 'var(--bg, var(--bg-page))', borderColor: 'var(--border)' }}
                onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(16,185,129,0.1)'; }}
                onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                placeholder="you@company.com" required />
            </div>

            <div className="space-y-1.5">
              <label className="block text-[13px] font-medium text-main">Password</label>
              <div className="relative">
                <input type={showPassword ? 'text' : 'password'} value={password}
                  onChange={e => setPassword(e.target.value)}
                  className="w-full h-11 px-3.5 pr-10 rounded-lg text-sm transition-all outline-none border text-main placeholder:text-muted"
                  style={{ background: 'var(--bg, var(--bg-page))', borderColor: 'var(--border)' }}
                  onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(16,185,129,0.1)'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                  placeholder="Enter your password" required />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-main transition-colors">
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading}
              className="w-full h-11 rounded-lg text-white text-sm font-medium flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
              style={{ background: 'var(--accent, #10b981)' }}>
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

        <p className="text-center text-[12px] text-muted mt-6">
          Contact your administrator if you need access
        </p>
      </div>
    </div>
  );
}
