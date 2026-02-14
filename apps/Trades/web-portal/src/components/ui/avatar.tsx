'use client';

import Image from 'next/image';
import { cn, getInitials } from '@/lib/utils';

const pixelSizes = { sm: 24, md: 32, lg: 40, xl: 48 } as const;

interface AvatarProps {
  src?: string;
  name: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  showStatus?: boolean;
  isOnline?: boolean;
}

export function Avatar({ src, name, size = 'md', className, showStatus, isOnline }: AvatarProps) {
  const sizes = {
    sm: 'w-6 h-6 text-xs',
    md: 'w-8 h-8 text-sm',
    lg: 'w-10 h-10 text-base',
    xl: 'w-12 h-12 text-lg',
  };

  const statusSizes = {
    sm: 'w-2 h-2 right-0 bottom-0',
    md: 'w-2.5 h-2.5 right-0 bottom-0',
    lg: 'w-3 h-3 right-0 bottom-0',
    xl: 'w-3.5 h-3.5 right-0.5 bottom-0.5',
  };

  const px = pixelSizes[size];

  return (
    <div className={cn('relative inline-flex', className)}>
      {src ? (
        <Image
          src={src}
          alt={name}
          width={px}
          height={px}
          className={cn(
            'rounded-full object-cover',
            sizes[size]
          )}
          unoptimized
        />
      ) : (
        <div
          className={cn(
            'rounded-full bg-accent-light flex items-center justify-center font-medium text-accent',
            sizes[size]
          )}
        >
          {getInitials(name)}
        </div>
      )}
      {showStatus && (
        <span
          className={cn(
            'absolute rounded-full border-2 border-[var(--bg-surface)]',
            statusSizes[size],
            isOnline ? 'bg-emerald-500' : 'bg-slate-400'
          )}
        />
      )}
    </div>
  );
}

interface AvatarGroupProps {
  avatars: { name: string; src?: string }[];
  max?: number;
  size?: 'sm' | 'md' | 'lg';
}

export function AvatarGroup({ avatars, max = 4, size = 'md' }: AvatarGroupProps) {
  const visible = avatars.slice(0, max);
  const remaining = avatars.length - max;

  const sizes = {
    sm: 'w-6 h-6 text-xs -ml-2',
    md: 'w-8 h-8 text-sm -ml-2.5',
    lg: 'w-10 h-10 text-base -ml-3',
  };

  return (
    <div className="flex items-center">
      {visible.map((avatar, index) => (
        <div
          key={index}
          className={cn(
            'rounded-full border-2 border-[var(--bg-surface)]',
            index === 0 ? '' : sizes[size]
          )}
        >
          <Avatar name={avatar.name} src={avatar.src} size={size} />
        </div>
      ))}
      {remaining > 0 && (
        <div
          className={cn(
            'rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center font-medium text-slate-600 dark:text-slate-300 border-2 border-[var(--bg-surface)]',
            sizes[size]
          )}
        >
          +{remaining}
        </div>
      )}
    </div>
  );
}
