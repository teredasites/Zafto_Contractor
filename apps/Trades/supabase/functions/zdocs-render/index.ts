import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ZDocsRequest {
  action: 'render' | 'preview' | 'get_entity_data' | 'send_for_signature' | 'verify_signature' | 'get_system_templates';
  // render / preview
  template_id?: string;
  entity_type?: string;
  entity_id?: string;
  title?: string;
  custom_variables?: Record<string, string>;
  // send_for_signature
  render_id?: string;
  signers?: { name: string; email: string; role: string }[];
  // verify_signature
  access_token?: string;
  signature_image_base64?: string;
  signer_name?: string;
}

// Variable substitution — replaces {{variable_name}} patterns
function substituteVariables(html: string, variables: Record<string, string>): string {
  let result = html;
  for (const [key, value] of Object.entries(variables)) {
    const pattern = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
    result = result.replace(pattern, value || '');
  }
  // Remove any remaining unresolved variables
  result = result.replace(/\{\{[^}]+\}\}/g, '');
  return result;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: ZDocsRequest = await req.json();
    const { action } = body;

    // Extract auth
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
      case 'get_entity_data': {
        // Fetch CRM data for a given entity to fill template variables
        if (!body.entity_type || !body.entity_id) {
          return new Response(JSON.stringify({ error: 'entity_type and entity_id required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const variables: Record<string, string> = {};
        const { entity_type, entity_id } = body;

        switch (entity_type) {
          case 'job': {
            const { data: job } = await supabase.from('jobs').select('*').eq('id', entity_id).single();
            if (job) {
              variables.job_title = job.title || '';
              variables.job_number = job.job_number || '';
              variables.job_status = job.status || '';
              variables.job_description = job.description || '';
              variables.job_address = job.address || '';
              variables.job_city = job.city || '';
              variables.job_state = job.state || '';
              variables.job_zip = job.zip_code || '';
              variables.customer_name = job.customer_name || '';
              variables.customer_email = job.customer_email || '';
              variables.customer_phone = job.customer_phone || '';
              variables.start_date = job.start_date || '';
              variables.end_date = job.end_date || '';
              variables.job_total = job.total ? `$${Number(job.total).toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '';
            }
            break;
          }
          case 'customer': {
            const { data: customer } = await supabase.from('customers').select('*').eq('id', entity_id).single();
            if (customer) {
              variables.customer_name = customer.name || '';
              variables.customer_email = customer.email || '';
              variables.customer_phone = customer.phone || '';
              variables.customer_address = customer.address || '';
              variables.customer_city = customer.city || '';
              variables.customer_state = customer.state || '';
              variables.customer_zip = customer.zip_code || '';
              variables.customer_notes = customer.notes || '';
            }
            break;
          }
          case 'estimate': {
            const { data: estimate } = await supabase.from('estimates').select('*, estimate_line_items(*)').eq('id', entity_id).single();
            if (estimate) {
              variables.estimate_number = estimate.estimate_number || '';
              variables.estimate_status = estimate.status || '';
              variables.estimate_total = estimate.total ? `$${Number(estimate.total).toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '';
              variables.estimate_date = estimate.created_at ? new Date(estimate.created_at).toLocaleDateString('en-US') : '';
              variables.customer_name = estimate.customer_name || '';
              variables.property_address = estimate.property_address || '';
              variables.scope_summary = estimate.scope_summary || '';
              // Line items as HTML table
              const items = estimate.estimate_line_items || [];
              if (items.length > 0) {
                variables.line_items_table = '<table style="width:100%;border-collapse:collapse;"><thead><tr style="background:#f5f5f5;"><th style="padding:8px;border:1px solid #ddd;text-align:left;">Description</th><th style="padding:8px;border:1px solid #ddd;text-align:right;">Qty</th><th style="padding:8px;border:1px solid #ddd;text-align:right;">Unit Price</th><th style="padding:8px;border:1px solid #ddd;text-align:right;">Total</th></tr></thead><tbody>' +
                  items.map((item: Record<string, unknown>) =>
                    `<tr><td style="padding:8px;border:1px solid #ddd;">${item.description || ''}</td><td style="padding:8px;border:1px solid #ddd;text-align:right;">${item.quantity || 0}</td><td style="padding:8px;border:1px solid #ddd;text-align:right;">$${Number(item.unit_price || 0).toFixed(2)}</td><td style="padding:8px;border:1px solid #ddd;text-align:right;">$${Number(item.total || 0).toFixed(2)}</td></tr>`
                  ).join('') + '</tbody></table>';
              }
            }
            break;
          }
          case 'invoice': {
            const { data: invoice } = await supabase.from('invoices').select('*').eq('id', entity_id).single();
            if (invoice) {
              variables.invoice_number = invoice.invoice_number || '';
              variables.invoice_status = invoice.status || '';
              variables.invoice_total = invoice.total ? `$${Number(invoice.total).toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '';
              variables.invoice_date = invoice.invoice_date || '';
              variables.due_date = invoice.due_date || '';
              variables.customer_name = invoice.customer_name || '';
              variables.customer_email = invoice.customer_email || '';
              variables.amount_paid = invoice.amount_paid ? `$${Number(invoice.amount_paid).toFixed(2)}` : '$0.00';
              variables.balance_due = invoice.balance_due ? `$${Number(invoice.balance_due).toFixed(2)}` : variables.invoice_total;
            }
            break;
          }
          case 'bid': {
            const { data: bid } = await supabase.from('bids').select('*').eq('id', entity_id).single();
            if (bid) {
              variables.bid_number = bid.bid_number || '';
              variables.bid_status = bid.status || '';
              variables.bid_total = bid.total ? `$${Number(bid.total).toFixed(2)}` : '';
              variables.bid_date = bid.created_at ? new Date(bid.created_at).toLocaleDateString('en-US') : '';
              variables.customer_name = bid.customer_name || '';
              variables.job_title = bid.title || '';
              variables.scope_of_work = bid.scope || '';
              variables.valid_until = bid.valid_until || '';
            }
            break;
          }
          case 'change_order': {
            const { data: co } = await supabase.from('change_orders').select('*').eq('id', entity_id).single();
            if (co) {
              variables.co_number = co.change_order_number || '';
              variables.co_status = co.status || '';
              variables.co_amount = co.amount ? `$${Number(co.amount).toFixed(2)}` : '';
              variables.co_reason = co.reason || '';
              variables.co_description = co.description || '';
              variables.customer_name = co.customer_name || '';
            }
            break;
          }
          case 'claim': {
            const { data: claim } = await supabase.from('insurance_claims').select('*').eq('id', entity_id).single();
            if (claim) {
              variables.claim_number = claim.claim_number || '';
              variables.claim_status = claim.status || '';
              variables.loss_date = claim.loss_date || '';
              variables.insurance_carrier = claim.insurance_carrier || '';
              variables.adjuster_name = claim.adjuster_name || '';
              variables.adjuster_phone = claim.adjuster_phone || '';
              variables.property_address = claim.property_address || '';
            }
            break;
          }
          case 'property': {
            const { data: prop } = await supabase.from('properties').select('*').eq('id', entity_id).single();
            if (prop) {
              variables.property_name = prop.name || '';
              variables.property_address = prop.address || '';
              variables.property_city = prop.city || '';
              variables.property_state = prop.state || '';
              variables.property_zip = prop.zip_code || '';
              variables.property_type = prop.property_type || '';
              variables.unit_count = String(prop.unit_count || 1);
            }
            break;
          }
        }

        // Add company data
        if (companyId) {
          const { data: company } = await supabase.from('companies').select('*').eq('id', companyId).single();
          if (company) {
            variables.company_name = company.name || '';
            variables.company_phone = company.phone || '';
            variables.company_email = company.email || '';
            variables.company_address = company.address || '';
            variables.company_city = company.city || '';
            variables.company_state = company.state || '';
            variables.company_zip = company.zip_code || '';
            variables.company_website = company.website || '';
            variables.company_license = company.license_number || '';
          }
        }

        // Add current date
        variables.current_date = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
        variables.current_year = String(new Date().getFullYear());

        return new Response(JSON.stringify({ variables }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'preview':
      case 'render': {
        if (!body.template_id) {
          return new Response(JSON.stringify({ error: 'template_id required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Fetch template with sections
        const { data: template, error: tmplErr } = await supabase
          .from('document_templates')
          .select('*, zdocs_template_sections(*)')
          .eq('id', body.template_id)
          .single();

        if (tmplErr || !template) {
          return new Response(JSON.stringify({ error: 'Template not found' }), {
            status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Get entity data if entity provided
        let variables: Record<string, string> = {};
        if (body.entity_type && body.entity_id) {
          // Re-use the get_entity_data logic by calling ourselves (inline)
          const entityReq = new Request(req.url, {
            method: 'POST',
            headers: req.headers,
            body: JSON.stringify({ action: 'get_entity_data', entity_type: body.entity_type, entity_id: body.entity_id }),
          });
          // Instead of recursion, just fetch entity data directly
          const entityVars = await fetchEntityVariables(supabase, body.entity_type, body.entity_id, companyId);
          variables = { ...entityVars, ...(body.custom_variables || {}) };
        } else {
          variables = body.custom_variables || {};
        }

        // Build HTML from template
        let html = '';

        // If template has sections, build from sections
        const sections = (template.zdocs_template_sections || [])
          .sort((a: Record<string, number>, b: Record<string, number>) => (a.sort_order || 0) - (b.sort_order || 0));

        if (sections.length > 0) {
          for (const section of sections) {
            // Check conditional visibility
            if (section.is_conditional && section.condition_field) {
              const fieldValue = variables[section.condition_field] || '';
              if (section.condition_value && fieldValue !== section.condition_value) continue;
              if (!section.condition_value && !fieldValue) continue;
            }

            switch (section.section_type) {
              case 'header':
                html += `<div style="text-align:center;margin-bottom:24px;">${substituteVariables(section.content_html || '', variables)}</div>`;
                break;
              case 'signature_block':
                html += `<div style="margin-top:48px;border-top:1px solid #ccc;padding-top:16px;">${substituteVariables(section.content_html || '<p>Signature: ___________________________</p><p>Date: ___________________________</p>', variables)}</div>`;
                break;
              case 'page_break':
                html += '<div style="page-break-after:always;"></div>';
                break;
              case 'divider':
                html += '<hr style="margin:24px 0;border:none;border-top:1px solid #e5e7eb;" />';
                break;
              case 'line_items':
                html += variables.line_items_table || '<p style="color:#999;">[No line items]</p>';
                break;
              default:
                html += substituteVariables(section.content_html || '', variables);
            }
          }
        } else {
          // Use template's content_html directly
          html = substituteVariables(template.content_html || '', variables);
        }

        // Wrap in PDF-ready HTML document
        const fullHtml = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { font-family: 'Helvetica Neue', Arial, sans-serif; font-size: 12px; line-height: 1.5; color: #1a1a1a; max-width: 8.5in; margin: 0 auto; padding: 0.75in; }
  h1 { font-size: 22px; font-weight: 600; margin-bottom: 8px; }
  h2 { font-size: 16px; font-weight: 600; margin-top: 24px; margin-bottom: 8px; }
  h3 { font-size: 14px; font-weight: 600; margin-top: 16px; margin-bottom: 6px; }
  p { margin: 0 0 8px; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0; }
  th, td { padding: 8px; border: 1px solid #e5e7eb; text-align: left; }
  th { background: #f9fafb; font-weight: 600; }
  .signature-block { margin-top: 48px; }
  .signature-line { border-bottom: 1px solid #000; width: 250px; display: inline-block; margin-bottom: 4px; }
  @media print { body { padding: 0; } }
</style>
</head>
<body>
${html}
</body>
</html>`;

        if (action === 'preview') {
          return new Response(JSON.stringify({ html: fullHtml, variables }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Render: save to zdocs_renders table
        if (!companyId) {
          return new Response(JSON.stringify({ error: 'Authentication required' }), {
            status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const { data: render, error: renderErr } = await supabase
          .from('zdocs_renders')
          .insert({
            company_id: companyId,
            template_id: body.template_id,
            entity_type: body.entity_type || 'general',
            entity_id: body.entity_id || null,
            title: body.title || `${template.name} - ${new Date().toLocaleDateString('en-US')}`,
            rendered_html: fullHtml,
            data_snapshot: variables,
            variables_used: variables,
            status: 'rendered',
            requires_signature: template.requires_signature || false,
            rendered_by_user_id: userId,
          })
          .select()
          .single();

        if (renderErr) throw renderErr;

        // Store rendered HTML as a file in Storage for PDF conversion
        const storagePath = `zdocs/${companyId}/${render.id}.html`;
        const htmlBlob = new Blob([fullHtml], { type: 'text/html' });
        await supabase.storage.from('documents').upload(storagePath, htmlBlob, {
          contentType: 'text/html',
          upsert: true,
        });

        // Update render with storage path
        await supabase.from('zdocs_renders').update({ pdf_storage_path: storagePath }).eq('id', render.id);

        return new Response(JSON.stringify({
          render_id: render.id,
          title: render.title,
          status: 'rendered',
          html_preview: fullHtml.substring(0, 500),
          storage_path: storagePath,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'send_for_signature': {
        if (!body.render_id || !body.signers || body.signers.length === 0) {
          return new Response(JSON.stringify({ error: 'render_id and signers required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        if (!companyId) {
          return new Response(JSON.stringify({ error: 'Authentication required' }), {
            status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Create signature requests for each signer
        const sigRequests = body.signers.map(s => ({
          company_id: companyId,
          render_id: body.render_id,
          signer_name: s.name,
          signer_email: s.email,
          signer_role: s.role || 'signer',
          status: 'sent',
          sent_at: new Date().toISOString(),
        }));

        const { data: sigs, error: sigErr } = await supabase
          .from('zdocs_signature_requests')
          .insert(sigRequests)
          .select();

        if (sigErr) throw sigErr;

        // Update render status
        await supabase.from('zdocs_renders').update({
          status: 'sent',
          signature_status: 'sent',
          signature_requested_at: new Date().toISOString(),
        }).eq('id', body.render_id);

        // In production: send email to each signer with their unique signing link
        // For now, return the access tokens (emails would be sent via sendgrid-email EF)

        return new Response(JSON.stringify({
          success: true,
          signature_requests: (sigs || []).map((s: Record<string, unknown>) => ({
            id: s.id,
            signer_name: s.signer_name,
            signer_email: s.signer_email,
            access_token: s.access_token,
            status: s.status,
          })),
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'verify_signature': {
        if (!body.access_token) {
          return new Response(JSON.stringify({ error: 'access_token required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Look up signature request by token
        const { data: sigReq, error: sigErr } = await supabase
          .from('zdocs_signature_requests')
          .select('*, zdocs_renders(title, rendered_html)')
          .eq('access_token', body.access_token)
          .single();

        if (sigErr || !sigReq) {
          return new Response(JSON.stringify({ error: 'Invalid or expired signature link' }), {
            status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        if (new Date(sigReq.expires_at) < new Date()) {
          await supabase.from('zdocs_signature_requests').update({ status: 'expired' }).eq('id', sigReq.id);
          return new Response(JSON.stringify({ error: 'Signature link has expired' }), {
            status: 410, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        if (sigReq.status === 'signed') {
          return new Response(JSON.stringify({ error: 'Document already signed' }), {
            status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        if (body.signature_image_base64) {
          // Process the signature
          const sigImagePath = `signatures/${sigReq.company_id}/${sigReq.id}.png`;

          // Decode base64 and upload
          const binaryString = atob(body.signature_image_base64);
          const bytes = new Uint8Array(binaryString.length);
          for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }
          await supabase.storage.from('documents').upload(sigImagePath, bytes, {
            contentType: 'image/png',
            upsert: true,
          });

          // Update signature request
          await supabase.from('zdocs_signature_requests').update({
            status: 'signed',
            signed_at: new Date().toISOString(),
            signature_image_path: sigImagePath,
            ip_address: req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || 'unknown',
            user_agent: req.headers.get('user-agent') || 'unknown',
          }).eq('id', sigReq.id);

          // Check if all signers have signed
          const { data: allSigs } = await supabase
            .from('zdocs_signature_requests')
            .select('status')
            .eq('render_id', sigReq.render_id)
            .eq('signer_role', 'signer');

          const allSigned = (allSigs || []).every((s: { status: string }) => s.status === 'signed');

          if (allSigned) {
            await supabase.from('zdocs_renders').update({
              status: 'signed',
              signature_status: 'signed',
              signed_at: new Date().toISOString(),
              signed_by_name: body.signer_name || sigReq.signer_name,
            }).eq('id', sigReq.render_id);
          }

          return new Response(JSON.stringify({
            success: true,
            all_signed: allSigned,
            status: 'signed',
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // If no signature provided, return document for viewing
        await supabase.from('zdocs_signature_requests').update({
          status: 'viewed',
          viewed_at: new Date().toISOString(),
        }).eq('id', sigReq.id);

        return new Response(JSON.stringify({
          document_title: sigReq.zdocs_renders?.title,
          document_html: sigReq.zdocs_renders?.rendered_html,
          signer_name: sigReq.signer_name,
          status: 'viewed',
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'get_system_templates': {
        // Return pre-built templates for common trade documents
        const systemTemplates = [
          {
            name: 'Professional Proposal',
            template_type: 'proposal',
            description: 'Clean proposal with scope of work, pricing, and terms',
            variables: [
              { name: 'customer_name', label: 'Customer Name', type: 'text' },
              { name: 'job_title', label: 'Project Title', type: 'text' },
              { name: 'scope_of_work', label: 'Scope of Work', type: 'textarea' },
              { name: 'estimate_total', label: 'Total Price', type: 'currency' },
              { name: 'valid_until', label: 'Valid Until', type: 'date' },
            ],
            content_html: `<h1 style="text-align:center;color:#10b981;">{{company_name}}</h1>
<p style="text-align:center;color:#666;">{{company_phone}} | {{company_email}} | {{company_website}}</p>
<hr/>
<h2>PROPOSAL</h2>
<p><strong>Prepared for:</strong> {{customer_name}}</p>
<p><strong>Project:</strong> {{job_title}}</p>
<p><strong>Date:</strong> {{current_date}}</p>
<h3>Scope of Work</h3>
<p>{{scope_of_work}}</p>
<h3>Pricing</h3>
{{line_items_table}}
<p style="text-align:right;font-size:16px;"><strong>Total: {{estimate_total}}</strong></p>
<h3>Terms & Conditions</h3>
<p>This proposal is valid until {{valid_until}}. A 50% deposit is required to begin work. Balance due upon completion.</p>
<div class="signature-block">
<p><strong>Accepted By:</strong></p>
<p>Signature: <span class="signature-line">&nbsp;</span></p>
<p>Name: <span class="signature-line">&nbsp;</span></p>
<p>Date: <span class="signature-line">&nbsp;</span></p>
</div>`,
          },
          {
            name: 'Service Contract',
            template_type: 'contract',
            description: 'Standard service agreement with scope, terms, and signatures',
            variables: [
              { name: 'customer_name', label: 'Customer Name', type: 'text' },
              { name: 'job_address', label: 'Job Address', type: 'text' },
              { name: 'job_total', label: 'Contract Amount', type: 'currency' },
            ],
            content_html: `<h1 style="text-align:center;">SERVICE AGREEMENT</h1>
<p style="text-align:center;">Between {{company_name}} ("Contractor") and {{customer_name}} ("Client")</p>
<hr/>
<p><strong>Date:</strong> {{current_date}}</p>
<p><strong>Project Location:</strong> {{job_address}}</p>
<p><strong>Contract Amount:</strong> {{job_total}}</p>
<h3>1. Scope of Work</h3>
<p>{{scope_of_work}}</p>
<h3>2. Payment Terms</h3>
<p>Payment schedule: 50% deposit upon signing, 50% upon completion. Late payments subject to 1.5% monthly interest.</p>
<h3>3. Timeline</h3>
<p>Work shall commence on {{start_date}} and be substantially complete by {{end_date}}, subject to weather and material delays.</p>
<h3>4. Warranty</h3>
<p>Contractor warrants all work for a period of one (1) year from date of completion.</p>
<h3>5. Insurance</h3>
<p>Contractor maintains general liability and workers' compensation insurance. License: {{company_license}}.</p>
<div style="display:flex;gap:48px;margin-top:48px;">
<div style="flex:1;"><p><strong>Contractor:</strong></p><p>{{company_name}}</p><p>Signature: <span class="signature-line">&nbsp;</span></p><p>Date: <span class="signature-line">&nbsp;</span></p></div>
<div style="flex:1;"><p><strong>Client:</strong></p><p>{{customer_name}}</p><p>Signature: <span class="signature-line">&nbsp;</span></p><p>Date: <span class="signature-line">&nbsp;</span></p></div>
</div>`,
          },
          {
            name: 'Lien Waiver (Conditional)',
            template_type: 'lien_waiver',
            description: 'Conditional waiver and release upon progress payment',
            variables: [
              { name: 'customer_name', label: 'Property Owner', type: 'text' },
              { name: 'job_address', label: 'Property Address', type: 'text' },
              { name: 'amount_paid', label: 'Payment Amount', type: 'currency' },
            ],
            content_html: `<h1 style="text-align:center;">CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p><strong>Project:</strong> {{job_address}}</p>
<p><strong>Owner:</strong> {{customer_name}}</p>
<p><strong>Claimant:</strong> {{company_name}}</p>
<p><strong>Payment Amount:</strong> {{amount_paid}}</p>
<p><strong>Date:</strong> {{current_date}}</p>
<hr/>
<p>Upon receipt of payment of {{amount_paid}} for labor, services, equipment, or material furnished through {{current_date}}, the undersigned waives and releases any mechanic's lien, stop payment notice, or bond right to the extent of said payment.</p>
<p>This waiver and release is conditioned upon the maker receiving actual payment of the amount stated. This waiver does not cover any retention or amounts unpaid.</p>
<div class="signature-block">
<p><strong>{{company_name}}</strong></p>
<p>By: <span class="signature-line">&nbsp;</span></p>
<p>Title: <span class="signature-line">&nbsp;</span></p>
<p>Date: <span class="signature-line">&nbsp;</span></p>
</div>`,
          },
          {
            name: 'Change Order',
            template_type: 'change_order',
            description: 'Formal change order document for project modifications',
            variables: [
              { name: 'co_number', label: 'CO Number', type: 'text' },
              { name: 'co_amount', label: 'CO Amount', type: 'currency' },
              { name: 'co_description', label: 'Description', type: 'textarea' },
            ],
            content_html: `<h1 style="text-align:center;">CHANGE ORDER</h1>
<table style="width:100%;margin:16px 0;">
<tr><td style="width:50%;"><strong>CO Number:</strong> {{co_number}}</td><td><strong>Date:</strong> {{current_date}}</td></tr>
<tr><td><strong>Project:</strong> {{job_title}}</td><td><strong>Location:</strong> {{job_address}}</td></tr>
<tr><td><strong>Contractor:</strong> {{company_name}}</td><td><strong>Owner:</strong> {{customer_name}}</td></tr>
</table>
<hr/>
<h3>Description of Change</h3>
<p>{{co_description}}</p>
<h3>Reason for Change</h3>
<p>{{co_reason}}</p>
<h3>Cost Impact</h3>
<p><strong>Change Order Amount:</strong> {{co_amount}}</p>
<p><em>This change order, when signed by both parties, becomes part of the original contract.</em></p>
<div style="display:flex;gap:48px;margin-top:48px;">
<div style="flex:1;"><p><strong>Contractor Approval:</strong></p><p>Signature: <span class="signature-line">&nbsp;</span></p><p>Date: <span class="signature-line">&nbsp;</span></p></div>
<div style="flex:1;"><p><strong>Owner Approval:</strong></p><p>Signature: <span class="signature-line">&nbsp;</span></p><p>Date: <span class="signature-line">&nbsp;</span></p></div>
</div>`,
          },
          {
            name: 'Daily Report',
            template_type: 'daily_report',
            description: 'Daily field report for construction projects',
            variables: [
              { name: 'job_title', label: 'Project', type: 'text' },
              { name: 'weather', label: 'Weather', type: 'text' },
              { name: 'work_performed', label: 'Work Performed', type: 'textarea' },
              { name: 'materials_used', label: 'Materials Used', type: 'textarea' },
              { name: 'crew_count', label: 'Crew Count', type: 'number' },
            ],
            content_html: `<h1>DAILY FIELD REPORT</h1>
<table style="width:100%;">
<tr><td><strong>Project:</strong> {{job_title}}</td><td><strong>Date:</strong> {{current_date}}</td></tr>
<tr><td><strong>Location:</strong> {{job_address}}</td><td><strong>Weather:</strong> {{weather}}</td></tr>
<tr><td><strong>Contractor:</strong> {{company_name}}</td><td><strong>Crew Size:</strong> {{crew_count}}</td></tr>
</table>
<hr/>
<h3>Work Performed Today</h3>
<p>{{work_performed}}</p>
<h3>Materials Used</h3>
<p>{{materials_used}}</p>
<h3>Issues / Delays</h3>
<p>{{issues}}</p>
<h3>Tomorrow's Plan</h3>
<p>{{tomorrows_plan}}</p>
<div class="signature-block">
<p><strong>Submitted by:</strong> <span class="signature-line">&nbsp;</span></p>
<p><strong>Date:</strong> {{current_date}}</p>
</div>`,
          },
        ];

        return new Response(JSON.stringify({ templates: systemTemplates }), {
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

// Helper: fetch entity variables for template substitution
async function fetchEntityVariables(
  supabase: ReturnType<typeof createClient>,
  entityType: string,
  entityId: string,
  companyId: string | null,
): Promise<Record<string, string>> {
  const variables: Record<string, string> = {};

  switch (entityType) {
    case 'job': {
      const { data: job } = await supabase.from('jobs').select('*').eq('id', entityId).single();
      if (job) {
        variables.job_title = job.title || '';
        variables.job_number = job.job_number || '';
        variables.job_status = job.status || '';
        variables.job_description = job.description || '';
        variables.job_address = job.address || '';
        variables.customer_name = job.customer_name || '';
        variables.customer_email = job.customer_email || '';
        variables.customer_phone = job.customer_phone || '';
        variables.start_date = job.start_date || '';
        variables.end_date = job.end_date || '';
        variables.job_total = job.total ? `$${Number(job.total).toFixed(2)}` : '';
      }
      break;
    }
    case 'estimate': {
      const { data: estimate } = await supabase.from('estimates').select('*').eq('id', entityId).single();
      if (estimate) {
        variables.estimate_number = estimate.estimate_number || '';
        variables.estimate_total = estimate.total ? `$${Number(estimate.total).toFixed(2)}` : '';
        variables.customer_name = estimate.customer_name || '';
        variables.property_address = estimate.property_address || '';
        variables.scope_summary = estimate.scope_summary || '';
      }
      break;
    }
    case 'invoice': {
      const { data: invoice } = await supabase.from('invoices').select('*').eq('id', entityId).single();
      if (invoice) {
        variables.invoice_number = invoice.invoice_number || '';
        variables.invoice_total = invoice.total ? `$${Number(invoice.total).toFixed(2)}` : '';
        variables.customer_name = invoice.customer_name || '';
        variables.due_date = invoice.due_date || '';
      }
      break;
    }
  }

  // Company data
  if (companyId) {
    const { data: company } = await supabase.from('companies').select('*').eq('id', companyId).single();
    if (company) {
      variables.company_name = company.name || '';
      variables.company_phone = company.phone || '';
      variables.company_email = company.email || '';
      variables.company_address = company.address || '';
      variables.company_license = company.license_number || '';
      variables.company_website = company.website || '';
    }
  }

  variables.current_date = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  variables.current_year = String(new Date().getFullYear());

  return variables;
}
