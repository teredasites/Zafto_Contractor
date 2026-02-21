'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';

// --- Types ---

export interface TemplateVariable {
  name: string;
  description: string;
  default_value?: string;
}

export interface EmailTemplate {
  id: string;
  companyId: string;
  name: string;
  subject: string;
  bodyHtml: string;
  bodyText: string;
  templateType: 'transactional' | 'marketing' | 'system' | 'custom';
  triggerEvent: string | null;
  variables: TemplateVariable[];
  isActive: boolean;
  sendgridTemplateId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface EmailSend {
  id: string;
  companyId: string;
  templateId: string | null;
  toEmail: string;
  toName: string | null;
  fromEmail: string | null;
  fromName: string | null;
  replyTo: string | null;
  subject: string;
  bodyPreview: string | null;
  emailType: 'transactional' | 'marketing' | 'system';
  relatedType: string | null;
  relatedId: string | null;
  sendgridMessageId: string | null;
  status: string;
  sentAt: Date | null;
  deliveredAt: Date | null;
  openedAt: Date | null;
  clickedAt: Date | null;
  bouncedAt: Date | null;
  openCount: number;
  clickCount: number;
  errorMessage: string | null;
  createdAt: Date;
}

export interface EmailCampaign {
  id: string;
  companyId: string;
  name: string;
  templateId: string | null;
  subject: string;
  audienceType: 'all_customers' | 'segment' | 'manual' | 'leads';
  audienceFilter: Record<string, unknown> | null;
  recipientCount: number;
  status: 'draft' | 'scheduled' | 'sending' | 'sent' | 'cancelled';
  scheduledAt: Date | null;
  sentAt: Date | null;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalBounced: number;
  totalUnsubscribed: number;
  openRate: number;
  clickRate: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface EmailUnsubscribe {
  id: string;
  companyId: string;
  email: string;
  reason: string | null;
  unsubscribedAt: Date;
}

// --- Mappers ---

function mapTemplate(row: Record<string, unknown>): EmailTemplate {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: (row.name as string) || '',
    subject: (row.subject as string) || '',
    bodyHtml: (row.body_html as string) || '',
    bodyText: (row.body_text as string) || '',
    templateType: (row.template_type as EmailTemplate['templateType']) || 'custom',
    triggerEvent: (row.trigger_event as string) || null,
    variables: (row.variables as TemplateVariable[]) || [],
    isActive: row.is_active as boolean ?? true,
    sendgridTemplateId: (row.sendgrid_template_id as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

function mapSend(row: Record<string, unknown>): EmailSend {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    templateId: (row.template_id as string) || null,
    toEmail: (row.to_email as string) || '',
    toName: (row.to_name as string) || null,
    fromEmail: (row.from_email as string) || null,
    fromName: (row.from_name as string) || null,
    replyTo: (row.reply_to as string) || null,
    subject: (row.subject as string) || '',
    bodyPreview: (row.body_preview as string) || null,
    emailType: (row.email_type as EmailSend['emailType']) || 'transactional',
    relatedType: (row.related_type as string) || null,
    relatedId: (row.related_id as string) || null,
    sendgridMessageId: (row.sendgrid_message_id as string) || null,
    status: (row.status as string) || 'queued',
    sentAt: row.sent_at ? new Date(row.sent_at as string) : null,
    deliveredAt: row.delivered_at ? new Date(row.delivered_at as string) : null,
    openedAt: row.opened_at ? new Date(row.opened_at as string) : null,
    clickedAt: row.clicked_at ? new Date(row.clicked_at as string) : null,
    bouncedAt: row.bounced_at ? new Date(row.bounced_at as string) : null,
    openCount: Number(row.open_count || 0),
    clickCount: Number(row.click_count || 0),
    errorMessage: (row.error_message as string) || null,
    createdAt: new Date(row.created_at as string),
  };
}

function mapCampaign(row: Record<string, unknown>): EmailCampaign {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: (row.name as string) || '',
    templateId: (row.template_id as string) || null,
    subject: (row.subject as string) || '',
    audienceType: (row.audience_type as EmailCampaign['audienceType']) || 'all_customers',
    audienceFilter: (row.audience_filter as Record<string, unknown>) || null,
    recipientCount: Number(row.recipient_count || 0),
    status: (row.status as EmailCampaign['status']) || 'draft',
    scheduledAt: row.scheduled_at ? new Date(row.scheduled_at as string) : null,
    sentAt: row.sent_at ? new Date(row.sent_at as string) : null,
    totalSent: Number(row.total_sent || 0),
    totalDelivered: Number(row.total_delivered || 0),
    totalOpened: Number(row.total_opened || 0),
    totalClicked: Number(row.total_clicked || 0),
    totalBounced: Number(row.total_bounced || 0),
    totalUnsubscribed: Number(row.total_unsubscribed || 0),
    openRate: Number(row.open_rate || 0),
    clickRate: Number(row.click_rate || 0),
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

function mapUnsubscribe(row: Record<string, unknown>): EmailUnsubscribe {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    email: (row.email as string) || '',
    reason: (row.reason as string) || null,
    unsubscribedAt: new Date(row.unsubscribed_at as string),
  };
}

// --- Default template seed data ---
function getDefaultTemplateRows(companyId: string) {
  return [
    { company_id: companyId, name: 'Invoice Sent', subject: 'Invoice #{{invoice_number}} from {{company_name}}', body_html: '<p>Hi {{customer_name}},</p><p>Please find your invoice <strong>#{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong>.</p><p>Due date: {{due_date}}</p><p>Thank you for your business,<br/>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nInvoice #{{invoice_number}} for {{invoice_total}}.\nDue: {{due_date}}\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'invoice_sent', variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Total amount' }, { name: 'due_date', description: 'Payment due date' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }] },
    { company_id: companyId, name: 'Estimate Sent', subject: 'Estimate from {{company_name}} — {{job_title}}', body_html: '<p>Hi {{customer_name}},</p><p>Please review the estimate for <strong>{{job_title}}</strong>.</p><p>Estimated total: <strong>{{estimate_total}}</strong></p><p>Valid for 30 days.</p><p>Best regards,<br/>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nEstimate for {{job_title}}: {{estimate_total}}\nValid 30 days.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'estimate_sent', variables: [{ name: 'job_title', description: 'Job/project title' }, { name: 'estimate_total', description: 'Estimate total' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }] },
    { company_id: companyId, name: 'Payment Received', subject: 'Payment Confirmed — Thank You!', body_html: '<p>Hi {{customer_name}},</p><p>We\'ve received your payment of <strong>{{payment_amount}}</strong> for invoice #{{invoice_number}}.</p><p>Thank you!</p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nPayment of {{payment_amount}} received for #{{invoice_number}}.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'payment_received', variables: [{ name: 'payment_amount', description: 'Amount paid' }, { name: 'invoice_number', description: 'Invoice number' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }] },
    { company_id: companyId, name: 'Payment Reminder', subject: 'Friendly Reminder — Invoice #{{invoice_number}} Due {{due_date}}', body_html: '<p>Hi {{customer_name}},</p><p>Reminder: invoice <strong>#{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong> is due <strong>{{due_date}}</strong>.</p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nReminder: #{{invoice_number}} ({{invoice_total}}) due {{due_date}}.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'payment_reminder', variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Total amount' }, { name: 'due_date', description: 'Due date' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }] },
    { company_id: companyId, name: 'Appointment Confirmation', subject: 'Appointment Confirmed — {{appointment_date}}', body_html: '<p>Hi {{customer_name}},</p><p>Confirmed:</p><ul><li>Date: {{appointment_date}}</li><li>Time: {{appointment_time}}</li><li>Service: {{service_type}}</li><li>Address: {{address}}</li></ul><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nConfirmed: {{appointment_date}} {{appointment_time}}\nService: {{service_type}}\nAt: {{address}}\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'appointment_confirmed', variables: [{ name: 'appointment_date', description: 'Date' }, { name: 'appointment_time', description: 'Time' }, { name: 'service_type', description: 'Service type' }, { name: 'address', description: 'Address' }, { name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
    { company_id: companyId, name: 'Job Complete', subject: 'Job Complete — {{job_title}}', body_html: '<p>Hi {{customer_name}},</p><p><strong>{{job_title}}</strong> at {{address}} is complete.</p><p>Questions? Reach out anytime.</p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\n{{job_title}} at {{address}} is complete.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'job_complete', variables: [{ name: 'job_title', description: 'Job title' }, { name: 'address', description: 'Address' }, { name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
    { company_id: companyId, name: 'Follow-Up', subject: 'Following up on your {{service_type}} inquiry', body_html: '<p>Hi {{customer_name}},</p><p>Following up about {{service_type}}. Any questions about the estimate?</p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nFollowing up on {{service_type}}.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'follow_up', variables: [{ name: 'service_type', description: 'Service type' }, { name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
    { company_id: companyId, name: 'Contract Sent', subject: 'Contract for {{job_title}} — Please Review & Sign', body_html: '<p>Hi {{customer_name}},</p><p>Contract for <strong>{{job_title}}</strong>:</p><ul><li>Total: {{contract_total}}</li><li>Start: {{start_date}}</li></ul><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nContract for {{job_title}}: {{contract_total}}, starting {{start_date}}.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'contract_sent', variables: [{ name: 'job_title', description: 'Job title' }, { name: 'contract_total', description: 'Amount' }, { name: 'start_date', description: 'Start date' }, { name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
    { company_id: companyId, name: 'Overdue Invoice Notice', subject: 'Past Due — Invoice #{{invoice_number}}', body_html: '<p>Hi {{customer_name}},</p><p>Invoice <strong>#{{invoice_number}}</strong> ({{invoice_total}}) was due {{due_date}}.</p><p>Balance: <strong>{{balance_due}}</strong></p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\n#{{invoice_number}} ({{invoice_total}}) due {{due_date}}. Balance: {{balance_due}}.\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'invoice_overdue', variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Total' }, { name: 'due_date', description: 'Due date' }, { name: 'balance_due', description: 'Balance' }, { name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
    { company_id: companyId, name: 'Welcome New Customer', subject: 'Welcome to {{company_name}}!', body_html: '<p>Hi {{customer_name}},</p><p>Welcome to <strong>{{company_name}}</strong>!</p><p>Professional service, clear communication, quality workmanship.</p><p>{{company_name}}</p>', body_text: 'Hi {{customer_name}},\n\nWelcome to {{company_name}}!\n\n{{company_name}}', template_type: 'transactional', trigger_event: 'customer_created', variables: [{ name: 'customer_name', description: 'Customer name' }, { name: 'company_name', description: 'Company name' }] },
  ];
}

// --- Hook ---

export function useEmail() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [sends, setSends] = useState<EmailSend[]>([]);
  const [campaigns, setCampaigns] = useState<EmailCampaign[]>([]);
  const [unsubscribes, setUnsubscribes] = useState<EmailUnsubscribe[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const autoSeedRef = useRef(false);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [templatesRes, sendsRes, campaignsRes, unsubRes] = await Promise.all([
        supabase
          .from('email_templates')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('email_sends')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(100),
        supabase
          .from('email_campaigns')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('email_unsubscribes')
          .select('*')
          .order('unsubscribed_at', { ascending: false }),
      ]);

      if (templatesRes.error) throw templatesRes.error;
      if (sendsRes.error) throw sendsRes.error;
      if (campaignsRes.error) throw campaignsRes.error;
      if (unsubRes.error) throw unsubRes.error;

      const templateData = (templatesRes.data || []).map(mapTemplate);
      setTemplates(templateData);
      setSends((sendsRes.data || []).map(mapSend));
      setCampaigns((campaignsRes.data || []).map(mapCampaign));
      setUnsubscribes((unsubRes.data || []).map(mapUnsubscribe));

      // Auto-seed default templates if company has none (first-time setup)
      if (templateData.length === 0 && !autoSeedRef.current) {
        autoSeedRef.current = true; // prevent re-seed on refetch
        const { data: { user } } = await supabase.auth.getUser();
        if (user?.app_metadata?.company_id) {
          const companyId = user.app_metadata.company_id;
          const { count } = await supabase
            .from('email_templates')
            .select('id', { count: 'exact', head: true })
            .eq('company_id', companyId);
          // Double-check server (another tab may have seeded)
          if ((count || 0) === 0) {
            const seedRows = getDefaultTemplateRows(companyId);
            await supabase.from('email_templates').insert(seedRows);
            // Re-fetch to pick up seeded templates
            const { data: seeded } = await supabase
              .from('email_templates')
              .select('*')
              .order('created_at', { ascending: false });
            if (seeded) setTemplates(seeded.map(mapTemplate));
          }
        }
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load email data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('email-sends-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'email_sends' }, () => {
        fetchAll();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAll]);

  // --- Mutations ---

  const createTemplate = async (input: {
    name: string;
    subject: string;
    bodyHtml: string;
    bodyText: string;
    templateType: EmailTemplate['templateType'];
    triggerEvent?: string;
    variables?: TemplateVariable[];
    isActive?: boolean;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('email_templates')
      .insert({
        company_id: companyId,
        name: input.name,
        subject: input.subject,
        body_html: input.bodyHtml,
        body_text: input.bodyText,
        template_type: input.templateType,
        trigger_event: input.triggerEvent || null,
        variables: input.variables || [],
        is_active: input.isActive ?? true,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const updateTemplate = async (id: string, data: Partial<{
    name: string;
    subject: string;
    bodyHtml: string;
    bodyText: string;
    templateType: EmailTemplate['templateType'];
    triggerEvent: string | null;
    variables: TemplateVariable[];
    isActive: boolean;
  }>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.subject !== undefined) updateData.subject = data.subject;
    if (data.bodyHtml !== undefined) updateData.body_html = data.bodyHtml;
    if (data.bodyText !== undefined) updateData.body_text = data.bodyText;
    if (data.templateType !== undefined) updateData.template_type = data.templateType;
    if (data.triggerEvent !== undefined) updateData.trigger_event = data.triggerEvent;
    if (data.variables !== undefined) updateData.variables = data.variables;
    if (data.isActive !== undefined) updateData.is_active = data.isActive;

    const { error: err } = await supabase.from('email_templates').update(updateData).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('email_templates').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const createCampaign = async (input: {
    name: string;
    templateId?: string;
    subject: string;
    audienceType: EmailCampaign['audienceType'];
    audienceFilter?: Record<string, unknown>;
    recipientCount?: number;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('email_campaigns')
      .insert({
        company_id: companyId,
        name: input.name,
        template_id: input.templateId || null,
        subject: input.subject,
        audience_type: input.audienceType,
        audience_filter: input.audienceFilter || null,
        recipient_count: input.recipientCount || 0,
        status: 'draft',
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const updateCampaign = async (id: string, data: Partial<{
    name: string;
    templateId: string | null;
    subject: string;
    audienceType: EmailCampaign['audienceType'];
    audienceFilter: Record<string, unknown> | null;
    recipientCount: number;
    status: EmailCampaign['status'];
  }>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.templateId !== undefined) updateData.template_id = data.templateId;
    if (data.subject !== undefined) updateData.subject = data.subject;
    if (data.audienceType !== undefined) updateData.audience_type = data.audienceType;
    if (data.audienceFilter !== undefined) updateData.audience_filter = data.audienceFilter;
    if (data.recipientCount !== undefined) updateData.recipient_count = data.recipientCount;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase.from('email_campaigns').update(updateData).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const scheduleCampaign = async (id: string, scheduledAt: Date) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('email_campaigns')
      .update({
        status: 'scheduled',
        scheduled_at: scheduledAt.toISOString(),
      })
      .eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  // --- Computed ---

  const activeTemplates = useMemo(
    () => templates.filter((t) => t.isActive),
    [templates]
  );

  const totalSent = useMemo(() => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    return sends.filter((s) => s.createdAt >= monthStart).length;
  }, [sends]);

  const deliveryRate = useMemo(() => {
    const delivered = sends.filter((s) => s.status === 'delivered' || s.status === 'opened' || s.status === 'clicked').length;
    return sends.length > 0 ? Math.round((delivered / sends.length) * 100) : 0;
  }, [sends]);

  const openRate = useMemo(() => {
    const withRates = campaigns.filter((c) => c.openRate > 0);
    if (withRates.length === 0) return 0;
    const avg = withRates.reduce((sum, c) => sum + c.openRate, 0) / withRates.length;
    return Math.round(avg * 100) / 100;
  }, [campaigns]);

  const bouncedCount = useMemo(
    () => sends.filter((s) => s.status === 'bounced').length,
    [sends]
  );

  const seedDefaultTemplates = async (): Promise<number> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const rows = getDefaultTemplateRows(companyId);
    const { error: err } = await supabase.from('email_templates').insert(rows);
    if (err) throw err;
    await fetchAll();
    return rows.length;
  };

  return {
    templates,
    sends,
    campaigns,
    unsubscribes,
    loading,
    error,
    // Mutations
    createTemplate,
    updateTemplate,
    deleteTemplate,
    createCampaign,
    updateCampaign,
    scheduleCampaign,
    seedDefaultTemplates,
    // Computed
    activeTemplates,
    totalSent,
    deliveryRate,
    openRate,
    bouncedCount,
    // Refetch
    refetch: fetchAll,
  };
}
