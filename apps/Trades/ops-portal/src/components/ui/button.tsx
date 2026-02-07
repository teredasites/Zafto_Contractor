import { cn } from '@/lib/utils';
import { Loader2 } from 'lucide-react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  loading?: boolean;
  children: React.ReactNode;
}

const variantStyles: Record<string, string> = {
  primary:
    'bg-[var(--accent)] text-white hover:bg-[var(--accent-hover)] focus:ring-[var(--accent)]',
  secondary:
    'bg-[var(--bg-elevated)] text-[var(--text-primary)] border border-[var(--border)] hover:bg-[var(--border)]',
  ghost:
    'bg-transparent text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] hover:text-[var(--text-primary)]',
  danger:
    'bg-[var(--danger)] text-white hover:bg-[var(--danger-hover)] focus:ring-[var(--danger)]',
};

export function Button({
  variant = 'primary',
  loading = false,
  children,
  className,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-[var(--bg-page)] disabled:opacity-50 disabled:cursor-not-allowed',
        variantStyles[variant],
        className
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Loader2 className="h-4 w-4 animate-spin" />}
      {children}
    </button>
  );
}
