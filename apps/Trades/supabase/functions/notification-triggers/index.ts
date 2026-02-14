// Notification Triggers — runs daily via pg_cron (7am per company timezone)
// 6 trigger types: overdue invoices, expired bids, past-deadline jobs,
// expiring certs, service visits due, missed clock-outs

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const now = new Date();
    const todayISO = now.toISOString().split('T')[0];
    const sevenDaysOut = new Date(now.getTime() + 7 * 86400000).toISOString().split('T')[0];
    const thirtyDaysOut = new Date(now.getTime() + 30 * 86400000).toISOString().split('T')[0];
    const twelveHoursAgo = new Date(now.getTime() - 12 * 3600000).toISOString();

    const notifications: {
      company_id: string;
      user_id: string;
      trigger_type: string;
      title: string;
      body: string;
      action_url: string;
      entity_type: string;
      entity_id: string;
    }[] = [];

    // ── 1. Overdue Invoices ──────────────────────────────────────
    const { data: overdueInvoices } = await supabase
      .from('invoices')
      .select('id, company_id, created_by_user_id, invoice_number, due_date')
      .lt('due_date', todayISO)
      .not('status', 'in', '("paid","cancelled","draft")')
      .is('deleted_at', null);

    for (const inv of overdueInvoices || []) {
      const days = Math.ceil((now.getTime() - new Date(inv.due_date).getTime()) / 86400000);
      notifications.push({
        company_id: inv.company_id,
        user_id: inv.created_by_user_id,
        trigger_type: 'invoice_overdue',
        title: `Invoice ${inv.invoice_number} overdue`,
        body: `Overdue by ${days} day${days === 1 ? '' : 's'}`,
        action_url: `/dashboard/invoices`,
        entity_type: 'invoice',
        entity_id: inv.id,
      });
    }

    // ── 2. Expired Bids ──────────────────────────────────────────
    const { data: expiredBids } = await supabase
      .from('bids')
      .select('id, company_id, created_by_user_id, bid_number, valid_until')
      .lt('valid_until', todayISO)
      .eq('status', 'sent')
      .is('deleted_at', null);

    for (const bid of expiredBids || []) {
      notifications.push({
        company_id: bid.company_id,
        user_id: bid.created_by_user_id,
        trigger_type: 'bid_expired',
        title: `Bid ${bid.bid_number} expired`,
        body: 'Expired without response',
        action_url: `/dashboard/bids`,
        entity_type: 'bid',
        entity_id: bid.id,
      });
    }

    // ── 3. Jobs Past Deadline ────────────────────────────────────
    const { data: lateJobs } = await supabase
      .from('jobs')
      .select('id, company_id, assigned_to, title, scheduled_end')
      .lt('scheduled_end', todayISO)
      .eq('status', 'in_progress')
      .is('deleted_at', null);

    for (const job of lateJobs || []) {
      if (job.assigned_to) {
        notifications.push({
          company_id: job.company_id,
          user_id: job.assigned_to,
          trigger_type: 'job_past_deadline',
          title: `Job "${job.title}" past deadline`,
          body: `Scheduled end was ${job.scheduled_end}`,
          action_url: `/dashboard/jobs/${job.id}`,
          entity_type: 'job',
          entity_id: job.id,
        });
      }
    }

    // ── 4. Expiring Certifications (30 days) ─────────────────────
    const { data: expiringCerts } = await supabase
      .from('certifications')
      .select('id, company_id, user_id, name, expiry_date')
      .lte('expiry_date', thirtyDaysOut)
      .gte('expiry_date', todayISO);

    for (const cert of expiringCerts || []) {
      const days = Math.ceil((new Date(cert.expiry_date).getTime() - now.getTime()) / 86400000);
      notifications.push({
        company_id: cert.company_id,
        user_id: cert.user_id,
        trigger_type: 'cert_expiring',
        title: `Certification "${cert.name}" expiring`,
        body: `Expires in ${days} day${days === 1 ? '' : 's'}`,
        action_url: `/dashboard/team`,
        entity_type: 'certification',
        entity_id: cert.id,
      });
    }

    // ── 5. Service Agreement Visits Due (7 days) ─────────────────
    const { data: visitsDue } = await supabase
      .from('service_agreements')
      .select('id, company_id, created_by_user_id, agreement_number, next_visit_date')
      .lte('next_visit_date', sevenDaysOut)
      .gte('next_visit_date', todayISO)
      .eq('status', 'active');

    for (const sa of visitsDue || []) {
      notifications.push({
        company_id: sa.company_id,
        user_id: sa.created_by_user_id,
        trigger_type: 'service_visit_due',
        title: `Service visit due — ${sa.agreement_number}`,
        body: `Next visit: ${sa.next_visit_date}`,
        action_url: `/dashboard/service-agreements`,
        entity_type: 'service_agreement',
        entity_id: sa.id,
      });
    }

    // ── 6. Missed Clock-Outs (12+ hours) ─────────────────────────
    const { data: missedClockouts } = await supabase
      .from('time_entries')
      .select('id, company_id, user_id')
      .is('clock_out', null)
      .lt('clock_in', twelveHoursAgo);

    for (const te of missedClockouts || []) {
      notifications.push({
        company_id: te.company_id,
        user_id: te.user_id,
        trigger_type: 'missed_clockout',
        title: 'Possible missed clock-out',
        body: 'Clocked in over 12 hours ago without clocking out',
        action_url: `/dashboard/time-clock`,
        entity_type: 'time_entry',
        entity_id: te.id,
      });
    }

    // ── Deduplicate: don't re-notify for same entity today ───────
    const deduped: typeof notifications = [];
    for (const n of notifications) {
      const { count } = await supabase
        .from('notification_log')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', n.user_id)
        .eq('entity_id', n.entity_id)
        .eq('trigger_type', n.trigger_type)
        .gte('created_at', `${todayISO}T00:00:00Z`);

      if ((count || 0) === 0) deduped.push(n);
    }

    // ── Insert notifications ─────────────────────────────────────
    if (deduped.length > 0) {
      // Insert in chunks of 50
      for (let i = 0; i < deduped.length; i += 50) {
        const chunk = deduped.slice(i, i + 50);
        await supabase.from('notification_log').insert(chunk);
      }
    }

    return new Response(
      JSON.stringify({ success: true, processed: notifications.length, sent: deduped.length }),
      { headers: corsHeaders }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: corsHeaders }
    );
  }
});
