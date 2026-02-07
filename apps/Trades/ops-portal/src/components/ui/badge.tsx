import { cn } from '@/lib/utils';

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
  className?: string;
}

const variantStyles: Record<string, string> = {
  default:
    'bg-[var(--bg-elevated)] text-[var(--text-secondary)] border-[var(--border)]',
  success:
    'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/30 dark:text-emerald-400 dark:border-emerald-800',
  warning:
    'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/30 dark:text-amber-400 dark:border-amber-800',
  danger:
    'bg-red-50 text-red-700 border-red-200 dark:bg-red-950/30 dark:text-red-400 dark:border-red-800',
  info: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-950/30 dark:text-blue-400 dark:border-blue-800',
};

export function Badge({
  children,
  variant = 'default',
  className,
}: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium',
        variantStyles[variant],
        className
      )}
    >
      {children}
    </span>
  );
}

interface StatusBadgeProps {
  status: string;
  className?: string;
}

const statusVariantMap: Record<string, BadgeProps['variant']> = {
  active: 'success',
  healthy: 'success',
  online: 'success',
  resolved: 'success',
  paid: 'success',
  pending: 'warning',
  trial: 'warning',
  degraded: 'warning',
  overdue: 'warning',
  inactive: 'danger',
  error: 'danger',
  offline: 'danger',
  cancelled: 'danger',
  churned: 'danger',
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const variant = statusVariantMap[status.toLowerCase()] || 'default';
  const label = status.charAt(0).toUpperCase() + status.slice(1).replace(/_/g, ' ');

  return (
    <Badge variant={variant} className={className}>
      {label}
    </Badge>
  );
}
