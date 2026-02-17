// ZAFTO — WDI/NPMA-33 Report PDF Export
// Generates professional NPMA-33 Wood Destroying Insect inspection report
// Sprint NICHE1 — Pest control module

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const companyId = user.app_metadata?.company_id;
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'No company' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { report_id } = await req.json();
    if (!report_id) {
      return new Response(JSON.stringify({ error: 'report_id required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: report, error: fetchErr } = await supabase
      .from('wdi_reports')
      .select('*')
      .eq('id', report_id)
      .eq('company_id', companyId)
      .single();

    if (fetchErr || !report) {
      return new Response(JSON.stringify({ error: 'Report not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: company } = await supabase
      .from('companies')
      .select('name, address, city, state, zip, phone, license_number')
      .eq('id', companyId)
      .single();

    const html = generateWdiHTML(report, company);

    return new Response(JSON.stringify({ html }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

function escapeHtml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// deno-lint-ignore no-explicit-any
function generateWdiHTML(report: any, company: any): string {
  const companyName = company?.name ?? 'Company';
  const companyAddr = [company?.address, company?.city, company?.state, company?.zip].filter(Boolean).join(', ');
  const propertyAddr = [report.property_address, report.property_city, report.property_state, report.property_zip].filter(Boolean).join(', ');
  const formatDate = (iso: string | null) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  };

  const evidenceItems = [
    { label: 'Live Insects', found: report.live_insects_found },
    { label: 'Dead Insects', found: report.dead_insects_found },
    { label: 'Visible Damage', found: report.damage_visible },
    { label: 'Frass (Droppings)', found: report.frass_found },
    { label: 'Shelter Tubes', found: report.shelter_tubes_found },
    { label: 'Exit Holes', found: report.exit_holes_found },
    { label: 'Moisture Damage', found: report.moisture_damage },
  ];

  const evidenceRows = evidenceItems.map((e) =>
    `<tr><td>${e.label}</td><td style="font-weight:bold;color:${e.found ? '#dc2626' : '#16a34a'}">${e.found ? 'YES' : 'No'}</td></tr>`
  ).join('');

  const insects = (report.insects_identified ?? []).join(', ') || 'None identified';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>WDI Inspection Report — ${escapeHtml(companyName)}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Helvetica Neue', Arial, sans-serif; font-size: 11px; color: #1a1a1a; padding: 40px; }
    .header { display: flex; justify-content: space-between; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 3px solid #111; }
    .company-name { font-size: 18px; font-weight: 700; }
    .company-info { font-size: 10px; color: #555; }
    .doc-title { font-size: 16px; font-weight: 700; text-align: right; }
    .doc-subtitle { font-size: 10px; color: #555; text-align: right; }
    .section { margin-bottom: 18px; }
    .section-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #333; padding-bottom: 4px; border-bottom: 1px solid #ddd; margin-bottom: 8px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 20px; }
    .field-label { font-size: 9px; text-transform: uppercase; color: #888; }
    .field-value { font-size: 11px; font-weight: 500; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 9px; text-transform: uppercase; color: #666; padding: 4px 8px; border-bottom: 1px solid #ddd; background: #f8f8f8; }
    td { padding: 4px 8px; border-bottom: 1px solid #eee; font-size: 10px; }
    .determination { padding: 16px; border: 3px solid; border-radius: 8px; margin: 16px 0; text-align: center; }
    .pass { border-color: #16a34a; background: #f0fdf4; }
    .fail { border-color: #dc2626; background: #fef2f2; }
    .determination-text { font-size: 18px; font-weight: 800; letter-spacing: 2px; }
    .footer { margin-top: 30px; padding-top: 15px; border-top: 2px solid #111; font-size: 9px; color: #666; }
    .sig-line { margin-top: 40px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
    .sig-box { border-top: 1px solid #333; padding-top: 4px; font-size: 9px; color: #555; }
    @media print { body { padding: 20px; } }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="company-name">${escapeHtml(companyName)}</div>
      <div class="company-info">${escapeHtml(companyAddr)}</div>
      ${company?.phone ? `<div class="company-info">${escapeHtml(company.phone)}</div>` : ''}
      ${company?.license_number ? `<div class="company-info">License: ${escapeHtml(company.license_number)}</div>` : ''}
    </div>
    <div>
      <div class="doc-title">Wood Destroying Insect<br/>Inspection Report</div>
      <div class="doc-subtitle">${report.report_type === 'npma_33' ? 'NPMA-33' : report.report_type?.toUpperCase() ?? 'Standard'}</div>
      <div class="doc-subtitle">${formatDate(report.inspection_date)}</div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Property Information</div>
    <div class="grid">
      <div><span class="field-label">Address</span><div class="field-value">${escapeHtml(propertyAddr || 'N/A')}</div></div>
      <div><span class="field-label">Report Number</span><div class="field-value">${escapeHtml(report.report_number ?? 'N/A')}</div></div>
      <div><span class="field-label">Inspection Date</span><div class="field-value">${formatDate(report.inspection_date)}</div></div>
      <div><span class="field-label">Report Type</span><div class="field-value">${report.report_type === 'npma_33' ? 'NPMA-33' : report.report_type}</div></div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Inspector</div>
    <div class="grid">
      <div><span class="field-label">Name</span><div class="field-value">${escapeHtml(report.inspector_name ?? 'N/A')}</div></div>
      <div><span class="field-label">License</span><div class="field-value">${escapeHtml(report.inspector_license ?? 'N/A')}</div></div>
      <div><span class="field-label">Company</span><div class="field-value">${escapeHtml(report.inspector_company ?? companyName)}</div></div>
    </div>
  </div>

  <div class="determination ${report.infestation_found || report.damage_found ? 'fail' : 'pass'}">
    <div class="determination-text" style="color:${report.infestation_found || report.damage_found ? '#dc2626' : '#16a34a'}">
      ${report.infestation_found ? 'INFESTATION FOUND' : report.damage_found ? 'DAMAGE FOUND' : 'NO INFESTATION OR DAMAGE FOUND'}
    </div>
  </div>

  <div class="section">
    <div class="section-title">Evidence Checklist</div>
    <table>
      <thead><tr><th>Evidence Type</th><th>Found</th></tr></thead>
      <tbody>${evidenceRows}</tbody>
    </table>
  </div>

  <div class="section">
    <div class="section-title">Insects Identified</div>
    <p style="font-size:11px">${escapeHtml(insects)}</p>
  </div>

  ${report.recommendations ? `
  <div class="section">
    <div class="section-title">Recommendations</div>
    <p style="font-size:11px">${escapeHtml(report.recommendations)}</p>
  </div>` : ''}

  ${report.treatment_plan ? `
  <div class="section">
    <div class="section-title">Treatment Plan</div>
    <p style="font-size:11px">${escapeHtml(report.treatment_plan)}</p>
  </div>` : ''}

  ${report.estimated_cost ? `
  <div class="section">
    <div class="section-title">Estimated Treatment Cost</div>
    <p style="font-size:14px;font-weight:700">$${Number(report.estimated_cost).toLocaleString()}</p>
  </div>` : ''}

  <div class="sig-line">
    <div><div class="sig-box">Inspector Signature / Date</div></div>
    <div><div class="sig-box">Property Owner / Buyer Signature / Date</div></div>
  </div>

  <div class="footer">
    <p>This report is based on a careful visual inspection of the readily accessible areas of the structure(s) on the date of inspection.</p>
    <p>Areas that were obstructed or inaccessible were not inspected. This report is not a guarantee or warranty.</p>
    <p style="margin-top:4px">Generated by Zafto — Professional Contractor Management Platform | Report ID: ${report.id}</p>
  </div>
</body>
</html>`;
}
