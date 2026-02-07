'use client';

import { cn, getStatusColor } from '@/lib/utils';

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info';
  className?: string;
}

export function Badge({ children, variant = 'default', className }: BadgeProps) {
  const variants = {
    default: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
    success: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
    warning: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
    error: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
    info: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  };
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', variants[variant], className)}>
      {children}
    </span>
  );
}

export function StatusBadge({ status, label, className }: { status: string; label?: string; className?: string }) {
  const colors = getStatusColor(status);
  const labels: Record<string, string> = {
    draft: 'Draft', scheduled: 'Scheduled', dispatched: 'Dispatched',
    en_route: 'En Route', in_progress: 'In Progress', on_hold: 'On Hold',
    completed: 'Completed', open: 'Open', pending: 'Pending',
    approved: 'Approved', rejected: 'Rejected', pending_approval: 'Pending Approval',
    new: 'New', assigned: 'Assigned', cancelled: 'Cancelled',
  };
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', colors.bg, colors.text, className)}>
      <span className={cn('w-1.5 h-1.5 rounded-full', colors.dot)} />
      {label || labels[status] || status}
    </span>
  );
}
