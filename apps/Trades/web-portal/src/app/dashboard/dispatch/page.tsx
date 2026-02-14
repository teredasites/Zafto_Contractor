'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  Radio,
  MapPin,
  Clock,
  User,
  AlertCircle,
  ChevronRight,
  Phone,
  ArrowRight,
  RefreshCw,
  Filter,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar } from '@/components/ui/avatar';
import { cn, formatRelativeTime } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Types
// ============================================================

interface DispatchJob {
  id: string;
  title: string;
  status: string;
  priority: string;
  jobType: string;
  customerName: string;
  customerPhone: string | null;
  address: string;
  scheduledStart: string | null;
  assignedUserIds: string[];
  createdAt: string;
}

interface TechStatus {
  id: string;
  fullName: string;
  email: string;
  role: string;
  isClockedIn: boolean;
  currentJobId: string | null;
  currentJobTitle: string | null;
  lastLocation: { lat: number; lng: number } | null;
  clockInTime: string | null;
}

// ============================================================
// Page
// ============================================================

export default function DispatchPage() {
  const router = useRouter();
  const [unassignedJobs, setUnassignedJobs] = useState<DispatchJob[]>([]);
  const [assignedJobs, setAssignedJobs] = useState<DispatchJob[]>([]);
  const [techs, setTechs] = useState<TechStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [priorityFilter, setPriorityFilter] = useState<string>('all');
  const [dispatching, setDispatching] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();

      // Fetch today's + tomorrow's jobs
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 2);
      tomorrow.setHours(0, 0, 0, 0);

      const { data: jobsData } = await supabase
        .from('jobs')
        .select('id, title, status, priority, job_type, customer_name, customer_phone, address_line1, address_city, address_state, scheduled_start, assigned_user_ids, created_at')
        .is('deleted_at', null)
        .in('status', ['lead', 'quoted', 'scheduled', 'dispatched', 'in_progress'])
        .order('priority', { ascending: false })
        .order('scheduled_start', { ascending: true });

      const jobs: DispatchJob[] = (jobsData || []).map((j: Record<string, unknown>) => ({
        id: j.id as string,
        title: (j.title as string) || 'Untitled Job',
        status: (j.status as string) || 'lead',
        priority: (j.priority as string) || 'medium',
        jobType: (j.job_type as string) || 'standard',
        customerName: (j.customer_name as string) || 'Unknown',
        customerPhone: (j.customer_phone as string) || null,
        address: [(j.address_line1 as string), (j.address_city as string), (j.address_state as string)].filter(Boolean).join(', ') || 'No address',
        scheduledStart: (j.scheduled_start as string) || null,
        assignedUserIds: (j.assigned_user_ids as string[]) || [],
        createdAt: j.created_at as string,
      }));

      setUnassignedJobs(jobs.filter((j) => j.assignedUserIds.length === 0 && j.status !== 'in_progress'));
      setAssignedJobs(jobs.filter((j) => j.assignedUserIds.length > 0 || j.status === 'in_progress'));

      // Fetch active techs
      const { data: usersData } = await supabase
        .from('users')
        .select('id, full_name, email, role')
        .is('deleted_at', null)
        .in('role', ['technician', 'field_tech', 'apprentice', 'admin', 'owner']);

      // Fetch active time entries (clocked in)
      const { data: timeEntries } = await supabase
        .from('time_entries')
        .select('user_id, clock_in, job_id, gps_lat_in, gps_lng_in')
        .is('clock_out', null)
        .order('clock_in', { ascending: false });

      // Build tech status
      const techMap = new Map<string, TechStatus>();
      for (const u of (usersData || [])) {
        const user = u as Record<string, unknown>;
        techMap.set(user.id as string, {
          id: user.id as string,
          fullName: (user.full_name as string) || (user.email as string),
          email: (user.email as string) || '',
          role: (user.role as string) || 'technician',
          isClockedIn: false,
          currentJobId: null,
          currentJobTitle: null,
          lastLocation: null,
          clockInTime: null,
        });
      }

      for (const te of (timeEntries || [])) {
        const entry = te as Record<string, unknown>;
        const userId = entry.user_id as string;
        const tech = techMap.get(userId);
        if (tech) {
          tech.isClockedIn = true;
          tech.clockInTime = entry.clock_in as string;
          if (entry.job_id) {
            tech.currentJobId = entry.job_id as string;
            const matchingJob = jobs.find((j) => j.id === entry.job_id);
            tech.currentJobTitle = matchingJob?.title || 'Unknown Job';
          }
          if (entry.gps_lat_in && entry.gps_lng_in) {
            tech.lastLocation = {
              lat: entry.gps_lat_in as number,
              lng: entry.gps_lng_in as number,
            };
          }
        }
      }

      setTechs(Array.from(techMap.values()).sort((a, b) => {
        if (a.isClockedIn && !b.isClockedIn) return -1;
        if (!a.isClockedIn && b.isClockedIn) return 1;
        if (a.currentJobId && !b.currentJobId) return 1;
        if (!a.currentJobId && b.currentJobId) return -1;
        return a.fullName.localeCompare(b.fullName);
      }));
    } catch (err) {
      console.error('Dispatch fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    // Real-time subscription
    const supabase = getSupabase();
    const channel = supabase
      .channel('dispatch-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'time_entries' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const handleDispatch = async (jobId: string, techId: string) => {
    setDispatching(jobId);
    try {
      const supabase = getSupabase();
      await supabase
        .from('jobs')
        .update({
          assigned_user_ids: [techId],
          status: 'scheduled',
        })
        .eq('id', jobId);
      // Data refreshes via real-time subscription
    } catch (err) {
      console.error('Dispatch error:', err);
    } finally {
      setDispatching(null);
    }
  };

  const filteredUnassigned = priorityFilter === 'all'
    ? unassignedJobs
    : unassignedJobs.filter((j) => j.priority === priorityFilter);

  const availableTechs = techs.filter((t) => t.isClockedIn && !t.currentJobId);
  const onJobTechs = techs.filter((t) => t.isClockedIn && t.currentJobId);
  const offlineTechs = techs.filter((t) => !t.isClockedIn);

  const priorityColor = (p: string) => {
    switch (p) {
      case 'urgent': return 'text-red-500 bg-red-500/10';
      case 'high': return 'text-amber-500 bg-amber-500/10';
      case 'medium': return 'text-blue-500 bg-blue-500/10';
      default: return 'text-slate-400 bg-slate-500/10';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="h-8 w-48 rounded skeleton-shimmer" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-96 rounded-xl skeleton-shimmer" />
          <div className="h-96 rounded-xl skeleton-shimmer" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-accent-light">
            <Radio size={20} className="text-accent" />
          </div>
          <div>
            <h1 className="text-2xl font-semibold text-main">Dispatch Board</h1>
            <p className="text-sm text-muted">{unassignedJobs.length} unassigned &middot; {assignedJobs.length} dispatched &middot; {availableTechs.length} available</p>
          </div>
        </div>
        <Button variant="secondary" onClick={fetchData}>
          <RefreshCw size={14} className="mr-1" /> Refresh
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">Unassigned</p>
            <p className="text-2xl font-bold text-main">{unassignedJobs.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">Dispatched</p>
            <p className="text-2xl font-bold text-accent">{assignedJobs.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">Available Techs</p>
            <p className="text-2xl font-bold text-emerald-500">{availableTechs.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">On Job</p>
            <p className="text-2xl font-bold text-amber-500">{onJobTechs.length}</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: Unassigned Jobs */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-main">Unassigned Jobs</h2>
            <div className="flex gap-1">
              <Filter size={14} className="text-muted mt-1 mr-1" />
              {['all', 'urgent', 'high', 'medium', 'low'].map((p) => (
                <button
                  key={p}
                  onClick={() => setPriorityFilter(p)}
                  className={cn(
                    'px-2 py-1 rounded text-xs font-medium',
                    priorityFilter === p ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main'
                  )}
                >
                  {p === 'all' ? 'All' : p.charAt(0).toUpperCase() + p.slice(1)}
                </button>
              ))}
            </div>
          </div>

          {filteredUnassigned.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <Zap size={24} className="mx-auto text-muted mb-2" />
                <p className="text-muted">No unassigned jobs</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredUnassigned.map((job) => (
                <Card key={job.id} className="hover:border-accent/30 transition-colors">
                  <CardContent className="py-3">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className={cn('px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase', priorityColor(job.priority))}>
                            {job.priority}
                          </span>
                          <h3 className="font-medium text-main text-sm truncate">{job.title}</h3>
                        </div>
                        <div className="flex items-center gap-4 mt-1 text-xs text-muted">
                          <span className="flex items-center gap-1">
                            <User size={12} /> {job.customerName}
                          </span>
                          <span className="flex items-center gap-1">
                            <MapPin size={12} /> {job.address}
                          </span>
                          {job.scheduledStart && (
                            <span className="flex items-center gap-1">
                              <Clock size={12} /> {new Date(job.scheduledStart).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Quick dispatch dropdown */}
                      <div className="flex items-center gap-2 ml-4">
                        {availableTechs.length > 0 ? (
                          <div className="flex gap-1">
                            {availableTechs.slice(0, 3).map((tech) => (
                              <button
                                key={tech.id}
                                onClick={() => handleDispatch(job.id, tech.id)}
                                disabled={dispatching === job.id}
                                className="flex items-center gap-1 px-2 py-1 rounded bg-emerald-500/10 text-emerald-600 hover:bg-emerald-500/20 text-xs font-medium transition-colors disabled:opacity-50"
                                title={`Dispatch to ${tech.fullName}`}
                              >
                                <ArrowRight size={10} />
                                {tech.fullName.split(' ')[0]}
                              </button>
                            ))}
                          </div>
                        ) : (
                          <span className="text-xs text-muted">No techs available</span>
                        )}
                        <button
                          onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                          className="p-1.5 rounded hover:bg-surface-hover text-muted"
                        >
                          <ChevronRight size={16} />
                        </button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Currently Dispatched */}
          {assignedJobs.length > 0 && (
            <>
              <h2 className="text-lg font-semibold text-main mt-6">Dispatched Jobs</h2>
              <div className="space-y-2">
                {assignedJobs.map((job) => (
                  <Card key={job.id} className="border-accent/20">
                    <CardContent className="py-3">
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <Badge variant={job.status === 'in_progress' ? 'success' : 'info'}>
                              {job.status.replace(/_/g, ' ')}
                            </Badge>
                            <h3 className="font-medium text-main text-sm">{job.title}</h3>
                          </div>
                          <div className="flex items-center gap-4 mt-1 text-xs text-muted">
                            <span>{job.customerName}</span>
                            <span>{job.address}</span>
                          </div>
                        </div>
                        <button
                          onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                          className="p-1.5 rounded hover:bg-surface-hover text-muted"
                        >
                          <ChevronRight size={16} />
                        </button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </>
          )}
        </div>

        {/* Right: Tech Panel */}
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-main">Technicians</h2>

          {/* Available */}
          {availableTechs.length > 0 && (
            <Card>
              <CardHeader className="py-2">
                <CardTitle className="text-sm text-emerald-500 flex items-center gap-1">
                  <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                  Available ({availableTechs.length})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 pt-0">
                {availableTechs.map((tech) => (
                  <div key={tech.id} className="flex items-center gap-3 p-2 rounded-lg bg-emerald-500/5">
                    <Avatar name={tech.fullName} size="sm" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main truncate">{tech.fullName}</p>
                      <p className="text-xs text-muted">
                        Clocked in {tech.clockInTime ? formatRelativeTime(tech.clockInTime) : ''}
                      </p>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          {/* On Job */}
          {onJobTechs.length > 0 && (
            <Card>
              <CardHeader className="py-2">
                <CardTitle className="text-sm text-amber-500 flex items-center gap-1">
                  <div className="w-2 h-2 rounded-full bg-amber-500" />
                  On Job ({onJobTechs.length})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 pt-0">
                {onJobTechs.map((tech) => (
                  <div key={tech.id} className="flex items-center gap-3 p-2 rounded-lg bg-amber-500/5">
                    <Avatar name={tech.fullName} size="sm" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main truncate">{tech.fullName}</p>
                      <p className="text-xs text-muted truncate">{tech.currentJobTitle}</p>
                    </div>
                    {tech.currentJobId && (
                      <button
                        onClick={() => router.push(`/dashboard/jobs/${tech.currentJobId}`)}
                        className="text-xs text-accent hover:underline"
                      >
                        View
                      </button>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          {/* Offline */}
          {offlineTechs.length > 0 && (
            <Card>
              <CardHeader className="py-2">
                <CardTitle className="text-sm text-muted flex items-center gap-1">
                  <div className="w-2 h-2 rounded-full bg-slate-400" />
                  Offline ({offlineTechs.length})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 pt-0">
                {offlineTechs.map((tech) => (
                  <div key={tech.id} className="flex items-center gap-3 p-2 rounded-lg opacity-60">
                    <Avatar name={tech.fullName} size="sm" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main truncate">{tech.fullName}</p>
                      <p className="text-xs text-muted">{tech.role}</p>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          {techs.length === 0 && (
            <Card>
              <CardContent className="py-8 text-center">
                <AlertCircle size={24} className="mx-auto text-muted mb-2" />
                <p className="text-sm text-muted">No team members found</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
