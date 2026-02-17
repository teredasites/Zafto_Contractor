// ZAFTO — Mold Clearance Certificate PDF Export
// Generates insurance-grade HTML clearance document
// Sprint REST2 — Mold remediation dedicated tools

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
    // Auth
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const companyId = user.app_metadata?.company_id;
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'No company' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Parse request
    const { assessment_id } = await req.json();
    if (!assessment_id) {
      return new Response(JSON.stringify({ error: 'assessment_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch assessment
    const { data: assessment, error: fetchErr } = await supabase
      .from('mold_assessments')
      .select('*')
      .eq('id', assessment_id)
      .eq('company_id', companyId)
      .single();

    if (fetchErr || !assessment) {
      return new Response(JSON.stringify({ error: 'Assessment not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch company
    const { data: company } = await supabase
      .from('companies')
      .select('name, address, city, state, zip, phone, email, license_number')
      .eq('id', companyId)
      .single();

    // Fetch chain of custody samples
    const { data: samples } = await supabase
      .from('mold_chain_of_custody')
      .select('*')
      .eq('mold_assessment_id', assessment_id)
      .order('created_at', { ascending: true });

    // Fetch job
    const { data: job } = await supabase
      .from('jobs')
      .select('title, address, city, state, zip')
      .eq('id', assessment.job_id)
      .single();

    // Generate HTML
    const html = generateClearanceHTML(assessment, company, job, samples ?? []);

    return new Response(JSON.stringify({ html }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// deno-lint-ignore no-explicit-any
function generateClearanceHTML(assessment: any, company: any, job: any, samples: any[]): string {
  const companyName = company?.name ?? 'Company';
  const companyAddr = [company?.address, company?.city, company?.state, company?.zip].filter(Boolean).join(', ');
  const jobAddr = [job?.address, job?.city, job?.state, job?.zip].filter(Boolean).join(', ');
  const levelLabel = assessment.iicrc_level === 1 ? 'Level 1 — Small (<10 sqft)' :
                     assessment.iicrc_level === 2 ? 'Level 2 — Medium (10-30 sqft)' :
                     'Level 3 — Large (>30 sqft)';

  const clearanceLabel = assessment.clearance_status === 'passed' ? 'PASSED' :
                         assessment.clearance_status === 'failed' ? 'FAILED' :
                         assessment.clearance_status ?? 'Pending';

  const clearanceColor = assessment.clearance_status === 'passed' ? '#16a34a' :
                         assessment.clearance_status === 'failed' ? '#dc2626' : '#d97706';

  const sporeReduction = assessment.spore_count_before && assessment.spore_count_after && assessment.spore_count_before > 0
    ? ((assessment.spore_count_before - assessment.spore_count_after) / assessment.spore_count_before * 100).toFixed(1)
    : null;

  const formatDate = (iso: string | null) => {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  };

  // Material removal table rows
  const materialRows = (assessment.material_removal ?? []).map((m: { material: string; removed_at: string; removed_by: string }) =>
    `<tr><td>${escapeHtml(m.material ?? '')}</td><td>${formatDate(m.removed_at)}</td><td>${escapeHtml(m.removed_by ?? '')}</td></tr>`
  ).join('');

  // Equipment table rows
  const equipmentRows = (assessment.equipment_deployed ?? []).map((eq: { equipment: string; deployed_at: string }) =>
    `<tr><td>${escapeHtml(eq.equipment ?? '')}</td><td>${formatDate(eq.deployed_at)}</td></tr>`
  ).join('');

  // Sample table rows
  const sampleRows = samples.map((s) =>
    `<tr>
      <td>${escapeHtml(s.sample_type ?? '')}</td>
      <td>${escapeHtml(s.sample_location ?? '')}</td>
      <td>${escapeHtml(s.lab_name ?? '')}</td>
      <td>${s.spore_count ? s.spore_count.toLocaleString() : '—'}</td>
      <td style="font-weight:bold;color:${s.pass_fail === 'pass' ? '#16a34a' : s.pass_fail === 'fail' ? '#dc2626' : '#6b7280'}">
        ${s.pass_fail ? s.pass_fail.toUpperCase() : 'Pending'}
      </td>
    </tr>`
  ).join('');

  // Protocol steps
  const protocolSteps = (assessment.protocol_steps ?? []).map((step: { step_index: number; completed: boolean; completed_at: string }) =>
    `<tr>
      <td>${step.step_index + 1}</td>
      <td>${step.completed ? '✓' : '—'}</td>
      <td>${step.completed ? formatDate(step.completed_at) : '—'}</td>
    </tr>`
  ).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Mold Clearance Certificate — ${companyName}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Helvetica Neue', Arial, sans-serif; font-size: 11px; color: #1a1a1a; line-height: 1.5; padding: 40px; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 3px solid #111; }
    .company-name { font-size: 20px; font-weight: 700; }
    .company-info { font-size: 10px; color: #555; }
    .doc-title { font-size: 16px; font-weight: 700; text-align: right; }
    .doc-subtitle { font-size: 10px; color: #555; text-align: right; }
    .clearance-badge { display: inline-block; padding: 8px 20px; font-size: 18px; font-weight: 800; letter-spacing: 2px; border: 3px solid ${clearanceColor}; color: ${clearanceColor}; border-radius: 6px; margin-top: 10px; }
    .section { margin-bottom: 20px; }
    .section-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #333; padding-bottom: 4px; border-bottom: 1px solid #ddd; margin-bottom: 8px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 20px; }
    .field-label { font-size: 9px; text-transform: uppercase; color: #888; letter-spacing: 0.5px; }
    .field-value { font-size: 11px; font-weight: 500; }
    table { width: 100%; border-collapse: collapse; margin-top: 6px; }
    th { text-align: left; font-size: 9px; text-transform: uppercase; color: #666; padding: 4px 8px; border-bottom: 1px solid #ddd; background: #f8f8f8; }
    td { padding: 4px 8px; border-bottom: 1px solid #eee; font-size: 10px; }
    .spore-section { background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 16px; margin: 12px 0; }
    .spore-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; text-align: center; }
    .spore-value { font-size: 18px; font-weight: 700; }
    .spore-label { font-size: 9px; text-transform: uppercase; color: #555; }
    .footer { margin-top: 30px; padding-top: 15px; border-top: 2px solid #111; font-size: 9px; color: #666; }
    .signature-line { margin-top: 40px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
    .sig-box { border-top: 1px solid #333; padding-top: 4px; font-size: 9px; color: #555; }
    @media print { body { padding: 20px; } .no-print { display: none; } }
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
      <div class="doc-title">Mold Clearance Certificate</div>
      <div class="doc-subtitle">IICRC S520 Compliant</div>
      <div class="doc-subtitle">${formatDate(assessment.clearance_date ?? assessment.updated_at)}</div>
      <div style="text-align:right"><span class="clearance-badge">${clearanceLabel}</span></div>
    </div>
  </div>

  <!-- Property Info -->
  <div class="section">
    <div class="section-title">Property Information</div>
    <div class="grid">
      <div><span class="field-label">Address</span><div class="field-value">${escapeHtml(jobAddr || 'N/A')}</div></div>
      <div><span class="field-label">Assessment Date</span><div class="field-value">${formatDate(assessment.created_at)}</div></div>
      <div><span class="field-label">IICRC Level</span><div class="field-value">${escapeHtml(levelLabel)}</div></div>
      <div><span class="field-label">Affected Area</span><div class="field-value">${assessment.affected_area_sqft ? assessment.affected_area_sqft + ' sqft' : 'TBD'}</div></div>
      <div><span class="field-label">Mold Type</span><div class="field-value">${escapeHtml(assessment.mold_type ?? 'Visual ID pending')}</div></div>
      <div><span class="field-label">Moisture Source</span><div class="field-value">${escapeHtml(assessment.moisture_source ?? 'Under investigation')}</div></div>
      <div><span class="field-label">Containment</span><div class="field-value">${escapeHtml(assessment.containment_type ?? 'None')}${assessment.negative_pressure ? ' + Negative Pressure' : ''}</div></div>
      <div><span class="field-label">Air Sampling</span><div class="field-value">${assessment.air_sampling_required ? 'Required' : 'Not required'}</div></div>
    </div>
  </div>

  <!-- Clearance Inspector -->
  <div class="section">
    <div class="section-title">Clearance Inspector</div>
    <div class="grid">
      <div><span class="field-label">Inspector</span><div class="field-value">${escapeHtml(assessment.clearance_inspector ?? 'N/A')}</div></div>
      <div><span class="field-label">Company</span><div class="field-value">${escapeHtml(assessment.clearance_company ?? 'N/A')}</div></div>
      <div><span class="field-label">Clearance Date</span><div class="field-value">${formatDate(assessment.clearance_date)}</div></div>
      <div><span class="field-label">Result</span><div class="field-value" style="color:${clearanceColor};font-weight:700">${clearanceLabel}</div></div>
    </div>
  </div>

  <!-- Spore Counts -->
  ${(assessment.spore_count_before || assessment.spore_count_after) ? `
  <div class="spore-section">
    <div class="section-title" style="border-bottom:none;margin-bottom:12px">Air Quality Results</div>
    <div class="spore-grid">
      <div>
        <div class="spore-label">Pre-Remediation</div>
        <div class="spore-value">${assessment.spore_count_before ? assessment.spore_count_before.toLocaleString() : '—'}</div>
        <div class="spore-label">spores/m³</div>
      </div>
      <div>
        <div class="spore-label">Post-Remediation</div>
        <div class="spore-value">${assessment.spore_count_after ? assessment.spore_count_after.toLocaleString() : '—'}</div>
        <div class="spore-label">spores/m³</div>
      </div>
      <div>
        <div class="spore-label">Reduction</div>
        <div class="spore-value" style="color:${sporeReduction && parseFloat(sporeReduction) >= 80 ? '#16a34a' : '#dc2626'}">${sporeReduction ? sporeReduction + '%' : '—'}</div>
        <div class="spore-label">&nbsp;</div>
      </div>
    </div>
  </div>` : ''}

  <!-- Air Samples -->
  ${samples.length > 0 ? `
  <div class="section">
    <div class="section-title">Chain of Custody — Air Samples (${samples.length})</div>
    <table>
      <thead><tr><th>Type</th><th>Location</th><th>Lab</th><th>Spore Count</th><th>Result</th></tr></thead>
      <tbody>${sampleRows}</tbody>
    </table>
  </div>` : ''}

  <!-- Materials Removed -->
  ${materialRows ? `
  <div class="section">
    <div class="section-title">Materials Removed (${(assessment.material_removal ?? []).length})</div>
    <table>
      <thead><tr><th>Material</th><th>Date Removed</th><th>Removed By</th></tr></thead>
      <tbody>${materialRows}</tbody>
    </table>
  </div>` : ''}

  <!-- Equipment Deployed -->
  ${equipmentRows ? `
  <div class="section">
    <div class="section-title">Equipment Deployed (${(assessment.equipment_deployed ?? []).length})</div>
    <table>
      <thead><tr><th>Equipment</th><th>Date Deployed</th></tr></thead>
      <tbody>${equipmentRows}</tbody>
    </table>
  </div>` : ''}

  <!-- Protocol Steps -->
  ${protocolSteps ? `
  <div class="section">
    <div class="section-title">Protocol Steps Completed</div>
    <table>
      <thead><tr><th>#</th><th>Status</th><th>Date</th></tr></thead>
      <tbody>${protocolSteps}</tbody>
    </table>
  </div>` : ''}

  <!-- Notes -->
  ${assessment.notes ? `
  <div class="section">
    <div class="section-title">Notes</div>
    <p style="font-size:10px;color:#444">${escapeHtml(assessment.notes)}</p>
  </div>` : ''}

  <!-- Signatures -->
  <div class="signature-line">
    <div>
      <div class="sig-box">Remediation Contractor Signature / Date</div>
    </div>
    <div>
      <div class="sig-box">Clearance Inspector Signature / Date</div>
    </div>
  </div>

  <div class="footer">
    <p>This document certifies that mold remediation was performed in accordance with IICRC S520 standards.</p>
    <p>Generated by Zafto — Professional Contractor Management Platform</p>
    <p style="margin-top:4px">Assessment ID: ${assessment.id}</p>
  </div>
</body>
</html>`;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
