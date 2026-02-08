import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface SendEmailRequest {
  action: 'send' | 'send_template' | 'send_campaign' | 'webhook' | 'get_stats';
  // send action
  to_email?: string;
  to_name?: string;
  subject?: string;
  body_html?: string;
  body_text?: string;
  from_email?: string;
  from_name?: string;
  reply_to?: string;
  email_type?: string;
  related_type?: string;
  related_id?: string;
  // send_template action
  template_id?: string;
  variables?: Record<string, string>;
  // send_campaign action
  campaign_id?: string;
  // webhook action (SendGrid event webhook)
  events?: SendGridEvent[];
}

interface SendGridEvent {
  email: string;
  timestamp: number;
  event: string;
  sg_message_id?: string;
  category?: string[];
  url?: string;
  reason?: string;
  status?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const sendgridApiKey = Deno.env.get('SENDGRID_API_KEY');
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: SendEmailRequest = await req.json();
    const { action } = body;

    // Extract company_id from auth token
    const authHeader = req.headers.get('Authorization');
    let companyId: string | null = null;
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user } } = await supabase.auth.getUser(token);
      companyId = user?.app_metadata?.company_id || null;
    }

    switch (action) {
      case 'send': {
        if (!body.to_email || !body.subject) {
          return new Response(JSON.stringify({ error: 'to_email and subject required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const fromEmail = body.from_email || 'noreply@zafto.app';
        const fromName = body.from_name || 'ZAFTO';

        let sendgridMessageId: string | null = null;

        if (sendgridApiKey) {
          // Send via SendGrid
          const sgResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${sendgridApiKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              personalizations: [{
                to: [{ email: body.to_email, name: body.to_name }],
              }],
              from: { email: fromEmail, name: fromName },
              reply_to: body.reply_to ? { email: body.reply_to } : undefined,
              subject: body.subject,
              content: [
                ...(body.body_text ? [{ type: 'text/plain', value: body.body_text }] : []),
                ...(body.body_html ? [{ type: 'text/html', value: body.body_html }] : []),
              ],
            }),
          });

          sendgridMessageId = sgResponse.headers.get('X-Message-Id');

          if (!sgResponse.ok) {
            const errText = await sgResponse.text();
            // Log the send as failed
            if (companyId) {
              await supabase.from('email_sends').insert({
                company_id: companyId,
                to_email: body.to_email,
                to_name: body.to_name || null,
                from_email: fromEmail,
                from_name: fromName,
                subject: body.subject,
                body_preview: (body.body_text || body.body_html || '').substring(0, 200),
                email_type: body.email_type || 'transactional',
                related_type: body.related_type || null,
                related_id: body.related_id || null,
                status: 'failed',
                error_message: errText.substring(0, 500),
              });
            }
            return new Response(JSON.stringify({ error: 'SendGrid send failed', detail: errText }), {
              status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
          }
        }

        // Log the send
        if (companyId) {
          await supabase.from('email_sends').insert({
            company_id: companyId,
            to_email: body.to_email,
            to_name: body.to_name || null,
            from_email: fromEmail,
            from_name: fromName,
            reply_to: body.reply_to || null,
            subject: body.subject,
            body_preview: (body.body_text || body.body_html || '').substring(0, 200),
            email_type: body.email_type || 'transactional',
            related_type: body.related_type || null,
            related_id: body.related_id || null,
            sendgrid_message_id: sendgridMessageId,
            status: sendgridApiKey ? 'sent' : 'queued',
          });
        }

        return new Response(JSON.stringify({
          success: true,
          message_id: sendgridMessageId,
          status: sendgridApiKey ? 'sent' : 'queued',
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'send_template': {
        if (!body.template_id || !body.to_email) {
          return new Response(JSON.stringify({ error: 'template_id and to_email required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Fetch template
        const { data: template, error: tmplErr } = await supabase
          .from('email_templates')
          .select('*')
          .eq('id', body.template_id)
          .single();

        if (tmplErr || !template) {
          return new Response(JSON.stringify({ error: 'Template not found' }), {
            status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Replace variables in subject and body
        let subject = template.subject;
        let bodyHtml = template.body_html;
        const vars = body.variables || {};
        for (const [key, value] of Object.entries(vars)) {
          const pattern = new RegExp(`{{${key}}}`, 'g');
          subject = subject.replace(pattern, value);
          bodyHtml = bodyHtml.replace(pattern, value);
        }

        // Recursively send using the same function logic
        const fromEmail = 'noreply@zafto.app';
        const fromName = 'ZAFTO';
        let sendgridMsgId: string | null = null;

        if (sendgridApiKey) {
          const sgRes = await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${sendgridApiKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              personalizations: [{ to: [{ email: body.to_email, name: body.to_name }] }],
              from: { email: fromEmail, name: fromName },
              subject,
              content: [{ type: 'text/html', value: bodyHtml }],
            }),
          });
          sendgridMsgId = sgRes.headers.get('X-Message-Id');
        }

        if (companyId) {
          await supabase.from('email_sends').insert({
            company_id: companyId,
            template_id: body.template_id,
            to_email: body.to_email,
            to_name: body.to_name || null,
            from_email: fromEmail,
            from_name: fromName,
            subject,
            body_preview: bodyHtml.replace(/<[^>]+>/g, '').substring(0, 200),
            email_type: template.template_type,
            related_type: body.related_type || null,
            related_id: body.related_id || null,
            sendgrid_message_id: sendgridMsgId,
            status: sendgridApiKey ? 'sent' : 'queued',
          });
        }

        return new Response(JSON.stringify({ success: true, message_id: sendgridMsgId }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'webhook': {
        // SendGrid Event Webhook — updates email_sends with delivery/open/click/bounce status
        const events = body.events || [];
        for (const event of events) {
          if (!event.sg_message_id) continue;

          const updateFields: Record<string, unknown> = {};

          switch (event.event) {
            case 'delivered':
              updateFields.status = 'delivered';
              updateFields.delivered_at = new Date(event.timestamp * 1000).toISOString();
              break;
            case 'open':
              updateFields.status = 'opened';
              updateFields.opened_at = new Date(event.timestamp * 1000).toISOString();
              // Increment open count
              await supabase.rpc('increment_email_open_count', { msg_id: event.sg_message_id });
              break;
            case 'click':
              updateFields.status = 'clicked';
              updateFields.clicked_at = new Date(event.timestamp * 1000).toISOString();
              await supabase.rpc('increment_email_click_count', { msg_id: event.sg_message_id });
              break;
            case 'bounce':
            case 'blocked':
              updateFields.status = 'bounced';
              updateFields.bounced_at = new Date(event.timestamp * 1000).toISOString();
              updateFields.error_message = event.reason || event.status;
              break;
            case 'dropped':
              updateFields.status = 'dropped';
              updateFields.error_message = event.reason;
              break;
            case 'spamreport':
              updateFields.status = 'spam';
              break;
            case 'unsubscribe':
              updateFields.status = 'unsubscribed';
              // Add to unsubscribe list
              const { data: sendRecord } = await supabase
                .from('email_sends')
                .select('company_id')
                .eq('sendgrid_message_id', event.sg_message_id)
                .single();
              if (sendRecord) {
                await supabase.from('email_unsubscribes').upsert({
                  company_id: sendRecord.company_id,
                  email: event.email,
                  reason: 'unsubscribe_link',
                }, { onConflict: 'company_id,email' });
              }
              break;
          }

          if (Object.keys(updateFields).length > 0) {
            await supabase
              .from('email_sends')
              .update(updateFields)
              .eq('sendgrid_message_id', event.sg_message_id);
          }
        }

        return new Response(JSON.stringify({ processed: events.length }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'get_stats': {
        if (!companyId) {
          return new Response(JSON.stringify({ error: 'Authentication required' }), {
            status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Get email stats for the current month
        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);

        const { data: sends } = await supabase
          .from('email_sends')
          .select('status')
          .eq('company_id', companyId)
          .gte('created_at', startOfMonth.toISOString());

        const stats = {
          total: sends?.length || 0,
          sent: sends?.filter((s: { status: string }) => s.status === 'sent').length || 0,
          delivered: sends?.filter((s: { status: string }) => s.status === 'delivered').length || 0,
          opened: sends?.filter((s: { status: string }) => s.status === 'opened').length || 0,
          clicked: sends?.filter((s: { status: string }) => s.status === 'clicked').length || 0,
          bounced: sends?.filter((s: { status: string }) => s.status === 'bounced').length || 0,
          failed: sends?.filter((s: { status: string }) => s.status === 'failed').length || 0,
          deliveryRate: 0,
          openRate: 0,
        };

        if (stats.total > 0) {
          stats.deliveryRate = Math.round(((stats.delivered + stats.opened + stats.clicked) / stats.total) * 100);
          const delivered = stats.delivered + stats.opened + stats.clicked;
          stats.openRate = delivered > 0 ? Math.round(((stats.opened + stats.clicked) / delivered) * 100) : 0;
        }

        return new Response(JSON.stringify(stats), {
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
