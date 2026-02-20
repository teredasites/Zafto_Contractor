'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
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

// --- Hook ---

export function useEmail() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [sends, setSends] = useState<EmailSend[]>([]);
  const [campaigns, setCampaigns] = useState<EmailCampaign[]>([]);
  const [unsubscribes, setUnsubscribes] = useState<EmailUnsubscribe[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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

      setTemplates((templatesRes.data || []).map(mapTemplate));
      setSends((sendsRes.data || []).map(mapSend));
      setCampaigns((campaignsRes.data || []).map(mapCampaign));
      setUnsubscribes((unsubRes.data || []).map(mapUnsubscribe));
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

    return () => {
      supabase.removeChannel(channel);
    };
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

    const defaults = [
      {
        name: 'Invoice Sent',
        subject: 'Invoice #{{invoice_number}} from {{company_name}}',
        body_html: '<p>Hi {{customer_name}},</p><p>Please find your invoice <strong>#{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong>.</p><p>Due date: {{due_date}}</p><p>If you have any questions, please don\'t hesitate to reach out.</p><p>Thank you for your business,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nPlease find your invoice #{{invoice_number}} for {{invoice_total}}.\n\nDue date: {{due_date}}\n\nThank you for your business,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'invoice_sent',
        variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Total amount' }, { name: 'due_date', description: 'Payment due date' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Estimate Sent',
        subject: 'Estimate from {{company_name}} — {{job_title}}',
        body_html: '<p>Hi {{customer_name}},</p><p>Thank you for the opportunity. Please review the attached estimate for <strong>{{job_title}}</strong>.</p><p>Estimated total: <strong>{{estimate_total}}</strong></p><p>This estimate is valid for 30 days. Let us know if you\'d like to proceed or have any questions.</p><p>Best regards,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nPlease review the attached estimate for {{job_title}}.\n\nEstimated total: {{estimate_total}}\n\nThis estimate is valid for 30 days.\n\nBest regards,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'estimate_sent',
        variables: [{ name: 'job_title', description: 'Job/project title' }, { name: 'estimate_total', description: 'Estimate total' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Payment Received',
        subject: 'Payment Confirmed — Thank You!',
        body_html: '<p>Hi {{customer_name}},</p><p>We\'ve received your payment of <strong>{{payment_amount}}</strong> for invoice #{{invoice_number}}.</p><p>Thank you for your prompt payment. A receipt is attached for your records.</p><p>Best,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nWe\'ve received your payment of {{payment_amount}} for invoice #{{invoice_number}}.\n\nThank you for your prompt payment.\n\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'payment_received',
        variables: [{ name: 'payment_amount', description: 'Amount paid' }, { name: 'invoice_number', description: 'Invoice number' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Payment Reminder',
        subject: 'Friendly Reminder — Invoice #{{invoice_number}} Due {{due_date}}',
        body_html: '<p>Hi {{customer_name}},</p><p>This is a friendly reminder that invoice <strong>#{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong> is due on <strong>{{due_date}}</strong>.</p><p>If you\'ve already sent payment, please disregard this message.</p><p>Thank you,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nThis is a friendly reminder that invoice #{{invoice_number}} for {{invoice_total}} is due on {{due_date}}.\n\nIf you\'ve already sent payment, please disregard this message.\n\nThank you,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'payment_reminder',
        variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Total amount' }, { name: 'due_date', description: 'Payment due date' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Appointment Confirmation',
        subject: 'Appointment Confirmed — {{appointment_date}}',
        body_html: '<p>Hi {{customer_name}},</p><p>Your appointment has been confirmed:</p><ul><li><strong>Date:</strong> {{appointment_date}}</li><li><strong>Time:</strong> {{appointment_time}}</li><li><strong>Service:</strong> {{service_type}}</li><li><strong>Address:</strong> {{address}}</li></ul><p>Our team will arrive on time. If you need to reschedule, please contact us at least 24 hours in advance.</p><p>See you soon,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nYour appointment has been confirmed:\n\nDate: {{appointment_date}}\nTime: {{appointment_time}}\nService: {{service_type}}\nAddress: {{address}}\n\nSee you soon,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'appointment_confirmed',
        variables: [{ name: 'appointment_date', description: 'Appointment date' }, { name: 'appointment_time', description: 'Appointment time' }, { name: 'service_type', description: 'Type of service' }, { name: 'address', description: 'Job address' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Job Complete',
        subject: 'Job Complete — {{job_title}}',
        body_html: '<p>Hi {{customer_name}},</p><p>Great news — the work on <strong>{{job_title}}</strong> at {{address}} is now <strong>complete</strong>.</p><p>If you have any questions or notice anything that needs attention, please don\'t hesitate to reach out.</p><p>We\'d love to hear about your experience. If you have a moment, a review would mean a lot to our team.</p><p>Thank you for choosing us,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nThe work on {{job_title}} at {{address}} is now complete.\n\nIf you have any questions, please reach out.\n\nThank you for choosing us,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'job_complete',
        variables: [{ name: 'job_title', description: 'Job/project title' }, { name: 'address', description: 'Job address' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Follow-Up',
        subject: 'Following up on your {{service_type}} inquiry',
        body_html: '<p>Hi {{customer_name}},</p><p>Thank you for reaching out about {{service_type}}. We wanted to follow up and see if you had any questions about the estimate we provided.</p><p>We\'d love the opportunity to earn your business. If there\'s anything we can clarify or if you\'d like to schedule the work, just reply to this email.</p><p>Best,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nThank you for reaching out about {{service_type}}. We wanted to follow up on the estimate we provided.\n\nBest,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'follow_up',
        variables: [{ name: 'service_type', description: 'Service discussed' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Contract Sent',
        subject: 'Contract for {{job_title}} — Please Review & Sign',
        body_html: '<p>Hi {{customer_name}},</p><p>Attached is the contract for <strong>{{job_title}}</strong>. Please review the terms and sign at your earliest convenience.</p><p><strong>Key details:</strong></p><ul><li>Project: {{job_title}}</li><li>Total: {{contract_total}}</li><li>Start date: {{start_date}}</li></ul><p>If you have any questions about the terms, we\'re happy to discuss.</p><p>Thank you,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nAttached is the contract for {{job_title}}. Please review and sign.\n\nProject: {{job_title}}\nTotal: {{contract_total}}\nStart date: {{start_date}}\n\nThank you,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'contract_sent',
        variables: [{ name: 'job_title', description: 'Job/project title' }, { name: 'contract_total', description: 'Contract amount' }, { name: 'start_date', description: 'Projected start date' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Overdue Invoice Notice',
        subject: 'Past Due — Invoice #{{invoice_number}}',
        body_html: '<p>Hi {{customer_name}},</p><p>Our records show that invoice <strong>#{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong> was due on <strong>{{due_date}}</strong> and remains unpaid.</p><p>Current balance: <strong>{{balance_due}}</strong></p><p>Please arrange payment at your earliest convenience. If you\'ve already sent payment, please disregard this notice.</p><p>If you have questions about this invoice, please contact us directly.</p><p>Regards,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nInvoice #{{invoice_number}} for {{invoice_total}} was due on {{due_date}} and remains unpaid.\n\nCurrent balance: {{balance_due}}\n\nPlease arrange payment at your earliest convenience.\n\nRegards,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'invoice_overdue',
        variables: [{ name: 'invoice_number', description: 'Invoice number' }, { name: 'invoice_total', description: 'Invoice total' }, { name: 'due_date', description: 'Original due date' }, { name: 'balance_due', description: 'Amount still owed' }, { name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
      {
        name: 'Welcome New Customer',
        subject: 'Welcome to {{company_name}}!',
        body_html: '<p>Hi {{customer_name}},</p><p>Welcome to <strong>{{company_name}}</strong>! We\'re excited to work with you.</p><p>Here\'s what you can expect from us:</p><ul><li>Professional, on-time service</li><li>Clear communication at every step</li><li>Quality workmanship with a satisfaction guarantee</li></ul><p>If you ever have questions or need assistance, don\'t hesitate to reach out.</p><p>Looking forward to working together,<br/>{{company_name}}</p>',
        body_text: 'Hi {{customer_name}},\n\nWelcome to {{company_name}}! We\'re excited to work with you.\n\nLooking forward to working together,\n{{company_name}}',
        template_type: 'transactional',
        trigger_event: 'customer_created',
        variables: [{ name: 'customer_name', description: 'Customer full name' }, { name: 'company_name', description: 'Your company name' }],
      },
    ];

    const rows = defaults.map((t) => ({ ...t, company_id: companyId }));
    const { error: err } = await supabase.from('email_templates').insert(rows);
    if (err) throw err;
    await fetchAll();
    return defaults.length;
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
