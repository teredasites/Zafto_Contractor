'use client';
import { useState, useEffect } from 'react';
import { Sun, Moon } from 'lucide-react';

export function ThemeToggle() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const stored = localStorage.getItem('zafto-client-theme') as 'light' | 'dark';
    if (stored) {
      setTheme(stored);
      if (stored === 'dark') document.documentElement.classList.add('dark');
    }
  }, []);

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
    localStorage.setItem('zafto-client-theme', newTheme);
    if (newTheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  if (!mounted) return <button className="p-2 text-muted hover:text-main rounded-lg transition-colors"><Sun size={18} /></button>;

  return (
    <button onClick={toggleTheme} className="p-2 text-muted hover:text-main hover:bg-surface-hover rounded-lg transition-colors" title={theme === 'light' ? 'Dark mode' : 'Light mode'}>
      {theme === 'light' ? <Moon size={18} /> : <Sun size={18} />}
    </button>
  );
}
