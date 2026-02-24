import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts';

/**
 * Kiosk Clock Edge Function
 *
 * Public endpoint (no user auth) for tablet/PC-based time clock kiosks.
 * Authenticates via kiosk access_token, not user JWT.
 *
 * Actions:
 *   verify_token  — Load kiosk config + employee list by access_token
 *   verify_pin    — Check employee PIN against stored hash
 *   clock_in      — Create time_entry via service role
 *   clock_out     — Update time_entry via service role
 *   start_break   — Record break start
 *   end_break     — Record break end
 */

interface KioskRequest {
  action: 'verify_token' | 'verify_pin' | 'clock_in' | 'clock_out' | 'start_break' | 'end_break';
  access_token: string;
  user_id?: string;
  pin?: string;
  job_id?: string;
  clock_in_method?: string;
}

// Simple SHA-256 hash for PIN verification
async function sha256(message: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

serve(async (req: Request) => {
  const origin = req.headers.get('Origin');

  if (req.method === 'OPTIONS') return corsResponse(origin);

  try {
    const body: KioskRequest = await req.json();
    const { action, access_token } = body;

    if (!access_token) {
      return errorResponse('Missing access_token', 400, origin);
    }

    // Service-role client for all operations (kiosk has no user auth)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // ── 1. Look up kiosk config by token ──
    const { data: kiosk, error: kioskErr } = await supabase
      .from('kiosk_configs')
      .select('id, company_id, name, is_active, auth_methods, settings, branding')
      .eq('access_token', access_token)
      .is('deleted_at', null)
      .single();

    if (kioskErr || !kiosk) {
      return errorResponse('Invalid kiosk token', 404, origin);
    }

    if (!kiosk.is_active) {
      return errorResponse('Kiosk is deactivated', 403, origin);
    }

    const companyId = kiosk.company_id;

    // ── VERIFY TOKEN ──
    if (action === 'verify_token') {
      // Fetch active employees for this company
      const { data: employees } = await supabase
        .from('users')
        .select('id, full_name, avatar_url, role, trade')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('full_name');

      // Fetch company name and logo
      const { data: company } = await supabase
        .from('companies')
        .select('name, logo_url')
        .eq('id', companyId)
        .single();

      // Check which employees have PINs set
      const { data: pins } = await supabase
        .from('employee_kiosk_pins')
        .select('user_id')
        .eq('company_id', companyId);

      const pinsSet = new Set((pins || []).map((p: { user_id: string }) => p.user_id));

      // Check for active clock-ins today
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);

      const { data: activeEntries } = await supabase
        .from('time_entries')
        .select('id, user_id, clock_in, status, break_minutes')
        .eq('company_id', companyId)
        .gte('clock_in', todayStart.toISOString())
        .is('deleted_at', null)
        .in('status', ['active']);

      const activeMap: Record<string, { entryId: string; clockIn: string; breakMinutes: number }> = {};
      for (const entry of activeEntries || []) {
        activeMap[entry.user_id] = {
          entryId: entry.id,
          clockIn: entry.clock_in,
          breakMinutes: entry.break_minutes || 0,
        };
      }

      return new Response(
        JSON.stringify({
          kiosk: {
            id: kiosk.id,
            name: kiosk.name,
            authMethods: kiosk.auth_methods,
            settings: kiosk.settings,
            branding: kiosk.branding,
          },
          company: company || { name: 'Unknown', logo_url: null },
          employees: (employees || []).map((e: Record<string, unknown>) => ({
            id: e.id,
            name: e.full_name,
            avatar: e.avatar_url,
            role: e.role,
            trade: e.trade,
            hasPin: pinsSet.has(e.id as string),
            activeEntry: activeMap[e.id as string] || null,
          })),
        }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    // ── VERIFY PIN ──
    if (action === 'verify_pin') {
      const { user_id, pin } = body;
      if (!user_id || !pin) {
        return errorResponse('Missing user_id or pin', 400, origin);
      }

      const pinHash = await sha256(pin);

      const { data: pinRecord } = await supabase
        .from('employee_kiosk_pins')
        .select('pin_hash')
        .eq('company_id', companyId)
        .eq('user_id', user_id)
        .single();

      if (!pinRecord || pinRecord.pin_hash !== pinHash) {
        return errorResponse('Invalid PIN', 401, origin);
      }

      return new Response(
        JSON.stringify({ verified: true }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    // ── CLOCK IN ──
    if (action === 'clock_in') {
      const { user_id, job_id, clock_in_method } = body;
      if (!user_id) {
        return errorResponse('Missing user_id', 400, origin);
      }

      // Check not already clocked in
      const { data: existing } = await supabase
        .from('time_entries')
        .select('id')
        .eq('company_id', companyId)
        .eq('user_id', user_id)
        .eq('status', 'active')
        .is('deleted_at', null)
        .limit(1);

      if (existing && existing.length > 0) {
        return errorResponse('Employee already clocked in', 409, origin);
      }

      const { data: entry, error: insertErr } = await supabase
        .from('time_entries')
        .insert({
          company_id: companyId,
          user_id,
          job_id: job_id || null,
          clock_in: new Date().toISOString(),
          status: 'active',
          kiosk_config_id: kiosk.id,
          clock_in_method: clock_in_method || 'kiosk_pin',
          location_pings: JSON.stringify([]),
        })
        .select('id, clock_in')
        .single();

      if (insertErr) {
        return errorResponse(insertErr.message, 500, origin);
      }

      return new Response(
        JSON.stringify({ success: true, entry_id: entry.id, clock_in: entry.clock_in }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    // ── CLOCK OUT ──
    if (action === 'clock_out') {
      const { user_id } = body;
      if (!user_id) {
        return errorResponse('Missing user_id', 400, origin);
      }

      // Find active entry
      const { data: active } = await supabase
        .from('time_entries')
        .select('id, clock_in, break_minutes')
        .eq('company_id', companyId)
        .eq('user_id', user_id)
        .eq('status', 'active')
        .is('deleted_at', null)
        .order('clock_in', { ascending: false })
        .limit(1)
        .single();

      if (!active) {
        return errorResponse('No active clock-in found', 404, origin);
      }

      const clockOut = new Date();
      const clockIn = new Date(active.clock_in);
      const totalMinutes = Math.max(0, Math.floor((clockOut.getTime() - clockIn.getTime()) / 60000) - (active.break_minutes || 0));
      const hourlyRate = 0; // Will be populated by payroll engine

      const { error: updateErr } = await supabase
        .from('time_entries')
        .update({
          clock_out: clockOut.toISOString(),
          status: 'completed',
          total_minutes: totalMinutes,
        })
        .eq('id', active.id);

      if (updateErr) {
        return errorResponse(updateErr.message, 500, origin);
      }

      return new Response(
        JSON.stringify({
          success: true,
          entry_id: active.id,
          clock_out: clockOut.toISOString(),
          total_minutes: totalMinutes,
        }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    // ── START BREAK ──
    if (action === 'start_break') {
      const { user_id } = body;
      if (!user_id) {
        return errorResponse('Missing user_id', 400, origin);
      }

      // We track break start via location_pings with type: 'break_start'
      const { data: active } = await supabase
        .from('time_entries')
        .select('id, location_pings')
        .eq('company_id', companyId)
        .eq('user_id', user_id)
        .eq('status', 'active')
        .is('deleted_at', null)
        .order('clock_in', { ascending: false })
        .limit(1)
        .single();

      if (!active) {
        return errorResponse('No active clock-in found', 404, origin);
      }

      const pings = Array.isArray(active.location_pings) ? active.location_pings : [];
      pings.push({ type: 'break_start', timestamp: new Date().toISOString() });

      await supabase
        .from('time_entries')
        .update({ location_pings: pings })
        .eq('id', active.id);

      return new Response(
        JSON.stringify({ success: true, entry_id: active.id }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    // ── END BREAK ──
    if (action === 'end_break') {
      const { user_id } = body;
      if (!user_id) {
        return errorResponse('Missing user_id', 400, origin);
      }

      const { data: active } = await supabase
        .from('time_entries')
        .select('id, location_pings, break_minutes')
        .eq('company_id', companyId)
        .eq('user_id', user_id)
        .eq('status', 'active')
        .is('deleted_at', null)
        .order('clock_in', { ascending: false })
        .limit(1)
        .single();

      if (!active) {
        return errorResponse('No active clock-in found', 404, origin);
      }

      const pings = Array.isArray(active.location_pings) ? active.location_pings : [];

      // Find last break_start
      let breakStart: string | null = null;
      for (let i = pings.length - 1; i >= 0; i--) {
        if (pings[i].type === 'break_start') {
          breakStart = pings[i].timestamp;
          break;
        }
      }

      let additionalBreakMinutes = 0;
      if (breakStart) {
        additionalBreakMinutes = Math.max(0, Math.floor((Date.now() - new Date(breakStart).getTime()) / 60000));
      }

      pings.push({ type: 'break_end', timestamp: new Date().toISOString() });

      await supabase
        .from('time_entries')
        .update({
          location_pings: pings,
          break_minutes: (active.break_minutes || 0) + additionalBreakMinutes,
        })
        .eq('id', active.id);

      return new Response(
        JSON.stringify({
          success: true,
          entry_id: active.id,
          break_minutes_added: additionalBreakMinutes,
          total_break_minutes: (active.break_minutes || 0) + additionalBreakMinutes,
        }),
        {
          status: 200,
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        }
      );
    }

    return errorResponse(`Unknown action: ${action}`, 400, origin);
  } catch (err) {
    const origin = req.headers.get('Origin');
    return errorResponse(
      err instanceof Error ? err.message : 'Internal server error',
      500,
      origin
    );
  }
});
