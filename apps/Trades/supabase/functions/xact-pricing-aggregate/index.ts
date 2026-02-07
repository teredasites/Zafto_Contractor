// Supabase Edge Function: xact-pricing-aggregate
// Monthly cron job that aggregates pricing_contributions into pricing_entries.
// Runs with service role key — no user auth required.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Get all distinct code_id + region_code combinations from contributions
    const { data: groups, error: groupErr } = await supabase
      .from('pricing_contributions')
      .select('code_id, region_code')

    if (groupErr) {
      return new Response(JSON.stringify({ error: groupErr.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Deduplicate groups
    const uniqueGroups = new Map<string, { code_id: string; region_code: string }>()
    for (const g of (groups || [])) {
      const key = `${g.code_id}:${g.region_code}`
      if (!uniqueGroups.has(key)) {
        uniqueGroups.set(key, g)
      }
    }

    let updated = 0
    let created = 0

    for (const [, group] of uniqueGroups) {
      // Get all contributions for this code + region
      const { data: contributions } = await supabase
        .from('pricing_contributions')
        .select('material_cost, labor_cost, equipment_cost')
        .eq('code_id', group.code_id)
        .eq('region_code', group.region_code)

      if (!contributions || contributions.length === 0) continue

      // Calculate averages
      const count = contributions.length
      const avgMaterial = contributions.reduce((sum, c) => sum + Number(c.material_cost || 0), 0) / count
      const avgLabor = contributions.reduce((sum, c) => sum + Number(c.labor_cost || 0), 0) / count
      const avgEquipment = contributions.reduce((sum, c) => sum + Number(c.equipment_cost || 0), 0) / count

      // Determine confidence based on data point count
      let confidence = 'low'
      if (count >= 50) confidence = 'verified'
      else if (count >= 20) confidence = 'high'
      else if (count >= 5) confidence = 'medium'

      // Upsert into pricing_entries (global — no company_id)
      const today = new Date().toISOString().split('T')[0]

      // Check if entry exists
      const { data: existing } = await supabase
        .from('pricing_entries')
        .select('id')
        .eq('code_id', group.code_id)
        .eq('region_code', group.region_code)
        .is('company_id', null)
        .single()

      if (existing) {
        await supabase
          .from('pricing_entries')
          .update({
            material_cost: Math.round(avgMaterial * 100) / 100,
            labor_cost: Math.round(avgLabor * 100) / 100,
            equipment_cost: Math.round(avgEquipment * 100) / 100,
            source: 'crowd',
            source_count: count,
            confidence,
            effective_date: today,
          })
          .eq('id', existing.id)
        updated++
      } else {
        await supabase
          .from('pricing_entries')
          .insert({
            code_id: group.code_id,
            region_code: group.region_code,
            material_cost: Math.round(avgMaterial * 100) / 100,
            labor_cost: Math.round(avgLabor * 100) / 100,
            equipment_cost: Math.round(avgEquipment * 100) / 100,
            source: 'crowd',
            source_count: count,
            confidence,
            effective_date: today,
          })
        created++
      }
    }

    console.log(`Pricing aggregation complete: ${created} created, ${updated} updated from ${uniqueGroups.size} code/region groups`)

    return new Response(JSON.stringify({
      success: true,
      groups: uniqueGroups.size,
      created,
      updated,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
