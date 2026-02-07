'use client';

import { useState } from 'react';
import { useAuth } from '@/components/auth-provider';
import { useTheme } from '@/components/theme-provider';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  Settings, User, Palette, Bell, Info,
  Sun, Moon, Mail, Shield,
} from 'lucide-react';

function Toggle({ enabled, onToggle, label }: { enabled: boolean; onToggle: () => void; label: string }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className="flex items-center justify-between w-full py-3 group"
    >
      <span className="text-sm text-main group-hover:text-accent transition-colors">{label}</span>
      <div
        className={cn(
          'relative w-10 h-[22px] rounded-full transition-colors',
          enabled ? 'bg-[var(--accent)]' : 'bg-[var(--border)]'
        )}
      >
        <div
          className={cn(
            'absolute top-[3px] w-4 h-4 rounded-full bg-white shadow-sm transition-transform',
            enabled ? 'translate-x-[22px]' : 'translate-x-[3px]'
          )}
        />
      </div>
    </button>
  );
}

export default function SettingsPage() {
  const { profile } = useAuth();
  const { theme, toggleTheme } = useTheme();

  const [pushNotifications, setPushNotifications] = useState(true);
  const [emailAlerts, setEmailAlerts] = useState(true);
  const [scheduleReminders, setScheduleReminders] = useState(true);

  const roleVariant = (role: string | null | undefined): 'success' | 'info' | 'warning' | 'default' => {
    switch (role) {
      case 'owner': return 'success';
      case 'admin': return 'info';
      case 'tech': return 'warning';
      default: return 'default';
    }
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Page header */}
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-accent-light">
          <Settings size={20} className="text-accent" />
        </div>
        <div>
          <h1 className="text-xl font-semibold text-main">Settings</h1>
          <p className="text-sm text-muted">Manage your profile and preferences</p>
        </div>
      </div>

      {/* Profile section */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <User size={16} className="text-accent" />
            <CardTitle>Profile</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-accent-light flex items-center justify-center">
              <span className="text-lg font-semibold text-accent">
                {profile?.displayName
                  ? profile.displayName.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
                  : '?'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[15px] font-semibold text-main truncate">
                {profile?.displayName || 'Team Member'}
              </p>
              <p className="text-sm text-muted truncate">
                {profile?.email || 'No email on file'}
              </p>
            </div>
          </div>

          <div className="border-t border-main pt-4 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">Display Name</span>
              <span className="text-sm font-medium text-main">
                {profile?.displayName || '--'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">Email</span>
              <span className="text-sm font-medium text-main">
                {profile?.email || '--'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">Role</span>
              <Badge variant={roleVariant(profile?.role)}>
                <Shield size={12} />
                {profile?.role ? profile.role.charAt(0).toUpperCase() + profile.role.slice(1) : 'Unknown'}
              </Badge>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">Trade</span>
              <span className="text-sm font-medium text-main">
                {profile?.trade
                  ? profile.trade.charAt(0).toUpperCase() + profile.trade.slice(1)
                  : 'Not assigned'}
              </span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Appearance section */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Palette size={16} className="text-accent" />
            <CardTitle>Appearance</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <button
            type="button"
            onClick={toggleTheme}
            className="flex items-center justify-between w-full py-1 group"
          >
            <div className="flex items-center gap-3">
              {theme === 'dark' ? (
                <Moon size={18} className="text-muted group-hover:text-accent transition-colors" />
              ) : (
                <Sun size={18} className="text-muted group-hover:text-accent transition-colors" />
              )}
              <div>
                <p className="text-sm font-medium text-main">Dark Mode</p>
                <p className="text-xs text-muted">
                  {theme === 'dark' ? 'Currently using dark theme' : 'Currently using light theme'}
                </p>
              </div>
            </div>
            <div
              className={cn(
                'relative w-10 h-[22px] rounded-full transition-colors',
                theme === 'dark' ? 'bg-[var(--accent)]' : 'bg-[var(--border)]'
              )}
            >
              <div
                className={cn(
                  'absolute top-[3px] w-4 h-4 rounded-full bg-white shadow-sm transition-transform',
                  theme === 'dark' ? 'translate-x-[22px]' : 'translate-x-[3px]'
                )}
              />
            </div>
          </button>
        </CardContent>
      </Card>

      {/* Notifications section */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Bell size={16} className="text-accent" />
            <CardTitle>Notifications</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <div className="divide-y divide-[var(--border-light)]">
            <Toggle
              enabled={pushNotifications}
              onToggle={() => setPushNotifications(prev => !prev)}
              label="Push Notifications"
            />
            <Toggle
              enabled={emailAlerts}
              onToggle={() => setEmailAlerts(prev => !prev)}
              label="Email Alerts"
            />
            <Toggle
              enabled={scheduleReminders}
              onToggle={() => setScheduleReminders(prev => !prev)}
              label="Schedule Reminders"
            />
          </div>
          <p className="text-xs text-muted mt-3">
            Notification preferences will sync once backend wiring is complete.
          </p>
        </CardContent>
      </Card>

      {/* About section */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Info size={16} className="text-accent" />
            <CardTitle>About</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted">App Version</span>
            <span className="text-sm font-mono font-medium text-main">1.0.0-beta</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted">Portal</span>
            <span className="text-sm font-medium text-main">Employee Field Portal</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted">Support</span>
            <a
              href="mailto:support@zafto.app"
              className="text-sm font-medium text-accent hover:underline flex items-center gap-1.5"
            >
              <Mail size={14} />
              support@zafto.app
            </a>
          </div>
          <div className="border-t border-main pt-3 mt-3">
            <p className="text-xs text-muted text-center">
              ZAFTO Employee Field Portal &middot; Tereda Software LLC
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
