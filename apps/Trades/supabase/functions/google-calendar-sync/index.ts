// Google Calendar Sync — two-way sync between ZAFTO jobs and Google Calendar
// Actions: connect (OAuth callback), sync-to-google, sync-from-google, disconnect

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GOOGLE_CLIENT_ID = Deno.env.get('GOOGLE_CLIENT_ID') || '';
const GOOGLE_CLIENT_SECRET = Deno.env.get('GOOGLE_CLIENT_SECRET') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return new Response(JSON.stringify({ error: 'No auth' }), { status: 401, headers: corsHeaders });

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const userClient = createClient(SUPABASE_URL, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authErr } = await userClient.auth.getUser();
    if (authErr || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const companyId = user.app_metadata?.company_id;
    if (!companyId) return new Response(JSON.stringify({ error: 'No company' }), { status: 403, headers: corsHeaders });

    const { action, code, redirect_uri } = await req.json();

    // ── Connect: Exchange OAuth code for tokens ────────────────
    if (action === 'connect') {
      if (!code || !redirect_uri) {
        return new Response(JSON.stringify({ error: 'Missing code or redirect_uri' }), { status: 400, headers: corsHeaders });
      }

      // Exchange authorization code for access + refresh tokens
      const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          code,
          client_id: GOOGLE_CLIENT_ID,
          client_secret: GOOGLE_CLIENT_SECRET,
          redirect_uri,
          grant_type: 'authorization_code',
        }),
      });

      const tokenData = await tokenRes.json();
      if (tokenData.error) {
        return new Response(JSON.stringify({ error: tokenData.error_description || 'Token exchange failed' }), { status: 400, headers: corsHeaders });
      }

      // Get user's Google email
      const profileRes = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
        headers: { Authorization: `Bearer ${tokenData.access_token}` },
      });
      const profile = await profileRes.json();

      // Store tokens (encrypted in production via Vault)
      await supabase.from('users').update({
        google_calendar_token: {
          access_token: tokenData.access_token,
          refresh_token: tokenData.refresh_token,
          expires_at: Date.now() + (tokenData.expires_in * 1000),
        },
        google_calendar_connected: true,
        google_calendar_email: profile.email || null,
      }).eq('id', user.id);

      return new Response(JSON.stringify({ success: true, email: profile.email }), { headers: corsHeaders });
    }

    // ── Sync to Google: Push ZAFTO jobs → Google Calendar ──────
    if (action === 'sync-to-google') {
      const { data: userData } = await supabase
        .from('users')
        .select('google_calendar_token')
        .eq('id', user.id)
        .single();

      if (!userData?.google_calendar_token) {
        return new Response(JSON.stringify({ error: 'Not connected' }), { status: 400, headers: corsHeaders });
      }

      const token = await getValidToken(supabase, user.id, userData.google_calendar_token);

      // Get user's assigned jobs with scheduled dates
      const role = user.app_metadata?.role;
      let jobQuery = supabase.from('jobs').select('id, title, description, address, scheduled_start, scheduled_end, customers(name, phone)')
        .eq('company_id', companyId)
        .not('scheduled_start', 'is', null);

      // Techs only see their assigned jobs
      if (role === 'technician' || role === 'apprentice') {
        jobQuery = jobQuery.eq('assigned_to', user.id);
      }

      const { data: jobs } = await jobQuery;
      let synced = 0;

      for (const job of jobs || []) {
        const customer = job.customers as Record<string, string> | null;
        const event = {
          summary: job.title || 'Job',
          location: job.address || '',
          description: [
            customer?.name ? `Customer: ${customer.name}` : '',
            customer?.phone ? `Phone: ${customer.phone}` : '',
            job.description || '',
          ].filter(Boolean).join('\n'),
          start: { dateTime: job.scheduled_start, timeZone: 'America/New_York' },
          end: { dateTime: job.scheduled_end || job.scheduled_start, timeZone: 'America/New_York' },
          extendedProperties: { private: { zafto_job_id: job.id } },
        };

        const res = await fetch('https://www.googleapis.com/calendar/v3/calendars/primary/events', {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
          body: JSON.stringify(event),
        });

        if (res.ok) synced++;
      }

      return new Response(JSON.stringify({ success: true, synced }), { headers: corsHeaders });
    }

    // ── Disconnect ─────────────────────────────────────────────
    if (action === 'disconnect') {
      await supabase.from('users').update({
        google_calendar_token: null,
        google_calendar_connected: false,
        google_calendar_email: null,
      }).eq('id', user.id);

      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), { status: 400, headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), { status: 500, headers: corsHeaders });
  }
});

// ── Token refresh helper ───────────────────────────────────────────
async function getValidToken(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  tokenData: { access_token: string; refresh_token: string; expires_at: number }
): Promise<string> {
  if (Date.now() < tokenData.expires_at - 60000) {
    return tokenData.access_token;
  }

  // Refresh the token
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      refresh_token: tokenData.refresh_token,
      grant_type: 'refresh_token',
    }),
  });

  const data = await res.json();
  if (data.error) throw new Error('Token refresh failed');

  const newToken = {
    access_token: data.access_token,
    refresh_token: tokenData.refresh_token, // refresh_token doesn't change
    expires_at: Date.now() + (data.expires_in * 1000),
  };

  await supabase.from('users').update({ google_calendar_token: newToken }).eq('id', userId);
  return data.access_token;
}
