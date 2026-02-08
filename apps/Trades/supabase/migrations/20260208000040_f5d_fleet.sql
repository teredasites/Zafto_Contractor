-- F5d: Fleet Management tables
-- Vehicle tracking, maintenance scheduling, fuel logs

-- Vehicles
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,  -- "White F-150 #3"
  vehicle_type TEXT NOT NULL DEFAULT 'truck' CHECK (vehicle_type IN ('truck','van','car','suv','trailer','equipment_trailer','other')),
  year INTEGER,
  make TEXT,
  model TEXT,
  vin TEXT,
  license_plate TEXT,
  license_state TEXT,
  color TEXT,
  -- Assignment
  assigned_to_user_id UUID REFERENCES auth.users(id),
  current_job_id UUID REFERENCES jobs(id),
  -- Tracking
  gps_device_id TEXT,  -- Samsara/Geotab device ID
  gps_provider TEXT CHECK (gps_provider IN ('samsara','geotab','manual',NULL)),
  last_lat NUMERIC(10,7),
  last_lng NUMERIC(10,7),
  last_location_at TIMESTAMPTZ,
  current_odometer INTEGER,
  -- Insurance
  insurance_provider TEXT,
  insurance_policy TEXT,
  insurance_expires_at DATE,
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','maintenance','out_of_service','sold','totaled')),
  purchase_date DATE,
  purchase_price NUMERIC(12,2),
  current_value NUMERIC(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Vehicle Maintenance Records
CREATE TABLE vehicle_maintenance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  maintenance_type TEXT NOT NULL CHECK (maintenance_type IN ('oil_change','tire_rotation','brake_service','transmission','engine','electrical','body','inspection','registration','other')),
  description TEXT NOT NULL,
  odometer_at INTEGER,
  vendor TEXT,
  cost NUMERIC(10,2) DEFAULT 0,
  parts_cost NUMERIC(10,2) DEFAULT 0,
  labor_cost NUMERIC(10,2) DEFAULT 0,
  scheduled_date DATE,
  completed_date DATE,
  next_due_date DATE,
  next_due_odometer INTEGER,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','in_progress','completed','cancelled')),
  receipt_path TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Fuel Logs
CREATE TABLE fuel_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  filled_by_user_id UUID REFERENCES auth.users(id),
  fill_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  odometer INTEGER,
  gallons NUMERIC(8,3) NOT NULL,
  price_per_gallon NUMERIC(6,3) NOT NULL,
  total_cost NUMERIC(10,2) NOT NULL,
  fuel_type TEXT DEFAULT 'regular' CHECK (fuel_type IN ('regular','premium','diesel','e85')),
  station_name TEXT,
  station_address TEXT,
  is_full_tank BOOLEAN DEFAULT true,
  receipt_path TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY vehicles_company ON vehicles FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY vehicle_maintenance_company ON vehicle_maintenance FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fuel_logs_company ON fuel_logs FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_vehicles_company ON vehicles(company_id);
CREATE INDEX idx_vehicles_assigned ON vehicles(assigned_to_user_id) WHERE assigned_to_user_id IS NOT NULL;
CREATE INDEX idx_vehicle_maintenance_vehicle ON vehicle_maintenance(vehicle_id);
CREATE INDEX idx_vehicle_maintenance_next ON vehicle_maintenance(next_due_date) WHERE status = 'scheduled';
CREATE INDEX idx_fuel_logs_vehicle ON fuel_logs(vehicle_id);
CREATE INDEX idx_fuel_logs_date ON fuel_logs(company_id, fill_date);

-- Triggers
CREATE TRIGGER vehicles_updated BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER vehicle_maintenance_updated BEFORE UPDATE ON vehicle_maintenance FOR EACH ROW EXECUTE FUNCTION update_updated_at();
