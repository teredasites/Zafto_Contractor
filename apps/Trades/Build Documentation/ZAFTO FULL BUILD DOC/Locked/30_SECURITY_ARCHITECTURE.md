# ZAFTO SECURITY ARCHITECTURE
## Enterprise-Grade Security Without Enterprise Complexity
### February 5, 2026 — Session 29

---

## EXECUTIVE PRINCIPLE

**Security lives in the DATABASE, not the app.**

If app code has a bug, the database still protects the data.
If someone bypasses the UI, the database still enforces rules.
If a developer makes a mistake, the database still blocks unauthorized access.

PostgreSQL Row-Level Security (RLS) is the foundation. Everything else is layered on top.

**The rule:** CIA-level safety. Zero overcomplification. Zero additional bugs.

---

## THE 6 SECURITY LAYERS

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│  LAYER 1: AUTHENTICATION (Who are you?)                                        │
│  ───────────────────────────────────────                                        │
│  Supabase Auth — JWT tokens, MFA, session management                           │
│                                                                                 │
│  LAYER 2: AUTHORIZATION (What can you do?)                                     │
│  ──────────────────────────────────────────                                     │
│  Role-Based Access Control — Owner/Admin/Office/Tech/CPA/Client                │
│                                                                                 │
│  LAYER 3: TENANT ISOLATION (Whose data can you see?)                           │
│  ─────────────────────────────────────────────────────                          │
│  PostgreSQL RLS — Every query auto-filtered by company_id                      │
│                                                                                 │
│  LAYER 4: DATA PROTECTION (How is data stored?)                                │
│  ──────────────────────────────────────────────                                 │
│  Encryption at rest + in transit + field-level for PII                          │
│                                                                                 │
│  LAYER 5: AUDIT & MONITORING (Who did what, when?)                             │
│  ──────────────────────────────────────────────────                             │
│  Append-only audit log, login tracking, anomaly alerts                         │
│                                                                                 │
│  LAYER 6: NETWORK & INFRASTRUCTURE (How is it protected?)                      │
│  ─────────────────────────────────────────────────────────                      │
│  Cloudflare WAF, rate limiting, DDoS protection, CSP headers                   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## LAYER 1: AUTHENTICATION

### Provider: Supabase Auth

| Feature | Implementation | Notes |
|---------|---------------|-------|
| Email/password | Supabase built-in | Bcrypt hashed, salted |
| Google OAuth | Supabase built-in | Contractor + CPA login |
| Apple OAuth | Supabase built-in | Required for iOS App Store |
| Phone/SMS (OTP) | Supabase + Twilio | For field techs without email |
| Biometric | Flutter local_auth | Fingerprint/Face ID on device |
| Magic links | Supabase built-in | Passwordless option |

### Multi-Factor Authentication (MFA)

```
WHO MUST USE MFA:
─────────────────
• Owner accounts — REQUIRED (controls everything)
• Admin accounts — REQUIRED (near-full access)
• CPA accounts — REQUIRED (access to multiple companies)
• Office staff — OPTIONAL (encouraged)
• Field techs — OPTIONAL (biometric on device is sufficient)
• Client portal — OPTIONAL

MFA METHODS:
────────────
• TOTP (authenticator app) — Primary
• SMS OTP — Fallback
• Biometric — Device-level (not server MFA, but adds physical security)
```

### Session Management

```sql
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  device_id TEXT,                    -- Unique device identifier
  device_name TEXT,                  -- "Robert's iPhone 15"
  ip_address INET,
  user_agent TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_revoked BOOLEAN DEFAULT FALSE,
  revoked_reason TEXT,               -- "manual", "password_change", "suspicious"
  mfa_verified BOOLEAN DEFAULT FALSE
);

-- Auto-expire sessions
-- Mobile: 30 days (with biometric refresh)
-- Web CRM: 8 hours idle timeout
-- CPA Portal: 4 hours idle timeout (stricter — multi-company access)
-- Client Portal: 30 days
```

### Brute Force Protection

```sql
CREATE TABLE login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_address INET NOT NULL,
  success BOOLEAN NOT NULL,
  failure_reason TEXT,               -- "wrong_password", "account_locked", "mfa_failed"
  attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- LOCKOUT RULES:
-- 5 failed attempts in 15 minutes → Lock account for 15 minutes
-- 10 failed attempts in 1 hour → Lock account for 1 hour + email owner
-- 20 failed attempts in 24 hours → Lock account + require email verification
-- Any failed attempt from new country → Email alert to account owner
```

### Password Policy

```
REQUIREMENTS:
• Minimum 10 characters
• At least 1 uppercase, 1 lowercase, 1 number
• Not in top 10,000 breached passwords list
• Cannot reuse last 5 passwords
• No forced expiry (NIST 800-63B recommendation — forced rotation causes weaker passwords)
```

---

## LAYER 2: AUTHORIZATION (RBAC)

### Role Definitions

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ROLE HIERARCHY                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  OWNER                                                                         │
│  └── Full control. Billing. Delete company. Transfer ownership.                │
│      Only role that can see SSNs and bank accounts.                            │
│      Only role that can manage subscription and payment methods.               │
│                                                                                 │
│  ADMIN                                                                         │
│  └── Everything except: billing, delete company, view SSNs/bank info.          │
│      Can manage users, roles, settings.                                        │
│      Can view all financials (revenue, costs, margins).                        │
│                                                                                 │
│  OFFICE                                                                        │
│  └── CRM operations: customers, jobs, bids, invoices, scheduling.             │
│      Can view financial totals but NOT employee PII.                           │
│      Cannot change company settings or manage users.                           │
│                                                                                 │
│  TECH (Field Technician)                                                       │
│  └── Own assigned jobs ONLY. Time clock. Field tools.                          │
│      Can see customer name/address/phone for assigned jobs.                    │
│      Cannot see other techs' jobs, payroll, or company financials.             │
│      Cannot export data.                                                       │
│                                                                                 │
│  CPA (External)                                                                │
│  └── Read-only financials for linked companies.                                │
│      Can see: invoices, expenses, P&L, balance sheet, tax data.               │
│      Cannot see: customer PII, employee personal info, GPS data.              │
│      Can see: employee names + pay rates (for payroll review).                │
│      Access scoped to cpa_clients table linkage.                              │
│                                                                                 │
│  CLIENT (Homeowner)                                                            │
│  └── Own portal ONLY. Own projects, invoices, property, equipment.            │
│      Cannot see any contractor internal data.                                  │
│      Cannot see other clients' data.                                           │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Permission Matrix (Complete)

```
┌──────────────────────────┬───────┬───────┬────────┬──────┬──────┬────────┐
│ Resource                 │ Owner │ Admin │ Office │ Tech │ CPA  │ Client │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ CUSTOMERS                │       │       │        │      │      │        │
│  View all                │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  View assigned only      │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
│  Create/Edit             │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Delete                  │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  Export                  │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ JOBS                     │       │       │        │      │      │        │
│  View all                │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  View assigned only      │  ─    │  ─    │  ─     │  ✅  │  ─   │  ✅*   │
│  Create                  │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Edit                    │  ✅   │  ✅   │  ✅    │  ✅** │  ─   │  ─     │
│  Delete                  │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  View financials         │  ✅   │  ✅   │  ✅    │  ─   │  ✅  │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ INVOICES                 │       │       │        │      │      │        │
│  View all                │  ✅   │  ✅   │  ✅    │  ─   │  ✅  │  ─     │
│  View own only           │  ─    │  ─    │  ─     │  ─   │  ─   │  ✅    │
│  Create/Edit             │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Delete                  │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  Mark as paid            │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Make payment            │  ─    │  ─    │  ─     │  ─   │  ─   │  ✅    │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ TIME CLOCK               │       │       │        │      │      │        │
│  View all entries        │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  View own entries        │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
│  Clock in/out (own)      │  ✅   │  ✅   │  ─     │  ✅  │  ─   │  ─     │
│  Edit others' entries    │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  View GPS tracking       │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ EMPLOYEES / HR           │       │       │        │      │      │        │
│  View roster             │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  View SSNs              │  ✅   │  ─    │  ─     │  ─   │  ─   │  ─     │
│  View pay rates          │  ✅   │  ✅   │  ─     │  ─   │  ✅  │  ─     │
│  Edit employee info      │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  View own profile        │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
│  Performance reviews     │  ✅   │  ✅   │  ─     │  ✅* │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ PAYROLL                  │       │       │        │      │      │        │
│  View all                │  ✅   │  ─    │  ─     │  ─   │  ✅  │  ─     │
│  Run payroll             │  ✅   │  ─    │  ─     │  ─   │  ─   │  ─     │
│  View own pay stubs      │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ FINANCIAL REPORTS        │       │       │        │      │      │        │
│  Revenue/P&L/Balance     │  ✅   │  ✅   │  ✅    │  ─   │  ✅  │  ─     │
│  Profit margins          │  ✅   │  ✅   │  ─     │  ─   │  ✅  │  ─     │
│  Bank reconciliation     │  ✅   │  ─    │  ─     │  ─   │  ✅  │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ COMPANY SETTINGS         │       │       │        │      │      │        │
│  View                    │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Edit                    │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  Billing/Subscription    │  ✅   │  ─    │  ─     │  ─   │  ─   │  ─     │
│  Delete company          │  ✅   │  ─    │  ─     │  ─   │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ FLEET / VEHICLES         │       │       │        │      │      │        │
│  View all                │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  View assigned vehicle   │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
│  Edit                    │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ WEBSITE BUILDER          │       │       │        │      │      │        │
│  Edit website            │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Manage domain           │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  View analytics          │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ DATA EXPORT              │       │       │        │      │      │        │
│  Export any data         │  ✅   │  ✅   │  ─     │  ─   │  ─   │  ─     │
│  Export financials       │  ✅   │  ─    │  ─     │  ─   │  ✅  │  ─     │
│  Export own data         │  ─    │  ─    │  ─     │  ─   │  ─   │  ✅    │
├──────────────────────────┼───────┼───────┼────────┼──────┼──────┼────────┤
│ CALL RECORDINGS (VoIP)   │       │       │        │      │      │        │
│  Listen to all           │  ✅   │  ✅   │  ✅    │  ─   │  ─   │  ─     │
│  Listen to own           │  ─    │  ─    │  ─     │  ✅  │  ─   │  ─     │
│  Delete recordings       │  ✅   │  ─    │  ─     │  ─   │  ─   │  ─     │
└──────────────────────────┴───────┴───────┴────────┴──────┴──────┴────────┘

*  = Own/assigned only
** = Status updates + notes on assigned jobs only (cannot change scope, pricing, assignment)
```

### Permission Storage

```sql
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  role TEXT NOT NULL,             -- owner, admin, office, tech
  resource TEXT NOT NULL,         -- customers, jobs, invoices, etc.
  can_create BOOLEAN DEFAULT FALSE,
  can_read BOOLEAN DEFAULT FALSE,
  can_read_own BOOLEAN DEFAULT FALSE,  -- Assigned/own data only
  can_update BOOLEAN DEFAULT FALSE,
  can_update_own BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  can_export BOOLEAN DEFAULT FALSE,
  field_restrictions TEXT[],      -- Fields hidden for this role (e.g., 'ssn', 'bank_account')
  UNIQUE(company_id, role, resource)
);

-- Default permissions seeded on company creation
-- Owner can customize (e.g., give office staff export access)
-- Changes logged in audit_log
```

---

## LAYER 3: TENANT ISOLATION

### The Foundation: Row-Level Security (RLS)

**Every table has RLS enabled. No exceptions.**

```sql
-- Master function: Get current user's company
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID AS $$
  SELECT company_id FROM users WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Master function: Get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM users WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════
-- APPLY TO EVERY BUSINESS TABLE
-- ════════════════════════════════════════════════════

-- CUSTOMERS: Company isolation + tech can only see assigned
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "company_isolation" ON customers
  FOR ALL USING (company_id = get_user_company_id());

-- JOBS: Company isolation + tech sees assigned only
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "company_isolation" ON jobs
  FOR SELECT USING (
    company_id = get_user_company_id()
    AND (
      get_user_role() IN ('owner', 'admin', 'office')
      OR assigned_to = auth.uid()
    )
  );

CREATE POLICY "company_insert" ON jobs
  FOR INSERT WITH CHECK (
    company_id = get_user_company_id()
    AND get_user_role() IN ('owner', 'admin', 'office')
  );

CREATE POLICY "company_update" ON jobs
  FOR UPDATE USING (
    company_id = get_user_company_id()
    AND (
      get_user_role() IN ('owner', 'admin', 'office')
      OR (assigned_to = auth.uid() AND get_user_role() = 'tech')
    )
  );

CREATE POLICY "company_delete" ON jobs
  FOR DELETE USING (
    company_id = get_user_company_id()
    AND get_user_role() IN ('owner', 'admin')
  );

-- TIME ENTRIES: Techs see own, office+ see all in company
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "time_entries_read" ON time_entries
  FOR SELECT USING (
    company_id = get_user_company_id()
    AND (
      get_user_role() IN ('owner', 'admin', 'office')
      OR user_id = auth.uid()
    )
  );

CREATE POLICY "time_entries_write" ON time_entries
  FOR INSERT WITH CHECK (
    company_id = get_user_company_id()
    AND user_id = auth.uid()  -- Can only create own entries
  );

-- INVOICES: Company isolation + client sees own
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoices_company" ON invoices
  FOR ALL USING (company_id = get_user_company_id());

-- Client portal has separate policies via client_id matching

-- EMPLOYEES: Sensitive data restricted
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "employees_read" ON employees
  FOR SELECT USING (
    company_id = get_user_company_id()
    AND (
      get_user_role() IN ('owner', 'admin', 'office')
      OR user_id = auth.uid()  -- Own profile only for techs
    )
  );

-- SSN field handled at application layer (field-level encryption)
-- Even owner sees encrypted value — decryption requires separate action

-- ════════════════════════════════════════════════════
-- CPA ACCESS (Cross-Company)
-- ════════════════════════════════════════════════════

-- CPA sees data across linked companies (read-only)
CREATE POLICY "cpa_read_invoices" ON invoices
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM cpa_clients
      WHERE cpa_firm_id IN (
        SELECT cpa_firm_id FROM cpa_staff WHERE user_id = auth.uid()
      )
    )
  );

-- Same pattern for: jobs (financials only), expenses, payroll, tax data
-- CPA CANNOT see: customer PII, GPS data, call recordings, employee SSNs

-- ════════════════════════════════════════════════════
-- CLIENT PORTAL ACCESS
-- ════════════════════════════════════════════════════

CREATE POLICY "client_own_invoices" ON invoices
  FOR SELECT USING (
    customer_id IN (
      SELECT id FROM customers WHERE portal_user_id = auth.uid()
    )
  );

-- Same pattern for: jobs (assigned to their property), estimates, documents
```

### Why This Is Bulletproof

```
SCENARIO: Developer writes buggy code that forgets to filter by company_id

WITHOUT RLS (Firebase):
  Bug exposes ALL companies' data. Lawsuit.

WITH RLS (PostgreSQL):
  Database automatically filters. Bug returns empty result instead of leaked data.
  Security cannot be bypassed by application bugs.
```

---

## LAYER 4: DATA PROTECTION

### Encryption

```
AT REST:
────────
• Supabase encrypts all data at rest (AES-256)
• This is automatic, zero configuration
• Covers: database files, backups, WAL logs

IN TRANSIT:
───────────
• TLS 1.3 for all connections
• Supabase enforces SSL
• Mobile app: certificate pinning (prevents MITM)
• HSTS headers on all web properties

FIELD-LEVEL ENCRYPTION (Sensitive PII):
───────────────────────────────────────
These fields are encrypted BEFORE storage. Even database admin can't read raw values.
```

### Field-Level Encryption

```sql
-- Extension for encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypted fields (stored as bytea, not text)
-- These columns store encrypted values that require explicit decryption

-- In the employees table:
--   ssn_encrypted BYTEA          (encrypted SSN)
--   bank_account_encrypted BYTEA (encrypted bank account)
--   routing_number_encrypted BYTEA

-- Encrypt on write (Edge Function handles key management)
-- App NEVER sees raw SSN except during explicit "view SSN" action
-- "View SSN" action logged in audit_log

-- WHAT GETS FIELD-LEVEL ENCRYPTION:
-- ✅ Social Security Numbers
-- ✅ Bank account numbers
-- ✅ Bank routing numbers
-- ✅ Tax ID numbers (EIN)
-- ✅ Driver's license numbers
--
-- WHAT DOES NOT (standard encryption at rest is sufficient):
-- ❌ Names, emails, phones (needed for queries/search)
-- ❌ Addresses (needed for mapping/routing)
-- ❌ Financials like invoice amounts (needed for aggregation)
-- ❌ Job details (needed for search/filter)
```

### Sensitive Data Handling Rules

```
CREDIT CARDS:
─────────────
• ZAFTO NEVER stores credit card numbers
• Stripe handles all card data (PCI DSS Level 1 compliant)
• We store Stripe customer_id and payment_method_id only
• Card last-4 digits stored for display (4242) — not sensitive

PASSWORDS:
──────────
• Supabase Auth handles password hashing (bcrypt)
• ZAFTO never sees or stores raw passwords
• Password reset via email/SMS token only

GPS DATA:
─────────
• Location pings stored with company_id + user_id
• Auto-purge after 90 days (configurable per company)
• Only collected during active clock-in (auto-stop on clock-out)
• Employee can view own tracking data
• Manager access logged in audit_log

CALL RECORDINGS:
────────────────
• Stored in Supabase Storage (encrypted at rest)
• Signed URLs with 1-hour expiry (no permanent links)
• Auto-delete after retention period (company configurable, default 90 days)
• Two-party consent states: recording disclosure auto-played
• Access logged in audit_log
```

### Secure File Storage

```
SUPABASE STORAGE BUCKETS:
─────────────────────────

company-photos/
  • Job site photos, portfolio images
  • Public read (for website portfolio)
  • Write: company members only
  • Path: {company_id}/{job_id}/{filename}

company-documents/
  • Contracts, proposals, permits
  • PRIVATE — signed URLs only (1-hour expiry)
  • Write: owner, admin, office
  • Path: {company_id}/documents/{doc_type}/{filename}

employee-documents/
  • W-2s, I-9s, certifications
  • PRIVATE — signed URLs, owner + individual only
  • Path: {company_id}/employees/{employee_id}/{filename}

call-recordings/
  • VoIP recordings
  • PRIVATE — signed URLs, 1-hour expiry
  • Auto-delete after retention period
  • Path: {company_id}/calls/{date}/{call_id}.mp3

ALL BUCKETS:
• Virus scanning on upload (Supabase built-in)
• File type validation (reject executables)
• Max file size: 50MB per file
• Signed URLs required for private buckets (no direct public access)
```

---

## LAYER 4B: UNIVERSAL ENCRYPTED STORAGE SYSTEM

### The Principle

```
EVERY piece of company data in ZAFTO is encrypted. All of it.

Not just "the database is encrypted" (that's table stakes — Supabase does that).
Not just "sensitive fields are encrypted" (that's Layer 4 above).

THIS IS:
→ Per-company encryption keys
→ Every file encrypted BEFORE it touches storage
→ Every sensitive record encrypted at the application layer
→ Key hierarchy that makes a database breach useless
→ Even ZAFTO employees cannot read company data without authorization

A hacker steals our entire database?
They get encrypted noise. Worthless without the key hierarchy.

A rogue ZAFTO employee tries to snoop?
Audit log catches them. Keys are HSM-protected. Access denied.
```

### Encryption Architecture: Envelope Encryption

```
HOW ENVELOPE ENCRYPTION WORKS:

┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  LEVEL 1: ROOT KEY (Master Key)                                    │
│  ───────────────────────────────                                    │
│  • Lives in Hardware Security Module (HSM)                          │
│  • Never leaves the HSM. Never.                                    │
│  • AWS KMS or Supabase Vault (HSM-backed)                          │
│  • Used ONLY to encrypt/decrypt company keys                       │
│  • If this is compromised, everything is compromised               │
│    → That's why it's in a hardware module, not a database          │
│                                                                     │
│  LEVEL 2: COMPANY KEYS (Data Encryption Keys)                     │
│  ─────────────────────────────────────────────                      │
│  • One unique AES-256 key per company                              │
│  • Generated when company is created                               │
│  • Encrypted by the root key (stored encrypted in database)        │
│  • Decrypted in memory only when needed, then discarded            │
│  • Used to encrypt all of that company's data                      │
│                                                                     │
│  LEVEL 3: DATA                                                     │
│  ─────────                                                          │
│  • Files, recordings, documents, voicemails                        │
│  • Encrypted with company key BEFORE upload                        │
│  • Stored as encrypted blobs in Supabase Storage                   │
│  • Database fields encrypted with company key via pgcrypto         │
│                                                                     │
│  THE RESULT:                                                       │
│  ───────────                                                        │
│  Steal the database → encrypted company keys (useless)             │
│  Steal storage files → encrypted blobs (useless)                   │
│  Steal a company key → only ONE company's data (contained)         │
│  Steal the root key → need HSM access (physical security)          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### What Gets Company-Key Encrypted

```
FILE STORAGE (encrypted BEFORE upload, AES-256-GCM):
─────────────────────────────────────────────────────
✅ Job site photos (originals — public thumbnails use CDN separately)
✅ Company documents (contracts, proposals, permits, plans)
✅ Employee documents (W-2, I-9, certifications, licenses)
✅ Call recordings + voicemails
✅ Resume uploads (career applications)
✅ Logo source files (SVG masters)
✅ Exported reports / financial documents
✅ Chat attachments (if future feature)
✅ Client portal shared documents

DATABASE FIELDS (encrypted at application layer):
──────────────────────────────────────────────────
✅ SSN, EIN, bank accounts, routing numbers (already in Layer 4)
✅ Customer alarm codes / gate codes / access instructions
✅ Employee emergency contact details
✅ Insurance policy numbers
✅ API keys / integration credentials stored per company
✅ Payment method tokens (beyond what Stripe stores)
✅ Notes flagged as "confidential" by user

NOT ENCRYPTED AT APPLICATION LAYER (standard DB encryption sufficient):
───────────────────────────────────────────────────────────────────────
❌ Names, emails, phones → needed for search/query (RLS protects these)
❌ Addresses → needed for mapping/geocoding
❌ Job descriptions → needed for full-text search
❌ Invoice amounts → needed for aggregation/reporting
❌ Timestamps → needed for sorting/filtering
❌ Status fields → needed for query filtering

WHY NOT ENCRYPT EVERYTHING?
You can't search, sort, filter, or aggregate encrypted data.
If you encrypt a customer name, you can't type "Smi..." and get "Smith."
The database can't do WHERE status = 'active' if status is encrypted.
RLS handles access control for these fields — encryption handles the nuclear scenario.
```

### File Encryption Flow

```
UPLOAD (e.g., tech takes a job site photo):
───────────────────────────────────────────

1. Photo captured on device
2. App requests company encryption key from Edge Function
3. Edge Function:
   a. Authenticates user (JWT + company_id)
   b. Fetches encrypted company key from database
   c. Decrypts company key using root key (HSM call)
   d. Returns company key to app (over TLS 1.3, in memory only)
4. App encrypts photo with AES-256-GCM + random IV
5. App uploads encrypted blob to Supabase Storage
6. Company key discarded from app memory
7. File is NEVER unencrypted on our servers

DOWNLOAD (e.g., owner views a document):
────────────────────────────────────────

1. App requests file from Supabase Storage
2. Receives encrypted blob
3. App requests company key from Edge Function (same auth flow)
4. App decrypts file locally on device
5. File displayed to user
6. Company key discarded from memory
7. Decrypted file exists ONLY in device memory (not saved to disk)

THE KEY NEVER TOUCHES STORAGE.
THE DECRYPTED FILE NEVER TOUCHES OUR SERVERS.
Encryption and decryption happen ON THE DEVICE.
```

### Key Rotation

```
WHY: Even good keys should be rotated periodically.
If a key is ever suspected compromised, rotate immediately.

SCHEDULED ROTATION (every 12 months):
1. Generate new company key
2. Re-encrypt all files with new key (background job)
3. Re-encrypt all encrypted database fields
4. Old key kept in key_history for 30 days (in case of recovery)
5. Old key permanently destroyed after 30 days

EMERGENCY ROTATION (suspected compromise):
1. Generate new company key immediately
2. Invalidate old key
3. Re-encryption begins as priority background job
4. All active sessions for that company invalidated
5. Users must re-authenticate
6. Audit log flagged with security event

KEY ROTATION STATUS:
Owner can see: "Last key rotation: 45 days ago"
Alert at 11 months: "Encryption key rotation recommended"
Auto-rotate at 12 months if not done manually
```

### Database Schema

```sql
-- Company encryption keys (the keys are themselves encrypted by root key)
CREATE TABLE company_encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  
  -- The company key, encrypted by root key (HSM)
  encrypted_key BYTEA NOT NULL,
  
  -- Key metadata
  key_version INTEGER NOT NULL DEFAULT 1,
  algorithm TEXT NOT NULL DEFAULT 'AES-256-GCM',
  is_active BOOLEAN DEFAULT true,      -- only one active key per company
  
  -- Rotation tracking
  created_at TIMESTAMPTZ DEFAULT now(),
  rotated_at TIMESTAMPTZ,               -- when this key was rotated out
  expires_at TIMESTAMPTZ,               -- scheduled rotation date
  rotated_by UUID REFERENCES users(id), -- who triggered rotation
  
  -- If this was an emergency rotation
  emergency_rotation BOOLEAN DEFAULT false,
  rotation_reason TEXT
);

-- CRITICAL: Only Edge Functions access this table
-- No direct app access. No RLS policy for users.
-- Edge Function authenticates, then uses service_role key to fetch.

CREATE INDEX idx_company_key_active 
  ON company_encryption_keys (company_id) 
  WHERE is_active = true;

-- File encryption metadata (tracks what's encrypted with which key)
CREATE TABLE encrypted_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  key_version INTEGER NOT NULL,         -- which key version encrypted this file
  storage_path TEXT NOT NULL,            -- path in Supabase Storage
  original_filename TEXT,                -- what the user called it
  mime_type TEXT,
  file_size_encrypted INTEGER,           -- size after encryption
  file_size_original INTEGER,            -- size before encryption
  iv BYTEA NOT NULL,                     -- initialization vector (unique per file)
  checksum TEXT NOT NULL,                -- SHA-256 of original for integrity verification
  
  -- Context
  resource_type TEXT,                    -- 'job_photo', 'document', 'recording', etc.
  resource_id UUID,                      -- which job, employee, etc.
  uploaded_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: users can only see their company's file records
-- Actual decryption requires the key (which requires Edge Function auth)
```

---

## LAYER 4C: DATA EXPORT & BACKUP SYSTEM

### The Principle

```
THE CONTRACTOR'S DATA IS THE CONTRACTOR'S DATA.

They can download ALL of it at ANY time.
Every record. Every file. Every photo. Every invoice. Every log.
Packaged, organized, and delivered to them.

WHY:
1. TRUST — "I can leave any time and take everything with me"
2. LIABILITY — "We gave you the option to back up. You chose not to."
3. LEGAL — Data portability is increasingly required by law
4. DISASTER RECOVERY — If ZAFTO burns down, they have their data
5. SWITCHING — If they leave, clean handoff. No hostage situations.

THIS IS THE SAME PHILOSOPHY AS THE DOMAIN:
We manage it. They own it. They can take it and leave.
```

### Export Options (CRM → Settings → Data & Backup)

```
┌──────────────────────────────────────────────────────────────────────┐
│  💾 Data & Backup                                                    │
│                                                                      │
│  YOUR DATA BELONGS TO YOU.                                           │
│  Download everything at any time.                                    │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  📦 FULL COMPANY BACKUP                                             │
│  Download your entire company's data — every record, every file.     │
│  Organized in folders, human-readable formats.                       │
│  Last backup: February 4, 2026 (auto)                               │
│  [Download Full Backup]  Estimated size: 2.4 GB                     │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  📁 SELECTIVE EXPORT                                                │
│  Download specific sections:                                         │
│                                                                      │
│  ☐ Customers & Contacts          ~12 MB  (CSV + JSON)              │
│  ☐ Jobs & Work Orders            ~45 MB  (CSV + JSON + attachments)│
│  ☐ Invoices & Billing            ~8 MB   (CSV + JSON + PDFs)      │
│  ☐ Bids & Proposals              ~15 MB  (CSV + JSON + PDFs)      │
│  ☐ Employees & HR                ~22 MB  (CSV + JSON + documents)  │
│  ☐ Payroll Records               ~5 MB   (CSV + JSON)             │
│  ☐ Photos & Portfolio            ~1.8 GB (originals)              │
│  ☐ Documents & Contracts         ~340 MB (originals)              │
│  ☐ Call Recordings               ~680 MB (MP3)                    │
│  ☐ Voicemails & Transcripts      ~45 MB  (MP3 + text)            │
│  ☐ Text Message History          ~3 MB   (JSON)                   │
│  ☐ Exam & Calculator History     ~1 MB   (JSON)                   │
│  ☐ Website Content & Assets      ~200 MB (HTML + images + logo)   │
│  ☐ AI Chat Conversations         ~8 MB   (JSON)                   │
│  ☐ Audit Log                     ~15 MB  (CSV)                    │
│  ☐ Analytics & Reports           ~4 MB   (CSV + JSON)            │
│                                                                      │
│  [Download Selected]                                                 │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  🔄 AUTOMATIC BACKUPS                                               │
│                                                                      │
│  Auto-backup frequency: [Weekly ▾]                                  │
│  ○ Off   ○ Daily   ☑ Weekly   ○ Monthly                           │
│                                                                      │
│  Delivery method:                                                    │
│  ☑ Keep in ZAFTO (download anytime, last 5 backups retained)       │
│  ☐ Email download link                                              │
│  ☐ Send to cloud storage (Google Drive / Dropbox)                   │
│                                                                      │
│  Backup encryption:                                                  │
│  ☑ Encrypt backup file with password                                │
│  Password: [••••••••••]  (you set this, we don't store it)          │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  📋 EXPORT HISTORY                                                  │
│                                                                      │
│  Feb 4, 2026 — Full backup (auto) — 2.4 GB — [Download]            │
│  Jan 28, 2026 — Full backup (auto) — 2.3 GB — [Download]           │
│  Jan 21, 2026 — Full backup (auto) — 2.2 GB — [Download]           │
│  Jan 20, 2026 — Customers export (manual) — 12 MB — Expired        │
│  Jan 14, 2026 — Full backup (auto) — 2.1 GB — [Download]           │
│                                                                      │
│  Backup retention: Last 5 automatic backups kept.                    │
│  Download links expire after 7 days.                                 │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### What The Export Contains

```
FULL BACKUP DIRECTORY STRUCTURE:
─────────────────────────────────

PowersElectric_Backup_2026-02-04/
│
├── README.txt                      ← "This is your complete data export from ZAFTO..."
├── manifest.json                   ← File listing with checksums for integrity verification
│
├── customers/
│   ├── customers.csv               ← All customers, human-readable spreadsheet
│   ├── customers.json              ← All customers, machine-readable
│   └── contacts.csv                ← All contact records
│
├── jobs/
│   ├── jobs.csv                    ← All jobs with status, dates, amounts
│   ├── jobs.json
│   ├── work_orders.csv
│   └── attachments/
│       ├── JOB-4201/              ← Photos, documents per job
│       ├── JOB-4202/
│       └── ...
│
├── invoices/
│   ├── invoices.csv
│   ├── invoices.json
│   └── pdfs/
│       ├── INV-2026-0001.pdf      ← Generated invoice PDFs
│       ├── INV-2026-0002.pdf
│       └── ...
│
├── bids/
│   ├── bids.csv
│   ├── bids.json
│   └── pdfs/
│       ├── BID-2026-0001.pdf
│       └── ...
│
├── employees/
│   ├── employees.csv
│   ├── certifications.csv
│   ├── licenses.csv
│   └── documents/
│       ├── mike-torres/
│       │   ├── W2-2025.pdf
│       │   ├── electrician-license.pdf
│       │   └── ...
│       └── ...
│
├── payroll/
│   ├── payroll_runs.csv
│   ├── pay_stubs.csv
│   └── tax_reports/
│
├── photos/
│   ├── originals/                  ← Full resolution, uncompressed
│   │   ├── photo_001.jpg
│   │   ├── photo_002.jpg
│   │   └── ...
│   ├── photo_metadata.csv          ← Job ID, category, date, GPS, captions
│   └── albums.json                 ← Album organization
│
├── documents/
│   ├── contracts/
│   ├── permits/
│   ├── proposals/
│   └── ...
│
├── phone/
│   ├── call_log.csv                ← All calls with duration, direction, who
│   ├── recordings/
│   │   ├── 2026-02-04_14-30_john-smith.mp3
│   │   └── ...
│   ├── voicemails/
│   │   ├── 2026-02-04_vm_203-555-1234.mp3
│   │   └── ...
│   ├── transcripts.csv             ← AI transcriptions of all voicemails + calls
│   └── text_messages.json          ← All SMS conversations
│
├── website/
│   ├── pages/                      ← All website page content
│   ├── assets/                     ← Logo, photos, favicon
│   ├── blog_posts/
│   └── settings.json               ← Template, colors, domain info
│
├── analytics/
│   ├── website_traffic.csv
│   ├── lead_sources.csv
│   ├── revenue_attribution.csv
│   └── phone_analytics.csv
│
├── ai_conversations/
│   ├── website_chat_sessions.json
│   └── ai_receptionist_calls.json
│
└── audit_log/
    └── audit_log.csv               ← Complete audit trail


FORMAT NOTES:
─────────────
• CSV files open directly in Excel/Google Sheets — zero technical knowledge needed
• JSON files are for developers / importing into another system
• All dates in ISO 8601 format
• All monetary values with currency code
• All file references are relative paths within the backup
• Manifest includes SHA-256 checksums for every file (integrity verification)
```

### Export Security

```
THE EXPORT ITSELF MUST BE SECURE:

1. BACKUP ENCRYPTION
   → User sets a password (we don't store it)
   → Entire ZIP encrypted with AES-256 using their password
   → If backup is intercepted in transit, it's useless without password
   → Forget password? Generate a new backup. We can't recover it.

2. DOWNLOAD SECURITY
   → Signed URL with 24-hour expiry
   → One-time use token (link dies after first download)
   → Must be authenticated + Owner role to request export
   → MFA required to initiate full backup
   → Export request logged in audit_log

3. AUTOMATIC BACKUP SECURITY
   → Stored in isolated Supabase Storage bucket (private)
   → Encrypted with company key (same Layer 4B system)
   → Retained for 5 cycles (5 weeks if weekly)
   → Auto-deleted after retention period
   → Never accessible to other companies (RLS)

4. EXPORT SANITIZATION
   → Decrypted fields are decrypted for the export (owner gets real data)
   → EXCEPTION: Other companies' data is NEVER included
   → CPA cross-company data is NOT included (only their company's data)
   → Client portal user data is limited to what client would see
   → Supabase service_role key is NEVER included
   → API keys / integration secrets are REDACTED with note
```

### Export Edge Function

```
Supabase Edge Function: exportCompanyData

AUTHORIZATION:
  → User must be Owner role
  → MFA must be verified in current session
  → Rate limit: 1 full export per 24 hours

PROCESS:
  1. Verify authorization (Owner + MFA)
  2. Log export request in audit_log
  3. Queue background job (exports can take minutes for large companies)
  4. For each data category:
     a. Query PostgreSQL with company_id filter
     b. Decrypt any encrypted fields using company key
     c. Generate CSV + JSON files
     d. Fetch all files from Supabase Storage
     e. Decrypt files using company key
     f. Organize into directory structure
  5. Generate manifest.json with SHA-256 checksums
  6. Generate README.txt with export metadata
  7. Compress into ZIP
  8. If password set → encrypt ZIP with AES-256
  9. Upload encrypted ZIP to private export bucket
  10. Generate signed URL (24hr, one-time use)
  11. Notify owner: "Your backup is ready to download"
  12. Log completion in audit_log

ESTIMATED TIME:
  Small company (<1 GB): ~2-5 minutes
  Medium company (1-5 GB): ~5-15 minutes
  Large company (5-20 GB): ~15-45 minutes
  → User gets push notification when ready
```

### RBAC: Data Export Permissions

```
ACTION                              OWNER    ADMIN    OFFICE    TECH
──────────────────────────────      ─────    ─────    ──────    ────
Request full company backup           ✅       ❌       ❌        ❌
Request selective export              ✅       ✅       ❌        ❌
Download backup files                 ✅       ❌       ❌        ❌
Configure auto-backup schedule        ✅       ❌       ❌        ❌
View export history                   ✅       ✅       ❌        ❌
Export own employee records           ✅       ✅       ✅        ✅
Export customer list (CSV)            ✅       ✅       ✅        ❌
```

### Legal Language

```
IN TERMS OF SERVICE:
───────────────────
"Your data belongs to you. You may export a complete copy of all your
company data at any time through the Data & Backup section. Upon
account cancellation, you will have 30 days to export your data before
it is permanently deleted. ZAFTO will never hold your data hostage or
charge fees for data export."

IN CANCELLATION FLOW:
────────────────────
Step 1: "Before you go — download your data"
        [Download Full Backup]
        [I already have a backup]
        [I don't need my data]

Step 2: If "I don't need my data" selected:
        "Are you sure? This is permanent. After 30 days,
        all your data will be permanently deleted and
        cannot be recovered."
        [Yes, I understand]  [Wait, let me download first]

Step 3: Account suspended (30-day grace period)
        → Can still log in to download data
        → Can reactivate during this period

Step 4: After 30 days → permanent deletion
        → All data purged
        → All files deleted
        → Company key destroyed
        → Audit log retained for 7 years (legal requirement)
```

### Implementation Checklist

```
ENCRYPTED STORAGE:
- [ ] Supabase Vault or AWS KMS integration (HSM for root key)
- [ ] Company key generation on company creation
- [ ] Company key table with RLS (Edge Function access only)
- [ ] File encryption/decryption in Edge Functions
- [ ] Client-side encryption for file uploads (Flutter)
- [ ] Client-side decryption for file downloads (Flutter)
- [ ] Key rotation system (scheduled + emergency)
- [ ] Encrypted file metadata table
- [ ] Migration: encrypt all existing files with company keys

DATA EXPORT:
- [ ] Export UI in CRM Settings
- [ ] Full backup Edge Function (background job)
- [ ] Selective export Edge Function
- [ ] CSV + JSON generation for all data tables
- [ ] File collection from Supabase Storage
- [ ] Directory structure organization
- [ ] Manifest generation with SHA-256 checksums
- [ ] ZIP compression + optional AES-256 password encryption
- [ ] Signed URL generation (24hr, one-time)
- [ ] Push notification on completion
- [ ] Auto-backup scheduler (daily/weekly/monthly)
- [ ] Backup retention management (keep last 5)
- [ ] Export history UI
- [ ] RBAC enforcement (Owner only for full backup)
- [ ] MFA verification before export
- [ ] Audit logging for all export actions
- [ ] Cancellation flow with data download prompt
- [ ] 30-day grace period implementation
```

### Audit Log (The Legal Shield)

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID,                  -- NULL for platform-level events
  user_id UUID NOT NULL,
  user_email TEXT,                   -- Denormalized for quick reading
  user_role TEXT,                    -- Role at time of action
  
  -- What happened
  action TEXT NOT NULL,              -- create, read, update, delete, export, login, logout
  resource_type TEXT NOT NULL,       -- customer, job, invoice, employee, payroll, etc.
  resource_id UUID,                  -- Which specific record
  
  -- What changed (for updates)
  changes JSONB,                     -- { "status": { "old": "draft", "new": "sent" } }
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  session_id UUID,
  
  -- Timestamp (immutable)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CRITICAL: This table is APPEND-ONLY
-- No updates. No deletes. Ever.
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Only platform admins can read audit logs
-- Company owners can read their own company's logs
CREATE POLICY "owner_reads_own_audit" ON audit_log
  FOR SELECT USING (
    company_id = get_user_company_id()
    AND get_user_role() = 'owner'
  );

-- No update or delete policies exist = impossible to modify

-- Index for fast queries
CREATE INDEX idx_audit_company_date ON audit_log (company_id, created_at DESC);
CREATE INDEX idx_audit_user ON audit_log (user_id, created_at DESC);
CREATE INDEX idx_audit_resource ON audit_log (resource_type, resource_id);
```

### What Gets Logged

```
ALWAYS LOGGED:
──────────────
• Login / logout / failed login
• Create any record
• Update any record (with old/new values)
• Delete any record
• Export any data
• View SSN or bank account (decryption event)
• View call recording
• View GPS tracking data
• Role changes
• Permission changes
• Session creation / revocation
• CPA accessing client data (which CPA, which client, what data)
• Password changes / resets
• MFA enable / disable

NOT LOGGED (to avoid noise):
────────────────────────────
• Normal page views (GET requests for lists)
• Calculator usage
• Exam progress
• Search queries
```

### Automatic Audit Trigger

```sql
-- Auto-log all changes to key tables
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (
    company_id,
    user_id,
    user_email,
    user_role,
    action,
    resource_type,
    resource_id,
    changes
  ) VALUES (
    COALESCE(NEW.company_id, OLD.company_id),
    auth.uid(),
    (SELECT email FROM auth.users WHERE id = auth.uid()),
    get_user_role(),
    TG_OP,  -- INSERT, UPDATE, DELETE
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE 
      WHEN TG_OP = 'UPDATE' THEN jsonb_build_object(
        'old', to_jsonb(OLD),
        'new', to_jsonb(NEW)
      )
      WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD)
      ELSE to_jsonb(NEW)
    END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply to all sensitive tables
CREATE TRIGGER audit_customers AFTER INSERT OR UPDATE OR DELETE ON customers
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_jobs AFTER INSERT OR UPDATE OR DELETE ON jobs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_invoices AFTER INSERT OR UPDATE OR DELETE ON invoices
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_employees AFTER INSERT OR UPDATE OR DELETE ON employees
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_time_entries AFTER INSERT OR UPDATE OR DELETE ON time_entries
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Add triggers to ALL business tables...
```

### Anomaly Detection (Automated Alerts)

```
ALERT TRIGGERS:
───────────────
1. Login from new country → Email owner immediately
2. 3+ failed logins → Email account holder
3. Bulk data export (>100 records) → Email owner
4. CPA accessing data outside business hours → Flag for review
5. Employee accessing data after termination date → Block + alert owner
6. Same account logged in from 2+ locations simultaneously → Alert
7. Sudden spike in API calls from one user → Rate limit + alert
```

---

## LAYER 6: NETWORK & INFRASTRUCTURE

### Cloudflare Protection (All Web Properties)

```
APPLIES TO:
───────────
• zafto.app (marketing)
• zafto.cloud (CRM)
• client.zafto.cloud (Client Portal)
• *.zafto.cloud (contractor websites)
• API endpoints

PROTECTIONS:
────────────
• DDoS mitigation (automatic, Cloudflare network)
• WAF (Web Application Firewall) rules
• Bot detection and blocking
• Rate limiting per IP
• SSL/TLS termination
• HSTS enforcement
```

### API Rate Limiting

```
PER USER:
─────────
• 100 requests/minute (normal use)
• 1,000 requests/hour (generous ceiling)
• Exceeding = 429 Too Many Requests + 60 second cooldown

PER COMPANY:
────────────
• 5,000 requests/minute (all users combined)
• Prevents runaway integrations from hammering API

SPECIAL LIMITS:
───────────────
• Data export: 5 exports per hour per user
• SSN decryption: 10 per hour per user (logged)
• Password attempts: 5 per 15 minutes (then lockout)
• File upload: 100 files per hour per company
```

### HTTP Security Headers

```
ALL RESPONSES INCLUDE:
──────────────────────
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self' https://js.stripe.com; ...
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(self)
```

### Input Validation

```
ALL USER INPUT:
───────────────
• Parameterized queries ONLY (Supabase SDK handles this)
• No raw SQL string concatenation — ever
• Input length limits on all fields
• Email validation (format + domain exists)
• Phone validation (E.164 format)
• File type validation on upload (allowlist, not blocklist)
• JSON schema validation on API endpoints
• HTML sanitization on rich text fields (DOMPurify or equivalent)
```

---

## COMPLIANCE READINESS

### What We Build Now

```
PRIVACY:
────────
• Privacy policy + terms of service
• Data retention policies (configurable per company)
• Right to delete: User requests → wipe their data (GDPR/CCPA)
• Data export: User requests → JSON/CSV download of their data
• Cookie consent on web properties

DATA HANDLING:
──────────────
• PII inventory: Know what sensitive data is stored and where
• Data minimization: Only collect what's needed
• Purpose limitation: Use data only for stated purpose
• Retention limits: Auto-purge GPS after 90 days, call recordings after configurable period

BREACH RESPONSE PLAN:
─────────────────────
• Detection: Anomaly alerts (Layer 5)
• Assessment: Determine scope within 24 hours
• Notification: Affected users within 72 hours (GDPR requirement)
• Remediation: Patch vulnerability, rotate keys, revoke sessions
• Documentation: Full incident report in audit log
```

### Future (When Scale Justifies)

```
SOC 2 TYPE II:
──────────────
• Everything above gets us 80% there
• Remaining 20%: Formal policies, annual audits, penetration testing
• Cost: ~$20-50k for certification
• Trigger: When enterprise clients require it

HIPAA (If we add medical trades):
──────────────────────────────────
• Supabase supports HIPAA (Business Associate Agreement)
• Our architecture is already compliant (encryption, audit, access controls)
• Just need formal BAA and policy documentation
```

---

## IMPLEMENTATION CHECKLIST

### Database Level (During Migration)

```
[ ] Enable RLS on ALL tables
[ ] Create get_user_company_id() function
[ ] Create get_user_role() function
[ ] Create tenant isolation policies for every table
[ ] Create role-based policies (tech sees assigned only)
[ ] Create CPA cross-company read policies
[ ] Create client portal read policies
[ ] Create audit_log table (append-only)
[ ] Create audit trigger function
[ ] Apply audit triggers to all business tables
[ ] Create login_attempts table
[ ] Create user_sessions table
[ ] Create role_permissions table with defaults
[ ] Set up field-level encryption for SSNs/bank accounts
[ ] Create indexes for audit_log queries
```

### Application Level (During Service Rewrites)

```
[ ] Supabase Auth integration (email, Google, Apple, phone)
[ ] MFA setup for owner/admin/CPA roles
[ ] Session timeout configuration per role
[ ] Brute force lockout logic
[ ] Password policy enforcement
[ ] Certificate pinning on mobile
[ ] Input validation on all forms
[ ] File type validation on uploads
[ ] Signed URL generation for private files
[ ] Export logging
[ ] SSN decryption logging
[ ] GPS auto-stop on clock-out
```

### Infrastructure Level (Deployment)

```
[ ] Cloudflare WAF rules configured
[ ] Rate limiting configured
[ ] HTTP security headers on all properties
[ ] HSTS preload submitted
[ ] SSL certificates valid on all domains
[ ] Supabase connection pooling configured
[ ] Database backups verified (Supabase daily automatic)
[ ] Monitoring/alerting configured
```

---

## WHAT THIS PREVENTS

| Attack | Prevention Layer | Result |
|--------|:----------------:|--------|
| Tenant data leak (see other company) | Layer 3: RLS | Database blocks query automatically |
| Unauthorized role escalation | Layer 2: RBAC + RLS | Database enforces role at query level |
| Stolen session token | Layer 1: Session expiry + MFA | Token expires, MFA required for sensitive ops |
| SQL injection | Layer 6: Parameterized queries | Supabase SDK prevents by design |
| Brute force login | Layer 1: Rate limiting + lockout | Account locks after 5 failures |
| Ex-employee access | Layer 1: Session revocation | Revoke all sessions on termination |
| CPA over-access | Layer 3: RLS + Layer 5: Audit | Database limits scope, all access logged |
| Insider data theft | Layer 5: Audit + anomaly alerts | Bulk export flagged and logged |
| GPS stalking | Layer 4: Auto-stop + Layer 5: Audit | Tracking stops at clock-out, manager access logged |
| Call recording violations | Layer 4: Consent tracking + auto-delete | State law compliance, retention limits |
| SSN breach | Layer 4: Field-level encryption | Even DB admin can't read raw SSNs |
| DDoS | Layer 6: Cloudflare | Automatic mitigation |
| Man-in-the-middle | Layer 4: TLS 1.3 + cert pinning | Encrypted transit, pinned certificates |

---

## INTEGRATION WITH DATABASE MIGRATION

**All of Layer 3 (RLS) and Layer 5 (Audit) get built DURING the Supabase migration.**

They are SQL tables, functions, policies, and triggers. They go into the migration script alongside the schema. Zero extra effort — it's just part of the database setup.

```
29_DATABASE_MIGRATION.md Phase 1 now includes:
  1. Create Supabase project
  2. Run database schema ← includes audit_log, sessions, login_attempts
  3. Enable RLS on all tables ← includes all policies
  4. Create audit triggers ← automatic logging
  5. Configure auth providers
  6. Set up storage buckets with access rules
  7. Configure RLS for CPA cross-company access
  8. Configure RLS for client portal access
```

**Security is not bolted on. It's part of the foundation.**

---

**END OF SECURITY ARCHITECTURE — UPDATED FEBRUARY 5, 2026 (Session 30)**
**Added: Layer 4B — Universal Encrypted Storage (envelope encryption, per-company keys, HSM)**
**Added: Layer 4C — Data Export & Backup System (full download, auto-backup, password-encrypted ZIPs)**
**THIS IS NOT OPTIONAL. BUILD SECURITY INTO THE DATABASE MIGRATION.**
**SEE ALSO: 29_DATABASE_MIGRATION.md (schema + RLS go together)**
**SEE ALSO: 31_PHONE_SYSTEM.md (call encryption architecture)**
