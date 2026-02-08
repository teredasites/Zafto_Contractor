import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ScanRequest {
  action: 'scan' | 'lookup' | 'generate_lead' | 'get_database' | 'add_equipment';
  // scan
  photo_path?: string;
  scan_type?: string;
  property_address?: string;
  lat?: number;
  lng?: number;
  // lookup
  manufacturer?: string;
  model_number?: string;
  category?: string;
  // generate_lead
  scan_id?: string;
  homeowner_name?: string;
  homeowner_email?: string;
  homeowner_phone?: string;
  trade_category?: string;
  service_type?: string;
  urgency?: string;
  description?: string;
  // get_database
  search?: string;
  page?: number;
  // add_equipment
  equipment_data?: Record<string, unknown>;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: ScanRequest = await req.json();
    const { action } = body;

    // Extract user from auth
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;
    let companyId: string | null = null;
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user } } = await supabase.auth.getUser(token);
      userId = user?.id || null;
      companyId = user?.app_metadata?.company_id || null;
    }

    switch (action) {
      case 'scan': {
        if (!body.photo_path) {
          return new Response(JSON.stringify({ error: 'photo_path required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Create scan record
        const { data: scan, error: scanErr } = await supabase
          .from('equipment_scans')
          .insert({
            scanned_by_user_id: userId,
            company_id: companyId,
            photo_path: body.photo_path,
            scan_type: body.scan_type || 'photo',
            property_address: body.property_address || null,
            lat: body.lat || null,
            lng: body.lng || null,
            status: 'pending',
          })
          .select()
          .single();

        if (scanErr) throw scanErr;

        // AI identification would happen here (Phase E)
        // For now, try to match against equipment_database by model plate text
        // The actual AI scan will use Claude Vision API in Phase E

        // Mark as completed with placeholder
        await supabase
          .from('equipment_scans')
          .update({
            status: 'completed',
            ai_confidence: 0,
            ai_diagnosis: {
              condition: 'unknown',
              estimated_age: null,
              issues_found: [],
              urgency: 'normal',
              recommendations: ['AI identification will be available after Phase E deployment'],
            },
          })
          .eq('id', scan.id);

        return new Response(JSON.stringify({
          scan_id: scan.id,
          status: 'completed',
          message: 'Scan recorded. AI identification pending Phase E deployment.',
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'lookup': {
        // Look up equipment in the database by manufacturer + model
        let query = supabase.from('equipment_database').select('*');

        if (body.manufacturer) {
          query = query.ilike('manufacturer', `%${body.manufacturer}%`);
        }
        if (body.model_number) {
          query = query.ilike('model_number', `%${body.model_number}%`);
        }
        if (body.category) {
          query = query.eq('category', body.category);
        }

        const { data: results, error: lookupErr } = await query.limit(20);

        if (lookupErr) throw lookupErr;

        return new Response(JSON.stringify({ results: results || [] }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'generate_lead': {
        if (!body.homeowner_name || !body.trade_category) {
          return new Response(JSON.stringify({ error: 'homeowner_name and trade_category required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Find matching contractors in the area
        const { data: contractors } = await supabase
          .from('contractor_profiles')
          .select('company_id, display_name, avg_rating, trade_categories, service_radius_miles')
          .eq('is_active', true)
          .contains('trade_categories', [body.trade_category])
          .order('avg_rating', { ascending: false })
          .limit(10);

        const matchedContractors = (contractors || []).map((c: Record<string, unknown>) => ({
          company_id: c.company_id,
          match_score: (c.avg_rating as number) || 0,
          distance_miles: 0, // would calculate with PostGIS
        }));

        // Create marketplace lead
        const { data: lead, error: leadErr } = await supabase
          .from('marketplace_leads')
          .insert({
            source_type: body.scan_id ? 'equipment_scan' : 'homeowner_request',
            equipment_scan_id: body.scan_id || null,
            homeowner_name: body.homeowner_name,
            homeowner_email: body.homeowner_email || null,
            homeowner_phone: body.homeowner_phone || null,
            property_address: body.property_address || 'Not provided',
            trade_category: body.trade_category,
            service_type: body.service_type || 'repair',
            urgency: body.urgency || 'normal',
            description: body.description || null,
            matched_contractors: matchedContractors,
            max_bids: 5,
            status: 'open',
            expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          })
          .select()
          .single();

        if (leadErr) throw leadErr;

        // Update scan with lead reference
        if (body.scan_id) {
          await supabase
            .from('equipment_scans')
            .update({ marketplace_lead_id: lead.id, status: 'lead_generated' })
            .eq('id', body.scan_id);
        }

        return new Response(JSON.stringify({
          lead_id: lead.id,
          matched_contractors: matchedContractors.length,
          expires_at: lead.expires_at,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'get_database': {
        const page = body.page || 1;
        const pageSize = 50;
        const offset = (page - 1) * pageSize;

        let query = supabase
          .from('equipment_database')
          .select('*', { count: 'exact' });

        if (body.search) {
          query = query.or(`manufacturer.ilike.%${body.search}%,model_number.ilike.%${body.search}%,model_name.ilike.%${body.search}%`);
        }
        if (body.category) {
          query = query.eq('category', body.category);
        }

        const { data, count, error: dbErr } = await query
          .order('manufacturer')
          .range(offset, offset + pageSize - 1);

        if (dbErr) throw dbErr;

        return new Response(JSON.stringify({
          equipment: data || [],
          total: count || 0,
          page,
          page_size: pageSize,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'add_equipment': {
        if (!body.equipment_data) {
          return new Response(JSON.stringify({ error: 'equipment_data required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const { data: equip, error: addErr } = await supabase
          .from('equipment_database')
          .insert({
            ...body.equipment_data,
            data_source: 'manual',
          })
          .select()
          .single();

        if (addErr) throw addErr;

        return new Response(JSON.stringify({ equipment: equip }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      default:
        return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
