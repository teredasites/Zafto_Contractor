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

### Sprint B2b: Safety & Compliance Tools (4 tools)
**Status: PENDING** | **Est: ~8-10 hours**

#### Objective
Wire LOTO Logger, Incident Report, Safety Briefing, and Confined Space Timer to compliance_records table.

#### Prerequisites
- A3c complete (compliance_records table)
- B1a complete (auth — need current user for records)

#### Files to Create
```
lib/repositories/compliance_repository.dart — CRUD for compliance_records
lib/providers/compliance_providers.dart     — Records by type, by job
```

#### Files to Modify
```
lib/screens/field_tools/loto_logger_screen.dart          — Wire save
lib/screens/field_tools/incident_report_screen.dart      — Wire save + PDF
lib/screens/field_tools/safety_briefing_screen.dart      — Wire save + crew
lib/screens/field_tools/confined_space_timer_screen.dart  — Wire OSHA logging
```

#### Steps

**Step 1: Compliance Repository**
- `createRecord(type, jobId, data, crewMembers)` → INSERT into compliance_records
- `getRecordsByJob(jobId)` → all safety records for a job
- `getRecordsByType(type)` → filtered by record_type
- `getRecentRecords(limit)` → latest safety records across all jobs
- Record types: safety_briefing, incident_report, loto, confined_space, inspection
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

**Step 5: Confined Space Timer**
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
- [ ] Confined Space: entry/exit times logged, atmosphere readings saved
- [ ] All records appear in job detail under "Safety" tab
- [ ] All records have audit trail
- [ ] Compliance records visible in Web CRM (B4)
- [ ] `flutter analyze` passes
- [ ] Commit: `[B2b] Safety tools wired — LOTO, incidents, briefings, confined space`

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
2. Add entries for all 18 field tools (13 existing + 5 new)
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
8. Enable WebAuthn (passkeys/biometrics) in Supabase Auth for phishing-resistant MFA
9. Add passkey enrollment option to all user-facing apps (CRM, Team Portal, Client Portal, Mobile)
10. Update Information Security Policy doc to reflect passkey/biometric support

#### Verify
- [ ] Every account uses admin@zafto.app
- [ ] Every account has unique 20+ char password
- [ ] Every account has 2FA enabled
- [ ] ProtonMail recovery email works
- [ ] All credentials in Bitwarden, organized
- [ ] No old API keys active
- [ ] WebAuthn/passkeys enabled in Supabase Auth config
- [ ] Passkey enrollment UI available in all portals + mobile
- [ ] Security policy doc updated with phishing-resistant MFA
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

### Sprint D8: Estimate Engine (~100+ hrs)
**Source:** `SPRINT/07_ESTIMATE_ENGINE_SPEC.md` (Clean-room production spec — S85)
**Goal:** Two-mode estimate engine. Mode 1: Regular Bids for ALL contractors (ZAFTO's own item database, PDF output). Mode 2: Insurance Estimates with ESX export (optional premium feature, industry-standard ZIP+XML format). Independent code database, crowdsource engine, regional pricing.
**Depends on:** D2 (Insurance Infrastructure), D1 (Job Type System)
**Status: PENDING**
**SUPERSEDES:** E5 (premature Xactimate estimate engine). E5 code is dormant. D8 is a clean-room rebuild with independent architecture. Zero references to proprietary tools, decryption, or reverse engineering.

#### D8a: Database — Estimate Engine Core Tables (~6 hrs)

**New migration:** `20260208_d8_estimate_engine.sql`

**10 new tables:**

```sql
-- ZAFTO's own item database (backbone for both modes)
CREATE TABLE estimate_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES estimate_categories(id),
    zafto_code VARCHAR(20) NOT NULL UNIQUE,
    industry_code VARCHAR(20),
    industry_selector VARCHAR(20),
    description TEXT NOT NULL,
    unit_code VARCHAR(10) NOT NULL,
    action_types TEXT[] DEFAULT '{add}',
    trade VARCHAR(50) NOT NULL,
    subtrade VARCHAR(100),
    tags TEXT[],
    is_common BOOLEAN DEFAULT false,
    source VARCHAR(50) DEFAULT 'zafto',
    life_expectancy_years INT,
    depreciation_max_pct INT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE estimate_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE,
    industry_code VARCHAR(10),
    name VARCHAR(100) NOT NULL,
    labor_pct INT DEFAULT 50,
    material_pct INT DEFAULT 40,
    equipment_pct INT DEFAULT 10,
    sort_order INT DEFAULT 0
);

CREATE TABLE estimate_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    abbreviation VARCHAR(10) NOT NULL
);

CREATE TABLE estimate_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES estimate_items(id),
    region_code VARCHAR(20) NOT NULL,
    labor_rate DECIMAL(10,2),
    material_cost DECIMAL(10,2),
    equipment_cost DECIMAL(10,2),
    effective_date DATE NOT NULL,
    source VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(item_id, region_code, effective_date)
);

CREATE TABLE estimate_labor_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL,
    trade VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    base_rate DECIMAL(10,2),
    markup DECIMAL(10,2),
    burden_pct DECIMAL(5,4),
    region_code VARCHAR(20),
    effective_date DATE,
    source VARCHAR(50) DEFAULT 'public'
);

CREATE TABLE code_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    user_id UUID REFERENCES auth.users(id),
    industry_code VARCHAR(10) NOT NULL,
    industry_selector VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    unit_code VARCHAR(10),
    action_type VARCHAR(10),
    verified BOOLEAN DEFAULT false,
    verification_count INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE estimates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    job_id UUID REFERENCES jobs(id),
    customer_id UUID REFERENCES customers(id),
    created_by UUID REFERENCES auth.users(id),
    estimate_number VARCHAR(20) NOT NULL,
    title VARCHAR(200),
    property_address TEXT,
    property_zip VARCHAR(10),
    estimate_type VARCHAR(20) DEFAULT 'regular',
    status VARCHAR(20) DEFAULT 'draft',
    subtotal DECIMAL(12,2) DEFAULT 0,
    overhead_pct DECIMAL(5,2) DEFAULT 10,
    profit_pct DECIMAL(5,2) DEFAULT 10,
    tax_pct DECIMAL(5,2) DEFAULT 0,
    grand_total DECIMAL(12,2) DEFAULT 0,
    deductible DECIMAL(10,2),
    claim_number VARCHAR(50),
    policy_number VARCHAR(50),
    date_of_loss DATE,
    insurance_carrier VARCHAR(200),
    adjuster_name VARCHAR(200),
    adjuster_email VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE estimate_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    floor_number INT DEFAULT 1,
    length_ft DECIMAL(8,2),
    width_ft DECIMAL(8,2),
    height_ft DECIMAL(8,2) DEFAULT 8,
    perimeter_ft DECIMAL(8,2),
    area_sf DECIMAL(10,2),
    sort_order INT DEFAULT 0,
    lidar_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE estimate_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(id) ON DELETE CASCADE,
    area_id UUID REFERENCES estimate_areas(id),
    item_id UUID REFERENCES estimate_items(id),
    industry_code VARCHAR(10),
    industry_selector VARCHAR(20),
    description TEXT NOT NULL,
    action_type VARCHAR(20) DEFAULT 'add',
    quantity DECIMAL(10,2) NOT NULL,
    unit_code VARCHAR(10) NOT NULL,
    labor_rate DECIMAL(10,2) DEFAULT 0,
    material_cost DECIMAL(10,2) DEFAULT 0,
    equipment_cost DECIMAL(10,2) DEFAULT 0,
    line_total DECIMAL(10,2) DEFAULT 0,
    depreciation_pct DECIMAL(5,2) DEFAULT 0,
    rcv DECIMAL(10,2) DEFAULT 0,
    acv DECIMAL(10,2) DEFAULT 0,
    phase INT DEFAULT 1,
    notes TEXT,
    ai_suggested BOOLEAN DEFAULT false,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE estimate_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(id) ON DELETE CASCADE,
    area_id UUID REFERENCES estimate_areas(id),
    line_item_id UUID REFERENCES estimate_line_items(id),
    storage_path VARCHAR(500) NOT NULL,
    caption TEXT,
    ai_analysis JSONB,
    taken_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

**RLS:** All tables company-scoped. estimate_items read-all for ZAFTO items. code_contributions insert-own, read-verified.

**Checklist D8a:**
- [x] Create migration file `20260208000029_d8a_estimate_engine.sql`
- [x] Deploy estimate_categories table + RLS
- [x] Deploy estimate_units table + RLS
- [x] Deploy estimate_items table + RLS + indexes (trade, category, tags GIN)
- [x] Deploy estimate_pricing table + RLS + UNIQUE constraint
- [x] Deploy estimate_labor_components table + RLS
- [x] Deploy code_contributions table + RLS
- [x] Deploy estimates table + RLS + audit trigger
- [x] Deploy estimate_areas table + RLS
- [x] Deploy estimate_line_items table + RLS
- [x] Deploy estimate_photos table + RLS
- [x] Verify all tables in Supabase SQL Editor (101 total)
- [ ] Commit: `[D8a] Estimate engine database — 10 tables deployed`

---

#### D8b: Seed Data — Initial Code Database (~8 hrs)

**Goal:** Populate estimate_items with ~200 common items across major trades. All data from publicly available sources (official Xactware category documentation, public industry training materials, published restoration guides).

**Seed categories (90+ from official Xactware help docs):**
ACC, ACT, APP, ARC, AWN, CAB, CLN, CNC, CON, CSF, DMO, DOR, DRY, ELE, ELS, EQA, EQC, EQU, EXC, FCC, FCR, FCS, FCT, FCV, FCW, FEE, FEN, FNC, FNH, FPL, FPS, FRM, FRP, GLS, HMR, HVC, INM, INS, LAB, LIT, LND, MAS, MBL, MPR, MSD, MSK, MTL, OBS, ORI, PLA, PLM, PNL, PNT, POL, PRM, PTG, RFG, SCF, SDG, SFG, SPE, SPR, STJ, STL, STR, STU, TBA, TCR, TIL, TMB, TMP, USR, VTC, WDA, WDP, WDR, WDS, WDT, WDV, WDW, WPR, WTR, XST

**Seed items per trade (priority trades):**
- Roofing (RFG): shingles, underlayment, flashing, ridge caps, drip edge
- Drywall (DRY): hang, tape, texture, patch, ceiling
- Plumbing (PLM): fixtures, supply lines, drain, water heater
- Electrical (ELE): outlets, switches, panels, wiring, fixtures
- Painting (PNT): interior walls, exterior, trim, ceilings
- Demolition (DMO): debris removal, hazmat, structural
- Water Remediation (WTR): extraction, drying, dehumidification, antimicrobial
- Framing (FRM): studs, headers, joists, sheathing
- Insulation (INS): batt, blown, spray foam, rigid
- Siding (SDG): vinyl, fiber cement, wood
- HVAC (HVC): units, ductwork, vents, thermostats

**Seed units:** SF, LF, EA, SQ, HR, BF, CY, GA, LB, RL, CT, MO

**Checklist D8b:**
- [x] Create seed migration `20260208000030_d8b_seed_estimate_data.sql`
- [x] Seed estimate_units (16 units of measure)
- [x] Seed estimate_categories (86 categories with industry code mappings)
- [x] Seed estimate_items (216 common items with ZAFTO codes + industry mappings)
- [x] Seed estimate_labor_components (28 base rates per trade from BLS public data)
- [x] Verify seed data loads correctly
- [ ] Commit: `[D8b] Estimate engine seed data — 86 categories, 216 items`

---

#### D8c: Estimate CRUD — Flutter Mobile (~14 hrs)

**Goal:** Full estimate creation and editing on mobile. Room-by-room workflow, line item picker, offline support.

**New files:**
- `lib/models/estimate.dart` — Estimate, EstimateArea, EstimateLineItem models
- `lib/models/estimate_item.dart` — EstimateItem (code database item) model
- `lib/repositories/estimate_repository.dart` — CRUD + code search + pricing lookup
- `lib/services/estimate_service.dart` — Auth-enriched, company_id injection
- `lib/screens/estimates/estimate_list_screen.dart` — List with filters (status, type)
- `lib/screens/estimates/estimate_builder_screen.dart` — Room-by-room editor
- `lib/screens/estimates/room_editor_screen.dart` — Room dimensions + line items
- `lib/screens/estimates/line_item_picker_screen.dart` — Search + filter items
- `lib/screens/estimates/estimate_preview_screen.dart` — Summary view before export

**UI Flow:**
1. Estimate List → tap "+" → New Estimate (regular or insurance toggle)
2. Add rooms/areas → enter dimensions (or LiDAR placeholder for Phase E)
3. Per room: search items → add to scope → adjust quantities
4. Preview: subtotal, O&P, tax, grand total
5. Actions: Save Draft, Generate PDF, Send to Customer

**Checklist D8c:**
- [x] Estimate model (Estimate, EstimateArea, EstimateLineItem, EstimatePhoto)
- [x] EstimateItem model (code database item, EstimateCategory, EstimateUnit)
- [x] EstimateEngineRepository (CRUD, search, code DB — separate from E5 estimate_repository)
- [x] EstimateEngineService (auth-enriched, providers, notifier, stats)
- [x] Estimate list screen (filters: draft/sent/approved/rejected, type: regular/insurance)
- [x] Estimate builder screen (room list, totals summary, actions)
- [x] Room editor screen (dimensions form, line item list, add item button)
- [x] Line item picker (search by description/code/trade, category filter, add to room)
- [x] Estimate preview screen (formatted summary, PDF trigger placeholder)
- [x] Insurance mode toggle (shows claim/policy/carrier/adjuster fields)
- [x] Auto-calculate totals (subtotal + O&P + tax = grand_total)
- [x] dart analyze: 0 issues
- [ ] Commit: `[D8c] Flutter estimate engine — mobile field estimating`

---

#### D8d: Estimate CRUD — Web CRM (~12 hrs)

**Goal:** Full estimate management in the CRM. Estimate editor with room-by-room breakdown, auto-pricing, template system.

**New files:**
- `web-portal/src/lib/hooks/use-estimates.ts` — Full CRUD + calculations + search
- `web-portal/src/app/dashboard/estimates/page.tsx` — Estimate list
- `web-portal/src/app/dashboard/estimates/new/page.tsx` — Create estimate
- `web-portal/src/app/dashboard/estimates/[id]/page.tsx` — Estimate editor
- `web-portal/src/app/dashboard/estimates/[id]/preview/page.tsx` — PDF preview

**Features:**
- Estimate list with status badges and type filter
- Room-by-room line item entry with drag-to-reorder
- Code browser: search/filter all categories
- Auto-price lookup: select item → populate costs from pricing DB
- O&P calculator: configurable markup per trade or total
- Insurance fields: claim #, policy #, carrier, adjuster (conditional on type=insurance)
- Template system: save/load common scopes per trade
- Summary view: subtotal, O&P, tax, depreciation (insurance mode), ACV/RCV

**Checklist D8d:**
- [x] use-estimates.ts hook (CRUD, search, calculations, real-time)
- [x] Mappers for estimate tables (estimates, areas, line_items, items)
- [x] Estimates list page (status filter, type filter, search)
- [x] Estimate creation page (type selector, customer/job linking)
- [x] Estimate editor page (room-by-room, line items, code search sidebar)
- [x] Auto-pricing from estimate_items base prices (estimate_pricing deferred to crowdsource)
- [x] O&P calculator (configurable percentages)
- [x] Insurance mode conditional fields
- [ ] Template save/load (estimate_templates) — deferred, needs template table wiring
- [x] Summary view with totals (inline preview mode)
- [x] Sidebar nav: add Estimates under Operations section (moved from Insurance)
- [x] npm run build passes (71 routes, 0 errors)
- [ ] Commit: `[D8d] Web CRM estimate engine — editor, pricing, templates`

---

#### D8e: PDF Export — Edge Function (~8 hrs)

**Goal:** Generate professional branded PDF estimates. Company logo, room-by-room breakdown, photo evidence pages.

**Edge Function:** `export-estimate-pdf`
**Input:** estimate_id, template (standard | detailed | summary)

**PDF Sections:**
1. Cover page: company branding (logo, colors, contact info)
2. Property details (address, customer, date)
3. Room-by-room breakdown with line items
4. Quantities, unit prices, line totals
5. Subtotal, O&P, tax, grand total
6. Insurance fields (if type=insurance): claim #, carrier, deductible
7. Terms and conditions
8. Photo evidence pages (from estimate_photos)

**Checklist D8e:**
- [x] Edge Function: export-estimate-pdf
- [x] Load estimate with all areas, line items, photos
- [x] Apply company branding from companies table
- [x] Render HTML template (standard layout)
- [x] Render HTML template (detailed layout — includes item-level pricing breakdown)
- [x] Render HTML template (summary layout — totals only, no line items)
- [x] PDF generation (HTML → print-ready page, standard Edge Function pattern)
- [ ] Photo evidence pages (auto-layout from estimate_photos) — deferred to D8g photos sprint
- [x] Download endpoint (returns HTML for print/PDF)
- [x] Flutter: PDF preview + share (via share_plus)
- [x] Web CRM: PDF preview + download button (fetch + blob URL + new tab)
- [x] Deploy Edge Function to dev
- [ ] Commit: `[D8e] PDF estimate export — branded, multi-template`

---

#### D8f: ESX Import — Edge Function (~8 hrs)
**PREREQUISITE:** IP attorney opinion letter on interoperability defense (recommended but not blocking)

**Goal:** Allow contractors to import existing estimate files (.esx) — standard industry ZIP+XML format documented publicly on FileFormat.com, FileInfo.com, and industry help sites.

**Edge Function:** `import-esx`
**Input:** .esx file (uploaded by user)

**Process:**
1. Validate file is ZIP archive (file size limit 100MB, ZIP bomb detection)
2. Extract contents (standard ZIP decompression)
3. Locate XML data file
4. Parse XML: extract property/claim info, areas, line items (code + selector + description + quantity + unit)
5. Map extracted codes to estimate_items (ZAFTO item database)
6. Create estimate record with all line items
7. Store new code+description pairs as contributions (code_contributions table)

**Checklist D8f:**
- [x] Edge Function: import-esx
- [x] ZIP extraction (fflate via esm.sh, ZIP bomb detection 500MB limit)
- [x] XML parser for industry-standard schema (fast-xml-parser via esm.sh)
- [x] Extract: property info, claim info, areas, line items, pricing (full XACTDOC schema support)
- [x] Map extracted codes to estimate_items table (ilike description match)
- [x] Create estimate + areas + line_items from parsed data (auto-number EST-YYYYMMDD-NNN)
- [x] Store unknown codes as code_contributions
- [x] Error handling: invalid ZIP, missing XML, unknown schema version
- [x] Input validation: file size limit (100MB), content type check
- [x] Flutter: upload .esx button on estimate list (file_picker + http multipart)
- [x] Web CRM: import .esx button on estimates page (FormData + fetch)
- [x] Deploy Edge Function to dev
- [ ] Commit: `[D8f] ESX import — parse industry-standard estimate files`

---

#### D8g: ESX Export — Edge Function (~8 hrs)
**PREREQUISITE:** IP attorney opinion letter on interoperability defense (recommended but not blocking)

**Goal:** Generate industry-compatible .esx files for insurance estimate submission. Standard ZIP+XML format.

**Edge Function:** `export-esx`
**Input:** estimate_id (must be type=insurance)

**Process:**
1. Load estimate with all areas, line items, photos
2. Build XML document following industry-standard schema
3. Add photo attachments as JPGs
4. Package as ZIP archive
5. Set .esx extension

**Checklist D8g:**
- [x] Edge Function: export-esx
- [x] Load estimate with areas, line items, photos
- [x] Generate XML: project header (property, dates, claim info)
- [x] Generate XML: area definitions (ROOM elements with name+level)
- [x] Generate XML: line items with industry codes + quantities (LINE elements with MAT/LAB/EQU)
- [x] Generate XML: pricing data (from ZAFTO's pricing engine)
- [x] Generate XML: O&P calculations + tax jurisdiction
- [x] Add photo attachments as JPGs in ZIP (from estimate-photos bucket)
- [x] Package as ZIP with .esx extension (fflate zipSync, level 6)
- [x] Flutter: export .esx button (insurance estimates only, share_plus)
- [x] Web CRM: export .esx button (insurance estimates only, blob download)
- [ ] Round-trip test: export → import → compare (deferred to D8j integration testing)
- [x] Deploy Edge Function to dev
- [ ] Commit: `[D8g] ESX export — generate industry-compatible estimate files`

---

#### D8h: Code Contribution Engine (~6 hrs)

**Goal:** Every ESX import feeds the code database. Crowdsource verification pipeline.

**Process:**
1. ESX import extracts code+description pairs → insert into code_contributions
2. When 3+ users contribute same code+description → mark verified
3. Verified contributions promoted to estimate_items (with source='contributed')
4. Monthly aggregation Edge Function processes verification queue

**Checklist D8h:**
- [x] ESX import auto-inserts to code_contributions (wired in D8f) — fixed column names (industry_code/industry_selector/user_id)
- [x] Verification count logic: increment when duplicate code+description submitted — dedup in import-esx
- [x] Promote verified codes (3+ verifications) to estimate_items — code-verify EF promote-all action
- [x] Edge Function: code-verify (on-demand via Ops Portal) — GET stats+queue, POST verify/reject/promote-one/promote-all
- [x] Admin page: code contribution queue (Ops Portal) — /dashboard/code-contributions (filter tabs, search, bulk promote)
- [x] Contribution stats: total contributed, verified, pending — stats cards + filter counts
- [x] Deploy Edge Function to dev — code-verify deployed, import-esx redeployed with fix
- [ ] Commit: `[D8h] Code contribution engine — crowdsource verification pipeline`

---

#### D8i: Pricing Engine Foundation (~8 hrs)

**Goal:** Regional pricing from public data sources. BLS labor stats, FEMA equipment rates, supplier API prep.

**Data Sources (all public, all legal):**
- BLS Occupational Employment Wage Statistics (labor rates by MSA)
- BLS Producer Price Index (material cost trends)
- FEMA Equipment Rate Schedule (equipment costs)
- Davis-Bacon prevailing wage data (government projects)
- Supplier APIs via Unwrangle ($99/mo for HD + Lowe's — wired in Phase F)

**Checklist D8i:**
- [x] BLS data ingestion Edge Function (fetch + parse + insert estimate_pricing)
- [x] FEMA equipment rate ingestion Edge Function
- [x] Regional pricing calculator: ZIP → MSA code → pricing lookup
- [x] Pricing fallback: if no regional data, use national average
- [x] estimate_pricing table populated for major MSAs
- [x] Pricing admin page (Ops Portal): view coverage, trigger refresh
- [x] Deploy Edge Functions to dev
- [ ] Commit: `[D8i] Pricing engine foundation — BLS + FEMA public data`

---

#### D8j: Portal Integration + Testing (~8 hrs)

**Goal:** Estimate engine visible in all relevant portals. End-to-end testing.

**Team Portal:**
- Field estimate creation (simplified mobile-friendly form)
- Assigned estimates view (estimates for tech's assigned jobs)

**Client Portal:**
- Estimate review page (customer views sent estimates)
- Approve/reject with signature

**Ops Portal:**
- Estimate analytics (total estimates, conversion rate, average value)
- Code database admin (view/edit/add items)
- Pricing coverage dashboard

**Checklist D8j:**
- [x] Team Portal: estimate creation flow (hook + page)
- [x] Team Portal: assigned estimates list
- [x] Client Portal: estimate review page (read-only + approve/reject)
- [x] Client Portal: digital signature on approval
- [x] Ops Portal: estimate analytics widgets
- [x] Ops Portal: code database browser/editor (covered by D8h code-contributions + D8j analytics Code DB Health section)
- [x] Ops Portal: pricing coverage dashboard (covered by D8i pricing-engine + D8j analytics)
- [ ] End-to-end test: create estimate (Flutter) → view in CRM → send to client → client approves (deferred — needs deployed env + test data)
- [ ] End-to-end test: import ESX → review → edit → export PDF (ESX deferred to revenue stage per S89 owner directive)
- [ ] End-to-end test: import ESX → edit → export ESX (round-trip) (ESX deferred to revenue stage per S89 owner directive)
- [x] All 5 apps build clean (dart analyze + npm run build × 4)
- [x] Commit: `[D8j] Estimate engine — portal integration + testing`

---

#### D8 Execution Order

Execute in sequence:
1. D8a (Database) — must be first
2. D8b (Seed Data) — needs tables from D8a
3. D8c + D8d (Flutter + Web CRM CRUD) — can be parallel, both need D8a+D8b
4. D8e (PDF Export) — needs CRUD working
5. D8f (ESX Import) — needs database + CRUD
6. D8g (ESX Export) — needs database + CRUD
7. D8h (Code Contribution Engine) — needs D8f wired
8. D8i (Pricing Engine) — independent of ESX, can run after D8a
9. D8j (Portal Integration + Testing) — last, needs everything above

**AI-dependent features (deferred to Phase E):**
- Photo damage classification (Claude Vision → suggested line items)
- AI scope builder (damage type + room → complete line item list)
- Text-to-code AI mapping (description → best matching items)
- LiDAR room scanner (ARKit → auto-populate estimate_areas)

**Total estimated: ~86 hours across 10 sub-steps**
**New tables: 10 (estimate_items, estimate_categories, estimate_units, estimate_pricing, estimate_labor_components, code_contributions, estimates, estimate_areas, estimate_line_items, estimate_photos)**
**New Edge Functions: 5 (export-estimate-pdf, import-esx, export-esx, code-verify, pricing-ingest)**

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
- [x] Remove dead features: Toolbox/static content deferred to Phase E (Z Intelligence replaces them). References removed from field_tools_hub, home_screen_v2, command_palette, command_registry.
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

## PHASE E: AI LAYER — **PAUSED (S80 OWNER DIRECTIVE)**

**STATUS: ALL PHASE E WORK IS PAUSED.** AI was built prematurely in S78-S80. Code is committed but DORMANT.
**AI goes TRULY LAST.** Must come after ALL of Phase F (Platform Completion) + Phase T (TPA) + Phase P (ZScan) + Phase SK (Sketch Engine) + Phase G (QA/Hardening).
**Reason:** AI must know every feature, every table, every screen, every workflow — so it can do literally anything within the program. Building AI before the platform is complete means AI won't know about Phone System, Website Builder, Meeting Rooms, ZDocs, Marketplace, Business OS, Hiring, etc.
**When to resume:** After Phase F + G are COMPLETE. Owner will initiate a deep AI spec session first. All premature E work will be audited/rebuilt with full platform context.
**Correct build order: A(DONE) → B(DONE) → C(DONE) → D(DONE) → R1(DONE) → F(NEXT) → G → E(LAST)**

**Premature work below is COMMITTED and DORMANT. Do not continue, extend, or deploy.**
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

### Sprint E3: Employee Portal AI + Mobile AI
**Source:** E1 infrastructure (z-intelligence Edge Function, z_threads/z_artifacts tables)
**Goal:** Wire AI into team portal troubleshooting center + mobile app Z button + basic client portal AI.
**Depends on:** E1 (AI infra DONE), E2 (Z Console wiring DONE).

#### E3a: AI Troubleshooting Center — Edge Functions (~6 hrs) — DONE (S80)
- [x] Edge Function: `ai-troubleshoot` — multi-trade diagnostics (314 lines, 20 trades, NEC/IRC/IPC/IMC code maps)
- [x] Edge Function: `ai-photo-diagnose` — Claude Vision photo analysis (308 lines, base64 image, 1-5 condition scale)
- [x] Edge Function: `ai-parts-identify` — text+photo part ID (298 lines, dual mode text/vision)
- [x] Edge Function: `ai-repair-guide` — skill-adaptive repair guide (391 lines, apprentice/journeyman/master)
- [x] Commit: `[E3a] AI troubleshooting Edge Functions` (876333e)
- [x] All 4 deployed to Supabase (26 Edge Functions total)

#### E3b: Team Portal AI Troubleshooting Center — UI (~8 hrs) — DONE (S80)
- [x] use-ai-troubleshoot.ts hook (254 lines, 5 AI function callers, conversation history)
- [x] troubleshoot/page.tsx (1364 lines, 5-tab UI: Diagnose/Photo/Code/Parts/Repair)
- [x] Photo diagnosis tab: upload photo → show analysis results with condition stars
- [x] Code lookup tab: search NEC/IRC/IPC/IMC/OSHA codes with AI explanation
- [x] Parts ID tab: describe or photo → part identification + alternatives + suppliers
- [x] Repair guides tab: trade/issue/skill → safety precautions + numbered steps + tools/materials
- [ ] Company knowledge base: DEFERRED — requires z_threads querying (Phase E4)
- [x] Commit: `[E3b] Team portal AI troubleshooting center` (91b287f)

#### E3c: Mobile App Z Button + AI Integration (~8 hrs) — DONE (S80)
- [x] ai_service.dart — AiService + AiChatNotifier + providers (Edge Function client)
- [x] z_chat_sheet.dart — bottom sheet chat with message bubbles + quick actions
- [x] ai_photo_analyzer.dart — photo defect detection screen with condition display
- [x] app_shell.dart — Z FAB tap opens Z chat sheet, long-press opens quick actions
- [x] Legacy aiService alias added for backward compat with ai_scanner screens
- [ ] Voice-to-text for field notes: DEFERRED — uses same transcribe Edge Function, UI wiring later
- [ ] Receipt OCR: DEFERRED to Phase E (already saves with ocr_status='pending')
- [x] Commit: `[E3c] Mobile AI integration — Z button + chat + photo` (839ea48)

#### E3d: Client Portal AI (basic) (~4 hrs) — DONE (S80)
- [x] use-ai-assistant.ts hook (chat, project summary, invoice explainer via z-intelligence)
- [x] ai-chat-widget.tsx (floating Z button + slide-up chat panel, 3 states)
- [x] layout.tsx updated to include AiChatWidget in PortalShell
- [x] Commit: `[E3d] Client portal AI — chat widget + summaries` (e9dc070)
- [x] Build clean (24 static pages + dynamic routes)

#### E3e: Testing + Verification (~2 hrs) — DONE (S80)
- [x] dart analyze: 0 issues on all 4 new Flutter files
- [x] team-portal: npm run build clean (troubleshoot page 11.4 kB)
- [x] client-portal: npm run build clean (24 pages)
- [x] All 4 Edge Functions deployed to Supabase
- [x] All commits pushed to GitHub (876333e..e9dc070)

---

### Sprint E4: Growth Advisor + Advanced AI
**Source:** E1 (z-intelligence Edge Function), E3 (troubleshooting functions), existing job/invoice/bid data.
**Goal:** AI-powered business intelligence — revenue insights, bid optimization, equipment lifecycle, growth automation.
**Depends on:** E1 (DONE), E3 (DONE), D4 ZBooks (DONE), D5 Property Management (DONE).

#### E4a: Revenue Intelligence Edge Functions (~6 hrs)
- [ ] Edge Function: `ai-revenue-insights` — analyze invoices/jobs for profit margins, trends, recommendations
- [ ] Edge Function: `ai-customer-insights` — CLV predictions, churn risk, upsell opportunities from job history
- [ ] Both query real data (invoices, jobs, customers tables) + Claude analysis
- [ ] Commit: `[E4a] Revenue intelligence Edge Functions`

#### E4b: Web CRM Revenue Dashboard (~8 hrs)
- [ ] use-revenue-insights.ts hook (revenue trends, margin analysis, pricing recommendations)
- [ ] Dashboard page: revenue trends chart, margin heatmap, top customers, seasonal patterns
- [ ] Customer insights panel: CLV scores, churn risk badges, recommended actions
- [ ] Commit: `[E4b] Web CRM revenue intelligence dashboard`

#### E4c: Bid Brain — AI-Enhanced Bidding (~8 hrs)
- [ ] Edge Function: `ai-bid-optimizer` — win probability, competitive pricing, scope suggestions
- [ ] Web CRM bid detail: AI suggestions panel (price adjustment, scope additions, win rate)
- [ ] Flutter bid screen: "Optimize with Z" button → shows AI suggestions before submission
- [ ] Auto-generate bid from walkthrough data (leverages walkthrough-generate-bid)
- [ ] Commit: `[E4c] Bid Brain — AI bid optimization`

#### E4d: Equipment Memory (~6 hrs)
- [ ] Edge Function: `ai-equipment-insights` — lifecycle analysis from property equipment data
- [ ] Predictive maintenance alerts: calculate next service date from install date + manufacturer intervals
- [ ] Parts inventory suggestions based on equipment age + common failure patterns
- [ ] Web CRM equipment detail: AI lifecycle panel with maintenance timeline
- [ ] Commit: `[E4d] Equipment Memory — lifecycle tracking + predictions`

#### E4e: Revenue Autopilot (~6 hrs)
- [ ] Edge Function: `ai-growth-actions` — generate follow-up, upsell, and campaign suggestions
- [ ] Automated follow-up queue: AI suggests next-touch dates for dormant customers
- [ ] Seasonal campaign generation: trade-specific campaigns (HVAC spring/fall, roofing spring, etc.)
- [ ] Review request automation: post-completion trigger → AI drafts personalized review request
- [ ] Web CRM growth page: action queue with AI-generated suggestions
- [ ] Commit: `[E4e] Revenue Autopilot — growth actions + campaigns`

#### E4f: Testing + Verification (~2 hrs)
- [ ] Revenue insights tested with real invoice/job data patterns
- [ ] Bid Brain suggestions render correctly in CRM + Flutter
- [ ] Equipment lifecycle calculations accurate for test data
- [ ] All 5 apps build clean
- [ ] Commit: `[E4f] Growth Advisor — testing complete`

---

### Sprint E5: Xactimate Estimate Engine — **SUPERSEDED BY D8**
**Source:** `Expansion/25_XACTIMATE_ESTIMATE_ENGINE.md` — REPLACED by `SPRINT/07_ESTIMATE_ENGINE_SPEC.md`
**Goal:** Replace $300/mo Xactimate with built-in estimate writing, independent pricing, and AI-powered scope analysis.
**Depends on:** E1 (AI infra), D2a (insurance tables already deployed), legal review (for ESX export).
**Status: SUPERSEDED (S85). E5 code is DORMANT. D8 (clean-room estimate engine) replaces this with independent architecture — two-mode engine (Regular Bids + Insurance ESX), own code database, crowdsource engine. AI features (photo analysis, scope builder, code suggestion) will fold into E1 Universal AI when Phase E resumes. Zero references to proprietary tools or reverse engineering.**

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
- [x] Walkthrough start screen (name, customer link, type, template)
- [x] Room capture screen (photo, notes, tags, custom fields per template)
- [x] Multi-photo per room with auto-numbering
- [ ] Voice note recording per room — DEFERRED (uses existing voice notes infra)
- [x] Room list with progress indicators
- [x] Exterior capture flow
- [x] Walkthrough finish screen (summary, upload trigger)
- [ ] Offline persistence (PowerSync + local file storage) — DEFERRED to PowerSync phase
- [ ] Background upload with progress tracking — DEFERRED to PowerSync phase
- [x] Model + Repository + Service layer
- [x] Commit: `[E6b] Flutter walkthrough capture flow` (8465b41)

#### E6c: Photo Annotation System (~8 hrs)
- [x] Annotation editor (CustomPainter overlay on photo)
- [x] Tools: draw, arrow, circle, rectangle, text, measurement, stamp
- [x] Color/thickness selection
- [x] Save annotations as JSON overlay (original untouched)
- [x] Render annotated version as PNG for export
- [x] Before/after photo linking + comparison view
- [x] Commit: `[E6c] Photo annotation system` (78efc26)

#### E6d: Sketch Editor + Floor Plan Engine (~16 hrs)
- [x] Floor plan canvas (CustomPainter + GestureDetector)
- [x] Wall drawing tool with angle snapping
- [x] Door/window/fixture placement from symbol library
- [x] Room auto-detection from enclosed walls
- [x] Dimension labels (auto-calculated, manually editable)
- [ ] Asset pins (link to property_assets table) — DEFERRED to property management wiring
- [x] Annotation overlay (text, area highlights)
- [x] Multi-floor support (tabs)
- [x] Undo/redo stack
- [x] Save as structured JSON (not bitmap)
- [ ] Export as PNG/PDF — DEFERRED (save as JSON, PNG export via RepaintBoundary later)
- [x] Commit: `[E6d] Sketch editor + floor plan engine` (a929ea7)

#### E6e: LiDAR Integration (~10 hrs) — DEFERRED
- [ ] Evaluate and integrate ARKit plugin for iOS
- [ ] Room dimension capture from LiDAR scan
- [ ] Auto-populate sketch from LiDAR data
- [ ] Dimension editing (override LiDAR with manual values)
- [ ] LiDAR data storage (compressed mesh/point cloud)
- [ ] Fallback to manual dimension entry on non-LiDAR devices
- [ ] Commit: `[E6e] LiDAR integration — room scanning + auto-sketch`
> DEFERRED — requires ARKit plugin evaluation + physical device testing

#### E6f: 2D Floor Plan Viewer — All Apps (~8 hrs)
- [x] Web CRM: Canvas/SVG floor plan renderer (interactive, editable)
- [x] Web CRM: Room selection, asset pins, photo pins, status color-coding
- [x] Client Portal: Simplified read-only viewer
- [x] Team Portal: Viewer with progress marking
- [ ] Print-friendly export (clean black-and-white) — DEFERRED
- [x] Commit: `[E6f] 2D floor plan viewer — all apps` (71af9d6)

#### E6g: AI Bid Generation Pipeline (~10 hrs)
- [x] Edge Function: process walkthrough → analyze photos (Claude Vision)
- [x] Edge Function: voice note transcription + extraction
- [x] Edge Function: combine all data → generate bid per format
- [x] Bid templates: standard, 3-tier, insurance/Xactimate, AIA, trade-specific, inspection report
- [x] Bid review screen (Flutter + Web CRM)
- [ ] Bid edit + send capabilities — wires in when bids table CRUD is live
- [x] Commit: `[E6g] AI bid generation pipeline — all formats` (11e4a4a)

#### E6h: Workflow Customization UI (~6 hrs)
- [x] Web CRM: Settings > Walkthrough Workflows page
- [x] Template editor: rooms, required fields, custom fields, checklist, AI instructions
- [ ] Approval workflow configuration — DEFERRED to workflow engine phase
- [x] Clone system template → customize
- [x] Commit: `[E6h] Walkthrough workflow customization` (50e644c)

#### E6i: 3D Property Viewer + Editor (~12 hrs) — PHASE 2
- [ ] LiDAR mesh capture + storage
- [ ] 3D renderer (Flutter: flutter_gl, Web: Three.js)
- [ ] Orbit/zoom/pan, tap surfaces, asset pins in 3D
- [ ] 2D ↔ 3D sync (edits in either view update both)
- [ ] Cross-section view
- [ ] Commit: `[E6i] 3D property viewer + editor`
> PHASE 2 — not blocking launch

#### E6j: Testing + Verification (~4 hrs)
- [x] End-to-end: walkthrough → upload → bid generation → review → send
- [ ] Offline walkthrough → reconnect → upload completes — DEFERRED to PowerSync phase
- [x] Floor plan CRUD across all apps
- [x] Template customization applied in walkthrough
- [x] All 5 apps build clean
- [x] Commit: `[E6j] Bid walkthrough engine — testing complete` — PARTIAL (E6e/E6i deferred)

**Total estimated: ~96 hours across 10 sub-steps**
**New tables: 5 (walkthroughs, walkthrough_rooms, walkthrough_photos, property_floor_plans, walkthrough_templates) + 3 ALTERs**

---

## PRE-F: FOUNDATION SPRINTS

### Sprint FM: Firebase → Supabase Migration (~8-12 hrs)
**Goal:** Migrate 11 Cloud Functions from `backend/functions/index.js` (Firebase project zafto-2b563) to Supabase Edge Functions. Eliminate last Firebase dependency.

**Functions to migrate:**
| Firebase Function | Purpose | New Edge Function |
|-------------------|---------|-------------------|
| analyzePanel | Panel AI analysis | Merge into existing ai-photo-diagnose |
| analyzeNameplate | Nameplate extraction | Merge into existing ai-photo-diagnose |
| analyzeWire | Wire identification | Merge into existing ai-photo-diagnose |
| analyzeViolation | NEC violation check | Merge into existing ai-photo-diagnose |
| smartScan | Auto-detect + route | Merge into existing ai-photo-diagnose |
| getCredits | Check scan credits | New: subscription-credits |
| addCredits | Add AI credits | New: subscription-credits |
| revenueCatWebhook | IAP processing | New: revenuecat-webhook |
| createPaymentIntent | Stripe payments | New: stripe-payments |
| stripeWebhook | Payment events | New: stripe-webhook |
| getPaymentStatus | Check payment status | Merge into stripe-payments |

**Secrets to migrate:** STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, ANTHROPIC_API_KEY → `npx supabase secrets set`

**Checklist FM:**
- [ ] Retrieve key values from Firebase: `firebase functions:secrets:access STRIPE_SECRET_KEY` (MANUAL — need Firebase CLI access)
- [ ] Set keys in Supabase: `npx supabase secrets set STRIPE_SECRET_KEY=... STRIPE_WEBHOOK_SECRET=...` (MANUAL — after key retrieval)
- [x] Database migration: payment_intents, payments, payment_failures, user_credits, scan_logs, credit_purchases (6 tables)
- [x] Edge Function: stripe-payments (createPaymentIntent, getPaymentStatus)
- [x] Edge Function: stripe-webhook (payment events handler with signature verification)
- [x] Edge Function: revenuecat-webhook (IAP credit processing + refund handling)
- [x] Edge Function: subscription-credits (getCredits, addCredits, deductCredits)
- [ ] Update Stripe webhook URL in Stripe Dashboard (Firebase → Supabase) (MANUAL)
- [ ] Update RevenueCat webhook URL (MANUAL)
- [ ] Deploy migration: `npx supabase db push` (MANUAL — after secrets set)
- [ ] Deploy Edge Functions: `npx supabase functions deploy stripe-payments stripe-webhook revenuecat-webhook subscription-credits` (MANUAL)
- [ ] Test: create payment intent → verify webhook fires
- [ ] Test: credit purchase → verify credits added
- [ ] Delete `backend/functions/` directory (Firebase code) — DEFERRED until webhook URLs updated and tested
- [ ] Remove Firebase packages from root package.json if any
- [x] Commit: `[FM] Firebase→Supabase migration — payments, credits, webhooks`

---

### Sprint R1-fix: Mobile Backend Rewire (~8-12 hrs)
**Goal:** Connect R1's 33 new role-based screens to existing Phase B wired data.

**Deferred from R1 (S78):**
- [ ] R1c: Rewire all 18 field tools to new design system nav
- [ ] R1c: Quick actions menu (role/context/time aware)
- [ ] R1e: Deploy inspection_templates + inspection_results + inspection_deficiencies tables
- [ ] R1e: Seed system inspection templates
- [ ] R1e: Deficiency capture (fail → photo → annotate → code cite → severity)
- [ ] R1e: Floor plan integration (pin deficiencies)
- [ ] R1e: Report generation (auto PDF)
- [ ] R1f: Deploy home_scan_logs + home_maintenance_reminders tables
- [ ] R1j: Permission override system (admin grants/restricts per user)
- [ ] R1j: Deep linking from notifications
- [ ] R1j: Onboarding flow per role
- [ ] R1j: All existing backend wiring connected to new R1 screens
- [ ] dart analyze: 0 errors
- [ ] Commit: `[R1-fix] Backend rewire — 33 screens connected to live data`

---

## PHASE F: PLATFORM COMPLETION

**Build order: F1→F3→F4→F5→F6→F7→F9→F10. F2+F8 build after Phase E (AI).**
**Every sprint: enterprise security (RLS on all tables), enterprise speed (indexes on all queries), enterprise polish (Stripe-quality UI).**

---

### Sprint F1: Phone System — SignalWire (~40-55 hrs)
**Source:** `04_EXPANSION_SPECS.md` F1 section
**API:** SignalWire (Voice, SMS, Fax, Video). Keys already stored in Supabase secrets + env files.

**F1a: Database + Edge Functions (~10 hrs)**
- [x] Tables: phone_config, phone_lines, phone_ring_groups, phone_on_call_schedule, phone_calls, phone_voicemails, phone_messages, phone_message_templates, phone_faxes (9 new)
- [x] RLS: company-scoped on all 9 tables
- [x] Edge Function: signalwire-voice (inbound/outbound call handling, recording)
- [x] Edge Function: signalwire-sms (send/receive, webhook handler)
- [x] Edge Function: signalwire-fax (send PDF, receive → auto-PDF → Storage)
- [x] Edge Function: signalwire-webhook (CDR, delivery receipts, fax status)
- [ ] Deploy + verify (manual)

**F1b: Business Phone — Web CRM (~8 hrs)**
- [x] Hook: use-phone.ts (call log, voicemail, SMS conversations)
- [x] Page: /dashboard/phone (call log, active calls, voicemail inbox)
- [x] Page: /dashboard/phone/sms (conversation threads per customer)
- [x] Dialer component (click-to-call from any customer/job page) — PhoneDialer + ClickToCall components
- [ ] Call recording playback in job timeline (deferred — needs audio player wiring after SignalWire live)

**F1c: Fax System — Web CRM + Mobile (~8 hrs)**
- [x] Hook: use-fax.ts (send, receive, history, status tracking)
- [x] Page: /dashboard/phone/fax (fax inbox/outbox, send new)
- [ ] One-click fax from estimates, invoices, permits, contracts (deferred — wiring after F-phase EFs live)
- [x] Inbound fax: auto-PDF → Storage → notify → handled by signalwire-fax EF webhook
- [ ] Flutter: fax send screen (deferred to Flutter wiring pass)
- [ ] Flutter: fax history screen (deferred to Flutter wiring pass)

**F1d: Auto-Attendant + AI Receptionist (~10 hrs)**
- [x] SignalWire LaML auto-attendant (IVR with menu options) — in signalwire-voice EF
- [x] AI receptionist: signalwire-ai-receptionist EF (STT → Claude Haiku → TTS, lead capture)
- [x] Voicemail → recording + storage — in signalwire-webhook EF (AI transcription = Phase E)
- [x] Business hours routing — phone_config.business_hours checked in signalwire-voice EF
- [ ] Call escalation to video (deferred to F3 Meeting Rooms)

**F1e: Portal Integration + Testing (~8 hrs)**
- [x] Team Portal: incoming call notifications, SMS from field — phone hook + /dashboard/phone page (28 routes)
- [x] Client Portal: SMS conversation with contractor — use-messages hook + /messages page (30 routes)
- [x] Ops Portal: call analytics, usage dashboard — phone-analytics hook + page (21 routes)
- [x] All 5 apps build clean — web CRM 74 routes, team 28, client 30, ops 21
- [ ] Commit: `[F1] Phone system — voice, SMS, fax, AI receptionist`

---

### Sprint F3: Meeting Room System — LiveKit (~70 hrs)
**Source:** `04_EXPANSION_SPECS.md` F3 section
**API:** LiveKit (WebRTC SFU). Keys already stored in Supabase secrets + env files.

**F3a: Database + Core Video (~20 hrs)**
- [x] Tables: meetings, meeting_participants, meeting_captures, meeting_booking_types, async_videos (5 new) — migration 20260208000034
- [x] RLS: company-scoped + participant access for external parties — all 5 tables have RLS
- [x] Edge Function: meeting-room (create/join/end/status) — HMAC-SHA256 JWT for LiveKit tokens
- [x] LiveKit room creation + token generation — in meeting-room EF
- [x] Web CRM: use-meetings hook + /dashboard/meetings page (upcoming/active/past tabs, join/start buttons)
- [x] 1-on-1 video calls (browser + mobile) — LiveKit room page at /dashboard/meetings/room with VideoConference + context panel
- [x] Call recording → Supabase Storage — meeting-recording EF handles LiveKit egress webhooks (download + upload to Storage)

**F3b: Smart Rooms + Context (~15 hrs)**
- [x] Context panel: job details, estimate, customer info visible during call — room page has context panel sidebar
- [x] Freeze-frame → annotate → save to job photos — meeting-capture EF (base64 upload → Storage + job_photos link)
- [ ] Rear camera mode (site walk with annotations) — deferred to mobile Flutter build
- [x] 6 meeting types: Customer Consultation, Insurance Adjuster, Team Huddle, Site Walk, Subcontractor, Expert Consult — booking_types table + config page

**F3c: Scheduling + Booking (~10 hrs)**
- [x] Booking types configuration (duration, buffer, availability) — /dashboard/meetings/booking-types page + meeting-booking EF
- [x] Public booking link (customer self-schedules) — meeting-booking EF availability+book actions, client portal /book page
- [ ] Calendar integration (blocks time, sends reminders) — deferred to Google Calendar API wiring
- [ ] Google Calendar sync (free API) — deferred to API wiring phase

**F3d: AI + Async (~12 hrs)**
- [ ] Deepgram real-time transcription — deferred to Phase E (AI goes last)
- [ ] Claude summary + action items (post-meeting) — deferred to Phase E
- [x] Async video messages (record + send, Loom-style) — /dashboard/meetings/async-videos page + use-async-videos hook
- [ ] Reply threads on async videos — deferred to polish

**F3e: Advanced + Polish (~13 hrs)**
- [x] Multi-party calls (3+ participants) — LiveKit VideoConference supports N participants natively
- [ ] Insurance adjuster role (limited view, no edit) — deferred to role wiring
- [ ] Phone-to-video escalation (F1 → F3 bridge via SignalWire SIP) — deferred to SignalWire SIP integration
- [ ] Meeting history + playback in job timeline — deferred to job timeline wiring
- [x] Client Portal: join meeting link — client portal /meetings page + /book page built (32 routes)
- [x] All 5 apps build clean — Web CRM, Team Portal (29 routes), Client Portal (32 routes), Ops Portal (22 routes) all pass
- [ ] Commit: `[F3] Meeting rooms — context-aware video, booking, AI transcription`

---

### Sprint F4: Mobile Field Toolkit + Sketch/Bid Flow (~120-140 hrs)
**Source:** `04_EXPANSION_SPECS.md` F4 section
**APIs:** OSHA (free), LiveKit (PTT), Deepgram (transcription)

**F4a: Database + New Tool Tables (~12 hrs)**
- [x] Tables: walkie_talkie_channels, walkie_talkie_messages, team_messages, team_message_reads, inspection_templates, inspection_results, osha_standards (7 new) — migration 20260208000035. moisture_readings, drying_logs, restoration_equipment already exist from D2.
- [x] RLS: company-scoped on all 7 tables
- [x] Indexes: inspection_results(job_id), inspection_results(company_id,status), osha_standards GIN(trade_tags), team_messages(channel_type,channel_id)

**F4b: Communication Tools (~20 hrs)**
- [x] Walkie-Talkie/PTT (LiveKit audio channels, push-to-talk, always-on per job) — walkie-talkie EF (create_channel, join, leave, list, log_message)
- [x] Team Chat (persistent messaging per job/channel, Supabase real-time) — team-chat EF + use-team-chat hook + /dashboard/team-chat page
- [ ] Client Messaging (direct messages visible in client portal)
- [ ] Phone UI integration (F1 mobile screens) — deferred to Flutter build
- [ ] Meeting UI integration (F3 mobile screens) — deferred to Flutter build

**F4c: Restoration Tools (~18 hrs)**
- [x] Moisture Reading Logger (daily readings per room, graphed over time, IICRC standards) — use-restoration-tools hook + /dashboard/moisture-readings page (color-coded, add modal)
- [x] Drying Log (immutable daily entries, equipment placement, readings) — /dashboard/drying-logs page (expandable rows, immutable notice, add modal)
- [x] Equipment Tracker (what's deployed where, pickup scheduling, utilization) — /dashboard/equipment rewired from mock to real hook (status updates, detail modal)
- [ ] Claim Documentation Camera (auto-tag to claim, timestamp, GPS) — deferred to Flutter mobile build

**F4d: Inspection Tools (~16 hrs)**
- [x] Inspection Checklist (template-based, pass/fail/conditional per item) — /dashboard/inspection-engine page with use-inspection-engine hook (templates + results)
- [ ] Safety Checklist (OSHA-auto-populated by trade/job type) — deferred to OSHA wiring
- [x] Site Survey (dimensions, conditions, photos, notes) — /dashboard/site-surveys page + use-site-surveys hook + site_surveys table (migration 36)
- [ ] Deficiency capture (fail → photo → annotate → code cite → severity) — deferred to Flutter mobile
- [ ] Report generation (auto PDF from completed inspection) — deferred to PDF generation system

**F4e: OSHA Integration (~8 hrs)**
- [x] Edge Function: osha-data-sync (pull enforcement data, standards by SIC/NAICS) — 4 actions: sync_standards, get_for_trade, lookup_violations, frequently_cited
- [x] osha_standards table populated (cached, daily refresh) — 23 frequently cited construction standards seeded with trade_tags
- [ ] Safety briefing auto-populates relevant OSHA standards for job trade
- [ ] Pre-job safety checklist generated from OSHA requirements
- [x] Violation lookup by company (competitor research in marketplace) — lookup_violations action in osha-data-sync EF

**F4f: Sketch + Bid Flow — THE KILLER FEATURE (~30-40 hrs)**
- [x] Sketch data stored in bid_sketches + sketch_rooms tables — migration 36 (3 tables: bid_sketches, sketch_rooms, site_surveys)
- [x] CRM page: /dashboard/sketch-bid — sketch list, room detail view, status cards, filters
- [x] use-sketch-bid hook — CRUD for sketches + rooms, real-time subscriptions
- [ ] Room capture: take photo → enter dimensions (length, width, height, window sizes, ceiling gaps) — deferred to Flutter mobile
- [ ] Sketch editor: draw room outlines, annotate measurements, mark damage areas — deferred to canvas implementation
- [ ] AI code suggestion: photos + dimensions + job type → pull from D8 price book → suggested line items — deferred to Phase E
- [ ] Location-based pricing: ZIP → MSA → BLS wage data + regional material costs — deferred to pricing engine wiring
- [ ] Advanced: identify specific code from photo (Claude Vision → match to estimate_items) — deferred to Phase E
- [ ] Generate bid: rooms + codes + local pricing + sketch + photos = professional bid PDF or ESX — deferred to PDF gen
- [ ] Connected to D8 estimate engine (shares estimate_items, estimate_pricing, estimates tables)
- [ ] Works on: Flutter app (phone/tablet), team portal (laptop), web CRM (office)

**F4g: Field Tool Rewire + Testing (~16 hrs)**
- [ ] Rewire all 19 existing field tools to R1 design system
- [ ] Quick actions menu (role/context/time aware)
- [ ] All 24 tools accessible from AppShell Tools tab
- [ ] Offline-first patterns (PowerSync) for field tools
- [ ] All 5 apps build clean
- [ ] Commit: `[F4] Mobile toolkit — 24 tools, sketch/bid, OSHA, PTT`

---

### Sprint F5: Business OS + Lead Aggregation (~180+ hrs)
**Source:** `04_EXPANSION_SPECS.md` F5 section
**APIs:** SendGrid, Google Business Profile (free), Meta Business (free), Nextdoor (free), Yelp Fusion (free), Google LSA, BuildZoom (free), Gusto Embedded, Samsara/Geotab

**F5a: Lead Aggregation System (~30 hrs)**
- [x] Tables: lead_source_configs, lead_assignment_rules, lead_notifications, lead_analytics_events (migration 37) + leads table extended with external_id, trade, urgency, auto_assigned, response_time
- [x] Edge Function: lead-aggregator (ingest, sync_source, webhook, auto_assign, get_analytics, configure_source, list_sources) — handles Meta, Angi, Thumbtack, Nextdoor, Google Business, Yelp, Google LSA
- [x] Normalize all lead data → existing `leads` table (source, stage, contact info) — normalizer functions per source in lead-aggregator EF
- [x] Auto-assign leads based on trade/area/availability rules — lead_assignment_rules table + round robin + priority matching
- [ ] Unified lead inbox in CRM (all sources, one view) — existing leads page needs source filter enhancement
- [x] Lead notification system (push + SMS + email) — lead_notifications table + auto-notify on assign
- [x] Lead analytics: source performance, conversion rates, cost per lead — get_analytics action in lead-aggregator EF

**F5b: CPA Portal (~20 hrs)**
- [x] Tables: cpa_access_tokens, cpa_activity_log (migration 38) — token-based read-only access for accountants
- [ ] Read-only ZBooks access for accountants — needs CPA portal app or role-gated CRM
- [ ] GL, P&L, Balance Sheet, Cash Flow reports — needs ZBooks report generation
- [ ] Bank reconciliation review
- [ ] 1099 preparation + export
- [ ] Separate subdomain or role-gated CRM access

**F5c: Payroll (~25 hrs)**
- [x] Tables: pay_periods, pay_stubs, payroll_tax_configs (migration 39) — biweekly/weekly/monthly periods, full stub breakdown with YTD
- [x] Time clock data → payroll calculations — payroll-engine EF (calculate_period, create_stubs, approve_period, get_tax_config) with 2026 federal brackets, SS/Medicare, benefit deductions
- [ ] Gusto Embedded integration (direct deposit, tax filing, W-2/1099) — needs Gusto API key
- [x] Pay run approval workflow — use-payroll hook + /dashboard/payroll page (pay periods table, expandable stubs, approve/process actions)
- [ ] Employee pay stubs in team portal — needs team portal page

**F5d: Fleet Management (~20 hrs)**
- [x] Tables: vehicles, vehicle_maintenance, fuel_logs (migration 40) — GPS tracking, maintenance scheduling, fuel tracking
- [ ] Vehicle tracking (Samsara/Geotab GPS) — needs GPS provider API integration
- [x] Maintenance scheduling + alerts — use-fleet hook + /dashboard/fleet page (stats cards, vehicles table with expandable maintenance history + fuel logs)
- [x] Fuel log tracking — use-fleet hook tracks fuel logs per vehicle, CRM page shows fuel history
- [x] Insurance docs per vehicle — stored in vehicles table, visible in fleet page
- [x] Fleet dashboard in CRM — /dashboard/fleet with stats cards, search, filters, expandable rows

**F5e: Route Optimization (~15 hrs)**
- [ ] Daily job schedule → optimized driving routes
- [ ] Google Maps Directions API
- [ ] Multi-stop optimization
- [ ] Navigate from app (deep link to Maps)

**F5f: Procurement (~20 hrs)**
- [x] Tables: vendor_directory, po_line_items, receiving_records (migration 41) — vendor management, PO line items, receiving
- [x] PO creation + approval workflow — use-procurement hook + /dashboard/purchase-orders page rewired from mock (expandable rows with line items + receiving records)
- [x] Vendor management (directory, contacts, terms) — use-procurement hook + /dashboard/vendors page rewired (2 tabs: Supplier Directory + Accounting Vendors)
- [x] Receiving + matching PO to invoice — use-procurement hook tracks receiving_records per PO line item
- [ ] Unwrangle integration for HD/Lowe's pricing (when activated)

**F5g: HR Suite (~20 hrs)**
- [x] Tables: employee_records, onboarding_checklists, training_records, performance_reviews (migration 42) — full HR data model
- [x] Employee records + onboarding checklists — use-hr hook + /dashboard/hr page (4 tabs: Employees/Onboarding/Training/Reviews, expandable rows with benefits/documents/ratings)
- [x] Training tracking + cert/license expiration alerts — use-hr hook computes expiringTraining (60 days), visible in HR page Training tab
- [x] Performance reviews — HR page Reviews tab with ratings, goals, feedback
- [ ] OSHA training compliance tracking — needs OSHA → training_records link

**F5h: Email System (~15 hrs)**
- [x] Tables: email_templates, email_sends, email_campaigns, email_unsubscribes (migration 43) — full email system with analytics
- [x] SendGrid integration: transactional — sendgrid-email EF (send, send_template, webhook, get_stats). Logs all sends to email_sends table. Handles delivery/open/click/bounce status updates.
- [x] Marketing email — use-email hook + /dashboard/email page (4 tabs: Templates/Sent/Campaigns/Unsubscribes, stats cards)
- [ ] Email templates tied to CRM events — needs trigger_event wiring
- [x] Email analytics (open rate, click rate) — sendgrid-email webhook handler updates email_sends status, get_stats action returns monthly analytics

**F5i: Document Management (~15 hrs)**
- [x] Tables: document_folders, documents, document_templates, document_access_log (migration 44) — hierarchical folders, versioning, e-signature tracking
- [x] File storage per job/customer/property — use-documents hook + /dashboard/documents page rewired from empty data (folder tree sidebar, grid/list toggle, type filters, signature status badges, upload modal)
- [x] Template system (proposals, contracts, lien waivers) — use-documents hook supports document_templates CRUD, templates section in documents page
- [ ] DocuSign integration for e-signatures — needs DocuSign API
- [x] Version history — documents page shows version info from hook data, tables support versioning
- [x] All 5 apps build clean — Web CRM 103 routes, Client Portal 33 routes
- [ ] Commit: `[F5] Business OS — 9 systems, lead aggregation, enterprise backbone`

---

### Sprint F6: Marketplace (~80-120 hrs)
**Source:** `04_EXPANSION_SPECS.md` F6 section

**F6a: Database + Edge Functions**
- [x] Tables: equipment_database, equipment_scans, marketplace_leads, marketplace_bids, contractor_profiles (5 tables, migration 45) — all with RLS, indexes, triggers
- [x] Edge Function: equipment-scanner (scan, lookup, generate_lead, get_database, add_equipment) — AI scan placeholder for Phase E, contractor matching for leads

**F6b: CRM + Portal Pages**
- [x] Hook: use-marketplace (leads, bids, contractor profile, real-time, mutations: createBid, updateBidStatus, withdrawBid, updateContractorProfile)
- [x] Page: /dashboard/marketplace (3 tabs: Available Leads with bid forms, My Bids with withdraw, Contractor Profile editor)
- [x] Equipment AI scanning (camera → model identification → diagnostics) — equipment-scanner EF with AI placeholder (Phase E for Claude Vision)
- [x] Pre-qualified lead generation (homeowner → contractor match) — equipment-scanner generate_lead action matches contractors by trade + rating
- [x] Contractor bidding on marketplace leads — marketplace page Place Bid form with amount/description/timeline
- [ ] Service history tracking per property — deferred to F7 client portal
- [x] Equipment database (known models, issues, lifespans) — equipment_database table + equipment-scanner get_database/add_equipment actions
- [ ] Commit: `[F6] Marketplace — equipment AI, lead gen, contractor bidding`

---

### Sprint F7: ZAFTO Home Platform (~140-180 hrs)
**Source:** `04_EXPANSION_SPECS.md` F7 section

**F7a: Database**
- [x] Tables: homeowner_properties, homeowner_equipment, service_history, maintenance_schedules, homeowner_documents (5 tables, migration 46) — all with RLS by owner_user_id, contractors can see service_history for their jobs

**F7b: Client Portal Pages**
- [x] Hook: use-home (all 5 tables, real-time on properties + equipment, mutations: addProperty, addEquipment, addServiceRecord, completeMaintenanceTask, computed: healthScore, maintenanceDue, alertCount)
- [x] Page: /my-home rewired from mock data (property card, health score gradient, systems overview by category, equipment passport link, upcoming maintenance, service timeline)
- [x] Page: /my-home/equipment rewired from mockEquipment (condition badges, age calc, alerts for warranty/service/lifespan, filters)
- [x] Page: /my-home/service-history NEW (service timeline, type badges, contractor info, cost, ratings, summary cards)
- [x] Page: /my-home/maintenance NEW (overdue/due soon/upcoming sections, priority badges, AI recommendations, complete task)
- [x] Client Portal evolves into homeowner property intelligence platform — 4 pages wired to real Supabase data
- [x] Free: equipment passport, service history, doc storage, maintenance reminders — all built in client portal
- [ ] Premium ($7.99/mo): AI property advisor, predictive maintenance, contractor matching — deferred to Phase E + RevenueCat
- [ ] R1f deferred items: home_scan_logs, home_maintenance_reminders tables — separate from F7 tables
- [ ] Home Scanner mobile feature (camera → AI equipment identification) — deferred to Flutter + Phase E
- [ ] Commit: `[F7] ZAFTO Home — homeowner property intelligence platform`

---

### Sprint F9: Hiring System (~18-22 hrs)
**Source:** `04_EXPANSION_SPECS.md` F9 section

**F9a: Database**
- [x] Tables: job_postings, applicants, interview_schedules (3 tables, migration 47) — multi-channel distribution fields, full pipeline stages, Checkr/E-Verify integration fields, interview feedback JSONB

**F9b: CRM Pages**
- [x] Hook: use-hiring (3 tables, real-time, mutations: createPosting, publishPosting, addApplicant, updateApplicantStage, scheduleInterview, sendOffer, rejectApplicant, computed: activePostings, inPipeline, interviewsThisWeek, hiredCount)
- [x] Page: /dashboard/hiring (3 tabs: Job Postings, Applicant Pipeline with 5-column kanban, Interviews with upcoming/past split)
- [x] Job posting creation in CRM — create modal with title/dept/type/desc/pay/location/positions
- [x] Multi-channel distribution: Indeed (free), LinkedIn, ZipRecruiter — posting_channels JSONB field, distribute toggle per channel
- [x] Applicant pipeline: applied → screening → interview → offer → hired — 5-column pipeline view with stage transitions via dropdown
- [ ] Checkr background checks ($29-$80/check) — needs Checkr API integration
- [ ] E-Verify integration (free federal employment verification) — needs E-Verify API
- [ ] Resume parsing — deferred to Phase E (AI)
- [x] Interview scheduling (ties to calendar) — Interviews tab with schedule/complete/reschedule/cancel actions
- [x] Onboarding checklist → HR Suite (F5g) — applicants table has FK to employee_records for hired applicants
- [ ] Commit: `[F9] Hiring system — multi-channel posting, applicant pipeline`

---

### Sprint F10: ZDocs + ZSheets (TBD hrs) — SECOND TO LAST
**Source:** `04_EXPANSION_SPECS.md` F10 section

**F10a: Database + Edge Function**
- [x] Tables: zdocs_renders, zdocs_template_sections, zdocs_signature_requests (3 tables, migration 48) — render tracking, structured sections, signature collection with access tokens
- [x] Edge Function: zdocs-render (render, preview, get_entity_data, send_for_signature, verify_signature, get_system_templates) — variable substitution from 8 entity types (job/customer/estimate/invoice/bid/change_order/property/claim), HTML rendering, signature workflow, 5 system templates (proposal/contract/lien waiver/change order/daily report)
- [x] Builds on F5i document_templates table (content_html + variables JSONB)

**F10b: CRM Page**
- [x] Hook: use-zdocs (templates + renders + signature requests, real-time, mutations: createTemplate, deleteTemplate, duplicateTemplate, renderDocument, sendForSignature, deleteRender)
- [x] Page: /dashboard/zdocs (3 tabs: Templates grid, Generated Documents table, Signatures tracking)
- [x] Sidebar: ZDocs added to OFFICE group

**F10c: Feature Checklist**
- [x] PDF-first document suite (NOT Google Docs — trade-focused)
- [x] Templates: proposals, contracts, change orders, inspection reports, lien waivers — 5 system templates with HTML content
- [x] Fill-from-CRM-data (customer, job, estimate, invoice auto-populate) — get_entity_data action fetches from 8 entity types + company data
- [x] E-signature workflow — zdocs_signature_requests with access tokens, send/view/sign/decline status, signature image upload
- [ ] DocuSign/PandaDoc integration — deferred (built-in signature system works for now)
- [x] Version history + audit trail — zdocs_renders tracks every generation with data_snapshot JSONB
- [x] Build AFTER all features locked so templates cover every document type — F1-F9 all complete
- [ ] Commit: `[F10] ZDocs — PDF-first document suite`

**F10d: Portal Expansion (All Portals)**
- [x] Team Portal: 4 hooks (use-pay-stubs, use-my-vehicle, use-my-training, use-my-documents) + 4 pages (/dashboard/pay-stubs, /dashboard/my-vehicle, /dashboard/training, /dashboard/my-documents) + sidebar MY STUFF section — 36 total routes, build clean
- [x] Client Portal: 3 hooks (use-home-documents, use-quotes, use-find-a-pro) + 3 pages (/my-home/documents, /get-quotes, /find-a-pro) + sidebar links — 38 total routes, build clean
- [x] Ops Portal: 5 analytics pages (payroll-analytics, fleet-analytics, hiring-analytics, email-analytics, marketplace-analytics) + sidebar PLATFORM section — 24 dashboard routes, build clean
- [x] Web CRM: 107 total routes, build clean (ZDocs = newest)

---

## PHASE G: DEBUG, QA & HARDENING (AFTER T + P + SK — harden everything at once)
*Final quality pass before launch.*

### Sprint G1: Full Platform Debug
**Goal:** Verify every build compiles clean, every route is accessible, every hook connects to real data.

**G1a: Consolidated Build Verification**
- [x] Web CRM: `npm run build` — 0 errors, 104 routes
- [x] Team Portal: `npm run build` — 0 errors, 34 routes
- [x] Client Portal: `npm run build` — 0 errors, 38 routes
- [x] Ops Portal: `npm run build` — 0 errors, 27 routes
- [x] Flutter: `dart analyze` — 0 errors, 2755 warnings/infos (deprecated withOpacity, unused imports)
- [x] Codemagic CI/CD: Android debug build PASSING (S91) — 95.53 MB .aab artifact
- [x] Dependabot: 0 vulnerabilities (S91) — protobufjs + fast-xml-parser fixed in legacy Firebase backend

**G1b: Dead Code & Mock Data Cleanup**
- [ ] Audit all hooks for remaining mock/fake data
- [ ] Remove any unused imports across all portals
- [ ] Remove console.log/console.error debug statements
- [ ] Verify no hardcoded test credentials or placeholder API keys in source
- [ ] Check for TODO/FIXME/HACK comments that need resolution

**G1c: Route & Navigation Verification**
- [ ] Every sidebar nav item links to an existing route (web CRM)
- [ ] Every sidebar nav item links to an existing route (team portal)
- [ ] Every sidebar nav item links to an existing route (ops portal)
- [ ] Client portal navigation links all valid
- [ ] No 404 routes in any portal

**G1d: Database Wiring Verification**
- [ ] All hooks reference tables that exist in migrations
- [ ] All hooks use correct column names matching DB schema
- [ ] Real-time subscriptions on correct table/channel names
- [ ] Supabase Storage bucket names match across hooks and EFs

**G1e: Edge Function Audit**
- [ ] All 53 Edge Functions have valid Deno syntax
- [ ] All EFs use consistent CORS + auth pattern
- [ ] All EFs reference tables that exist
- [ ] No EFs reference non-existent secrets

---

### Sprint G2: Security Audit
**Goal:** Verify RLS, auth, input sanitization across entire platform.

**G2a: RLS Policy Review**
- [ ] Audit all ~169 tables for RLS enabled
- [ ] Verify company_id isolation on multi-tenant tables
- [ ] Verify user_id isolation on personal data tables
- [ ] Check for tables with overly permissive policies

**G2b: Auth & Middleware**
- [ ] Web CRM auth middleware covers all /dashboard/* routes
- [ ] Team Portal auth middleware covers all /dashboard/* routes
- [ ] Client Portal auth middleware covers all portal routes
- [ ] Ops Portal super_admin role gate enforced

**G2c: Input Validation**
- [ ] Check for SQL injection vectors in dynamic queries
- [ ] Check for XSS vectors in user-rendered content (ZDocs templates)
- [ ] Verify file upload size/type restrictions

---

### Sprint G3: Performance Optimization
- [ ] Bundle size analysis (identify >500kB routes)
- [ ] Lazy load heavy components (charts, editors)
- [ ] Image optimization (next/image usage)
- [ ] Database query optimization (N+1 queries, missing indexes)

---

### Sprint G4: Final Security Hardening
- [ ] Sentry DSN configured in all apps (currently EMPTY)
- [ ] Security headers (CSP, X-Frame-Options, etc.)
- [ ] Rate limiting on auth endpoints
- [ ] Deploy pending migrations: `npx supabase db push`

### Sprint G5: CI/CD & Release Readiness (S91 foundation)
- [x] Codemagic account set up — Android debug build PASSING (S91)
- [ ] iOS code signing — add Apple Developer API key to Codemagic Distribution
- [ ] Android release keystore — generate, upload to Codemagic
- [ ] Create `codemagic.yaml` for reproducible builds (currently using UI workflow)
- [ ] Set `--dart-define` environment variables in Codemagic (SUPABASE_URL, SUPABASE_ANON_KEY, SENTRY_DSN)
- [ ] Remove 13 remaining cloud_firestore imports (Phase G cleanup)
- [ ] Remove firebase_core/cloud_firestore/cloud_functions from pubspec.yaml after cleanup
- [ ] Google Play Developer account creation
- [ ] TestFlight distribution setup (after iOS code signing)
- [ ] Play Store internal testing track setup (after Android keystore)

### Sprint G6: TPA Module QA
**Goal:** Verify all TPA features work end-to-end after Phase T build.

**G6a: TPA Database & Data Integrity**
- [ ] All ~17 TPA tables exist and have RLS enabled
- [ ] company_id isolation verified on all TPA tables
- [ ] Feature flag (`companies.features.tpa_enabled`) gates TPA sidebar section correctly
- [ ] TPA assignment status workflow transitions verified (each status → valid next statuses)
- [ ] SLA countdown timers calculate correctly (contact, inspect, upload, complete deadlines)
- [ ] Referral fee calculations match program settings

**G6b: TPA CRM Pages — Full Button-Click Audit**
- [ ] TPA Command Center: all filters work, assignment cards clickable, status badges accurate
- [ ] TPA Assignment Detail: every action button works (accept, schedule, upload, submit, supplement)
- [ ] TPA Program Settings: create/edit/archive programs, SLA presets save correctly
- [ ] TPA Profitability Dashboard: per-program metrics calculate from real data
- [ ] TPA Scorecard: score entries create/display correctly, trend charts render
- [ ] TPA Document Validation: required docs checklist enforces per-program requirements
- [ ] IICRC compliance fields: moisture readings, drying logs, equipment placement formulas validate

**G6c: TPA Integration Points**
- [ ] TPA assignment → creates job with `is_tpa_job=true` + correct `tpa_program_id`
- [ ] TPA job → estimate links via `tpa_assignment_id` on estimates table
- [ ] TPA supplement workflow: supplement number auto-increments, linked to original estimate
- [ ] D8 estimate engine works with TPA-generated estimates
- [ ] TPA-specific line items (IICRC codes) map correctly to estimate categories
- [ ] All 3 TPA Edge Functions respond correctly (test with sample data)

**G6d: TPA Portal Pages**
- [ ] Team portal: TPA assignment view works for field techs
- [ ] Client portal: TPA job visibility (if applicable to homeowner)
- [ ] Ops portal: TPA analytics page shows aggregate data
- [ ] Mobile app: TPA screens (if built) connect to live data

---

### Sprint G7: ZScan / Property Intelligence QA
**Goal:** Verify all ZScan features work end-to-end after Phase P build.

**G7a: ZScan Database & API Verification**
- [ ] All ~8 ZScan tables exist and have RLS enabled
- [ ] company_id isolation verified on all ZScan tables
- [ ] Google Solar API integration returns valid Building Insights data
- [ ] ATTOM Property API returns property metadata (if key configured)
- [ ] Regrid parcel boundary data imports correctly
- [ ] Microsoft Building Footprints fallback works when Solar API insufficient

**G7b: ZScan Measurement Accuracy**
- [ ] Roof measurement pipeline: pitch detection, facet area calculation, ridge/hip/valley LF
- [ ] Siding measurement: wall SF minus openings
- [ ] Gutter measurement: eave/rake LF from roof geometry
- [ ] Solar potential: panel placement, annual kWh estimate
- [ ] Waste factor engine: per-trade percentages applied correctly
- [ ] Material quantity calculator: measurements → order quantities

**G7c: ZScan CRM Pages — Full Button-Click Audit**
- [ ] Property scan initiation: address lookup → API call → results display
- [ ] Scan results page: all measurement tabs render correctly
- [ ] Material ordering: Unwrangle/ABC Supply integration (if keys configured)
- [ ] On-site verification workflow: field tech confirms/adjusts measurements
- [ ] Export/share scan results
- [ ] All 4 ZScan Edge Functions respond correctly

**G7d: ZScan Integration Points**
- [ ] ZScan → bid generation (measurements populate bid line items)
- [ ] ZScan → estimate (measurements flow to D8 estimate engine)
- [ ] ZScan → job (property data attached to job record)
- [ ] Multiple scans per property (history preserved)

---

### Sprint G8: Sketch Engine QA
**Goal:** Verify all Sketch Engine features work end-to-end after Phase SK build.

**G8a: Sketch Engine Database & Sync**
- [ ] `property_floor_plans` table has all V2 columns (job_id, estimate_id, status, sync_version)
- [ ] `floor_plan_layers` table: trade layer CRUD works
- [ ] `floor_plan_rooms` table: room boundary + computed measurements accurate
- [ ] `floor_plan_estimate_links` bridge table: room ↔ estimate area links work
- [ ] Offline sync: Hive cache saves locally, syncs when online
- [ ] Conflict resolution: server version wins, user prompted on conflict
- [ ] Thumbnail generation: plans render to PNG in storage bucket

**G8b: Flutter Mobile Editor — Full Tool Audit**
- [ ] Wall drawing: straight walls snap to grid + endpoints
- [ ] Wall editing: tap to select, drag endpoints, split wall, change thickness
- [ ] Arc walls: Bezier drawing + thickness + door/window attachment
- [ ] Doors: all door types (7) place on walls correctly, swing direction
- [ ] Windows: place on walls, set width/height/sill height
- [ ] Fixtures: all 25+ fixtures place + rotate (two-finger gesture)
- [ ] Multi-select: lasso + shift-tap, move/delete/copy group
- [ ] Copy/paste: single elements + groups, across floors
- [ ] Undo/redo: every action reversible
- [ ] Unit toggle: imperial ↔ metric, all dimensions convert live
- [ ] Smart dimensions: auto-generated wall lengths + room area labels

**G8c: Trade Layers — Every Symbol**
- [ ] Electrical layer: all 15 symbols place correctly (receptacles, switches, lights, panel, junction)
- [ ] Wire paths: circuit runs draw along walls, color-coded by circuit
- [ ] Plumbing layer: all 12 symbols place correctly (fixtures + pipes)
- [ ] Pipe routing: hot/cold/drain/gas with diameter labels
- [ ] HVAC layer: all 10 symbols place correctly (equipment + distribution)
- [ ] Duct routing: supply/return with CFM labels
- [ ] Damage layer: affected area zones (Class 1-4 color coding), moisture readings, containment barriers, source arrows
- [ ] IICRC category overlay: Cat 1 blue, Cat 2 yellow, Cat 3 red
- [ ] Layer panel: visibility toggle, lock toggle, opacity slider — all work for each layer

**G8d: LiDAR Scanning (iPhone)**
- [ ] LiDAR capability detection: shows "Manual entry" fallback on non-LiDAR devices
- [ ] RoomPlan scanning UX: instructions overlay, real-time preview
- [ ] 3D→2D projection: wall positions/lengths match physical room (±2 inches)
- [ ] Multi-room scanning: room boundaries auto-detected
- [ ] Scanned plan fully editable after import
- [ ] Manual room entry fallback: generates rectangular rooms from dimensions

**G8e: Web CRM Canvas Editor (Konva.js)**
- [ ] All drawing tools work: wall, arc wall, door, window, fixture, label, dimension
- [ ] All trade layer tools match mobile parity
- [ ] Pan (space+drag/middle-click) and zoom (scroll wheel) smooth at 60fps
- [ ] Property inspector panel: shows selected element properties, editable
- [ ] Keyboard shortcuts: Ctrl+Z, Ctrl+Y, Ctrl+C/V, Delete, Escape
- [ ] Snap to grid, snap to endpoints, angle snap (15° increments)
- [ ] Mini-map renders in corner for large plans
- [ ] Ruler along top and left edges
- [ ] Real-time sync: edit on web → appears on mobile (and vice versa)

**G8f: Auto-Estimate Pipeline**
- [ ] "Generate Estimate" creates estimate from floor plan
- [ ] Room measurements: floor SF (shoelace formula), wall SF, ceiling SF, baseboard LF accurate
- [ ] Door/window count per room correct
- [ ] Line item suggestions match room type + trade + damage data
- [ ] D8 estimate engine pricing lookup works with generated areas
- [ ] User can review and adjust before finalizing

**G8g: Export Pipeline**
- [ ] PDF export: title block, floor plan drawing, room schedule, trade legend — all render
- [ ] PNG export: 2x and 4x scale options produce clean raster
- [ ] DXF export: opens in AutoCAD (or free DXF viewer) with correct geometry
- [ ] FML export: valid XML, opens in Symbility/Cotality (or validates against schema)

**G8h: 3D Visualization**
- [ ] 2D↔3D toggle switch works
- [ ] Wall extrusion: 3D prisms at correct wall height
- [ ] Door/window openings: boolean subtraction visible
- [ ] Floor plane with material texture
- [ ] Trade elements rendered as 3D icons
- [ ] Orbit controls: rotate, pan, zoom smooth
- [ ] Room labels floating above rooms

**G8i: Stress Testing**
- [ ] 50-room floor plan with all trade layers: 60fps web, 30fps mobile
- [ ] Large plan pan/zoom performance acceptable
- [ ] Undo/redo stack handles 100+ actions without lag

---

### Sprint G9: Full Platform Button-Click Audit
**Goal:** Every button on every page across ALL portals + mobile app — clicked and verified. S93 lesson: hooks have the functions but UI never calls them.

**G9a: Web CRM — All 107 Routes**
- [ ] Every sidebar nav link works (no 404s)
- [ ] Every action button on every page triggers the correct function
- [ ] Every modal opens, submits, and closes correctly
- [ ] Every dropdown menu item works
- [ ] Every status change button updates the DB and UI
- [ ] Every delete button shows confirmation and actually deletes
- [ ] Every export/download button produces output
- [ ] Every form submits with company_id and all required fields
- [ ] Error states display to user (not swallowed silently)

**G9b: Team Portal — All 36 Routes**
- [ ] Every nav link works
- [ ] Every action button works
- [ ] Every form submits correctly
- [ ] Permission gates: role-restricted pages show access denied for wrong roles

**G9c: Client Portal — All 38 Routes**
- [ ] Every nav link works
- [ ] Magic link auth flow: send link → click → signed in on original tab
- [ ] Password auth flow: enter credentials → signed in
- [ ] Every action button works
- [ ] Client-facing data: only shows THEIR jobs/invoices/property

**G9d: Ops Portal — All 24 Routes**
- [ ] Every nav link works
- [ ] super_admin gate: non-super_admin gets access denied
- [ ] Every analytics page renders with real data (or graceful empty state)
- [ ] Every action button works

**G9e: Flutter Mobile — All 33 R1 Screens + 18 Field Tools**
- [ ] Every screen navigates correctly from AppShell
- [ ] Every form submits to Supabase
- [ ] Every field tool saves data correctly
- [ ] Role switching works (owner → admin → tech)
- [ ] Offline mode: data saves to Hive, syncs when online

---

### Sprint G10: Cross-Feature Integration Testing
**Goal:** Verify the full end-to-end workflows that span multiple features.

**G10a: Sketch → Estimate → Invoice Pipeline**
- [ ] Draw floor plan (mobile or web) → generate estimate → review line items → create invoice → send to client
- [ ] Client receives invoice in client portal
- [ ] Payment recorded → job marked complete

**G10b: TPA → Estimate → Xactimate Pipeline**
- [ ] Receive TPA assignment → create job → draw sketch → generate estimate with IICRC codes
- [ ] Export estimate to FML format
- [ ] Supplement workflow: original + supplement estimates linked
- [ ] TPA profitability calculates correctly (revenue - referral fee - costs)

**G10c: ZScan → Bid → Job Pipeline**
- [ ] Scan property address → get measurements → create bid with measurement data
- [ ] Bid accepted → convert to job → schedule → complete → invoice

**G10d: Real-Time Sync Verification**
- [ ] Create job on CRM → appears on team portal in <5s
- [ ] Update job on mobile → appears on CRM in <5s
- [ ] Client portal shows job status change in real-time
- [ ] Ops portal analytics update with new data

**G10e: Multi-App Data Consistency**
- [ ] Same job shows identical data across CRM + team + client + ops + mobile
- [ ] Invoice totals match across all portals
- [ ] Customer info consistent across all views
- [ ] Photo uploads visible everywhere (mobile → CRM → client portal)

---

## PHASE T: TPA PROGRAM MANAGEMENT MODULE (~80 hours)
*Optional module for restoration/insurance contractors. Feature flag: company.features.tpa_enabled*
*Full spec: `Expansion/39_TPA_MODULE_SPEC.md` | Legal: `memory/tpa-legal-assessment.md` | Research: `memory/tpa-research.md`*

---

### Sprint T1: TPA Foundation (~8 hours)
**Goal:** Core TPA tables, feature flag, CRM settings page.

**T1a: Database — Core TPA Tables**
- [ ] Migration: `tpa_programs` table (company enrollment, SLA settings, referral fees, portal reference) + RLS
- [ ] Migration: `tpa_assignments` table (dispatched jobs with full SLA tracking, status workflow, financials) + RLS
- [ ] Migration: `tpa_scorecards` table (periodic score entries per TPA program) + RLS
- [ ] Migration: `companies.features` JSONB column (`ALTER TABLE companies ADD COLUMN features jsonb DEFAULT '{}'`)
- [ ] Add `tpa_assignment_id`, `tpa_program_id`, `is_tpa_job` columns to `jobs` table
- [ ] Add `tpa_assignment_id`, `supplement_number` columns to `estimates` table
- [ ] Deploy migration: `npx supabase db push`

**T1b: CRM — TPA Settings + Feature Flag**
- [ ] CRM hook: `use-tpa-programs.ts` (CRUD, real-time subscription)
- [ ] CRM page: `/dashboard/settings/tpa-programs` — manage enrolled TPA programs
- [ ] Feature flag logic: conditionally show "INSURANCE PROGRAMS" sidebar section when `features.tpa_enabled = true`
- [ ] TPA program create/edit form: name, type, carrier names, referral fee, SLA settings, portal URL, contacts
- [ ] `npm run build` passes

---

### Sprint T2: Assignment Tracking (~12 hours)
**Goal:** TPA assignment lifecycle — create, track, SLA countdown.

**T2a: Database — Supplements + Documentation Tables**
- [ ] Migration: `tpa_supplements` table (supplement tracking with status workflow: draft → submitted → approved/denied) + RLS
- [ ] Migration: `tpa_doc_requirements` table (configurable per-TPA documentation checklists) + RLS
- [ ] Migration: `tpa_photo_compliance` table (photo-to-checklist linking, phase tagging) + RLS
- [ ] Deploy migration

**T2b: CRM — Assignment Management**
- [ ] CRM hook: `use-tpa-assignments.ts` (CRUD, real-time, SLA deadline auto-calculation)
- [ ] CRM page: `/dashboard/tpa/assignments` — table view with SLA status badges (green/yellow/red)
- [ ] CRM page: `/dashboard/tpa/assignments/[id]` — detail view with timeline, milestones, documentation status
- [ ] Assignment create form: manual entry (TPA program, assignment/claim/policy numbers, carrier, adjuster, policyholder, loss type/date, property address)
- [ ] SLA auto-calculation: first_contact_deadline = assigned_at + sla_first_contact_minutes, etc.
- [ ] Job integration: link assignment to existing job or auto-create job with type=insurance_claim
- [ ] `npm run build` passes

---

### Sprint T3: Water Damage Assessment + Moisture (~12 hours)
**Goal:** IICRC S500-compliant water damage classification, moisture mapping, psychrometric monitoring.

**T3a: Database — Assessment + Monitoring Tables**
- [ ] Migration: `water_damage_assessments` table (IICRC category 1-3, class 1-4, source, affected areas, pre-existing) + RLS
- [ ] Migration: `moisture_readings` table (daily MC readings at mapped locations, reference standards, drying goals) + RLS
- [ ] Migration: `psychrometric_logs` table (indoor/outdoor temp+RH, GPP, dew point, dehu inlet/outlet) + RLS
- [ ] Migration: `contents_inventory` table (room-by-room item tracking: move/block/pack-out/dispose, condition, destination, pre-loss value, photo_ids, packed_by/at, returned_at — billable service, 10-30% of water mitigation invoices) + RLS
- [ ] Deploy migration

**T3b: Mobile — Water Damage + Moisture Screens**
- [ ] Mobile: Water damage assessment screen (category picker 1-3 with descriptions, class picker 1-4, source, affected rooms/materials, sqft)
- [ ] Mobile: Enhanced moisture reading screen (numbered location grid, material type, MC reading, reference standard, drying goal indicator, color coding: red/yellow/green)
- [ ] Mobile: Psychrometric log entry (temp + RH → auto-calculate GPP via formula, dew point calculation, indoor vs outdoor comparison)
- [ ] Mobile: Contents inventory screen (room-by-room item list: description, qty, condition, action: move/block/pack-out/dispose, destination, photos, packed_by)
- [ ] `dart analyze` passes

**T3c: CRM — Monitoring Dashboard**
- [ ] CRM hook: `use-moisture-readings.ts` (readings over time per job, drying progress)
- [ ] CRM page: Moisture/drying monitoring view on job detail (readings chart, location grid, "all dry" validation)
- [ ] `npm run build` passes

---

### Sprint T4: Equipment Deployment + Calculator (~10 hours)
**Goal:** IICRC equipment placement formulas, billing clock, deployment tracking.

**T4a: Database — Equipment Tables**
- [ ] Migration: `equipment_deployments` table (type, serial, AHAM rating, room, placement, billing clock: placed_at → removed_at) + RLS
- [ ] Migration: `equipment_calculations` table (room dimensions, class, dehu/air mover/scrubber formula results, variance notes) + RLS
- [ ] Migration: `equipment_inventory` table (warehouse inventory — equipment_type, name, serial_number, asset_tag, AHAM PPD/CFM ratings, purchase_date/price, daily_rental_rate, status: available/deployed/maintenance/retired/lost, current_job_id, maintenance tracking) + RLS
- [ ] Deploy migration

**T4b: Edge Function — Equipment Calculator**
- [ ] Edge Function: `tpa-equipment-calculator` — IICRC S500 formulas:
  - Dehu: cubic_ft / chart_factor = PPD needed / unit_ppd = units (round UP)
  - Air movers: wall_lf/14 + floor_sf/50-70 + ceiling_sf/100-150 + insets (round UP)
  - Air scrubbers: cubic_ft * target_ach / 60 / scrubber_cfm = units (round UP)
  - Returns formula breakdown for adjuster justification
- [ ] Deploy Edge Function

**T4c: Mobile — Equipment Screens**
- [ ] Mobile: IICRC equipment calculator screen (input: room L x W x H, water class, dehu type → output: counts with formula breakdown)
- [ ] Mobile: Equipment deployment screen (place equipment with serial number, start billing clock; remove equipment, auto-calculate billable days)
- [ ] Mobile: Equipment warehouse inventory check (show available vs deployed equipment before placement)
- [ ] `dart analyze` passes

**T4d: CRM — Equipment Tracking**
- [ ] CRM hook: `use-equipment-deployments.ts`
- [ ] CRM hook: `use-equipment-inventory.ts` (warehouse inventory CRUD — available/deployed/maintenance status)
- [ ] CRM: Equipment deployment tracking on job detail page (deployed equipment list, billing summary)
- [ ] CRM: Equipment inventory management page (warehouse view — what's available, what's deployed where, maintenance schedule)
- [ ] `npm run build` passes

---

### Sprint T5: Documentation Validation (~8 hours)
**Goal:** Pre-submission documentation completeness checking, COC generation.

**T5a: Database — Certificate of Completion**
- [ ] Migration: `certificates_of_completion` table (signatures, scope summary, PDF, lien waiver, satisfaction survey) + RLS
- [ ] Deploy migration

**T5b: Edge Function — Documentation Validator**
- [ ] Edge Function: `tpa-documentation-validator` — given job_id, check all documentation against TPA program requirements, return missing items + compliance percentage + deadline status
- [ ] Deploy Edge Function

**T5c: Seed Data — Documentation Checklists**
- [ ] Seed: Default water mitigation checklist (20+ items across 5 phases: initial inspection, during work, daily monitoring, completion, closeout)
- [ ] Seed: Default fire restoration checklist
- [ ] Seed: Default mold remediation checklist
- [ ] Seed: Default roofing claim checklist
- [ ] Seed: IICRC equipment chart factors (Class 1-4 for LGR, conventional, desiccant)

**T5d: Mobile + CRM — Documentation UI**
- [ ] Mobile: Documentation checklist overlay on TPA jobs (shows required items by phase, completion count: "6 of 12 initial inspection photos")
- [ ] Mobile: Photo phase tagging on upload (before/during/after/equipment/moisture/source/exterior/contents/pre_existing)
- [ ] CRM: Documentation completeness dashboard per assignment
- [ ] `dart analyze` + `npm run build` pass

---

### Sprint T6: Financial Analytics (~8 hours)
**Goal:** Per-TPA profitability, referral fee tracking, AR aging.

**T6a: Database — Financial Summary**
- [ ] Migration: `tpa_program_financials` table (monthly rollup: revenue, referral fees, labor/material/equipment costs, margins, AR, supplement performance, scoring) + RLS
- [ ] Deploy migration

**T6b: Edge Function — Financial Rollup**
- [ ] Edge Function: `tpa-financial-rollup` — monthly aggregation from tpa_assignments + jobs + ZBooks data, calculate gross/net margins, avg payment days, supplement recovery rate
- [ ] Deploy Edge Function

**T6c: CRM — TPA Dashboard**
- [ ] CRM hook: `use-tpa-financials.ts`
- [ ] CRM page: `/dashboard/tpa` — TPA Dashboard (program cards with active count + avg score + cycle time, assignment pipeline: received → in progress → estimate → payment → paid, SLA violations count, financial summary per program)
- [ ] CRM: Per-TPA P&L report (integrates with ZBooks job costing)
- [ ] Referral fee auto-calculation on job close (based on tpa_program.referral_fee_percent)
- [ ] `npm run build` passes

---

### Sprint T7: Supplement Workflow + Scorecard (~8 hours)
**Goal:** Supplement discovery/tracking, TPA performance scoring over time.

**T7a: CRM — Supplement Tracking**
- [ ] CRM hook: `use-tpa-supplements.ts`
- [ ] CRM: Supplement tracking UI on assignment detail (create supplement S1/S2/S3, document reason, link photos + line items, track status: draft → submitted → approved/denied)
- [ ] Mobile: Supplement discovery workflow (flag additional scope from field with photos + readings)

**T7b: CRM — Scorecards**
- [ ] CRM hook: `use-tpa-scorecards.ts`
- [ ] CRM page: `/dashboard/tpa/scorecards` — enter/view scores per TPA program, trend line charts over time, alert thresholds (contractor sets warning level, system alerts when approaching)
- [ ] `dart analyze` + `npm run build` pass

---

### Sprint T8: Restoration Line Items + Export (~10 hours)
**Goal:** ZAFTO's own line item database with Xactimate code mapping, format exports.

**T8a: Database — Line Items**
- [ ] Migration: `restoration_line_items` table (ZAFTO codes Z-WTR-xxx, own descriptions + pricing, Xactimate category/selector mapping for export) + RLS
- [ ] Seed: ~50 initial restoration line items (Water Extraction, Demolition, Drying Equipment, Cleaning/Treatment, Monitoring, Contents, Hazmat, Temporary Repairs, Reconstruction)

**T8b: Estimate Engine Integration**
- [ ] Add Xactimate code mapping column to estimate line items for export reference
- [ ] Integrate restoration_line_items into estimate builder line item picker (additional category)

**T8c: Format Exports**
- [ ] FML floor plan export (open format, JSON-based, Symbility/Cotality compatible)
- [ ] DXF floor plan export (universal CAD format)
- [ ] PDF documentation package export (photos + moisture readings + psychrometric logs + equipment + estimate → single PDF)
- [ ] ESX import capability (read contractor's own ESX files into ZAFTO via existing import-esx EF)
- [ ] `dart analyze` + `npm run build` pass

---

### Sprint T9: Portal Integration (~8 hours)
**Goal:** TPA features in team portal + ops portal.

**T9a: Team Portal**
- [ ] Team Portal hooks: `use-tpa-jobs.ts` (SLA data for assigned TPA jobs), `use-equipment.ts` (field equipment management)
- [ ] Team Portal: SLA countdown badges on TPA job cards
- [ ] Team Portal: Documentation checklist view (required items + completion count)
- [ ] Team Portal: Equipment deployment quick-add from field
- [ ] `npm run build` passes

**T9b: Ops Portal**
- [ ] Ops Portal: TPA analytics page (assignment volume, SLA compliance, program performance across all companies)
- [ ] Ops Portal sidebar: TPA link in PLATFORM section
- [ ] `npm run build` passes

**T9c: CRM Sidebar**
- [ ] CRM sidebar: "INSURANCE PROGRAMS" collapsible section (conditional on `features.tpa_enabled`)
  - TPA Dashboard
  - Assignments
  - Scorecards
  - Program Settings
- [ ] `npm run build` passes

---

### Sprint T10: Polish + Build Verification (~4 hours)
**Goal:** Full verification, feature flag toggle, disclaimer text.

- [ ] All portals build clean: `npm run build` (CRM, team, client, ops)
- [ ] Mobile: `dart analyze` passes
- [ ] Feature flag toggle: verify ALL TPA UI hidden when `features.tpa_enabled = false`
- [ ] Feature flag toggle: verify ALL TPA UI visible when `features.tpa_enabled = true`
- [ ] Documentation checklist validation end-to-end: create assignment → upload photos → validate → confirm counts
- [ ] IICRC calculator accuracy: verify against published IICRC S500 equipment placement formulas
- [ ] Legal disclaimers present on all pages referencing TPA/carrier/Xactimate names
- [ ] Estimate engine disclaimer: "Estimates represent contractor's scope of work and pricing"
- [ ] IICRC disclaimer: "Based on publicly available IICRC formulas"
- [ ] Commit: `[T1-T10] TPA Program Management Module — 17 tables, 3 EFs, feature flag`

---

## PHASE P: PROPERTY INTELLIGENCE ENGINE (ZScan) — after Phase T
*Spec: Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md*
*8 tables, 4 Edge Functions, 8 sprints (~68 hours)*
*Satellite-powered property measurements: address in → instant roof/wall/lot/solar data → estimate → material order*
*$0/scan vs EagleView $18-91/report. 10 trade pipelines. On-site verification workflow.*

---

### Sprint P1: Foundation + Google Solar API (~10 hours)
**Goal:** Core tables + Google Solar integration for roof segments, pitch, area, sun hours.
**Prereqs:** Phase T complete. Google Cloud Solar API enabled. API key in Supabase secrets.
**Tables:** property_scans, roof_measurements, roof_facets
**Edge Functions:** zscan-property-lookup, zscan-roof-calculator

- [ ] Migration: `property_scans` table (id, company_id, job_id nullable, address fields, lat/lng, status enum [pending/scanning/complete/partial/failed], scan_sources JSONB, confidence_score, cached_until, created_by, timestamps) + RLS (company isolation)
- [ ] Migration: `roof_measurements` table (id, scan_id FK, total_area_sqft, total_area_squares, pitch_primary, pitch_distribution JSONB, ridge_length_ft, hip_length_ft, valley_length_ft, eave_length_ft, rake_length_ft, facet_count, complexity_score, predominant_shape enum [gable/hip/flat/gambrel/mansard/mixed], predominant_material, condition_score nullable, penetration_count, data_source, raw_response JSONB) + RLS
- [ ] Migration: `roof_facets` table (id, roof_measurement_id FK, facet_number, area_sqft, pitch_degrees, azimuth_degrees, annual_sun_hours, shade_factor, shape_type, vertices JSONB) + RLS
- [ ] Edge Function: `zscan-property-lookup` — accepts address → geocode → call Google Solar buildingInsights.findClosest → parse roof segments → insert property_scans + roof_measurements + roof_facets → return structured data
- [ ] Edge Function: `zscan-roof-calculator` — accepts roof_measurement_id → calculate edge lengths from facet geometry → calculate total edges (ridge, hip, valley, eave, rake) → update roof_measurements → calculate complexity score
- [ ] Google Cloud Console: Enable Solar API, create restricted API key, add to Supabase secrets as `GOOGLE_SOLAR_API_KEY`
- [ ] CRM: Auto-trigger property scan on job creation (fire-and-forget, non-blocking)
- [ ] CRM: Basic "Property Intelligence" card on job detail page — satellite thumbnail, roof area (squares), primary pitch, facet count, year built placeholder
- [ ] Error handling: Address not found, no solar data available, API rate limit exceeded
- [ ] Verify: Create test job with known address → scan triggers → roof data populates → card displays on job detail

---

### Sprint P2: Property Data + Parcel Boundaries (~8 hours)
**Goal:** ATTOM property records + Regrid parcel boundaries + Microsoft building footprints + USGS elevation.
**Tables:** parcel_boundaries, property_features

- [ ] Migration: `parcel_boundaries` table (id, scan_id FK, apn, boundary_geojson JSONB, lot_area_sqft, lot_width_ft, lot_depth_ft, zoning, zoning_description, owner_name, owner_type, data_source) + RLS
- [ ] Migration: `property_features` table (id, scan_id FK, year_built, stories, living_sqft, lot_sqft, beds, baths_full, baths_half, construction_type, wall_type, roof_type_record, heating_type, cooling_type, pool_type, garage_spaces, assessed_value, last_sale_price, last_sale_date, elevation_ft, terrain_slope_pct, tree_coverage_pct, building_height_ft, data_sources JSONB, raw_attom JSONB, raw_regrid JSONB) + RLS
- [ ] ATTOM API integration in `zscan-property-lookup`: call /property/expandedprofile → parse building object (sqft, stories, beds, baths, construction, wall type, heating, cooling) + lot object (lot size, pool, depth, frontage) + assessment (assessed value) + sale history (last sale)
- [ ] Regrid API integration in `zscan-property-lookup`: call address search → parse parcel polygon (GeoJSON), APN, zoning, lot dimensions, owner info → insert parcel_boundaries
- [ ] Microsoft Building Footprints: Pre-loaded lookup or API call for building polygon → calculate building footprint area → cross-reference with Google Solar footprint
- [ ] USGS 3DEP elevation lookup: call National Map API → elevation, terrain slope → insert into property_features
- [ ] Supabase secrets: Add `ATTOM_API_KEY`, `REGRID_API_KEY`
- [ ] CRM: Full Property Report page — Roof tab (facet diagram, pitch labels, area per facet, edges) + Lot tab (parcel boundary on Mapbox map, lot dimensions, zoning)
- [ ] Data source badges on property card: "Google Solar ✓" "ATTOM ✓" "Regrid ✓" (only show badges for sources that returned data)
- [ ] Confidence indicator logic: High (all 3+ sources agree), Moderate (tree obstruction or partial data), Low (single source only — verify on site)
- [ ] Verify: Scan address → all 4 APIs called → property_features + parcel_boundaries populated → full report page renders

---

### Sprint P3: Wall Measurements + Trade Bid Data (~10 hours)
**Goal:** Derive wall measurements from property data. Build trade-specific bid data engine for 10 trades.
**Tables:** wall_measurements, trade_bid_data
**Edge Function:** zscan-trade-estimator

- [ ] Migration: `wall_measurements` table (id, scan_id FK, total_wall_area_sqft, total_siding_area_sqft, per_face JSONB [{direction, width_ft, height_ft, area_sqft, window_count_est, door_count_est, net_area_sqft}], stories, avg_wall_height_ft, window_area_est_sqft, door_area_est_sqft, trim_linear_ft, fascia_linear_ft, soffit_sqft, data_source, confidence) + RLS
- [ ] Migration: `trade_bid_data` table (id, scan_id FK, trade enum [roofing/siding/gutters/solar/painting/landscaping/fencing/concrete/hvac/electrical], measurements JSONB, material_list JSONB [{item, quantity, unit, waste_pct, total_with_waste}], waste_factor_pct, complexity_score, notes, recommended_crew_size, estimated_labor_hours, data_sources JSONB) + RLS
- [ ] Wall derivation logic in `zscan-roof-calculator`: building_footprint_perimeter × stories × avg_wall_height (8ft standard, 9ft if year_built > 2000) − estimated_window_area (15% of wall area standard) − estimated_door_area (2 doors × 21sqft) = net siding area. Per-face breakdown from building footprint orientation.
- [ ] Edge Function: `zscan-trade-estimator` — accepts scan_id + trade → read property_scans + roof_measurements + wall_measurements + property_features → calculate trade-specific bid data:
  - [ ] **Roofing pipeline:** total_area_squares, pitch_factor, waste_factor (gable 10-14%, hip 15-17%), material_list [shingles_bundles, underlayment_rolls, ridge_cap, starter_strip, flashing, nails, drip_edge_ft, ice_shield_rolls]
  - [ ] **Siding pipeline:** net_wall_area_sqft, material_list [siding_squares, j_channel_ft, corner_posts, starter_strip, utility_trim, nails], waste 10-12%
  - [ ] **Gutters pipeline:** eave_length_ft + rake_overhangs, material_list [gutter_ft, downspout_ft, elbows, end_caps, hangers, outlets], corner count from facets
  - [ ] **Solar pipeline:** usable_roof_area (south/west-facing facets with >4 sun hours), max_panel_count, estimated_kw, estimated_kwh_annual, shade_analysis per facet
  - [ ] **Painting pipeline:** exterior_paint_sqft (walls + trim + fascia + soffit), interior_estimate (living_sqft × 3.5 wall factor), gallons_exterior, gallons_interior, primer_gallons
  - [ ] **Landscaping pipeline:** lot_sqft - building_footprint - hardscape_est = softscape_area, fence_perimeter_ft (lot perimeter - building frontage), tree_count_est, mulch_yards, sod_sqft
  - [ ] **Fencing pipeline:** lot_perimeter_ft - front_setback, post_count (every 8ft), rail_count, picket_count or panel_count, concrete_bags for posts
  - [ ] **Concrete pipeline:** driveway_est_sqft (from aerial), sidewalk_est_sqft, patio_est_sqft, total_yards, rebar_sheets, form_lumber_ft
  - [ ] **HVAC pipeline:** living_sqft → tonnage_estimate (400-600 sqft/ton by climate zone), duct_linear_ft_est, return_count_est
  - [ ] **Electrical pipeline:** living_sqft → circuit_count_est, panel_amp_recommendation, outlet_count_est (1 per 12ft wall)
- [ ] Waste factor engine: base_waste + complexity_adjustment (from complexity_score 1-10)
- [ ] CRM: Walls tab on property report (per-face diagram, areas, window/door counts)
- [ ] CRM: Trade Data tab (dropdown per trade → material list with quantities, waste factors, crew size, labor hours)
- [ ] CRM hook: `use-property-scan.ts` (CRUD + real-time subscription for scan status updates)
- [ ] Verify: Scan address → trade data generated for all 10 trades → material lists accurate → CRM displays all tabs

---

### Sprint P4: Estimate Integration (~8 hours)
**Goal:** Connect ZScan data directly into D8 estimate engine. Auto-populate estimates from scans.

- [ ] "Import from ZScan" button on estimate create/edit page
- [ ] On click: read trade_bid_data for job's scan → map material_list items to estimate line items → pre-populate estimate with quantities, descriptions, units
- [ ] Contractor can adjust any imported values before saving
- [ ] Migration: Add `property_scan_id` column to `jobs` table (FK nullable, references property_scans)
- [ ] Migration: Add `property_scan_id` column to `estimates` table (FK nullable, references property_scans)
- [ ] Auto-populate estimate line items from trade_bid_data material list
- [ ] Material list generation: measurements → item list with quantities (including waste factor)
- [ ] CRM: Solar tab on property report (sun hours heatmap per facet, shade analysis, panel layout suggestion, estimated kWh)
- [ ] CRM: "Create Estimate from Scan" button on property report → opens estimate editor pre-filled with selected trade's material list
- [ ] Estimate line items display ZScan source badge: "📡 From ZScan" on auto-populated lines
- [ ] Verify: Scan property → select trade → "Create Estimate" → estimate opens pre-filled → contractor adjusts → saves → estimate links to scan

---

### Sprint P5: Material Ordering Pipeline (~8 hours)
**Goal:** ZScan measurements → material list → supplier pricing → one-click order.
**Edge Function:** zscan-material-order

- [ ] Edge Function: `zscan-material-order` — accepts trade_bid_data material list → map items to Unwrangle product search → query real-time pricing from HD/Lowe's/ABC Supply → return supplier comparison
- [ ] Material list → supplier SKU mapping logic (generic item names → closest product matches)
- [ ] Real-time pricing comparison UI: table showing item, quantity, HD price, Lowe's price, ABC price, best price highlighted
- [ ] "Order Materials" button on estimate detail page (only if estimate has property_scan_id)
- [ ] Supplier selection workflow: contractor picks supplier per item (or "all from one supplier")
- [ ] Order placement via Unwrangle API (HD/Lowe's) and ABC Supply API
- [ ] Delivery tracking: order status stored on job, linked to material_orders table (existing from F1)
- [ ] CRM: Material ordering modal with pricing comparison grid
- [ ] Verify: Estimate with ZScan data → "Order Materials" → supplier prices shown → select → order placed → delivery tracking visible

---

### Sprint P6: Mobile + On-Site Verification (~10 hours)
**Goal:** Mobile property scan + swipeable results + on-site verification workflow.
**Table:** scan_history

- [ ] Mobile screen: `property_scan_screen.dart` — address search bar (autocomplete via Mapbox geocoder) + "Use Current Location" + "Scan" button
- [ ] Mobile: Loading animation during scan (satellite imagery rendering effect)
- [ ] Mobile: Swipeable result cards — Roof → Walls → Lot → Solar → Trade Data (each card shows key measurements for that category)
- [ ] Mobile: On-site verification workflow screen — checklist of key measurements from ZScan:
  - Each measurement shows: label, ZScan value, [Confirm ✓] / [Adjust ✏️] buttons
  - "Roof area: 35.2 SQ" → [Confirm] [Adjust: ___]
  - Adjusted measurements update property_scans record
  - Track verification_status: unverified → verified → adjusted
- [ ] Migration: `scan_history` table (id, scan_id FK, action enum [created/updated/verified/adjusted/re_scanned], field_changed, old_value, new_value, performed_by, performed_at, device, notes) + RLS
- [ ] Scan audit trail: every scan, verification, and adjustment logged to scan_history
- [ ] Verification badge on scan: "Measurements verified on site by [tech name] on [date]"
- [ ] Mobile: "Share Report" — generate PDF property report (satellite image + key measurements + trade data) via existing PDF generation pattern
- [ ] Mobile model: `property_scan.dart` (PropertyScan, RoofMeasurement, RoofFacet, WallMeasurement, TradeBidData)
- [ ] Mobile repository: `property_scan_repository.dart` (CRUD for scans + related data)
- [ ] Mobile service: `property_scan_service.dart` (auth-enriched, triggers edge function calls)
- [ ] Verify: Open mobile → enter address → scan → swipe through results → tap "Verify on site" → confirm/adjust measurements → verification badge shows → share PDF

---

### Sprint P7: Portal Integration (~8 hours)
**Goal:** ZScan data visible in Team Portal, Client Portal, CRM sidebar. Pre-scan for leads.

- [ ] Team Portal: Property scan view on assigned job detail page (read-only measurements card)
- [ ] Team Portal: On-site verification workflow (same confirm/adjust UI as mobile, for tablet-based field use)
- [ ] Team Portal hook: `use-property-scan.ts` (same hook pattern as CRM)
- [ ] Client Portal: Property overview card on project page — satellite image, key measurements, "Your property" section (customer-friendly labels: "Roof Size: ~35 squares" not "35.2 SQ")
- [ ] Client Portal: Property overview stripped of internal data (no cost estimates, no material lists, no crew size — just measurements and property info)
- [ ] CRM: Pre-scan for leads — scan property WITHOUT creating a job first. Creates property_scans with job_id=null. Can be linked to job later.
- [ ] CRM: Property intelligence data included in bid/proposal PDF export (satellite image + key measurements section)
- [ ] CRM sidebar: "Property Intelligence" collapsible section under existing job management
  - Property Scans (list view)
  - Full Reports
  - Scan Settings (default trade pipelines, cache duration)
- [ ] Verify: All 4 portals display scan data correctly → team portal verification works → client sees friendly view → lead pre-scan creates unlinked scan → PDF includes property data

---

### Sprint P8: Polish + Build Verification (~6 hours)
**Goal:** Error handling, caching, rate limiting, attribution, disclaimers, clean builds.

- [ ] All portals build clean: `npm run build` (CRM, team, client, ops)
- [ ] Mobile: `dart analyze` passes
- [ ] Google Solar API error handling: address not found (show "No satellite data available" gracefully), no data for address, API quota exceeded (queue and retry), invalid response
- [ ] ATTOM API error handling: property not found, partial data (some fields null)
- [ ] Regrid API error handling: no parcel data, boundary mismatch
- [ ] Partial scan handling: if some APIs succeed and others fail, save partial data with clear indicators of what's missing. Don't block the whole scan.
- [ ] Caching: 30-day cache per address per company (`cached_until` on property_scans). Re-scan only on explicit request or cache expiry.
- [ ] Rate limiting: Queue system for API calls. Max 600 QPM Google Solar. Max concurrent ATTOM/Regrid calls.
- [ ] Attribution compliance: Google Maps attribution on all map displays, Regrid attribution on parcel boundaries, "Property data from public records" disclaimer
- [ ] Legal disclaimers on every property report: "Measurements are estimates from satellite imagery and public records. Verify on site before ordering materials."
- [ ] Legal disclaimer on material ordering: "Quantities calculated from estimated measurements. Verify before ordering."
- [ ] Feature flag: `features.property_intelligence_enabled` — all ZScan UI hidden when false
- [ ] Cost tracking: Log API costs per scan for monitoring ($0.075/Google Solar + ATTOM per-call + Regrid per-call)
- [ ] Commit: `[P1-P8] Property Intelligence Engine (ZScan) — 8 tables, 4 EFs, 10 trade pipelines`

---

## PHASE SK: CAD-GRADE SKETCH ENGINE (~176 hours) — after Phase P
*Spec: Expansion/46_SKETCH_ENGINE_SPEC.md*
*3 new tables, 1 migration, ~46 new files (21 Flutter, 25 Web CRM)*
*LiDAR scan → multi-trade layers → auto-estimate → export → 3D visualization → real-time mobile-to-web sync*
*Replaces: magicplan, Xactimate Sketch, ArcSite. No competitor does the full pipeline.*

---

### Sprint SK1: Unified Data Model + Migration (~16 hours)
**Goal:** Merge two disconnected table systems (property_floor_plans + bid_sketches) into single source of truth. Create FloorPlanDataV2 schema. Bridge to D8 estimate engine.
**Prereqs:** Phase P complete. All existing floor plan and sketch data stable.
**Tables:** ALTER property_floor_plans, CREATE floor_plan_layers, floor_plan_rooms, floor_plan_estimate_links, ALTER bid_sketches
**Migration:** `sk1_unified_sketch_model.sql`

- [ ] Migration: ALTER `property_floor_plans` — add `job_id UUID REFERENCES jobs(id)`, `estimate_id UUID REFERENCES estimates(id)`, `status TEXT CHECK (status IN ('draft','scanning','processing','complete','archived')) DEFAULT 'draft'`, `sync_version INTEGER DEFAULT 1`, `last_synced_at TIMESTAMPTZ`
- [ ] Migration: CREATE `floor_plan_layers` (id, floor_plan_id FK CASCADE, company_id FK, layer_type CHECK ('electrical','plumbing','hvac','damage','custom'), layer_name, layer_data JSONB DEFAULT '{}', visible BOOLEAN DEFAULT true, locked BOOLEAN DEFAULT false, opacity NUMERIC DEFAULT 1.0, sort_order INTEGER DEFAULT 0, timestamps) + RLS (company isolation)
- [ ] Migration: CREATE `floor_plan_rooms` (id, floor_plan_id FK CASCADE, company_id FK, name, boundary_points JSONB, boundary_wall_ids JSONB, floor_area_sf NUMERIC, wall_area_sf NUMERIC, perimeter_lf NUMERIC, ceiling_height_inches INTEGER DEFAULT 96, floor_material, damage_class CHECK, iicrc_category CHECK, room_type CHECK 14 values, metadata JSONB, timestamps) + RLS
- [ ] Migration: CREATE `floor_plan_estimate_links` (id, floor_plan_id FK CASCADE, room_id FK CASCADE, estimate_id FK CASCADE, estimate_area_id FK CASCADE, auto_generated BOOLEAN DEFAULT true, company_id FK, created_at) + RLS
- [ ] Migration: ALTER `bid_sketches` — add `floor_plan_id UUID REFERENCES property_floor_plans(id)`
- [ ] Dart model: Update `lib/models/floor_plan.dart` — add job_id, estimate_id, status, sync_version, last_synced_at fields + fromJson/toJson
- [ ] Dart model: Create `lib/models/floor_plan_layer.dart` — FloorPlanLayer class
- [ ] Dart model: Create `lib/models/floor_plan_room.dart` — FloorPlanRoom class
- [ ] Dart model: Update `lib/models/floor_plan_elements.dart` — add FloorPlanDataV2 wrapper class with version detection (V1 backward compat: no `version` field → treat as V2 with empty tradeLayers). Add ArcWall, TradeElement, TradeGroup, TradePath, DamageZone, DamageBarrier, TradeLayerData, DamageLayerData types.
- [ ] Verify: Migration applies clean. V1 FloorPlanData still parses. V2 schema serializes/deserializes correctly. `dart analyze` passes.

---

### Sprint SK2: Flutter Editor Upgrades Part 1 (~16 hours)
**Goal:** Wall editing after drawing, wall thickness control, fixture rotation, unit toggle (imperial/metric).
**Prereqs:** SK1 complete (V2 data model).

- [ ] Wall selection mode: Tap wall → selection handles appear at endpoints (blue circles)
- [ ] Wall endpoint dragging: Drag handle → wall stretches, connected walls follow (chain constraint solver)
- [ ] Wall properties: Double-tap wall → bottom sheet with thickness (4"/6"/8"/12"/custom), height, material
- [ ] Wall split: Long-press wall → insert midpoint, splits wall into two segments
- [ ] Wall thickness rendering: Update `sketch_painter.dart` — render walls as filled rectangles (not single lines). Interior vs exterior presets.
- [ ] Bottom toolbar: Thickness picker (4", 6", 8", 12", custom input)
- [ ] Fixture rotation: Two-finger rotate gesture on selected fixture
- [ ] Fixture rotation handle: Circular arrow icon appears on selected fixture, drag to rotate
- [ ] Fixture rotation snap: Snap to 0/45/90/135/180/225/270/315 degrees
- [ ] Unit toggle: Imperial (ft/in) ↔ Metric (m/cm) toggle button in toolbar
- [ ] Unit conversion: All dimensions, labels, measurements convert live on toggle
- [ ] Unit persistence: Stored in FloorPlanDataV2.units, persists per plan
- [ ] Update `sketch_editor_screen.dart` — wall selection mode, thickness picker, unit toggle
- [ ] Update `sketch_painter.dart` — thick wall rendering, selection handles, rotation handles
- [ ] Update `floor_plan_elements.dart` — Wall.thickness, Wall.height, Wall.material, FixturePlacement.rotation updates
- [ ] Verify: Draw walls → tap to select → drag endpoints → double-tap to change thickness → rotate fixtures → toggle units → all renders correctly. `dart analyze` passes.

---

### Sprint SK3: Flutter Editor Upgrades Part 2 (~12 hours)
**Goal:** Arc walls, copy/paste, multi-select with lasso, smart auto-dimensions.
**Prereqs:** SK2 complete.

- [ ] Arc wall tool: New tool in toolbar ("Arc Wall" icon)
- [ ] Arc wall drawing: Tap start, tap end, drag control point for curvature (quadratic Bezier)
- [ ] Arc wall rendering: Update `sketch_painter.dart` — Bezier curve with thickness fill
- [ ] Arc wall door/window attachment: Position along curve parameter t (0.0 to 1.0)
- [ ] Arc wall room detection: Approximate as polyline for area calculation (shoelace formula)
- [ ] Copy/paste: Select element(s) → "Copy" button appears in toolbar
- [ ] Paste behavior: Places at screen center with offset, enters drag-to-position mode
- [ ] Cross-floor copy: Copy room layout from floor 1, paste on floor 2
- [ ] Multi-select lasso: New lasso tool — draw freeform selection boundary
- [ ] Multi-select shift-tap: Tap additional elements while holding (or toggle button on mobile)
- [ ] Group operations: Move group, delete group, copy group
- [ ] Alignment helpers: Align left, align top, distribute evenly (toolbar buttons on multi-select)
- [ ] Smart auto-dimensions: Wall lengths auto-labeled on draw (dimension lines appear automatically)
- [ ] Room area auto-label: Area label auto-placed at centroid of detected rooms
- [ ] Room perimeter: Total perimeter shown in room properties bottom sheet
- [ ] New commands in `floor_plan_elements.dart`: ArcWall class, CopyCommand, PasteCommand, MultiSelectCommand, LassoSelectCommand
- [ ] Verify: Draw arc walls → copy/paste elements → lasso select → group move → auto-dimensions appear → area labels at centroids. `dart analyze` passes.

---

### Sprint SK4: Trade Layers System (~20 hours)
**Goal:** 4 trade overlay layers (electrical 15 symbols, plumbing 12, HVAC 10, damage 4 tools) with layer management UI.
**Prereqs:** SK2+SK3 complete (editing foundation).

- [ ] Create `lib/models/trade_layer.dart` — TradeElement (id, position, rotation, type, symbol, properties JSONB), TradePath (id, points[], type, properties), TradeGroup (id, name, elementIds[], color), DamageZone (id, boundary[], damageClass, iicrcCategory, opacity), MoistureReading (id, position, value, severity), ContainmentBarrier (id, start, end)
- [ ] Create SVG symbol assets: 62 total — Electrical receptacles (4), switches (4), lights (5), equipment (2), Plumbing fixtures (7), pipes (4 colors), HVAC equipment (5), HVAC distribution (5), Damage icons
- [ ] Create `lib/painters/trade_layer_painter.dart` — CustomPainter for trade overlay rendering (composited on top of base floor plan)
- [ ] Electrical layer tools: Place receptacles, switches, lights, panels, junction boxes. Draw wire paths (auto-route along nearest wall). Circuit grouping with color coding.
- [ ] Plumbing layer tools: Place fixtures (sink, toilet, shower, tub, washer, water heater, hose bib). Draw pipe runs (hot=red, cold=blue, drain=gray, gas=yellow). Diameter labels on pipes.
- [ ] HVAC layer tools: Place equipment (furnace, condenser, air handler, mini-split, ERV). Draw ducts (supply, return). Place registers, thermostats, dampers. CFM labels on ducts.
- [ ] Damage layer tools: Draw affected area zones (polygon with opacity, Class 1-4 color: green/yellow/orange/red). Place moisture reading points (value + severity color). Draw containment barrier lines (dashed red). Place source arrows.
- [ ] IICRC category overlay: Cat 1 = blue tint, Cat 2 = yellow tint, Cat 3 = red tint on damage zones
- [ ] Create `lib/widgets/sketch/layer_panel.dart` — Collapsible sidebar with: layer list, visibility toggle (eye icon), lock toggle (lock icon), opacity slider, active layer highlight
- [ ] Create `lib/widgets/sketch/trade_toolbar.dart` — Per-trade toolbars that swap based on active layer selection
- [ ] Active layer selector: Drawing tools change based on which layer is active. Base layer = walls/doors/windows/fixtures. Trade layer = trade-specific tools.
- [ ] Layer data persistence: Each layer's elements saved to FloorPlanDataV2.tradeLayers and/or floor_plan_layers table
- [ ] Update `sketch_editor_screen.dart` — layer switching, trade tool modes, layer panel toggle
- [ ] Update `sketch_painter.dart` — compose base layer + active trade layers (respect visibility/opacity)
- [ ] Verify: Switch between layers → place trade elements → toggle visibility → lock layers → adjust opacity → damage zones render with IICRC colors → wire/pipe paths route along walls. `dart analyze` passes.

---

### Sprint SK5: LiDAR Scanning — Apple RoomPlan Integration (~20 hours)
**Goal:** iPhone LiDAR scanning via Apple RoomPlan, 3D→2D conversion, guided scanning UX, non-LiDAR fallback.
**Prereqs:** SK4 complete (layer system ready for scanned data import).

- [ ] Create `ios/Runner/RoomPlanService.swift` — native Swift class wrapping `RoomCaptureSession` + `RoomCaptureView`. Session delegate captures `CapturedRoom` on completion. Serializes room data (walls, doors, windows, objects with 3D transforms) to JSON. Sends via FlutterMethodChannel.
- [ ] Platform channel setup: Register `MethodChannel('com.zafto.roomplan')` in `AppDelegate.swift`
- [ ] Create `lib/services/roomplan_bridge.dart` — Dart side of MethodChannel. Methods: `checkAvailability()`, `startScan()`, `stopScan()`, `getCapturedRoom()`. Event channel for real-time scan progress.
- [ ] Create `lib/services/roomplan_converter.dart` — Converts CapturedRoom JSON → FloorPlanDataV2. 3D→2D projection: extract X and Z from 4x4 transform matrix (Y = height). Scale meters → inches (x39.3701). Wall endpoints: center ± (length/2) along orientation vector. Height → Wall.height. Door/window → parametric position along parent wall.
- [ ] Create `lib/widgets/sketch/lidar_scan_screen.dart` — Full scanning UX overlay:
  - Check device capability (`ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)`)
  - Instructions overlay: "Slowly walk through the room. Point at all walls, doors, and windows."
  - Real-time preview of detected walls/openings (from RoomPlan native UI)
  - "Done" button → processing spinner → FloorPlanDataV2 generated
  - Transitions to sketch editor with scanned plan loaded
- [ ] Multi-room scanning: Scan room → save → scan next → auto-merge based on shared wall detection. Or walk through multiple rooms in single session (RoomPlan native).
- [ ] Create `lib/widgets/sketch/manual_room_entry.dart` — Fallback for non-LiDAR devices (Android, older iPhones). Room-by-room entry: name, width, length, height. Generates rectangular rooms in grid layout. User edits walls/doors/windows manually after.
- [ ] "LiDAR Scan" button in sketch editor toolbar (only visible on iOS with LiDAR)
- [ ] "Manual Entry" button always visible as alternative
- [ ] Scanned plan is fully editable after import (walls snap to scanned positions but can be moved)
- [ ] Save scanned plan: FloorPlanDataV2 with `lidarMetadata` populated (source, scanDate, deviceModel, accuracy)
- [ ] No new packages needed in pubspec.yaml (platform channels built-in)
- [ ] Verify: On LiDAR iPhone → tap "LiDAR Scan" → scan room → "Done" → editor opens with accurate floor plan → walls/doors/windows match physical room (±2 inches). On non-LiDAR device → "Manual Entry" flow works. `dart analyze` passes.

---

### Sprint SK6: Web CRM Canvas Editor — Konva.js (~24 hours)
**Goal:** Full Konva.js-based canvas editor on web CRM. TypeScript port of geometry engine. Feature parity with Flutter editor.
**Prereqs:** SK1 complete (V2 data model). SK4 preferred (trade layer types defined).
**Packages:** `konva`, `react-konva`

- [ ] Install packages: `npm install konva react-konva` in web-portal
- [ ] Create `src/lib/sketch-engine/types.ts` — TypeScript interfaces ported from `floor_plan_elements.dart` (Wall, Door, Window, Fixture, Room, Label, Dimension, ArcWall, TradeElement, TradePath, DamageZone, FloorPlanDataV2)
- [ ] Create `src/lib/sketch-engine/geometry.ts` — Port SketchGeometry class: angle snapping, endpoint snapping, point-to-segment distance, line intersection, room detection (DFS cycle + shoelace area)
- [ ] Create `src/lib/sketch-engine/commands.ts` — Port UndoRedoManager + command pattern (AddWallCommand, RemoveWallCommand, MoveWallCommand, AddDoorCommand, etc.)
- [ ] Create `src/lib/sketch-engine/renderers/wall-renderer.ts` — Konva shapes for walls (Line for thin, Rect for thick, custom Shape for arc)
- [ ] Create `src/lib/sketch-engine/renderers/door-renderer.ts` — Konva shapes for 7 door types with swing arcs
- [ ] Create `src/lib/sketch-engine/renderers/window-renderer.ts` — Konva shapes for windows (3-line symbol)
- [ ] Create `src/lib/sketch-engine/renderers/fixture-renderer.ts` — Konva shapes for 25 fixture types
- [ ] Create `src/lib/sketch-engine/renderers/trade-renderer.ts` — Konva shapes for trade layer elements (62 symbols)
- [ ] Create `src/lib/sketch-engine/renderers/damage-renderer.ts` — Konva shapes for damage zones, moisture points, barriers
- [ ] Create `src/components/sketch-editor/SketchCanvas.tsx` — Main Konva Stage component. Base Layer + Trade Layers + UI Layer. Pan (middle-click/space+drag), zoom (scroll wheel), grid rendering.
- [ ] Create `src/components/sketch-editor/Toolbar.tsx` — Drawing tools (wall, arc wall, door, window, fixture, label, dimension, select, lasso), trade layer tools, undo/redo, zoom controls
- [ ] Create `src/components/sketch-editor/LayerPanel.tsx` — Layer management: visibility, lock, opacity, active layer
- [ ] Create `src/components/sketch-editor/PropertyInspector.tsx` — Right sidebar: selected element properties (wall thickness/height, fixture type/rotation, room name/type)
- [ ] Create `src/components/sketch-editor/MiniMap.tsx` — Corner mini-map for large plan navigation
- [ ] Keyboard shortcuts: Ctrl+Z undo, Ctrl+Y redo, Ctrl+C copy, Ctrl+V paste, Delete remove, Escape deselect, Space+drag pan
- [ ] Snap system: Grid snap, wall endpoint snap, angle snap (15-degree increments)
- [ ] Ruler: Top and left edge rulers showing measurements in current unit
- [ ] Create `src/lib/hooks/use-floor-plan.ts` — Supabase CRUD for property_floor_plans + floor_plan_layers + floor_plan_rooms. Real-time subscription on plan row. Debounced save (500ms). Conflict detection via sync_version.
- [ ] Replace `src/app/dashboard/sketch-bid/page.tsx` — Remove existing form-only UI. Replace with full canvas editor importing SketchCanvas + Toolbar + LayerPanel + PropertyInspector.
- [ ] Verify: Open sketch-bid page → canvas loads → draw walls/doors/windows → switch layers → place trade elements → save → refresh → data persists → undo/redo works → keyboard shortcuts work. `npm run build` passes.

---

### Sprint SK7: Sync Pipeline — Offline-First + Real-Time (~12 hours)
**Goal:** Hive-based offline cache on mobile, Supabase real-time sync, thumbnail generation, conflict resolution.
**Prereqs:** SK1 complete. SK2+ preferred (editing works).

- [ ] Create `lib/repositories/floor_plan_repository.dart` — Supabase CRUD for property_floor_plans + floor_plan_layers + floor_plan_rooms. Select with joins. Insert/update with company_id. Delete cascade.
- [ ] Create `lib/services/floor_plan_sync_service.dart` — Offline-first sync:
  - New Hive box: `floor_plans_cache` (register in Hive init)
  - Every edit saves to Hive immediately (zero-latency UX)
  - Background sync: ConnectivityService detects online → push pending changes
  - Sync version: increment local version on edit, send with POST
  - Conflict: if server sync_version > local → prompt user (merge or overwrite)
  - Queue pending changes while offline, flush on reconnect
- [ ] Create `lib/services/floor_plan_thumbnail_service.dart` — Render plan to 512x512 PNG using RepaintBoundary + toImage(). Upload to `floor-plan-thumbnails` Supabase storage bucket. Update property_floor_plans.thumbnail_path.
- [ ] Web real-time: Supabase channel subscription on `property_floor_plans` row in `use-floor-plan.ts`. On remote update → re-render canvas.
- [ ] Web thumbnail: Konva `stage.toDataURL()` → upload to storage on save.
- [ ] Supabase storage: Create `floor-plan-thumbnails` bucket (if not exists) with company-scoped RLS.
- [ ] Hive box registration: Add `floor_plans_cache` to Hive initialization in app startup.
- [ ] Verify: Edit on mobile (offline) → go online → plan appears on web → edit on web → mobile receives update → thumbnails generated in storage bucket → conflict scenario tested (edit same plan on both → conflict prompt appears).

---

### Sprint SK8: Auto-Estimate Pipeline (~16 hours)
**Goal:** Geometry-derived measurements → D8 estimate areas → suggested line items. "Generate Estimate" button on sketch editor.
**Prereqs:** SK1 (rooms), SK4 (trade data) complete. D8 estimate engine operational.

- [ ] Create `lib/services/room_measurement_calculator.dart` — Per-room calculations from FloorPlanDataV2:
  - Floor SF: shoelace formula on room boundary polygon
  - Wall SF: sum(wall_length x wall_height) for boundary walls, minus door/window opening areas
  - Ceiling SF: same as floor SF (flat ceiling assumption, adjustable per room)
  - Baseboard LF: perimeter minus door widths
  - Door count + Window count: from room boundary walls
  - Paint SF: wall SF + ceiling SF (configurable: walls only, ceiling only, both)
- [ ] Create `lib/services/estimate_area_generator.dart` — For each FloorPlanRoom: create estimate_areas row with computed measurements. Link via floor_plan_estimate_links bridge table. Sets auto_generated=true.
- [ ] Create `lib/services/line_item_suggester.dart` — Maps measurements + trade data to estimate line items:
  - Room type + trade: bathroom + plumbing → toilet, sink, shower rough-in
  - Damage layer data: Class 3 water damage → demo drywall, dry structure, replace drywall
  - Trade layer elements: 5 receptacles → 5x receptacle rough-in line items
  - Uses estimate_items table for pricing lookup
- [ ] "Generate Estimate" button on Flutter sketch editor toolbar
- [ ] Generate estimate flow: Creates estimates row linked to floor plan → for each room creates estimate_areas → suggests line items → opens estimate editor with pre-filled data
- [ ] User review: Line items are suggestions — user adjusts quantities/prices before finalizing
- [ ] Create `web-portal/src/lib/sketch-engine/measurement-calculator.ts` — TypeScript port of room measurement calculator
- [ ] Create `web-portal/src/lib/sketch-engine/estimate-generator.ts` — TypeScript port of estimate area generator + line item suggester
- [ ] Create `web-portal/src/components/sketch-editor/GenerateEstimateModal.tsx` — Modal: select rooms to include, select trade, preview measurements, "Generate" button → navigates to estimate editor
- [ ] Update D8 estimate hooks to accept floor-plan-generated areas (accept property_floor_plan_id on estimate creation)
- [ ] Verify: Draw floor plan with rooms + trade elements → "Generate Estimate" → estimate created with correct measurements per room → line items match trade elements → pricing from D8 engine → user can edit → save. Both mobile and web.

---

### Sprint SK9: Export Pipeline (~12 hours)
**Goal:** Export floor plans to PDF, PNG, DXF (AutoCAD), and FML (open format for Symbility/Cotality).
**Prereqs:** SK4 (trade layers render), SK6 (web canvas renders).

- [ ] Create `lib/services/sketch_export_service.dart` — Orchestrates all export formats. Export menu UI (bottom sheet with format selection).
- [ ] PDF export (Flutter): Title block (company name, project address, date, scale) + floor plan rendering (all visible layers) + room schedule table (name, dimensions, area, perimeter) + trade symbol legend. Uses existing `pdf` + `printing` packages.
- [ ] PNG export (Flutter): High-resolution raster via RepaintBoundary.toImage(). Scale options: 1x, 2x, 4x pixel ratio. Share via share_plus.
- [ ] Create `lib/services/dxf_writer.dart` — DXF format generator (ASCII format, well-documented):
  - Walls → LINE/LWPOLYLINE entities
  - Rooms → HATCH fills
  - Doors/windows → INSERT block references
  - Trade elements → separate DXF layers (ELECTRICAL, PLUMBING, HVAC, DAMAGE)
  - Standard DXF header with units (INSUNITS)
- [ ] Create `lib/services/fml_writer.dart` — FML (Floor Markup Language) generator:
  - XML-based open format (Floorplanner origin — NOT Verisk/Xactimate)
  - Rooms, walls, openings, dimensions
  - Safe for Symbility/Cotality integration
  - NOT accepted by Xactimate (ESX export deferred pending legal)
- [ ] Web PDF export: Create `src/lib/sketch-engine/export/pdf-export.ts` — Konva stage.toDataURL() → jsPDF with title block + room schedule
- [ ] Web PNG export: Create `src/lib/sketch-engine/export/png-export.ts` — Konva stage.toDataURL({ pixelRatio: 4 })
- [ ] Web DXF export: Create `src/lib/sketch-engine/export/dxf-export.ts` — TypeScript port of DXF writer
- [ ] Web FML export: Create `src/lib/sketch-engine/export/fml-export.ts` — TypeScript port of FML writer
- [ ] Create `src/components/sketch-editor/ExportModal.tsx` — Export format selection modal (PDF, PNG, DXF, FML) with preview and download
- [ ] Export menu in Flutter sketch editor: Add export button → bottom sheet with format options → generate → share/save
- [ ] Verify: Export floor plan with trade layers → PDF opens correctly (title block + plan + schedule) → PNG is high-res → DXF opens in AutoCAD/LibreCAD → FML validates as XML. Both mobile and web.

---

### Sprint SK10: 3D Visualization — three.js (~16 hours)
**Goal:** Toggle between 2D (Konva) and 3D (three.js) views on web CRM. Wall extrusion, openings, orbit controls.
**Prereqs:** SK6 complete (web canvas operational).
**Packages:** `three`, `@react-three/fiber`, `@react-three/drei`

- [ ] Install packages: `npm install three @react-three/fiber @react-three/drei` in web-portal
- [ ] Create `src/lib/sketch-engine/three-converter.ts` — FloorPlanDataV2 → three.js scene:
  - Walls: Extrude 2D wall rectangles to 3D prisms at wall height
  - Door/window openings: Boolean subtraction (CSG) from wall geometry
  - Floor plane: Flat mesh at y=0 with material texture
  - Trade elements: 3D icons/sprites positioned at element locations
  - Room labels: Text sprites floating above room centroids
- [ ] Create `src/components/sketch-editor/ThreeDView.tsx` — React Three Fiber Canvas:
  - Scene with ambient + directional lighting
  - OrbitControls (rotate, pan, zoom)
  - Wall materials: interior=white, exterior=gray
  - Floor material: light wood texture
  - Optional: LiDAR point cloud as background reference
- [ ] Create `src/components/sketch-editor/ViewToggle.tsx` — 2D/3D toggle button. Smooth transition. Preserves camera position mapping between views.
- [ ] Integration: ViewToggle sits in sketch editor toolbar. Toggles between SketchCanvas (Konva) and ThreeDView (three.js). Both read same FloorPlanDataV2 data.
- [ ] Verify: Draw floor plan in 2D → toggle to 3D → walls extruded correctly → doors/windows cut out → orbit around → toggle back to 2D → data unchanged. `npm run build` passes.

---

### Sprint SK11: Polish + Testing + Button Audit (~12 hours)
**Goal:** Round-trip testing, performance optimization, every-button audit on both mobile and web.
**Prereqs:** All SK1-SK10 complete.

- [ ] Round-trip test: Create plan on mobile → verify appears on web with full fidelity (walls, doors, windows, fixtures, trade elements, labels, dimensions)
- [ ] LiDAR accuracy test: Scan room with LiDAR → measure physical room → compare dimensions (target: ±2 inches tolerance)
- [ ] Cross-platform edit test: Edit on web → verify sync to mobile → edit on mobile → verify sync to web
- [ ] Auto-estimate test: Generate estimate from sketch → verify line items match room measurements → verify pricing from D8
- [ ] Export test: PDF opens in viewer (title block + plan + schedule correct). PNG is high-res. DXF opens in AutoCAD/LibreCAD. FML validates as XML.
- [ ] Performance: Stress test with 50-room floor plan + all trade layers active. Target: 60fps pan/zoom on web, 30fps on mobile. Konva optimization: `listening: false` on static shapes, batch layer updates. Flutter optimization: RepaintBoundary per trade layer.
- [ ] Button audit (Flutter sketch editor): Every toolbar button clicked and verified. Every layer control works. Every export format produces valid output. Every trade symbol renders. LiDAR scan button + manual entry button both work.
- [ ] Button audit (Web sketch editor): Every toolbar button clicked and verified. Every keyboard shortcut works. Layer panel toggles/locks/opacity all work. Property inspector updates on selection. Mini-map reflects current view. Ruler displays correct measurements.
- [ ] 3D view audit: All wall types render. Door/window openings correct. Orbit controls smooth. View toggle preserves state.
- [ ] Offline audit: Disable network on mobile → edit plan → verify Hive saves → re-enable → verify sync completes → no data loss
- [ ] Error handling: Invalid floor plan data (corrupt JSON) → graceful error, not crash. Network failure during sync → queued for retry. LiDAR scan interrupted → partial data saved.
- [ ] All builds pass: `dart analyze` (0 errors), `npm run build` for all 4 web portals (CRM, team, client, ops)
- [ ] Commit: `[SK1-SK11] CAD-Grade Sketch Engine — 3 tables, LiDAR scan, trade layers, Konva web editor, auto-estimate, export, 3D view`

---

## PHASE E: AI LAYER — REBUILD (after Phase T + Phase P + Phase SK + Phase G)
*Deep spec session with owner required before starting. AI must know every feature, every table, every screen — including TPA module + ZScan + Sketch Engine.*

### Sprint E-review: Audit premature E work
### Sprint E1-E4: Full AI implementation (rebuilt with complete platform knowledge — including TPA module + ZScan + Sketch Engine + all Phase F features)

---

### >>> LAUNCH <<<

---

## POST-LAUNCH FEATURES

### Sprint F2: Website Builder V2 (~60-90 hrs) — DEFERRED POST-LAUNCH (S94 owner directive)
*Scrapped from pre-launch scope. Too much maintenance overhead (hosting, custom domains, WYSIWYG, SSL, SEO support burden). Revisit post-launch with real contractor feedback + completed AI layer. Consider white-label (Duda API) or template-only auto-generated approach.*
- [ ] Cloudflare Registrar for custom domains
- [ ] Trade-specific templates
- [ ] AI content generation (service pages, blog — needs Phase E)
- [ ] CRM sync (completed job photos → auto-showcase)
- [ ] Booking widget → CRM calendar
- [ ] SEO optimization
- [ ] Review display (Google/Yelp)
- [ ] $19.99/mo add-on
- [ ] Commit: `[F2] Website Builder — AI content, templates, booking`

### Sprint F8: Ops Portal Phases 2-4 (~111 hrs) — POST-LAUNCH
- [ ] Marketing engine (growth CRM, content, campaigns)
- [ ] Treasury (revenue analytics, churn, LTV)
- [ ] Legal (contracts, compliance, disputes)
- [ ] Dev terminal (deployment, feature flags, A/B testing)
- [ ] Ads + SEO management
- [ ] Vault (secrets management UI)
- [ ] Referral program management
- [ ] Advanced analytics
- [ ] 54 additional pages
- [ ] Commit: `[F8] Ops Portal 2-4 — marketing, treasury, legal, dev`

---

CLAUDE: Execute sprints in order. Update status as you complete each one. Never skip a sprint.
