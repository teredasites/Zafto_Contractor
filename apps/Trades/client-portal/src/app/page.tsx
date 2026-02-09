'use client';

import { useState } from 'react';
import { ArrowRight, Mail, CheckCircle2, Lock, Eye, EyeOff, Sun, Moon, Shield } from 'lucide-react';
import { signInWithMagicLink, signInWithPassword } from '@/lib/auth';
import { useTheme } from '@/components/theme-provider';

export default function LoginPage() {
  const { theme, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [usePassword, setUsePassword] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setLoading(true);
    setError(null);

    if (usePassword) {
      const { error: authError } = await signInWithPassword(email, password);
      setLoading(false);
      if (authError) {
        setError(authError);
      }
    } else {
      const { error: authError } = await signInWithMagicLink(email);
      setLoading(false);
      if (authError) {
        setError(authError);
      } else {
        setSent(true);
      }
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden p-6"
      style={{ background: 'var(--bg-secondary, var(--bg))' }}>

      {/* Soft gradient */}
      <div className="absolute top-[-300px] left-1/2 -translate-x-1/2 w-[800px] h-[600px] rounded-full opacity-[0.07] blur-[120px] pointer-events-none"
        style={{ background: 'var(--accent, #635bff)' }} />

      {/* Theme toggle */}
      <button onClick={toggleTheme}
        className="absolute top-5 right-5 z-10 p-2 rounded-lg transition-colors text-muted hover:text-main">
        {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
      </button>

      <div className="relative z-10 w-full max-w-[400px]">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2.5 mb-5">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="36" height="36" style={{ color: 'var(--text)' }}>
              <g transform="translate(50,50)">
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s"/></path>
                <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s"/></path>
              </g>
            </svg>
            <span className="text-lg font-semibold tracking-tight" style={{ color: 'var(--text)' }}>Zafto</span>
          </div>
          <h1 className="text-[22px] font-semibold tracking-tight" style={{ color: 'var(--text)' }}>Client Portal</h1>
          <p className="text-sm mt-1" style={{ color: 'var(--text-muted)' }}>View your projects, invoices & property</p>
        </div>

        {/* Card */}
        <div className="rounded-xl p-6 border" style={{ background: 'var(--surface)', borderColor: 'var(--border-light, var(--border))' }}>
          {sent ? (
            <div className="text-center space-y-4 py-4">
              <div className="w-14 h-14 rounded-full mx-auto flex items-center justify-center"
                style={{ background: 'rgba(34,197,94,0.1)' }}>
                <CheckCircle2 size={28} className="text-green-500" />
              </div>
              <div>
                <h2 className="text-base font-semibold" style={{ color: 'var(--text)' }}>Check your email</h2>
                <p className="text-sm mt-2 leading-relaxed" style={{ color: 'var(--text-muted)' }}>
                  We sent a sign-in link to <strong style={{ color: 'var(--text)' }}>{email}</strong>
                </p>
              </div>
              <button onClick={() => { setSent(false); setEmail(''); }}
                className="text-sm font-medium" style={{ color: 'var(--accent)' }}>
                Use a different email
              </button>
            </div>
          ) : (
            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-1.5">
                <label className="block text-[13px] font-medium" style={{ color: 'var(--text-secondary, var(--text))' }}>Email</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)}
                  className="w-full h-11 px-3.5 rounded-lg text-sm transition-all outline-none border"
                  style={{ background: 'var(--bg)', borderColor: 'var(--border)', color: 'var(--text)' }}
                  onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(99,91,255,0.1)'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                  placeholder="you@email.com" required />
              </div>

              {usePassword && (
                <div className="space-y-1.5">
                  <label className="block text-[13px] font-medium" style={{ color: 'var(--text-secondary, var(--text))' }}>Password</label>
                  <div className="relative">
                    <input type={showPassword ? 'text' : 'password'} value={password}
                      onChange={e => setPassword(e.target.value)}
                      className="w-full h-11 px-3.5 pr-10 rounded-lg text-sm transition-all outline-none border"
                      style={{ background: 'var(--bg)', borderColor: 'var(--border)', color: 'var(--text)' }}
                      onFocus={(e) => { e.target.style.borderColor = 'var(--accent)'; e.target.style.boxShadow = '0 0 0 3px rgba(99,91,255,0.1)'; }}
                      onBlur={(e) => { e.target.style.borderColor = 'var(--border)'; e.target.style.boxShadow = 'none'; }}
                      placeholder="Enter password" required />
                    <button type="button" onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 transition-colors"
                      style={{ color: 'var(--text-muted)' }}>
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
              )}

              {error && (
                <div className="px-3.5 py-3 rounded-lg text-sm"
                  style={{ background: 'rgba(239,68,68,0.08)', color: '#ef4444' }}>
                  {error}
                </div>
              )}

              <button type="submit" disabled={loading || !email || (usePassword && !password)}
                className="w-full h-11 rounded-lg text-white text-sm font-medium flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
                style={{ background: 'var(--accent)' }}>
                {loading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : usePassword ? (
                  <>
                    <Lock size={16} />
                    Sign In
                    <ArrowRight size={16} />
                  </>
                ) : (
                  <>
                    <Mail size={16} />
                    Send Sign-In Link
                    <ArrowRight size={16} />
                  </>
                )}
              </button>

              <div className="text-center pt-1">
                {usePassword ? (
                  <button type="button" onClick={() => setUsePassword(false)}
                    className="text-[13px] font-medium" style={{ color: 'var(--accent)' }}>
                    Use magic link instead
                  </button>
                ) : (
                  <button type="button" onClick={() => setUsePassword(true)}
                    className="text-[13px] font-medium" style={{ color: 'var(--accent)' }}>
                    Sign in with password
                  </button>
                )}
              </div>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="text-center mt-6 space-y-2">
          <p className="text-[12px] flex items-center justify-center gap-1.5" style={{ color: 'var(--text-muted)' }}>
            <Shield size={12} /> Secured by ZAFTO
          </p>
          <p className="text-[12px]" style={{ color: 'var(--text-muted)', opacity: 0.6 }}>
            Your contractor will send you an invite to get started
          </p>
        </div>
      </div>
    </div>
  );
}
