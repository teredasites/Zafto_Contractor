// Warranty Outreach Scheduler — runs daily via pg_cron
// Scans home_equipment for warranties approaching expiry (6mo, 3mo, 1mo)
// Creates outreach_log entries and optionally triggers SMS/email via SignalWire
//
// Thresholds: 180 days (6mo), 90 days (3mo), 30 days (1mo)
// Dedup: one outreach per equipment per threshold per 30-day window

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface OutreachEntry {
  company_id: string;
  equipment_id: string;
  customer_id: string;
  outreach_type: string;
  outreach_trigger: string;
  message_content: string;
  sent_at: string;
  response_status: string;
  created_by: string | null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const now = new Date();
    const todayISO = now.toISOString().split('T')[0];

    // Calculate threshold dates
    const thresholds = [
      { days: 180, label: '6_month', trigger: 'warranty_expiring_6mo' },
      { days: 90, label: '3_month', trigger: 'warranty_expiring_3mo' },
      { days: 30, label: '1_month', trigger: 'warranty_expiring_1mo' },
    ];

    const outreachEntries: OutreachEntry[] = [];
    let processedCount = 0;
    let skippedCount = 0;

    for (const threshold of thresholds) {
      const targetDate = new Date(now.getTime() + threshold.days * 86400000);
      // Look for equipment expiring within ±7 days of the threshold
      const windowStart = new Date(targetDate.getTime() - 7 * 86400000).toISOString().split('T')[0];
      const windowEnd = new Date(targetDate.getTime() + 7 * 86400000).toISOString().split('T')[0];

      // Fetch equipment with warranties expiring in this window
      const { data: equipment, error: eqErr } = await supabase
        .from('home_equipment')
        .select('id, company_id, customer_id, name, manufacturer, warranty_end_date, customers(name, email, phone)')
        .gte('warranty_end_date', windowStart)
        .lte('warranty_end_date', windowEnd)
        .not('customer_id', 'is', null);

      if (eqErr || !equipment) continue;

      for (const eq of equipment) {
        if (!eq.customer_id) continue;

        // Dedup: check if outreach already sent for this equipment+trigger in last 30 days
        const dedupDate = new Date(now.getTime() - 30 * 86400000).toISOString();
        const { data: existing } = await supabase
          .from('warranty_outreach_log')
          .select('id')
          .eq('equipment_id', eq.id)
          .eq('outreach_trigger', threshold.trigger)
          .gte('created_at', dedupDate)
          .limit(1);

        if (existing && existing.length > 0) {
          skippedCount++;
          continue;
        }

        const customer = eq.customers as Record<string, string> | null;
        const daysLeft = Math.ceil(
          (new Date(eq.warranty_end_date as string).getTime() - now.getTime()) / 86400000
        );

        const message = buildOutreachMessage({
          customerName: customer?.name || 'Homeowner',
          equipmentName: eq.name as string,
          manufacturer: eq.manufacturer as string | null,
          daysLeft,
          thresholdLabel: threshold.label,
        });

        outreachEntries.push({
          company_id: eq.company_id as string,
          equipment_id: eq.id as string,
          customer_id: eq.customer_id as string,
          outreach_type: 'warranty_expiring',
          outreach_trigger: threshold.trigger,
          message_content: message,
          sent_at: now.toISOString(),
          response_status: 'pending',
          created_by: null,
        });

        processedCount++;
      }
    }

    // Also check for recall notices — equipment with recall_status = 'active' that hasn't been notified
    const { data: recalledEquipment } = await supabase
      .from('home_equipment')
      .select('id, company_id, customer_id, name, manufacturer, recall_status, customers(name)')
      .eq('recall_status', 'active')
      .not('customer_id', 'is', null);

    if (recalledEquipment) {
      for (const eq of recalledEquipment) {
        if (!eq.customer_id) continue;

        // Dedup recall notices (one per 90 days)
        const recallDedupDate = new Date(now.getTime() - 90 * 86400000).toISOString();
        const { data: existing } = await supabase
          .from('warranty_outreach_log')
          .select('id')
          .eq('equipment_id', eq.id)
          .eq('outreach_type', 'recall_notice')
          .gte('created_at', recallDedupDate)
          .limit(1);

        if (existing && existing.length > 0) continue;

        const customer = eq.customers as Record<string, string> | null;

        outreachEntries.push({
          company_id: eq.company_id as string,
          equipment_id: eq.id as string,
          customer_id: eq.customer_id as string,
          outreach_type: 'recall_notice',
          outreach_trigger: 'recall_active',
          message_content: `Important: A product recall has been issued for your ${eq.manufacturer || ''} ${eq.name}. Please contact us to schedule a safety inspection.`,
          sent_at: now.toISOString(),
          response_status: 'pending',
          created_by: null,
        });
        processedCount++;
      }
    }

    // Bulk insert outreach entries
    if (outreachEntries.length > 0) {
      const { error: insertErr } = await supabase
        .from('warranty_outreach_log')
        .insert(outreachEntries);

      if (insertErr) {
        console.error('Failed to insert outreach entries:', insertErr);
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        processed: processedCount,
        skipped: skippedCount,
        date: todayISO,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Warranty outreach scheduler error:', err);
    return new Response(
      JSON.stringify({ ok: false, error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

// ── Message Builder ─────────────────────────────────────

function buildOutreachMessage(params: {
  customerName: string;
  equipmentName: string;
  manufacturer: string | null;
  daysLeft: number;
  thresholdLabel: string;
}): string {
  const { customerName, equipmentName, manufacturer, daysLeft, thresholdLabel } = params;
  const mfg = manufacturer ? `${manufacturer} ` : '';

  switch (thresholdLabel) {
    case '6_month':
      return `Hi ${customerName}, your ${mfg}${equipmentName} warranty expires in about 6 months. Consider scheduling a maintenance check while it's still covered. We can also discuss extended warranty options.`;
    case '3_month':
      return `Hi ${customerName}, your ${mfg}${equipmentName} warranty expires in ${daysLeft} days. Now is a great time to address any issues while they're still covered. Would you like to schedule a service visit?`;
    case '1_month':
      return `Hi ${customerName}, urgent: your ${mfg}${equipmentName} warranty expires in just ${daysLeft} days. If you have any concerns about this equipment, please contact us immediately to schedule a covered service visit.`;
    default:
      return `Hi ${customerName}, your ${mfg}${equipmentName} warranty is expiring soon. Contact us to schedule a service visit.`;
  }
}
