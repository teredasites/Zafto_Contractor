-- F5a: Lead Aggregation System
-- Extends leads table + adds source configurations + lead routing rules + lead analytics

-- Add new lead sources to the CHECK constraint
ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_source_check;
ALTER TABLE leads ADD CONSTRAINT leads_source_check CHECK (
  source IN (
    'website', 'referral', 'google', 'yelp', 'facebook', 'instagram', 'nextdoor',
    'homeadvisor', 'other',
    -- New aggregated sources
    'google_business', 'google_lsa', 'meta_business', 'buildzoom', 'angi',
    'thumbtack', 'porch', 'bark', 'houzz', 'angies_list',
    'manual', 'phone_call', 'walk_in', 'email_inbound'
  )
);

-- Add new columns to leads for aggregation metadata
ALTER TABLE leads ADD COLUMN IF NOT EXISTS external_id TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS external_source_data JSONB DEFAULT '{}'::jsonb;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS trade TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('low','normal','high','emergency'));
ALTER TABLE leads ADD COLUMN IF NOT EXISTS auto_assigned BOOLEAN DEFAULT false;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS response_time_minutes INTEGER;

-- Lead Source Configurations — API credentials + sync settings per source
CREATE TABLE lead_source_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  source TEXT NOT NULL,
  display_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  api_key_encrypted TEXT,
  api_secret_encrypted TEXT,
  webhook_url TEXT,
  sync_interval_minutes INTEGER DEFAULT 60,
  last_synced_at TIMESTAMPTZ,
  config JSONB NOT NULL DEFAULT '{}'::jsonb,  -- source-specific settings (location_id, business_id, etc.)
  stats JSONB NOT NULL DEFAULT '{}'::jsonb,   -- cached performance stats
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, source)
);

-- Lead Assignment Rules — auto-routing based on trade/area/availability
CREATE TABLE lead_assignment_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  -- Conditions (all must match)
  condition_source TEXT[],        -- match any of these sources
  condition_trade TEXT[],         -- match any of these trades
  condition_zip_codes TEXT[],     -- match any of these zip codes
  condition_urgency TEXT[],       -- match any of these urgency levels
  condition_value_min NUMERIC(12,2),
  condition_value_max NUMERIC(12,2),
  -- Actions
  assign_to_user_id UUID REFERENCES auth.users(id),
  assign_to_round_robin BOOLEAN DEFAULT false,
  round_robin_user_ids UUID[],
  set_stage TEXT,
  send_notification BOOLEAN DEFAULT true,
  notification_channels TEXT[] DEFAULT ARRAY['push','email'],
  auto_respond BOOLEAN DEFAULT false,
  auto_respond_template_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Lead Notifications — track notifications sent per lead
CREATE TABLE lead_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  channel TEXT NOT NULL CHECK (channel IN ('push','sms','email','in_app')),
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent','delivered','read','failed')),
  sent_at TIMESTAMPTZ DEFAULT now(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Lead Analytics Events — track conversion funnel
CREATE TABLE lead_analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('received','viewed','contacted','qualified','proposal_sent','won','lost','response_time')),
  source TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE lead_source_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_assignment_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY lead_configs_company ON lead_source_configs FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY lead_rules_company ON lead_assignment_rules FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY lead_notifs_company ON lead_notifications FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY lead_analytics_company ON lead_analytics_events FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_lead_configs_company ON lead_source_configs(company_id);
CREATE INDEX idx_lead_rules_company ON lead_assignment_rules(company_id, priority);
CREATE INDEX idx_lead_notifs_lead ON lead_notifications(lead_id);
CREATE INDEX idx_lead_analytics_company ON lead_analytics_events(company_id, event_type);
CREATE INDEX idx_lead_analytics_source ON lead_analytics_events(source, event_type);
CREATE INDEX idx_leads_external ON leads(external_id) WHERE external_id IS NOT NULL;
CREATE INDEX idx_leads_source ON leads(company_id, source);

-- Triggers
CREATE TRIGGER lead_configs_updated BEFORE UPDATE ON lead_source_configs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER lead_rules_updated BEFORE UPDATE ON lead_assignment_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at();
