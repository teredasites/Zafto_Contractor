import { cn } from '@/lib/utils';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizeStyles = {
  sm: 'text-lg',
  md: 'text-xl',
  lg: 'text-3xl',
};

export function Logo({ size = 'md', className }: LogoProps) {
  return (
    <div className={cn('select-none', className)}>
      <span
        className={cn(
          'font-bold tracking-tight text-[var(--text-primary)]',
          sizeStyles[size]
        )}
      >
        ZAFTO
      </span>
      <span
        className={cn(
          'font-medium text-[var(--accent)]',
          sizeStyles[size]
        )}
      >
        .ops
      </span>
    </div>
  );
}
