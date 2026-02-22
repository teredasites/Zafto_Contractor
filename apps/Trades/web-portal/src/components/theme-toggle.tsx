'use client';

import { Sun, Moon } from 'lucide-react';
import { useTheme } from '@/components/theme-provider';

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      className="p-2 text-muted hover:text-main hover:bg-surface-hover rounded-lg transition-colors"
      title={theme === 'light' ? 'Switch to dark mode' : 'Switch to light mode'}
    >
      {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
    </button>
  );
}
