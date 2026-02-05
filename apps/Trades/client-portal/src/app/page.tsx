'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, Shield, ArrowRight } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => router.push('/home'), 800);
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
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: 'var(--text-secondary)' }}>Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@email.com"
                className="w-full px-3.5 py-2.5 rounded-lg text-sm outline-none transition-colors border"
                style={{ backgroundColor: 'var(--bg)', borderColor: 'var(--border)', color: 'var(--text)' }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: 'var(--text-secondary)' }}>Password</label>
              <div className="relative">
                <input type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="Enter your password"
                  className="w-full px-3.5 py-2.5 rounded-lg text-sm outline-none transition-colors border pr-10"
                  style={{ backgroundColor: 'var(--bg)', borderColor: 'var(--border)', color: 'var(--text)' }}
                />
                <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2" style={{ color: 'var(--text-muted)' }}>
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="rounded" style={{ accentColor: 'var(--accent)' }} />
                <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Remember me</span>
              </label>
              <button type="button" className="text-sm font-medium" style={{ color: 'var(--accent)' }}>Forgot password?</button>
            </div>

            <button type="submit" disabled={loading}
              className="w-full py-2.5 rounded-lg text-white text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
              style={{ backgroundColor: 'var(--accent)' }}>
              {loading ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <>Sign In <ArrowRight size={16} /></>}
            </button>
          </form>
        </div>

        {/* Footer */}
        <div className="text-center mt-6 space-y-2">
          <p className="text-xs flex items-center justify-center gap-1.5" style={{ color: 'var(--text-muted)' }}>
            <Shield size={12} /> Secured by ZAFTO · Your contractor sent you this portal
          </p>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>
            Don&apos;t have an account? Your contractor will send you an invite.
          </p>
        </div>
      </div>
    </div>
  );
}
