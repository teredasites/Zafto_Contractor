'use client';

import { cn } from '@/lib/utils';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface StatsCardProps {
  title: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
}

export function StatsCard({
  title,
  value,
  change,
  changeLabel,
  icon,
  trend,
  className,
}: StatsCardProps) {
  const getTrendIcon = () => {
    if (!trend && change === undefined) return null;
    const actualTrend = trend || (change && change > 0 ? 'up' : change && change < 0 ? 'down' : 'neutral');

    if (actualTrend === 'up') return <TrendingUp size={14} />;
    if (actualTrend === 'down') return <TrendingDown size={14} />;
    return <Minus size={14} />;
  };

  const getTrendColor = () => {
    if (!trend && change === undefined) return 'text-muted';
    const actualTrend = trend || (change && change > 0 ? 'up' : change && change < 0 ? 'down' : 'neutral');

    if (actualTrend === 'up') return 'text-emerald-600 dark:text-emerald-400';
    if (actualTrend === 'down') return 'text-red-600 dark:text-red-400';
    return 'text-muted';
  };

  return (
    <div className={cn('bg-surface border border-main rounded-xl p-5 card-hover', className)}>
      <div className="flex items-center justify-between">
        <p className="text-[13px] font-medium text-muted">{title}</p>
        {icon && (
          <div className="text-muted">
            {icon}
          </div>
        )}
      </div>
      <div className="mt-2">
        <p className="text-[26px] font-semibold text-main leading-tight">{value}</p>
        {(change !== undefined || changeLabel) && (
          <div className={cn('flex items-center gap-1 mt-1.5 text-[13px]', getTrendColor())}>
            {getTrendIcon()}
            {change !== undefined && (
              <span className="font-medium">
                {change > 0 ? '+' : ''}{change}%
              </span>
            )}
            {changeLabel && <span className="text-muted">{changeLabel}</span>}
          </div>
        )}
      </div>
    </div>
  );
}

interface MiniStatsProps {
  items: {
    label: string;
    value: string | number;
    color?: string;
  }[];
  className?: string;
}

export function MiniStats({ items, className }: MiniStatsProps) {
  return (
    <div className={cn('flex items-center gap-6', className)}>
      {items.map((item, index) => (
        <div key={index} className="flex items-center gap-2">
          {item.color && (
            <span
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: item.color }}
            />
          )}
          <span className="text-[13px] text-muted">{item.label}</span>
          <span className="text-[13px] font-semibold text-main">{item.value}</span>
        </div>
      ))}
    </div>
  );
}
