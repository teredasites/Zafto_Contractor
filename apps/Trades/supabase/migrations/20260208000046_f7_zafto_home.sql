-- F7: ZAFTO Home Platform tables
-- Homeowner property intelligence: equipment passport, service history, maintenance reminders

-- Homeowner Properties
CREATE TABLE homeowner_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  -- Address
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zip_code TEXT NOT NULL,
  -- Property details
  property_type TEXT DEFAULT 'single_family' CHECK (property_type IN ('single_family','townhouse','condo','multi_family','mobile_home','other')),
  year_built INTEGER,
  square_footage INTEGER,
  lot_size_sqft INTEGER,
  stories INTEGER DEFAULT 1,
  bedrooms INTEGER,
  bathrooms NUMERIC(3,1),
  garage_spaces INTEGER DEFAULT 0,
  -- Media
  photo_path TEXT,
  -- Settings
  is_primary BOOLEAN DEFAULT true,
  nickname TEXT,  -- "Lake House", "Rental Property"
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Homeowner Equipment — installed systems in the home
CREATE TABLE homeowner_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES homeowner_properties(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  -- Equipment info
  category TEXT NOT NULL CHECK (category IN ('hvac','plumbing','electrical','appliance','roofing','structural','fire_protection','water_heater','water_treatment','garage_door','security','solar','pool','other')),
  name TEXT NOT NULL,  -- "Main HVAC System", "Kitchen Fridge"
  manufacturer TEXT,
  model_number TEXT,
  serial_number TEXT,
  install_date DATE,
  purchase_date DATE,
  -- Lifecycle
  estimated_lifespan_years INTEGER,
  condition TEXT DEFAULT 'good' CHECK (condition IN ('excellent','good','fair','poor','critical','unknown')),
  last_service_date DATE,
  next_service_due DATE,
  -- Warranty
  warranty_expiry DATE,
  warranty_provider TEXT,
  warranty_document_path TEXT,
  -- Equipment DB link
  equipment_database_id UUID REFERENCES equipment_database(id),
  -- AI scan link
  last_scan_id UUID REFERENCES equipment_scans(id),
  ai_health_score INTEGER CHECK (ai_health_score BETWEEN 0 AND 100),
  -- Media
  photo_path TEXT,
  manual_path TEXT,
  -- Location in home
  location TEXT,  -- "Basement", "Kitchen", "Attic"
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Service History — completed services linked to contractors
CREATE TABLE service_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES homeowner_properties(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  equipment_id UUID REFERENCES homeowner_equipment(id),
  -- Service details
  service_type TEXT NOT NULL CHECK (service_type IN ('repair','replacement','installation','inspection','maintenance','emergency','other')),
  trade_category TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  -- Contractor
  company_id UUID REFERENCES companies(id),
  contractor_name TEXT,
  contractor_phone TEXT,
  contractor_email TEXT,
  -- Cost
  total_cost NUMERIC(10,2),
  parts_cost NUMERIC(10,2),
  labor_cost NUMERIC(10,2),
  -- Dates
  service_date DATE NOT NULL,
  warranty_until DATE,
  -- Documents
  invoice_path TEXT,
  receipt_path TEXT,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Review
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  review_date TIMESTAMPTZ,
  -- From CRM (if contractor uses ZAFTO)
  job_id UUID REFERENCES jobs(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Maintenance Schedules — upcoming maintenance reminders
CREATE TABLE maintenance_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES homeowner_properties(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  equipment_id UUID REFERENCES homeowner_equipment(id),
  -- Schedule
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ('monthly','quarterly','semi_annual','annual','biennial','custom')),
  custom_interval_days INTEGER,
  -- Dates
  next_due_date DATE NOT NULL,
  last_completed_date DATE,
  -- Reminders
  remind_days_before INTEGER DEFAULT 7,
  reminder_sent BOOLEAN DEFAULT false,
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active','paused','completed','skipped')),
  -- AI
  ai_recommended BOOLEAN DEFAULT false,
  ai_priority TEXT CHECK (ai_priority IN ('low','medium','high','critical')),
  ai_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Homeowner Documents — warranties, manuals, permits
CREATE TABLE homeowner_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES homeowner_properties(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  equipment_id UUID REFERENCES homeowner_equipment(id),
  -- Document
  name TEXT NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('warranty','manual','receipt','invoice','permit','inspection_report','insurance','photo','contract','other')),
  file_type TEXT,
  mime_type TEXT,
  file_size_bytes BIGINT DEFAULT 0,
  storage_path TEXT NOT NULL,
  description TEXT,
  -- Dates
  expiry_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE homeowner_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE homeowner_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE homeowner_documents ENABLE ROW LEVEL SECURITY;

-- Homeowners see only their own data
CREATE POLICY ho_properties_owner ON homeowner_properties FOR ALL USING (owner_user_id = auth.uid());
CREATE POLICY ho_equipment_owner ON homeowner_equipment FOR ALL USING (owner_user_id = auth.uid());
CREATE POLICY ho_service_owner ON service_history FOR ALL USING (owner_user_id = auth.uid());
CREATE POLICY ho_maintenance_owner ON maintenance_schedules FOR ALL USING (owner_user_id = auth.uid());
CREATE POLICY ho_documents_owner ON homeowner_documents FOR ALL USING (owner_user_id = auth.uid());

-- Contractors can see service history for their jobs
CREATE POLICY service_history_contractor ON service_history FOR SELECT USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);

-- Indexes
CREATE INDEX idx_ho_properties_owner ON homeowner_properties(owner_user_id);
CREATE INDEX idx_ho_equipment_property ON homeowner_equipment(property_id);
CREATE INDEX idx_ho_equipment_category ON homeowner_equipment(category);
CREATE INDEX idx_ho_equipment_next_service ON homeowner_equipment(next_service_due) WHERE next_service_due IS NOT NULL;
CREATE INDEX idx_service_history_property ON service_history(property_id);
CREATE INDEX idx_service_history_equipment ON service_history(equipment_id) WHERE equipment_id IS NOT NULL;
CREATE INDEX idx_service_history_company ON service_history(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX idx_maintenance_property ON maintenance_schedules(property_id);
CREATE INDEX idx_maintenance_next_due ON maintenance_schedules(next_due_date) WHERE status = 'active';
CREATE INDEX idx_ho_documents_property ON homeowner_documents(property_id);
CREATE INDEX idx_ho_documents_equipment ON homeowner_documents(equipment_id) WHERE equipment_id IS NOT NULL;

-- Triggers
CREATE TRIGGER ho_properties_updated BEFORE UPDATE ON homeowner_properties FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER ho_equipment_updated BEFORE UPDATE ON homeowner_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER service_history_updated BEFORE UPDATE ON service_history FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER maintenance_updated BEFORE UPDATE ON maintenance_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at();
