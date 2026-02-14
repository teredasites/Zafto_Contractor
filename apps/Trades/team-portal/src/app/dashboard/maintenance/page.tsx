'use client';

import { useState, useEffect } from 'react';
import { Hammer, Calendar, Clock, CheckCircle2, MapPin, User, Loader2, Inbox, AlertTriangle } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface MaintenanceJob {
  id: string;
  title: string;
  status: string;
  customerName: string;
  address: string;
  scheduledStart: string | null;
  agreementTitle: string | null;
  visitNumber: number | null;
}

function formatTime(d: string | null): string {
  if (!d) return '--';
  return new Date(d).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function formatDate(d: string | null): string {
  if (!d) return '--';
  return new Date(d).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
}

const statusColors: Record<string, string> = {
  scheduled: 'bg-blue-100 text-blue-700',
  dispatched: 'bg-indigo-100 text-indigo-700',
  en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-amber-100 text-amber-700',
  completed: 'bg-green-100 text-green-700',
  on_hold: 'bg-red-100 text-red-700',
};

export default function MaintenancePage() {
  const [todayJobs, setTodayJobs] = useState<MaintenanceJob[]>([]);
  const [upcomingJobs, setUpcomingJobs] = useState<MaintenanceJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setError('Not authenticated'); setLoading(false); return; }

      const companyId = user.app_metadata?.company_id;
      if (!companyId) { setError('No company'); setLoading(false); return; }

      const today = new Date();
      const todayStr = today.toISOString().split('T')[0];
      const weekEnd = new Date(today);
      weekEnd.setDate(weekEnd.getDate() + 7);
      const weekEndStr = weekEnd.toISOString().split('T')[0];

      // Get maintenance/agreement visits scheduled today
      const { data: visitData } = await supabase
        .from('service_agreement_visits')
        .select('*, service_agreements(title, customer_id, customers:customer_id(first_name, last_name)), jobs(title, address, status, scheduled_start)')
        .eq('company_id', companyId)
        .is('deleted_at', null)
        .gte('scheduled_date', todayStr)
        .lte('scheduled_date', weekEndStr)
        .order('scheduled_date', { ascending: true });

      // Also get jobs with type=maintenance scheduled today
      const { data: jobData } = await supabase
        .from('jobs')
        .select('*, customers(first_name, last_name)')
        .eq('company_id', companyId)
        .is('deleted_at', null)
        .or(`trade_type.eq.maintenance,title.ilike.%maintenance%`)
        .gte('scheduled_start', todayStr)
        .lte('scheduled_start', weekEndStr + 'T23:59:59')
        .order('scheduled_start', { ascending: true });

      const allJobs: MaintenanceJob[] = [];

      // Map visits
      (visitData || []).forEach((v: Record<string, unknown>) => {
        const agreement = v.service_agreements as Record<string, unknown> | null;
        const job = v.jobs as Record<string, unknown> | null;
        const customer = agreement?.customers as Record<string, unknown> | null;
        allJobs.push({
          id: v.id as string,
          title: job?.title as string || agreement?.title as string || 'Maintenance Visit',
          status: job?.status as string || v.status as string || 'scheduled',
          customerName: customer ? `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : 'Unknown',
          address: job?.address as string || '',
          scheduledStart: job?.scheduled_start as string || v.scheduled_date as string,
          agreementTitle: agreement?.title as string || null,
          visitNumber: v.visit_number as number || null,
        });
      });

      // Map direct maintenance jobs (avoid duplicates)
      const visitJobIds = new Set((visitData || []).map((v: Record<string, unknown>) => v.job_id).filter(Boolean));
      (jobData || []).forEach((j: Record<string, unknown>) => {
        if (visitJobIds.has(j.id)) return;
        const customer = j.customers as Record<string, unknown> | null;
        allJobs.push({
          id: j.id as string,
          title: j.title as string || 'Maintenance Job',
          status: j.status as string || 'scheduled',
          customerName: customer ? `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : j.customer_name as string || 'Unknown',
          address: j.address as string || '',
          scheduledStart: j.scheduled_start as string || null,
          agreementTitle: null,
          visitNumber: null,
        });
      });

      // Split into today and upcoming
      const todayItems = allJobs.filter(j => {
        if (!j.scheduledStart) return false;
        return j.scheduledStart.startsWith(todayStr);
      });
      const upcomingItems = allJobs.filter(j => {
        if (!j.scheduledStart) return false;
        return !j.scheduledStart.startsWith(todayStr);
      });

      setTodayJobs(todayItems);
      setUpcomingJobs(upcomingItems);
      setLoading(false);
    };

    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 text-[var(--accent)] animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3">
        <AlertTriangle className="h-8 w-8 text-red-400" />
        <p className="text-sm text-red-400">{error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-xl font-semibold text-main">Maintenance</h1>
        <p className="text-sm text-muted mt-1">Service agreement visits and maintenance jobs</p>
      </div>

      {/* Today's Jobs */}
      <div>
        <h2 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
          <Calendar className="h-4 w-4 text-[var(--accent)]" />
          Today ({todayJobs.length})
        </h2>
        {todayJobs.length === 0 ? (
          <div className="bg-main border border-main rounded-xl p-8 text-center">
            <CheckCircle2 className="h-8 w-8 text-green-500 mx-auto mb-2" />
            <p className="text-sm text-muted">No maintenance jobs scheduled today</p>
          </div>
        ) : (
          <div className="space-y-2">
            {todayJobs.map(job => (
              <div key={job.id} className="bg-main border border-main rounded-xl p-4 hover:border-[var(--accent)]/30 transition-colors">
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-amber-500/10 rounded-lg shrink-0">
                    <Hammer className="h-5 w-5 text-amber-500" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-main truncate">{job.title}</span>
                      <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${statusColors[job.status] || 'bg-gray-100 text-gray-600'}`}>
                        {job.status.replace(/_/g, ' ')}
                      </span>
                    </div>
                    <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                      <span className="flex items-center gap-1">
                        <User className="h-3 w-3" />{job.customerName}
                      </span>
                      {job.address && (
                        <span className="flex items-center gap-1 truncate">
                          <MapPin className="h-3 w-3" />{job.address}
                        </span>
                      )}
                      <span className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />{formatTime(job.scheduledStart)}
                      </span>
                    </div>
                    {job.agreementTitle && (
                      <p className="text-[11px] text-[var(--accent)] mt-1">
                        Agreement: {job.agreementTitle}{job.visitNumber ? ` (Visit #${job.visitNumber})` : ''}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Upcoming */}
      {upcomingJobs.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
            <Clock className="h-4 w-4 text-muted" />
            Upcoming This Week ({upcomingJobs.length})
          </h2>
          <div className="space-y-2">
            {upcomingJobs.map(job => (
              <div key={job.id} className="bg-main border border-main rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-blue-500/10 rounded-lg shrink-0">
                    <Hammer className="h-4 w-4 text-blue-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="text-sm font-medium text-main truncate block">{job.title}</span>
                    <div className="flex items-center gap-3 mt-0.5 text-xs text-muted">
                      <span>{job.customerName}</span>
                      <span>{formatDate(job.scheduledStart)}</span>
                      {job.agreementTitle && <span className="text-[var(--accent)]">{job.agreementTitle}</span>}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {todayJobs.length === 0 && upcomingJobs.length === 0 && (
        <div className="bg-main border border-main rounded-xl p-12 text-center">
          <Inbox className="h-12 w-12 text-muted mx-auto mb-3 opacity-50" />
          <p className="text-muted text-sm">No maintenance jobs this week</p>
          <p className="text-muted text-xs mt-1 opacity-75">Jobs linked to service agreements will appear here</p>
        </div>
      )}
    </div>
  );
}
