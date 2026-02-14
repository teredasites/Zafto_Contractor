// Predictive Maintenance Engine — runs monthly via pg_cron
// Scans all home_equipment, calculates age vs lifecycle curves,
// generates predictions for equipment approaching maintenance or end-of-life.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface Prediction {
  company_id: string;
  equipment_id: string;
  customer_id: string | null;
  prediction_type: string;
  predicted_date: string;
  confidence_score: number;
  recommended_action: string;
  estimated_cost: number | null;
  outreach_status: string;
  notes: string | null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const now = new Date();
    const todayISO = now.toISOString().split('T')[0];

    // 1. Load all lifecycle reference data
    const { data: lifecycleData, error: lcErr } = await supabase
      .from('equipment_lifecycle_data')
      .select('*');

    if (lcErr || !lifecycleData) {
      throw new Error('Failed to load lifecycle data');
    }

    // Build lookup by category (and optionally manufacturer)
    const lifecycleMap = new Map<string, Record<string, unknown>>();
    for (const lc of lifecycleData) {
      const key = lc.manufacturer
        ? `${lc.equipment_category}:${lc.manufacturer.toLowerCase()}`
        : lc.equipment_category;
      lifecycleMap.set(key, lc);
      // Also store generic category if not already present
      if (lc.manufacturer && !lifecycleMap.has(lc.equipment_category)) {
        lifecycleMap.set(lc.equipment_category, lc);
      }
    }

    // 2. Load all equipment with install dates
    const { data: equipment, error: eqErr } = await supabase
      .from('home_equipment')
      .select('id, company_id, customer_id, name, category, manufacturer, install_date, warranty_start_date, created_at')
      .is('deleted_at', null);

    if (eqErr || !equipment) {
      throw new Error('Failed to load equipment');
    }

    // 3. Load existing predictions (to avoid duplicates)
    const { data: existingPredictions } = await supabase
      .from('maintenance_predictions')
      .select('equipment_id, prediction_type, predicted_date')
      .is('deleted_at', null);

    const existingSet = new Set(
      (existingPredictions || []).map(
        (p: Record<string, unknown>) => `${p.equipment_id}:${p.prediction_type}:${p.predicted_date}`
      )
    );

    // 4. Generate predictions
    const predictions: Prediction[] = [];
    let skipped = 0;

    for (const eq of equipment) {
      const category = (eq.category as string) || null;
      if (!category) continue;

      // Find lifecycle data — try manufacturer-specific first, then generic
      const mfg = (eq.manufacturer as string || '').toLowerCase();
      const lifecycle = lifecycleMap.get(`${category}:${mfg}`) || lifecycleMap.get(category);
      if (!lifecycle) continue;

      // Calculate equipment age
      const installDateStr = (eq.install_date as string) || (eq.warranty_start_date as string) || (eq.created_at as string);
      const installDate = new Date(installDateStr);
      const ageYears = (now.getTime() - installDate.getTime()) / (365.25 * 86400000);

      const avgLifespan = lifecycle.avg_lifespan_years as number;
      const maintenanceMonths = lifecycle.maintenance_interval_months as number;
      const companyId = eq.company_id as string;
      const equipmentId = eq.id as string;
      const customerId = eq.customer_id as string | null;
      const eqName = eq.name as string;

      // ── Prediction: End of Life ─────────────────────────────
      const remainingLifeYears = avgLifespan - ageYears;
      if (remainingLifeYears <= 2 && remainingLifeYears > -1) {
        // Equipment within 2 years of expected end-of-life
        const predictedDate = new Date(installDate.getTime() + avgLifespan * 365.25 * 86400000);
        const predDateISO = predictedDate.toISOString().split('T')[0];
        const dedupKey = `${equipmentId}:end_of_life:${predDateISO}`;

        if (!existingSet.has(dedupKey)) {
          const confidence = remainingLifeYears <= 0 ? 0.9 : (0.5 + 0.2 * (2 - remainingLifeYears));
          predictions.push({
            company_id: companyId,
            equipment_id: equipmentId,
            customer_id: customerId,
            prediction_type: 'end_of_life',
            predicted_date: predDateISO,
            confidence_score: Math.min(confidence, 0.95),
            recommended_action: `${eqName} is approaching end of expected lifespan (${avgLifespan} years). Recommend proactive replacement planning.`,
            estimated_cost: null,
            outreach_status: 'pending',
            notes: `Age: ${ageYears.toFixed(1)} years, Expected lifespan: ${avgLifespan} years`,
          });
        } else {
          skipped++;
        }
      }

      // ── Prediction: Maintenance Due ─────────────────────────
      if (maintenanceMonths > 0) {
        // Calculate next maintenance date based on install date + intervals
        const intervalMs = maintenanceMonths * 30.44 * 86400000;
        const timeSinceInstall = now.getTime() - installDate.getTime();
        const intervalsPassed = Math.floor(timeSinceInstall / intervalMs);
        const nextMaintenanceDate = new Date(installDate.getTime() + (intervalsPassed + 1) * intervalMs);

        // Only predict if within next 60 days
        const daysUntilMaint = (nextMaintenanceDate.getTime() - now.getTime()) / 86400000;
        if (daysUntilMaint <= 60 && daysUntilMaint >= -30) {
          const predDateISO = nextMaintenanceDate.toISOString().split('T')[0];
          const dedupKey = `${equipmentId}:maintenance_due:${predDateISO}`;

          if (!existingSet.has(dedupKey)) {
            predictions.push({
              company_id: companyId,
              equipment_id: equipmentId,
              customer_id: customerId,
              prediction_type: 'maintenance_due',
              predicted_date: predDateISO,
              confidence_score: 0.85,
              recommended_action: `Scheduled maintenance for ${eqName} (every ${maintenanceMonths} months).`,
              estimated_cost: null,
              outreach_status: 'pending',
              notes: `Maintenance interval: ${maintenanceMonths} months`,
            });
          } else {
            skipped++;
          }
        }
      }

      // ── Prediction: Seasonal Checks ─────────────────────────
      const seasonalMaint = lifecycle.seasonal_maintenance as string[] | null;
      if (seasonalMaint && seasonalMaint.length > 0) {
        const month = now.getMonth(); // 0-based
        for (const season of seasonalMaint) {
          let targetMonth: number | null = null;
          if (season.includes('spring') && month >= 1 && month <= 4) targetMonth = 2; // March
          if (season.includes('fall') && month >= 7 && month <= 10) targetMonth = 8; // September
          if (season.includes('annual') && month === 0) targetMonth = 1; // February

          if (targetMonth !== null) {
            const targetDate = new Date(now.getFullYear(), targetMonth, 15);
            const daysUntil = (targetDate.getTime() - now.getTime()) / 86400000;

            if (daysUntil >= -15 && daysUntil <= 45) {
              const predDateISO = targetDate.toISOString().split('T')[0];
              const dedupKey = `${equipmentId}:seasonal_check:${predDateISO}`;

              if (!existingSet.has(dedupKey)) {
                predictions.push({
                  company_id: companyId,
                  equipment_id: equipmentId,
                  customer_id: customerId,
                  prediction_type: 'seasonal_check',
                  predicted_date: predDateISO,
                  confidence_score: 0.90,
                  recommended_action: `Seasonal ${season.replace('_', ' ')} recommended for ${eqName}.`,
                  estimated_cost: null,
                  outreach_status: 'pending',
                  notes: `Seasonal: ${season}`,
                });
              } else {
                skipped++;
              }
            }
          }
        }
      }
    }

    // 5. Bulk insert predictions
    if (predictions.length > 0) {
      // Insert in chunks of 100
      for (let i = 0; i < predictions.length; i += 100) {
        const chunk = predictions.slice(i, i + 100);
        const { error: insertErr } = await supabase
          .from('maintenance_predictions')
          .insert(chunk);

        if (insertErr) {
          console.error(`Failed to insert predictions chunk ${i}:`, insertErr);
        }
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        equipmentScanned: equipment.length,
        predictionsGenerated: predictions.length,
        skippedDuplicates: skipped,
        date: todayISO,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Predictive maintenance engine error:', err);
    return new Response(
      JSON.stringify({ ok: false, error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
