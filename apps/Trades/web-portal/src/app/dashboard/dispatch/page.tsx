'use client';

import { useState, useEffect, useCallback, useRef, DragEvent } from 'react';
import { useRouter } from 'next/navigation';
import {
  Radio,
  MapPin,
  Clock,
  User,
  AlertCircle,
  ChevronRight,
  ArrowRight,
  RefreshCw,
  Filter,
  Zap,
  Map,
  List,
  Navigation,
  MessageSquare,
  GripVertical,
  Truck,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar } from '@/components/ui/avatar';
import { cn, formatRelativeTime } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

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
  customerId: string | null;
  address: string;
  latitude: number | null;
  longitude: number | null;
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
  vehicleName: string | null;
  vehiclePlate: string | null;
}

// ============================================================
// Haversine distance (meters) between two GPS coords
// ============================================================

function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371000; // meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Estimate drive time from straight-line distance. ~40 km/h avg city speed, 1.4x detour factor */
function estimateDriveMinutes(distMeters: number): number {
  const detourFactor = 1.4;
  const avgSpeedMps = 40000 / 3600; // ~11.1 m/s
  return Math.round((distMeters * detourFactor) / avgSpeedMps / 60);
}

// ============================================================
// Page
// ============================================================

export default function DispatchPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const [unassignedJobs, setUnassignedJobs] = useState<DispatchJob[]>([]);
  const [assignedJobs, setAssignedJobs] = useState<DispatchJob[]>([]);
  const [techs, setTechs] = useState<TechStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [priorityFilter, setPriorityFilter] = useState<string>('all');
  const [dispatching, setDispatching] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'map'>('list');
  const [draggedJobId, setDraggedJobId] = useState<string | null>(null);
  const [dropTargetTechId, setDropTargetTechId] = useState<string | null>(null);
  const [smsStatus, setSmsStatus] = useState<Record<string, string>>({});
  const dragCounterRef = useRef<Record<string, number>>({});

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();

      // Fetch today's + tomorrow's jobs
      const { data: jobsData } = await supabase
        .from('jobs')
        .select(
          'id, title, status, priority, job_type, customer_name, customer_phone, customer_id, address_line1, address_city, address_state, latitude, longitude, scheduled_start, assigned_user_ids, created_at'
        )
        .is('deleted_at', null)
        .in('status', [
          'lead',
          'quoted',
          'scheduled',
          'dispatched',
          'in_progress',
        ])
        .order('priority', { ascending: false })
        .order('scheduled_start', { ascending: true });

      const jobs: DispatchJob[] = (jobsData || []).map(
        (j: Record<string, unknown>) => ({
          id: j.id as string,
          title: (j.title as string) || 'Untitled Job',
          status: (j.status as string) || 'lead',
          priority: (j.priority as string) || 'medium',
          jobType: (j.job_type as string) || 'standard',
          customerName: (j.customer_name as string) || 'Unknown',
          customerPhone: (j.customer_phone as string) || null,
          customerId: (j.customer_id as string) || null,
          address: [
            j.address_line1 as string,
            j.address_city as string,
            j.address_state as string,
          ]
            .filter(Boolean)
            .join(', ') || 'No address',
          latitude: (j.latitude as number) || null,
          longitude: (j.longitude as number) || null,
          scheduledStart: (j.scheduled_start as string) || null,
          assignedUserIds: (j.assigned_user_ids as string[]) || [],
          createdAt: j.created_at as string,
        })
      );

      setUnassignedJobs(
        jobs.filter(
          (j) => j.assignedUserIds.length === 0 && j.status !== 'in_progress'
        )
      );
      setAssignedJobs(
        jobs.filter(
          (j) => j.assignedUserIds.length > 0 || j.status === 'in_progress'
        )
      );

      // Fetch active techs
      const { data: usersData } = await supabase
        .from('users')
        .select('id, full_name, email, role')
        .is('deleted_at', null)
        .in('role', [
          'technician',
          'field_tech',
          'apprentice',
          'admin',
          'owner',
        ]);

      // Fetch active time entries (clocked in)
      const { data: timeEntries } = await supabase
        .from('time_entries')
        .select('user_id, clock_in, job_id, gps_lat_in, gps_lng_in')
        .is('clock_out', null)
        .order('clock_in', { ascending: false });

      // Fetch vehicle assignments for techs
      const userIds = (usersData || []).map(
        (u: Record<string, unknown>) => u.id as string
      );
      const { data: vehicleData } =
        userIds.length > 0
          ? await supabase
              .from('vehicles')
              .select('id, name, license_plate, assigned_to_user_id')
              .in('assigned_to_user_id', userIds)
          : { data: null };

      const vehicleByUser: Record<string, { name: string; plate: string }> = {};
      for (const v of vehicleData || []) {
        const veh = v as Record<string, unknown>;
        const uid = veh.assigned_to_user_id as string;
        if (uid) {
          vehicleByUser[uid] = {
            name: (veh.name as string) || 'Vehicle',
            plate: (veh.license_plate as string) || '',
          };
        }
      }

      // Build tech status
      const techMap: Record<string, TechStatus> = {};
      for (const u of usersData || []) {
        const user = u as Record<string, unknown>;
        const uid = user.id as string;
        const vehicle = vehicleByUser[uid];
        techMap[uid] = {
          id: uid,
          fullName: (user.full_name as string) || (user.email as string),
          email: (user.email as string) || '',
          role: (user.role as string) || 'technician',
          isClockedIn: false,
          currentJobId: null,
          currentJobTitle: null,
          lastLocation: null,
          clockInTime: null,
          vehicleName: vehicle?.name || null,
          vehiclePlate: vehicle?.plate || null,
        };
      }

      for (const te of timeEntries || []) {
        const entry = te as Record<string, unknown>;
        const userId = entry.user_id as string;
        const tech = techMap[userId];
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

      setTechs(
        Object.values(techMap).sort((a, b) => {
          if (a.isClockedIn && !b.isClockedIn) return -1;
          if (!a.isClockedIn && b.isClockedIn) return 1;
          if (a.currentJobId && !b.currentJobId) return 1;
          if (!a.currentJobId && b.currentJobId) return -1;
          return a.fullName.localeCompare(b.fullName);
        })
      );
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
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'jobs' },
        () => fetchData()
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'time_entries' },
        () => fetchData()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchData]);

  // ==========================================================
  // Dispatch + SMS
  // ==========================================================

  const handleDispatch = async (jobId: string, techId: string) => {
    setDispatching(jobId);
    try {
      const supabase = getSupabase();
      const tech = techs.find((t) => t.id === techId);
      const job = unassignedJobs.find((j) => j.id === jobId);

      // Update job assignment
      await supabase
        .from('jobs')
        .update({
          assigned_user_ids: [techId],
          status: 'dispatched',
        })
        .eq('id', jobId);

      // Send customer SMS notification (non-blocking)
      if (job?.customerPhone && tech) {
        sendDispatchSms(job, tech).catch(() => {
          // Non-critical — don't fail dispatch on SMS failure
        });
      }

      // Data refreshes via real-time subscription
    } catch (err) {
      console.error('Dispatch error:', err);
    } finally {
      setDispatching(null);
      setDraggedJobId(null);
      setDropTargetTechId(null);
    }
  };

  const sendDispatchSms = async (job: DispatchJob, tech: TechStatus) => {
    try {
      setSmsStatus((prev) => ({ ...prev, [job.id]: 'sending' }));

      // Calculate ETA if GPS data available
      let etaText = '';
      if (tech.lastLocation && job.latitude && job.longitude) {
        const dist = haversineDistance(
          tech.lastLocation.lat,
          tech.lastLocation.lng,
          job.latitude,
          job.longitude
        );
        const minutes = estimateDriveMinutes(dist);
        if (minutes <= 5) {
          etaText = ' Estimated arrival: less than 5 minutes.';
        } else if (minutes <= 60) {
          etaText = ` Estimated arrival: ~${minutes} minutes.`;
        } else {
          const hrs = Math.round(minutes / 30) / 2;
          etaText = ` Estimated arrival: ~${hrs} hours.`;
        }
      }

      const firstName = tech.fullName.split(' ')[0];
      const message = `${firstName} from your service team is on the way to ${job.address}.${etaText} Questions? Reply to this text.`;

      const supabase = getSupabase();
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (session?.access_token) {
        await fetch(
          `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/signalwire-sms`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${session.access_token}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              action: 'send',
              toNumber: job.customerPhone,
              message,
              customerId: job.customerId,
              jobId: job.id,
            }),
          }
        );
      }

      setSmsStatus((prev) => ({ ...prev, [job.id]: 'sent' }));
      setTimeout(
        () => setSmsStatus((prev) => ({ ...prev, [job.id]: '' })),
        3000
      );
    } catch (e) {
      console.error('Dispatch SMS failed:', e);
      setSmsStatus((prev) => ({ ...prev, [job.id]: 'failed' }));
      setTimeout(
        () => setSmsStatus((prev) => ({ ...prev, [job.id]: '' })),
        3000
      );
    }
  };

  // ==========================================================
  // Drag & Drop
  // ==========================================================

  const onDragStart = (e: DragEvent, jobId: string) => {
    setDraggedJobId(jobId);
    e.dataTransfer.setData('text/plain', jobId);
    e.dataTransfer.effectAllowed = 'move';
  };

  const onDragEnd = () => {
    setDraggedJobId(null);
    setDropTargetTechId(null);
    dragCounterRef.current = {};
  };

  const onDragEnterTech = (e: DragEvent, techId: string) => {
    e.preventDefault();
    dragCounterRef.current[techId] = (dragCounterRef.current[techId] || 0) + 1;
    setDropTargetTechId(techId);
  };

  const onDragLeaveTech = (_e: DragEvent, techId: string) => {
    dragCounterRef.current[techId] = (dragCounterRef.current[techId] || 0) - 1;
    if (dragCounterRef.current[techId] <= 0) {
      dragCounterRef.current[techId] = 0;
      if (dropTargetTechId === techId) setDropTargetTechId(null);
    }
  };

  const onDragOverTech = (e: DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  };

  const onDropTech = (e: DragEvent, techId: string) => {
    e.preventDefault();
    const jobId = e.dataTransfer.getData('text/plain');
    if (jobId && techId) {
      handleDispatch(jobId, techId);
    }
    dragCounterRef.current = {};
  };

  // ==========================================================
  // ETA Helpers
  // ==========================================================

  const getEtaForTechToJob = (
    tech: TechStatus,
    job: DispatchJob
  ): string | null => {
    if (!tech.lastLocation || !job.latitude || !job.longitude) return null;
    const dist = haversineDistance(
      tech.lastLocation.lat,
      tech.lastLocation.lng,
      job.latitude,
      job.longitude
    );
    const minutes = estimateDriveMinutes(dist);
    if (minutes <= 5) return '<5 min';
    if (minutes <= 60) return `~${minutes} min`;
    const hrs = Math.round(minutes / 30) / 2;
    return `~${hrs}h`;
  };

  // ==========================================================
  // Filtering
  // ==========================================================

  const filteredUnassigned =
    priorityFilter === 'all'
      ? unassignedJobs
      : unassignedJobs.filter((j) => j.priority === priorityFilter);

  const availableTechs = techs.filter(
    (t) => t.isClockedIn && !t.currentJobId
  );
  const onJobTechs = techs.filter((t) => t.isClockedIn && t.currentJobId);
  const offlineTechs = techs.filter((t) => !t.isClockedIn);

  const priorityColor = (p: string) => {
    switch (p) {
      case 'urgent':
        return 'text-red-500 bg-red-500/10';
      case 'high':
        return 'text-amber-500 bg-amber-500/10';
      case 'medium':
        return 'text-blue-500 bg-blue-500/10';
      default:
        return 'text-slate-400 bg-slate-500/10';
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
            <h1 className="text-2xl font-semibold text-main">
              {t('dispatch.title')}
            </h1>
            <p className="text-sm text-muted">
              {unassignedJobs.length} {t('dispatch.unassigned').toLowerCase()} &middot;{' '}
              {assignedJobs.length} {t('dispatch.dispatched').toLowerCase()} &middot;{' '}
              {availableTechs.length} {t('common.available').toLowerCase()}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {/* View mode toggle */}
          <div className="flex rounded-lg border border-default overflow-hidden">
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'px-3 py-1.5 text-xs flex items-center gap-1',
                viewMode === 'list'
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main'
              )}
            >
              <List size={14} /> {t('dispatch.listView')}
            </button>
            <button
              onClick={() => setViewMode('map')}
              className={cn(
                'px-3 py-1.5 text-xs flex items-center gap-1',
                viewMode === 'map'
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main'
              )}
            >
              <Map size={14} /> {t('dispatch.mapView')}
            </button>
          </div>
          <Button variant="secondary" onClick={fetchData}>
            <RefreshCw size={14} className="mr-1" /> {t('common.refresh')}
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">{t('dispatch.unassigned')}</p>
            <p className="text-2xl font-bold text-main">
              {unassignedJobs.length}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">{t('dispatch.dispatched')}</p>
            <p className="text-2xl font-bold text-accent">
              {assignedJobs.length}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">{t('dispatch.availableTechs')}</p>
            <p className="text-2xl font-bold text-emerald-500">
              {availableTechs.length}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3">
            <p className="text-xs text-muted">{t('dispatch.onJob')}</p>
            <p className="text-2xl font-bold text-amber-500">
              {onJobTechs.length}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Drag hint */}
      {draggedJobId && (
        <div className="bg-accent/10 border border-accent/30 rounded-lg px-4 py-2 text-sm text-accent flex items-center gap-2">
          <Navigation size={14} />
          {t('dispatch.dropHint')}
        </div>
      )}

      {/* Map View */}
      {viewMode === 'map' && (
        <Card>
          <CardContent className="py-8">
            <div className="min-h-[400px] flex flex-col items-center justify-center text-center">
              <Map size={48} className="text-muted mb-4" />
              <h3 className="text-lg font-semibold text-main mb-1">
                {t('dispatch.mapViewTitle')}
              </h3>
              <p className="text-sm text-muted max-w-md mb-4">
                {t('dispatch.mapViewDesc')}
              </p>

              {/* Summary grid as text-based map alternative */}
              <div className="w-full max-w-2xl grid grid-cols-1 md:grid-cols-2 gap-3 mt-4">
                {/* Jobs with locations */}
                <div className="text-left">
                  <h4 className="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                    {t('dispatch.jobLocations')} ({[...unassignedJobs, ...assignedJobs].filter((j) => j.latitude).length} {t('dispatch.withGPS')})
                  </h4>
                  {[...unassignedJobs, ...assignedJobs]
                    .filter((j) => j.latitude)
                    .slice(0, 8)
                    .map((j) => (
                      <div
                        key={j.id}
                        className="flex items-center gap-2 py-1 text-xs"
                      >
                        <MapPin
                          size={10}
                          className={
                            j.assignedUserIds.length > 0
                              ? 'text-accent'
                              : 'text-red-400'
                          }
                        />
                        <span className="text-main truncate flex-1">
                          {j.title}
                        </span>
                        <span className="text-muted">{j.address}</span>
                      </div>
                    ))}
                </div>

                {/* Techs with GPS */}
                <div className="text-left">
                  <h4 className="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                    {t('dispatch.techLocations')} ({techs.filter((t) => t.lastLocation).length} {t('dispatch.withGPS')})
                  </h4>
                  {techs
                    .filter((t) => t.lastLocation)
                    .map((t) => (
                      <div
                        key={t.id}
                        className="flex items-center gap-2 py-1 text-xs"
                      >
                        <div
                          className={cn(
                            'w-2 h-2 rounded-full',
                            t.currentJobId
                              ? 'bg-amber-500'
                              : t.isClockedIn
                              ? 'bg-emerald-500'
                              : 'bg-slate-400'
                          )}
                        />
                        <span className="text-main truncate flex-1">
                          {t.fullName}
                        </span>
                        {t.vehicleName && (
                          <span className="text-muted flex items-center gap-1">
                            <Truck size={10} /> {t.vehicleName}
                          </span>
                        )}
                      </div>
                    ))}
                  {techs.filter((t) => t.lastLocation).length === 0 && (
                    <p className="text-xs text-muted">
                      {t('dispatch.noTechsGPS')}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left: Unassigned Jobs */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-main">
                {t('dispatch.unassignedJobs')}
              </h2>
              <div className="flex gap-1">
                <Filter size={14} className="text-muted mt-1 mr-1" />
                {['all', 'urgent', 'high', 'medium', 'low'].map((p) => (
                  <button
                    key={p}
                    onClick={() => setPriorityFilter(p)}
                    className={cn(
                      'px-2 py-1 rounded text-xs font-medium',
                      priorityFilter === p
                        ? 'bg-accent text-white'
                        : 'bg-secondary text-muted hover:text-main'
                    )}
                  >
                    {p === 'all'
                      ? 'All'
                      : p.charAt(0).toUpperCase() + p.slice(1)}
                  </button>
                ))}
              </div>
            </div>

            {filteredUnassigned.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <Zap size={24} className="mx-auto text-muted mb-2" />
                  <p className="text-muted">{t('dispatch.noUnassigned')}</p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-2">
                {filteredUnassigned.map((job) => (
                  <div
                    key={job.id}
                    draggable
                    onDragStart={(e) => onDragStart(e, job.id)}
                    onDragEnd={onDragEnd}
                    className={cn(
                      'cursor-grab active:cursor-grabbing',
                      draggedJobId === job.id && 'opacity-50'
                    )}
                  >
                  <Card
                    className={cn(
                      'hover:border-accent/30 transition-colors',
                      draggedJobId === job.id && 'border-accent'
                    )}
                  >
                    <CardContent className="py-3">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2 flex-1 min-w-0">
                          <GripVertical
                            size={14}
                            className="text-muted/40 flex-shrink-0"
                          />
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span
                                className={cn(
                                  'px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase',
                                  priorityColor(job.priority)
                                )}
                              >
                                {job.priority}
                              </span>
                              <h3 className="font-medium text-main text-sm truncate">
                                {job.title}
                              </h3>
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
                                  <Clock size={12} />{' '}
                                  {new Date(
                                    job.scheduledStart
                                  ).toLocaleTimeString([], {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        {/* Quick dispatch buttons */}
                        <div className="flex items-center gap-2 ml-4">
                          {availableTechs.length > 0 ? (
                            <div className="flex gap-1">
                              {availableTechs.slice(0, 3).map((tech) => {
                                const eta = getEtaForTechToJob(tech, job);
                                return (
                                  <button
                                    key={tech.id}
                                    onClick={() =>
                                      handleDispatch(job.id, tech.id)
                                    }
                                    disabled={dispatching === job.id}
                                    className="flex items-center gap-1 px-2 py-1 rounded bg-emerald-500/10 text-emerald-600 hover:bg-emerald-500/20 text-xs font-medium transition-colors disabled:opacity-50"
                                    title={`Dispatch to ${tech.fullName}${eta ? ` (ETA: ${eta})` : ''}`}
                                  >
                                    <ArrowRight size={10} />
                                    {tech.fullName.split(' ')[0]}
                                    {eta && (
                                      <span className="text-[10px] opacity-70 ml-0.5">
                                        {eta}
                                      </span>
                                    )}
                                  </button>
                                );
                              })}
                            </div>
                          ) : (
                            <span className="text-xs text-muted">
                              {t('dispatch.noTechsAvailable')}
                            </span>
                          )}
                          {/* SMS status indicator */}
                          {smsStatus[job.id] === 'sent' && (
                            <MessageSquare
                              size={12}
                              className="text-emerald-500"
                            />
                          )}
                          {smsStatus[job.id] === 'sending' && (
                            <MessageSquare
                              size={12}
                              className="text-muted animate-pulse"
                            />
                          )}
                          <button
                            onClick={() =>
                              router.push(`/dashboard/jobs/${job.id}`)
                            }
                            className="p-1.5 rounded hover:bg-surface-hover text-muted"
                          >
                            <ChevronRight size={16} />
                          </button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                  </div>
                ))}
              </div>
            )}

            {/* Currently Dispatched */}
            {assignedJobs.length > 0 && (
              <>
                <h2 className="text-lg font-semibold text-main mt-6">
                  {t('dispatch.dispatchedJobs')}
                </h2>
                <div className="space-y-2">
                  {assignedJobs.map((job) => (
                    <Card key={job.id} className="border-accent/20">
                      <CardContent className="py-3">
                        <div className="flex items-center justify-between">
                          <div>
                            <div className="flex items-center gap-2">
                              <Badge
                                variant={
                                  job.status === 'in_progress'
                                    ? 'success'
                                    : 'info'
                                }
                              >
                                {job.status.replace(/_/g, ' ')}
                              </Badge>
                              <h3 className="font-medium text-main text-sm">
                                {job.title}
                              </h3>
                            </div>
                            <div className="flex items-center gap-4 mt-1 text-xs text-muted">
                              <span>{job.customerName}</span>
                              <span>{job.address}</span>
                            </div>
                          </div>
                          <button
                            onClick={() =>
                              router.push(`/dashboard/jobs/${job.id}`)
                            }
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
            <h2 className="text-lg font-semibold text-main">
              {t('dispatch.technicians')}
              {draggedJobId && (
                <span className="text-xs text-accent ml-2 font-normal">
                  {t('dispatch.dropJobHere')}
                </span>
              )}
            </h2>

            {/* Available */}
            {availableTechs.length > 0 && (
              <Card>
                <CardHeader className="py-2">
                  <CardTitle className="text-sm text-emerald-500 flex items-center gap-1">
                    <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    {t('dispatch.available')} ({availableTechs.length})
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 pt-0">
                  {availableTechs.map((tech) => (
                    <div
                      key={tech.id}
                      onDragEnter={(e) => onDragEnterTech(e, tech.id)}
                      onDragLeave={(e) => onDragLeaveTech(e, tech.id)}
                      onDragOver={onDragOverTech}
                      onDrop={(e) => onDropTech(e, tech.id)}
                      className={cn(
                        'flex items-center gap-3 p-2 rounded-lg transition-all',
                        dropTargetTechId === tech.id
                          ? 'bg-accent/20 ring-2 ring-accent scale-[1.02]'
                          : 'bg-emerald-500/5',
                        draggedJobId && 'cursor-copy'
                      )}
                    >
                      <Avatar name={tech.fullName} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-main truncate">
                          {tech.fullName}
                        </p>
                        <p className="text-xs text-muted">
                          {t('dispatch.clockedIn')}{' '}
                          {tech.clockInTime
                            ? formatRelativeTime(tech.clockInTime)
                            : ''}
                          {tech.vehicleName && ` · ${tech.vehicleName}`}
                          {tech.lastLocation && (
                            <span className="ml-1 text-emerald-500">
                              <MapPin
                                size={10}
                                className="inline-block -mt-0.5"
                              />{' '}
                              GPS
                            </span>
                          )}
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
                    {t('dispatch.onJobLabel')} ({onJobTechs.length})
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 pt-0">
                  {onJobTechs.map((tech) => (
                    <div
                      key={tech.id}
                      className="flex items-center gap-3 p-2 rounded-lg bg-amber-500/5"
                    >
                      <Avatar name={tech.fullName} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-main truncate">
                          {tech.fullName}
                        </p>
                        <p className="text-xs text-muted truncate">
                          {tech.currentJobTitle}
                          {tech.vehicleName && ` · ${tech.vehicleName}`}
                        </p>
                      </div>
                      {tech.currentJobId && (
                        <button
                          onClick={() =>
                            router.push(
                              `/dashboard/jobs/${tech.currentJobId}`
                            )
                          }
                          className="text-xs text-accent hover:underline"
                        >
                          {t('common.view')}
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
                    {t('dispatch.offline')} ({offlineTechs.length})
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 pt-0">
                  {offlineTechs.map((tech) => (
                    <div
                      key={tech.id}
                      className="flex items-center gap-3 p-2 rounded-lg opacity-60"
                    >
                      <Avatar name={tech.fullName} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-main truncate">
                          {tech.fullName}
                        </p>
                        <p className="text-xs text-muted">
                          {tech.role}
                          {tech.vehicleName && ` · ${tech.vehicleName}`}
                        </p>
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
                  <p className="text-sm text-muted">{t('dispatch.noTeamMembers')}</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
