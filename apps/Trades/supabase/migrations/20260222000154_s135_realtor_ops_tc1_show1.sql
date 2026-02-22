-- ============================================================
-- S135-ENTITY: Realtor Operations — TC1 + SHOW1
-- Migration 000154
--
-- TC1: Transaction Coordinator Module
--   transaction_templates   (template library with step blueprints)
--   transaction_checklists  (per-transaction checklist instances)
--   transaction_steps       (individual steps within checklists)
--   8 seeded templates: buyer, seller, dual, new construction,
--     commercial, short sale, REO, lease/rental
--
-- SHOW1: Showing Management & Feedback
--   showings               (individual showing appointments)
--   showing_feedback       (buyer feedback per showing)
-- ============================================================

-- ============================================================
-- 1. TRANSACTION TEMPLATES — reusable checklist blueprints
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  description TEXT,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN (
    'buyer_residential','seller_residential','dual_agency',
    'new_construction','commercial','short_sale','reo_foreclosure',
    'lease_rental','1031_exchange','land','condo','co_op','other'
  )),
  state TEXT,                        -- state-specific template variant
  steps JSONB NOT NULL DEFAULT '[]', -- blueprint: [{step_number, name, description, category, responsible_party, due_relative_days, due_relative_to, document_required, auto_action}]
  step_count INTEGER NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,  -- system-provided defaults
  is_active BOOLEAN NOT NULL DEFAULT true,

  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_tt_company ON transaction_templates(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tt_type ON transaction_templates(transaction_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_tt_default ON transaction_templates(is_default) WHERE is_default = true AND deleted_at IS NULL;

ALTER TABLE transaction_templates ENABLE ROW LEVEL SECURITY;

-- System defaults (company_id IS NULL) readable by all; company templates by company
CREATE POLICY tt_select ON transaction_templates FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL AND (
      company_id IS NULL  -- system defaults
      OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );
CREATE POLICY tt_insert ON transaction_templates FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY tt_update ON transaction_templates FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY tt_delete ON transaction_templates FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('transaction_templates');
CREATE TRIGGER tt_audit AFTER INSERT OR UPDATE OR DELETE ON transaction_templates
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 2. TRANSACTION CHECKLISTS — per-transaction instance
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Transaction reference
  template_id UUID REFERENCES transaction_templates(id) ON DELETE SET NULL,
  checklist_name TEXT NOT NULL,
  transaction_type TEXT NOT NULL,

  -- Property/deal reference
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,  -- buyer or seller

  -- Address (denormalized for quick display)
  property_address TEXT,

  -- Financial
  contract_price NUMERIC(14,2),
  earnest_money NUMERIC(14,2),
  commission_pct NUMERIC(5,3),
  commission_amount NUMERIC(14,2),

  -- Key dates
  contract_date DATE,
  closing_date DATE,
  possession_date DATE,
  inspection_deadline DATE,
  appraisal_deadline DATE,
  financing_deadline DATE,
  title_deadline DATE,

  -- Assignment
  assigned_tc UUID REFERENCES auth.users(id),
  listing_agent_id UUID REFERENCES auth.users(id),
  buyer_agent_id UUID REFERENCES auth.users(id),

  -- Progress tracking
  total_steps INTEGER NOT NULL DEFAULT 0,
  completed_steps INTEGER NOT NULL DEFAULT 0,
  completion_pct NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN total_steps > 0
      THEN ROUND((completed_steps::numeric / total_steps) * 100, 2)
      ELSE 0
    END
  ) STORED,

  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
    'draft','active','under_contract','inspection_period',
    'appraisal','title_review','clear_to_close','closing',
    'closed','cancelled','fallen_through'
  )),

  -- MLS reference
  mls_number TEXT,

  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tc_company ON transaction_checklists(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tc_status ON transaction_checklists(company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tc_tc ON transaction_checklists(assigned_tc) WHERE assigned_tc IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_tc_closing ON transaction_checklists(closing_date) WHERE closing_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_tc_property ON transaction_checklists(property_id) WHERE property_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_tc_type ON transaction_checklists(company_id, transaction_type) WHERE deleted_at IS NULL;

ALTER TABLE transaction_checklists ENABLE ROW LEVEL SECURITY;

CREATE POLICY tc_select ON transaction_checklists FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY tc_insert ON transaction_checklists FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY tc_update ON transaction_checklists FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY tc_delete ON transaction_checklists FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('transaction_checklists');
CREATE TRIGGER tc_audit AFTER INSERT OR UPDATE OR DELETE ON transaction_checklists
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. TRANSACTION STEPS — individual steps within checklists
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES transaction_checklists(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Step definition
  step_number INTEGER NOT NULL,
  step_name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'contract','inspection','appraisal','financing','title',
    'disclosure','compliance','closing','post_closing',
    'insurance','hoa','survey','environmental','tenant',
    'negotiation','marketing','other'
  )),

  -- Responsibility
  responsible_party TEXT CHECK (responsible_party IN (
    'listing_agent','buyer_agent','tc','escrow','title_company',
    'lender','appraiser','inspector','buyer','seller',
    'hoa','insurance','attorney','other'
  )),
  assigned_to UUID REFERENCES auth.users(id),

  -- Due dates (absolute or relative)
  due_date DATE,
  due_relative_days INTEGER,           -- days from due_relative_to event
  due_relative_to TEXT,                -- 'contract_date', 'closing_date', 'inspection_deadline', etc.

  -- Completion
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id),

  -- Documents
  document_required BOOLEAN NOT NULL DEFAULT false,
  document_id UUID,                    -- FK to documents when doc system exists
  document_path TEXT,

  -- Automation
  auto_action JSONB DEFAULT '{}',      -- {type: 'notify', target: 'buyer_agent', template: 'inspection_reminder'}
  reminder_sent BOOLEAN NOT NULL DEFAULT false,
  reminder_sent_at TIMESTAMPTZ,

  -- Dependencies (domino chain)
  depends_on_step_ids UUID[] DEFAULT '{}',  -- steps that must complete before this one
  triggers_step_ids UUID[] DEFAULT '{}',    -- steps to activate when this completes

  -- Priority
  is_critical_path BOOLEAN NOT NULL DEFAULT false,
  priority INTEGER NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),

  notes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ts_checklist ON transaction_steps(checklist_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ts_company ON transaction_steps(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ts_due ON transaction_steps(due_date) WHERE due_date IS NOT NULL AND completed = false AND deleted_at IS NULL;
CREATE INDEX idx_ts_status ON transaction_steps(checklist_id, completed) WHERE deleted_at IS NULL;
CREATE INDEX idx_ts_assigned ON transaction_steps(assigned_to) WHERE assigned_to IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_ts_category ON transaction_steps(checklist_id, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_ts_order ON transaction_steps(checklist_id, sort_order) WHERE deleted_at IS NULL;
CREATE INDEX idx_ts_critical ON transaction_steps(checklist_id, is_critical_path) WHERE is_critical_path = true AND deleted_at IS NULL;

ALTER TABLE transaction_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY ts_select ON transaction_steps FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ts_insert ON transaction_steps FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ts_update ON transaction_steps FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ts_delete ON transaction_steps FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('transaction_steps');
CREATE TRIGGER ts_audit AFTER INSERT OR UPDATE OR DELETE ON transaction_steps
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. SHOWINGS — individual showing appointments
-- ============================================================
CREATE TABLE IF NOT EXISTS showings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Property reference
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  property_address TEXT NOT NULL,
  mls_number TEXT,

  -- Agents
  listing_agent_name TEXT,
  listing_agent_phone TEXT,
  listing_agent_email TEXT,
  buyer_agent_id UUID REFERENCES auth.users(id),
  buyer_client_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  buyer_client_name TEXT,

  -- Schedule
  showing_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME,
  duration_minutes INTEGER NOT NULL DEFAULT 30,

  -- Type & access
  showing_type TEXT NOT NULL DEFAULT 'in_person' CHECK (showing_type IN (
    'in_person','virtual','open_house','broker_open','inspection',
    'appraisal','final_walkthrough','drive_by','other'
  )),
  access_type TEXT CHECK (access_type IN (
    'lockbox_combo','lockbox_supra','electronic_lockbox',
    'call_listing_agent','call_showing_service','occupied_appointment',
    'vacant_go','gate_code','other'
  )),
  access_instructions TEXT,
  lockbox_code TEXT,
  gate_code TEXT,

  -- Confirmation
  confirmation_required BOOLEAN NOT NULL DEFAULT true,
  confirmed BOOLEAN NOT NULL DEFAULT false,
  confirmed_at TIMESTAMPTZ,
  confirmed_by TEXT,

  -- Route optimization
  route_order INTEGER,                  -- position in day's showing route
  drive_time_from_prev_minutes INTEGER,
  distance_from_prev_miles NUMERIC(8,2),

  -- GPS check-in
  check_in_at TIMESTAMPTZ,
  check_in_lat NUMERIC(10,7),
  check_in_lng NUMERIC(10,7),
  check_out_at TIMESTAMPTZ,

  -- Feedback tracking
  feedback_requested BOOLEAN NOT NULL DEFAULT false,
  feedback_requested_at TIMESTAMPTZ,
  feedback_received BOOLEAN NOT NULL DEFAULT false,

  -- Status
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (
    'requested','pending_confirmation','scheduled','confirmed',
    'en_route','checked_in','completed','cancelled','no_show','rescheduled'
  )),
  cancelled_reason TEXT,
  rescheduled_to UUID REFERENCES showings(id),

  notes TEXT,
  agent_private_notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_show_company ON showings(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_show_date ON showings(company_id, showing_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_show_agent ON showings(buyer_agent_id) WHERE buyer_agent_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_show_client ON showings(buyer_client_id) WHERE buyer_client_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_show_property ON showings(property_id) WHERE property_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_show_status ON showings(company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_show_mls ON showings(mls_number) WHERE mls_number IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_show_route ON showings(buyer_agent_id, showing_date, route_order) WHERE deleted_at IS NULL;

ALTER TABLE showings ENABLE ROW LEVEL SECURITY;

CREATE POLICY show_select ON showings FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY show_insert ON showings FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY show_update ON showings FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY show_delete ON showings FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('showings');
CREATE TRIGGER show_audit AFTER INSERT OR UPDATE OR DELETE ON showings
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 5. SHOWING FEEDBACK — buyer ratings per showing
-- ============================================================
CREATE TABLE IF NOT EXISTS showing_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  showing_id UUID NOT NULL REFERENCES showings(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Who submitted
  submitted_by UUID REFERENCES auth.users(id),
  submitter_role TEXT CHECK (submitter_role IN ('buyer_agent','buyer_client','listing_agent','other')),

  -- Ratings (1-5 stars)
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  price_opinion TEXT CHECK (price_opinion IN ('overpriced','fair','underpriced','unsure')),
  condition_rating INTEGER CHECK (condition_rating BETWEEN 1 AND 5),
  location_rating INTEGER CHECK (location_rating BETWEEN 1 AND 5),
  layout_rating INTEGER CHECK (layout_rating BETWEEN 1 AND 5),
  curb_appeal_rating INTEGER CHECK (curb_appeal_rating BETWEEN 1 AND 5),

  -- Decision signals
  would_recommend BOOLEAN,
  likelihood_to_offer TEXT CHECK (likelihood_to_offer IN (
    'definitely_yes','probably_yes','maybe','probably_no','definitely_no'
  )),
  interest_level INTEGER CHECK (interest_level BETWEEN 1 AND 10),

  -- Qualitative
  pros TEXT[] DEFAULT '{}',
  cons TEXT[] DEFAULT '{}',
  comments TEXT,

  -- Agent-only notes
  agent_private_notes TEXT,
  client_visible BOOLEAN NOT NULL DEFAULT true,

  -- Comparison
  compared_to_showing_ids UUID[] DEFAULT '{}',  -- other showings buyer is comparing

  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_sf_showing ON showing_feedback(showing_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sf_company ON showing_feedback(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sf_submitted_by ON showing_feedback(submitted_by) WHERE submitted_by IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_sf_rating ON showing_feedback(overall_rating) WHERE deleted_at IS NULL;

ALTER TABLE showing_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY sf_select ON showing_feedback FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sf_insert ON showing_feedback FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sf_update ON showing_feedback FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sf_delete ON showing_feedback FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('showing_feedback');
CREATE TRIGGER sf_audit AFTER INSERT OR UPDATE OR DELETE ON showing_feedback
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 6. SEED: 8 Transaction Templates with full step blueprints
--    Steps stored as JSONB arrays in transaction_templates.steps
--    Instantiated into transaction_steps when a checklist is created
-- ============================================================

INSERT INTO transaction_templates (company_id, name, transaction_type, is_default, step_count, steps) VALUES

-- 6a. Buyer-Side Residential (~85 steps)
(NULL, 'Buyer-Side Residential (Standard)', 'buyer_residential', true, 85, '[
  {"step_number":1,"name":"Offer accepted — executed contract received","category":"contract","responsible_party":"buyer_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":2,"name":"Earnest money deposit delivered","category":"contract","responsible_party":"buyer","due_relative_days":3,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":3,"name":"Title company/escrow opened","category":"title","responsible_party":"tc","due_relative_days":2,"due_relative_to":"contract_date","document_required":false},
  {"step_number":4,"name":"Lender notified — contract copy sent","category":"financing","responsible_party":"buyer_agent","due_relative_days":1,"due_relative_to":"contract_date","document_required":false},
  {"step_number":5,"name":"Home inspection scheduled","category":"inspection","responsible_party":"buyer_agent","due_relative_days":3,"due_relative_to":"contract_date","document_required":false},
  {"step_number":6,"name":"HOA documents requested","category":"hoa","responsible_party":"tc","due_relative_days":3,"due_relative_to":"contract_date","document_required":false},
  {"step_number":7,"name":"Home warranty ordered","category":"insurance","responsible_party":"buyer_agent","due_relative_days":5,"due_relative_to":"contract_date","document_required":false},
  {"step_number":8,"name":"Homeowners insurance quote obtained","category":"insurance","responsible_party":"buyer","due_relative_days":7,"due_relative_to":"contract_date","document_required":false},
  {"step_number":9,"name":"Loan application completed (1003)","category":"financing","responsible_party":"buyer","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":10,"name":"Home inspection completed","category":"inspection","responsible_party":"inspector","due_relative_days":7,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":11,"name":"Inspection report reviewed with buyer","category":"inspection","responsible_party":"buyer_agent","due_relative_days":8,"due_relative_to":"contract_date","document_required":false},
  {"step_number":12,"name":"Repair request submitted (if applicable)","category":"inspection","responsible_party":"buyer_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":13,"name":"Seller response to repair request","category":"negotiation","responsible_party":"listing_agent","due_relative_days":13,"due_relative_to":"contract_date","document_required":true},
  {"step_number":14,"name":"Inspection contingency resolved","category":"inspection","responsible_party":"buyer_agent","due_relative_days":15,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":15,"name":"Radon test completed (if applicable)","category":"inspection","responsible_party":"inspector","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":16,"name":"Wood-destroying organism inspection","category":"inspection","responsible_party":"inspector","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":17,"name":"Sewer scope completed (if applicable)","category":"inspection","responsible_party":"inspector","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":18,"name":"Lead paint disclosure reviewed (pre-1978)","category":"disclosure","responsible_party":"tc","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":19,"name":"HOA documents reviewed — buyer approval","category":"hoa","responsible_party":"buyer","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":20,"name":"Appraisal ordered by lender","category":"appraisal","responsible_party":"lender","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":21,"name":"Appraisal scheduled","category":"appraisal","responsible_party":"appraiser","due_relative_days":14,"due_relative_to":"contract_date","document_required":false},
  {"step_number":22,"name":"Appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":21,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":23,"name":"Appraisal review — value meets/exceeds price","category":"appraisal","responsible_party":"lender","due_relative_days":23,"due_relative_to":"contract_date","document_required":false},
  {"step_number":24,"name":"Appraisal contingency resolved","category":"appraisal","responsible_party":"buyer_agent","due_relative_days":25,"due_relative_to":"contract_date","document_required":true},
  {"step_number":25,"name":"Title commitment received","category":"title","responsible_party":"title_company","due_relative_days":14,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":26,"name":"Title commitment reviewed","category":"title","responsible_party":"buyer_agent","due_relative_days":16,"due_relative_to":"contract_date","document_required":false},
  {"step_number":27,"name":"Title exceptions cleared","category":"title","responsible_party":"title_company","due_relative_days":21,"due_relative_to":"contract_date","document_required":false},
  {"step_number":28,"name":"Survey ordered (if required)","category":"survey","responsible_party":"tc","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":29,"name":"Survey completed and reviewed","category":"survey","responsible_party":"buyer_agent","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":30,"name":"Loan estimate received and reviewed","category":"financing","responsible_party":"buyer","due_relative_days":7,"due_relative_to":"contract_date","document_required":true},
  {"step_number":31,"name":"Credit report completed","category":"financing","responsible_party":"lender","due_relative_days":5,"due_relative_to":"contract_date","document_required":false},
  {"step_number":32,"name":"Employment verification completed","category":"financing","responsible_party":"lender","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":33,"name":"Bank statements verified","category":"financing","responsible_party":"lender","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":34,"name":"Tax returns verified","category":"financing","responsible_party":"lender","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":35,"name":"Conditional loan approval received","category":"financing","responsible_party":"lender","due_relative_days":21,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":36,"name":"Loan conditions satisfied","category":"financing","responsible_party":"buyer","due_relative_days":28,"due_relative_to":"contract_date","document_required":true},
  {"step_number":37,"name":"Final loan approval (clear to close)","category":"financing","responsible_party":"lender","due_relative_days":-7,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":38,"name":"Homeowners insurance policy bound","category":"insurance","responsible_party":"buyer","due_relative_days":-10,"due_relative_to":"closing_date","document_required":true},
  {"step_number":39,"name":"Insurance binder sent to lender","category":"insurance","responsible_party":"buyer_agent","due_relative_days":-10,"due_relative_to":"closing_date","document_required":true},
  {"step_number":40,"name":"Closing disclosure received (3-day review)","category":"closing","responsible_party":"lender","due_relative_days":-5,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":41,"name":"Closing disclosure reviewed and approved","category":"closing","responsible_party":"buyer","due_relative_days":-3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":42,"name":"Wire instructions received from title","category":"closing","responsible_party":"title_company","due_relative_days":-3,"due_relative_to":"closing_date","document_required":true},
  {"step_number":43,"name":"Wire transfer initiated","category":"closing","responsible_party":"buyer","due_relative_days":-2,"due_relative_to":"closing_date","document_required":true},
  {"step_number":44,"name":"Wire transfer confirmed received","category":"closing","responsible_party":"title_company","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":45,"name":"Final walkthrough scheduled","category":"closing","responsible_party":"buyer_agent","due_relative_days":-2,"due_relative_to":"closing_date","document_required":false},
  {"step_number":46,"name":"Final walkthrough completed","category":"closing","responsible_party":"buyer_agent","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false,"is_critical_path":true},
  {"step_number":47,"name":"Closing appointment confirmed","category":"closing","responsible_party":"tc","due_relative_days":-2,"due_relative_to":"closing_date","document_required":false},
  {"step_number":48,"name":"Closing documents signed","category":"closing","responsible_party":"buyer","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":49,"name":"Deed recorded","category":"closing","responsible_party":"title_company","due_relative_days":0,"due_relative_to":"closing_date","document_required":true},
  {"step_number":50,"name":"Keys delivered to buyer","category":"closing","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":51,"name":"Commission disbursement confirmed","category":"post_closing","responsible_party":"tc","due_relative_days":1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":52,"name":"Closing package filed","category":"post_closing","responsible_party":"tc","due_relative_days":3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":53,"name":"Welcome home gift/card sent","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":54,"name":"Utility transfer reminders sent","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":-3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":55,"name":"Address change checklist provided","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":56,"name":"Homestead exemption filing reminder (30 days)","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":30,"due_relative_to":"closing_date","document_required":false},
  {"step_number":57,"name":"30-day post-close check-in","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":30,"due_relative_to":"closing_date","document_required":false},
  {"step_number":58,"name":"90-day post-close check-in","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":90,"due_relative_to":"closing_date","document_required":false},
  {"step_number":59,"name":"1-year home anniversary — review/referral request","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":365,"due_relative_to":"closing_date","document_required":false}
]'::jsonb),

-- 6b. Seller-Side Residential (~75 steps)
(NULL, 'Seller-Side Residential (Standard)', 'seller_residential', true, 75, '[
  {"step_number":1,"name":"Listing agreement signed","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":2,"name":"Seller disclosures completed","category":"disclosure","responsible_party":"seller","due_relative_days":3,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":3,"name":"Lead paint disclosure (pre-1978)","category":"disclosure","responsible_party":"listing_agent","due_relative_days":3,"due_relative_to":"contract_date","document_required":true},
  {"step_number":4,"name":"Pre-listing inspection (recommended)","category":"inspection","responsible_party":"listing_agent","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":5,"name":"Home staging consultation","category":"marketing","responsible_party":"listing_agent","due_relative_days":5,"due_relative_to":"contract_date","document_required":false},
  {"step_number":6,"name":"Professional photography scheduled","category":"marketing","responsible_party":"listing_agent","due_relative_days":7,"due_relative_to":"contract_date","document_required":false},
  {"step_number":7,"name":"Photos/video/3D tour completed","category":"marketing","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":8,"name":"MLS listing activated","category":"marketing","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":false,"is_critical_path":true},
  {"step_number":9,"name":"Showing instructions set","category":"marketing","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":10,"name":"Lockbox installed","category":"marketing","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":11,"name":"Yard sign installed","category":"marketing","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":false},
  {"step_number":12,"name":"Offer received and presented to seller","category":"negotiation","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":true},
  {"step_number":13,"name":"Counter-offer drafted (if applicable)","category":"negotiation","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":true},
  {"step_number":14,"name":"Offer accepted — executed contract","category":"contract","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":true,"is_critical_path":true},
  {"step_number":15,"name":"Earnest money deposit verified","category":"contract","responsible_party":"tc","due_relative_days":3,"due_relative_to":"contract_date","document_required":true},
  {"step_number":16,"name":"Title company/escrow opened","category":"title","responsible_party":"tc","due_relative_days":2,"due_relative_to":"contract_date","document_required":false},
  {"step_number":17,"name":"HOA documents ordered","category":"hoa","responsible_party":"tc","due_relative_days":3,"due_relative_to":"contract_date","document_required":false},
  {"step_number":18,"name":"Buyer inspection — grant access","category":"inspection","responsible_party":"listing_agent","due_relative_days":7,"due_relative_to":"contract_date","document_required":false},
  {"step_number":19,"name":"Repair request received from buyer","category":"negotiation","responsible_party":"listing_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":20,"name":"Repair negotiation completed","category":"negotiation","responsible_party":"listing_agent","due_relative_days":13,"due_relative_to":"contract_date","document_required":true},
  {"step_number":21,"name":"Repairs completed (if agreed)","category":"inspection","responsible_party":"seller","due_relative_days":-7,"due_relative_to":"closing_date","document_required":true},
  {"step_number":22,"name":"Repair receipts collected","category":"inspection","responsible_party":"listing_agent","due_relative_days":-5,"due_relative_to":"closing_date","document_required":true},
  {"step_number":23,"name":"Appraisal — grant access","category":"appraisal","responsible_party":"listing_agent","due_relative_days":14,"due_relative_to":"contract_date","document_required":false},
  {"step_number":24,"name":"Appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":21,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":25,"name":"Title commitment reviewed","category":"title","responsible_party":"listing_agent","due_relative_days":16,"due_relative_to":"contract_date","document_required":false},
  {"step_number":26,"name":"Payoff statement ordered (mortgage)","category":"title","responsible_party":"title_company","due_relative_days":-14,"due_relative_to":"closing_date","document_required":true},
  {"step_number":27,"name":"Final walkthrough — grant access","category":"closing","responsible_party":"listing_agent","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":28,"name":"Closing documents signed","category":"closing","responsible_party":"seller","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":29,"name":"Keys/remotes/garage openers delivered","category":"closing","responsible_party":"seller","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":30,"name":"MLS status updated to sold","category":"post_closing","responsible_party":"listing_agent","due_relative_days":1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":31,"name":"Lockbox and sign removed","category":"post_closing","responsible_party":"listing_agent","due_relative_days":1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":32,"name":"Commission disbursement confirmed","category":"post_closing","responsible_party":"tc","due_relative_days":2,"due_relative_to":"closing_date","document_required":false},
  {"step_number":33,"name":"Closing package filed","category":"post_closing","responsible_party":"tc","due_relative_days":3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":34,"name":"Seller thank-you card sent","category":"post_closing","responsible_party":"listing_agent","due_relative_days":3,"due_relative_to":"closing_date","document_required":false},
  {"step_number":35,"name":"Review/referral request sent","category":"post_closing","responsible_party":"listing_agent","due_relative_days":7,"due_relative_to":"closing_date","document_required":false}
]'::jsonb),

-- 6c. Dual Agency (~95 steps)
(NULL, 'Dual Agency Transaction', 'dual_agency', true, 50, '[
  {"step_number":1,"name":"Dual agency disclosure signed by ALL parties","category":"disclosure","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":2,"name":"Conflict of interest acknowledgment documented","category":"compliance","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":3,"name":"Broker approval obtained for dual agency","category":"compliance","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true},
  {"step_number":4,"name":"Separate communication channels established","category":"compliance","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":false},
  {"step_number":5,"name":"Offer presented with neutrality documentation","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true},
  {"step_number":6,"name":"Executed contract with dual agency addendum","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":7,"name":"Earnest money deposit delivered","category":"contract","responsible_party":"buyer","due_relative_days":3,"due_relative_to":"contract_date","document_required":true},
  {"step_number":8,"name":"Title/escrow opened","category":"title","responsible_party":"tc","due_relative_days":2,"due_relative_to":"contract_date","document_required":false},
  {"step_number":9,"name":"Home inspection completed","category":"inspection","responsible_party":"inspector","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":10,"name":"CONFLICT CHECK: repair negotiations handled neutrally","category":"compliance","responsible_party":"listing_agent","due_relative_days":12,"due_relative_to":"contract_date","document_required":true},
  {"step_number":11,"name":"Appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":21,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":12,"name":"CONFLICT CHECK: appraisal gap handled neutrally","category":"compliance","responsible_party":"listing_agent","due_relative_days":23,"due_relative_to":"contract_date","document_required":true},
  {"step_number":13,"name":"Title commitment reviewed by both parties","category":"title","responsible_party":"tc","due_relative_days":16,"due_relative_to":"contract_date","document_required":false},
  {"step_number":14,"name":"Closing disclosure reviewed by both parties","category":"closing","responsible_party":"lender","due_relative_days":-5,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":15,"name":"Final walkthrough completed","category":"closing","responsible_party":"listing_agent","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":16,"name":"Closing — all parties sign","category":"closing","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":17,"name":"Commission split documented and disbursed","category":"post_closing","responsible_party":"tc","due_relative_days":1,"due_relative_to":"closing_date","document_required":true}
]'::jsonb),

-- 6d. New Construction (~60 steps)
(NULL, 'New Construction Purchase', 'new_construction', true, 40, '[
  {"step_number":1,"name":"Builder contract executed","category":"contract","responsible_party":"buyer_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":2,"name":"Earnest money deposit (builder schedule)","category":"contract","responsible_party":"buyer","due_relative_days":3,"due_relative_to":"contract_date","document_required":true},
  {"step_number":3,"name":"Lot/plan selections confirmed","category":"contract","responsible_party":"buyer","due_relative_days":7,"due_relative_to":"contract_date","document_required":true},
  {"step_number":4,"name":"Design center selections completed","category":"contract","responsible_party":"buyer","due_relative_days":30,"due_relative_to":"contract_date","document_required":true},
  {"step_number":5,"name":"Construction start confirmed","category":"contract","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":false},
  {"step_number":6,"name":"Foundation poured — milestone photo","category":"inspection","responsible_party":"buyer_agent","due_relative_days":null,"due_relative_to":null,"document_required":false},
  {"step_number":7,"name":"Framing inspection passed","category":"inspection","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":true},
  {"step_number":8,"name":"Pre-drywall walkthrough","category":"inspection","responsible_party":"buyer_agent","due_relative_days":null,"due_relative_to":null,"document_required":false},
  {"step_number":9,"name":"Mechanical rough-in inspections passed","category":"inspection","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":true},
  {"step_number":10,"name":"Drywall complete","category":"inspection","responsible_party":"listing_agent","due_relative_days":null,"due_relative_to":null,"document_required":false},
  {"step_number":11,"name":"Finishes installation progress check","category":"inspection","responsible_party":"buyer_agent","due_relative_days":null,"due_relative_to":null,"document_required":false},
  {"step_number":12,"name":"Certificate of Occupancy issued","category":"compliance","responsible_party":"listing_agent","due_relative_days":-14,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":13,"name":"Final inspection / punch list walkthrough","category":"inspection","responsible_party":"buyer_agent","due_relative_days":-7,"due_relative_to":"closing_date","document_required":true},
  {"step_number":14,"name":"Punch list items completed by builder","category":"inspection","responsible_party":"listing_agent","due_relative_days":-3,"due_relative_to":"closing_date","document_required":true},
  {"step_number":15,"name":"Appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":-21,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":16,"name":"Final loan approval","category":"financing","responsible_party":"lender","due_relative_days":-7,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":17,"name":"Builder warranty package reviewed","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":-5,"due_relative_to":"closing_date","document_required":true},
  {"step_number":18,"name":"Closing documents signed","category":"closing","responsible_party":"buyer","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":19,"name":"Builder orientation/walkthrough","category":"post_closing","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":20,"name":"11-month warranty walkthrough scheduled","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":330,"due_relative_to":"closing_date","document_required":false}
]'::jsonb),

-- 6e. Commercial (~45 steps)
(NULL, 'Commercial Purchase', 'commercial', true, 35, '[
  {"step_number":1,"name":"Letter of Intent (LOI) submitted","category":"negotiation","responsible_party":"buyer_agent","due_relative_days":-30,"due_relative_to":"contract_date","document_required":true},
  {"step_number":2,"name":"LOI accepted / countered","category":"negotiation","responsible_party":"listing_agent","due_relative_days":-25,"due_relative_to":"contract_date","document_required":true},
  {"step_number":3,"name":"Purchase and sale agreement executed","category":"contract","responsible_party":"buyer_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":4,"name":"Earnest money deposit","category":"contract","responsible_party":"buyer","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":5,"name":"Due diligence period begins","category":"inspection","responsible_party":"buyer_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":false,"is_critical_path":true},
  {"step_number":6,"name":"Phase I Environmental Assessment ordered","category":"environmental","responsible_party":"buyer","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":7,"name":"Zoning verification obtained","category":"compliance","responsible_party":"buyer_agent","due_relative_days":7,"due_relative_to":"contract_date","document_required":true},
  {"step_number":8,"name":"Rent roll and financial statements reviewed","category":"inspection","responsible_party":"buyer_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":9,"name":"Tenant estoppel certificates requested","category":"tenant","responsible_party":"listing_agent","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":10,"name":"Building inspection completed","category":"inspection","responsible_party":"inspector","due_relative_days":14,"due_relative_to":"contract_date","document_required":true},
  {"step_number":11,"name":"Phase I ESA report received","category":"environmental","responsible_party":"buyer_agent","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":12,"name":"Phase II ESA (if triggered)","category":"environmental","responsible_party":"buyer","due_relative_days":35,"due_relative_to":"contract_date","document_required":true},
  {"step_number":13,"name":"ALTA survey ordered and completed","category":"survey","responsible_party":"buyer_agent","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":14,"name":"Tenant estoppels received and reviewed","category":"tenant","responsible_party":"buyer_agent","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":15,"name":"Due diligence period ends — go/no-go","category":"contract","responsible_party":"buyer_agent","due_relative_days":30,"due_relative_to":"contract_date","document_required":false,"is_critical_path":true},
  {"step_number":16,"name":"Commercial appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":28,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":17,"name":"Commercial loan commitment received","category":"financing","responsible_party":"lender","due_relative_days":35,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":18,"name":"Title commitment + exceptions reviewed","category":"title","responsible_party":"attorney","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":19,"name":"Closing statement reviewed","category":"closing","responsible_party":"buyer_agent","due_relative_days":-5,"due_relative_to":"closing_date","document_required":true},
  {"step_number":20,"name":"Closing — documents executed","category":"closing","responsible_party":"buyer","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":21,"name":"Tenant notification letters sent","category":"post_closing","responsible_party":"buyer_agent","due_relative_days":3,"due_relative_to":"closing_date","document_required":true}
]'::jsonb),

-- 6f. Short Sale (~50 steps)
(NULL, 'Short Sale Purchase', 'short_sale', true, 30, '[
  {"step_number":1,"name":"Short sale package submitted to seller bank","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":2,"name":"Bank acknowledgment of package received","category":"contract","responsible_party":"listing_agent","due_relative_days":7,"due_relative_to":"contract_date","document_required":false},
  {"step_number":3,"name":"Negotiator assigned by bank","category":"negotiation","responsible_party":"listing_agent","due_relative_days":14,"due_relative_to":"contract_date","document_required":false},
  {"step_number":4,"name":"BPO (Broker Price Opinion) ordered by bank","category":"appraisal","responsible_party":"listing_agent","due_relative_days":21,"due_relative_to":"contract_date","document_required":false},
  {"step_number":5,"name":"BPO completed — agent provides comps","category":"appraisal","responsible_party":"listing_agent","due_relative_days":28,"due_relative_to":"contract_date","document_required":true},
  {"step_number":6,"name":"Bank counter-offer or approval","category":"negotiation","responsible_party":"listing_agent","due_relative_days":45,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":7,"name":"Short sale approval letter received","category":"contract","responsible_party":"listing_agent","due_relative_days":60,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":8,"name":"Buyer inspection (post-approval)","category":"inspection","responsible_party":"buyer_agent","due_relative_days":65,"due_relative_to":"contract_date","document_required":true},
  {"step_number":9,"name":"Title cleared — subordinate lien releases","category":"title","responsible_party":"title_company","due_relative_days":-14,"due_relative_to":"closing_date","document_required":true},
  {"step_number":10,"name":"Closing within bank-required timeframe","category":"closing","responsible_party":"tc","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":11,"name":"Deficiency judgment waiver documented","category":"post_closing","responsible_party":"listing_agent","due_relative_days":3,"due_relative_to":"closing_date","document_required":true}
]'::jsonb),

-- 6g. REO/Foreclosure (~40 steps)
(NULL, 'REO/Foreclosure Purchase', 'reo_foreclosure', true, 25, '[
  {"step_number":1,"name":"Asset manager offer submitted","category":"contract","responsible_party":"buyer_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true},
  {"step_number":2,"name":"Bank addenda signed (as-is, special conditions)","category":"contract","responsible_party":"buyer","due_relative_days":3,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":3,"name":"Earnest money to bank-designated escrow","category":"contract","responsible_party":"buyer","due_relative_days":5,"due_relative_to":"contract_date","document_required":true},
  {"step_number":4,"name":"Proof of funds / pre-approval submitted","category":"financing","responsible_party":"buyer","due_relative_days":3,"due_relative_to":"contract_date","document_required":true},
  {"step_number":5,"name":"Home inspection (as-is — informational only)","category":"inspection","responsible_party":"buyer_agent","due_relative_days":10,"due_relative_to":"contract_date","document_required":true},
  {"step_number":6,"name":"Title search — foreclosure procedure verified","category":"title","responsible_party":"title_company","due_relative_days":14,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":7,"name":"Clear title confirmed (liens, judgments, tax)","category":"title","responsible_party":"title_company","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":8,"name":"Appraisal completed","category":"appraisal","responsible_party":"appraiser","due_relative_days":21,"due_relative_to":"contract_date","document_required":true},
  {"step_number":9,"name":"Loan approval received","category":"financing","responsible_party":"lender","due_relative_days":-7,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":10,"name":"Final walkthrough (verify no new damage)","category":"closing","responsible_party":"buyer_agent","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":11,"name":"Closing — bank-designated title company","category":"closing","responsible_party":"tc","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":12,"name":"Occupancy check (eviction if needed)","category":"post_closing","responsible_party":"buyer","due_relative_days":1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":13,"name":"Property secured — locks changed","category":"post_closing","responsible_party":"buyer","due_relative_days":1,"due_relative_to":"closing_date","document_required":false}
]'::jsonb),

-- 6h. Lease/Rental (~30 steps)
(NULL, 'Lease/Rental Transaction', 'lease_rental', true, 22, '[
  {"step_number":1,"name":"Rental application received","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true},
  {"step_number":2,"name":"Application fee collected","category":"contract","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"contract_date","document_required":true},
  {"step_number":3,"name":"Credit check completed","category":"compliance","responsible_party":"listing_agent","due_relative_days":1,"due_relative_to":"contract_date","document_required":true},
  {"step_number":4,"name":"Background check completed","category":"compliance","responsible_party":"listing_agent","due_relative_days":1,"due_relative_to":"contract_date","document_required":true},
  {"step_number":5,"name":"Income/employment verification","category":"compliance","responsible_party":"listing_agent","due_relative_days":2,"due_relative_to":"contract_date","document_required":true},
  {"step_number":6,"name":"Landlord references checked","category":"compliance","responsible_party":"listing_agent","due_relative_days":2,"due_relative_to":"contract_date","document_required":false},
  {"step_number":7,"name":"Application approved by owner","category":"contract","responsible_party":"listing_agent","due_relative_days":3,"due_relative_to":"contract_date","document_required":false,"is_critical_path":true},
  {"step_number":8,"name":"Lease agreement prepared","category":"contract","responsible_party":"listing_agent","due_relative_days":4,"due_relative_to":"contract_date","document_required":true},
  {"step_number":9,"name":"Lease reviewed and signed by tenant","category":"contract","responsible_party":"buyer","due_relative_days":5,"due_relative_to":"contract_date","document_required":true,"is_critical_path":true},
  {"step_number":10,"name":"Lease signed by landlord","category":"contract","responsible_party":"seller","due_relative_days":6,"due_relative_to":"contract_date","document_required":true},
  {"step_number":11,"name":"Security deposit collected","category":"contract","responsible_party":"listing_agent","due_relative_days":6,"due_relative_to":"contract_date","document_required":true},
  {"step_number":12,"name":"First months rent collected","category":"contract","responsible_party":"listing_agent","due_relative_days":6,"due_relative_to":"contract_date","document_required":true},
  {"step_number":13,"name":"Move-in inspection scheduled","category":"inspection","responsible_party":"listing_agent","due_relative_days":-1,"due_relative_to":"closing_date","document_required":false},
  {"step_number":14,"name":"Move-in inspection completed with photos","category":"inspection","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":true,"is_critical_path":true},
  {"step_number":15,"name":"Keys/access devices delivered","category":"closing","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":16,"name":"Utilities transfer confirmed","category":"closing","responsible_party":"buyer","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":17,"name":"Welcome packet provided","category":"post_closing","responsible_party":"listing_agent","due_relative_days":0,"due_relative_to":"closing_date","document_required":false},
  {"step_number":18,"name":"Commission disbursement","category":"post_closing","responsible_party":"tc","due_relative_days":3,"due_relative_to":"closing_date","document_required":false}
]'::jsonb)

ON CONFLICT DO NOTHING;


-- ============================================================
-- 7. FUNCTION: Instantiate template steps into a checklist
-- ============================================================
CREATE OR REPLACE FUNCTION fn_instantiate_transaction_checklist(
  p_checklist_id UUID,
  p_template_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_template RECORD;
  v_step JSONB;
  v_company_id UUID;
  v_closing_date DATE;
  v_contract_date DATE;
  v_inspection_deadline DATE;
  v_appraisal_deadline DATE;
  v_financing_deadline DATE;
  v_due DATE;
  v_relative_to TEXT;
  v_relative_days INTEGER;
  v_count INTEGER := 0;
BEGIN
  -- Get checklist info
  SELECT tc.company_id, tc.closing_date, tc.contract_date,
         tc.inspection_deadline, tc.appraisal_deadline, tc.financing_deadline
    INTO v_company_id, v_closing_date, v_contract_date,
         v_inspection_deadline, v_appraisal_deadline, v_financing_deadline
    FROM transaction_checklists tc
   WHERE tc.id = p_checklist_id;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Checklist not found: %', p_checklist_id;
  END IF;

  -- Get template
  SELECT * INTO v_template FROM transaction_templates WHERE id = p_template_id;
  IF v_template.id IS NULL THEN
    RAISE EXCEPTION 'Template not found: %', p_template_id;
  END IF;

  -- Iterate and insert each step
  FOR v_step IN SELECT * FROM jsonb_array_elements(v_template.steps)
  LOOP
    v_due := NULL;
    v_relative_to := v_step ->> 'due_relative_to';
    v_relative_days := (v_step ->> 'due_relative_days')::integer;

    IF v_relative_days IS NOT NULL AND v_relative_to IS NOT NULL THEN
      CASE v_relative_to
        WHEN 'contract_date' THEN v_due := v_contract_date + v_relative_days;
        WHEN 'closing_date' THEN v_due := v_closing_date + v_relative_days;
        WHEN 'inspection_deadline' THEN v_due := v_inspection_deadline + v_relative_days;
        WHEN 'appraisal_deadline' THEN v_due := v_appraisal_deadline + v_relative_days;
        WHEN 'financing_deadline' THEN v_due := v_financing_deadline + v_relative_days;
        ELSE v_due := NULL;
      END CASE;
    END IF;

    INSERT INTO transaction_steps (
      checklist_id, company_id, step_number, step_name, description,
      category, responsible_party, due_date, due_relative_days, due_relative_to,
      document_required, auto_action, is_critical_path, sort_order
    ) VALUES (
      p_checklist_id,
      v_company_id,
      COALESCE((v_step ->> 'step_number')::integer, v_count + 1),
      v_step ->> 'name',
      v_step ->> 'description',
      COALESCE(v_step ->> 'category', 'other'),
      v_step ->> 'responsible_party',
      v_due,
      v_relative_days,
      v_relative_to,
      COALESCE((v_step ->> 'document_required')::boolean, false),
      COALESCE(v_step -> 'auto_action', '{}'::jsonb),
      COALESCE((v_step ->> 'is_critical_path')::boolean, false),
      COALESCE((v_step ->> 'step_number')::integer, v_count + 1)
    );

    v_count := v_count + 1;
  END LOOP;

  -- Update checklist totals
  UPDATE transaction_checklists
     SET total_steps = v_count,
         completed_steps = 0,
         template_id = p_template_id
   WHERE id = p_checklist_id;

  RETURN v_count;
END;
$$;
