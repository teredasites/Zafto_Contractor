# ZAFTO DATABASE MIGRATION
## Firebase → Supabase + PostgreSQL + PowerSync
### February 5, 2026 — Session 29

---

## EXECUTIVE DECISION

**Migrate from Firebase/Firestore to Supabase/PostgreSQL BEFORE building remaining features.**

Rationale:
- CPA Portal needs cross-company queries (impossible in Firestore efficiently)
- ZAFTO Books needs complex aggregations (painful in Firestore)
- Payroll needs transactions and aggregations (limited in Firestore)
- Reporting needs SQL (Firestore can't do this)
- Cost at scale: Firestore explodes, PostgreSQL is predictable
- Build it right once, never migrate again

---

## THE STACK

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              FINAL STACK                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  DATABASE:        Supabase (PostgreSQL)                                        │
│  AUTH:            Supabase Auth                                                │
│  STORAGE:         Supabase Storage                                             │
│  REAL-TIME:       Supabase Realtime                                            │
│  OFFLINE SYNC:    PowerSync                                                    │
│  EDGE FUNCTIONS:  Supabase Edge Functions (or Cloudflare Workers)              │
│                                                                                 │
│  EXTERNAL APIS:                                                                │
│  • Twilio (SMS, VoIP)                                                          │
│  • Stripe (Payments)                                                           │
│  • Cloudflare (Domains, CDN, Website hosting)                                  │
│  • Claude API (AI features)                                                    │
│  • SendGrid (Email)                                                            │
│  • Check.com or Gusto (Payroll processing)                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## COST COMPARISON

```
SCENARIO: 10,000 Companies

FIREBASE:
─────────
Reads: ~100M/month × $0.36/100k = $360
Writes: ~20M/month × $1.08/100k = $216
Storage: 500GB × $0.18/GB = $90
Cloud Functions: ~50M invocations = $200+
Egress: Variable = $200+
───────────────────────────────
TOTAL: $1,000-3,000/month (grows with usage)

SUPABASE:
──────────
Team tier: $599/month
Compute add-on: ~$200/month
───────────────────────────────
TOTAL: ~$800/month (predictable)

SAVINGS AT SCALE: 60-75%
```

---

## WHAT CHANGES

### Services (Data Layer)

```dart
// BEFORE (Firestore)
Future<Job> getJob(String id) async {
  final doc = await _firestore.collection('jobs').doc(id).get();
  return Job.fromFirestore(doc);
}

// AFTER (Supabase)
Future<Job> getJob(String id) async {
  final response = await _supabase
    .from('jobs')
    .select()
    .eq('id', id)
    .single();
  return Job.fromJson(response);
}
```

### Real-Time Subscriptions

```dart
// BEFORE (Firestore)
Stream<List<Job>> watchJobs() {
  return _firestore
    .collection('jobs')
    .where('companyId', isEqualTo: companyId)
    .snapshots()
    .map((snap) => snap.docs.map(Job.fromFirestore).toList());
}

// AFTER (Supabase)
Stream<List<Job>> watchJobs() {
  return _supabase
    .from('jobs')
    .stream(primaryKey: ['id'])
    .eq('company_id', companyId)
    .map((data) => data.map(Job.fromJson).toList());
}
```

### Offline Sync (PowerSync)

```dart
// PowerSync handles offline automatically
final db = PowerSyncDatabase(schema: schema);
await db.connect(connector: SupabaseConnector());

// Queries work offline (SQLite on device)
final jobs = await db.getAll(
  'SELECT * FROM jobs WHERE status = ?', 
  ['active']
);

// Changes sync automatically when online
await db.execute(
  'UPDATE jobs SET status = ? WHERE id = ?',
  ['completed', jobId]
);
```

### Complex Queries (The Payoff)

```sql
-- CPA Portal: All clients with overdue invoices
SELECT c.*, 
       COUNT(i.id) as overdue_count,
       SUM(i.amount) as overdue_total
FROM companies c
JOIN cpa_clients cc ON c.id = cc.company_id
JOIN invoices i ON c.id = i.company_id
WHERE cc.cpa_id = $1
  AND i.status = 'unpaid'
  AND i.due_date < NOW() - INTERVAL '30 days'
GROUP BY c.id;

-- ONE QUERY. 50ms. Done.
-- Firestore: 50+ queries, client-side aggregation, slow, expensive.
```

---

## WHAT STAYS THE SAME

| Component | Changes? | Notes |
|-----------|:--------:|-------|
| 90 Screens | ❌ No | UI doesn't know about database |
| 50+ Widgets | ❌ No | Pure UI components |
| Business Logic | ❌ No | Calculations, validations stay same |
| State Management (Riverpod) | ❌ No | Providers stay same |
| Navigation | ❌ No | Routing unchanged |
| Design System | ❌ No | All components unchanged |
| Calculators | ❌ No | Pure Dart, no database |

---

## MIGRATION SCOPE

### Files That Change

| Category | Count | Work |
|----------|:-----:|------|
| Service files | ~15 | Rewrite Firestore → Supabase calls |
| Model files | ~25 | fromFirestore() → fromJson() (minor) |
| Auth service | 1 | Firebase Auth → Supabase Auth |
| Storage service | 1 | Firebase Storage → Supabase Storage |
| Cloud Functions | ~10 | Rewrite for Edge Functions or keep separate |
| New: Database schema | 1 | PostgreSQL tables, relationships, RLS |
| New: PowerSync schema | 1 | Sync rules, offline tables |

### Files That Don't Change

| Category | Count |
|----------|:-----:|
| Screen files | ~90 |
| Widget files | ~50 |
| Business logic | All |
| State management | All |
| Navigation | All |
| Calculators | All |

### Time Estimate

| Task | Hours |
|------|:-----:|
| Schema design (incl. security tables) | 2-3 |
| Supabase project setup | 1 |
| RLS policies + audit triggers | 2-3 |
| PowerSync integration | 2-3 |
| Service rewrites | 4-6 |
| Model updates | 1-2 |
| Auth migration + MFA setup | 1-2 |
| Storage migration + signed URLs | 1 |
| Security verification testing | 1-2 |
| Feature testing | 2-3 |
| **TOTAL** | **17-25** |

**Realistic: 2 focused days**

---

## DATABASE SCHEMA (PostgreSQL)

### Core Tables

```sql
-- Companies (tenant isolation)
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  trade TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address JSONB,
  logo_url TEXT,
  website_id UUID,
  subscription_tier TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  company_id UUID REFERENCES companies(id),
  email TEXT NOT NULL,
  name TEXT,
  role TEXT NOT NULL, -- owner, admin, tech, office
  phone TEXT,
  avatar_url TEXT,
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address JSONB,
  type TEXT DEFAULT 'residential', -- residential, commercial
  source TEXT, -- referral, website, google, etc.
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Jobs
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  assigned_to UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
  priority TEXT DEFAULT 'normal',
  trade TEXT,
  job_type TEXT,
  scheduled_start TIMESTAMPTZ,
  scheduled_end TIMESTAMPTZ,
  actual_start TIMESTAMPTZ,
  actual_end TIMESTAMPTZ,
  address JSONB,
  total DECIMAL(10,2),
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  invoice_number TEXT NOT NULL,
  status TEXT DEFAULT 'draft', -- draft, sent, paid, overdue, cancelled
  subtotal DECIMAL(10,2),
  tax DECIMAL(10,2),
  total DECIMAL(10,2),
  due_date DATE,
  paid_at TIMESTAMPTZ,
  line_items JSONB DEFAULT '[]',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time Entries
CREATE TABLE time_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  clock_in TIMESTAMPTZ NOT NULL,
  clock_out TIMESTAMPTZ,
  break_minutes INTEGER DEFAULT 0,
  total_hours DECIMAL(5,2),
  hourly_rate DECIMAL(8,2),
  labor_cost DECIMAL(10,2),
  notes TEXT,
  location_pings JSONB DEFAULT '[]', -- GPS tracking
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bids/Estimates
CREATE TABLE bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  bid_number TEXT NOT NULL,
  status TEXT DEFAULT 'draft', -- draft, sent, accepted, rejected, expired
  subtotal DECIMAL(10,2),
  tax DECIMAL(10,2),
  total DECIMAL(10,2),
  valid_until DATE,
  line_items JSONB DEFAULT '[]',
  notes TEXT,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Business OS Tables (New Systems)

```sql
-- Employees (extends users for HR)
CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT,
  department TEXT,
  hire_date DATE,
  hourly_rate DECIMAL(8,2),
  salary DECIMAL(12,2),
  pay_type TEXT, -- hourly, salary
  status TEXT DEFAULT 'active',
  emergency_contact JSONB,
  documents JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vehicles (Fleet)
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  make TEXT,
  model TEXT,
  year INTEGER,
  vin TEXT,
  license_plate TEXT,
  status TEXT DEFAULT 'active',
  current_mileage INTEGER,
  assigned_to UUID REFERENCES employees(id),
  insurance_expiry DATE,
  registration_expiry DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CPA Firms
CREATE TABLE cpa_firms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CPA Clients (links CPAs to companies)
CREATE TABLE cpa_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cpa_firm_id UUID REFERENCES cpa_firms(id) NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  access_level TEXT DEFAULT 'read', -- read, write, admin
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cpa_firm_id, company_id)
);

-- Vendors
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  address JSONB,
  payment_terms TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Purchase Orders
CREATE TABLE purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  vendor_id UUID REFERENCES vendors(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  po_number TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  total DECIMAL(10,2),
  line_items JSONB DEFAULT '[]',
  notes TEXT,
  ordered_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

-- Users can only see their company's data
CREATE POLICY "Users see own company data" ON customers
  FOR ALL USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

-- Same pattern for all tables...

-- CPA access (special case)
CREATE POLICY "CPAs see their clients data" ON companies
  FOR SELECT USING (
    id IN (
      SELECT company_id FROM cpa_clients 
      WHERE cpa_firm_id IN (
        SELECT cpa_firm_id FROM cpa_staff WHERE user_id = auth.uid()
      )
    )
  );
```

---

## POWERSYNC SCHEMA

```dart
// lib/db/schema.dart
import 'package:powersync/powersync.dart';

final schema = Schema([
  Table('companies', [
    Column.text('name'),
    Column.text('trade'),
    Column.text('phone'),
    Column.text('email'),
  ]),
  
  Table('customers', [
    Column.text('company_id'),
    Column.text('name'),
    Column.text('email'),
    Column.text('phone'),
    Column.text('address'), // JSON stored as text
  ]),
  
  Table('jobs', [
    Column.text('company_id'),
    Column.text('customer_id'),
    Column.text('assigned_to'),
    Column.text('title'),
    Column.text('status'),
    Column.text('scheduled_start'),
    Column.real('total'),
  ]),
  
  Table('time_entries', [
    Column.text('company_id'),
    Column.text('user_id'),
    Column.text('job_id'),
    Column.text('clock_in'),
    Column.text('clock_out'),
    Column.real('total_hours'),
  ]),
  
  // Add remaining tables...
]);
```

---

## SUPABASE SETUP CHECKLIST

```
[ ] Create Supabase project
[ ] Run schema migrations (all tables)
[ ] Enable Row Level Security on ALL tables
[ ] Create get_user_company_id() + get_user_role() functions
[ ] Create tenant isolation RLS policies for every table
[ ] Create role-based RLS policies (tech sees assigned only)
[ ] Create CPA cross-company read policies
[ ] Create client portal read policies
[ ] Create audit_log table (append-only, no update/delete policies)
[ ] Create audit trigger function + apply to all business tables
[ ] Create login_attempts table
[ ] Create user_sessions table
[ ] Create role_permissions table with defaults
[ ] Set up field-level encryption for SSNs/bank accounts (pgcrypto)
[ ] Create indexes for audit_log queries
[ ] Configure auth providers (email, Google, Apple, Phone/SMS)
[ ] Set up storage buckets (photos, documents, employee-docs, call-recordings)
[ ] Configure storage access rules (signed URLs for private buckets)
[ ] Create Edge Functions (or set up Cloudflare Workers)
[ ] Configure PowerSync connection
[ ] Set up environment variables in Flutter
[ ] Test real-time subscriptions
[ ] Test offline sync
[ ] Verify RLS policies block cross-tenant access
[ ] Verify audit triggers log all CRUD operations
```

**SECURITY IS BUILT INTO THE MIGRATION, NOT BOLTED ON AFTER.**
**See `Locked/30_SECURITY_ARCHITECTURE.md` for complete security spec.**

---

## MIGRATION ORDER

```
PHASE 1: Foundation + Security (Day 1 Morning)
───────────────────────────────────────────────
1. Create Supabase project
2. Run database schema (all tables including audit_log, sessions, login_attempts)
3. Enable RLS on ALL tables
4. Create tenant isolation + role-based RLS policies
5. Create CPA cross-company + client portal policies
6. Create audit trigger function + apply to all business tables
7. Set up auth (email, Google, Apple, Phone/SMS)
8. Set up storage buckets with access rules
9. Configure field-level encryption (pgcrypto) for SSNs/bank accounts
10. Seed default role_permissions per company

PHASE 2: PowerSync (Day 1 Afternoon)
────────────────────────────────────
1. Add PowerSync to Flutter
2. Define sync schema
3. Configure Supabase connector
4. Test offline queries

PHASE 3: Service Migration (Day 2)
──────────────────────────────────
1. Update all service files
2. Update model fromJson/toJson
3. Update auth service (Firebase Auth → Supabase Auth)
4. Update storage service (Firebase Storage → Supabase Storage)
5. Add MFA setup for owner/admin/CPA roles
6. Add session timeout per role
7. Add brute force lockout logic
8. Test each feature

PHASE 4: Verification (Day 2 Evening)
─────────────────────────────────────
1. Test offline mode
2. Test real-time updates
3. Test all CRUD operations
4. Test auth flows (including MFA)
5. Test file uploads (signed URLs working)
6. Verify RLS: Tech cannot see other techs' jobs
7. Verify RLS: Company A cannot see Company B data
8. Verify audit_log capturing all changes
9. Verify SSN encryption (cannot read raw value in DB)
```

---

## WHAT THIS ENABLES (The Payoff)

| Feature | Before (Firebase) | After (Supabase) |
|---------|:-----------------:|:----------------:|
| CPA cross-client queries | 50+ queries, slow | 1 query, instant |
| Payroll aggregations | Manual counting | Native SQL SUM/AVG |
| Revenue reports | Read all docs | One GROUP BY |
| Complex filtering | Limited, expensive | Full SQL WHERE |
| Data integrity | No foreign keys | Full referential integrity |
| Transactions | Limited | Full ACID |
| BI tools | Hard to connect | Native SQL connection |
| Cost at 10k companies | $3,000+/mo | $800/mo |
| Migration later | Guaranteed pain | Never needed |

---

## ROLLBACK PLAN

If something goes catastrophically wrong:

1. Firebase project still exists (don't delete)
2. Revert Flutter to Firebase branch
3. Data is still in Firestore

**Risk is low. Supabase is production-ready.**

---

### Security Tables (From 30_SECURITY_ARCHITECTURE.md)

```sql
-- Audit Log (APPEND-ONLY — no update/delete policies ever)
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID,
  user_id UUID NOT NULL,
  user_email TEXT,
  user_role TEXT,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  session_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Session Management
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  device_id TEXT,
  device_name TEXT,
  ip_address INET,
  user_agent TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_revoked BOOLEAN DEFAULT FALSE,
  revoked_reason TEXT,
  mfa_verified BOOLEAN DEFAULT FALSE
);

-- Brute Force Protection
CREATE TABLE login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_address INET NOT NULL,
  success BOOLEAN NOT NULL,
  failure_reason TEXT,
  attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Role Permissions (granular, customizable per company)
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  role TEXT NOT NULL,
  resource TEXT NOT NULL,
  can_create BOOLEAN DEFAULT FALSE,
  can_read BOOLEAN DEFAULT FALSE,
  can_read_own BOOLEAN DEFAULT FALSE,
  can_update BOOLEAN DEFAULT FALSE,
  can_update_own BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  can_export BOOLEAN DEFAULT FALSE,
  field_restrictions TEXT[],
  UNIQUE(company_id, role, resource)
);
```

---

**END OF DATABASE MIGRATION SPEC — LOCKED FEBRUARY 5, 2026 (Session 29)**
**SECURITY IS BUILT IN, NOT BOLTED ON — See 30_SECURITY_ARCHITECTURE.md**
**DO THIS MIGRATION BEFORE BUILDING NEW FEATURES**
