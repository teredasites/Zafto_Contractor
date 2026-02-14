'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  Clock,
  MapPin,
  Play,
  Pause,
  Coffee,
  ChevronRight,
  Users,
  Timer,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import type { TeamMember } from '@/types';

// Time entry type for clocked-in users
interface TimeEntry {
  id: string;
  userId: string;
  clockIn: Date;
  clockOut?: Date;
  status: 'active' | 'on_break' | 'completed';
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  jobId?: string;
  jobTitle?: string;
}

function useActiveTimeEntries() {
  const [entries, setEntries] = useState<TimeEntry[]>([]);

  const fetchEntries = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('time_entries')
        .select('id, user_id, clock_in, status, location_pings, job_id, jobs(name)')
        .in('status', ['active', 'on_break'])
        .order('clock_in', { ascending: false });

      if (data) {
        setEntries(
          data.map((row: Record<string, unknown>) => {
            const pings = row.location_pings as { lat: number; lng: number; address?: string }[] | null;
            const latest = pings && pings.length > 0 ? pings[pings.length - 1] : null;
            const jobObj = row.jobs as { name: string } | null;
            return {
              id: row.id as string,
              userId: row.user_id as string,
              clockIn: new Date(row.clock_in as string),
              status: (row.status as string) === 'on_break' ? 'on_break' as const : 'active' as const,
              location: latest ? { latitude: latest.lat, longitude: latest.lng, address: latest.address } : undefined,
              jobId: (row.job_id as string) || undefined,
              jobTitle: jobObj?.name || undefined,
            };
          })
        );
      }
    } catch {
      // Fail silently — widget is non-critical
    }
  }, []);

  useEffect(() => {
    fetchEntries();

    // Real-time subscription
    const supabase = getSupabase();
    const channel = supabase
      .channel('clock-status-widget')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'time_entries' }, () => {
        fetchEntries();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchEntries]);

  return entries;
}

interface ClockStatusWidgetProps {
  teamMembers: TeamMember[];
  className?: string;
  variant?: 'compact' | 'full';
}

export function ClockStatusWidget({
  teamMembers,
  className,
  variant = 'compact',
}: ClockStatusWidgetProps) {
  const router = useRouter();
  const timeEntries = useActiveTimeEntries();

  // Get clocked-in users with their team member info
  const clockedInUsers = timeEntries
    .filter((entry) => entry.status !== 'completed')
    .map((entry) => {
      const member = teamMembers.find((m) => m.id === entry.userId);
      return { entry, member };
    })
    .filter((item) => item.member);

  const activeCount = timeEntries.filter((e) => e.status === 'active').length;
  const onBreakCount = timeEntries.filter((e) => e.status === 'on_break').length;

  // Calculate total hours today
  const totalHoursToday = timeEntries.reduce((sum, entry) => {
    const elapsed = (Date.now() - entry.clockIn.getTime()) / (1000 * 60 * 60);
    return sum + Math.min(elapsed, 12); // Cap at 12 hours per person for display
  }, 0);

  const formatElapsedTime = (clockIn: Date) => {
    const elapsed = Date.now() - clockIn.getTime();
    const hours = Math.floor(elapsed / (1000 * 60 * 60));
    const minutes = Math.floor((elapsed % (1000 * 60 * 60)) / (1000 * 60));
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  };

  if (variant === 'compact') {
    return (
      <Card className={cn('hover:border-accent/50 transition-colors', className)}>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 rounded-lg bg-green-500/10">
                <Clock size={18} className="text-green-500" />
              </div>
              <CardTitle className="text-base">Who's On The Clock</CardTitle>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => router.push('/dashboard/time-clock')}
              className="text-muted hover:text-main"
            >
              View All
              <ChevronRight size={16} />
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Stats row */}
          <div className="flex items-center gap-6 mb-4">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="text-2xl font-bold text-main">{activeCount}</span>
              <span className="text-sm text-muted">Working</span>
            </div>
            {onBreakCount > 0 && (
              <div className="flex items-center gap-2">
                <Coffee size={14} className="text-amber-500" />
                <span className="text-lg font-semibold text-main">{onBreakCount}</span>
                <span className="text-sm text-muted">On break</span>
              </div>
            )}
            <div className="flex items-center gap-2 ml-auto">
              <Timer size={14} className="text-muted" />
              <span className="text-sm text-muted">{totalHoursToday.toFixed(1)}h today</span>
            </div>
          </div>

          {/* Clocked-in users list */}
          <div className="space-y-2">
            {clockedInUsers.slice(0, 3).map(({ entry, member }) => (
              <div
                key={entry.id}
                className="flex items-center gap-3 p-2 rounded-lg hover:bg-surface-hover transition-colors cursor-pointer"
                onClick={() => router.push('/dashboard/time-clock')}
              >
                <div className="relative">
                  <Avatar name={member!.name} size="sm" />
                  <div
                    className={cn(
                      'absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-surface',
                      entry.status === 'active' ? 'bg-green-500' : 'bg-amber-500'
                    )}
                  />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium text-main truncate">{member!.name}</p>
                    {entry.status === 'on_break' && (
                      <span className="px-1.5 py-0.5 text-[10px] font-medium bg-amber-500/10 text-amber-500 rounded">
                        BREAK
                      </span>
                    )}
                  </div>
                  {entry.jobTitle ? (
                    <p className="text-xs text-muted truncate">{entry.jobTitle}</p>
                  ) : entry.location?.address ? (
                    <p className="text-xs text-muted truncate flex items-center gap-1">
                      <MapPin size={10} />
                      {entry.location.address}
                    </p>
                  ) : null}
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-green-500">
                    {formatElapsedTime(entry.clockIn)}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {clockedInUsers.length > 3 && (
            <button
              onClick={() => router.push('/dashboard/time-clock')}
              className="w-full mt-2 py-2 text-sm text-muted hover:text-main text-center transition-colors"
            >
              +{clockedInUsers.length - 3} more on the clock
            </button>
          )}

          {clockedInUsers.length === 0 && (
            <div className="text-center py-6">
              <Users size={32} className="mx-auto mb-2 text-muted/50" />
              <p className="text-sm text-muted">No one clocked in</p>
            </div>
          )}
        </CardContent>
      </Card>
    );
  }

  // Full variant - more detailed view
  return (
    <Card className={cn('', className)}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-green-500/10">
              <Clock size={22} className="text-green-500" />
            </div>
            <div>
              <CardTitle>Time Clock</CardTitle>
              <p className="text-sm text-muted mt-0.5">Real-time team status</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-green-500/10">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="text-sm font-semibold text-green-500">{activeCount} Active</span>
            </div>
            {onBreakCount > 0 && (
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-amber-500/10">
                <Coffee size={14} className="text-amber-500" />
                <span className="text-sm font-semibold text-amber-500">{onBreakCount} Break</span>
              </div>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {clockedInUsers.map(({ entry, member }) => (
            <div
              key={entry.id}
              className="flex items-center gap-4 p-3 rounded-xl bg-secondary hover:bg-surface-hover transition-colors cursor-pointer"
              onClick={() => router.push('/dashboard/time-clock')}
            >
              <div className="relative">
                <Avatar name={member!.name} size="md" />
                <div
                  className={cn(
                    'absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-surface flex items-center justify-center',
                    entry.status === 'active' ? 'bg-green-500' : 'bg-amber-500'
                  )}
                >
                  {entry.status === 'active' ? (
                    <Play size={8} className="text-white" />
                  ) : (
                    <Pause size={8} className="text-white" />
                  )}
                </div>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-0.5">
                  <p className="font-medium text-main">{member!.name}</p>
                  <span className="text-xs text-muted">{member!.role.replace('_', ' ')}</span>
                </div>
                {entry.jobTitle && (
                  <p className="text-sm text-main truncate">{entry.jobTitle}</p>
                )}
                {entry.location?.address && (
                  <p className="text-xs text-muted flex items-center gap-1 mt-0.5">
                    <MapPin size={12} />
                    {entry.location.address}
                  </p>
                )}
              </div>
              <div className="text-right">
                <p className="text-xl font-bold text-green-500">
                  {formatElapsedTime(entry.clockIn)}
                </p>
                <p className="text-xs text-muted">
                  Since {entry.clockIn.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </p>
              </div>
            </div>
          ))}
        </div>

        {clockedInUsers.length === 0 && (
          <div className="text-center py-6">
            <Users size={32} className="mx-auto mb-2 text-muted/50" />
            <p className="text-sm text-muted">No one clocked in</p>
          </div>
        )}

        {/* Summary footer */}
        <div className="mt-4 pt-4 border-t border-main flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div>
              <p className="text-xs text-muted uppercase tracking-wide">Total Today</p>
              <p className="text-lg font-semibold text-main">{totalHoursToday.toFixed(1)} hours</p>
            </div>
          </div>
          <Button onClick={() => router.push('/dashboard/time-clock')}>
            View Timesheets
            <ChevronRight size={16} />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

// Export a simpler stat indicator for use in headers/nav
export function ClockStatusIndicator({ teamMembers }: { teamMembers: TeamMember[] }) {
  const timeEntries = useActiveTimeEntries();
  const activeCount = timeEntries.filter((e) => e.status === 'active').length;

  if (activeCount === 0) return null;

  return (
    <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-green-500/10">
      <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
      <span className="text-xs font-semibold text-green-500">{activeCount} on clock</span>
    </div>
  );
}
