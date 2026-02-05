'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LogIn, Briefcase, FileText, Calendar, Users, AlertCircle } from 'lucide-react';
import { signIn } from '@/lib/auth';
import { onAuthChange } from '@/lib/auth';

export default function Home() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [checkingAuth, setCheckingAuth] = useState(true);

  // Check if already logged in
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
      <div className="min-h-screen flex items-center justify-center bg-main">
        <div className="w-8 h-8 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <main className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-secondary flex-col justify-between p-12">
        <div>
          {/* Logo */}
          <span className="text-3xl font-bold text-main tracking-tight">Zafto</span>
        </div>

        {/* Features */}
        <div className="space-y-8">
          <h1 className="text-4xl font-bold leading-tight text-main">
            Your business,<br />from anywhere.
          </h1>
          <p className="text-secondary text-lg">
            Manage bids, jobs, invoices, and your team - all in one place.
          </p>

          <div className="grid grid-cols-2 gap-4">
            <FeatureCard icon={<Briefcase size={20} />} title="Bids" desc="Create & track" />
            <FeatureCard icon={<FileText size={20} />} title="Invoices" desc="Get paid faster" />
            <FeatureCard icon={<Calendar size={20} />} title="Schedule" desc="Plan your week" />
            <FeatureCard icon={<Users size={20} />} title="Team" desc="Dispatch & manage" />
          </div>
        </div>

        <p className="text-muted text-sm">
          Built for trades professionals
        </p>
      </div>

      {/* Right side - Login */}
      <div className="flex-1 flex items-center justify-center p-8 bg-main">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="lg:hidden mb-8 text-center">
            <span className="text-3xl font-bold text-main tracking-tight">Zafto</span>
          </div>

          <div className="bg-surface border border-main rounded-xl p-8 shadow-sm">
            <h2 className="text-2xl font-semibold mb-2 text-main">Welcome back</h2>
            <p className="text-muted mb-8">Sign in to your account</p>

            {error && (
              <div className="mb-4 p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 rounded-lg flex items-center gap-2 text-red-600 dark:text-red-400 text-sm">
                <AlertCircle size={16} />
                {error}
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-4">
              <div>
                <label htmlFor="email" className="block text-sm font-medium mb-2 text-main">
                  Email
                </label>
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3 bg-main border border-main rounded-lg focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors text-main placeholder:text-muted"
                  placeholder="you@company.com"
                  required
                />
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium mb-2 text-main">
                  Password
                </label>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-4 py-3 bg-main border border-main rounded-lg focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors text-main placeholder:text-muted"
                  placeholder="Enter your password"
                  required
                />
              </div>

              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" className="rounded border-main bg-main accent-[var(--accent)]" />
                  <span className="text-muted">Remember me</span>
                </label>
                <a href="#" className="text-accent hover:underline">
                  Forgot password?
                </a>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3 bg-accent hover:bg-accent-hover text-white font-medium rounded-lg transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {isLoading ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <LogIn size={18} />
                    Sign in
                  </>
                )}
              </button>
            </form>

            <div className="mt-6 pt-6 border-t border-main">
              <p className="text-center text-sm text-muted">
                Don't have an account?{' '}
                <a href="#" className="text-accent hover:underline font-medium">
                  Download the app
                </a>
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

function FeatureCard({ icon, title, desc }: { icon: React.ReactNode; title: string; desc: string }) {
  return (
    <div className="p-4 bg-surface border border-main rounded-lg">
      <div className="text-accent mb-2">{icon}</div>
      <h3 className="font-medium text-main">{title}</h3>
      <p className="text-sm text-muted">{desc}</p>
    </div>
  );
}
