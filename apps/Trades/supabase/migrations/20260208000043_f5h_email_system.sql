-- F5h: Email System tables
-- SendGrid integration, transactional + marketing emails, templates

-- Email Templates
CREATE TABLE email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  body_html TEXT NOT NULL,
  body_text TEXT,
  template_type TEXT NOT NULL DEFAULT 'transactional' CHECK (template_type IN ('transactional','marketing','system','custom')),
  trigger_event TEXT,  -- 'invoice_sent', 'job_complete', 'appointment_reminder', etc.
  variables JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{name, description, default_value}]
  is_active BOOLEAN DEFAULT true,
  sendgrid_template_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Email Sends — log of all sent emails
CREATE TABLE email_sends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  template_id UUID REFERENCES email_templates(id),
  -- Recipients
  to_email TEXT NOT NULL,
  to_name TEXT,
  from_email TEXT NOT NULL,
  from_name TEXT,
  reply_to TEXT,
  -- Content
  subject TEXT NOT NULL,
  body_preview TEXT,
  -- Metadata
  email_type TEXT NOT NULL DEFAULT 'transactional' CHECK (email_type IN ('transactional','marketing','system')),
  related_type TEXT,  -- 'invoice', 'job', 'customer', 'lead', 'appointment'
  related_id UUID,
  -- SendGrid
  sendgrid_message_id TEXT,
  -- Status
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('queued','sent','delivered','opened','clicked','bounced','dropped','spam','unsubscribed','failed')),
  sent_at TIMESTAMPTZ DEFAULT now(),
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  bounced_at TIMESTAMPTZ,
  -- Analytics
  open_count INTEGER DEFAULT 0,
  click_count INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Email Campaigns — marketing email batches
CREATE TABLE email_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  template_id UUID REFERENCES email_templates(id),
  subject TEXT NOT NULL,
  -- Audience
  audience_type TEXT DEFAULT 'all_customers' CHECK (audience_type IN ('all_customers','segment','manual','leads')),
  audience_filter JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {stage, source, tags, etc.}
  recipient_count INTEGER DEFAULT 0,
  -- Schedule
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','scheduled','sending','sent','cancelled')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  -- Analytics
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  total_bounced INTEGER DEFAULT 0,
  total_unsubscribed INTEGER DEFAULT 0,
  open_rate NUMERIC(5,2) DEFAULT 0,
  click_rate NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Email Unsubscribes
CREATE TABLE email_unsubscribes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  email TEXT NOT NULL,
  reason TEXT,
  unsubscribed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, email)
);

-- RLS
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_sends ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_unsubscribes ENABLE ROW LEVEL SECURITY;

CREATE POLICY email_templates_company ON email_templates FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY email_sends_company ON email_sends FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY email_campaigns_company ON email_campaigns FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY email_unsub_company ON email_unsubscribes FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_email_templates_company ON email_templates(company_id);
CREATE INDEX idx_email_templates_trigger ON email_templates(trigger_event) WHERE trigger_event IS NOT NULL;
CREATE INDEX idx_email_sends_company ON email_sends(company_id, sent_at);
CREATE INDEX idx_email_sends_related ON email_sends(related_type, related_id);
CREATE INDEX idx_email_sends_status ON email_sends(status);
CREATE INDEX idx_email_campaigns_company ON email_campaigns(company_id);
CREATE INDEX idx_email_unsub_company ON email_unsubscribes(company_id, email);

-- Triggers
CREATE TRIGGER email_templates_updated BEFORE UPDATE ON email_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER email_campaigns_updated BEFORE UPDATE ON email_campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();
