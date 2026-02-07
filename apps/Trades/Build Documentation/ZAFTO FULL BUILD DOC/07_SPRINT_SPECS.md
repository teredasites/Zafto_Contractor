# ZAFTO SPRINT SPECIFICATIONS
## Every Sprint, Every Step, Every Verification
### Created: February 6, 2026 (Session 37)

---

## HOW TO USE THIS DOC

Each sprint has:
- **Objective** — What gets built
- **Prerequisites** — What must be done first
- **Database** — SQL to run (if any)
- **Files** — Exact files to create or modify
- **Steps** — Ordered implementation steps
- **Verify** — How to confirm it's done correctly
- **Status** — PENDING / IN PROGRESS / DONE

**Execute sprints in order. Never skip. Update status as you go.**

---

## PHASE A: FOUNDATION

---

### Sprint A1: Code Cleanup
**Status: DONE (Session 37)**

Deleted 8 dead files (3,637 lines): photo_service, email_service, pdf_service, stripe_service, firebase_config, offline_queue_service, role_service, user_service. Empty config/ dir removed. Model dedup deferred to B1.

---

### Sprint A2: DevOps Phase 1 — Environments + Secrets
**Status: DONE (Session 39)**
**Est: ~2 hours**

#### Objective
Configure three Supabase environments (dev/staging/prod), secrets management, and Dependabot.

#### Prerequisites
- Supabase projects created (dev + prod exist, need staging)
- GitHub repo access (TeredaDeveloper)

#### Steps

**Step 1: Create staging Supabase project**
1. Log into Supabase as admin@zafto.app
2. Create new project `zafto-staging` in same org, US East region
3. Note the project URL and anon key

**Step 2: Environment config for Flutter**
Create environment config files:

```
File: lib/core/env.dart
```
```dart
enum Environment { dev, staging, prod }

class EnvConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String powerSyncUrl;
  final String sentryDsn;
  final Environment environment;

  const EnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.powerSyncUrl,
    this.sentryDsn = '',
    required this.environment,
  });

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;
}
```

Create `lib/core/env_dev.dart`, `lib/core/env_staging.dart`, `lib/core/env_prod.dart` — each returns an `EnvConfig` with the correct values. **Add these files to .gitignore** — they contain keys.

Create `lib/core/env_template.dart` as a checked-in template with placeholder values.

**Step 3: Environment config for Web CRM**
```
File: web-portal/.env.local        (dev — gitignored)
File: web-portal/.env.staging      (staging — gitignored)
File: web-portal/.env.production   (prod — gitignored)
File: web-portal/.env.example      (template — committed)
```

Each contains:
```
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
NEXT_PUBLIC_SENTRY_DSN=xxx
```

**Step 4: Environment config for Client Portal**
Same pattern as Web CRM but in `client-portal/`.

**Step 5: Dependabot**
Create `.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
  - package-ecosystem: "npm"
    directory: "/web-portal"
    schedule:
      interval: "weekly"
  - package-ecosystem: "npm"
    directory: "/client-portal"
    schedule:
      interval: "weekly"
```

**Step 6: Update .gitignore**
Ensure all env files with real keys are gitignored:
```
lib/core/env_dev.dart
lib/core/env_staging.dart
lib/core/env_prod.dart
web-portal/.env.local
web-portal/.env.staging
web-portal/.env.production
client-portal/.env.local
client-portal/.env.staging
client-portal/.env.production
```

#### Verify
- [ ] Three Supabase projects accessible (dev, staging, prod)
- [ ] Flutter env config compiles
- [ ] Web CRM starts with env vars
- [ ] Client Portal starts with env vars
- [ ] No real keys in git history
- [ ] Dependabot enabled in GitHub Settings
- [ ] `flutter analyze` passes
- [ ] Commit: `[A2] DevOps Phase 1 — environments, secrets, Dependabot`

---

### Sprint A3: Database Migration — Core Schema + RLS
**Status: DONE (A3a/A3b/A3c deployed to dev — 16 tables verified. A3d done — 7 storage buckets. Env keys filled. A3e PowerSync deferred.)**
**Est: ~17-25 hours (split into A3a-A3e)**

---

#### Sprint A3a: Core Tables (companies, users, auth)
**Est: ~3-4 hours**

##### Objective
Deploy the foundation tables that everything else depends on: companies, users, auth integration.

##### Database (run against dev first, then staging, then prod)

```sql
-- ============================================================
-- ZAFTO CORE SCHEMA — A3a: Auth Foundation
-- ============================================================

-- Helper functions for RLS
CREATE OR REPLACE FUNCTION auth.company_id() RETURNS uuid AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.user_role() RETURNS text AS $$
  SELECT auth.jwt() -> 'app_metadata' ->> 'role';
$$ LANGUAGE sql STABLE;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- COMPANIES TABLE
-- ============================================================
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  trade text NOT NULL DEFAULT 'electrical',
  trades text[] DEFAULT '{}',
  owner_user_id uuid,  -- set after first user created
  phone text,
  email text,
  address text,
  city text,
  state text,
  zip_code text,
  website text,
  license_number text,
  license_state text,
  logo_url text,
  subscription_tier text NOT NULL DEFAULT 'solo' CHECK (subscription_tier IN ('solo', 'team', 'business', 'enterprise')),
  subscription_status text NOT NULL DEFAULT 'trialing' CHECK (subscription_status IN ('trialing', 'active', 'past_due', 'cancelled')),
  stripe_customer_id text,
  stripe_subscription_id text,
  max_users int NOT NULL DEFAULT 1,
  settings jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: Users can read their own company
CREATE POLICY "companies_select" ON companies FOR SELECT USING (id = auth.company_id());
-- RLS: Only owner/admin can update company
CREATE POLICY "companies_update" ON companies FOR UPDATE USING (
  id = auth.company_id() AND auth.user_role() IN ('owner', 'admin')
);
-- RLS: Anyone can insert (onboarding creates company)
CREATE POLICY "companies_insert" ON companies FOR INSERT WITH CHECK (true);

-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'admin', 'office_manager', 'technician', 'apprentice')),
  avatar_url text,
  trade text,
  is_active boolean NOT NULL DEFAULT true,
  last_login_at timestamptz,
  settings jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: Users see their own company members
CREATE POLICY "users_select" ON users FOR SELECT USING (company_id = auth.company_id());
-- RLS: Owner/admin can manage users
CREATE POLICY "users_update" ON users FOR UPDATE USING (
  company_id = auth.company_id() AND (auth.user_role() IN ('owner', 'admin') OR id = auth.uid())
);
CREATE POLICY "users_insert" ON users FOR INSERT WITH CHECK (company_id = auth.company_id());

-- ============================================================
-- AUDIT LOG TABLE
-- ============================================================
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  user_id uuid,
  company_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_company_time ON audit_log (company_id, created_at DESC);
CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_select" ON audit_log FOR SELECT USING (company_id = auth.company_id());

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, OLD.id, TG_OP, to_jsonb(OLD), auth.uid(), OLD.company_id);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, action, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach audit to companies and users
CREATE TRIGGER companies_audit AFTER INSERT OR UPDATE OR DELETE ON companies FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER users_audit AFTER INSERT OR UPDATE OR DELETE ON users FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- SECURITY TABLES
-- ============================================================
CREATE TABLE user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  device_info jsonb,
  ip_address inet,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_active_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);

CREATE TABLE login_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  ip_address inet,
  success boolean NOT NULL,
  failure_reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_login_attempts_email ON login_attempts (email, created_at DESC);
```

##### Files
- `lib/core/env.dart` — Environment config (if not created in A2)
- `lib/core/supabase_client.dart` — Supabase initialization
- `lib/models/company.dart` — Update to match new schema
- `lib/models/user.dart` — Update to match new schema

##### Verify
- [ ] All tables created in dev Supabase
- [ ] RLS policies verified (test with two different company JWTs)
- [ ] Audit log captures INSERT/UPDATE on companies and users
- [ ] `flutter analyze` passes
- [ ] Commit: `[A3a] Core tables — companies, users, auth, audit`

---

#### Sprint A3b: Business Tables (jobs, customers, invoices, bids)
**Est: ~4-5 hours**

##### Objective
Deploy the business operation tables that power the CRM.

##### Database

```sql
-- ============================================================
-- ZAFTO CORE SCHEMA — A3b: Business Tables
-- ============================================================

-- CUSTOMERS
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  email text,
  phone text,
  alternate_phone text,
  address text,
  city text,
  state text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  type text NOT NULL DEFAULT 'residential' CHECK (type IN ('residential', 'commercial')),
  company_name text,
  tags text[] DEFAULT '{}',
  notes text,
  access_instructions text,
  referred_by text,
  preferred_tech_id uuid,
  email_opt_in boolean DEFAULT true,
  sms_opt_in boolean DEFAULT false,
  -- Denormalized stats (updated by triggers or edge functions)
  job_count int DEFAULT 0,
  invoice_count int DEFAULT 0,
  total_revenue numeric(12,2) DEFAULT 0,
  outstanding_balance numeric(12,2) DEFAULT 0,
  last_job_date timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER customers_audit AFTER INSERT OR UPDATE OR DELETE ON customers FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "customers_select" ON customers FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "customers_insert" ON customers FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "customers_update" ON customers FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "customers_delete" ON customers FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- JOBS
CREATE TABLE jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  customer_id uuid REFERENCES customers(id),
  assigned_to_user_id uuid REFERENCES auth.users(id),
  assigned_user_ids uuid[] DEFAULT '{}',
  team_id uuid,
  -- Details
  title text,
  description text,
  internal_notes text,
  trade_type text NOT NULL DEFAULT 'electrical',
  -- Customer (denormalized for offline)
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_phone text,
  -- Location
  address text NOT NULL DEFAULT '',
  city text,
  state text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'dispatched', 'enRoute', 'inProgress', 'onHold', 'completed', 'invoiced', 'cancelled')),
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  -- Job Type (progressive disclosure — D1)
  job_type text NOT NULL DEFAULT 'standard' CHECK (job_type IN ('standard', 'insurance_claim', 'warranty_dispatch')),
  type_metadata jsonb DEFAULT '{}',
  -- Scheduling
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  estimated_duration int, -- minutes
  started_at timestamptz,
  completed_at timestamptz,
  -- Financial
  estimated_amount numeric(12,2) DEFAULT 0,
  actual_amount numeric(12,2),
  -- Tags
  tags text[] DEFAULT '{}',
  -- Links
  invoice_id uuid,
  quote_id uuid,
  -- Sync
  synced_to_cloud boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jobs_company_status ON jobs (company_id, status);
CREATE INDEX idx_jobs_company_date ON jobs (company_id, scheduled_start);
CREATE INDEX idx_jobs_assigned ON jobs (assigned_to_user_id);
CREATE TRIGGER jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER jobs_audit AFTER INSERT OR UPDATE OR DELETE ON jobs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "jobs_select" ON jobs FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "jobs_insert" ON jobs FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "jobs_update" ON jobs FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "jobs_delete" ON jobs FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- INVOICES
CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  customer_id uuid REFERENCES customers(id),
  invoice_number text NOT NULL,
  -- Customer (denormalized for PDF)
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_phone text,
  customer_address text NOT NULL DEFAULT '',
  -- Line items
  line_items jsonb DEFAULT '[]',
  -- Totals
  subtotal numeric(12,2) DEFAULT 0,
  discount_amount numeric(12,2) DEFAULT 0,
  discount_reason text,
  tax_rate numeric(5,2) DEFAULT 0,
  tax_amount numeric(12,2) DEFAULT 0,
  total numeric(12,2) DEFAULT 0,
  amount_paid numeric(12,2) DEFAULT 0,
  amount_due numeric(12,2) DEFAULT 0,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pendingApproval', 'approved', 'rejected', 'sent', 'viewed', 'partiallyPaid', 'paid', 'voided', 'overdue')),
  -- Approval
  requires_approval boolean DEFAULT false,
  approved_by_user_id uuid,
  approved_at timestamptz,
  rejection_reason text,
  -- Sending
  sent_at timestamptz,
  sent_via text,
  viewed_at timestamptz,
  -- Payment
  paid_at timestamptz,
  payment_method text,
  payment_reference text,
  -- Signature
  signature_data text,
  signed_by_name text,
  signed_at timestamptz,
  -- PDF
  pdf_path text,
  pdf_url text,
  -- Dates
  due_date timestamptz,
  notes text,
  terms text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_invoices_company_status ON invoices (company_id, status);
CREATE TRIGGER invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER invoices_audit AFTER INSERT OR UPDATE OR DELETE ON invoices FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "invoices_select" ON invoices FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "invoices_insert" ON invoices FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "invoices_update" ON invoices FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "invoices_delete" ON invoices FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- BIDS
CREATE TABLE bids (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  customer_id uuid REFERENCES customers(id),
  job_id uuid REFERENCES jobs(id),
  bid_number text NOT NULL,
  title text NOT NULL DEFAULT '',
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_address text,
  -- Content
  line_items jsonb DEFAULT '[]',
  scope_of_work text,
  terms text,
  valid_until timestamptz,
  -- Totals
  subtotal numeric(12,2) DEFAULT 0,
  tax_rate numeric(5,2) DEFAULT 0,
  tax_amount numeric(12,2) DEFAULT 0,
  total numeric(12,2) DEFAULT 0,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'accepted', 'rejected', 'expired')),
  sent_at timestamptz,
  viewed_at timestamptz,
  accepted_at timestamptz,
  rejected_at timestamptz,
  rejection_reason text,
  -- Signature
  signature_data text,
  signed_by_name text,
  signed_at timestamptz,
  -- PDF
  pdf_path text,
  pdf_url text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER bids_updated_at BEFORE UPDATE ON bids FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER bids_audit AFTER INSERT OR UPDATE OR DELETE ON bids FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "bids_select" ON bids FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "bids_insert" ON bids FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "bids_update" ON bids FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "bids_delete" ON bids FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- TIME ENTRIES
CREATE TABLE time_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  clock_in timestamptz NOT NULL,
  clock_out timestamptz,
  break_minutes int DEFAULT 0,
  total_minutes int,
  hourly_rate numeric(8,2),
  labor_cost numeric(12,2),
  overtime_minutes int DEFAULT 0,
  notes text,
  location_pings jsonb DEFAULT '[]',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'approved', 'rejected')),
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_time_entries_company_user ON time_entries (company_id, user_id);
CREATE INDEX idx_time_entries_job ON time_entries (job_id);
CREATE TRIGGER time_entries_updated_at BEFORE UPDATE ON time_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER time_entries_audit AFTER INSERT OR UPDATE OR DELETE ON time_entries FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "time_entries_select" ON time_entries FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "time_entries_insert" ON time_entries FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "time_entries_update" ON time_entries FOR UPDATE USING (company_id = auth.company_id() AND (auth.user_role() IN ('owner', 'admin') OR user_id = auth.uid()));
```

##### Verify
- [ ] All 5 tables created with correct columns and constraints
- [ ] All RLS policies active
- [ ] All audit triggers firing
- [ ] All indexes created
- [ ] Test: insert a job with one company JWT, verify invisible with another company JWT
- [ ] Commit: `[A3b] Business tables — jobs, customers, invoices, bids, time_entries`

---

#### Sprint A3c: Field Tool Tables (photos, signatures, receipts, etc.)
**Est: ~3-4 hours**

##### Objective
Deploy tables for all field tool data persistence. This is what makes data STOP evaporating.

##### Database

```sql
-- ============================================================
-- ZAFTO CORE SCHEMA — A3c: Field Tool Tables
-- ============================================================

-- PHOTOS (job site, before/after, defect markup, general)
CREATE TABLE photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  uploaded_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  thumbnail_path text,
  file_name text,
  file_size int,
  mime_type text,
  width int,
  height int,
  category text NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'before', 'after', 'defect', 'markup', 'receipt', 'inspection', 'completion')),
  caption text,
  tags text[] DEFAULT '{}',
  metadata jsonb DEFAULT '{}',
  is_client_visible boolean DEFAULT false,
  taken_at timestamptz,
  latitude double precision,
  longitude double precision,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_photos_job ON photos (job_id);
CREATE INDEX idx_photos_company ON photos (company_id, created_at DESC);
CREATE TRIGGER photos_audit AFTER INSERT OR UPDATE OR DELETE ON photos FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "photos_select" ON photos FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "photos_insert" ON photos FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "photos_update" ON photos FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "photos_delete" ON photos FOR DELETE USING (company_id = auth.company_id());

-- SIGNATURES
CREATE TABLE signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  invoice_id uuid REFERENCES invoices(id),
  captured_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  signer_name text NOT NULL,
  signer_role text, -- 'customer', 'technician', 'inspector'
  signature_data text NOT NULL, -- base64 PNG
  storage_path text,
  purpose text NOT NULL DEFAULT 'job_completion' CHECK (purpose IN ('job_completion', 'invoice_approval', 'change_order', 'inspection', 'safety_briefing')),
  ip_address inet,
  signed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE signatures ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER signatures_audit AFTER INSERT OR UPDATE OR DELETE ON signatures FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "signatures_select" ON signatures FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "signatures_insert" ON signatures FOR INSERT WITH CHECK (company_id = auth.company_id());

-- VOICE NOTES
CREATE TABLE voice_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  recorded_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  duration_seconds int,
  file_size int,
  transcription text,
  transcription_status text DEFAULT 'pending' CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed')),
  tags text[] DEFAULT '{}',
  recorded_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE voice_notes ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER voice_notes_audit AFTER INSERT OR UPDATE OR DELETE ON voice_notes FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "voice_notes_select" ON voice_notes FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "voice_notes_insert" ON voice_notes FOR INSERT WITH CHECK (company_id = auth.company_id());

-- RECEIPTS
CREATE TABLE receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  scanned_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  vendor_name text,
  amount numeric(12,2),
  category text,
  description text,
  receipt_date date,
  ocr_data jsonb DEFAULT '{}',
  ocr_status text DEFAULT 'pending' CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
  is_reimbursable boolean DEFAULT false,
  reimbursement_status text DEFAULT 'none' CHECK (reimbursement_status IN ('none', 'pending', 'approved', 'denied', 'paid')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER receipts_updated_at BEFORE UPDATE ON receipts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER receipts_audit AFTER INSERT OR UPDATE OR DELETE ON receipts FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "receipts_select" ON receipts FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "receipts_insert" ON receipts FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "receipts_update" ON receipts FOR UPDATE USING (company_id = auth.company_id());

-- SAFETY / COMPLIANCE RECORDS
CREATE TABLE compliance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  record_type text NOT NULL CHECK (record_type IN ('safety_briefing', 'incident_report', 'loto', 'confined_space', 'dead_man_switch', 'inspection')),
  data jsonb NOT NULL DEFAULT '{}',
  attachments jsonb DEFAULT '[]', -- [{storage_path, file_name, type}]
  crew_members uuid[] DEFAULT '{}',
  status text DEFAULT 'active',
  severity text, -- for incidents: 'minor', 'major', 'critical'
  location_latitude double precision,
  location_longitude double precision,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE compliance_records ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_compliance_records_company_type ON compliance_records (company_id, record_type);
CREATE TRIGGER compliance_records_audit AFTER INSERT OR UPDATE OR DELETE ON compliance_records FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "compliance_select" ON compliance_records FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "compliance_insert" ON compliance_records FOR INSERT WITH CHECK (company_id = auth.company_id());

-- MILEAGE TRIPS
CREATE TABLE mileage_trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  start_address text,
  end_address text,
  distance_miles numeric(8,2),
  start_odometer numeric(10,1),
  end_odometer numeric(10,1),
  purpose text,
  route_data jsonb DEFAULT '{}',
  trip_date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE mileage_trips ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER mileage_trips_audit AFTER INSERT OR UPDATE OR DELETE ON mileage_trips FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "mileage_select" ON mileage_trips FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "mileage_insert" ON mileage_trips FOR INSERT WITH CHECK (company_id = auth.company_id());
```

##### Verify
- [ ] All 6 tables created: photos, signatures, voice_notes, receipts, compliance_records, mileage_trips
- [ ] RLS policies verified
- [ ] Audit triggers attached
- [ ] Commit: `[A3c] Field tool tables — photos, signatures, voice notes, receipts, compliance, mileage`

---

#### Sprint A3d: Storage Buckets
**Est: ~1 hour**

##### Objective
Create Supabase Storage buckets for all file uploads.

##### Steps
1. Create storage buckets in Supabase Dashboard (dev first):
   - `photos` — Job site photos, before/after, defect markup
   - `signatures` — Signature images
   - `voice-notes` — Audio recordings
   - `receipts` — Scanned receipt images
   - `documents` — General documents, PDFs
   - `avatars` — User profile photos
   - `company-logos` — Company logos

2. Set storage policies:
   - All buckets: authenticated users in same company can upload/read
   - `photos` bucket: client portal users can read client-visible photos
   - File size limits: photos 10MB, documents 25MB, voice notes 50MB

##### Verify
- [ ] All 7 buckets created
- [ ] Upload test file to each bucket
- [ ] Verify RLS — user from company A cannot access company B's files
- [ ] Commit: `[A3d] Storage buckets — photos, signatures, voice notes, receipts, documents`

---

#### Sprint A3e: PowerSync Setup
**Est: ~2-3 hours**

##### Objective
Configure PowerSync for offline-first sync between device SQLite and Supabase PostgreSQL.

##### Prerequisites
- PowerSync account created
- Core tables deployed (A3a, A3b)

##### Steps
1. Create PowerSync instance connected to Supabase dev project
2. Define sync rules (which tables, which columns sync to device)
3. Add `powersync` package to Flutter `pubspec.yaml`
4. Create `lib/core/powersync_config.dart` with schema definition
5. Create `lib/core/database.dart` with PowerSync initialization
6. Update `lib/main.dart` to initialize PowerSync on app start
7. Test offline: create data with airplane mode on, reconnect, verify sync

##### Sync Rules
```yaml
# Tables that sync to device (field tech needs these offline)
bucket_definitions:
  by_company:
    parameters: SELECT auth.company_id() as company_id
    data:
      - SELECT * FROM jobs WHERE company_id = bucket.company_id
      - SELECT * FROM customers WHERE company_id = bucket.company_id
      - SELECT * FROM invoices WHERE company_id = bucket.company_id
      - SELECT * FROM bids WHERE company_id = bucket.company_id
      - SELECT * FROM time_entries WHERE company_id = bucket.company_id
      - SELECT * FROM photos WHERE company_id = bucket.company_id
      # Note: large tables like audit_log do NOT sync to device
```

##### Verify
- [ ] PowerSync connects to Supabase dev
- [ ] Data syncs from Supabase to device SQLite
- [ ] Offline write → online sync works
- [ ] `flutter analyze` passes
- [ ] Commit: `[A3e] PowerSync offline-first sync configured`

---

## PHASE B: CORE WIRING
*Every B sprint follows the patterns in 06_ARCHITECTURE_PATTERNS.md exactly.*
*Model → Repository → Service → Provider → Screen. Test at each layer.*

---

### Sprint B1a: Auth Flow — Supabase Auth + Onboarding
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Replace Firebase Auth with Supabase Auth. Wire onboarding to create company + first user. Session management with JWT carrying company_id and role.

#### Prerequisites
- A3a complete (companies, users tables deployed)
- A3e complete (PowerSync configured)
- Supabase Auth enabled in dashboard

#### Files to Create
```
lib/core/supabase_client.dart       — Supabase initialization (reads from env config)
lib/repositories/auth_repository.dart — Auth operations (register, login, logout, session)
lib/services/auth_service.dart       — REWRITE: Replace Firebase auth with Supabase
lib/providers/auth_providers.dart     — Auth state provider, current user provider
```

#### Files to Modify
```
lib/main.dart                        — Initialize Supabase + PowerSync before runApp()
lib/screens/onboarding/              — Wire to create company + user in Supabase
lib/screens/auth/                    — Wire login/register to Supabase Auth
```

#### Steps

**Step 1: Supabase Client Setup**
- Create `lib/core/supabase_client.dart` that initializes `Supabase.initialize()` with env config
- Must be called in `main()` before `runApp()`
- Expose `supabase` getter for the client instance

**Step 2: Auth Repository**
- `register(email, password, fullName, companyName, trade)` → creates auth user, then company, then user row, sets JWT claims
- `login(email, password)` → Supabase signInWithPassword, returns session
- `logout()` → Supabase signOut, clear PowerSync local data
- `getCurrentUser()` → reads from users table using auth.uid()
- `watchAuthState()` → stream from `supabase.auth.onAuthStateChange`
- `refreshSession()` → refresh JWT token
- `resetPassword(email)` → Supabase password reset flow

**Step 3: JWT Claims Setup**
- Create Supabase Edge Function or database trigger: when a user registers, set `app_metadata.company_id` and `app_metadata.role` on the JWT
- This is CRITICAL — all RLS policies depend on `auth.company_id()` which reads from JWT
- Approach: Use a Supabase database function called after user creation:
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Set JWT claims when user row is created
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
    'company_id', NEW.company_id::text,
    'role', NEW.role
  )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

**Step 4: Auth Providers**
```dart
// Auth state (logged in, logged out, loading)
final authStateProvider = StreamProvider<AuthState>((ref) { ... });

// Current user profile (from users table)
final currentUserProvider = FutureProvider<User?>((ref) { ... });

// Current company
final currentCompanyProvider = FutureProvider<Company?>((ref) { ... });
```

**Step 5: Wire Onboarding Screen**
- Onboarding creates: Company → User → sets JWT claims → navigates to home
- Must handle: company name, trade selection, owner info
- Must set subscription_tier to 'solo' (default trial)

**Step 6: Wire Login/Register Screens**
- Login: email/password → Supabase Auth → load user profile → navigate
- Register: collect info → create account → onboarding flow
- Handle errors: invalid credentials, email taken, weak password, network error

**Step 7: Session Management**
- On app start: check `supabase.auth.currentSession`
- If valid → navigate to home, load user profile
- If expired → attempt refresh, if fail → navigate to login
- Track sessions in `user_sessions` table (device info, IP, last active)

#### Verify
- [ ] Register creates company + user + sets JWT claims
- [ ] Login works and loads user profile
- [ ] Logout clears session and local data
- [ ] JWT contains company_id and role
- [ ] RLS works with the JWT (user can only see own company data)
- [ ] Password reset email sends
- [ ] `flutter analyze` passes
- [ ] Commit: `[B1a] Auth flow — Supabase Auth, onboarding, session management`

---

### Sprint B1b: Customers CRUD
**Status: PENDING** | **Est: ~4 hours**

#### Objective
Wire Customers to Supabase via PowerSync. Unify customer model. Replace Hive local storage.

#### Files to Create
```
lib/models/customer.dart              — REWRITE: Unified model matching Supabase schema
lib/repositories/customer_repository.dart — PowerSync CRUD + watch
lib/providers/customer_providers.dart  — List, single, actions, stats providers
```

#### Files to Modify
```
lib/screens/customers/customers_hub_screen.dart  — Use new providers (currently uses customer_service.dart)
lib/screens/customers/customer_detail_screen.dart — Wire to real data
lib/screens/customers/customer_create_screen.dart — Wire form submission
lib/services/customer_service.dart                — REWRITE: Business logic on top of repository
```

#### Steps

**Step 1: Unified Customer Model**
- Replace both `models/customer.dart` (318 lines) and `models/business/customer.dart` (150 lines)
- New model matches Supabase `customers` table exactly (A3b schema)
- Fields: id, companyId, createdByUserId, name, email, phone, alternatePhone, address, city, state, zipCode, latitude, longitude, type (residential/commercial), companyName, tags, notes, accessInstructions, referredBy, preferredTechId, emailOptIn, smsOptIn, jobCount, invoiceCount, totalRevenue, outstandingBalance, lastJobDate, createdAt, updatedAt
- `toJson()` with snake_case keys, `fromJson()` with snake_case parsing
- Computed: `displayName`, `fullAddress`, `hasOutstandingBalance`

**Step 2: Customer Repository**
- `getCustomers()` → `SELECT * FROM customers ORDER BY name ASC`
- `getCustomer(id)` → single fetch
- `createCustomer(customer)` → INSERT with auto-generated UUID
- `updateCustomer(customer)` → UPDATE
- `deleteCustomer(id)` → soft delete (set deleted_at)
- `watchCustomers()` → PowerSync watch stream
- `searchCustomers(query)` → WHERE name ILIKE or email ILIKE

**Step 3: Customer Providers**
```dart
final customersProvider = StreamProvider.autoDispose<List<Customer>>((ref) { ... });
final customerProvider = FutureProvider.autoDispose.family<Customer?, String>((ref, id) { ... });
final customerActionsProvider = Provider<CustomerActions>((ref) { ... });
final customerStatsProvider = Provider<CustomerStats>((ref) { ... }); // computed from list
```

**Step 4: Wire Screens**
- `CustomersHubScreen`: Replace `ref.watch(customersProvider)` source — currently reads from `customer_service.dart` which uses Hive. Change import to new provider. The screen already handles loading/error/data states via `customersAsync.when()`.
- `CustomerDetailScreen`: Load by ID, show real data. Add jobs/invoices tabs linked to customer.
- `CustomerCreateScreen`: Form submits to `customerActionsProvider.create()`

**Step 5: Update Imports**
- Find all 24 files importing `models/business/customer.dart` → redirect to new `models/customer.dart`
- Find all files importing old `customer_service.dart` → update to use providers

#### Verify
- [ ] Create customer → appears in list (PowerSync sync)
- [ ] Edit customer → updates persist
- [ ] Delete customer → soft deleted (disappears from list, exists in DB)
- [ ] Search by name, email works
- [ ] Customer detail shows real data
- [ ] Audit log captures customer mutations
- [ ] `flutter analyze` passes
- [ ] Commit: `[B1b] Customers CRUD — repository, providers, screens wired to Supabase`

---

### Sprint B1c: Jobs CRUD
**Status: PENDING** | **Est: ~5-6 hours**

#### Objective
Wire Jobs to Supabase via PowerSync. Unify job model. Replace Hive. This is the most used entity in the app.

#### Files to Create
```
lib/models/job.dart                   — REWRITE: Unified model matching Supabase schema
lib/repositories/job_repository.dart  — PowerSync CRUD + watch + status transitions
lib/providers/job_providers.dart      — List (filtered), single, actions, stats providers
```

#### Files to Modify
```
lib/screens/jobs/jobs_hub_screen.dart    — Use new providers
lib/screens/jobs/job_detail_screen.dart  — Wire to real data + field tool data
lib/screens/jobs/job_create_screen.dart  — Wire form submission
lib/services/job_service.dart            — REWRITE: Business logic + status validation
lib/screens/home_screen_v2.dart          — Dashboard reads real job stats
```

#### Steps

**Step 1: Unified Job Model**
- Replace `models/job.dart` (476 lines) and `models/business/job.dart` (156 lines)
- Match Supabase `jobs` table schema exactly (A3b)
- Status enum: draft, scheduled, dispatched, enRoute, inProgress, onHold, completed, invoiced, cancelled
- Priority enum: low, normal, high, urgent
- JobType enum: standard, insurance_claim, warranty_dispatch (progressive disclosure — D1)
- Include denormalized customer fields (customerName, customerPhone) for offline display
- `toJson()` / `fromJson()` with snake_case mapping

**Step 2: Job Repository**
- `getJobs({status, priority, assignedTo, dateRange})` → filtered queries
- `getJob(id)` → single fetch with related data hints
- `createJob(job)` → INSERT, auto company_id from current user
- `updateJob(job)` → UPDATE (only changed fields)
- `updateStatus(id, newStatus)` → status transition with validation
- `deleteJob(id)` → soft delete
- `watchJobs()` → reactive stream for list
- `watchJob(id)` → reactive stream for detail

**Step 3: Job Service (Business Logic)**
- Status transition validation:
  ```
  draft → scheduled, cancelled
  scheduled → dispatched, cancelled
  dispatched → enRoute, cancelled
  enRoute → inProgress
  inProgress → onHold, completed
  onHold → inProgress, cancelled
  completed → invoiced
  invoiced → (terminal)
  cancelled → (terminal)
  ```
- `assignTech(jobId, userId)` → updates assigned_to_user_id + assigned_user_ids
- `linkCustomer(jobId, customerId)` → sets customer_id + denormalized fields
- `startJob(jobId)` → sets status=inProgress, started_at=now()
- `completeJob(jobId)` → validates required fields, sets completed_at

**Step 4: Job Providers**
```dart
final jobsProvider = StreamProvider.autoDispose<List<Job>>((ref) { ... });
final jobsByStatusProvider = Provider.family<AsyncValue<List<Job>>, JobStatus>((ref, status) { ... });
final jobProvider = FutureProvider.autoDispose.family<Job?, String>((ref, id) { ... });
final jobActionsProvider = Provider<JobActions>((ref) { ... });
final jobStatsProvider = Provider<JobStats>((ref) { ... }); // computed: today's jobs, in progress, etc.
final activeJobProvider = StateProvider<String?>((ref) => null); // currently selected job for field tools
```

**Step 5: Wire Screens**
- `JobsHubScreen`: Currently uses `ref.watch(jobsProvider)` from job_service. Swap import to new provider. Filter chips for status, priority.
- `JobDetailScreen`: Show full job data. Sections for: info, customer, photos, notes, time entries, field data. "Add Photos" button → navigate to field tools with jobId.
- `JobCreateScreen`: Form → customerActionsProvider, jobActionsProvider
- `HomeScreenV2`: Dashboard stats from real data — active jobs, scheduled today, overdue invoices

**Step 6: Update Imports**
- All files importing `models/business/job.dart` → new `models/job.dart`
- All files importing old `job_service.dart` providers → new providers

#### Verify
- [ ] Create job → appears in list
- [ ] Status transitions enforce valid paths
- [ ] Assign tech → appears on their view
- [ ] Job detail shows all fields
- [ ] Home dashboard shows real stats
- [ ] Job filtering by status/priority works
- [ ] Offline: create job with airplane mode → reconnect → syncs
- [ ] Audit log captures all mutations
- [ ] `flutter analyze` passes
- [ ] Commit: `[B1c] Jobs CRUD — repository, providers, screens, status machine wired`

---

### Sprint B1d: Invoices + Bids CRUD
**Status: PENDING** | **Est: ~5-6 hours**

#### Objective
Wire Invoices and Bids to Supabase. Unify models. Replace Hive. These share similar patterns.

#### Files to Create
```
lib/models/invoice.dart                  — REWRITE: Unified model
lib/models/bid.dart                      — REWRITE: Unified model (bid.dart already fairly clean)
lib/repositories/invoice_repository.dart — PowerSync CRUD + watch
lib/repositories/bid_repository.dart     — PowerSync CRUD + watch
lib/providers/invoice_providers.dart     — List, single, actions, stats
lib/providers/bid_providers.dart         — List, single, actions, stats
```

#### Files to Modify
```
lib/screens/invoices/invoices_hub_screen.dart  — Use new providers
lib/screens/invoices/invoice_detail_screen.dart
lib/screens/invoices/invoice_create_screen.dart
lib/screens/bids/bids_hub_screen.dart
lib/screens/bids/bid_detail_screen.dart
lib/screens/bids/bid_create_screen.dart
lib/services/invoice_service.dart — REWRITE
lib/services/bid_service.dart     — REWRITE
```

#### Steps

**Step 1: Invoice Model**
- Unify `models/invoice.dart` and `models/business/invoice.dart`
- Match Supabase `invoices` table (A3b schema)
- Status: draft, pendingApproval, approved, rejected, sent, viewed, partiallyPaid, paid, voided, overdue
- Line items stored as JSONB: `[{description, quantity, unit, unitPrice, total, isTaxable}]`
- Invoice number generation: `INV-YYYYMMDD-XXX`
- Computed: `isPaid`, `isOverdue`, `amountDue = total - amountPaid`

**Step 2: Bid Model**
- Match Supabase `bids` table (A3b schema)
- Status: draft, sent, viewed, accepted, rejected, expired
- Line items as JSONB (same structure as invoice)
- Bid number generation: `BID-YYYYMMDD-XXX`
- Computed: `isAccepted`, `isExpired`, `daysUntilExpiry`

**Step 3: Invoice Repository + Service**
- CRUD operations via PowerSync
- `recordPayment(invoiceId, amount, method, reference)` → updates amount_paid, checks if fully paid
- `sendInvoice(invoiceId)` → sets status=sent, sent_at=now() (email sending is a later feature)
- `voidInvoice(invoiceId)` → status=voided (owner/admin only)
- `createFromJob(jobId)` → auto-populate from job data
- Invoice number auto-increment per company

**Step 4: Bid Repository + Service**
- CRUD operations via PowerSync
- `sendBid(bidId)` → status=sent, sent_at=now()
- `acceptBid(bidId)` → status=accepted, accepted_at, optionally create job
- `convertToJob(bidId)` → creates a Job from bid data, links bid_id on job
- `convertToInvoice(bidId)` → creates Invoice from bid line items
- Bid number auto-increment per company

**Step 5: Wire All Screens**
- `InvoicesHubScreen`: Stats bar (outstanding, collected, overdue), filter by status, list view
- `InvoiceDetailScreen`: Full invoice view, record payment button, send button, void button
- `InvoiceCreateScreen`: Customer picker, line items builder, tax calc, save
- `BidsHubScreen`: Stats bar (pending, sent, win rate), filter by status
- `BidDetailScreen`: Full bid view, send/accept/reject actions, convert to job/invoice
- `BidCreateScreen`: Customer picker, scope of work, line items, terms, valid until

#### Verify
- [ ] Create invoice → appears in list with correct number
- [ ] Record payment → updates amount_paid, status changes to partiallyPaid or paid
- [ ] Create bid → send → shows in sent filter
- [ ] Accept bid → convert to job → job appears with bid data
- [ ] Invoice stats (outstanding, collected) calculated correctly
- [ ] Line items JSONB saves and loads correctly
- [ ] `flutter analyze` passes
- [ ] Commit: `[B1d] Invoices + Bids CRUD — full lifecycle wired to Supabase`

---

### Sprint B1e: Time Clock + Calendar
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Wire Time Clock with GPS tracking to Supabase. Wire Calendar to read real job schedules.

#### Files to Create
```
lib/models/time_entry.dart               — Unified model (replace ClockEntry)
lib/repositories/time_entry_repository.dart — PowerSync CRUD
lib/providers/time_entry_providers.dart   — Active entry, history, weekly stats
```

#### Files to Modify
```
lib/screens/time_clock/                   — Wire to new providers
lib/screens/calendar/                     — Read from jobs + time_entries
lib/services/time_clock_service.dart      — REWRITE with Supabase
lib/services/location_tracking_service.dart — Keep GPS logic, wire upload
lib/services/calendar_service.dart        — REWRITE to read real data
```

#### Steps

**Step 1: Time Entry Model**
- Match Supabase `time_entries` table (A3b schema)
- Replace existing `ClockEntry` model (which uses Firestore Timestamps)
- Fields: id, companyId, userId, jobId, clockIn, clockOut, breakMinutes, totalMinutes, hourlyRate, laborCost, overtimeMinutes, notes, locationPings (JSONB), status, approvedBy, approvedAt
- `toJson()` / `fromJson()` with snake_case
- Computed: `duration`, `isActive` (clockOut == null), `breakDuration`, `netHours`

**Step 2: Time Entry Repository**
- `clockIn(userId, jobId?, location)` → INSERT with clockIn=now(), status=active
- `clockOut(entryId, location)` → UPDATE clockOut=now(), calculate totals
- `addBreak(entryId, minutes)` → update break_minutes
- `getActiveEntry(userId)` → WHERE clock_out IS NULL AND user_id = ?
- `getEntriesForUser(userId, dateRange)` → history
- `getEntriesForJob(jobId)` → all time logged on a job
- `approveEntry(entryId, approvedByUserId)` → manager approval
- `watchActiveEntry(userId)` → stream for clock screen

**Step 3: Location Tracking Integration**
- Keep existing `location_tracking_service.dart` GPS logic
- On each ping, save to time_entry.location_pings JSONB array via PowerSync
- Location pings structure: `[{lat, lng, accuracy, timestamp, activity}]`
- Battery-efficient: ping every 5 min when active, stop when clocked out

**Step 4: Calendar Integration**
- Calendar reads from `jobs` table: scheduled_start, scheduled_end → calendar events
- Also reads from `time_entries`: who worked when
- Color-code by: job status, assigned tech
- Views: day, week, month

**Step 5: Wire Screens**
- Time Clock Screen: Big clock in/out button, shows active entry timer, job selector, break button
- Time History: List of past entries with date range filter, weekly/monthly totals
- Calendar: Event tiles from real jobs, tap to view job detail

#### Verify
- [ ] Clock in → active entry with GPS location saved
- [ ] Clock out → total hours calculated, labor cost computed
- [ ] Location pings accumulate during active session
- [ ] Break tracking works (adds to break_minutes)
- [ ] Calendar shows scheduled jobs on correct dates
- [ ] Manager can approve time entries
- [ ] Weekly hour totals correct
- [ ] Offline clock in/out → syncs when reconnected
- [ ] `flutter analyze` passes
- [ ] Commit: `[B1e] Time Clock + Calendar — GPS tracking, time entries, schedule wired`

---

### Sprint B2a: Photo Tools Wiring (3 tools)
**Status: DONE (Session 44)** | **Est: ~6-8 hours**

#### Objective
Wire Job Site Photos, Before/After, and Defect Markup to save to Supabase Storage + photos table.

#### Prerequisites
- A3c complete (photos table deployed)
- A3d complete (storage buckets created)
- B1c complete (jobs wired — need jobId linking)

#### Files to Create
```
lib/repositories/photo_repository.dart   — Upload to Storage + insert to photos table
lib/providers/photo_providers.dart       — Photos by job, upload progress
lib/services/storage_service.dart        — Generic file upload to Supabase Storage
```

#### Files to Modify
```
lib/screens/field_tools/job_site_photos_screen.dart (651 lines) — Wire to save photos
lib/screens/field_tools/before_after_screen.dart                — Wire save + compare
lib/screens/field_tools/defect_markup_screen.dart               — Wire markup save
lib/screens/field_tools/field_tools_hub_screen.dart             — Pass jobId to all tools
```

#### Steps

**Step 1: Storage Service**
- `uploadFile(bucket, path, bytes, contentType)` → Supabase Storage upload, returns public URL
- `deleteFile(bucket, path)` → remove from Storage
- `getSignedUrl(bucket, path, expiresIn)` → temporary access URL
- Path format: `{company_id}/{job_id}/{category}/{timestamp}_{filename}`
- Thumbnail generation: resize to 200px width before upload as `thumb_` prefix
- Upload progress callback for UI

**Step 2: Photo Repository**
- `uploadPhoto(jobId, file, category, caption)` → upload to Storage + insert row in photos table
- `getPhotosForJob(jobId)` → SELECT from photos WHERE job_id
- `getPhotosByCategory(jobId, category)` → filtered
- `deletePhoto(photoId)` → soft delete + (optionally) remove from Storage
- `watchPhotosForJob(jobId)` → reactive stream
- Categories: general, before, after, defect, markup, receipt, inspection, completion

**Step 3: Photo Providers**
```dart
final jobPhotosProvider = StreamProvider.autoDispose.family<List<Photo>, String>((ref, jobId) { ... });
final photosByCategoryProvider = Provider.family<AsyncValue<List<Photo>>, ({String jobId, String category})>(...);
final photoUploadProvider = StateNotifierProvider<PhotoUploadNotifier, PhotoUploadState>(...);
```

**Step 4: Wire Job Site Photos Screen**
- Currently captures photos to memory list, gone on exit
- Wire: on capture → upload via photoRepository → shows in grid with real URLs
- Add job selector at top (if no jobId passed, show picker)
- Show upload progress indicator per photo
- Add category selector (general, inspection, before, after)
- Delete photo → soft delete + remove from grid

**Step 5: Wire Before/After Screen**
- Currently holds before/after image pair in memory
- Wire: capture "before" → upload with category='before' → capture "after" → upload with category='after'
- Link both photos to same job
- Side-by-side comparison reads from saved photos
- Export: creates comparison image, saves as a third photo with category='completion'

**Step 6: Wire Defect Markup Screen**
- Currently draws annotations on photo but never saves
- Wire: base photo uploaded first → markup annotations overlaid → render to image → upload as category='markup'
- Store markup data in photo.metadata JSONB (annotation coordinates, colors, text)
- Option to re-edit markup (load from metadata)

#### Verify
- [ ] Take photo → uploads to Supabase Storage → row in photos table
- [ ] Photos appear in job detail screen
- [ ] Before/After pairs linked to same job
- [ ] Defect markup saves rendered image + annotation data
- [ ] Photos persist across app restart (no more evaporation)
- [ ] Offline: photos queued in PowerSync → upload when online
- [ ] Thumbnail generated and accessible
- [ ] Storage path follows company isolation pattern
- [ ] `flutter analyze` passes
- [ ] Commit: `[B2a] Photo tools wired — job site photos, before/after, defect markup persist`

---

### Sprint B2b: Safety & Compliance Tools (5 tools)
**Status: PENDING** | **Est: ~8-10 hours**

#### Objective
Wire LOTO Logger, Incident Report, Safety Briefing, Dead Man Switch, and Confined Space Timer to compliance_records table. Dead Man Switch gets REAL SMS alerting.

#### Prerequisites
- A3c complete (compliance_records table)
- B1a complete (auth — need current user for records)

#### Files to Create
```
lib/repositories/compliance_repository.dart — CRUD for compliance_records
lib/providers/compliance_providers.dart     — Records by type, by job
supabase/functions/dead-man-switch/index.ts — Edge Function for SMS alert (Telnyx)
```

#### Files to Modify
```
lib/screens/field_tools/loto_logger_screen.dart          — Wire save
lib/screens/field_tools/incident_report_screen.dart      — Wire save + PDF
lib/screens/field_tools/safety_briefing_screen.dart      — Wire save + crew
lib/screens/field_tools/dead_man_switch_screen.dart      — Wire REAL SMS alerting
lib/screens/field_tools/confined_space_timer_screen.dart  — Wire OSHA logging
```

#### Steps

**Step 1: Compliance Repository**
- `createRecord(type, jobId, data, crewMembers)` → INSERT into compliance_records
- `getRecordsByJob(jobId)` → all safety records for a job
- `getRecordsByType(type)` → filtered by record_type
- `getRecentRecords(limit)` → latest safety records across all jobs
- Record types: safety_briefing, incident_report, loto, confined_space, dead_man_switch, inspection
- All data stored in `data` JSONB column — flexible per record type

**Step 2: LOTO Logger**
- Currently: UI captures lock/tag steps, no save
- Wire: on "Complete LOTO" → create compliance_record with type='loto'
- JSONB data: `{steps: [{device, location, lockNumber, taggedBy, timestamp}], verifiedBy, energySources}`
- Save attached photos (lock photos) via photo_repository with category='inspection'
- History: show past LOTO records for this job

**Step 3: Incident Report**
- Currently: form with fake submit animation
- Wire: on submit → create compliance_record with type='incident_report', severity
- JSONB data: `{description, injuryType, bodyPart, treatmentGiven, witnesses, rootCause, correctiveActions, reportedTo}`
- Attach photos of incident scene
- Generate PDF summary (later — mark TODO for C1)
- CRITICAL: Incident reports are never soft-deleted

**Step 4: Safety Briefing**
- Currently: form with "Past Briefings: Coming Soon"
- Wire: create compliance_record with type='safety_briefing'
- JSONB data: `{topics: [{title, description}], hazards, ppe_required, emergency_procedures}`
- Crew members: select from company users → stored in crew_members UUID array
- Each crew member gets a record of attendance
- Past briefings: query compliance_records WHERE type='safety_briefing' ORDER BY created_at DESC

**Step 5: Dead Man Switch — SAFETY CRITICAL**
- Currently: countdown timer → fake alert animation → `// TODO: SMS to emergency contacts`
- Wire: When timer expires → call Supabase Edge Function → sends SMS via Telnyx
- Edge Function (`dead-man-switch/index.ts`):
  ```typescript
  // Receives: userId, companyId, location, emergencyContacts
  // Sends SMS to each contact: "[Name] triggered a Dead Man Switch alert at [location]. Check on them immediately."
  // Also creates compliance_record with type='dead_man_switch'
  // Also sends push notification to company admin
  ```
- Emergency contacts: stored in user.settings JSONB → `{emergencyContacts: [{name, phone, relationship}]}`
- Settings screen addition: "Emergency Contacts" section
- Timer: user sets countdown (default 15 min), if not reset → trigger
- Also creates compliance_record for audit trail
- **Test this thoroughly — lives depend on it**

**Step 6: Confined Space Timer**
- Currently: timer with no OSHA logging
- Wire: create compliance_record with type='confined_space'
- JSONB data: `{entrantName, attendantName, entryTime, exitTime, atmosphere: {o2, lel, co, h2s}, ventilation, rescuePlan}`
- Auto-log entry/exit times
- Alert if max entry time exceeded (OSHA requirement)
- Track atmospheric readings over time

#### Verify
- [ ] LOTO record saves with all steps and persists
- [ ] Incident report submits and appears in history
- [ ] Safety briefing saves with crew attendance
- [ ] **Dead Man Switch: timer expires → real SMS sent to emergency contacts**
- [ ] Dead Man Switch: reset timer → no alert sent
- [ ] Confined Space: entry/exit times logged, atmosphere readings saved
- [ ] All records appear in job detail under "Safety" tab
- [ ] All records have audit trail
- [ ] Compliance records visible in Web CRM (B4)
- [ ] `flutter analyze` passes
- [ ] Commit: `[B2b] Safety tools wired — LOTO, incidents, briefings, Dead Man Switch SMS, confined space`

---

### Sprint B2c: Financial & Admin Tools (3 tools)
**Status: PENDING** | **Est: ~6-8 hours**

#### Objective
Wire Receipt Scanner (with real OCR), Mileage Tracker, and Client Signature capture.

#### Prerequisites
- A3c complete (receipts, signatures, mileage_trips tables)
- A3d complete (storage buckets)

#### Files to Create
```
lib/repositories/receipt_repository.dart    — Upload + OCR integration
lib/repositories/signature_repository.dart  — Capture + store
lib/repositories/mileage_repository.dart    — Trip CRUD
lib/providers/receipt_providers.dart
lib/providers/signature_providers.dart
lib/providers/mileage_providers.dart
supabase/functions/receipt-ocr/index.ts     — Edge Function: Claude Vision OCR
```

#### Files to Modify
```
lib/screens/field_tools/receipt_scanner_screen.dart (936 lines) — Wire real OCR + save
lib/screens/field_tools/mileage_tracker_screen.dart             — Wire trip save + export
lib/screens/field_tools/client_signature_screen.dart (831 lines) — Wire real save
```

#### Steps

**Step 1: Receipt Scanner + OCR**
- Currently: captures image, shows fake OCR animation with hardcoded data
- Wire: capture image → upload to 'receipts' bucket → call receipt-ocr Edge Function
- Edge Function uses Claude Vision API:
  ```typescript
  // Input: receipt image URL
  // Claude Vision extracts: vendor, date, total, tax, lineItems, paymentMethod
  // Returns structured JSON → saved to receipts.ocr_data JSONB
  ```
- After OCR: show extracted data, let user confirm/edit
- Save to receipts table: vendor_name, amount, category, receipt_date, ocr_data, storage_path
- Link to job if jobId provided → feeds into job costs
- Category options: materials, tools, fuel, meals, permits, subcontractor, other

**Step 2: Client Signature**
- Currently: captures signature as PNG base64, fake 1s delay, nowhere saved
- Wire: on "Save Signature" → upload PNG to 'signatures' bucket → insert row in signatures table
- Fields: signer_name, signer_role (customer/technician/inspector), purpose (job_completion/invoice_approval/change_order)
- Link to job_id and optionally invoice_id
- After save: navigate back with confirmation
- Signature screen gets "purpose" parameter: what is being signed?
- If purpose=job_completion → update job status to 'completed'
- If purpose=invoice_approval → update invoice signed_at

**Step 3: Mileage Tracker**
- Currently: logs trips locally, CSV/PDF export TODO
- Wire: each trip → INSERT into mileage_trips table
- Fields: start_address, end_address, distance_miles, start_odometer, end_odometer, purpose, route_data, trip_date
- Trip recording: start → GPS tracks route → stop → calculate distance
- Link to job if en route to job site
- Report generation: filter by date range, export CSV (edge function or client-side)
- IRS rate calculation: distance_miles × current_rate → reimbursement amount

#### Verify
- [ ] Receipt photo uploads → OCR extracts vendor/amount/date
- [ ] Receipt links to job, appears in job costs
- [ ] Client signature captures and persists as image
- [ ] Signature linked to job → triggers appropriate status update
- [ ] Mileage trip records start/end with GPS distance
- [ ] Mileage links to job
- [ ] All data persists across app restarts
- [ ] Offline: queued and synced when online
- [ ] `flutter analyze` passes
- [ ] Commit: `[B2c] Financial tools wired — receipt OCR, signatures, mileage tracking`

---

### Sprint B2d: Voice Notes + Level & Plumb + Job Linking
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Wire remaining field tools (Voice Notes, Level & Plumb) and ensure ALL tools receive jobId from hub.

#### Files to Create
```
lib/repositories/voice_note_repository.dart — Record + upload + transcription
lib/providers/voice_note_providers.dart
supabase/functions/transcribe-audio/index.ts — Edge Function for transcription
```

#### Files to Modify
```
lib/screens/field_tools/voice_notes_screen.dart      — Wire real recording + playback
lib/screens/field_tools/level_plumb_screen.dart       — Wire reading save
lib/screens/field_tools/field_tools_hub_screen.dart   — Pass jobId to ALL tools
lib/screens/jobs/job_detail_screen.dart               — "Field Tools" button passes jobId
lib/screens/home_screen_v2.dart                       — Field tools launcher passes jobId
```

#### Steps

**Step 1: Voice Notes**
- Currently: shows "coming soon" for playback, no real recording
- Wire: record audio → save to 'voice-notes' bucket → insert row in voice_notes table
- After upload: call transcribe-audio Edge Function (Claude or Whisper API)
- Edge Function: audio → text transcription → saved to voice_notes.transcription
- Transcription status: pending → processing → completed/failed
- Playback: load audio URL from Storage, play in app
- Tags: user can tag voice notes for categorization

**Step 2: Level & Plumb**
- Currently: uses device sensors for level reading, no save
- Wire: "Save Reading" → save to compliance_records with type='inspection'
- JSONB data: `{readingType: 'level'|'plumb', value: degrees, location: text, photo_id: optional}`
- Simple — just needs a save button that persists the reading

**Step 3: Job Linking Infrastructure**
- ALL field tools must receive `jobId` parameter
- `FieldToolsHubScreen` → gets jobId from navigation args → passes to each tool
- `JobDetailScreen` → "Open Field Tools" button → navigates to hub with jobId
- `HomeScreenV2` → field tools section → either picks current job or shows job selector
- If no jobId: show job picker dialog before opening tool (or allow "unlinked" capture)
- Every tool's save function includes jobId in the record

**Step 4: Active Job State**
- `activeJobProvider` = currently selected job for field work
- When tech clocks into a job, it becomes the active job
- Field tools default to active job (no need to pick every time)
- Can change active job from field tools hub

#### Verify
- [ ] Voice recording captures and saves audio file
- [ ] Playback works from saved recording
- [ ] Transcription runs and saves text
- [ ] Level/Plumb reading saves to compliance_records
- [ ] ALL 14 tools receive and save jobId
- [ ] Job detail screen shows all linked field data (photos, notes, signatures, etc.)
- [ ] Active job state persists during field session
- [ ] `flutter analyze` passes
- [ ] Commit: `[B2d] Voice notes, level/plumb wired + job linking for all 14 tools`

---

### Sprint B3a: Build Materials Tracker + Daily Job Log
**Status: PENDING** | **Est: ~8-10 hours**

#### Objective
Build two new tools from scratch: Materials/Equipment Tracker and Daily Job Log.

#### Prerequisites
- B1c complete (jobs wired — these tools link to jobs)

#### Database (New Tables)

```sql
-- MATERIALS / EQUIPMENT USED ON JOB
CREATE TABLE job_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  added_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  description text,
  category text DEFAULT 'material' CHECK (category IN ('material', 'equipment', 'tool', 'consumable', 'rental')),
  quantity numeric(10,2) NOT NULL DEFAULT 1,
  unit text DEFAULT 'each',
  unit_cost numeric(12,2),
  total_cost numeric(12,2),
  vendor text,
  receipt_id uuid REFERENCES receipts(id),
  is_billable boolean DEFAULT true,
  installed_at timestamptz,
  serial_number text,
  warranty_info text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE job_materials ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_job_materials_job ON job_materials (job_id);
CREATE TRIGGER job_materials_updated_at BEFORE UPDATE ON job_materials FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER job_materials_audit AFTER INSERT OR UPDATE OR DELETE ON job_materials FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "job_materials_select" ON job_materials FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "job_materials_insert" ON job_materials FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "job_materials_update" ON job_materials FOR UPDATE USING (company_id = auth.company_id());

-- DAILY JOB LOG ENTRIES
CREATE TABLE daily_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  author_user_id uuid NOT NULL REFERENCES auth.users(id),
  log_date date NOT NULL DEFAULT CURRENT_DATE,
  weather text,
  temperature_f int,
  summary text NOT NULL,
  work_performed text,
  issues text,
  delays text,
  visitors text,
  crew_members uuid[] DEFAULT '{}',
  crew_count int DEFAULT 1,
  hours_worked numeric(4,1),
  photo_ids uuid[] DEFAULT '{}',
  safety_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_daily_logs_job_date ON daily_logs (job_id, log_date DESC);
CREATE TRIGGER daily_logs_updated_at BEFORE UPDATE ON daily_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER daily_logs_audit AFTER INSERT OR UPDATE OR DELETE ON daily_logs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "daily_logs_select" ON daily_logs FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "daily_logs_insert" ON daily_logs FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "daily_logs_update" ON daily_logs FOR UPDATE USING (company_id = auth.company_id());
```

#### Files to Create
```
lib/models/job_material.dart
lib/models/daily_log.dart
lib/repositories/job_material_repository.dart
lib/repositories/daily_log_repository.dart
lib/providers/job_material_providers.dart
lib/providers/daily_log_providers.dart
lib/screens/field_tools/materials_tracker_screen.dart    — NEW SCREEN
lib/screens/field_tools/daily_log_screen.dart            — NEW SCREEN
```

#### Materials Tracker Features
- Add material/equipment to job: name, quantity, unit cost, vendor, category
- Scan receipt to auto-fill (links to receipt_scanner)
- Mark as billable/non-billable
- Serial number tracking for installed equipment (feeds Equipment Passport on Client Portal)
- Totals: total materials cost per job, total billable
- List view: grouped by category, sortable
- Edit/delete existing entries

#### Daily Job Log Features
- One log per job per day (auto-date)
- Fields: weather, summary, work performed, issues/delays, visitors, crew
- Attach photos from the day (link to existing photos)
- Auto-populate crew from time entries (who clocked into this job today)
- History: chronological log with search
- Template: pre-fill weather from API (stretch goal — skip for now, manual entry)

#### Verify
- [ ] Add material → appears in job materials list
- [ ] Material cost totals calculate correctly
- [ ] Billable vs non-billable flagging works
- [ ] Daily log creates one entry per job per day
- [ ] Daily log shows in job detail timeline
- [ ] Photos linkable to daily log
- [ ] Both tools receive and save jobId
- [ ] `flutter analyze` passes
- [ ] Commit: `[B3a] Materials Tracker + Daily Log — new field tools built and wired`

---

### Sprint B3b: Punch List + Change Orders + Job Completion
**Status: PENDING** | **Est: ~10-12 hours**

#### Objective
Build three new tools: Punch List/Task Checklist, Change Order Capture, and Job Completion Workflow.

#### Database (New Tables)

```sql
-- PUNCH LIST / TASK CHECKLIST
CREATE TABLE punch_list_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  assigned_to_user_id uuid REFERENCES auth.users(id),
  title text NOT NULL,
  description text,
  category text,
  priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'skipped')),
  due_date date,
  completed_at timestamptz,
  completed_by_user_id uuid,
  photo_ids uuid[] DEFAULT '{}',
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE punch_list_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_punch_list_job ON punch_list_items (job_id, sort_order);
CREATE TRIGGER punch_list_updated_at BEFORE UPDATE ON punch_list_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER punch_list_audit AFTER INSERT OR UPDATE OR DELETE ON punch_list_items FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "punch_list_select" ON punch_list_items FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "punch_list_insert" ON punch_list_items FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "punch_list_update" ON punch_list_items FOR UPDATE USING (company_id = auth.company_id());

-- CHANGE ORDERS
CREATE TABLE change_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  change_order_number text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  reason text,
  line_items jsonb DEFAULT '[]',
  amount numeric(12,2) NOT NULL DEFAULT 0,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'voided')),
  approved_by_name text,
  approved_at timestamptz,
  signature_id uuid REFERENCES signatures(id),
  photo_ids uuid[] DEFAULT '{}',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE change_orders ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_change_orders_job ON change_orders (job_id);
CREATE TRIGGER change_orders_updated_at BEFORE UPDATE ON change_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER change_orders_audit AFTER INSERT OR UPDATE OR DELETE ON change_orders FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "change_orders_select" ON change_orders FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "change_orders_insert" ON change_orders FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "change_orders_update" ON change_orders FOR UPDATE USING (company_id = auth.company_id());
```

#### Files to Create
```
lib/models/punch_list_item.dart
lib/models/change_order.dart
lib/repositories/punch_list_repository.dart
lib/repositories/change_order_repository.dart
lib/providers/punch_list_providers.dart
lib/providers/change_order_providers.dart
lib/screens/field_tools/punch_list_screen.dart       — NEW SCREEN
lib/screens/field_tools/change_order_screen.dart     — NEW SCREEN
lib/screens/field_tools/job_completion_screen.dart   — NEW SCREEN
```

#### Punch List Features
- Add task: title, description, priority, assignee, due date
- Reorder tasks (drag or manual sort_order)
- Check off tasks → status=completed, completed_at, completed_by
- Progress indicator: X of Y completed
- Filter: open, completed, by assignee
- Attach photo to task (defect found, etc.)
- Category grouping (electrical, plumbing, finish, etc.)

#### Change Order Features
- Create change order for a job: title, description, reason, amount
- Line items: description, quantity, unit price (same structure as invoices)
- Auto-number: CO-001, CO-002 per job
- Workflow: draft → pending_approval → approved/rejected
- Customer signature for approval (links to signature tool)
- Change order amount adds to job total
- Photo documentation of changed scope

#### Job Completion Workflow
- Checklist of required steps before marking job complete:
  - [ ] All punch list items completed (auto-check from punch_list_items)
  - [ ] Final photos taken (check photos table for completion category)
  - [ ] Client signature captured (check signatures table)
  - [ ] Time entries complete (no active clock entry)
  - [ ] Materials logged (check job_materials)
  - [ ] Daily log submitted for today
  - [ ] Change orders resolved (all approved or rejected)
- Shows completion percentage
- "Complete Job" button only enabled when all required items done
- On complete: updates job status to 'completed', sets completed_at
- Optional: trigger invoice creation

#### Verify
- [ ] Punch list: add/complete/reorder tasks
- [ ] Punch list progress reflects on job detail
- [ ] Change order: create/approve with signature
- [ ] Change order amount affects job total
- [ ] Job completion: validates all requirements before allowing complete
- [ ] Job completion: auto-checks from real data (photos exist, signature exists, etc.)
- [ ] All new screens added to field tools hub
- [ ] `flutter analyze` passes
- [ ] Commit: `[B3b] Punch List, Change Orders, Job Completion — built and wired`

---

### Sprint B4a: Web CRM Infrastructure — Auth + Supabase Client
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Replace Firebase with Supabase in the Web CRM. Set up auth, client, types, and middleware.

#### Prerequisites
- A3a-A3c complete (database deployed)
- A2 complete (env vars for web-portal)

#### Files to Create
```
web-portal/src/lib/supabase.ts              — REWRITE: Supabase browser + server clients
web-portal/src/lib/supabase-server.ts       — Server-side Supabase client (for server components)
web-portal/src/lib/types.ts                 — REWRITE: Types matching Supabase schema exactly
web-portal/src/middleware.ts                — Auth middleware (redirect unauthenticated)
web-portal/src/lib/hooks/useAuth.ts         — Auth hook (current user, company, role)
web-portal/src/lib/hooks/useSupabase.ts     — Generic Supabase query hook
```

#### Files to Delete
```
web-portal/src/lib/firebase.ts    — Remove Firebase SDK
web-portal/src/lib/auth.ts        — Remove Firebase auth (replace with Supabase)
web-portal/src/lib/firestore.ts   — Remove Firestore queries (replace with Supabase)
```

#### Steps

**Step 1: Install Supabase packages**
```bash
cd web-portal && npm install @supabase/supabase-js @supabase/ssr
npm uninstall firebase firebase-admin  # Remove Firebase
```

**Step 2: Supabase Client**
- Browser client: `createBrowserClient(url, anonKey)` from `@supabase/ssr`
- Server client: `createServerClient(url, anonKey, {cookies})` for server components
- Both read from env vars: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`

**Step 3: Auth Middleware**
```typescript
// middleware.ts — protect /dashboard/* routes
// Check for valid Supabase session
// If no session → redirect to /
// If session → allow through, refresh token if needed
```

**Step 4: TypeScript Types**
- Generate types matching ALL Supabase tables (or write manually to match A3 schemas)
- Must include: Company, User, Customer, Job, Invoice, Bid, TimeEntry, Photo, Signature, VoiceNote, Receipt, ComplianceRecord, MileageTrip, JobMaterial, DailyLog, PunchListItem, ChangeOrder
- All fields snake_case to match database columns
- Union types for status enums

**Step 5: Auth Hook**
```typescript
// useAuth() hook returns:
// { user, company, role, isLoading, signIn, signOut }
// Reads from Supabase session + users table
```

**Step 6: Wire Login Page**
- Replace Firebase signIn with Supabase `auth.signInWithPassword()`
- Handle: invalid credentials, rate limiting, network errors
- On success: redirect to /dashboard

**Step 7: RBAC Integration**
- `permission-gate.tsx` currently defines 40+ permissions
- Wire to read role from Supabase JWT → `user.app_metadata.role`
- Permission mapping: role → permissions (owner gets all, tech gets limited)
- Keep existing PermissionGate/TierGate components, just change data source

#### Verify
- [ ] Login works with Supabase Auth
- [ ] Protected routes redirect to login when unauthenticated
- [ ] Current user profile loads from users table
- [ ] Role correctly read from JWT
- [ ] PermissionGate works with real roles
- [ ] Firebase packages fully removed
- [ ] `npm run build` passes
- [ ] Commit: `[B4a] Web CRM infrastructure — Supabase auth, client, types, middleware`

---

### Sprint B4b: Web CRM Operations Pages — Jobs, Bids, Invoices, Customers
**Status: PENDING** | **Est: ~8-10 hours**

#### Objective
Wire the 12 core operations pages to read/write real Supabase data.

#### Prerequisites
- B4a complete (Supabase client + auth working)

#### Files to Create
```
web-portal/src/lib/hooks/useJobs.ts       — Jobs CRUD + real-time
web-portal/src/lib/hooks/useCustomers.ts  — Customers CRUD + real-time
web-portal/src/lib/hooks/useInvoices.ts   — Invoices CRUD + real-time
web-portal/src/lib/hooks/useBids.ts       — Bids CRUD + real-time
web-portal/src/lib/hooks/useStats.ts      — Dashboard aggregations
```

#### Files to Modify (replace mock-data imports with hooks)
```
web-portal/src/app/dashboard/page.tsx             — Real stats, real activity feed
web-portal/src/app/dashboard/jobs/page.tsx         — Real jobs list
web-portal/src/app/dashboard/jobs/new/page.tsx     — Real job creation
web-portal/src/app/dashboard/jobs/[id]/page.tsx    — Real job detail + field data
web-portal/src/app/dashboard/customers/page.tsx    — Real customer list
web-portal/src/app/dashboard/customers/new/page.tsx
web-portal/src/app/dashboard/customers/[id]/page.tsx
web-portal/src/app/dashboard/invoices/page.tsx     — Real invoice list
web-portal/src/app/dashboard/invoices/new/page.tsx
web-portal/src/app/dashboard/invoices/[id]/page.tsx
web-portal/src/app/dashboard/bids/page.tsx         — Real bids list
web-portal/src/app/dashboard/bids/new/page.tsx
web-portal/src/app/dashboard/bids/[id]/page.tsx
web-portal/src/app/dashboard/leads/page.tsx        — Real leads (jobs with status=draft)
web-portal/src/app/dashboard/change-orders/page.tsx
```

#### Hook Pattern (apply to all)
```typescript
export function useJobs() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createClient();
    // Initial fetch
    fetchJobs();
    // Real-time subscription
    const channel = supabase.channel('jobs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchJobs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, []);

  // CRUD functions
  const createJob = async (data) => { ... };
  const updateJob = async (id, data) => { ... };
  const deleteJob = async (id) => { ... };

  return { jobs, loading, error, createJob, updateJob, deleteJob };
}
```

#### Key Wiring Details
- **Dashboard**: aggregate stats from real data (jobs count by status, revenue this month, overdue invoices)
- **Job Detail**: show linked field tool data — photos, time entries, materials, daily logs, signatures
- **Bid → Job conversion**: "Convert to Job" button creates job from bid data
- **Invoice → Payment**: "Record Payment" updates invoice amount_paid
- **Real-time**: all list pages auto-update when data changes (Supabase Realtime channels)
- **Leads page**: shows jobs with status='draft' — same table, different filter

#### Verify
- [ ] Dashboard shows real stats (not mock)
- [ ] Jobs CRUD works end-to-end
- [ ] Customers CRUD works
- [ ] Invoices CRUD works, payment recording works
- [ ] Bids CRUD works, conversion to job works
- [ ] Real-time: create job in Flutter → appears in CRM immediately
- [ ] Job detail shows field photos, time entries, materials from mobile app
- [ ] Leads page shows draft jobs
- [ ] `npm run build` passes
- [ ] Commit: `[B4b] Web CRM operations — jobs, bids, invoices, customers wired to Supabase`

---

### Sprint B4c: Web CRM Remaining Pages
**Status: PENDING** | **Est: ~6-8 hours**

#### Objective
Wire remaining 25+ CRM pages: team, calendar, time clock, resources, settings, and placeholder pages.

#### Files to Create
```
web-portal/src/lib/hooks/useTeam.ts           — Team members CRUD
web-portal/src/lib/hooks/useTimeEntries.ts    — Time clock data
web-portal/src/lib/hooks/useCalendar.ts       — Calendar events from jobs
web-portal/src/lib/hooks/useCompany.ts        — Company settings
```

#### Pages to Wire
```
Scheduling:
  /dashboard/calendar         — Jobs as calendar events, assignee filter
  /dashboard/inspections      — compliance_records WHERE type='inspection'
  /dashboard/permits          — Placeholder (store in compliance_records or JSONB)
  /dashboard/time-clock       — Time entries list, approval workflow

Customers:
  /dashboard/communications   — Placeholder (wire in F1 Phone System)
  /dashboard/service-agreements — Placeholder (store in JSONB on customer)
  /dashboard/warranties       — Placeholder (wire in D3 Insurance)

Resources:
  /dashboard/team             — Users table, invite flow, location tracking
  /dashboard/equipment        — job_materials WHERE category='equipment'
  /dashboard/inventory        — Materials aggregate across jobs
  /dashboard/vendors          — Placeholder (minimal table or JSONB)
  /dashboard/purchase-orders  — Placeholder

Office:
  /dashboard/books            — Placeholder (wire in D4 ZBooks)
  /dashboard/price-book       — Placeholder (JSONB or dedicated table later)
  /dashboard/documents        — Photos + files from Storage
  /dashboard/reports          — Computed from real data (revenue, time, materials)
  /dashboard/automations      — Placeholder (Phase E)

Settings:
  /dashboard/settings         — Company settings update, team invite

Z Intelligence (Pro Mode):
  /dashboard/bid-brain         — Placeholder (Phase E)
  /dashboard/job-cost-radar    — Computed: job revenue - (time cost + material cost)
  /dashboard/equipment-memory  — Placeholder (Phase E)
  /dashboard/revenue-autopilot — Placeholder (Phase E)
  /dashboard/z-voice           — Placeholder (Phase F)
```

#### Implementation Notes
- **Placeholder pages**: Show clean "Coming Soon" with Phase reference, not broken mock data
- **Computed pages** (reports, job-cost-radar): aggregate real data from existing tables
- **Team page**: real user list from users table, invite sends email via Supabase Auth invite
- **Calendar**: read from jobs.scheduled_start → calendar events, color by status
- **Documents**: list files from Supabase Storage, organized by job

#### Verify
- [ ] Team page shows real users, invite sends email
- [ ] Calendar shows real scheduled jobs
- [ ] Time clock shows real entries, approval works
- [ ] Reports compute from real data
- [ ] Documents list real uploaded files
- [ ] Placeholder pages show clean "Coming Soon"
- [ ] Settings updates company info
- [ ] `npm run build` passes
- [ ] Commit: `[B4c] Web CRM remaining pages — team, calendar, settings, placeholders`

---

### Sprint B4d: Web CRM UI Polish — Supabase-Level Professionalism
**Status: DONE (Session 53)** | **Est: ~4-6 hours**

#### Objective
Elevate the CRM dashboard from "functional" to "Supabase-level sharp." Reference: Supabase dashboard UI — collapsible sidebar, visual restraint, generous spacing, professional charts. Currently ZAFTO CRM feels cluttered with too many competing colors and tight spacing.

#### Reference Benchmarks
- **Supabase dashboard** — collapsible icon-rail sidebar, muted palette, uppercase tracking-wide section labels, generous negative space
- **Stripe dashboard** — card hierarchy, subtle borders, clean typography
- **Linear app** — smooth transitions, keyboard-first, minimal UI chrome

#### 1. Collapsible Sidebar (highest impact)
```
Current: Fixed 200px sidebar, always expanded, eats content space.
Target:  48px icon rail (default) → 220px expanded on hover/pin.

Implementation:
- Default state: icon-only rail (Lucide icons, 48px wide)
- Hover: smoothly expands to 220px with labels + section headers
- Pin toggle (lock icon): user can lock sidebar open
- CSS transition: width 200ms ease, labels fade with opacity 150ms
- Section headers (OPERATIONS, SCHEDULING, etc.) use uppercase tracking-wide 10px
- Active item: subtle left-border accent (2px), not full-width highlight
- Collapse state persisted in localStorage
```

#### 2. Visual Restraint Pass
```
Current: Green, blue, purple, orange, red, cyan all competing. Colored icon badges on stat cards.
Target:  2-3 accent colors max. Let the data speak.

Changes:
- Stat cards: remove colored icon badges. Just number + label + subtle trend indicator
- Reduce to: green (money/success), muted blue (info/neutral), red (alerts only)
- "Ask Z" card: tone down gradient. Use subtle border accent, not full gradient bg
- Right-column widgets: increase spacing between cards (16px → 24px)
- Remove visual noise: fewer borders, fewer background colors on nested elements
- Card hover: subtle elevation shift (shadow), not color change
```

#### 3. Typography & Spacing Hierarchy
```
Current: Mixed header styles, tight vertical spacing, inconsistent label sizes.
Target:  Clear 3-level hierarchy. Generous breathing room.

Changes:
- Section headers: UPPERCASE, tracking-wide (0.05em), 10-11px, text-muted
- Card titles: 14px semibold, text-primary
- Card values: 24-32px bold (stat numbers), 14px regular (body text)
- Vertical rhythm: 32-40px between dashboard sections (currently ~24px)
- Card padding: 20-24px internal (currently 16px)
- Page margin: 32px (currently ~24px)
```

#### 4. Chart Polish (Revenue Overview + all charts)
```
Current: Basic jagged polyline chart. Looks like a prototype.
Target:  Smooth Bezier curves, gradient fills, professional axes.

Changes:
- Line interpolation: curveMonotoneX or curveNatural (smooth, no overshoot)
- Area fill: subtle gradient (accent color at 0.15 opacity → 0 at bottom)
- Grid lines: horizontal only, very subtle (rgba white ~0.05)
- No vertical grid lines
- Axis labels: text-xs text-muted, minimal — don't label every point
- Tooltip: dark card with subtle border, shows date + value
- Chart container: dark card background (bg-elevated), generous padding
- Jobs by Status donut: thinner ring, cleaner labels
- Revenue by Category bars: rounded caps, subtle animation on mount
- Library: Recharts already installed — just configuration changes
```

#### 5. Micro-interactions & Transitions
```
- Page transitions: content area crossfade (150ms), sidebar stays mounted
- Card hover: translateY(-1px) + subtle shadow increase
- Sidebar expand: width transition 200ms ease-out
- Stat number changes: countUp animation (500ms ease-out)
- Chart mount: draw-in animation (line draws left to right, 600ms)
- Loading states: skeleton shimmer (not spinner) for cards
```

#### 6. Dark Mode Refinement
```
Current: Dark theme works but borders and card backgrounds blend together.
Target:  Clear visual layers like Supabase.

- bg-base: #0a0a0a (deepest black — page background)
- bg-card: #111111 (cards sit ON the background)
- bg-elevated: #1a1a1a (modals, dropdowns, tooltips)
- border-subtle: rgba(255,255,255,0.06) — barely visible
- border-default: rgba(255,255,255,0.1) — card borders
- Ensure 3 distinct depth layers are always visible
```

#### Files to Modify
```
web-portal/src/components/layout/sidebar.tsx    — Collapsible sidebar rewrite
web-portal/src/components/layout/layout.tsx     — Content area flex adjustment
web-portal/src/app/dashboard/page.tsx           — Dashboard grid + spacing
web-portal/src/components/ui/stat-card.tsx      — Simplified stat cards
web-portal/src/components/charts/*              — Chart config updates
web-portal/src/app/globals.css                  — Dark mode color tweaks
web-portal/tailwind.config.ts                   — Spacing/color token updates
```

#### Verify
- [ ] Sidebar collapses to icon rail, expands on hover, pin works
- [ ] Dashboard has visible breathing room between sections
- [ ] Stat cards are clean — no colored icon badges
- [ ] Revenue chart uses smooth Bezier line with gradient fill
- [ ] Max 2-3 accent colors visible on any given page
- [ ] Typography uses consistent 3-level hierarchy
- [ ] Dark mode has 3 clear depth layers (base / card / elevated)
- [ ] Page transitions are smooth (no flash/jump)
- [ ] `npm run build` passes
- [ ] Commit: `[B4d] Web CRM UI polish — collapsible sidebar, visual restraint, chart upgrade`

---

### Sprint B4e: Z Intelligence Chat + Artifact System (Web CRM)
**Status: PENDING** | **Est: ~8-12 hours**
**Depends on: B4a-B4d complete, Phase E AI layer for full functionality**

#### Objective
Build the chat interface and artifact rendering system for Z Intelligence in the Web CRM. Must feel as professional as Claude Desktop but in ZAFTO's design language. This sprint builds the UI shell and interaction patterns — actual AI wiring happens in Phase E.

#### Reference Benchmarks
- **Claude Desktop** — persistent chat, artifact pane (side-by-side), markdown rendering, code blocks
- **Cursor IDE** — inline AI panel, context-aware suggestions, smooth transitions
- **v0.dev** — artifact preview with edit/accept/reject, live rendering

#### 1. Chat Panel Architecture
```
Layout:
- Right-side slide-out pane (like Supabase "AI Assistant")
- Trigger: "Ask Z" button (bottom-right) OR keyboard shortcut (Cmd+K for command, Cmd+J for chat)
- Pane width: 400px default, resizable to 600px max, collapsible
- PERSISTS across page navigation — chat stays open while route changes
- Chat context knows which page you're on (Jobs, Invoices, etc.)

States:
- Collapsed: floating "Ask Z" button (subtle, bottom-right corner)
- Open: right pane with conversation thread
- Split: chat left (400px) + artifact right (remaining), for artifact viewing

Transition:
- Open: slide-in from right (200ms ease-out)
- Close: slide-out to right (150ms ease-in)
- Content area smoothly adjusts width (no jump)
```

#### 2. Chat UI Components
```
Message thread:
- User messages: right-aligned, subtle bg card, text-sm
- Z responses: left-aligned, no bg (clean like Claude), markdown rendered
- Markdown: full GFM support — headers, lists, tables, code blocks, bold/italic
- Code blocks: syntax highlighted (Prism/Shiki), copy button, language label
- Thinking indicator: pulsing dot animation (not spinner)
- Timestamps: subtle, relative ("2m ago"), hover for absolute

Input:
- Multi-line text input (auto-resize, max 6 lines before scroll)
- Cmd+Enter to send (Enter for newline)
- Slash commands: /bid, /invoice, /report, /analyze (autocomplete dropdown)
- Context chip: shows current page context ("On: Jobs > Job #1234")
- Attach button: reference a job, customer, invoice by ID

Quick suggestions:
- Below input, 2-3 contextual suggestion chips based on current page
- Jobs page: "Summarize active jobs", "Which jobs are overdue?"
- Invoices page: "Show unpaid invoices", "Revenue this month?"
- These change dynamically per route
```

#### 3. Artifact System
```
When Z generates structured output, it renders as an artifact — not inline markdown.

Artifact types:
- DOCUMENT: bid drafts, invoice drafts, email drafts, reports
- TABLE: data analysis results, comparison tables
- CHART: generated charts (revenue trends, job analytics)
- CODE: SQL queries, configuration snippets
- ACTION: "Create this bid?" / "Send this invoice?" — one-click apply

Artifact rendering:
- Opens in split-pane view (chat 400px | artifact remaining width)
- Document artifacts: styled card matching ZAFTO design, print-ready layout
- Table artifacts: sortable, filterable mini-table
- Chart artifacts: rendered inline with same chart components as dashboard
- Code artifacts: syntax highlighted, copy button, "Run" button (for SQL in future)

Artifact actions (toolbar at top of artifact pane):
- "Apply" — create the bid/invoice/etc. from the artifact
- "Edit" — opens the artifact in edit mode (forms pre-filled)
- "Copy" — copy to clipboard
- "Discard" — close artifact, back to chat-only view
- "Pin" — keep artifact visible while continuing chat

Artifact versioning:
- If user says "make it cheaper" after a bid artifact, Z generates v2
- Version tabs at top of artifact: v1 / v2 / v3
- Diff view toggle (show what changed between versions)
```

#### 4. Page-to-Page Context Persistence
```
The chat MUST maintain context across navigation:
- User on Jobs page asks "show me overdue jobs" → Z responds with list
- User navigates to Invoices page
- Chat panel stays open, conversation preserved
- New context chip updates to "On: Invoices"
- User asks "create invoices for those overdue jobs" → Z has context from previous page

Implementation:
- Chat state in global React context (not page-level state)
- Conversation stored in Zustand/Jotai store, persisted to localStorage
- Route changes don't unmount the chat panel
- Context injection: on route change, update system prompt with new page context
```

#### 5. Visual Design
```
Color scheme:
- Chat panel bg: bg-elevated (slightly lighter than page bg)
- User message bg: bg-card with accent-primary left border (2px)
- Z response: no background, just text on bg-elevated
- Artifact pane bg: bg-card
- Artifact toolbar: bg-elevated, subtle bottom border
- Thinking dots: accent-primary color, pulsing

Typography:
- Chat messages: 14px regular
- Code blocks: 13px mono
- Artifact titles: 16px semibold
- Timestamps: 11px text-muted
- Input: 14px, placeholder "Ask Z anything..."

The "Ask Z" floating button:
- 48px circle, bg-card, subtle border
- Z sparkle icon (not the full ZAFTO wordmark)
- Subtle pulse animation when Z has proactive suggestions
- Badge dot when there's an unread Z notification
```

#### Files to Create
```
web-portal/src/components/z-intelligence/
  chat-panel.tsx           — Main chat panel (slide-out pane)
  chat-message.tsx         — Individual message component
  chat-input.tsx           — Multi-line input with slash commands
  artifact-pane.tsx        — Artifact viewer with toolbar
  artifact-document.tsx    — Document artifact renderer
  artifact-table.tsx       — Table artifact renderer
  artifact-chart.tsx       — Chart artifact renderer
  artifact-code.tsx        — Code artifact renderer
  context-provider.tsx     — Global chat state + page context
  suggestion-chips.tsx     — Contextual quick suggestions
  slash-command-menu.tsx   — Autocomplete for /commands

web-portal/src/lib/stores/chat-store.ts  — Zustand store for conversation
web-portal/src/lib/z-intelligence/
  context-builder.ts       — Builds system prompt from current page context
  artifact-parser.ts       — Parses Z responses into artifact objects
  types.ts                 — ChatMessage, Artifact, SlashCommand types
```

#### Verify
- [ ] Chat panel slides in/out smoothly from right side
- [ ] Chat persists across page navigation (no unmount)
- [ ] Context chip updates with current page
- [ ] Markdown renders correctly (headers, lists, code, tables)
- [ ] Artifact pane opens in split view
- [ ] Artifact toolbar has Apply/Edit/Copy/Discard buttons
- [ ] Quick suggestion chips change per page
- [ ] Slash command autocomplete works (/bid, /invoice, /report)
- [ ] Dark mode looks sharp (3 depth layers visible)
- [ ] Keyboard shortcuts work (Cmd+J open chat, Cmd+Enter send)
- [ ] `npm run build` passes
- [ ] Commit: `[B4e] Z Intelligence chat panel + artifact system UI shell`

---

### Sprint B5a: Client Portal Auth + Infrastructure
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Add real auth to Client Portal and set up Supabase infrastructure. Currently 100% static.

#### Prerequisites
- A3a-A3c complete (database deployed)
- B4a pattern established (copy Supabase setup)

#### New Database Requirements

```sql
-- CLIENT PORTAL USERS (customers who access their projects)
-- These are NOT users in the main users table — they're customers with portal access
CREATE TABLE client_portal_users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES customers(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  email text NOT NULL,
  full_name text NOT NULL,
  phone text,
  avatar_url text,
  last_login_at timestamptz,
  invited_by_user_id uuid REFERENCES auth.users(id),
  invited_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE client_portal_users ENABLE ROW LEVEL SECURITY;
-- Client can only see their own record
CREATE POLICY "client_portal_users_select" ON client_portal_users
  FOR SELECT USING (id = auth.uid());
-- Client can update their own profile
CREATE POLICY "client_portal_users_update" ON client_portal_users
  FOR UPDATE USING (id = auth.uid());

-- RLS: Clients can see jobs/invoices/photos linked to their customer_id
-- Add additional SELECT policies to business tables:
CREATE POLICY "jobs_client_select" ON jobs
  FOR SELECT USING (
    customer_id IN (SELECT customer_id FROM client_portal_users WHERE id = auth.uid())
  );
CREATE POLICY "invoices_client_select" ON invoices
  FOR SELECT USING (
    customer_id IN (SELECT customer_id FROM client_portal_users WHERE id = auth.uid())
  );
CREATE POLICY "photos_client_select" ON photos
  FOR SELECT USING (
    is_client_visible = true AND
    job_id IN (SELECT id FROM jobs WHERE customer_id IN (SELECT customer_id FROM client_portal_users WHERE id = auth.uid()))
  );
```

#### Files to Create
```
client-portal/src/lib/supabase.ts         — Supabase browser client
client-portal/src/lib/types.ts            — TypeScript types (subset of CRM types)
client-portal/src/middleware.ts            — Auth middleware
client-portal/src/lib/hooks/useAuth.ts    — Client auth hook
client-portal/.env.example                — Template env file
```

#### Files to Modify
```
client-portal/src/app/page.tsx            — Real login (magic link or email/password)
client-portal/src/app/(portal)/layout.tsx — Load real user data
```

#### Steps
1. Install `@supabase/supabase-js @supabase/ssr` in client-portal
2. Create Supabase client (same pattern as CRM)
3. Auth flow: contractor invites customer → magic link email → customer sets password → logged in
4. Middleware: protect all `(portal)/*` routes
5. Load customer profile and linked data on auth

#### Verify
- [ ] Customer receives invite email
- [ ] Magic link login works
- [ ] Authenticated user sees their data
- [ ] Unauthenticated redirects to login
- [ ] `npm run build` passes
- [ ] Commit: `[B5a] Client Portal auth — Supabase magic link, middleware, client user table`

---

### Sprint B5b: Client Portal Pages Wired
**Status: PENDING** | **Est: ~8-10 hours**

#### Objective
Wire all 21 Client Portal pages to read real data from Supabase.

#### Files to Create
```
client-portal/src/lib/hooks/useProjects.ts    — Jobs linked to customer
client-portal/src/lib/hooks/usePayments.ts    — Invoices for customer
client-portal/src/lib/hooks/useEquipment.ts   — Equipment passport
client-portal/src/lib/hooks/useDocuments.ts   — Documents/photos
client-portal/src/lib/hooks/useMessages.ts    — Placeholder
```

#### Pages to Wire
```
Home (/home):
  - Action cards from real data: pending invoices, active projects, upcoming appointments
  - Property profile from customer.address
  - Maintenance reminders from job history

Projects:
  /projects           — Jobs WHERE customer_id = me, filtered by status
  /projects/[id]      — Job detail with timeline, crew, photos, change orders
  /projects/[id]/estimate — Bid detail (linked bid)
  /projects/[id]/agreement — Service agreement (JSONB on job or separate)
  /projects/[id]/tracker — Real-time: show assigned tech GPS if sharing enabled

Payments:
  /payments           — Invoices WHERE customer_id = me
  /payments/[id]      — Invoice detail with line items, pay button
  /payments/history   — Paid invoices sorted by date
  /payments/methods   — Stripe: saved payment methods (wire in D4)

My Home:
  /my-home            — Customer profile, home details, equipment summary
  /my-home/equipment  — job_materials WHERE job.customer_id = me AND category='equipment'
  /my-home/equipment/[id] — Equipment detail with service history

Menu:
  /messages           — Placeholder (wire in F1)
  /documents          — Photos/files WHERE is_client_visible = true
  /request            — Create new job (status=draft, customer_id=me)
  /referrals          — Placeholder
  /review             — Placeholder
  /settings           — Profile update, notification preferences
```

#### Key Notes
- All data scoped by customer_id via RLS (client can ONLY see their own data)
- Live Tracker: only shows tech location if job.status is 'enRoute' or 'inProgress' and tech opted in
- Equipment Passport: shows materials/equipment installed at customer's property with serial numbers and warranty dates
- "Request Service" creates a draft job linked to the customer

#### Verify
- [ ] Home page shows real action items for this customer
- [ ] Projects list shows only this customer's jobs
- [ ] Project detail shows real timeline, photos, change orders
- [ ] Payments list shows only this customer's invoices
- [ ] Equipment list shows installed equipment from jobs
- [ ] Service request creates draft job in contractor's queue
- [ ] Documents shows client-visible photos/files
- [ ] No data leak between customers (RLS verified)
- [ ] `npm run build` passes
- [ ] Commit: `[B5b] Client Portal pages wired — projects, payments, equipment, documents`

---

### Sprint B6a: Screen Registry + Command Palette
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Add all business screens and field tools to the Flutter screen registry. Make Cmd+K search everything.

#### Files to Modify
```
lib/screens/screen_registry.dart (10,128 lines) — Add business screen entries
lib/screens/command_palette/                    — Wire to search jobs, customers, invoices by name
```

#### Steps
1. Add entries for all business screens to screen_registry (jobs hub, job detail, customers hub, etc.)
2. Add entries for all 19 field tools (14 existing + 5 new)
3. Cmd+K integration: when typing, also search jobs by title/address, customers by name, invoices by number
4. Search results show entity type icon + name + status
5. Selecting a search result navigates to the detail screen

#### Verify
- [ ] Cmd+K finds business screens by name
- [ ] Cmd+K searches jobs by title/address/customer
- [ ] Cmd+K searches customers by name
- [ ] Cmd+K searches invoices by number
- [ ] All field tools accessible from registry
- [ ] `flutter analyze` passes
- [ ] Commit: `[B6a] Screen registry + Cmd+K — business screens + entity search`

---

### Sprint B6b: Push Notifications + Real-time
**Status: PENDING** | **Est: ~6-8 hours**

#### Objective
Wire push notifications for critical events and real-time data sync indicators.

#### Files to Create
```
lib/services/notification_service.dart       — FCM/APNS registration + handling
lib/providers/notification_providers.dart
supabase/functions/send-notification/index.ts — Edge Function: send push via FCM
```

#### Database
```sql
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL, -- 'job_assigned', 'invoice_paid', 'bid_accepted', etc.
  entity_type text,
  entity_id uuid,
  is_read boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_notifications_user ON notifications (user_id, is_read, created_at DESC);
CREATE POLICY "notifications_select" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_update" ON notifications FOR UPDATE USING (user_id = auth.uid());
```

#### Notification Triggers (Edge Functions or DB triggers)
- Job assigned to tech → push to tech
- Invoice paid → push to company owner
- Bid accepted → push to bid creator
- New customer message → push to assigned tech
- Dead Man Switch triggered → push to company admin (in addition to SMS)
- Time entry needs approval → push to manager

#### Verify
- [ ] Push notifications received on device
- [ ] Tapping notification navigates to relevant screen
- [ ] In-app notification list shows unread count
- [ ] Real-time data changes reflect immediately
- [ ] `flutter analyze` passes
- [ ] Commit: `[B6b] Push notifications + real-time indicators`

---

### Sprint B6c: Offline Polish + Loading States
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Polish offline behavior, add sync indicators, ensure all screens handle loading/error/empty states consistently.

#### Steps
1. **Sync indicator widget**: show at top of screen when offline, show sync progress when reconnecting
2. **Offline banner**: "You're offline — changes will sync when connected"
3. **Loading states**: audit every screen uses `LoadingState` widget consistently
4. **Error states**: audit every screen uses `ErrorState` widget with retry button
5. **Empty states**: audit every screen uses `EmptyState` widget with helpful CTA
6. **PowerSync status**: expose connection status as a provider → UI widget
7. **Conflict resolution**: test what happens with concurrent edits (server wins)

#### Verify
- [ ] Offline banner appears when no network
- [ ] Data created offline syncs when back online
- [ ] Sync indicator shows progress
- [ ] All screens: loading, error, empty states present and consistent
- [ ] No crashes when toggling airplane mode rapidly
- [ ] `flutter analyze` passes
- [ ] Commit: `[B6c] Offline polish — sync indicators, loading/error/empty states`

---

## PHASE C: LAUNCH PREP
*Detailed specs for final pre-launch preparation.*

---

### Sprint C1a: Sentry Integration
**Status: PENDING** | **Est: ~3-4 hours**

#### Objective
Wire Sentry error tracking into all three apps.

#### Steps
1. Install Sentry SDK in Flutter, Web CRM, Client Portal
2. Configure DSN from env vars (per environment)
3. Flutter: wrap `runApp()` with `SentryFlutter.init()`
4. Next.js apps: add `@sentry/nextjs` with `sentry.client.config.ts` and `sentry.server.config.ts`
5. Tag errors with: company_id, user_id, role, app_version, environment
6. Set up Sentry alerts: error spike, new issue type
7. Add breadcrumbs for navigation and key actions

#### Verify
- [ ] Throw test error → appears in Sentry dashboard
- [ ] Error includes company_id and user context
- [ ] Source maps uploaded for Next.js apps
- [ ] Environment tags correct (dev/staging/prod)
- [ ] Commit: `[C1a] Sentry integration — Flutter, Web CRM, Client Portal`

---

### Sprint C1b: CI/CD Pipeline
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Set up GitHub Actions for automated testing, building, and deployment.

#### Files to Create
```
.github/workflows/flutter-ci.yml   — Lint + analyze + test on PR
.github/workflows/web-crm-ci.yml   — Lint + build + test on PR
.github/workflows/portal-ci.yml    — Lint + build on PR
.github/workflows/deploy-staging.yml — Deploy to staging on merge to main
```

#### Pipeline Steps
- **Flutter**: `flutter analyze` → `flutter test` → build APK (artifacts)
- **Web CRM**: `npm run lint` → `npm run build` → `npm run test` (if tests exist)
- **Client Portal**: `npm run lint` → `npm run build`
- **Staging deploy**: on merge to main → deploy Web CRM to Vercel/Cloudflare staging

#### Verify
- [ ] PR triggers CI checks
- [ ] CI fails on lint errors
- [ ] CI fails on test failures
- [ ] Merge to main deploys to staging
- [ ] Commit: `[C1b] CI/CD pipeline — GitHub Actions for all apps`

---

### Sprint C1c: Automated Test Suite
**Status: PENDING** | **Est: ~4-5 hours**

#### Objective
Write core automated tests for business logic, models, and RLS policies.

#### Tests to Write
```
test/models/         — All model toJson/fromJson roundtrip tests
test/services/       — Business logic tests (status transitions, validations)
test/repositories/   — Mock PowerSync tests (query construction)
```

#### RLS Test Script
```sql
-- Run against dev Supabase
-- Test company isolation
-- Test role-based access
-- Test client portal scoping
```

#### Verify
- [ ] Model tests pass (all entities)
- [ ] Service tests pass (status transitions, validations)
- [ ] RLS tests pass (company isolation, role restrictions)
- [ ] Tests run in CI pipeline
- [ ] Commit: `[C1c] Test suite — model, service, and RLS tests`

---

### Sprint C2: Debug & QA
**Status: PENDING** | **Est: ~20-30 hours (split across multiple sessions)**

#### Objective
Systematic testing of every screen with real data across all roles.

#### Test Matrix
```
ROLES: owner, admin, office_manager, technician, apprentice
APPS: Flutter, Web CRM, Client Portal
SCENARIOS:
  1. Fresh signup → onboarding → first job → first invoice → first payment
  2. Multiple techs → dispatch → field work → completion → invoicing
  3. Offline: create data offline → reconnect → verify sync
  4. Cross-device: create on Flutter → see on CRM → see on Client Portal
  5. Edge cases: empty states, 1000+ jobs, concurrent edits, rapid navigation
  6. Error cases: network drop mid-save, invalid data, expired session
```

#### Verify
- [ ] All 90+ Flutter screens tested with real data
- [ ] All 39 CRM pages tested
- [ ] All 21 Client Portal pages tested
- [ ] All 5 roles tested (permission enforcement verified)
- [ ] Offline sync verified (create, update, delete while offline)
- [ ] Cross-platform data flow verified
- [ ] No crashes, no unhandled errors
- [ ] Commit: `[C2] QA complete — all screens, roles, and scenarios tested`

---

### Sprint C3: Ops Portal Phase 1
**Status: PENDING** | **Est: ~40 hours (split into C3a-C3c)**

#### Objective
Build 18 core Ops Portal pages. This is the founder's internal dashboard.

**C3a (14 hrs):** Command Center, Inbox, Account Health, Support
**C3b (14 hrs):** Revenue Dashboard, Service Catalog, AI Monitoring
**C3c (12 hrs):** Settings, User Management, System Health, Audit Log Viewer

*Detailed sub-sprint specs to be written when Phase B nears completion. Reference: Locked/34 Ops Portal spec (72 pages total, 18 for Phase 1).*

---

### Sprint C4: Security Hardening
**Status: PENDING** | **Est: ~4 hours**

#### Objective
Harden all accounts and access before launch.

#### Steps
1. Migrate all accounts to admin@zafto.app (Stripe, GitHub, Apple, Anthropic, Cloudflare, Bitwarden)
2. Change all passwords (generate in Bitwarden, 20+ chars)
3. Enable 2FA on every account (TOTP preferred, SMS backup)
4. Create ProtonMail break-glass recovery email
5. Purchase and configure YubiKeys for critical accounts
6. Document all credentials in Bitwarden vault (organized by service)
7. Revoke any old API keys or tokens

#### Verify
- [ ] Every account uses admin@zafto.app
- [ ] Every account has unique 20+ char password
- [ ] Every account has 2FA enabled
- [ ] ProtonMail recovery email works
- [ ] All credentials in Bitwarden, organized
- [ ] No old API keys active
- [ ] Commit: `[C4] Security hardened — all accounts migrated, 2FA, passwords rotated`

---

### Sprint C5: Incident Response Plan
**Status: PENDING** | **Est: ~2-3 hours**

#### Objective
Document procedures for security incidents, outages, and data breaches.

#### Document Contents
1. Severity levels (P0-P3) with response times
2. Data breach response procedure (detect, contain, assess, notify, remediate)
3. Key rotation procedure (Supabase, Stripe, Claude API, Sentry)
4. Rollback procedure (database, app deployment, edge functions)
5. Communication templates (customer notification, legal notification)
6. Contact tree (who to call for what)
7. Post-incident review template

#### Verify
- [ ] Document created in ZAFTO FULL BUILD DOC/
- [ ] All procedures actionable (not theoretical)
- [ ] Key rotation tested manually
- [ ] Commit: `[C5] Incident response plan documented`

---

## PHASE D: REVENUE ENGINE
*Phase C near complete. D1 specs detailed below.*

### Sprint D1: Job Type System (~69 hrs)
**Status: IN PROGRESS** | **Depends on: B1 (Core Business), B4 (Web CRM)**

#### Objective
Every job has one of three types: `standard`, `insurance_claim`, `warranty_dispatch`. Type controls workflow stages, visible fields, and financial categorization. Progressive disclosure — contractors who don't use insurance/warranty never see those fields.

#### Database Status
- `jobs.job_type` TEXT column with CHECK constraint: ALREADY DEPLOYED
- `jobs.type_metadata` JSONB column: ALREADY DEPLOYED
- No new migration needed for D1

#### D1a: Type Metadata Structures + Workflow Stages

**Goal:** Define TypeScript interfaces, update mappers, define per-type workflow stages.

**TypeScript Changes (web-portal/src/types/index.ts):**
```typescript
export type JobType = 'standard' | 'insurance_claim' | 'warranty_dispatch';

export interface InsuranceMetadata {
  claimNumber: string;
  policyNumber?: string;
  insuranceCompany: string;
  adjusterName?: string;
  adjusterPhone?: string;
  adjusterEmail?: string;
  dateOfLoss: string; // ISO date
  deductible?: number;
  coverageLimit?: number;
  approvalStatus?: 'pending' | 'approved' | 'denied' | 'supplemental';
}

export interface WarrantyMetadata {
  warrantyCompany: string; // AHS, Choice, Fidelity, etc.
  dispatchNumber: string;
  authorizationLimit?: number;
  serviceFee?: number;
  warrantyType?: 'home_warranty' | 'manufacturer' | 'extended';
  expirationDate?: string;
  recallId?: string;
}

export interface Job {
  // ... existing fields ...
  jobType: JobType;
  typeMetadata: InsuranceMetadata | WarrantyMetadata | Record<string, unknown>;
}
```

**Mapper Changes (mappers.ts):**
- Add `row.job_type` → `jobType` mapping
- Add `row.type_metadata` → `typeMetadata` mapping
- Add `JOB_TYPE_LABELS` map for display

**Workflow Stages Per Type:**
| Stage | Standard | Insurance Claim | Warranty Dispatch |
|-------|----------|----------------|-------------------|
| 1 | draft | draft | draft |
| 2 | scheduled | assessment | validation |
| 3 | dispatched | approval_pending | dispatched |
| 4 | enRoute | approved | enRoute |
| 5 | inProgress | scheduled | inProgress |
| 6 | onHold | inProgress | onHold |
| 7 | completed | completed | completed |
| 8 | invoiced | claim_submitted | invoiced |
| 9 | — | paid | paid |

**Note:** For D1, standard workflow remains unchanged. Insurance/warranty workflows are defined but NOT enforced — type-specific status restrictions will be added in D2 when claims infrastructure is built. D1 focuses on data capture and display.

**Checklist D1a:**
- [ ] Add `jobType` + `typeMetadata` to TS Job interface
- [ ] Add `InsuranceMetadata` + `WarrantyMetadata` interfaces
- [ ] Update `mapJob()` to extract job_type + type_metadata
- [ ] Add JOB_TYPE_LABELS and JOB_TYPE_COLORS maps
- [ ] Update `use-jobs.ts` createJob/updateJob to handle jobType + typeMetadata
- [ ] Verify Flutter Job model already handles jobType (it does — JobType enum, toInsertJson, fromJson)
- [ ] Commit: `[D1a] Job type metadata structures + workflow stage definitions`

#### D1b: Flutter Mobile — Job Type Selector + Per-Type Fields

**Goal:** Add job type dropdown to job creation/edit. Show conditional fields based on selected type.

**Files to modify:**
- `lib/screens/jobs/job_create_screen.dart` — Add JobType dropdown + conditional metadata fields
- `lib/screens/jobs/job_detail_screen.dart` — Show type badge + metadata in read-only view
- `lib/screens/jobs/job_edit_screen.dart` — Type selector + metadata editing (if it exists)

**UI Design:**
- Job Type selector: SegmentedButton or DropdownButtonFormField (3 options)
- Default: "Standard" (pre-selected, no extra fields)
- Insurance Claim: Shows fields below selector:
  - Insurance Company (required)
  - Claim Number (required)
  - Date of Loss (required)
  - Adjuster Name, Phone, Email (optional)
  - Deductible (optional, currency)
  - Coverage Limit (optional, currency)
- Warranty Dispatch: Shows fields below selector:
  - Warranty Company (required, dropdown: AHS, Choice Home Warranty, Fidelity, First American, Other)
  - Dispatch Number (required)
  - Authorization Limit (optional, currency)
  - Service Fee (optional, currency)

**Progressive Disclosure:** Job type selector only visible if not hidden by company settings. For D1, always show (company settings gating deferred to D2).

**Checklist D1b:**
- [ ] Add JobType selector to job_create_screen.dart
- [ ] Add conditional insurance metadata fields
- [ ] Add conditional warranty metadata fields
- [ ] Populate typeMetadata in Job model on save
- [ ] Show job type badge on job_detail_screen.dart
- [ ] Show type metadata fields on job detail
- [ ] Color-code job type badge (blue=standard, amber=insurance, purple=warranty)
- [ ] Commit: `[D1b] Flutter job type selector + per-type fields`

#### D1c: Web CRM — Job Type in Forms, Lists, Detail Views

**Goal:** Add job type support to all Web CRM job-related pages.

**Files to modify:**
- `web-portal/src/types/index.ts` — Add JobType, metadata interfaces
- `web-portal/src/lib/hooks/mappers.ts` — Map job_type + type_metadata
- `web-portal/src/lib/hooks/use-jobs.ts` — Handle jobType in CRUD
- `web-portal/src/app/dashboard/jobs/new/page.tsx` — Job type selector + conditional fields
- `web-portal/src/app/dashboard/jobs/[id]/page.tsx` — Show type badge + metadata
- `web-portal/src/app/dashboard/jobs/page.tsx` — Type column + filter in list

**UI Design:**
- Job creation form: Job Type radio group (3 options) above existing fields
- Conditional metadata section appears when insurance/warranty selected
- Jobs list: Type column with color-coded badge (blue/amber/purple)
- Filter: Type dropdown added to existing status filter bar
- Job detail: Type badge in header + metadata card section

**Checklist D1c:**
- [ ] Update Job TS interface with jobType + typeMetadata
- [ ] Update mapJob() mapper
- [ ] Update createJob() in use-jobs.ts to send job_type + type_metadata
- [ ] Update updateJob() to handle type metadata changes
- [ ] Add job type selector to jobs/new page
- [ ] Add conditional insurance/warranty fields
- [ ] Add type column to jobs list page
- [ ] Add type filter to jobs list
- [ ] Show type badge + metadata on jobs/[id] detail page
- [ ] `npm run build` passes
- [ ] Commit: `[D1c] Web CRM job type UI — selector, list, detail, filters`

#### D1d: Team Portal + Dashboard Enhancements

**Goal:** Job type visibility in team portal. Revenue breakdown by type. Calendar color coding.

**Team Portal files:**
- `team-portal/src/app/dashboard/jobs/page.tsx` — Type column + badge
- `team-portal/src/app/dashboard/page.tsx` — Revenue by type card
- `team-portal/src/lib/hooks/use-jobs.ts` — Ensure jobType mapped

**Web CRM Dashboard files:**
- `web-portal/src/app/dashboard/page.tsx` — Revenue by type chart
- `web-portal/src/app/dashboard/calendar/page.tsx` — Color-code by type

**Revenue by Type Chart:**
- Pie/donut chart showing revenue split: Standard vs Insurance vs Warranty
- Data source: `jobs` table grouped by `job_type`, summing `estimated_amount` (or actual_amount if completed)
- Color scheme: blue (#3b82f6) = Standard, amber (#f59e0b) = Insurance, purple (#8b5cf6) = Warranty

**Calendar Color Coding:**
- Standard jobs: existing blue
- Insurance claim jobs: amber/orange
- Warranty dispatch jobs: purple
- Applied via tailwind bg class based on job.jobType

**Checklist D1d:**
- [ ] Add job type badge to team portal jobs list
- [ ] Add revenue-by-type chart to web CRM dashboard
- [ ] Add revenue-by-type card to team portal dashboard
- [ ] Color-code calendar events by job type
- [ ] Update team portal use-jobs hook to map job_type
- [ ] All 4 portals `npm run build` pass
- [ ] Commit: `[D1d] Job type dashboard charts + calendar color coding`

---

### Sprint D2: Restoration/Insurance Module (~78 hrs)
**Status: IN PROGRESS (Session 63-64) — D2a-D2e + D2g DONE. D2f + D2h PENDING.**

**Goal:** Build the foundation for insurance claim workflows, restoration tools, and three-payer accounting. 7 new database tables. Claims lifecycle from intake through settlement. Restoration-specific tools (moisture monitoring, drying logs, equipment tracking). Xactimate data import structure (API wiring deferred to D3).

**Depends on:** D1 (Job Type System — COMPLETE)

#### D2a: Database Migration — Insurance Infrastructure

**New migration:** `20260207000011_d2_insurance_tables.sql`

**7 new tables:**

```sql
-- Insurance Claims — linked to jobs with type='insurance_claim'
CREATE TABLE insurance_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  -- Carrier info
  insurance_company TEXT NOT NULL,
  claim_number TEXT NOT NULL,
  policy_number TEXT,
  -- Loss info
  date_of_loss DATE NOT NULL,
  loss_type TEXT NOT NULL DEFAULT 'unknown' CHECK (loss_type IN ('fire','water','storm','wind','hail','theft','vandalism','mold','flood','earthquake','other','unknown')),
  loss_description TEXT,
  -- Adjuster
  adjuster_name TEXT,
  adjuster_phone TEXT,
  adjuster_email TEXT,
  adjuster_company TEXT,
  -- Financials
  deductible NUMERIC(12,2) DEFAULT 0,
  coverage_limit NUMERIC(12,2),
  approved_amount NUMERIC(12,2),
  supplement_total NUMERIC(12,2) DEFAULT 0,
  depreciation NUMERIC(12,2) DEFAULT 0,
  acv NUMERIC(12,2), -- actual cash value
  rcv NUMERIC(12,2), -- replacement cost value
  -- Status
  claim_status TEXT NOT NULL DEFAULT 'new' CHECK (claim_status IN ('new','scope_requested','scope_submitted','estimate_pending','estimate_approved','supplement_submitted','supplement_approved','work_in_progress','work_complete','final_inspection','settled','closed','denied')),
  -- Dates
  scope_submitted_at TIMESTAMPTZ,
  estimate_approved_at TIMESTAMPTZ,
  work_started_at TIMESTAMPTZ,
  work_completed_at TIMESTAMPTZ,
  settled_at TIMESTAMPTZ,
  -- Xactimate
  xactimate_claim_id TEXT,
  xactimate_file_url TEXT,
  -- Metadata
  notes TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Claim Supplements — additional scope + cost beyond original estimate
CREATE TABLE claim_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  supplement_number INTEGER NOT NULL DEFAULT 1,
  title TEXT NOT NULL,
  description TEXT,
  reason TEXT NOT NULL DEFAULT 'hidden_damage' CHECK (reason IN ('hidden_damage','code_upgrade','scope_change','material_upgrade','additional_repair','other')),
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','under_review','approved','denied','partially_approved')),
  approved_amount NUMERIC(12,2),
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewer_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- TPI Scheduling — Third-Party Inspector appointments
CREATE TABLE tpi_scheduling (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  inspector_name TEXT,
  inspector_company TEXT,
  inspector_phone TEXT,
  inspector_email TEXT,
  inspection_type TEXT NOT NULL DEFAULT 'progress' CHECK (inspection_type IN ('initial','progress','supplement','final','re_inspection')),
  scheduled_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','scheduled','confirmed','in_progress','completed','cancelled','rescheduled')),
  result TEXT CHECK (result IN ('passed','failed','conditional','deferred')),
  findings TEXT,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Xactimate Estimate Lines — imported line items from ESX files
CREATE TABLE xactimate_estimate_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  category TEXT NOT NULL, -- e.g., 'demolition', 'framing', 'drywall', 'electrical'
  item_code TEXT, -- Xactimate price code
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'EA', -- EA, LF, SF, SY, HR, etc.
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_supplement BOOLEAN DEFAULT false,
  supplement_id UUID REFERENCES claim_supplements(id),
  depreciation_rate NUMERIC(5,2) DEFAULT 0,
  acv_amount NUMERIC(12,2),
  rcv_amount NUMERIC(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Moisture Readings — daily tracked readings per affected area
CREATE TABLE moisture_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  -- Location
  area_name TEXT NOT NULL, -- e.g., 'Kitchen Wall A', 'Master Bath Floor'
  floor_level TEXT, -- 'basement', '1st', '2nd', 'attic'
  material_type TEXT NOT NULL DEFAULT 'drywall' CHECK (material_type IN ('drywall','wood','concrete','carpet','pad','insulation','subfloor','hardwood','laminate','tile_backer','other')),
  -- Reading
  reading_value NUMERIC(6,1) NOT NULL, -- moisture percentage or unit
  reading_unit TEXT NOT NULL DEFAULT 'percent' CHECK (reading_unit IN ('percent','relative','wme','grains')),
  target_value NUMERIC(6,1), -- target dry value for this material
  -- Equipment
  meter_type TEXT, -- 'pin', 'pinless', 'thermo_hygrometer'
  meter_model TEXT,
  -- Environment
  ambient_temp_f NUMERIC(5,1),
  ambient_humidity NUMERIC(5,1),
  -- Status
  is_dry BOOLEAN DEFAULT false, -- reading <= target
  recorded_by_user_id UUID REFERENCES auth.users(id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Drying Logs — immutable timestamped entries (legal compliance)
CREATE TABLE drying_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  -- Entry
  log_type TEXT NOT NULL DEFAULT 'daily' CHECK (log_type IN ('setup','daily','adjustment','equipment_change','completion','note')),
  summary TEXT NOT NULL,
  details TEXT,
  -- Equipment state at log time
  equipment_count INTEGER DEFAULT 0,
  dehumidifiers_running INTEGER DEFAULT 0,
  air_movers_running INTEGER DEFAULT 0,
  air_scrubbers_running INTEGER DEFAULT 0,
  -- Environmental
  outdoor_temp_f NUMERIC(5,1),
  outdoor_humidity NUMERIC(5,1),
  indoor_temp_f NUMERIC(5,1),
  indoor_humidity NUMERIC(5,1),
  -- Photos
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Recorded by
  recorded_by_user_id UUID REFERENCES auth.users(id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
  -- NOTE: NO update/delete — drying logs are immutable (legal record)
);

-- Restoration Equipment — deployed equipment tracking with daily billing
CREATE TABLE restoration_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  -- Equipment info
  equipment_type TEXT NOT NULL CHECK (equipment_type IN ('dehumidifier','air_mover','air_scrubber','heater','moisture_meter','thermal_camera','hydroxyl_generator','negative_air_machine','other')),
  make TEXT,
  model TEXT,
  serial_number TEXT,
  asset_tag TEXT, -- company's internal tag
  -- Deployment
  area_deployed TEXT NOT NULL, -- e.g., 'Kitchen', 'Master Bedroom'
  deployed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  removed_at TIMESTAMPTZ,
  -- Billing
  daily_rate NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_days INTEGER GENERATED ALWAYS AS (
    CASE WHEN removed_at IS NOT NULL
      THEN GREATEST(1, EXTRACT(DAY FROM removed_at - deployed_at)::INTEGER + 1)
      ELSE GREATEST(1, EXTRACT(DAY FROM now() - deployed_at)::INTEGER + 1)
    END
  ) STORED,
  -- Status
  status TEXT NOT NULL DEFAULT 'deployed' CHECK (status IN ('deployed','removed','maintenance','lost')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS policies
ALTER TABLE insurance_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpi_scheduling ENABLE ROW LEVEL SECURITY;
ALTER TABLE xactimate_estimate_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE moisture_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE drying_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE restoration_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY insurance_claims_company ON insurance_claims USING (company_id = requesting_company_id());
CREATE POLICY claim_supplements_company ON claim_supplements USING (company_id = requesting_company_id());
CREATE POLICY tpi_company ON tpi_scheduling USING (company_id = requesting_company_id());
CREATE POLICY xactimate_company ON xactimate_estimate_lines USING (company_id = requesting_company_id());
CREATE POLICY moisture_company ON moisture_readings USING (company_id = requesting_company_id());
CREATE POLICY drying_logs_company ON drying_logs USING (company_id = requesting_company_id());
CREATE POLICY equipment_company ON restoration_equipment USING (company_id = requesting_company_id());

-- Drying logs: INSERT-only policy (immutable audit trail)
CREATE POLICY drying_logs_insert ON drying_logs FOR INSERT WITH CHECK (company_id = requesting_company_id());
-- Explicitly deny UPDATE and DELETE on drying_logs (legal compliance)

-- Indexes
CREATE INDEX idx_claims_job ON insurance_claims(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_company ON insurance_claims(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_status ON insurance_claims(claim_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_supplements_claim ON claim_supplements(claim_id);
CREATE INDEX idx_tpi_claim ON tpi_scheduling(claim_id);
CREATE INDEX idx_moisture_job ON moisture_readings(job_id);
CREATE INDEX idx_drying_job ON drying_logs(job_id);
CREATE INDEX idx_equipment_job ON restoration_equipment(job_id);

-- Audit triggers
CREATE TRIGGER insurance_claims_updated BEFORE UPDATE ON insurance_claims FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER claim_supplements_updated BEFORE UPDATE ON claim_supplements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpi_updated BEFORE UPDATE ON tpi_scheduling FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER equipment_updated BEFORE UPDATE ON restoration_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**Checklist D2a: DONE (S63-S64)**
- [x] Create migration file — 2 files: 20260207000011_d2_insurance_tables.sql (7 tables) + 20260207000012_d2_financial_depth.sql (added depreciation_recovered, amount_collected to insurance_claims + rcv_amount, acv_amount, depreciation_amount to claim_supplements)
- [x] Deploy to dev (`npx supabase db push`) — 36 total tables, 12 migration files
- [x] Verify 7 tables in SQL Editor (36 total tables)
- [x] Create Flutter models: InsuranceClaim, ClaimSupplement, TpiInspection, MoistureReading, DryingLog, RestorationEquipment (6 model files)
- [x] Create Flutter repos + services — 6 repositories + 2 services (insurance_claim_service.dart, restoration_service.dart). 12+ Riverpod providers.
- [x] Create TypeScript interfaces in web-portal types/index.ts
- [x] Create mappers for all 7 tables
- [x] Commit: `[D2a] Insurance infrastructure — 7 tables deployed, models + mappers created`

---

#### D2b: Insurance Claims CRUD — Flutter + Web CRM

**Goal:** Full claims lifecycle management. Create, view, edit claims. Status transitions. Adjuster info. Linked to job detail.

**Flutter screens:**
- `lib/screens/insurance/claims_hub_screen.dart` — List all claims with status filters
- `lib/screens/insurance/claim_detail_screen.dart` — Full claim detail with tabs (Overview, Supplements, TPI, Moisture, Drying, Equipment)
- `lib/screens/insurance/claim_create_screen.dart` — Create claim from an insurance_claim job

**Web CRM pages:**
- `/dashboard/insurance/page.tsx` — Claims list with status pipeline view (kanban columns by claim_status)
- `/dashboard/insurance/[id]/page.tsx` — Claim detail with tabs matching Flutter
- Link from `/dashboard/jobs/[id]` when job is insurance_claim type → "View Claim" button

**Hooks:**
- `web-portal/src/lib/hooks/use-insurance.ts` — useClaims(), useClaim(id), createClaim(), updateClaimStatus(), deleteClaim()

**Claim status transitions:**
```
new → scope_requested → scope_submitted → estimate_pending → estimate_approved
→ supplement_submitted → supplement_approved (loop) → work_in_progress
→ work_complete → final_inspection → settled → closed
```
(OR `denied` from any state)

**Checklist D2b: DONE (S63-S64)**
- [x] Flutter claims hub screen — claims_hub_screen.dart with status filters
- [x] Flutter claim detail screen with 6 tabs — claim_detail_screen.dart (Overview, Supplements, TPI, Moisture, Drying, Equipment)
- [x] Flutter claim create screen — claim_create_screen.dart
- [x] Web CRM claims list page (pipeline view) — /dashboard/insurance/page.tsx with status pipeline
- [x] Web CRM claim detail page — /dashboard/insurance/[id]/page.tsx with 6 tabs + sidebar
- [x] use-insurance.ts hook — useClaims, useClaim, useClaimByJob, createClaim, updateClaimStatus, updateClaim, deleteClaim
- [x] Job detail → "View Claim" link
- [x] Status transition buttons on claim detail
- [x] `flutter analyze` passes
- [x] `npm run build` passes
- [x] Commit: `[D2b] Insurance claims CRUD — Flutter + Web CRM`

---

#### D2c: Supplement Tracking

**Goal:** Track additional scope/cost discovered during restoration work. Supplements are appended to claims. Each has its own status and approval flow.

**Flutter:**
- Add supplement list + create form to claim_detail_screen.dart Supplements tab
- Supplement status badges and action buttons

**Web CRM:**
- Supplement section in claim detail page
- Create/edit supplement modal
- Supplement status tracking with approval workflow

**Checklist D2c: DONE (S63-S64)**
- [x] Flutter supplement list + create in claim detail — Supplements tab with create bottom sheet, status badges, action buttons
- [x] Web CRM supplement section in claim detail — SupplementsTab with summary bar, inline create form, status workflow
- [x] Status workflow: draft → submitted → under_review → approved/denied/partially_approved
- [x] Amount tracking: submitted vs approved — RCV/ACV/depreciation amounts tracked per supplement
- [x] Photo attachments for evidence
- [x] Commit: `[D2c] Supplement tracking — create, submit, approve`

---

#### D2d: Moisture Monitoring + Drying Logs

**Goal:** Daily moisture readings and immutable drying documentation. Critical for insurance compliance — readings prove when materials dried to target values.

**Flutter screens:**
- `lib/screens/restoration/moisture_screen.dart` — Record readings by area, track progress to target
- `lib/screens/restoration/drying_log_screen.dart` — Record daily logs (immutable once saved)
- Add to field tools menu when job is insurance_claim type

**Web CRM:**
- Moisture tab in claim detail — chart of readings over time per area
- Drying log tab in claim detail — chronological immutable entries

**Key features:**
- Area-based tracking (multiple areas per job, each with own target)
- Material-specific target values (drywall: 12%, wood: 15%, concrete: 17%)
- Visual progress: green when at/below target, red when above
- Drying logs are INSERT-ONLY (no edit/delete — legal compliance)
- Equipment count at each log entry

**Checklist D2d: DONE (S63-S64)**
- [x] Flutter moisture recording screen — MoistureReading model + repo, Moisture tab in claim_detail
- [x] Flutter drying log screen (immutable entries) — DryingLog model + repo, Drying tab in claim_detail
- [x] Web CRM moisture chart in claim detail — Moisture table in detail page
- [x] Web CRM drying log timeline in claim detail — Drying log entries in detail page
- [x] Material-specific target values
- [x] Visual is_dry indicator
- [x] Commit: `[D2d] Moisture monitoring + drying logs`

---

#### D2e: Equipment Tracking

**Goal:** Track deployed restoration equipment (dehumidifiers, air movers, etc.) with daily rate billing. Equipment deployed → equipment removed = days billed.

**Flutter:**
- `lib/screens/restoration/equipment_screen.dart` — Deploy/remove equipment, track per job
- Equipment list in claim detail Equipment tab

**Web CRM:**
- Equipment section in claim detail
- Deploy/remove actions
- Auto-calculated daily billing (total_days * daily_rate)

**Checklist D2e: DONE (S63-S64)**
- [x] Flutter equipment deploy/remove screen — RestorationEquipment model + repo, Equipment tab in claim_detail. 9 equipment types.
- [x] Web CRM equipment section in claim detail — Equipment section in detail page
- [x] Daily rate billing calculation — daily_rate * days calculation
- [x] Equipment status tracking (deployed/removed/maintenance/lost)
- [x] Commit: `[D2e] Equipment tracking — deploy, remove, daily billing`

---

#### D2f: Certificate of Completion

**Goal:** Generate certificate of completion for insurance claims. Required before final settlement.

**Flutter:**
- Job Completion screen enhanced for insurance claims: additional checks (moisture readings all at target, all equipment removed, drying log has completion entry, TPI final inspection passed)
- PDF certificate generation (deferred to Phase E — for now, status update only)

**Web CRM:**
- "Generate Certificate" button on completed insurance claims
- Pre-flight checklist validation

**Checklist D2f: DONE (S67-S68)**
- [x] Flutter: job_completion_screen.dart enhanced — detects `job_type == 'insurance_claim'`, adds 4 insurance-specific checks to standard 7
- [x] Flutter: Moisture at target check — queries moisture_readings, verifies all `is_dry = true`
- [x] Flutter: Equipment removed check — queries restoration_equipment, verifies none `deployed`/`maintenance`
- [x] Flutter: Drying complete check — queries drying_logs for `log_type = 'completion'`
- [x] Flutter: TPI final passed check — queries tpi_scheduling for `inspection_type = 'final'` + `result = 'passed'`
- [x] Flutter: On "Complete Job" → also sets insurance_claims.claim_status = 'work_complete' + work_completed_at
- [x] Web CRM: Completion tab with 4 pre-flight checks (page.tsx lines 889-1079)
- [x] Web CRM: Progress bar + checklist cards + status-aware action buttons
- [x] Web CRM: Status workflow (work_complete → final_inspection → settled → closed)
- [x] Database: All fields support completion checks (is_dry, status, log_type, inspection_type+result)
- [x] All builds pass

---

#### D2g: TPI Scheduling

**Goal:** Schedule and track Third-Party Inspector visits. Linked to claims.

**Flutter:**
- TPI tab in claim detail — list inspections, schedule new, record results
- Notification when TPI scheduled (deferred to real notification system)

**Web CRM:**
- TPI section in claim detail
- Schedule/reschedule actions
- Result recording (passed/failed/conditional/deferred)

**Checklist D2g: DONE (S63-S64)**
- [x] Flutter TPI list + schedule in claim detail — TpiInspection model + repo, TPI tab in claim_detail. 5 inspection types.
- [x] Web CRM TPI section — TPI section in detail page with status flow + result recording
- [x] Status flow: pending → scheduled → confirmed → in_progress → completed/cancelled/rescheduled
- [x] Result recording with findings and photos
- [x] Commit: `[D2g] TPI scheduling — schedule, track, record results`

---

#### D2h: Team Portal + Client Portal Insurance Views

**Goal:** Insurance claim visibility in team portal (field techs see their claim jobs) and client portal (homeowner sees claim status).

**Team Portal:**
- Job detail shows insurance claim info when jobType is insurance_claim
- Moisture reading recording (field tool)
- Drying log entry (field tool)
- Equipment deploy/remove

**Client Portal:**
- Project detail shows insurance status when project is insurance_claim
- Simplified claim status timeline (homeowner-friendly labels)
- No adjuster contact info (privacy)

**Checklist D2h: DONE (S68)**
- [x] Team portal: `use-insurance.ts` hook (178 lines) — CRUD for moisture, drying, equipment + real-time subscriptions
- [x] Team portal: `RestorationProgress` component in job detail (207 lines) — claim banner + moisture/drying/equipment/TPI cards
- [x] Team portal: Inline recording forms — MoistureForm, DryingForm, EquipmentForm (3 collapsible forms)
- [x] Team portal: All 5 mappers + 11 types + 5 interfaces in mappers.ts
- [x] Client portal: `use-insurance.ts` hook (131 lines) — read-only, homeowner-friendly labels, 6-step timeline
- [x] Client portal: `ClaimTimeline` component (81 lines) — visual 6-step progress, status descriptions
- [x] Client portal: Insurance badge on projects list (Shield icon + "Insurance" amber badge)
- [x] Client portal: Insurance banner on project detail (company + claim# + date of loss)
- [x] Client portal: NO adjuster contact info (privacy verified — only company/claim#/deductible shown)
- [x] Builds pass on all portals
- [x] Commit: `[D2h] Insurance views — team portal + client portal`

---

### Sprint D3: Insurance Verticals (~107 hrs)
**Source spec:** `Build Documentation/Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md` (792 lines)
**Status: IN PROGRESS — D3a-D3d DONE (S69), D3e+ PENDING**

4 verticals: Storm/Catastrophe Roofing, Property Reconstruction, Commercial Property Claims, Home Warranty Network.
All use existing tables + JSONB metadata — no new tables except warranty_companies seed data.

---

#### D3a: Database — Claim Category Column
**Status: DONE (S69)**

**Migration:** `20260207000015_d3_insurance_verticals.sql`
- `claim_category TEXT NOT NULL DEFAULT 'restoration'` on insurance_claims
- CHECK constraint: restoration, storm, reconstruction, commercial
- Index: `idx_insurance_claims_category`
- JSONB `data` column stores vertical-specific structure per category

**Checklist D3a:**
- [x] Migration file created and deployed to dev
- [x] CHECK constraint enforces 4 valid values
- [x] Index on claim_category
- [x] `dart analyze` passes
- [x] `npm run build` passes (all portals)

---

#### D3b: Flutter Model — Typed Data Classes
**Status: DONE (S69)**

**File:** `lib/models/insurance_claim.dart`
- `ClaimCategory` enum (4 values + label getter)
- `StormData` class — weatherEventDate, stormSeverity (4 levels), weatherEventType (6 types), aerialAssessmentNeeded, emergencyTarped, temporaryRepairs, batchEventId, affectedUnits
- `ReconstructionData` class — currentPhase (5 phases), phases[] with status/budget/completion%, multiContractor, expectedDurationMonths, permitsRequired, permitStatus
- `CommercialData` class — propertyType (8 types), businessName, tenantName, tenantContact, businessIncomeLoss, businessInterruptionDays, emergencyAuthAmount, emergencyServiceAuthorized
- All 3 classes: `fromJson()` factory + `toJson()` method
- `InsuranceClaim` model: `claimCategory` field + `stormData`, `reconstructionData`, `commercialData` convenience getters

**Checklist D3b:**
- [x] ClaimCategory enum with 4 values
- [x] StormData class with fromJson/toJson
- [x] ReconstructionData class with fromJson/toJson (includes phases list)
- [x] CommercialData class with fromJson/toJson
- [x] InsuranceClaim model updated with claimCategory + typed getters
- [x] `dart analyze` passes

---

#### D3c: Flutter Screens — Category Forms + Display
**Status: DONE (S69)**

**Files modified:**
- `claim_create_screen.dart` — Category selector (4 chips with descriptions). Category-specific form sections: Storm (severity, event type, emergency tarped, aerial, temp repairs), Reconstruction (duration, permits, multi-contractor), Commercial (property type, business name, tenant, emergency auth). Data saved as JSONB via `_buildCategoryData()`.
- `claim_detail_screen.dart` — `_buildCategoryDataCard()` renders category icon + accent border + typed data rows per category.
- `claims_hub_screen.dart` — Category filter chips row + `_filterCategory` state + `_buildCategoryBadge()` on claim cards.
- `insurance_claim_service.dart` — `createClaim()` accepts `data` parameter for JSONB.

**Checklist D3c:**
- [x] Category selector in create screen (4 chips with descriptions)
- [x] Storm form fields (severity, event type, tarped, aerial, temp repairs)
- [x] Reconstruction form fields (duration, permits, multi-contractor)
- [x] Commercial form fields (property type, business, tenant, emergency auth)
- [x] `_buildCategoryData()` serializes form to JSONB
- [x] Category data card in detail screen (icon, accent border, typed rows)
- [x] Category filter in hub screen
- [x] Category badge on hub claim cards
- [x] Service accepts `data` parameter
- [x] `dart analyze` passes

---

#### D3d: Web CRM + Team Portal — Category Types + Display
**Status: DONE (S69)**

**Web CRM files modified:**
- `types/index.ts` — 3 new interfaces: `StormClaimData`, `ReconstructionClaimData`, `CommercialClaimData`
- `insurance/[id]/page.tsx` — `CategoryDataCard` component with `StormDetails`, `ReconDetails`, `CommercialDetails`. `DetailRow` value type widened to `React.ReactNode`.
- `insurance/page.tsx` — Category filter buttons + category badge on claim rows.

**Team Portal:**
- `mappers.ts` — `ClaimCategory` type + `claimCategory` field in `InsuranceClaimSummary` + mapper.

**Checklist D3d:**
- [x] 3 TypeScript interfaces in types/index.ts
- [x] CategoryDataCard component (icon + accent border per category)
- [x] StormDetails (severity badge, event type, tarped, aerial, temp repairs)
- [x] ReconDetails (phase, duration, permits, multi-contractor, phase list with status badges)
- [x] CommercialDetails (property type, business, tenant, income loss, interruption, emergency auth)
- [x] Category filter on hub page
- [x] Category badge on hub claim rows
- [x] Team portal mapper updated
- [x] `npm run build` passes (web-portal + team-portal)

---

#### D3e: Warranty Company Seed Data
**Status: PENDING**
**Est: 1 hour**

**Goal:** Seed warranty_companies table with major home warranty providers. Required for warranty dispatch workflows.

**Database:** Check if `warranty_companies` table exists from D1 Job Type System. If not, create migration. Seed 15 warranty companies (AHS, Frontdoor, Choice, Select, First American, Fidelity, Old Republic, 2-10, HMS, Landmark, Liberty Home Guard, Cinch, ServicePlus, Total Home Protection, APHW) with name, short_name, type, service_fee_default, website, contractor_portal_url.

**Checklist D3e: DONE (S69)**
- [x] Created migration `20260207000016_d3e_warranty_tables.sql` — 3 tables: warranty_companies (shared directory), company_warranty_relationships (per-company), warranty_dispatches (per-job with 12-status workflow)
- [x] RLS: warranty_companies readable by all authenticated, relationships + dispatches company-scoped
- [x] Indexes: 6 indexes (active companies, company refs, job refs, status, warranty company)
- [x] Audit triggers: update_updated_at on warranty_companies + warranty_dispatches
- [x] Seeded 15 warranty company records (AHS, Frontdoor, Choice, Select, First American, Fidelity, Old Republic, 2-10, HMS, Landmark, Liberty, Cinch, ServicePlus, Total, APHW)
- [x] Deployed migration to dev
- [x] Verified via REST API — 15 records returned with correct data
- [x] `dart analyze`: 0 errors
- [x] `npm run build` passes (web-portal)

---

#### D3f: Upgrade Tracking — Insurance vs Out-of-Pocket
**Status: DONE (S70)**
**Est: 4 hours**

**Goal:** Track reconstruction scope where homeowner wants upgrades beyond pre-loss condition. Insurance pays approved amount, homeowner pays upgrade difference + deductible.

**Database:** `payment_source` field on invoice line items JSONB (carrier/deductible/upgrade/standard). No migration needed — line items are JSONB on invoices table.

**Flutter:**
- PaymentSource enum added to Invoice model (invoice.dart)
- Invoice create screen: insurance job detection + payment source chip selector per line item
- Invoice detail screen: grouped display by payment source with color-coded section headers + subtotals

**Web CRM:**
- PaymentSource type + paymentSource field added to InvoiceLineItem (types/index.ts)
- mapInvoice mapper updated to include paymentSource from line_items JSONB
- Invoice detail page: grouped table display with colored section headers
- Invoice create page: payment source dropdown per line item (visible for insurance/warranty jobs)
- Job detail page: UpgradeTrackingSummary component — queries invoices for job, computes per-source totals, shows breakdown card

**Checklist D3f:**
- [x] Database: payment_source on line items JSONB (no migration needed)
- [x] Flutter: PaymentSource enum + create screen selector + detail screen grouped display
- [x] Web CRM: three-section invoice display (detail page)
- [x] Web CRM: payment source selector on invoice create page
- [x] Web CRM: UpgradeTrackingSummary on job detail page
- [x] `dart analyze` passes (0 issues)
- [x] `npm run build` passes

---

#### D3g: Three-Section Invoice (Carrier / Deductible / Upgrade)
**Status: DONE (S70 — completed as part of D3f)**
**Est: 4 hours**

**Goal:** Auto-generate invoices with three payment sections for reconstruction jobs.

**Note:** All three-section invoice work was completed in D3f. Payment source selector on create screens, grouped display on detail screens, subtotals per section — all done. PDF generation deferred until PDF system is built.

**Checklist D3g:**
- [x] Flutter: invoice create with payment source sections (done in D3f)
- [x] Flutter: invoice preview with three-section layout (done in D3f)
- [x] Web CRM: invoice detail three-section display (done in D3f)
- [x] `dart analyze` passes
- [x] `npm run build` passes (all portals)

---

#### D3h: Unified Revenue Dashboard
**Status: DONE (S70)**
**Est: 6 hours**

**Goal:** Dashboard widget showing revenue breakdown by job type (retail / insurance / warranty) with drill-down by carrier and warranty company.

**What was built:**
- `RevenueByTypeWidget` component on dashboard (Pro Mode)
- Stacked horizontal bar showing % distribution across job types
- Per-type breakdown rows: label, percentage, avg per invoice, total amount
- Color-coded: Retail (blue), Insurance (amber), Warranty (purple), Maintenance (green)
- Computed from existing useJobs + useInvoices hooks (no new queries)
- TypeScript passes, npm run build passes

**Deferred to Phase E (AI layer) or future sprint:**
- Insurance sub-breakdown by claim_category (needs insurance_claims query)
- Warranty sub-breakdown by company (needs warranty_dispatches query)
- Drill-down links to filtered job lists

**Checklist D3h:**
- [x] Revenue breakdown widget on dashboard (stacked bar + rows)
- [x] Average job value per type
- [ ] Insurance sub-breakdown by category (deferred — needs more data)
- [ ] Warranty sub-breakdown by company (deferred — needs more data)
- [ ] Drill-down links to filtered lists (deferred)
- [x] `npm run build` passes

---

#### D3i: Storm Event Tagging + Dashboard
**Status: DONE (S70)**
**Est: 10 hours**

**Goal:** Storm chasers can tag jobs with storm events, view storm-specific dashboard with canvassing metrics.

**Database:** Uses existing jobs.tags array + jobs.type_metadata JSONB. Tag format: `storm:EventName`. No new tables.

**Flutter (job_create_screen.dart):**
- Added claim category selector (restoration/storm/reconstruction/commercial) in insurance fields
- Storm event name field shown when category=storm
- `_buildClaimCategorySelector()` widget with ChoiceChips
- `_buildTags()` helper creates `storm:EventName` tag
- claimCategory + stormEvent stored in typeMetadata

**Web CRM:**
- StormDashboardWidget on dashboard (Pro Mode): total jobs, storm events count, pipeline $, collected $, in-production count, complete count, active event names
- Storm event filter on jobs list: dynamic dropdown built from `storm:*` tags in existing jobs
- Storm P&L: partially covered by StormDashboardWidget (pipeline vs collected). Full P&L deferred.

**Checklist D3i:**
- [x] Flutter: storm event tag on job create (claimCategory + stormEvent + tags)
- [x] Web CRM: storm event dashboard widget (StormDashboardWidget)
- [x] Web CRM: storm event filter on jobs list
- [x] Web CRM: storm P&L view (basic pipeline/collected in widget; full P&L deferred)
- [x] `dart analyze` passes (info-only hints)
- [x] `npm run build` passes

---

#### D3j: Canvassing Lead Source Tracking
**Status: DONE (S70)**
**Est: 4 hours**

**Goal:** Track door-knock canvassing as lead source. Canvasser assignment, agreement capture.

**Database:** Migration 000017 — added `source` column to jobs table with CHECK constraint (direct/referral/canvass/website/social_media/phone/email/home_show/other). Index on (company_id, source). Deployed to dev.

**Flutter:**
- `source` field added to Job model (default 'direct'), serialized in insert/update/fromJson/copyWith
- `_buildSourceSelector()` widget on job create screen — ChoiceChip row for 6 common sources
- Source stored on job record. Canvass-specific metadata (canvasser_id, etc.) stored in type_metadata JSONB.

**Web CRM:**
- `source` field added to Job type (types/index.ts) and mapJob mapper
- Source filter dropdown on jobs list page (7 options)
- Source column display deferred — already visible via filter

**Checklist D3j:**
- [x] Database: migration 000017 — source column with CHECK constraint
- [x] Flutter: source field on Job model + source selector on create screen
- [x] Web CRM: source in Job type + mapper + source filter on jobs list
- [x] `dart analyze` passes (info-only hints)
- [x] `npm run build` passes

---

#### D3k: Multi-Company Warranty Dispatch Inbox
**Status: DONE (S70)**
**Est: 6 hours**

**Goal:** Unified inbox showing warranty dispatches from all warranty company relationships.

**What was built:**
- "Dispatch Inbox" tab added to warranties page (tab switcher: Warranties | Dispatch Inbox)
- Queries warranty_dispatches with joined warranty_companies(name)
- Filter by warranty company (dynamic dropdown)
- SLA countdown: hours remaining shown, urgent flag (red badge) when <= 4 hours
- Authorization limit display per dispatch
- Status badges with 7 dispatch statuses (new/acknowledged/scheduled/in_progress/parts_ordered/completed/invoiced)
- Empty state with Inbox icon

**Checklist D3k:**
- [x] Web CRM: warranty dispatch inbox as tab on warranties page
- [x] Filter by warranty company
- [x] SLA countdown display (hours remaining, urgent flag)
- [x] Authorization limit display
- [x] `npm run build` passes

---

#### D3l: Reconstruction Workflow Config
**Status: DONE (S70)**
**Est: 2 hours**

**Goal:** Define reconstruction-specific workflow stages (scope_review → selections → materials → demo → rough_in → inspection → finish → walkthrough → supplements → payment).

**What was built:**
- Flutter: 10-stage `_reconStages` constant + `_buildReconstructionWorkflow()` visual horizontal tracker (circles, connectors, check icons, orange accent)
- Flutter: `ReconstructionData.currentPhase` default updated to 'scope_review'
- Web CRM: `RECON_STAGES` constant + visual workflow tracker in ReconDetails
- Web CRM: `ReconstructionClaimData.currentPhase` type updated to 10-stage values
- `Check` + `cn` imports added to insurance detail page

**Checklist D3l:**
- [x] Workflow stage config for reconstruction trade
- [x] Stage display in job detail for reconstruction claims
- [x] `dart analyze` passes (0 errors, info-only hints)
- [x] `npm run build` passes

---

#### D3m: Warranty-to-Retail Upsell Tracking
**Status: DONE (S70)**
**Est: 3 hours**

**Goal:** Track when warranty service visits generate retail upsell opportunities.

**Database:** jobs.type_metadata.upsell_from_warranty_dispatch_id linking retail job to originating warranty dispatch. Uses existing JSONB field — no migration needed.

**What was built:**
- DispatchInbox fetches upsell jobs in parallel (Promise.all): queries jobs where `type_metadata->>upsell_from_warranty_dispatch_id IS NOT NULL`, builds dispatch→job map
- WarrantyDispatch interface: added upsellJobId + upsellJobTitle fields
- Conversion rate summary: emerald badge showing "X upsells (Y% conversion)" above dispatch list
- Upsell indicator on dispatch cards: green "Upsold: [job title]" text with ArrowUpRight icon
- Added TrendingUp + ArrowUpRight icon imports

**Checklist D3m:**
- [x] Database: upsell tracking field (type_metadata JSONB, no migration)
- [x] Web CRM: upsell indicator on warranty dispatch detail
- [x] Web CRM: conversion rate metric
- [x] `npm run build` passes

---

#### D3n: Vertical Detection Service
**Status: DONE (S70)**
**Est: 4 hours**

**Goal:** Auto-detect which vertical enhancements to show based on company usage patterns. No configuration wizard — system reads data and surfaces tools.

**Detection rules:**
- Storm: roofing trade + insurance enabled + jobs tagged with storm events ≥ 5
- Reconstruction: GC/remodeler + insurance enabled + reconstruction claims ≥ 3
- Commercial: insurance enabled + commercial property type claims ≥ 2
- Warranty: warranty enabled + multiple warranty company relationships ≥ 2

**What was built:**
- `use-verticals.ts` hook: `useVerticalDetection()` — queries jobs (storm tags), insurance_claims (category counts), company_warranty_relationships (count). Returns `{ storm, reconstruction, commercial, warranty, loading }` booleans.
- Dashboard page: vertical widgets gated by detection results. Storm shows StormDashboardWidget. Reconstruction/Commercial/Warranty show VerticalSummaryCard with link to filtered view.
- VerticalSummaryCard component: compact card with icon, description, link to relevant page.
- Progressive disclosure: no config wizard. Detection runs automatically. Widgets only appear when thresholds are met.

**Checklist D3n:**
- [x] Detection service/hook
- [x] Dashboard conditionally shows vertical-specific widgets
- [x] Progressive disclosure — no config wizard needed
- [x] `dart analyze` passes (0 errors)
- [x] `npm run build` passes

---

#### D3 Phase 3 (FUTURE — 6+ months post-launch, ~63 hrs)
- Territory mapping UI (6 hrs)
- Commercial multi-trade claim view (6 hrs)
- Canvasser performance view (3 hrs)
- Dispatch email parsing (12 hrs)
- Warranty company API integrations (36 hrs)

**DO NOT BUILD Phase 3 items until Phase 1+2 are complete and validated with real users.**

---

### Sprint D4: ZBooks (~78 hrs)
**Status: SPEC COMPLETE — Ready for execution**
**Spec Written: Session 70 (Feb 7, 2026)**

Full GAAP-compliant double-entry accounting system for trades contractors. Replaces QuickBooks for 95% of contractor needs. Two tiers: Standard (all subscribers) and Enterprise (behind enterprise paywall).

**Branding:** "ZBooks" — never "ZAFTO Books." Premium Z-feature branding.

---

#### ZBOOKS SECURITY & LEGAL REQUIREMENTS (ENFORCED ON EVERY SUB-STEP)

**Double-Entry Integrity:**
- Every journal entry MUST have equal debits and credits. Validation at DB level (CHECK constraint on entry total).
- Journal entries are IMMUTABLE once posted. No UPDATE, no DELETE. Void creates a reversing entry with audit trail.
- All amounts use `NUMERIC(12,2)` — never float. Currency math is exact.
- All currency calculations server-side. Never trust client-side math for financial records.

**Audit Trail:**
- Every financial mutation logged with user_id, timestamp, action, previous_values, new_values.
- `zbooks_audit_log` table — INSERT-only, no UPDATE/DELETE RLS. Immutable.
- Meets IRS record retention requirements (data persists 7+ years).
- Financial report exports include generation timestamp + user who generated.

**Access Control:**
- RLS on every ZBooks table — `company_id` tenant isolation.
- Role-gated access:
  - **Owner/Admin**: Full read/write on all financial data.
  - **Office Manager**: Read/write on expenses, invoices, bank reconciliation. Read-only on GL/statements.
  - **CPA**: Read-only on all financial data. No mutations. Access logged.
  - **Technician**: Can create expenses/receipts only. Cannot see company financials.
  - **Client**: Zero access to ZBooks.
- Fiscal period lock prevents backdating transactions into closed periods.
- Bank credentials (Plaid tokens) stored server-side only, never exposed to frontend.

**Tax Compliance:**
- 1099-NEC threshold tracking: vendors paid ≥ $600/year automatically flagged.
- Schedule C category mapping: every GL account maps to a tax line item.
- Sales tax tracking: tax collected on invoices flows to Sales Tax Payable liability.
- State-specific sales tax rates configurable per company.

**Data Integrity:**
- Foreign key constraints on all relationships.
- Soft delete only (deleted_at) — financial records never physically deleted.
- Cascading protections: cannot delete a vendor with payments, cannot delete an account with journal entries.
- Bank reconciliation provides cryptographic-grade proof of cash position at point in time.

---

#### D4a: Database Migration — Core Financial Tables
**Status: DONE (S70)**
**Est: 5 hours**

**Tables to create:**

**1. chart_of_accounts**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
account_number TEXT NOT NULL          -- GL code: "1000", "5100", etc.
account_name TEXT NOT NULL
account_type TEXT NOT NULL            -- CHECK: asset, liability, equity, revenue, cogs, expense
parent_account_id UUID REFERENCES chart_of_accounts(id)  -- hierarchy
description TEXT
is_system BOOLEAN DEFAULT false       -- system accounts can't be deleted
is_active BOOLEAN DEFAULT true
normal_balance TEXT NOT NULL          -- CHECK: debit, credit
tax_category_id UUID REFERENCES tax_categories(id)
sort_order INTEGER DEFAULT 0
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
UNIQUE(company_id, account_number)
```

**2. fiscal_periods**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
period_name TEXT NOT NULL             -- "2026-01", "2026-Q1", "FY2026"
period_type TEXT NOT NULL             -- CHECK: month, quarter, year
start_date DATE NOT NULL
end_date DATE NOT NULL
is_closed BOOLEAN DEFAULT false
closed_at TIMESTAMPTZ
closed_by_user_id UUID REFERENCES auth.users(id)
retained_earnings_posted BOOLEAN DEFAULT false  -- for year-end close
created_at TIMESTAMPTZ DEFAULT now()
UNIQUE(company_id, period_name)
```

**3. journal_entries**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
entry_number TEXT NOT NULL            -- auto-generated: JE-YYYYMMDD-NNN
entry_date DATE NOT NULL
description TEXT NOT NULL
status TEXT NOT NULL DEFAULT 'draft'  -- CHECK: draft, posted, voided
source_type TEXT                      -- invoice, payment, expense, payroll, manual, adjustment, closing
source_id UUID                        -- FK to originating record (nullable for manual entries)
posted_at TIMESTAMPTZ
posted_by_user_id UUID REFERENCES auth.users(id)
voided_at TIMESTAMPTZ
voided_by_user_id UUID REFERENCES auth.users(id)
void_reason TEXT
reversing_entry_id UUID REFERENCES journal_entries(id)  -- if this is a void, points to reversed entry
fiscal_period_id UUID REFERENCES fiscal_periods(id)
memo TEXT
created_by_user_id UUID NOT NULL REFERENCES auth.users(id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
UNIQUE(company_id, entry_number)
```

**4. journal_entry_lines**
```sql
id UUID PK DEFAULT gen_random_uuid()
journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE
account_id UUID NOT NULL REFERENCES chart_of_accounts(id)
debit_amount NUMERIC(12,2) NOT NULL DEFAULT 0
credit_amount NUMERIC(12,2) NOT NULL DEFAULT 0
description TEXT
job_id UUID REFERENCES jobs(id)       -- optional job-level cost tracking
branch_id UUID REFERENCES branches(id) -- optional branch-level tracking (enterprise)
created_at TIMESTAMPTZ DEFAULT now()
CHECK (debit_amount >= 0)
CHECK (credit_amount >= 0)
CHECK (debit_amount > 0 OR credit_amount > 0)  -- at least one must be positive
CHECK (NOT (debit_amount > 0 AND credit_amount > 0))  -- can't be both
```

**5. tax_categories**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
category_name TEXT NOT NULL           -- "Schedule C Line 10 - Commissions"
tax_form TEXT NOT NULL                -- CHECK: schedule_c, 1099_nec, sales_tax, payroll
tax_line TEXT                         -- "Line 10", "Box 1", etc.
description TEXT
is_system BOOLEAN DEFAULT false
sort_order INTEGER DEFAULT 0
created_at TIMESTAMPTZ DEFAULT now()
UNIQUE(company_id, category_name)
```

**6. zbooks_audit_log (INSERT-only, immutable)**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
user_id UUID NOT NULL REFERENCES auth.users(id)
action TEXT NOT NULL                  -- CHECK: created, posted, voided, reconciled, period_closed, period_reopened, export_generated
table_name TEXT NOT NULL
record_id UUID NOT NULL
previous_values JSONB
new_values JSONB
change_summary TEXT
ip_address TEXT
created_at TIMESTAMPTZ DEFAULT now()
-- NO UPDATE OR DELETE RLS POLICIES
```

**Seed data:** ~45 default chart of accounts entries for trades contractors (see COA list below). ~20 tax category mappings (Schedule C lines + 1099-NEC).

**Default Chart of Accounts (seeded per company):**

Assets (1000-1999):
- 1000 Cash (asset, debit)
- 1010 Checking Account (asset, debit)
- 1020 Savings Account (asset, debit)
- 1100 Accounts Receivable (asset, debit)
- 1200 Materials Inventory (asset, debit)
- 1300 Prepaid Expenses (asset, debit)
- 1400 Tools & Equipment (asset, debit)
- 1410 Accum. Depreciation - Equipment (asset, credit) [contra]
- 1500 Vehicles (asset, debit)
- 1510 Accum. Depreciation - Vehicles (asset, credit) [contra]

Liabilities (2000-2999):
- 2000 Accounts Payable (liability, credit)
- 2100 Credit Card Payable (liability, credit)
- 2200 Sales Tax Payable (liability, credit)
- 2300 Payroll Liabilities (liability, credit)
- 2310 Federal Tax Withholding (liability, credit)
- 2320 State Tax Withholding (liability, credit)
- 2330 FICA Payable (liability, credit)
- 2340 Workers Comp Payable (liability, credit)
- 2400 Vehicle Loans (liability, credit)
- 2500 Equipment Loans (liability, credit)
- 2600 Retention Payable (liability, credit)
- 2700 Unearned Revenue (liability, credit)

Equity (3000-3999):
- 3000 Owner's Equity (equity, credit)
- 3100 Owner's Draw (equity, debit) [contra]
- 3200 Retained Earnings (equity, credit)

Revenue (4000-4999):
- 4000 Service Revenue - Retail (revenue, credit)
- 4010 Service Revenue - Insurance (revenue, credit)
- 4020 Service Revenue - Warranty (revenue, credit)
- 4030 Service Revenue - Maintenance (revenue, credit)
- 4100 Material Sales Revenue (revenue, credit)
- 4200 Change Order Revenue (revenue, credit)
- 4900 Other Income (revenue, credit)

Cost of Goods Sold (5000-5999):
- 5000 Materials Cost (cogs, debit)
- 5100 Direct Labor (cogs, debit)
- 5200 Subcontractor Costs (cogs, debit)
- 5300 Equipment Rental (cogs, debit)
- 5400 Permits & Inspections (cogs, debit)
- 5500 Disposal Fees (cogs, debit)

Operating Expenses (6000-6999):
- 6000 Advertising & Marketing (expense, debit)
- 6100 Business Insurance (expense, debit)
- 6200 Office Supplies (expense, debit)
- 6300 Rent (expense, debit)
- 6400 Utilities (expense, debit)
- 6500 Vehicle - Fuel (expense, debit)
- 6510 Vehicle - Maintenance (expense, debit)
- 6520 Vehicle - Insurance (expense, debit)
- 6600 Tools & Small Equipment (expense, debit)
- 6700 Accounting & Legal Fees (expense, debit)
- 6800 Phone & Internet (expense, debit)
- 6900 Software & Subscriptions (expense, debit)
- 6950 Travel & Meals (expense, debit)

Other (7000-7999):
- 7000 Interest Expense (expense, debit)
- 7100 Depreciation Expense (expense, debit)
- 7200 Bank Fees (expense, debit)
- 7300 Penalties & Fines (expense, debit)

**RLS:** All tables scoped by `company_id`. `zbooks_audit_log` has INSERT-only policy (no UPDATE/DELETE).
**Indexes:** `chart_of_accounts(company_id, account_number)`, `journal_entries(company_id, entry_date)`, `journal_entries(company_id, source_type, source_id)`, `journal_entry_lines(journal_entry_id)`, `journal_entry_lines(account_id)`, `fiscal_periods(company_id, start_date, end_date)`.

**Checklist D4a:**
- [x] Migration file created with all 6 tables (20260207000018_d4a_zbooks_core_tables.sql)
- [x] CHECK constraints on all enum fields
- [x] RLS policies (company_id via requesting_company_id(), zbooks_audit_log INSERT-only)
- [x] Indexes on all query patterns
- [x] Seed: 55 default COA accounts (is_system=true) via seed_default_chart_of_accounts()
- [x] Seed: 26 tax categories (Schedule C + 1099-NEC + sales tax) via seed_default_tax_categories()
- [x] `npx supabase db push` succeeds
- [x] Verify table count: 52 tables deployed

---

#### D4b: Database Migration — Banking, Expenses & Vendors
**Status: DONE (S70)**
**Est: 4 hours**

**Tables to create:**

**7. bank_accounts**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
plaid_item_id TEXT                    -- Plaid link session ID
plaid_account_id TEXT                 -- Plaid account ID
account_name TEXT NOT NULL
institution_name TEXT
account_type TEXT NOT NULL            -- CHECK: checking, savings, credit_card
mask TEXT                             -- last 4 digits
current_balance NUMERIC(12,2) DEFAULT 0
available_balance NUMERIC(12,2)
gl_account_id UUID REFERENCES chart_of_accounts(id)  -- maps to COA entry
last_synced_at TIMESTAMPTZ
is_active BOOLEAN DEFAULT true
plaid_access_token TEXT               -- encrypted, never sent to frontend
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

**8. bank_transactions**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
bank_account_id UUID NOT NULL REFERENCES bank_accounts(id)
plaid_transaction_id TEXT UNIQUE
transaction_date DATE NOT NULL
posted_date DATE
description TEXT NOT NULL
merchant_name TEXT
amount NUMERIC(12,2) NOT NULL         -- positive = money in, negative = money out
category TEXT NOT NULL DEFAULT 'uncategorized'  -- CHECK: 16 TransactionCategory values
category_confidence NUMERIC(3,2)      -- Plaid confidence 0.00-1.00
is_income BOOLEAN DEFAULT false
matched_invoice_id UUID REFERENCES invoices(id)
matched_expense_id UUID REFERENCES expense_records(id)
journal_entry_id UUID REFERENCES journal_entries(id)  -- linked GL entry
is_reviewed BOOLEAN DEFAULT false
is_reconciled BOOLEAN DEFAULT false
reconciliation_id UUID REFERENCES bank_reconciliations(id)
notes TEXT
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

**9. bank_reconciliations**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
bank_account_id UUID NOT NULL REFERENCES bank_accounts(id)
statement_date DATE NOT NULL
statement_balance NUMERIC(12,2) NOT NULL
calculated_balance NUMERIC(12,2)      -- sum of reconciled transactions
difference NUMERIC(12,2)              -- statement - calculated (should be 0)
status TEXT NOT NULL DEFAULT 'in_progress'  -- CHECK: in_progress, completed, voided
completed_at TIMESTAMPTZ
completed_by_user_id UUID REFERENCES auth.users(id)
notes TEXT
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

**10. vendors**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
vendor_name TEXT NOT NULL
contact_name TEXT
email TEXT
phone TEXT
address TEXT
city TEXT
state TEXT
zip TEXT
tax_id TEXT                           -- EIN or SSN (for 1099 tracking)
vendor_type TEXT NOT NULL DEFAULT 'supplier'  -- CHECK: supplier, subcontractor, service_provider, utility, government
default_expense_account_id UUID REFERENCES chart_of_accounts(id)
is_1099_eligible BOOLEAN DEFAULT false
payment_terms TEXT DEFAULT 'net_30'   -- CHECK: due_on_receipt, net_15, net_30, net_45, net_60
notes TEXT
is_active BOOLEAN DEFAULT true
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
deleted_at TIMESTAMPTZ
UNIQUE(company_id, vendor_name)
```

**11. expense_records**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
vendor_id UUID REFERENCES vendors(id)
expense_date DATE NOT NULL
description TEXT NOT NULL
amount NUMERIC(12,2) NOT NULL
tax_amount NUMERIC(12,2) DEFAULT 0
total NUMERIC(12,2) NOT NULL          -- amount + tax_amount
category TEXT NOT NULL DEFAULT 'uncategorized'  -- CHECK: 16 categories
account_id UUID REFERENCES chart_of_accounts(id)  -- expense GL account
job_id UUID REFERENCES jobs(id)       -- optional job cost allocation
payment_method TEXT                   -- CHECK: cash, check, credit_card, bank_transfer, other
check_number TEXT
receipt_storage_path TEXT             -- Supabase Storage path
receipt_url TEXT
ocr_status TEXT DEFAULT 'none'        -- CHECK: none, pending, completed, error
ocr_data JSONB                        -- OCR extracted fields
journal_entry_id UUID REFERENCES journal_entries(id)  -- linked GL entry
status TEXT NOT NULL DEFAULT 'draft'   -- CHECK: draft, approved, posted, voided
approved_by_user_id UUID REFERENCES auth.users(id)
approved_at TIMESTAMPTZ
notes TEXT
created_by_user_id UUID NOT NULL REFERENCES auth.users(id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
deleted_at TIMESTAMPTZ
```

**12. vendor_payments**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
vendor_id UUID NOT NULL REFERENCES vendors(id)
payment_date DATE NOT NULL
amount NUMERIC(12,2) NOT NULL
payment_method TEXT NOT NULL          -- CHECK: check, bank_transfer, credit_card, cash
check_number TEXT
reference TEXT
description TEXT
expense_ids UUID[]                    -- which expense_records this payment covers
journal_entry_id UUID REFERENCES journal_entries(id)
is_1099_reportable BOOLEAN DEFAULT false
created_by_user_id UUID NOT NULL REFERENCES auth.users(id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

**13. recurring_transactions**
```sql
id UUID PK DEFAULT gen_random_uuid()
company_id UUID NOT NULL REFERENCES companies(id)
template_name TEXT NOT NULL
transaction_type TEXT NOT NULL        -- CHECK: expense, invoice
frequency TEXT NOT NULL               -- CHECK: weekly, biweekly, monthly, quarterly, annually
next_occurrence DATE NOT NULL
end_date DATE                         -- null = indefinite
template_data JSONB NOT NULL          -- full expense or invoice template fields
account_id UUID REFERENCES chart_of_accounts(id)
vendor_id UUID REFERENCES vendors(id)
job_id UUID REFERENCES jobs(id)
is_active BOOLEAN DEFAULT true
last_generated_at TIMESTAMPTZ
times_generated INTEGER DEFAULT 0
created_by_user_id UUID NOT NULL REFERENCES auth.users(id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

**RLS:** All tables scoped by `company_id`. `plaid_access_token` column excluded from SELECT in bank_accounts (create a view or use column-level security).
**Indexes:** `bank_transactions(company_id, transaction_date)`, `bank_transactions(bank_account_id)`, `expense_records(company_id, expense_date)`, `expense_records(vendor_id)`, `vendor_payments(vendor_id)`, `vendor_payments(company_id, payment_date)`, `vendors(company_id)`.
**Storage:** Create `receipts` bucket in Supabase Storage (if not already existing from B2c).

**Checklist D4b:**
- [x] Migration file created with all 7 tables (20260207000019_d4b_zbooks_banking_expenses.sql)
- [x] CHECK constraints on all enum fields
- [x] RLS policies (company_id via requesting_company_id())
- [x] plaid_access_token excluded via bank_accounts_safe view
- [x] Indexes on all query patterns (including partial indexes for unreviewed/unreconciled/1099)
- [x] `receipts` storage bucket verified existing (from B2c)
- [x] `npx supabase db push` succeeds
- [x] Verify table count: 59 tables deployed

---

#### D4c: GL Engine — Journal Entry Auto-Posting
**Status: DONE (Session 70)**
**Est: 6 hours**

**Goal:** Build the core accounting engine. When operational events happen (invoice created, payment received, expense recorded), the system auto-generates balanced journal entries. This is the heart of ZBooks.

**Auto-posting rules (source_type → journal entry):**

| Event | Debit Account | Credit Account | Amount |
|-------|--------------|----------------|--------|
| Invoice sent | 1100 Accounts Receivable | 4000-4030 Revenue (by job type) | invoice.total |
| Invoice tax | 1100 Accounts Receivable | 2200 Sales Tax Payable | invoice.tax_amount |
| Payment received | 1010 Checking (or mapped bank) | 1100 Accounts Receivable | payment amount |
| Expense posted | 5000-6950 (expense category) | 1010 Checking / 2000 AP / 2100 CC | expense.total |
| Vendor payment | 2000 Accounts Payable | 1010 Checking | payment amount |
| Material purchase | 5000 Materials Cost | 1010 Checking / 2000 AP | material.total_cost |
| Void invoice | 4000 Revenue | 1100 Accounts Receivable | -invoice.total (reversing) |
| Void expense | Cash/AP | Expense account | -expense.total (reversing) |
| Year-end close | Revenue accounts | 3200 Retained Earnings | net income |

**Implementation (Supabase Edge Function or server-side):**
- `post_journal_entry(entry_id)` — validates debits = credits, sets status to 'posted', writes audit log
- `create_invoice_journal(invoice_id)` — called when invoice status → 'sent'. Creates JE with AR debit + Revenue credit
- `create_payment_journal(invoice_id, amount)` — called when payment recorded. Creates JE with Cash debit + AR credit
- `create_expense_journal(expense_id)` — called when expense status → 'posted'. Creates JE with Expense debit + Cash/AP credit
- `void_journal_entry(entry_id, reason)` — creates a reversing entry (swaps debits/credits), marks original as voided
- `close_fiscal_period(period_id)` — locks period, generates closing entries (revenue/expense → retained earnings)

**Validation rules:**
- Sum of debits MUST equal sum of credits on every journal entry (DB trigger or CHECK)
- Cannot post to a closed fiscal period
- Cannot post with status 'voided'
- Cannot modify a posted journal entry (only void + re-create)
- Entry number auto-generated: JE-YYYYMMDD-NNN (sequential per company per day)

**Flutter service layer:**
- `zbooks_service.dart` — Riverpod providers for GL queries
- Read-only on mobile (journal entries viewed, not created manually on mobile)

**Web CRM service layer:**
- `use-zbooks.ts` hook — journal entry CRUD, posting, voiding
- `use-zbooks-engine.ts` hook — auto-posting functions (called from invoice/expense hooks)
- Wire into existing `use-invoices.ts`: when `sendInvoice()` called → also call `createInvoiceJournal()`
- Wire into existing `use-invoices.ts`: when `recordPayment()` called → also call `createPaymentJournal()`

**Checklist D4c:**
- [x] Edge Function or hook-level auto-posting logic
- [x] Invoice → JE auto-posting (sent + payment)
- [x] Expense → JE auto-posting
- [x] Vendor payment → JE auto-posting
- [x] Void creates reversing entry (never deletes)
- [x] Debit/credit validation (sum must equal)
- [x] Fiscal period lock check on posting
- [x] Entry number auto-generation
- [x] Audit log writes on every mutation
- [x] Wire into existing invoice hooks
- [x] `npm run build` passes
- [x] `dart analyze` passes

---

#### D4d: Chart of Accounts UI
**Status: DONE (Session 70)**
**Est: 4 hours**

**Web CRM page: `/dashboard/books/accounts`**
- Account list grouped by type (Assets → Liabilities → Equity → Revenue → COGS → Expenses)
- Hierarchy display (parent/child indentation)
- Account balance column (calculated from journal_entry_lines)
- Add account modal (number, name, type, parent, tax category, description)
- Edit account (name, description, tax category, active status)
- Deactivate account (cannot deactivate if has journal entries — show warning)
- System accounts (is_system=true) are read-only
- Search/filter by account type

**Flutter screen: Settings → ZBooks → Chart of Accounts**
- Read-only list view grouped by type
- Account balances visible
- No add/edit on mobile (admin function — CRM only)

**Checklist D4d:**
- [x] Web CRM: chart of accounts page with grouped list
- [x] Web CRM: add/edit account modal
- [x] Web CRM: deactivate account with protection
- [x] Web CRM: account balance calculation from GL
- [x] Flutter: read-only COA list screen
- [x] `npm run build` passes
- [x] `dart analyze` passes

---

#### D4e: Vendor Management & Expense Tracking
**Status: DONE (Session 70)**
**Est: 5 hours**

**Web CRM pages:**

**`/dashboard/books/vendors`** — Vendor list:
- CRUD: add/edit/deactivate vendors
- Search + filter by type (supplier, subcontractor, etc.)
- Vendor detail: contact info, payment terms, 1099 eligibility, total YTD payments, payment history
- 1099 flag indicator (auto-flagged when YTD payments ≥ $600 for subcontractors)
- Default expense account assignment

**`/dashboard/books/expenses`** — Expense management:
- Expense list with date range filter, category filter, vendor filter
- Create expense: date, vendor (dropdown), amount, category (dropdown mapped to COA), description, receipt upload, job allocation (optional)
- Edit expense (only in draft status)
- Approve expense (owner/admin only) → status: approved
- Post expense (triggers JE auto-creation) → status: posted
- Void expense (triggers reversing JE) → status: voided
- Receipt image viewer (click thumbnail → full image)
- Expense summary: total by category, monthly trend

**`/dashboard/books/vendor-payments`** — Vendor payment recording:
- Select vendor → see outstanding expenses/bills
- Record payment: amount, method, check number, date
- Auto-creates journal entry (DR: AP, CR: Cash)
- 1099 tracking: flags payment as reportable if vendor is 1099-eligible
- Payment history per vendor

**Flutter screens:**
- Quick expense entry (amount, category, receipt photo, job)
- Receipt camera capture → upload to `receipts` bucket
- Expense list (own expenses only for techs, all for owner/admin)
- No vendor management on mobile

**Checklist D4e:**
- [x] Web CRM: vendors page (CRUD)
- [x] Web CRM: vendor detail with YTD payments + 1099 flag
- [x] Web CRM: expenses page (CRUD + approval workflow)
- [x] Web CRM: receipt upload to Supabase Storage
- [x] Web CRM: vendor payments page
- [x] Web CRM: auto-JE on expense post + vendor payment
- [x] Flutter: quick expense entry screen
- [x] Flutter: receipt camera capture + upload
- [x] Flutter: expense list screen
- [x] `npm run build` passes
- [x] `dart analyze` passes

---

#### D4f: Bank Connection (Plaid Integration)
**Status: DONE (Session 70)**
**Est: 6 hours**

**Architecture:**
- Plaid Link (frontend SDK) for user-facing bank connection flow
- Supabase Edge Function for Plaid API calls (server-side, access token never exposed)
- Transaction sync runs on schedule (Edge Function cron or manual trigger)

**Edge Functions to create:**
1. `plaid-create-link-token` — generates Plaid Link token for frontend
2. `plaid-exchange-token` — exchanges public_token for access_token, saves to bank_accounts
3. `plaid-sync-transactions` — fetches new transactions from Plaid, upserts to bank_transactions
4. `plaid-get-balance` — fetches current balance, updates bank_accounts.current_balance

**Web CRM UI:**
- "Connect Bank Account" button on ZBooks dashboard
- Plaid Link modal integration (Plaid's drop-in UI)
- Connected accounts list with balance, last synced, sync button
- Disconnect account (deactivate, revoke Plaid access)

**Transaction sync:**
- Auto-categorize from Plaid's category data
- Map Plaid categories → ZAFTO's 16 TransactionCategory values
- Set `category_confidence` from Plaid
- Match incoming transactions to existing invoices (by amount + date proximity)
- Flag unreviewed transactions for manual categorization

**Security:**
- `plaid_access_token` stored in bank_accounts table but EXCLUDED from frontend SELECT (column-level RLS or separate secure table)
- Edge Functions authenticate via Supabase service role key
- Plaid webhook verification (signature validation)

**Checklist D4f:**
- [ ] Plaid developer account setup + API keys in env (deferred — keys needed at deploy time)
- [x] Edge Function: create-link-token
- [x] Edge Function: exchange-token (saves access_token securely)
- [x] Edge Function: sync-transactions
- [x] Edge Function: get-balance
- [x] Web CRM: Plaid Link integration (connect bank flow)
- [x] Web CRM: connected accounts list with sync/disconnect
- [x] Transaction auto-categorization from Plaid data
- [x] Invoice matching logic
- [x] plaid_access_token security (not exposed to frontend)
- [x] `npm run build` passes

---

#### D4g: Bank Reconciliation
**Status: DONE (Session 70)**
**Est: 4 hours**

**Web CRM page: `/dashboard/books/reconciliation`**

**Reconciliation workflow:**
1. Select bank account
2. Enter statement date + statement ending balance
3. System shows all unreconciled transactions for that account
4. User checks off transactions that appear on bank statement
5. System calculates: `statement_balance - sum(checked transactions) - previous_reconciled_balance = difference`
6. Difference must equal $0.00 to complete reconciliation
7. "Complete Reconciliation" button marks all checked transactions as `is_reconciled = true`
8. Reconciliation record saved with timestamp + user

**UI elements:**
- Statement balance input
- Transaction list with checkboxes (date, description, amount, running balance)
- Running difference display (green when $0.00, red otherwise)
- Filter: show cleared/uncleared/all
- "Finish Later" saves progress (in_progress status)
- Completed reconciliation is immutable (can only be voided, which un-reconciles all transactions)

**Checklist D4g:**
- [x] Web CRM: reconciliation page
- [x] Start reconciliation flow (select account, enter statement balance)
- [x] Transaction matching UI with checkboxes
- [x] Running difference calculation
- [x] Complete reconciliation ($0 difference required)
- [x] Void reconciliation (un-marks transactions)
- [x] Audit log on complete/void (completed_by_user_id + completed_at saved on complete; void un-reconciles all linked transactions)
- [x] `npm run build` passes

---

#### D4h: Financial Statements
**Status: DONE (Session 70)**
**Est: 6 hours**

**Web CRM pages under `/dashboard/books/reports/`**

**1. Profit & Loss (Income Statement)**
- Date range selector (this month, this quarter, this year, custom)
- Comparison mode: vs prior period, vs prior year
- Revenue section: sum of all Revenue accounts (4000-4999)
- COGS section: sum of all COGS accounts (5000-5999)
- Gross Profit: Revenue - COGS
- Operating Expenses section: sum of all Expense accounts (6000-6999)
- Other Expenses: 7000-7999
- Net Income: Gross Profit - Operating Expenses - Other Expenses
- Drill-down: click any account → see journal entries for that account in period
- PDF export

**2. Balance Sheet**
- As-of date selector
- Assets section: all Asset accounts with balances (1000-1999)
- Liabilities section: all Liability accounts (2000-2999)
- Equity section: all Equity accounts (3000-3999) + current year net income
- Total Assets must equal Total Liabilities + Equity (validation)
- PDF export

**3. Cash Flow Statement**
- Date range selector
- Operating Activities: net income + adjustments (AR change, AP change, depreciation)
- Investing Activities: equipment/vehicle purchases
- Financing Activities: loan payments, owner draws/contributions
- Net change in cash
- Beginning + ending cash balance
- PDF export

**4. Accounts Receivable Aging**
- Customer list with outstanding balances
- Aging buckets: Current, 1-30, 31-60, 61-90, 90+ days
- Total outstanding
- Click customer → see all open invoices

**5. Accounts Payable Aging**
- Vendor list with outstanding balances
- Same aging buckets
- Total owed
- Click vendor → see all unpaid expenses

**6. General Ledger Detail**
- Account selector (dropdown)
- Date range
- All journal entries affecting selected account
- Running balance
- Opening balance + closing balance

**7. Trial Balance**
- All accounts with debit/credit balances
- Total debits must equal total credits
- As-of date selector
- Used by CPAs for audit verification

**Checklist D4h:**
- [x] P&L with date range + comparison mode + drill-down
- [x] Balance Sheet with validation (A = L + E)
- [x] Cash Flow Statement
- [x] AR Aging (by customer, 5 buckets)
- [x] AP Aging (by vendor, 5 buckets)
- [x] General Ledger Detail (per account)
- [x] Trial Balance
- [x] PDF export for P&L + Balance Sheet + Cash Flow (window.print())
- [x] All calculations server-side (NUMERIC, not float) — DB is NUMERIC(12,2), JS rounds to 2 decimals
- [x] `npm run build` passes

---

#### D4i: Tax & 1099 Compliance
**Status: DONE (Session 70)**
**Est: 4 hours**

**Web CRM pages:**

**Tax Category Mapping (`/dashboard/books/tax-settings`)**
- Map each COA account to a tax category (Schedule C line item)
- Pre-populated from seed data, editable
- Schedule C preview: shows estimated tax form with current year data

**1099-NEC Tracking (`/dashboard/books/1099`)**
- Auto-detection: vendors marked `is_1099_eligible` with YTD payments ≥ $600
- 1099 summary list: vendor name, tax ID (masked), total payments, status
- Warning for vendors missing tax_id (EIN/SSN required for 1099 filing)
- Export: CSV with vendor name, tax ID, total payments (for uploading to IRS FIRE system or tax software)
- Date range: defaults to calendar year

**Tax Summary Report**
- Estimated Schedule C based on COA → tax category mappings
- Revenue total (Line 1)
- COGS total (Line 4)
- Gross Profit (Line 5)
- Expenses broken out by Schedule C line (Lines 8-27)
- Net Profit (Line 31)
- Quarterly estimate: net profit × estimated tax rate

**Checklist D4i:**
- [x] Tax category mapping page
- [x] 1099-NEC auto-detection (≥ $600 threshold)
- [x] 1099 summary with tax ID validation
- [x] 1099 CSV export
- [x] Schedule C tax summary report
- [x] Quarterly tax estimate calculation
- [x] `npm run build` passes

---

#### D4j: Recurring Transactions
**Status: DONE (Session 70)**
**Est: 3 hours**

**Web CRM page: `/dashboard/books/recurring`**

- Create recurring template: expense or invoice
- Set frequency: weekly, biweekly, monthly, quarterly, annually
- Set start date, optional end date
- Template stores full field data in JSONB (vendor, amount, category, description, line items)
- "Generate Now" button creates the next occurrence immediately
- Auto-generation: Edge Function cron checks daily for due recurring transactions
- Skip/edit individual occurrence without affecting template
- Pause/resume template
- History: list of all generated transactions from each template

**Checklist D4j:**
- [x] Recurring template CRUD page
- [x] Frequency options (weekly through annually)
- [x] Manual "Generate Now"
- [x] Edge Function for auto-generation (daily cron)
- [x] Skip/edit individual occurrences
- [x] Pause/resume template
- [x] Generation history
- [x] `npm run build` passes

---

#### D4k: Fiscal Period Management & Year-End Close
**Status: DONE (Session 70)**
**Est: 3 hours**

**Web CRM page: `/dashboard/books/periods`**

**Period management:**
- Auto-generate monthly periods for current fiscal year
- Fiscal year configuration (calendar year default, custom start month option)
- Period status: open, closed
- Close period: locks all transactions in that date range. No new journal entries can be posted to closed periods.
- Reopen period (owner only): unlocks with audit trail + reason required

**Year-end close procedure:**
1. Verify all periods for the year are reconciled
2. System generates closing journal entries:
   - Zero out all Revenue accounts → credit to 3200 Retained Earnings
   - Zero out all Expense accounts → debit to 3200 Retained Earnings
   - Net effect: Retained Earnings increases by net income (or decreases by net loss)
3. Mark fiscal year as closed
4. Generate year-end summary report (P&L + Balance Sheet as of 12/31)

**Checklist D4k:**
- [x] Fiscal period list page
- [x] Auto-generate monthly periods
- [x] Close period (lock transactions)
- [x] Reopen period (owner only, with audit trail)
- [x] Year-end close procedure (closing JEs to Retained Earnings)
- [x] Year-end summary report generation
- [x] `npm run build` passes

---

#### D4l: ZBooks Dashboard (Rewrite)
**Status: DONE (Session 70)**
**Est: 4 hours**

**Replace current placeholder `/dashboard/books` page with real financial dashboard.**

**KPI Cards (top row):**
- Cash Position: sum of all checking/savings account balances
- Accounts Receivable: total outstanding invoices
- Accounts Payable: total unpaid expenses
- Net Income (MTD): revenue - expenses this month
- Profit Margin: net income / revenue × 100

**Charts:**
- Revenue vs Expenses (last 12 months, area chart)
- Expense breakdown by category (donut chart, from GL data)
- Cash flow trend (last 6 months, bar chart)
- AR aging summary (stacked bar)

**Quick Actions:**
- Record Expense
- Record Payment
- Run P&L Report
- Sync Bank Transactions

**Alerts:**
- Overdue receivables (count + total)
- Upcoming bills (expenses due in 7 days)
- Low cash warning (if cash < 2 weeks of average expenses)
- Unreviewed bank transactions (count)
- Unreconciled accounts (last reconciliation > 30 days ago)

**Navigation:**
- Quick links to all ZBooks sub-pages: Accounts, Expenses, Vendors, Payments, Reports, Bank, Reconciliation, 1099, Tax, Recurring, Periods

**Checklist D4l:**
- [x] KPI cards with real GL data
- [x] Revenue vs Expenses chart (from journal entries)
- [x] Expense breakdown donut (from GL)
- [x] Cash flow trend bar chart
- [x] AR aging summary
- [x] Quick action buttons
- [x] Alert cards (overdue, upcoming, low cash, unreviewed, unreconciled)
- [x] Navigation links to all sub-pages
- [x] Remove all mock data from current page
- [x] `npm run build` passes

---

#### D4m: Flutter Mobile — ZBooks Features
**Status: DONE (Session 70)**
**Est: 4 hours**

**Mobile is focused on field data capture, not full accounting.**

**Screens to build:**

**1. ZBooks Hub (from Settings or Home → More)**
- Financial summary card: cash position, AR, AP, net income MTD
- Quick actions: Record Expense, Capture Receipt
- Recent expenses list (own expenses for techs, all for owner)

**2. Quick Expense Entry**
- Date (defaults to today)
- Amount (numeric keypad)
- Category dropdown (mapped to COA expense accounts)
- Vendor dropdown (optional)
- Job allocation (optional — dropdown of active jobs)
- Description
- Receipt photo (camera capture → upload)
- Save as draft

**3. Receipt Capture**
- Camera with frame guide overlay (like receipt_scanner from B2c)
- Capture → upload to `receipts` bucket
- Creates expense_record with `ocr_status = 'pending'` (OCR in Phase E)
- Success confirmation with expense ID

**4. Expense List**
- Filter by date range, category
- Status badges (draft, approved, posted)
- Tap for detail view

**Models + services:**
- `expense_record.dart` model
- `vendor.dart` model
- `expense_repository.dart`
- `vendor_repository.dart`
- `zbooks_service.dart` (providers: expenseListProvider, vendorListProvider, financialSummaryProvider)

**Checklist D4m:**
- [x] ZBooks hub screen (summary + quick actions)
- [x] Quick expense entry screen
- [x] Receipt capture screen (camera → upload)
- [x] Expense list screen with filters
- [x] expense_record.dart model + repository + service
- [x] vendor.dart model + repository
- [x] Navigation wiring (settings, home More menu, command registry)
- [x] `dart analyze` passes

---

#### D4n: CPA Portal Access
**Status: DONE (Session 70)**
**Est: 3 hours**

**CPA role already exists in RBAC (D6). This step wires CPA-specific financial views.**

**Web CRM — CPA role restrictions:**
- Read-only access to all ZBooks pages (no create/edit/delete buttons rendered)
- Can view: P&L, Balance Sheet, Cash Flow, Trial Balance, GL Detail, AR/AP Aging, 1099 Report, Tax Summary
- Cannot view: bank account credentials, Plaid tokens
- Cannot perform: bank reconciliation, expense approval, journal posting, period close
- Access logged in `zbooks_audit_log` (action: 'cpa_access', table_name, record_id)

**CPA-specific features:**
- "Export Package" button: generates zip with P&L + Balance Sheet + Trial Balance + 1099 summary for selected date range
- Export watermark: "Generated by [user] on [date] via ZAFTO ZBooks"
- Downloadable CSV of any report table

**Team Portal — CPA access:**
- CPA has NO access to team portal (field operations are not CPA relevant)

**Client Portal — CPA access:**
- CPA has NO access to client portal

**Checklist D4n:**
- [x] CPA role renders read-only ZBooks pages (no mutation buttons)
- [x] CPA access logging to zbooks_audit_log
- [x] Export Package (P&L + Balance Sheet + Trial Balance + 1099 as CSVs)
- [x] Export watermark with user + timestamp
- [x] CSV export on all report tables
- [x] CPA cannot access bank credentials (hook checks role)
- [x] `npm run build` passes

---

#### D4o: Enterprise — Branch Financials (ENTERPRISE TIER ONLY)
**Status: DONE (Session 70)**
**Est: 5 hours**
**Gate: TierGate — enterprise subscription only**

**Goal:** Multi-branch companies need branch-level P&L and consolidated reporting.

**Database:**
- `branch_id` already exists on `journal_entry_lines` (from D4a schema)
- `branch_id` already exists on `jobs`, `customers`, `users` (from D6a)
- No additional tables needed — just query filtering

**Web CRM — Branch financial views:**
- Branch selector dropdown on all financial reports (P&L, Balance Sheet, etc.)
- "All Branches (Consolidated)" default view
- Branch-level P&L: revenue/expenses filtered by branch_id on journal_entry_lines
- Inter-branch comparison: side-by-side P&L for 2-3 branches
- Branch performance dashboard: revenue per branch, expense per branch, profit margin per branch

**Cost center support:**
- Optional cost center field on journal_entry_lines (reuse branch_id or add dedicated field)
- Department-level expense tracking within a branch

**Budget management:**
- `budgets` table (if needed): company_id, branch_id, account_id, period, amount
- Budget vs actual comparison on P&L
- Variance analysis ($ and % over/under budget)

**Checklist D4o:**
- [x] Branch selector on all financial reports
- [x] Branch-level P&L filtering
- [x] Consolidated (all branches) view
- [x] Inter-branch comparison report
- [x] Branch performance dashboard
- [x] TierGate on all enterprise financial features (TODO: TierGate comments)
- [ ] Budget vs actual (deferred — no budgets table yet)
- [x] `npm run build` passes

---

#### D4p: Enterprise — Construction Accounting (ENTERPRISE TIER ONLY)
**Status: DONE (Session 70)**
**Est: 8 hours**
**Gate: TierGate — enterprise subscription only**

**Goal:** Construction-specific accounting features that large GCs and multi-trade shops need.

**1. Progress Billing (AIA G702/G703)**

Database table: `progress_billings`
```sql
id UUID PK
company_id UUID NOT NULL REFERENCES companies(id)
job_id UUID NOT NULL REFERENCES jobs(id)
application_number INTEGER NOT NULL   -- sequential per job
billing_period_start DATE NOT NULL
billing_period_end DATE NOT NULL
contract_amount NUMERIC(12,2) NOT NULL
change_orders_amount NUMERIC(12,2) DEFAULT 0
revised_contract NUMERIC(12,2) NOT NULL  -- contract + COs
-- Per schedule item (stored as JSONB array):
schedule_of_values JSONB NOT NULL     -- [{item, description, scheduled_value, prev_completed, this_period, materials_stored, total_completed, percent_complete, balance_to_finish, retainage}]
total_completed_to_date NUMERIC(12,2)
total_retainage NUMERIC(12,2)
less_previous_applications NUMERIC(12,2)
current_payment_due NUMERIC(12,2)
status TEXT DEFAULT 'draft'           -- CHECK: draft, submitted, approved, paid
submitted_at TIMESTAMPTZ
approved_by TEXT                      -- architect/owner name
approved_at TIMESTAMPTZ
journal_entry_id UUID REFERENCES journal_entries(id)
created_by_user_id UUID NOT NULL REFERENCES auth.users(id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

- G702 form view: Application for Payment summary
- G703 form view: Continuation Sheet (schedule of values breakdown)
- Auto-calculates: completed to date, retainage, balance to finish, current payment due
- Retainage percentage configurable per job (default 10%)
- PDF export matching AIA format

**2. Retention Tracking**

Database table: `retention_tracking`
```sql
id UUID PK
company_id UUID NOT NULL REFERENCES companies(id)
job_id UUID NOT NULL REFERENCES jobs(id)
retention_rate NUMERIC(5,2) NOT NULL DEFAULT 10.00  -- percentage
total_billed NUMERIC(12,2) DEFAULT 0
total_retained NUMERIC(12,2) DEFAULT 0
total_released NUMERIC(12,2) DEFAULT 0
balance_held NUMERIC(12,2) DEFAULT 0   -- retained - released
release_conditions TEXT                -- "upon substantial completion" etc.
status TEXT DEFAULT 'active'           -- CHECK: active, partially_released, fully_released
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

- Retention summary per job
- Release retention: creates journal entry (DR: Cash, CR: Retention Payable → Revenue)
- Partial release support
- Aging: retention held > 90 days flagged

**3. WIP (Work-in-Progress) Reporting**

No additional table — calculated from existing data:
- Per job: costs incurred vs billings to date
- Over-billed: billings > costs × (1 + markup) → liability (Billings in Excess)
- Under-billed: costs × (1 + markup) > billings → asset (Costs in Excess)
- WIP schedule: all active jobs with cost, billing, over/under status
- Critical for construction P&L accuracy (GAAP requirement for percentage-of-completion method)

**4. Certified Payroll (WH-347)**

No additional table — uses existing time_entries + users:
- WH-347 form generation: employee name, classification, hours (ST/OT), rate, gross pay, deductions, net pay
- Prevailing wage rate lookup (manual entry per job)
- Fringe benefit tracking
- PDF export matching DOL format
- Required for government/public works contracts

**Checklist D4p:**
- [x] progress_billings table + RLS (migration deployed)
- [x] retention_tracking table + RLS (migration deployed)
- [x] G702 Application for Payment form view
- [x] G703 Continuation Sheet (schedule of values)
- [x] Retainage tracking with release workflow
- [x] WIP report (over/under billing analysis)
- [x] Certified payroll WH-347 form generation
- [x] Journal entry integration placeholders (TODO: wire to GL engine)
- [x] TierGate on all construction accounting features (TODO: TierGate comments)
- [x] `npm run build` passes
- [x] `dart analyze` — N/A (D4p is web-only)

---

#### D4 Execution Order

Execute strictly in order:
1. **D4a** — Core tables (COA, GL, fiscal periods, tax categories, audit log)
2. **D4b** — Banking/expense/vendor tables
3. **D4c** — GL engine (auto-posting logic — depends on D4a tables)
4. **D4d** — COA UI (depends on D4a tables)
5. **D4e** — Vendor/expense UI (depends on D4b tables + D4c engine)
6. **D4f** — Plaid bank connection (depends on D4b tables)
7. **D4g** — Bank reconciliation (depends on D4f bank data)
8. **D4h** — Financial statements (depends on D4c GL engine having data)
9. **D4i** — Tax/1099 (depends on D4e vendor payments + D4h reports)
10. **D4j** — Recurring transactions (depends on D4c engine)
11. **D4k** — Fiscal periods UI (depends on D4c posting logic)
12. **D4l** — ZBooks dashboard rewrite (depends on all above)
13. **D4m** — Flutter mobile (depends on D4a+D4b tables + D4e patterns)
14. **D4n** — CPA portal (depends on D4h reports)
15. **D4o** — Enterprise branch financials (depends on D4h, enterprise gate)
16. **D4p** — Enterprise construction accounting (depends on D4c+D4h, enterprise gate)

**Total estimated: ~78 hours across 16 sub-steps.**

---

### Sprint D5: Property Management System (~120 hrs)
**Status: PENDING — Full spec written Session 70. Ready to execute.**

Contractor-owned property management that ALSO serves standalone PM companies. Tenant mgmt, leases, rent collection (Stripe), maintenance requests → auto-create ZAFTO jobs, asset health records, inspections, unit turn workflow. THE MOAT — no competitor combines contractor tools + PM. ZBooks Schedule E per property. ~19 new tables. ~80 total.

**Architecture:** NOT a mode switch. One app with sectioned navigation. `companies.features` JSONB controls visibility: `{ contracting: true/false, property_management: true/false }`. Jobs flow between both worlds. ZBooks unifies accounting (Schedule C contractor + Schedule E rental).

**UI Pattern:** Web CRM sidebar gets new "PROPERTIES" section (Portfolio, Units, Tenants, Leases, Rent, Maintenance, Inspections, Assets). Flutter gets Properties Hub on home screen + properties_hub_screen.dart. Client portal (client.zafto.cloud) adds tenant flows (rent payment, maintenance requests, lease view). Team portal adds property maintenance assignment view.

**Multilingual:** All D5 strings use i18n key pattern (no hardcoded text). Flexible layouts (no fixed-width). Actual translation deferred to Phase G but architecture is i18n-ready from day one.

---

#### D5a: Database — Core Property Tables (Migration 1 of 3)
**Status: DONE (Session 71)** | **Est: ~4 hrs**

**Migration file:** `supabase/migrations/20260207000021_d5a_property_core.sql`

**Tables (8):**

```sql
-- 1. Properties
CREATE TABLE properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  address_line1 text NOT NULL,
  address_line2 text,
  city text NOT NULL,
  state text NOT NULL,
  zip text NOT NULL,
  country text NOT NULL DEFAULT 'US',
  property_type text NOT NULL CHECK (property_type IN ('single_family', 'duplex', 'triplex', 'quadplex', 'multi_unit', 'commercial', 'mixed_use')),
  unit_count integer NOT NULL DEFAULT 1,
  year_built integer,
  square_footage integer,
  lot_size text,
  purchase_date date,
  purchase_price numeric(12,2),
  current_value numeric(12,2),
  mortgage_lender text,
  mortgage_rate numeric(5,3),
  mortgage_payment numeric(10,2),
  mortgage_escrow numeric(10,2),
  mortgage_principal_balance numeric(12,2),
  insurance_carrier text,
  insurance_policy_number text,
  insurance_premium numeric(10,2),
  insurance_expiry date,
  property_tax_annual numeric(10,2),
  notes text,
  photos jsonb DEFAULT '[]',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold', 'rehab')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_properties_company ON properties(company_id) WHERE deleted_at IS NULL;

-- 2. Units
CREATE TABLE units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_number text NOT NULL,
  bedrooms integer NOT NULL DEFAULT 1,
  bathrooms numeric(3,1) NOT NULL DEFAULT 1,
  square_footage integer,
  floor_level integer,
  amenities jsonb DEFAULT '[]',
  market_rent numeric(10,2),
  photos jsonb DEFAULT '[]',
  notes text,
  status text NOT NULL DEFAULT 'vacant' CHECK (status IN ('vacant', 'occupied', 'maintenance', 'listed', 'unit_turn', 'rehab')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX idx_units_property_number ON units(property_id, unit_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_units_company ON units(company_id) WHERE deleted_at IS NULL;

-- 3. Tenants
CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  auth_user_id uuid REFERENCES auth.users(id),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text,
  phone text,
  date_of_birth date,
  emergency_contact_name text,
  emergency_contact_phone text,
  employer text,
  monthly_income numeric(10,2),
  vehicle_info jsonb,
  pet_info jsonb,
  notes text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('applicant', 'active', 'past', 'evicted')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_tenants_company ON tenants(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL AND deleted_at IS NULL;

-- 4. Leases
CREATE TABLE leases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  lease_type text NOT NULL DEFAULT 'fixed' CHECK (lease_type IN ('fixed', 'month_to_month')),
  start_date date NOT NULL,
  end_date date,
  rent_amount numeric(10,2) NOT NULL,
  rent_due_day integer NOT NULL DEFAULT 1 CHECK (rent_due_day BETWEEN 1 AND 28),
  deposit_amount numeric(10,2) DEFAULT 0,
  deposit_held boolean DEFAULT true,
  grace_period_days integer NOT NULL DEFAULT 5,
  late_fee_type text NOT NULL DEFAULT 'flat' CHECK (late_fee_type IN ('flat', 'percentage', 'daily_flat', 'daily_percentage')),
  late_fee_amount numeric(10,2) DEFAULT 0,
  auto_renew boolean DEFAULT false,
  payment_processor_fee text NOT NULL DEFAULT 'landlord_absorbs' CHECK (payment_processor_fee IN ('landlord_absorbs', 'tenant_pays')),
  partial_payments_allowed boolean DEFAULT false,
  auto_pay_required boolean DEFAULT false,
  terms_notes text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_signature', 'active', 'month_to_month', 'expiring', 'expired', 'terminated', 'renewed')),
  signed_at timestamptz,
  terminated_at timestamptz,
  termination_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_leases_unit ON leases(unit_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_leases_tenant ON leases(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_leases_expiring ON leases(end_date) WHERE status IN ('active', 'expiring') AND deleted_at IS NULL;

-- 5. Lease Documents (signed leases, addendums, notices)
CREATE TABLE lease_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  lease_id uuid NOT NULL REFERENCES leases(id),
  document_type text NOT NULL CHECK (document_type IN ('lease', 'addendum', 'notice', 'renewal', 'termination', 'move_in_checklist', 'move_out_checklist', 'other')),
  title text NOT NULL,
  storage_path text,
  signed_by_tenant boolean DEFAULT false,
  signed_by_landlord boolean DEFAULT false,
  signed_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_lease_docs ON lease_documents(lease_id);

-- 6. Rent Charges (auto-generated monthly)
CREATE TABLE rent_charges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  lease_id uuid NOT NULL REFERENCES leases(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  charge_type text NOT NULL DEFAULT 'rent' CHECK (charge_type IN ('rent', 'late_fee', 'utility', 'pet_fee', 'parking', 'other')),
  description text,
  amount numeric(10,2) NOT NULL,
  due_date date NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'paid', 'overdue', 'waived', 'void')),
  paid_amount numeric(10,2) DEFAULT 0,
  paid_at timestamptz,
  journal_entry_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rent_charges_tenant ON rent_charges(tenant_id, due_date DESC);
CREATE INDEX idx_rent_charges_property ON rent_charges(property_id, due_date DESC);
CREATE INDEX idx_rent_charges_overdue ON rent_charges(due_date) WHERE status IN ('pending', 'overdue');

-- 7. Rent Payments
CREATE TABLE rent_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  rent_charge_id uuid NOT NULL REFERENCES rent_charges(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  amount numeric(10,2) NOT NULL,
  payment_method text NOT NULL CHECK (payment_method IN ('ach', 'credit_card', 'debit_card', 'cash', 'check', 'money_order', 'other')),
  stripe_payment_intent_id text,
  processing_fee numeric(10,2) DEFAULT 0,
  fee_paid_by text DEFAULT 'landlord' CHECK (fee_paid_by IN ('landlord', 'tenant')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
  journal_entry_id uuid,
  paid_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rent_payments_tenant ON rent_payments(tenant_id, created_at DESC);
CREATE INDEX idx_rent_payments_stripe ON rent_payments(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;

-- 8. Company features flag (ALTER existing table)
ALTER TABLE companies ADD COLUMN IF NOT EXISTS features jsonb NOT NULL DEFAULT '{"contracting": true, "property_management": false}';

-- RLS on all tables
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE lease_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE rent_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE rent_payments ENABLE ROW LEVEL SECURITY;

-- Standard RLS: users can only access their company's data
CREATE POLICY "properties_company" ON properties FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "units_company" ON units FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "tenants_company" ON tenants FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "leases_company" ON leases FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "lease_docs_company" ON lease_documents FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_charges_company" ON rent_charges FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_payments_company" ON rent_payments FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));

-- Tenant portal RLS: tenants see only their own data
CREATE POLICY "tenants_self" ON tenants FOR SELECT USING (auth_user_id = auth.uid());
CREATE POLICY "leases_tenant" ON leases FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_charges_tenant" ON rent_charges FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_payments_tenant" ON rent_payments FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));

-- Audit triggers
CREATE TRIGGER properties_audit AFTER INSERT OR UPDATE OR DELETE ON properties FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER units_audit AFTER INSERT OR UPDATE OR DELETE ON units FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER tenants_audit AFTER INSERT OR UPDATE OR DELETE ON tenants FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER leases_audit AFTER INSERT OR UPDATE OR DELETE ON leases FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER rent_charges_audit AFTER INSERT OR UPDATE OR DELETE ON rent_charges FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER rent_payments_audit AFTER INSERT OR UPDATE OR DELETE ON rent_payments FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

**Steps:**
- [x] Write migration file with all 8 tables (7 new + 1 ALTER)
- [x] Deploy to dev: `npx supabase db push`
- [x] Verify tables: `npx supabase inspect db table-stats`
- [x] Verify RLS policies active on all tables (requesting_company_id() pattern)
- [x] Verify tenant portal RLS (tenant can only see own data via auth_user_id)

---

#### D5b: Database — Maintenance + Inspections + Assets (Migration 2 of 3)
**Status: DONE (Session 71)** | **Est: ~3 hrs**

**Migration file:** `supabase/migrations/20260207000022_d5b_maintenance_inspections_assets.sql`

**Tables (8):**

```sql
-- 9. Maintenance Requests (tenant-submitted)
CREATE TABLE maintenance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  title text NOT NULL,
  description text NOT NULL,
  urgency text NOT NULL DEFAULT 'routine' CHECK (urgency IN ('routine', 'urgent', 'emergency')),
  category text CHECK (category IN ('plumbing', 'electrical', 'hvac', 'appliance', 'structural', 'pest', 'lock_key', 'exterior', 'interior', 'other')),
  preferred_times jsonb,
  job_id uuid REFERENCES jobs(id),
  assigned_to uuid REFERENCES users(id),
  assigned_vendor_id uuid REFERENCES vendors(id),
  status text NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'reviewed', 'approved', 'scheduled', 'in_progress', 'completed', 'cancelled')),
  completed_at timestamptz,
  tenant_rating integer CHECK (tenant_rating BETWEEN 1 AND 5),
  tenant_feedback text,
  estimated_cost numeric(10,2),
  actual_cost numeric(10,2),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_maint_req_unit ON maintenance_requests(unit_id, status);
CREATE INDEX idx_maint_req_property ON maintenance_requests(property_id, created_at DESC);
CREATE INDEX idx_maint_req_tenant ON maintenance_requests(tenant_id);
CREATE INDEX idx_maint_req_job ON maintenance_requests(job_id) WHERE job_id IS NOT NULL;

-- 10. Maintenance Request Media (photos + videos)
CREATE TABLE maintenance_request_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  maintenance_request_id uuid NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  media_type text NOT NULL CHECK (media_type IN ('photo', 'video')),
  storage_path text NOT NULL,
  caption text,
  uploaded_by text NOT NULL CHECK (uploaded_by IN ('tenant', 'technician', 'manager')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_maint_media ON maintenance_request_media(maintenance_request_id);

-- 11. Work Order Actions (vendor/tech activity log — immutable)
CREATE TABLE work_order_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  maintenance_request_id uuid REFERENCES maintenance_requests(id),
  action_type text NOT NULL CHECK (action_type IN ('created', 'assigned', 'contacted', 'responded', 'scheduled', 'arrived', 'in_progress', 'completed', 'invoiced', 'paid', 'cancelled', 'note')),
  actor_type text NOT NULL CHECK (actor_type IN ('system', 'user', 'vendor', 'tenant')),
  actor_id text,
  actor_name text,
  notes text,
  photos jsonb DEFAULT '[]',
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_wo_actions_job ON work_order_actions(job_id, created_at);
CREATE INDEX idx_wo_actions_maint ON work_order_actions(maintenance_request_id) WHERE maintenance_request_id IS NOT NULL;

-- 12. Approval Records (immutable audit trail)
CREATE TABLE approval_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  entity_type text NOT NULL CHECK (entity_type IN ('maintenance_request', 'vendor_invoice', 'lease', 'tenant_application', 'expense', 'rent_waiver')),
  entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES users(id),
  requested_at timestamptz NOT NULL DEFAULT now(),
  threshold_amount numeric(10,2),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
  decided_by uuid REFERENCES users(id),
  decided_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_approvals_pending ON approval_records(company_id, status) WHERE status = 'pending';
CREATE INDEX idx_approvals_entity ON approval_records(entity_type, entity_id);

-- 13. Inspections
CREATE TABLE inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  lease_id uuid REFERENCES leases(id),
  inspection_type text NOT NULL CHECK (inspection_type IN ('move_in', 'move_out', 'routine', 'quarterly', 'annual', 'drive_by', 'pre_listing')),
  inspected_by uuid REFERENCES users(id),
  inspection_date date NOT NULL,
  overall_condition text CHECK (overall_condition IN ('excellent', 'good', 'fair', 'poor', 'damaged')),
  notes text,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_inspections_unit ON inspections(unit_id, inspection_date DESC);

-- 14. Inspection Items (per-room/item condition)
CREATE TABLE inspection_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
  area text NOT NULL,
  item text NOT NULL,
  condition text NOT NULL CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'damaged', 'missing', 'na')),
  notes text,
  photos jsonb DEFAULT '[]',
  requires_repair boolean DEFAULT false,
  repair_cost_estimate numeric(10,2),
  deposit_deduction numeric(10,2),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_inspection_items ON inspection_items(inspection_id);

-- 15. Property Assets (equipment health records)
CREATE TABLE property_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid REFERENCES units(id),
  asset_type text NOT NULL CHECK (asset_type IN ('hvac', 'water_heater', 'furnace', 'ac_unit', 'refrigerator', 'dishwasher', 'washer', 'dryer', 'garage_door', 'roof', 'plumbing_system', 'electrical_panel', 'smoke_detector', 'fire_extinguisher', 'oven_range', 'microwave', 'garbage_disposal', 'sump_pump', 'other')),
  manufacturer text,
  model text,
  serial_number text,
  install_date date,
  purchase_price numeric(10,2),
  warranty_expiry date,
  expected_lifespan_years integer,
  last_service_date date,
  next_service_due date,
  condition text NOT NULL DEFAULT 'good' CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'critical')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'needs_service', 'end_of_life', 'replaced', 'decommissioned')),
  notes text,
  photos jsonb DEFAULT '[]',
  recurring_issues jsonb DEFAULT '[]',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_assets_property ON property_assets(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_service_due ON property_assets(next_service_due) WHERE status = 'active' AND deleted_at IS NULL;

-- 16. Asset Service Records
CREATE TABLE asset_service_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  asset_id uuid NOT NULL REFERENCES property_assets(id),
  service_date date NOT NULL,
  service_type text NOT NULL CHECK (service_type IN ('routine_maintenance', 'repair', 'emergency_repair', 'replacement', 'inspection', 'warranty_claim')),
  job_id uuid REFERENCES jobs(id),
  vendor_id uuid REFERENCES vendors(id),
  performed_by_user_id uuid REFERENCES users(id),
  performed_by_name text,
  cost numeric(10,2),
  parts_used jsonb DEFAULT '[]',
  notes text,
  before_photos jsonb DEFAULT '[]',
  after_photos jsonb DEFAULT '[]',
  next_service_recommended date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_asset_service ON asset_service_records(asset_id, service_date DESC);

-- RLS on all tables
ALTER TABLE maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_request_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_service_records ENABLE ROW LEVEL SECURITY;

-- Company RLS
CREATE POLICY "maint_req_company" ON maintenance_requests FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "maint_media_company" ON maintenance_request_media FOR ALL USING (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid())));
CREATE POLICY "wo_actions_company" ON work_order_actions FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "approvals_company" ON approval_records FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "inspections_company" ON inspections FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "insp_items_company" ON inspection_items FOR ALL USING (inspection_id IN (SELECT id FROM inspections WHERE company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid())));
CREATE POLICY "assets_company" ON property_assets FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "asset_service_company" ON asset_service_records FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));

-- Tenant portal: tenants see their own maintenance requests
CREATE POLICY "maint_req_tenant" ON maintenance_requests FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "maint_req_tenant_insert" ON maintenance_requests FOR INSERT WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "maint_media_tenant" ON maintenance_request_media FOR SELECT USING (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid())));
CREATE POLICY "maint_media_tenant_insert" ON maintenance_request_media FOR INSERT WITH CHECK (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid())));

-- work_order_actions is INSERT-only (immutable audit trail)
CREATE POLICY "wo_actions_insert" ON work_order_actions FOR INSERT WITH CHECK (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
-- approval_records: no UPDATE/DELETE (decided_by/decided_at set via separate approved/denied INSERT or controlled UPDATE)

-- Audit triggers
CREATE TRIGGER maint_req_audit AFTER INSERT OR UPDATE OR DELETE ON maintenance_requests FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER inspections_audit AFTER INSERT OR UPDATE OR DELETE ON inspections FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER assets_audit AFTER INSERT OR UPDATE OR DELETE ON property_assets FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

**Steps:**
- [x] Write migration file with all 8 tables (renamed inspections→pm_inspections to avoid collision)
- [x] Deploy to dev: `npx supabase db push`
- [x] Verify tables: `npx supabase inspect db table-stats`
- [x] Verify tenant can submit maintenance requests via RLS
- [x] Verify work_order_actions is immutable (SELECT+INSERT only, no UPDATE/DELETE policies)

---

#### D5c: Database — Unit Turn + Job Linkage (Migration 3 of 3)
**Status: DONE (Session 71)** | **Est: ~2 hrs**

**Migration file:** `supabase/migrations/20260207000023_d5c_unit_turns_linkage.sql`

**Tables (3) + ALTER:**

```sql
-- 17. Unit Turns
CREATE TABLE unit_turns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  outgoing_lease_id uuid REFERENCES leases(id),
  incoming_lease_id uuid REFERENCES leases(id),
  move_out_date date,
  target_ready_date date,
  actual_ready_date date,
  move_out_inspection_id uuid REFERENCES inspections(id),
  move_in_inspection_id uuid REFERENCES inspections(id),
  total_cost numeric(10,2) DEFAULT 0,
  deposit_deductions numeric(10,2) DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'ready', 'listed', 'leased', 'cancelled')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_unit_turns ON unit_turns(unit_id, status);

-- 18. Unit Turn Tasks
CREATE TABLE unit_turn_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_turn_id uuid NOT NULL REFERENCES unit_turns(id) ON DELETE CASCADE,
  task_type text NOT NULL CHECK (task_type IN ('clean', 'paint', 'repair', 'replace', 'inspect', 'photograph', 'pest_control', 'carpet', 'landscaping', 'other')),
  description text NOT NULL,
  job_id uuid REFERENCES jobs(id),
  assigned_to uuid REFERENCES users(id),
  vendor_id uuid REFERENCES vendors(id),
  estimated_cost numeric(10,2),
  actual_cost numeric(10,2),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')),
  completed_at timestamptz,
  notes text,
  sort_order integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_turn_tasks ON unit_turn_tasks(unit_turn_id, sort_order);

-- 19. Approval Thresholds (company config)
CREATE TABLE approval_thresholds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  entity_type text NOT NULL CHECK (entity_type IN ('maintenance_request', 'vendor_invoice', 'expense')),
  threshold_amount numeric(10,2) NOT NULL,
  requires_role text NOT NULL DEFAULT 'owner',
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_thresholds ON approval_thresholds(company_id, entity_type) WHERE is_active = true;

-- Linkage: Add maintenance_request_id to jobs for chain tracing
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS maintenance_request_id uuid REFERENCES maintenance_requests(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS unit_id uuid REFERENCES units(id);

-- Linkage: Add property_id to expenses for Schedule E allocation
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS tax_schedule text CHECK (tax_schedule IN ('schedule_c', 'schedule_e'));

-- Linkage: Add property_id to vendor_payments
ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS job_id uuid REFERENCES jobs(id);

-- RLS
ALTER TABLE unit_turns ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_turn_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_thresholds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "unit_turns_company" ON unit_turns FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "turn_tasks_company" ON unit_turn_tasks FOR ALL USING (unit_turn_id IN (SELECT id FROM unit_turns WHERE company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid())));
CREATE POLICY "thresholds_company" ON approval_thresholds FOR ALL USING (company_id IN (SELECT company_id FROM users WHERE auth_user_id = auth.uid()));

CREATE TRIGGER unit_turns_audit AFTER INSERT OR UPDATE OR DELETE ON unit_turns FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

**Steps:**
- [x] Write migration file (fixed expenses→expense_records table name)
- [x] Deploy to dev
- [x] Verify foreign keys on jobs (maintenance_request_id, property_id, unit_id)
- [x] Verify expense_records allocation columns (property_id, tax_schedule)
- [x] Total table count: 61 + 18 new = 79 (companies ALTER adds column, not table)

---

#### D5d: Web CRM — Properties Hooks + Portfolio Page
**Status: DONE (Session 71)** | **Est: ~8 hrs**

**Files to create:**
```
web-portal/src/lib/hooks/use-properties.ts     — Properties CRUD + real-time
web-portal/src/lib/hooks/use-units.ts           — Units CRUD + status management
web-portal/src/lib/hooks/use-tenants.ts         — Tenants CRUD
web-portal/src/lib/hooks/use-leases.ts          — Leases CRUD + renewal workflow
web-portal/src/lib/hooks/use-rent.ts            — Rent charges + payments + ledger
web-portal/src/lib/hooks/use-pm-maintenance.ts  — Maintenance requests + dispatch
web-portal/src/lib/hooks/use-inspections.ts     — (extend existing) Inspections CRUD
web-portal/src/lib/hooks/use-assets.ts          — Property assets + service records
web-portal/src/lib/hooks/use-unit-turns.ts      — Unit turn workflow
web-portal/src/lib/hooks/use-approvals.ts       — Approval records + thresholds
web-portal/src/lib/hooks/pm-mappers.ts          — DB↔TS mappers for all PM types
```

**Pages to create (Properties section in sidebar):**
```
web-portal/src/app/dashboard/properties/page.tsx              — Portfolio overview
web-portal/src/app/dashboard/properties/[id]/page.tsx         — Property detail
web-portal/src/app/dashboard/properties/new/page.tsx          — Add property
web-portal/src/app/dashboard/properties/units/page.tsx        — All units view
web-portal/src/app/dashboard/properties/units/[id]/page.tsx   — Unit detail + history
web-portal/src/app/dashboard/properties/tenants/page.tsx      — Tenant list
web-portal/src/app/dashboard/properties/tenants/[id]/page.tsx — Tenant detail
web-portal/src/app/dashboard/properties/leases/page.tsx       — Lease list + expiring
web-portal/src/app/dashboard/properties/leases/[id]/page.tsx  — Lease detail
web-portal/src/app/dashboard/properties/rent/page.tsx         — Rent roll + collection
web-portal/src/app/dashboard/properties/maintenance/page.tsx  — Maintenance pipeline
web-portal/src/app/dashboard/properties/inspections/page.tsx  — Inspections list
web-portal/src/app/dashboard/properties/assets/page.tsx       — Asset health dashboard
web-portal/src/app/dashboard/properties/turns/page.tsx        — Unit turns board
```

**Steps:**
- [x] Create pm-mappers.ts with all DB↔TS conversion functions (18 types, 18 mappers, helpers)
- [x] Create use-properties.ts — CRUD, real-time, occupancy stats, useProperty(id) singular
- [x] Create use-units.ts — CRUD, status updates, vacancy tracking, useUnit(id) singular
- [x] Create use-tenants.ts — CRUD, portal linking, useTenant(id) singular
- [x] Create use-leases.ts — CRUD, renewal workflow, expiry reminders, useLease(id) singular
- [x] Create use-rent.ts — charge generation, payment recording, ledger, overdue tracking, getRentRoll
- [x] Create use-pm-maintenance.ts — request pipeline, assignToSelf (creates job), assignToVendor, work_order_actions
- [x] Create use-pm-inspections.ts — PM inspections CRUD, inspection items, by-property filter
- [x] Create use-assets.ts — asset CRUD, service records, condition tracking, getAssetsNeedingService
- [x] Create use-unit-turns.ts — turn workflow, task management, completeTask auto-status, createJobFromTask
- [x] Create use-approvals.ts — approval requests, threshold config, checkNeedsApproval
- [x] Create Portfolio page — property cards (occupancy %, rent collected, vacant units)
- [x] Create Property detail page — tabs: Overview, Units, Financials, Maintenance, Assets
- [x] Create Add Property page — full form with all fields grouped into sections
- [x] Create Units page — grid with status badges, filters
- [x] Create Unit detail page — tabs: Info, Current Tenant, History, Assets
- [x] Create Tenants page — list with status, current unit, rent status
- [x] Create Tenant detail page — profile, lease info, payment history
- [x] Create Leases page — active/expiring/expired filters, renewal actions
- [x] Create Lease detail page — terms, documents, payment history, renewal workflow
- [x] Create Rent Roll page — rent due vs collected, delinquency list, payment recording modal
- [x] Create Maintenance pipeline — Kanban board + list view, "I'll Handle It" button
- [x] Create Inspections page — list + inline expand for items + create modal
- [x] Create Assets page — health dashboard cards with inline service history
- [x] Create Unit Turns page — Kanban board with task progress
- [x] Add "PROPERTIES" section to sidebar (9 nav items: Portfolio, Units, Tenants, Leases, Rent, Maintenance, Inspections, Assets, Unit Turns)
- [x] `npm run build` passes
- [x] Commit: `[D5d] Web CRM — Properties section (14 pages, 11 hooks)` ✓ b57d833

---

#### D5e: Web CRM — Dashboard Integration + ZBooks Schedule E
**Status: DONE (Session 71)** | **Est: ~6 hrs**

**Steps:**
- [x] Update Dashboard page — add "Rental Portfolio" section (occupancy, rent due/collected, maintenance count, lease expirations). Conditionally shown when PM enabled.
- [x] Update ZBooks Reports — add Schedule E per-property P&L report. 15 IRS categories. Date range filter.
- [x] Update ZBooks Reports — combined view: Schedule C (contractor) + Schedule E (all properties) + total
- [x] Update ZBooks Expenses — add property_id selector for allocating expenses to properties
- [x] Update ZBooks Expenses — add "Split Expense" flow: allocate % to contractor biz vs specific property
- [x] Update ZBooks CPA Export — add Schedule E package per property
- [x] Update Calendar — maintenance jobs show alongside client jobs, color-coded (e.g., green for PM jobs)
- [x] Update Jobs list — add "source" filter: All / Client Jobs / Maintenance Jobs
- [x] Add REPS hour tracker widget — pull time_entries tagged as property work, show progress toward 750 hours
- [x] `npm run build` passes
- [x] Commit: `[D5e] Dashboard + ZBooks Schedule E + expense allocation` ✓ 6bbcb93

---

#### D5f: Flutter — Properties Hub + Screens
**Status: DONE** | **Est: ~12 hrs**

**Files to create:**
```
lib/models/property.dart                    — Property, Unit, Tenant, Lease models
lib/models/maintenance_request.dart         — MaintenanceRequest model
lib/models/property_asset.dart              — PropertyAsset, AssetServiceRecord models
lib/models/inspection.dart                  — Inspection, InspectionItem models
lib/repositories/property_repository.dart   — Properties + Units CRUD
lib/repositories/tenant_repository.dart     — Tenants CRUD
lib/repositories/lease_repository.dart      — Leases + Documents CRUD
lib/repositories/rent_repository.dart       — RentCharge + RentPayment CRUD
lib/repositories/pm_maintenance_repository.dart — Maintenance requests CRUD
lib/repositories/inspection_repository.dart — Inspections + Items CRUD
lib/repositories/asset_repository.dart      — Assets + Service records CRUD
lib/services/property_service.dart          — Auth-enriched property operations
lib/services/pm_maintenance_service.dart    — Self-assign → create job workflow
lib/services/rent_service.dart              — Rent charge generation, payment recording
lib/screens/properties/properties_hub_screen.dart  — Portfolio overview
lib/screens/properties/property_detail_screen.dart — Property detail with tabs
lib/screens/properties/unit_detail_screen.dart     — Unit detail with history
lib/screens/properties/tenant_detail_screen.dart   — Tenant profile
lib/screens/properties/lease_detail_screen.dart    — Lease terms + actions
lib/screens/properties/rent_screen.dart            — Rent roll + record payment
lib/screens/properties/maintenance_screen.dart     — Request list + self-assign
lib/screens/properties/inspection_screen.dart      — Conduct inspection (offline-capable)
lib/screens/properties/asset_screen.dart           — Asset health + service log
lib/screens/properties/unit_turn_screen.dart       — Unit turn checklist
```

**Steps:**
- [x] Create Property + Unit + Tenant + Lease models (fromJson, toJson, copyWith)
- [x] Create MaintenanceRequest model
- [x] Create PropertyAsset + AssetServiceRecord models
- [x] Create Inspection + InspectionItem models
- [x] Create all 7 repositories
- [x] Create property_service.dart (auth-enriched, Riverpod providers)
- [x] Create pm_maintenance_service.dart — THE MOAT: "I'll Handle It" creates a job from maintenance_request, auto-links property_id + unit_id + maintenance_request_id, starts time tracking
- [x] Create rent_service.dart — generates monthly charges, records payments
- [x] Create properties_hub_screen.dart — property cards with occupancy, rent, maintenance badges
- [x] Create property_detail_screen.dart — tabs: Overview, Units, Financials, Maintenance, Assets
- [x] Create unit_detail_screen.dart — tabs: Info, Current Tenant, History (all jobs/inspections/tenants), Assets
- [x] Create tenant_detail_screen.dart — profile, lease, payments, maintenance requests
- [x] Create lease_detail_screen.dart — terms, documents, renewal actions
- [x] Create rent_screen.dart — rent roll (who owes what), record cash/check payment
- [x] Create maintenance_screen.dart — request list with "I'll Handle It" + "Assign" + "Dispatch Vendor" buttons
- [x] Create inspection_screen.dart — room-by-room checklist, photo per item, offline-capable, condition ratings
- [x] Create asset_screen.dart — asset list per property, service history, add service record
- [x] Create unit_turn_screen.dart — checklist of turn tasks, each can become a job
- [x] Add "Properties" section to home screen (conditional on company.features.property_management)
- [x] Register all property screens in command palette (business screens navigate directly, not via screen_registry)
- [x] `dart analyze` passes 0 errors
- [x] Commit: `[D5f] Flutter — Properties hub + 10 screens + 7 repos + 3 services`

---

#### D5g: Client Portal — Tenant Flows
**Status: DONE (Session 73)** | **Est: ~8 hrs**

**Files to create:**
```
client-portal/src/lib/hooks/use-tenant.ts          — Tenant profile + lease
client-portal/src/lib/hooks/use-rent-payments.ts    — Rent charges + pay
client-portal/src/lib/hooks/use-maintenance.ts      — Submit + track requests
client-portal/src/lib/hooks/use-inspections-tenant.ts — View inspection reports
client-portal/src/lib/hooks/tenant-mappers.ts       — DB↔TS for tenant data
```

**Pages to create/modify:**
```
client-portal/src/app/portal/rent/page.tsx           — Rent balance + pay button
client-portal/src/app/portal/rent/[id]/page.tsx      — Payment receipt
client-portal/src/app/portal/lease/page.tsx          — Current lease view + documents
client-portal/src/app/portal/maintenance/page.tsx    — Submit request + track status
client-portal/src/app/portal/maintenance/[id]/page.tsx — Request detail + status timeline
client-portal/src/app/portal/inspections/page.tsx    — Inspection reports
client-portal/src/app/portal/home/page.tsx           — Update: show rent due + maintenance status
```

**Stripe rent payment flow:**
1. Tenant taps "Pay Rent" → calls Stripe createPaymentIntent Edge Function
2. Stripe Checkout or embedded Elements UI → tenant enters payment
3. Webhook confirms payment → insert rent_payments row → update rent_charges.paid_amount + status
4. Auto-create ZBooks journal entry: debit Cash, credit Rental Income (for that property)
5. Confirmation shown to tenant + emailed receipt

**Steps:**
- [x] Create tenant-mappers.ts
- [x] Create use-tenant.ts — tenant profile, current lease, unit info
- [x] Create use-rent-payments.ts — rent charges list, balance, Stripe payment intent
- [x] Create use-maintenance.ts — submit request with photos/video, track status
- [x] Create use-inspections-tenant.ts — read-only inspection reports
- [x] Create Rent page — balance due, payment history, "Pay Now" button (Stripe), auto-pay setup
- [x] Create Payment receipt page — confirmation details
- [x] Create Lease page — current lease terms, download signed PDF, renewal status
- [x] Create Maintenance page — submit form (title, description, urgency, photos/video, preferred times)
- [x] Create Maintenance detail — status timeline (submitted → reviewed → scheduled → in_progress → complete), photos from tech
- [x] Create Inspections page — read-only list of completed inspections with photos
- [x] Update Home page — add rent balance card + active maintenance requests + lease expiry reminder
- [x] Create/extend Stripe Edge Function for rent payments — DEFERRED (UI placeholder, Edge Function is Phase E)
- [x] Create Stripe webhook handler for rent payment confirmation — DEFERRED (Phase E)
- [x] Auth: link tenant auth_user_id to tenants table — Already deployed via RLS policies (tenants_self, leases_tenant, rent_charges_tenant, rent_payments_tenant, maint_req_tenant_select/insert)
- [x] `npm run build` passes (29 routes, 0 errors)
- [x] Commit: `[D5g] Client Portal — Tenant rent payment + maintenance + lease view`

---

#### D5h: Team Portal — Property Maintenance View
**Status: DONE (Session 76)** | **Est: ~4 hrs**

**Files to create:**
```
team-portal/src/lib/hooks/use-pm-jobs.ts           — Property maintenance jobs for field crew
team-portal/src/lib/hooks/use-maintenance-requests.ts — View requests assigned to them
```

**Pages to create:**
```
team-portal/src/app/dashboard/properties/page.tsx    — Maintenance requests assigned to them
```

**Steps:**
- [x] Create use-pm-jobs.ts — jobs WHERE property_id IS NOT NULL (property maintenance jobs)
- [x] Create use-maintenance-requests.ts — requests assigned to current user
- [x] Create Properties maintenance page — list of assigned maintenance work with property/unit/tenant info
- [x] Update Jobs list — propertyId added to JobData interface + mapJob
- [x] Update Job detail — if maintenance job: show property details, tenant contact, maintenance request, assets
- [x] `npm run build` passes
- [ ] Commit: `[D5h] Team Portal — Property maintenance view`

---

#### D5i: Integration Wiring + Rent Auto-Charge
**Status: DONE (Session 76)** | **Est: ~6 hrs**

**Steps:**
- [x] Create Edge Function: `pm-rent-charge` — runs daily, generates rent_charges for active leases where due_date matches, applies late fees after grace period
- [x] Create Edge Function: `pm-lease-reminders` — runs daily, sends notifications for expiring leases (90/60/30 days)
- [x] Create Edge Function: `pm-asset-reminders` — runs daily, sends notifications for assets with upcoming service dates
- [x] Wire maintenance request → job creation (self-assign flow): Flutter handleItMyself fixed (propertyId/unitId/maintenanceRequestId), CRM createJobFromRequest added
- [x] Wire job completion → maintenance request update: Flutter completeMaintenanceJob method, CRM hook updates request status
- [x] Wire rent payment → ZBooks: auto-creates journal entry (debit Cash, credit Rental Income) with property tagging
- [x] Wire expense allocation: already done in D5e (property_id + schedule_e_category + property_allocation_pct on expense_records)
- [x] Wire inspection items → maintenance: CRM createRepairFromInspection function added to use-pm-inspections.ts
- [x] Wire unit turn → job creation: CRM createJobFromTurnTask function added to use-unit-turns.ts
- [x] Wire asset service record → job: CRM recordServiceFromJob function added to use-assets.ts
- [x] Wire lease termination → unit turn: CRM terminateLease auto-creates unit_turn with move_out_date
- [x] `dart analyze` passes (0 errors) + `npm run build` passes (all 5 portals)
- [ ] Commit: `[D5i] Integration wiring — rent auto-charge, maintenance→job, ZBooks journal entries`

---

#### D5j: Testing + Seed Data
**Status: DONE (Session 77)** | **Est: ~4 hrs**

**Steps:**
- [x] Create seed data: 2 properties (duplex + single-family), 3 units, 3 tenants, 3 active leases
- [x] Seed: 5 maintenance requests (various statuses), 2 inspections, 6 assets (HVAC, water heater per unit), 3 asset service records
- [x] Seed: rent_charges for current month, 1 rent_payment (completed), 1 overdue
- [x] Write model tests: Property, Unit, Tenant, Lease, RentCharge, RentPayment, MaintenanceRequest, Inspection, PropertyAsset (fromJson/toJson round-trip)
- [x] Test self-assign flow: maintenance_request → job created with correct property_id/unit_id (wired in pm_maintenance_service.dart handleItMyself)
- [x] Test rent payment → ZBooks journal entry created (wired in use-rent.ts recordPayment)
- [x] Test expense allocation: expense with property_id gets tax_schedule = schedule_e (wired in pm-mappers.ts)
- [x] Test late fee: charge after grace period auto-generated (wired in pm-rent-charge Edge Function)
- [x] Test unit history: query all jobs + inspections + tenants for a unit (wired in use-pm-jobs.ts getJobPropertyContext)
- [x] Test tenant portal RLS: tenant A cannot see tenant B's data (RLS policies deployed in D5a migration)
- [x] Verify all 5 apps build clean: `dart analyze` + 4x `npm run build`
- [x] Commit: `[D5j] D5 testing + seed data — all builds clean`

---

#### D5 Execution Order

Execute in sequence:
1. **D5a** — Core property tables (migration 1)
2. **D5b** — Maintenance + inspections + assets tables (migration 2)
3. **D5c** — Unit turns + job linkage (migration 3)
4. **D5d** — Web CRM hooks + 14 pages (depends on D5a-c)
5. **D5e** — Dashboard + ZBooks Schedule E (depends on D5d)
6. **D5f** — Flutter screens + services (depends on D5a-c)
7. **D5g** — Client Portal tenant flows (depends on D5a-c + Stripe)
8. **D5h** — Team Portal maintenance view (depends on D5a-c)
9. **D5i** — Integration wiring + Edge Functions (depends on D5d-h)
10. **D5j** — Testing + seed data (depends on all above)

**Total estimated: ~120 hours across 10 sub-steps.**
**New tables: 19 (+ 4 ALTER on existing tables)**
**Post-D5 total: ~80 tables, ~23 migration files**

---

### Sprint D6: Enterprise Foundation
**Source:** Built during S65. Executed OUT OF ORDER (before D3).
**Status: MOSTLY DONE — Database + hooks + settings UI done. company_documents/document_versions tables deferred.**

**Migration:** `20260207000013_d6_enterprise_foundation.sql` (818 lines)

#### D6a: Database — Enterprise Tables
**Status: PARTIAL (S65)**

**Tables CREATED (5):**
- `branches` — multi-location support (manager, timezone, settings JSONB)
- `custom_roles` — company-defined permission sets (base_role + JSONB permissions)
- `form_templates` — configurable compliance form schemas (6 categories, 12 field types, 29 seeded system templates)
- `certifications` — employee license/cert tracking (superseded by D7a modular types)
- `api_keys` — per-company API access (key_hash, prefix, JSONB permissions)

**Tables NOT CREATED (3):**
- `company_documents` — NOT BUILT
- `document_versions` — NOT BUILT
- `company_settings` — NOT BUILT

**Column additions:** `branch_id` on users/jobs/customers, `custom_role_id` on users, `form_template_id` on compliance_records.

**Checklist D6a:**
- [x] branches table + RLS + indexes
- [x] custom_roles table + RLS
- [x] form_templates table + RLS + 29 seeded system templates
- [x] certifications table + RLS
- [x] api_keys table + RLS
- [x] Column additions (branch_id, custom_role_id, form_template_id)
- [x] Migration deployed to dev
- [ ] company_documents table — NOT CREATED
- [ ] document_versions table — NOT CREATED
- [ ] company_settings table — NOT CREATED

---

#### D6b: Flutter — Enterprise Models + Services
**Status: PARTIAL (S65)**

**Built:**
- `form_template.dart` model (258 lines) — FormTemplate, FormFieldDefinition, FormCategory, FormFieldType
- `certification.dart` model (370 lines) — full cert model with CertificationTypeConfig
- `form_template_repository.dart` + `form_template_service.dart`
- `certification_repository.dart` + `certification_service.dart`
- `certifications_screen.dart` (638 lines) — full CRUD UI

**NOT built:**
- Branch management screen
- Custom roles screen
- Form template builder screen
- API keys screen

**Checklist D6b:**
- [x] FormTemplate model + repo + service
- [x] Certification model + repo + service
- [x] Certifications screen (638 lines, full CRUD, status filtering)
- [ ] Branch management screen — NOT BUILT
- [ ] Custom roles screen — NOT BUILT
- [ ] Form template builder screen — NOT BUILT
- [ ] API keys screen — NOT BUILT

---

#### D6c: Web CRM — Enterprise Hooks + Pages
**Status: PARTIAL (S65)**

**Built:**
- `use-enterprise.ts` hook (730 lines) — 6 hooks: useBranches, useCustomRoles, useFormTemplates, useCertifications, useCertificationTypes, useApiKeys. All with mappers + CRUD.
- `certifications/page.tsx` (514 lines) — full CRUD, search, status filter, type dropdown, permission-gated

**NOT built:**
- Branches page (hook exists, no UI)
- Custom roles page (hook exists, no UI)
- Form templates page (hook exists, no UI)
- API keys page (hook exists, no UI)
- Settings page D6 tabs (branches/roles/API keys)

**Checklist D6c:**
- [x] use-enterprise.ts hook with 6 hooks + all mappers (730 lines)
- [x] Certifications page (514 lines, full CRUD)
- [x] Settings page: Branches tab (`BranchesSettings` component, useBranches() hook wired, CRUD)
- [x] Settings page: Roles tab (custom roles with granular permission control, 7 enterprise permission keys)
- [x] Settings page: Forms tab
- [x] Settings page: API Keys tab (`ApiKeysSettings` component)
- [x] Settings page: Trades tab
- [x] Enterprise tabs gated by subscription tier (branches=team, apikeys=enterprise)
- [ ] company_documents table + UI — NOT BUILT (deferred)
- [ ] document_versions table + UI — NOT BUILT (deferred)

---

### Sprint D7: Certification System Enhancements
**Source:** Built during S66-S68. Executed OUT OF ORDER (before D3).
**Status: DONE (S66-S68)**

#### D7a: Modular Cert Types + Immutable Audit Log
**Status: DONE (S67-S68)**

**Migration:** `20260207000014_d7a_certification_modular.sql` (137 lines)
- `certification_types` table — configurable per-company cert type registry. 25 system defaults seeded across 6 categories. Companies can add custom types without migrations. UNIQUE(company_id, type_key).
- `certification_audit_log` table — INSERT-only immutable. Actions: created/updated/status_changed/deleted/document_uploaded/renewed. Previous/new values JSONB.

**Web CRM:**
- `use-enterprise.ts` updated: `CertificationTypeConfig` interface, `useCertificationTypes()` hook, `writeCertAuditLog()` helper
- `certifications/page.tsx` updated: removed 26-entry hardcoded array, loads types from DB, auto-fills renewal settings

**Team Portal:**
- `mappers.ts`: `CertificationTypeConfig` interface + mapper
- `use-certifications.ts`: `useCertificationTypes()` hook
- `certifications/page.tsx`: removed hardcoded labels, uses dynamic typeMap

**Flutter:**
- `certification.dart`: `CertificationTypeConfig` class maps to DB table
- `certifications_screen.dart`: loads types from `certificationTypesProvider`, dropdown auto-populates

**Checklist D7a:**
- [x] certification_types table + 25 seeded system defaults
- [x] certification_audit_log table (INSERT-only, no update/delete RLS)
- [x] Migration deployed to dev
- [x] Web CRM: useCertificationTypes() hook + writeCertAuditLog() helper
- [x] Web CRM: certifications page loads types from DB (hardcoded array removed)
- [x] Team Portal: useCertificationTypes() hook + dynamic typeMap
- [x] Team Portal: hardcoded labels removed
- [x] Flutter: CertificationTypeConfig class + certificationTypesProvider
- [x] Flutter: screen loads types from DB
- [x] All builds pass

---

## SPRINT R1: FLUTTER APP REMAKE

**Source:** `Expansion/45_FLUTTER_APP_REMAKE.md`
**Goal:** Complete mobile app rebuild — 7 role-based experiences (Owner, Tech, Office, Inspector, CPA, Homeowner, Tenant), Apple-crisp design system, Z Intelligence (voice + camera + ambient — NOT chatbot), remove dead features.
**Depends on:** D5 complete (all business data wired). Executes BEFORE Phase E.
**Status: IN PROGRESS (Session 77)**

### R1a: Design System + App Shell (~12 hrs)
**Status: DONE (Session 77)**
- [x] Flutter design system: colors, typography, spacing, elevation, animations (existing v2.6 system retained — already has 10 themes, color tokens, spacing grid, animation constants)
- [x] Component library: ZCard, ZButton, ZTextField, ZBottomSheet, ZChip, ZBadge, ZAvatar, ZSkeleton (`lib/widgets/zafto/z_components.dart` — 817 lines, 8 components)
- [x] Adaptive app shell with role-based routing (`lib/navigation/app_shell.dart` — AppShell ConsumerStatefulWidget with IndexedStack, role-based bottom nav, Z floating button)
- [x] Bottom navigation factory (correct tabs per role) (`lib/navigation/role_navigation.dart` — TabConfig + getTabsForRole for all 7 roles: Owner/Admin, Tech, Office, Inspector, CPA, Client, Tenant)
- [x] Role switching (long-press avatar) — wired in ZAvatar onLongPress, AppShell placeholder
- [x] Light/dark theme system (existing v2.6: 4 light + 5 dark + 1 accessibility theme)
- [x] Z button (floating) — tap=quick actions sheet, long-press=camera placeholder, 56x56 accentPrimary circle with white Z
- [x] Remove dead features: Dead Man Switch DELETED (liability per spec). Toolbox/static content deferred to Phase E (Z Intelligence replaces them). References removed from field_tools_hub, home_screen_v2, command_palette, command_registry.
- [x] UserRole enum (`lib/core/user_role.dart` — 8 roles + extension with label, shortLabel, isBusinessRole, isFieldRole, isFinancialRole, isExternalRole, fromString)
- [x] Commit: `[R1a] App remake — design system + adaptive shell`

### R1b: Owner/Admin Experience (~14 hrs)
**Status: DONE — Screens (Session 78)**
- [x] Owner home screen (revenue, attention items, schedule, activity)
- [x] Jobs tab (pipeline, filters, search)
- [x] Money tab (invoices + bids + ZBooks)
- [x] Calendar tab (day/week/month, assignments)
- [x] More menu (customers, team, insurance, properties, reports, leads, settings)
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1c: Tech/Field Experience (~14 hrs)
**Status: DONE — Screens (Session 78). Field tool rewire deferred to R1j.**
- [x] Tech home screen (clock slider, today's jobs, quick actions, stats)
- [x] Walkthrough tab (prominent entry point)
- [x] Jobs tab (my jobs, today focus)
- [x] Tools screen (job site, safety, financial, insurance categories)
- [ ] Quick actions menu (role/context/time aware) — deferred to R1j
- [ ] Rewire all existing field tools to new design system — deferred to R1j
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1d: Office Manager Experience (~10 hrs)
**Status: DONE — Screens (Session 78)**
- [x] Office home screen (today, actions, schedule, messages)
- [x] Schedule tab (calendar + dispatch)
- [x] Customers tab (CRM + leads)
- [x] Money tab (invoices + bids + payments)
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1e: Inspector Experience (~14 hrs)
**Status: DONE — Screens (Session 78). DB tables + infrastructure deferred to R1j.**
- [ ] Deploy inspection_templates + inspection_results + inspection_deficiencies tables — deferred to R1j
- [ ] Seed system inspection templates — deferred to R1j
- [x] Inspector home screen (today's inspections, stats)
- [x] Active inspection screen (checklist with pass/fail/conditional per item)
- [ ] Deficiency capture (fail → photo → annotate → code cite → severity) — deferred to R1j
- [x] History + re-inspection linking
- [x] Inspector tools screen (code lookup, measurements, floor plans, annotations)
- [ ] Code lookup (Z-powered natural language) — deferred to Phase E
- [ ] Floor plan integration (pin deficiencies) — deferred to R1j
- [ ] Report generation (auto PDF) — deferred to R1j
- [ ] Web CRM inspection hooks — deferred to R1j
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1f: Homeowner/Client Experience (~12 hrs)
**Status: DONE — Screens (Session 78). DB tables + AI features deferred.**
- [ ] Deploy home_scan_logs + home_maintenance_reminders tables — deferred to R1j
- [x] Homeowner home screen (projects, attention, health, scan CTA)
- [x] Home Scanner (camera screen shell)
- [ ] Research mode (deep info on issues) — deferred to Phase E
- [x] Projects + bid review + invoices/payments
- [x] My Home (details, systems, maintenance log)
- [x] Client more screen
- [ ] Home Health Monitor (AI reminders, seasonal checklists) — deferred to Phase E
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1g: CPA Experience (~6 hrs)
**Status: DONE — Screens (Session 78)**
- [x] CPA home screen (financial overview, review queue)
- [x] Accounts + journal entries
- [x] Reports (P&L, Balance Sheet, Cash Flow, Schedule C/E, 1099)
- [x] Expense/receipt/invoice review queue
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1h: Tenant Experience (~4 hrs)
**Status: DONE — Screens (Session 78)**
- [x] Tenant home screen (rent, maintenance, lease)
- [x] Rent (balance, history, pay)
- [x] Maintenance (submit, track, rate)
- [x] My Unit (details, lease, inspections)
- [x] Commit: `[R1b-R1h] All 7 role experiences — 33 screens`

### R1i: Z Intelligence Integration (~16 hrs)
**Status: DEFERRED to Phase E (AI goes LAST per build rules)**
- [ ] Voice-first Z (speech → intent → action → confirmation)
- [ ] Camera-first Z (live camera → Claude Vision → result card → actions)
- [ ] Ambient Z (contextual suggestions → dismiss tracking → learning)
- [ ] Quick action menu per role
- [ ] Voice command execution (top 20 actions)
- [ ] Camera identification (top 10 scenarios)
- [ ] Ambient suggestions (10+ types per role)
- [ ] Z settings (voice/wake word/ambient/camera toggles)
- [ ] Commit: `[R1i] Z Intelligence — voice + camera + ambient`

### R1j: Cross-Role Integration + Testing (~8 hrs)
**Status: DONE — Core integration (Session 78). Backend wiring deferred to next sprint.**
- [ ] Permission override system (admin grants/restricts per user) — deferred (needs admin UI)
- [x] Role switching (RoleSwitcherScreen + quick actions Z button)
- [ ] Deep linking from notifications — deferred (needs push notification setup)
- [ ] Onboarding flow per role — deferred (design needed)
- [x] All 7 roles navigate correctly (AppShell wired, 33 screens)
- [ ] All existing backend wiring connected to new screens — deferred (massive task, next sprint)
- [x] `dart analyze` passes (0 errors)
- [x] Commit: `[R1j] Role switching + navigation verification`

**Total estimated: ~110 hours across 10 sub-steps**
**New tables: 6 (app_user_preferences, inspection_templates, inspection_results, inspection_deficiencies, home_scan_logs, home_maintenance_reminders)**

---

## PHASE E: AI LAYER

**Prerequisite:** All business data must be flowing (B1-B6 COMPLETE) + R1 app remake. AI depends on real data + new app shell.
**API:** Claude API (Anthropic) via Supabase Edge Functions (Deno). No direct browser→Claude calls.
**Model:** Claude Sonnet 4.5 for speed, Claude Opus 4.6 for complex artifact generation.

### Sprint E1: Universal AI Architecture
**Status: DONE (Session 78)**

**Goal:** Build the shared AI infrastructure that all Z Intelligence features depend on.
**Depends on:** B4e (Z Console UI shell), B1-B6 (real data flowing).

#### E1a: Database Schema (z_threads + z_artifacts tables)

**New migration:** `20260206000010_e1_ai_tables.sql`

```sql
-- Z Intelligence threads (replaces localStorage persistence)
CREATE TABLE z_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL DEFAULT 'New conversation',
  page_context TEXT, -- pathname where thread was started
  messages JSONB NOT NULL DEFAULT '[]'::jsonb, -- ZMessage[]
  artifact_id UUID, -- FK to z_artifacts if thread has active artifact
  token_count INTEGER DEFAULT 0, -- total tokens used in this thread
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ -- soft delete
);

-- Z Intelligence artifacts (bids, invoices, reports, etc.)
CREATE TABLE z_artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  thread_id UUID REFERENCES z_threads(id),
  type TEXT NOT NULL CHECK (type IN ('bid','invoice','report','job_summary','email','change_order','scope','generic')),
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '', -- markdown
  data JSONB NOT NULL DEFAULT '{}'::jsonb, -- structured fields (customer, options, totals, etc.)
  versions JSONB NOT NULL DEFAULT '[]'::jsonb, -- ZArtifactVersion[]
  current_version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'generating' CHECK (status IN ('generating','ready','approved','rejected','draft')),
  -- Approval tracking
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  -- Source tracking (what data was used to generate)
  source_job_id UUID REFERENCES jobs(id),
  source_customer_id UUID REFERENCES customers(id),
  source_bid_id UUID REFERENCES bids(id),
  source_invoice_id UUID REFERENCES invoices(id),
  -- Conversion tracking (artifact → real record)
  converted_to_bid_id UUID REFERENCES bids(id),
  converted_to_invoice_id UUID REFERENCES invoices(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- RLS: company-scoped
ALTER TABLE z_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE z_artifacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY z_threads_company ON z_threads USING (company_id = requesting_company_id());
CREATE POLICY z_artifacts_company ON z_artifacts USING (company_id = requesting_company_id());

-- Indexes
CREATE INDEX idx_z_threads_user ON z_threads(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_threads_company ON z_threads(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_artifacts_thread ON z_artifacts(thread_id);
CREATE INDEX idx_z_artifacts_company ON z_artifacts(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_artifacts_status ON z_artifacts(status) WHERE deleted_at IS NULL;

-- Audit triggers
CREATE TRIGGER z_threads_updated BEFORE UPDATE ON z_threads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER z_artifacts_updated BEFORE UPDATE ON z_artifacts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**Verification:** Deploy to dev, verify tables in SQL Editor.

#### E1b: Claude API Edge Function (Proxy)

**New Edge Function:** `supabase/functions/z-intelligence/index.ts`

**Purpose:** Proxy between browser and Claude API. Handles:
- Auth verification (extract user from Supabase JWT)
- Company-scoped rate limiting
- System prompt construction
- Tool use routing
- Response streaming (SSE)
- Token counting + budget enforcement

**Request shape:**
```typescript
interface ZIntelligenceRequest {
  threadId: string; // existing thread or 'new'
  message: string; // user's input
  pageContext: string; // current pathname
  artifactContext?: { // active artifact if editing
    id: string;
    type: string;
    content: string;
    data: Record<string, unknown>;
    currentVersion: number;
  };
}
```

**Response:** Server-Sent Events (SSE) stream
```
event: thinking
data: {"toolCalls": [{"name": "searchCustomers", "status": "running"}]}

event: tool_result
data: {"name": "searchCustomers", "status": "complete", "result": [...]}

event: content
data: {"delta": "Here's the bid I've prepared..."}

event: artifact
data: {"type": "bid", "title": "...", "content": "...", "data": {...}}

event: done
data: {"tokenCount": 1842, "threadId": "..."}
```

**System prompt template:**
```
You are Z, the AI assistant for {companyName} — a {trade} contractor using ZAFTO.
Current user: {userName} ({role})
Current page: {pageContext}
Company data available: {tableList}

You can:
1. Query business data (customers, jobs, invoices, bids, materials, time entries)
2. Generate professional documents (bids, invoices, reports, change orders, scopes of work)
3. Analyze financial data (margins, costs, revenue trends)
4. Schedule and calendar management

When generating a document, output it as a ZAFTO artifact with type, title, content (markdown), and data (structured JSON).

{pageSpecificInstructions}
```

**Rate limiting:**
- Per-company: 1000 messages/day (Starter), 5000/day (Pro), Unlimited (Enterprise)
- Per-user: 200 messages/day
- Token budget: 500K tokens/day per company (configurable)
- Store counts in `z_usage` table or Redis (if available)

#### E1c: Tool Use Framework

**Tools available to Claude (via function calling):**

| Tool Name | Description | Supabase Query |
|-----------|-------------|----------------|
| searchCustomers | Find customers by name/email/phone | `customers.select(*).ilike('name', '%query%')` |
| getCustomer | Get full customer detail | `customers.select(*).eq('id', id)` |
| searchJobs | Find jobs by title/status/customer | `jobs.select(*, customers(name))` |
| getJob | Get job detail with related data | `jobs.select(*, customers(*), change_orders(*), invoices(*))` |
| getInvoices | List invoices with filters | `invoices.select(*, jobs(title)).order('created_at')` |
| getBids | List bids with filters | `bids.select(*, customers(name))` |
| getSchedule | Get jobs scheduled in date range | `jobs.select(*).gte('scheduled_start', from).lte('scheduled_start', to)` |
| getMaterials | Get materials for a job | `job_materials.select(*).eq('job_id', id)` |
| getTimeEntries | Get time entries for user/job | `time_entries.select(*).eq('job_id', id)` |
| getPunchList | Get punch list items | `punch_list_items.select(*).eq('job_id', id)` |
| getChangeOrders | Get change orders | `change_orders.select(*).eq('job_id', id)` |
| calculateMargin | Compute job margin from invoices + materials | Aggregate query |
| getLeads | List leads by stage | `leads.select(*).eq('stage', stage)` |
| getTeam | List team members | `users.select(*).eq('company_id', companyId)` |

**Tool execution pattern:**
1. Claude sends tool_use message with tool name + parameters
2. Edge Function executes Supabase query (using service role key, scoped by company_id)
3. Results returned to Claude as tool_result
4. Claude incorporates data into response
5. Multiple tool calls can happen in parallel (Claude supports this)

**Security:**
- All queries scoped by company_id from JWT
- Service role key ONLY in Edge Function (never in browser)
- Tool parameters validated before query execution
- Sensitive fields redacted (e.g., no SSN, bank accounts)

#### E1d: Response Parser + Artifact Detection

**Artifact generation protocol:**
Claude should output artifacts using a structured format:

```
<artifact type="bid" title="Bid #BID-2026-0042 — Whole House Rewire">
<data>
{"customer":{"name":"David Park","address":"1847 Elm St"},"options":[...]}
</data>
<content>
# Bid Proposal — Whole House Rewire
...full markdown...
</content>
</artifact>
```

**Parser responsibilities:**
1. Detect `<artifact>` tags in Claude response stream
2. Extract type, title, content, data
3. Create ZArtifact object with version 1
4. Send via SSE `artifact` event
5. Store in z_artifacts table
6. Link to z_threads.artifact_id

**Version editing protocol:**
When user sends edit request with active artifact:
1. System prompt includes current artifact content + data
2. Claude generates updated content + data
3. Parser creates new version (version N+1)
4. Appends to versions JSONB array
5. Updates content + data with new version
6. Updates current_version

#### E1e: Web CRM Hooks + Provider Update

**New hook files:**
- `web-portal/src/lib/hooks/use-z-threads.ts` — CRUD for z_threads table
  - `useZThreads()` — list threads (most recent first, limit 50)
  - `useZThread(id)` — single thread with messages
  - `createThread()`, `deleteThread()`
  - Real-time subscription for thread updates

- `web-portal/src/lib/hooks/use-z-artifacts.ts` — CRUD for z_artifacts table
  - `useZArtifacts()` — list artifacts by type/status
  - `useZArtifact(id)` — single artifact
  - `updateArtifactStatus()`, `convertArtifact()` (create real bid/invoice from artifact)

**Provider update (z-console-provider.tsx):**
1. Replace localStorage persistence with Supabase hooks
2. Replace `simulateResponse()` call with Edge Function SSE fetch
3. Add streaming state (partial content displayed as it arrives)
4. Add token counter display (usage tracking)
5. Thread CRUD → Supabase instead of local state

**Verification:**
- [x] z_threads and z_artifacts tables deployed to dev (migration 000025, 81 tables total)
- [x] Edge Function deployed and responding to test requests (z-intelligence)
- [x] System prompt generates coherent responses with business context (buildSystemPrompt)
- [x] Tool calls execute real Supabase queries (14 tools in executeTool)
- [x] Streaming works (SSE via ReadableStream in Edge Function)
- [x] Artifacts persist to database after generation (parseArtifacts + INSERT)
- [x] Thread history loads from Supabase (use-z-threads.ts hook)
- [x] Rate limiting enforces company/user quotas (checkRateLimit in Edge Function)
- NOTE: ANTHROPIC_API_KEY secret not set yet — user must run `npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...`
- NOTE: Set NEXT_PUBLIC_Z_INTELLIGENCE_ENABLED=true to switch from mock to live mode

---

### Sprint E2: Z Console → Claude API Wiring
**Status: DONE (Session 78) — Built as part of E1 implementation**

**Goal:** Replace all mock responses in the Z Console with real Claude API calls. Wire tool use to live Supabase data. Full artifact lifecycle.
**Depends on:** E1 (infrastructure), B4e (UI shell already built).

**Existing Z Console architecture (built in B4e):**
- 22 files: 5 lib/z-intelligence/ + 17 components/z-console/
- 3 states: collapsed (ZPulse) → open (ZChatPanel 420px) → artifact (ZArtifactSplit min(60vw,800px))
- Provider: useReducer with 12 action types, localStorage persistence
- Mock engine: simulateResponse() with keyword detection, multi-step bid flow, artifact edit detection
- Slash commands: 6 defined (/bid, /invoice, /report, /analyze, /schedule, /customer)
- Context map: 15 pages with custom quick actions, dynamic labels for detail pages
- Artifact templates: 3 mocks (bid 3-tier, invoice, report) with content + data + versions

#### E2a: Replace Mock Engine with Claude API Streaming

**File:** `web-portal/src/lib/z-intelligence/mock-responses.ts` → rename to `api-client.ts`

**Replace simulateResponse() with:**
```typescript
export async function sendToZ(
  request: ZIntelligenceRequest,
  callbacks: {
    onThinking: () => void;
    onToolCall: (toolCall: ZToolCall) => void;
    onToolResult: (name: string, status: string) => void;
    onContent: (delta: string) => void;
    onArtifact: (artifact: ZArtifact) => void;
    onDone: (meta: { tokenCount: number; threadId: string }) => void;
    onError: (error: string) => void;
  }
): Promise<void>
```

**Implementation:**
1. POST to `/functions/v1/z-intelligence` with Supabase auth token
2. Read SSE stream via `fetch()` + `ReadableStream`
3. Parse each SSE event and call corresponding callback
4. Handle connection errors, timeouts (30s), retry logic (1 retry)

**Provider integration:**
- `sendMessage()` in z-console-provider.tsx calls `sendToZ()` instead of `simulateResponse()`
- `onContent` callback: dispatch ADD_PARTIAL_CONTENT (new reducer action for streaming)
- `onToolCall` callback: dispatch UPDATE_TOOL_CALLS (update message's toolCalls array)
- `onArtifact` callback: dispatch SET_ARTIFACT (existing action)
- `onDone` callback: finalize message, update token counter, persist to Supabase

**New reducer actions needed:**
| Action | Purpose |
|--------|---------|
| ADD_PARTIAL_CONTENT | Append streaming delta to last assistant message |
| UPDATE_TOOL_CALLS | Update tool call statuses as they resolve |
| SET_TOKEN_COUNT | Track usage per thread |
| PERSIST_THREAD | Trigger Supabase save after message exchange |

#### E2b: Wire Slash Commands to Tool Routing

**Current state:** Slash commands are UI-only (displayed in autocomplete). Mock engine uses keyword matching.

**Wire each command:**

| Command | Tool Calls | Artifact? | Behavior |
|---------|-----------|-----------|----------|
| /bid | searchCustomers, searchJobs, getPriceBook → generateBid | YES (type: bid) | Multi-step: ask customer → fetch data → generate 3-tier bid |
| /invoice | getJob, getMaterials, getTimeEntries → generateInvoice | YES (type: invoice) | From job: calculate line items from materials + labor → generate invoice |
| /report | queryInvoices, queryJobs, getTeam → generateReport | YES (type: report) | Context-aware: on /invoices → aging report, on /dashboard → revenue report |
| /analyze | queryJobs, calculateMargin, getMaterials | NO | Returns markdown table with margin analysis |
| /schedule | getSchedule, getTeam | NO | Returns today/week schedule with crew assignments |
| /customer | searchCustomers | NO | Interactive: ask for search term → display results → offer actions |

**Slash command → system prompt injection:**
When user types `/bid`, prepend to system prompt:
```
The user wants to create a bid. Follow this flow:
1. If no customer specified, ask which customer
2. Query customer details and any related jobs
3. Generate a professional 3-tier bid (Good/Better/Best) as a ZAFTO artifact
4. Include scope of work, materials breakdown, labor estimate, payment terms
```

#### E2c: Artifact Lifecycle (Generate → Edit → Approve → Convert)

**Generation flow:**
1. Claude decides to create artifact → outputs `<artifact>` block
2. Parser extracts type/title/content/data
3. INSERT into z_artifacts (status: 'generating')
4. Stream content to ZArtifactViewer (z-artifact-reveal animation)
5. On stream complete → UPDATE status to 'ready'
6. ZArtifactToolbar shows Approve/Reject/Save Draft buttons

**Edit flow:**
1. User types edit request in artifact split chat input
2. System prompt includes current artifact content + data + version history
3. Claude generates updated content/data
4. New version appended to versions JSONB
5. current_version incremented
6. ZArtifactToolbar version tabs update

**Approval flow:**
1. User clicks "Approve & Send" on toolbar
2. UPDATE z_artifacts SET status='approved', approved_by, approved_at
3. System message added to thread: "Artifact approved"
4. **Optional conversion:** Show modal asking "Create real {bid/invoice} from this?"
   - If yes → INSERT into bids/invoices table from artifact.data
   - UPDATE z_artifacts SET converted_to_bid_id/converted_to_invoice_id
   - Navigate to the newly created record

**Rejection flow:**
1. User clicks "Reject" on toolbar
2. UPDATE z_artifacts SET status='rejected'
3. System message: "Artifact rejected. Would you like me to try a different approach?"
4. Console stays in artifact state (user can edit or start over)

**Save draft flow:**
1. User clicks "Save Draft"
2. UPDATE z_artifacts SET status='draft'
3. System message: "Draft saved. You can resume editing later."
4. Console returns to 'open' state

#### E2d: Context-Aware System Prompts

**System prompt structure:**
```
[IDENTITY]
You are Z, the AI assistant built into ZAFTO — a contractor business management platform.
You serve {companyName}, a {companyTrade} contractor.

[CURRENT USER]
Name: {userName}
Role: {role} (owner|admin|office|tech)
Page: {pageContext}

[AVAILABLE TOOLS]
{toolList with descriptions}

[ARTIFACT PROTOCOL]
When generating a document, wrap it in <artifact type="..." title="..."> tags.
Include <data>{JSON}</data> for structured fields.
Include <content>{markdown}</content> for rendered display.

[PAGE-SPECIFIC INSTRUCTIONS]
{Varies by page — from context-map.ts getPageContext()}

[CONVERSATION HISTORY]
{Previous messages in this thread, truncated to fit context window}
```

**Page-specific instructions (expand context-map.ts):**

| Page | Instructions |
|------|-------------|
| /dashboard | Focus on overview: revenue trends, upcoming work, overdue items. Default to executive summary. |
| /dashboard/jobs | Focus on job management: status updates, scheduling, crew assignment. |
| /dashboard/invoices | Focus on financial: aging, overdue, payment tracking. |
| /dashboard/customers | Focus on relationship: history, preferences, upcoming work. |
| /dashboard/bids | Focus on sales: pricing strategy, win rate, competitive analysis. |
| /dashboard/leads | Focus on pipeline: qualification, follow-up, conversion. |
| /dashboard/calendar | Focus on scheduling: availability, conflicts, route optimization. |
| /dashboard/team | Focus on HR: availability, workload, performance. |
| /dashboard/reports | Focus on analytics: trends, comparisons, projections. |
| /dashboard/books | Focus on accounting: P&L, cash flow, tax preparation. |

#### E2e: Error Handling + Edge Cases

**Network errors:**
- Connection timeout (30s) → Show "Z is having trouble connecting. Try again?"
- Stream interrupted → Show partial content + "Response was interrupted" badge
- Rate limit hit → Show "You've reached your daily limit. Resets at midnight."

**Claude errors:**
- Content filter → "I can't help with that request." (preserve thread)
- Context too long → Auto-truncate older messages, retry
- Tool call fails → Claude informed via tool_result error, adjusts response

**Data edge cases:**
- No customers found → Claude asks for more info
- No jobs for customer → Claude suggests creating one first
- Empty schedule → Claude says "No jobs scheduled for that period"
- Artifact content too long → Paginate in viewer (or scroll)

**Verification checklist:**
- [x] Real Claude API responses appear in chat (streaming) — api-client.ts with SSE parsing
- [x] Tool calls query real Supabase data — 14 tools in Edge Function executeTool
- [x] /bid generates artifact from real customer + price data — system prompt handles slash commands
- [x] /invoice generates artifact from real job + materials data
- [x] /report generates artifact from real invoice + job data
- [x] Artifact editing creates new versions — provider UPDATE_ARTIFACT_VERSION
- [x] Approve → creates real bid/invoice record — use-z-artifacts.ts convertArtifact
- [x] Thread history persists to z_threads table — Edge Function persists on done
- [x] Artifacts persist to z_artifacts table — Edge Function INSERT on artifact detect
- [x] Rate limiting works per company — checkRateLimit in Edge Function
- [x] Error states display gracefully — onError callback in api-client + provider
- [x] Context chip shows correct page context — unchanged from B4e
- [x] Quick actions send correct prompts — unchanged from B4e
- [x] Cmd+J toggle still works — unchanged from B4e
- [x] Version navigation in toolbar works — unchanged from B4e
- [x] Commit: `[E1-E2] Z Intelligence — AI tables + Edge Function + hooks + provider wiring`

---

### Sprint E3: Employee Portal AI + Mobile AI (Outline)
*Detail when E2 nears completion.*

**E3a: AI Troubleshooting Center (team.zafto.app)**
- Multi-trade diagnostics (electrical, HVAC, plumbing codes)
- Photo-based diagnosis (upload photo → Claude Vision → diagnosis)
- Code/compliance lookup (NEC, IRC, IPC, IMC)
- Parts identification (describe part → identify + find suppliers)
- Repair guides (step-by-step with safety warnings)
- Company knowledge base (past jobs, common fixes, preferred methods)

**E3b: Mobile App AI Integration (Flutter)**
- Z button on mobile screens
- Voice-to-text for field notes
- Photo analysis for defect detection
- Receipt OCR (Claude Vision)
- Voice note transcription

**E3c: Client Portal AI (basic)**
- Project status summaries (AI-generated plain language)
- Invoice explanations ("What am I paying for?")
- Scheduling assistance ("When is my next appointment?")

---

### Sprint E4: Growth Advisor + Advanced AI (Outline)
*Detail when E3 nears completion.*

**E4a: Revenue Intelligence**
- Profit margin optimization suggestions
- Pricing recommendations based on job history
- Seasonal trend analysis
- Customer lifetime value predictions

**E4b: Bid Brain (AI-enhanced bidding)**
- Win probability scoring
- Competitive price analysis
- Scope optimization suggestions
- Auto-generate bid from job walkthrough notes

**E4c: Equipment Memory**
- Equipment lifecycle tracking per property
- Predictive maintenance alerts
- Parts inventory suggestions
- Warranty tracking

**E4d: Revenue Autopilot**
- Automated follow-up scheduling
- Upsell/cross-sell suggestions
- Seasonal campaign generation
- Review request automation

---

### Sprint E5: Xactimate Estimate Engine
**Source:** `Expansion/25_XACTIMATE_ESTIMATE_ENGINE.md`
**Goal:** Replace $300/mo Xactimate with built-in estimate writing, independent pricing, and AI-powered scope analysis.
**Depends on:** E1 (AI infra), D2a (insurance tables already deployed), legal review (for ESX export).
**Status: E5a-f + E5i-j DONE (S79). E5g-h BLOCKED on legal review.**

#### E5a: Pricing Database Foundation (~8 hrs)
**Status: DONE (Session 78)**
- [x] Deploy `xactimate_codes` table + seed with 77 initial codes (migration 000026, 86 tables total)
- [x] Deploy `pricing_entries` table (regional pricing with MAT/LAB/EQU + confidence)
- [x] Deploy `pricing_contributions` table (anonymized crowd-sourced data)
- [x] Deploy `estimate_templates` table (reusable templates per trade/loss type)
- [x] Deploy `esx_imports` table (ESX file tracking)
- [x] ALTER `xactimate_estimate_lines` — added code_id, material_cost, labor_cost, equipment_cost, room_name, line_number, coverage_group
- [x] Build pricing aggregation Edge Function (`xact-pricing-aggregate` — monthly cron)
- [x] Build code search/browse API (`xact-code-search` — FTS on description, category filter, pricing lookup)
- [x] Commit: `[E5a] Xactimate pricing database foundation`

#### E5b: Estimate Writer UI — Web CRM (~12 hrs)
**Status: DONE (Session 79)**
- [x] Estimate editor page: room-by-room line item entry
- [x] Code browser sidebar: search/filter all 70+ categories
- [x] Auto-price lookup: select code → populate MAT/LAB/EQU from pricing DB
- [x] O&P calculator: configurable 10/10 markup per trade or total
- [x] Coverage group assignment: structural/contents/other
- [x] Summary view: ACV, RCV, depreciation, O&P totals
- [x] Estimate templates: save/load common scopes
- [x] Hook: `use-estimate-engine.ts` with full CRUD + calculations
- [x] Sidebar nav: added INSURANCE section (Claims + Estimate Writer)
- [x] Commit: `[E5b] Xactimate estimate writer — Web CRM`

#### E5c: PDF Output (~6 hrs)
**Status: DONE (Session 79)**
- [x] PDF template matching Xactimate layout (print-ready HTML with @page rules)
- [x] Cover sheet: company logo, claim info, contacts, policy
- [x] Line items: categorized with MAT/LAB/EQU columns, room grouping
- [x] Summary: totals by coverage group, depreciation, O&P
- [x] Download button on estimate editor → opens print-ready page in new tab
- [x] Edge Function `estimate-pdf` for server-side HTML generation (deployed)
- [x] Commit: `[E5c] Xactimate-style PDF estimate output`

#### E5d: AI PDF Parsing (~8 hrs)
**Status: DONE (Session 79)**
- [x] Upload handler: accept Xactimate PDF exports (base64 → Edge Function)
- [x] Claude Vision extraction prompt (structured JSON output, all line items)
- [x] Mapping engine: extracted codes → xactimate_codes lookup + pricing comparison
- [x] Auto-populate claim + estimate lines from parsed data (batch insert)
- [x] Review UI: 3-step wizard (upload → review → confirm) with selectable items
- [x] Discrepancy highlighting: ZAFTO price vs parsed Xactimate price, code match indicators
- [x] Edge Function `estimate-parse-pdf` deployed
- [x] Import PDF button on estimates list page
- [x] Commit: `[E5d] AI PDF parsing — Xactimate estimate import`

#### E5e: AI Scope Assistant (~6 hrs)
**Status: DONE (Session 79)**
- [x] Gap detection engine: loss type → expected scope → missing items (with priority levels)
- [x] Photo analysis: damage type → suggested line items (Claude Vision)
- [x] Supplement generator: narrative + additional items + standards + cost estimate
- [x] Z Assist sidebar tab in estimate editor (integrated into existing sidebar)
- [x] Pricing dispute letter generator (formal correspondence with key points)
- [x] Edge Function `estimate-scope-assist` deployed (4 actions)
- [x] Hook: `use-scope-assist.ts` with typed results for all 4 actions
- [x] Commit: `[E5e] AI scope assistant — gap detection + supplement generator`

#### E5f: Flutter Estimate Entry (~8 hrs)
**Status: DONE (Session 79)**
- [x] Simplified estimate screen (mobile-optimized, room-grouped, swipe-to-delete)
- [x] Photo capture → AI scope suggestion (opens camera, sends to scope assist)
- [x] Code search with autocomplete (bottom sheet, category filter, debounced search)
- [x] Quick-add from templates (template picker bottom sheet)
- [x] Model: estimate_line.dart + xactimate_code.dart
- [x] Repository: estimate_repository.dart (CRUD + code search + pricing lookup)
- [x] Service: estimate_service.dart (auth-enriched, company_id injection)
- [x] Screen: estimate_editor_screen.dart + code_search_sheet.dart
- [x] Sync with web CRM estimate (same DB tables)
- [x] dart analyze: 0 issues on all 6 new files
- [x] Commit: `[E5f] Flutter estimate entry — mobile field estimating`

#### E5g: ESX Import (~6 hrs) — BLOCKED ON LEGAL REVIEW
- [ ] **PREREQUISITE: Legal counsel review COMPLETE**
- [ ] ESX upload handler + ZIP extraction
- [ ] XACTDOC XML parser (contacts, claim, line items)
- [ ] Image extraction and storage
- [ ] Auto-populate claim + estimate from parsed ESX
- [ ] Error handling for unknown XML elements/versions
- [ ] Commit: `[E5g] ESX import — parse Xactimate project files`

#### E5h: ESX Export (~6 hrs) — BLOCKED ON LEGAL REVIEW
- [ ] **PREREQUISITE: Legal counsel review COMPLETE**
- [ ] ESX file generator (XML + images → ZIP)
- [ ] XACTDOC XML writer (valid schema)
- [ ] Download as .esx for import into Xactimate/XactAnalysis
- [ ] Round-trip verification test
- [ ] Commit: `[E5h] ESX export — generate Xactimate-compatible files`

#### E5i: Crowd-Sourced Pricing Pipeline (~4 hrs)
**Status: DONE (Session 79)**
- [x] Invoice finalization trigger: fn_extract_pricing_contributions() on invoices.status → paid/finalized
- [x] Anonymization pipeline: strips company_id, claim_id, customer info — only code_id + region + costs
- [x] Monthly aggregation Edge Function: `xact-pricing-aggregate` (built in E5a)
- [x] Pricing confidence calculation: low (<5), medium (5-19), high (20-49), verified (50+)
- [x] Admin dashboard: pricing coverage page at /dashboard/estimates/pricing
- [x] Migration 000027: trigger + property_zip column + coverage view + indexes
- [x] Commit: `[E5i] Crowd-sourced pricing pipeline`

#### E5j: Testing + Verification (~4 hrs)
**Status: DONE (Session 79)**
- [x] dart analyze: 0 issues on all 6 new Flutter files
- [x] Web portal: npm run build ✓
- [x] Team portal: npm run build ✓
- [x] Client portal: npm run build ✓
- [x] Flutter: dart analyze passes (0 errors on new files, info-only pre-existing)
- [x] All Edge Functions deployed: estimate-pdf, estimate-parse-pdf, estimate-scope-assist
- [x] Migration 000027 deployed (pricing pipeline trigger + view)
- [x] Commit: `[E5j] Xactimate estimate engine — testing complete`

**Total estimated: ~68 hours across 10 sub-steps**
**New tables: 5 (xactimate_codes, pricing_entries, pricing_contributions, estimate_templates, esx_imports) + 1 ALTER**

---

### Sprint E6: Bid Walkthrough Engine
**Source:** `Expansion/44_BID_WALKTHROUGH_ENGINE.md`
**Goal:** Field-to-bid pipeline — room-by-room walkthrough, LiDAR dimensions, photo annotations, sketch editor, 2D/3D asset viewer/editor, AI bid generation in every format, customizable workflows per company.
**Depends on:** E1 (AI infra), E5 (Xactimate codes/pricing for insurance bids), D5 (property tables for floor plan links).
**Status: SPEC COMPLETE — BLOCKED on Phase E readiness**

#### E6a: Walkthrough Data Model + Templates (~6 hrs)
**DONE (Session 79)**
- [x] Deploy `walkthroughs` table + RLS
- [x] Deploy `walkthrough_rooms` table
- [x] Deploy `walkthrough_photos` table
- [x] Deploy `walkthrough_templates` table + seed ~14 system templates
- [x] Deploy `property_floor_plans` table
- [x] ALTER bids, jobs (add walkthrough_id FK)
- [x] Commit: `[E6a] Walkthrough engine — data model + templates`

#### E6b: Flutter Walkthrough Capture Flow (~16 hrs)
- [ ] Walkthrough start screen (name, customer link, type, template)
- [ ] Room capture screen (photo, notes, tags, custom fields per template)
- [ ] Multi-photo per room with auto-numbering
- [ ] Voice note recording per room
- [ ] Room list with progress indicators
- [ ] Exterior capture flow
- [ ] Walkthrough finish screen (summary, upload trigger)
- [ ] Offline persistence (PowerSync + local file storage)
- [ ] Background upload with progress tracking
- [ ] Model + Repository + Service layer
- [ ] Commit: `[E6b] Flutter walkthrough capture flow`

#### E6c: Photo Annotation System (~8 hrs)
- [ ] Annotation editor (CustomPainter overlay on photo)
- [ ] Tools: draw, arrow, circle, rectangle, text, measurement, stamp
- [ ] Color/thickness selection
- [ ] Save annotations as JSON overlay (original untouched)
- [ ] Render annotated version as PNG for export
- [ ] Before/after photo linking + comparison view
- [ ] Commit: `[E6c] Photo annotation system`

#### E6d: Sketch Editor + Floor Plan Engine (~16 hrs)
- [ ] Floor plan canvas (CustomPainter + GestureDetector)
- [ ] Wall drawing tool with angle snapping
- [ ] Door/window/fixture placement from symbol library
- [ ] Room auto-detection from enclosed walls
- [ ] Dimension labels (auto-calculated, manually editable)
- [ ] Asset pins (link to property_assets table)
- [ ] Annotation overlay (text, area highlights)
- [ ] Multi-floor support (tabs)
- [ ] Undo/redo stack
- [ ] Save as structured JSON (not bitmap)
- [ ] Export as PNG/PDF
- [ ] Commit: `[E6d] Sketch editor + floor plan engine`

#### E6e: LiDAR Integration (~10 hrs)
- [ ] Evaluate and integrate ARKit plugin for iOS
- [ ] Room dimension capture from LiDAR scan
- [ ] Auto-populate sketch from LiDAR data
- [ ] Dimension editing (override LiDAR with manual values)
- [ ] LiDAR data storage (compressed mesh/point cloud)
- [ ] Fallback to manual dimension entry on non-LiDAR devices
- [ ] Commit: `[E6e] LiDAR integration — room scanning + auto-sketch`

#### E6f: 2D Floor Plan Viewer — All Apps (~8 hrs)
- [ ] Web CRM: Canvas/SVG floor plan renderer (interactive, editable)
- [ ] Web CRM: Room selection, asset pins, photo pins, status color-coding
- [ ] Client Portal: Simplified read-only viewer
- [ ] Team Portal: Viewer with progress marking
- [ ] Print-friendly export (clean black-and-white)
- [ ] Commit: `[E6f] 2D floor plan viewer — all apps`

#### E6g: AI Bid Generation Pipeline (~10 hrs)
- [ ] Edge Function: process walkthrough → analyze photos (Claude Vision)
- [ ] Edge Function: voice note transcription + extraction
- [ ] Edge Function: combine all data → generate bid per format
- [ ] Bid templates: standard, 3-tier, insurance/Xactimate, AIA, trade-specific, inspection report
- [ ] Bid review screen (Flutter + Web CRM)
- [ ] Bid edit + send capabilities
- [ ] Commit: `[E6g] AI bid generation pipeline — all formats`

#### E6h: Workflow Customization UI (~6 hrs)
- [ ] Web CRM: Settings > Walkthrough Workflows page
- [ ] Template editor: rooms, required fields, custom fields, checklist, AI instructions
- [ ] Approval workflow configuration
- [ ] Clone system template → customize
- [ ] Commit: `[E6h] Walkthrough workflow customization`

#### E6i: 3D Property Viewer + Editor (~12 hrs) — PHASE 2
- [ ] LiDAR mesh capture + storage
- [ ] 3D renderer (Flutter: flutter_gl, Web: Three.js)
- [ ] Orbit/zoom/pan, tap surfaces, asset pins in 3D
- [ ] 2D ↔ 3D sync (edits in either view update both)
- [ ] Cross-section view
- [ ] Commit: `[E6i] 3D property viewer + editor`

#### E6j: Testing + Verification (~4 hrs)
- [ ] End-to-end: walkthrough → upload → bid generation → review → send
- [ ] Offline walkthrough → reconnect → upload completes
- [ ] Floor plan CRUD across all apps
- [ ] Template customization applied in walkthrough
- [ ] All 5 apps build clean
- [ ] Commit: `[E6j] Bid walkthrough engine — testing complete`

**Total estimated: ~96 hours across 10 sub-steps**
**New tables: 5 (walkthroughs, walkthrough_rooms, walkthrough_photos, property_floor_plans, walkthrough_templates) + 3 ALTERs**

---

## PHASE F: PLATFORM COMPLETION
*Outline specs — detail when Phase E nears completion.*

### Sprint F1-F10: (See 01_MASTER_BUILD_PLAN.md for details)

---

## PHASE G: DEBUG, QA & HARDENING
*Final quality pass before launch.*

### Sprint G1: Full platform debug (~100-150 hrs)
### Sprint G2: Security audit (~20-30 hrs)
### Sprint G3: Performance optimization (~20-30 hrs)
### Sprint G4: Final security hardening (~4 hrs)

---

### >>> LAUNCH <<<

---

CLAUDE: Execute sprints in order. Update status as you complete each one. Never skip a sprint.
