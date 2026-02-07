'use client';
import { useState } from 'react';
import { Shield, ArrowRight, Mail, CheckCircle2 } from 'lucide-react';
import { signInWithMagicLink } from '@/lib/auth';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setLoading(true);
    setError(null);

    const { error: authError } = await signInWithMagicLink(email);
    setLoading(false);

    if (authError) {
      setError(authError);
    } else {
      setSent(true);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4" style={{ backgroundColor: 'var(--bg-secondary)' }}>
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="48" height="48" className="mx-auto mb-4" style={{ color: 'var(--text)' }}>
            <defs><filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="0.4" result="blur" /><feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge></filter></defs>
            <g transform="translate(50, 50)" filter="url(#glow)">
              <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.08" transform="translate(6,6)"><animate attributeName="opacity" values="0.08;0.15;0.08" dur="2s" repeatCount="indefinite" /></path>
              <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity="0.18" transform="translate(3,3)"><animate attributeName="opacity" values="0.18;0.3;0.18" dur="2s" repeatCount="indefinite" begin="0.3s" /></path>
              <path d="M-22,-22 L22,-22 L-22,22 L22,22" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><animate attributeName="stroke-width" values="3.5;4;3.5" dur="2s" repeatCount="indefinite" begin="0.6s" /></path>
            </g>
          </svg>
          <h1 className="text-xl font-semibold" style={{ color: 'var(--text)' }}>Client Portal</h1>
          <p className="text-sm mt-1" style={{ color: 'var(--text-muted)' }}>View your projects, invoices & property</p>
        </div>

        {/* Form Card */}
        <div className="rounded-xl p-6 border" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          {sent ? (
            <div className="text-center space-y-3 py-4">
              <div className="w-12 h-12 rounded-full mx-auto flex items-center justify-center" style={{ backgroundColor: 'var(--success-light)' }}>
                <CheckCircle2 size={24} style={{ color: 'var(--success)' }} />
              </div>
              <h2 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>Check your email</h2>
              <p className="text-xs leading-relaxed" style={{ color: 'var(--text-muted)' }}>
                We sent a sign-in link to <strong style={{ color: 'var(--text)' }}>{email}</strong>. Click the link in your email to access your portal.
              </p>
              <button onClick={() => { setSent(false); setEmail(''); }} className="text-xs font-medium mt-2" style={{ color: 'var(--accent)' }}>
                Use a different email
              </button>
            </div>
          ) : (
            <form onSubmit={handleLogin} className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1.5" style={{ color: 'var(--text-secondary)' }}>Email</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@email.com" required
                  className="w-full px-3.5 py-2.5 rounded-lg text-sm outline-none transition-colors border"
                  style={{ backgroundColor: 'var(--bg)', borderColor: 'var(--border)', color: 'var(--text)' }}
                />
              </div>

              {error && (
                <p className="text-xs px-3 py-2 rounded-lg" style={{ backgroundColor: 'var(--error-light)', color: 'var(--error)' }}>
                  {error}
                </p>
              )}

              <button type="submit" disabled={loading || !email}
                className="w-full py-2.5 rounded-lg text-white text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                style={{ backgroundColor: 'var(--accent)' }}>
                {loading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <Mail size={16} />
                    Send Sign-In Link
                    <ArrowRight size={16} />
                  </>
                )}
              </button>

              <p className="text-xs text-center" style={{ color: 'var(--text-muted)' }}>
                No password needed. We&apos;ll send a secure link to your email.
              </p>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="text-center mt-6 space-y-2">
          <p className="text-xs flex items-center justify-center gap-1.5" style={{ color: 'var(--text-muted)' }}>
            <Shield size={12} /> Secured by ZAFTO
          </p>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>
            Don&apos;t have an account? Your contractor will send you an invite.
          </p>
        </div>
      </div>
    </div>
  );
}
