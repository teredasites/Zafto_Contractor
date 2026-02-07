'use client';

import { cn } from '@/lib/utils';
import { forwardRef } from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, id, ...props }, ref) => {
    return (
      <div className="space-y-1.5">
        {label && <label htmlFor={id} className="text-sm font-medium text-main">{label}</label>}
        <input
          ref={ref}
          id={id}
          className={cn(
            'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
            'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]',
            error && 'border-red-500 focus:border-red-500 focus:ring-red-500',
            className
          )}
          {...props}
        />
        {error && <p className="text-xs text-red-500">{error}</p>}
      </div>
    );
  }
);
Input.displayName = 'Input';
