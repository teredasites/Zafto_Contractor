# ZAFTO Information Security Policy

**Tereda Software LLC (DBA: ZAFTO)**
**Effective Date:** February 7, 2026
**Version:** 1.0
**Owner:** Damian Tereda, CEO
**Contact:** admin@zafto.app

---

## 1. Purpose

This policy establishes the information security framework for ZAFTO, a SaaS platform operated by Tereda Software LLC. It defines the controls, procedures, and responsibilities for protecting customer data, financial information, and system integrity across all ZAFTO applications and infrastructure.

---

## 2. Scope

This policy applies to:
- All ZAFTO applications: Mobile App (iOS), Web CRM (zafto.cloud), Employee Portal (team.zafto.app), Client Portal (client.zafto.cloud), Operations Portal (ops.zafto.cloud)
- All infrastructure: Supabase (PostgreSQL), Cloudflare (CDN/WAF/DNS), Vercel (hosting), GitHub (source control)
- All personnel with access to production systems or customer data
- All third-party integrations and API connections

---

## 3. Data Classification

| Level | Description | Examples |
|-------|-------------|----------|
| **Confidential** | Financial data, PII, credentials | Bank account tokens, SSNs, API keys, passwords |
| **Internal** | Business data, operational records | Job records, invoices, bids, employee data |
| **Public** | Marketing content, public-facing pages | Website content, public documentation |

---

## 4. Access Control

### 4.1 Role-Based Access Control (RBAC)
ZAFTO enforces a 7-tier RBAC model at the database level:
- **super_admin** — Platform operator only (Ops Portal)
- **owner** — Company owner, full access
- **admin** — Company administrator, near-full access
- **office** — Office manager, no financial admin
- **tech** — Field technician, job/tool access only
- **cpa** — Accountant, financial data only
- **client** — End customer, own data only

### 4.2 Row-Level Security (RLS)
Every database table enforces PostgreSQL Row-Level Security policies. Users can only access data belonging to their company (tenant isolation via `company_id`). No application-level filtering — security is enforced at the database layer.

### 4.3 Multi-Factor Authentication (MFA)
- Required for: Owner, Admin, and CPA roles
- **Phishing-resistant MFA supported:** WebAuthn (passkeys, biometrics, hardware security keys such as YubiKey)
- TOTP-based MFA (authenticator apps) supported as secondary option
- Users can enroll passkeys/biometrics from all platforms: Web CRM, Employee Portal, Client Portal, and Mobile App
- All infrastructure accounts (Supabase, GitHub, Cloudflare, Vercel) require MFA with hardware keys

### 4.4 Principle of Least Privilege
- Each role has the minimum permissions necessary for their function
- API keys are scoped per-environment (dev/staging/prod)
- Service role keys are server-side only, never exposed to clients

---

## 5. Encryption

### 5.1 Data in Transit
- All connections use TLS 1.2 or higher
- Enforced by Cloudflare (edge) and Supabase (database)
- HSTS headers enabled on all domains
- No plaintext HTTP connections accepted

### 5.2 Data at Rest
- Supabase PostgreSQL uses AES-256 encryption at rest
- Supabase Storage buckets are encrypted at rest
- All storage buckets are PRIVATE (signed URL access only, time-limited)
- API keys and secrets stored in Supabase Vault (encrypted secret management)

---

## 6. Infrastructure Security

### 6.1 Network Security
- Cloudflare WAF protects all web applications
- DDoS protection via Cloudflare
- Database not directly accessible from public internet (Supabase managed networking)
- Edge Functions run in isolated Deno sandboxes

### 6.2 Environment Separation
- Development and production are separate Supabase projects with separate credentials
- Environment variables are never committed to source control
- `.env` files are gitignored; only `.env.example` templates are tracked

### 6.3 Dependency Management
- Dependabot configured for automated vulnerability scanning (weekly)
- GitHub security alerts enabled for all repositories
- Dependencies reviewed before major version upgrades

---

## 7. Application Security

### 7.1 Authentication
- Supabase Auth handles all authentication (JWT-based)
- Magic link authentication for client portal (passwordless)
- Session tokens expire and rotate automatically
- No custom authentication implementations

### 7.2 Input Validation
- All user input validated at application boundaries
- Parameterized queries via Supabase client (no raw SQL from frontend)
- File uploads restricted by type, size, and scanned before storage

### 7.3 Audit Logging
- All database tables include `created_at` and `updated_at` timestamps
- Compliance records are INSERT-only (immutable audit trail, no update/delete)
- Sensitive operations logged with user ID, timestamp, and action

---

## 8. Data Protection & Privacy

### 8.1 Consumer Data
- Consumer financial data (via Plaid) is accessed only with explicit user consent through Plaid Link
- Bank tokens are stored server-side only, never exposed to frontend
- Data is used solely for the stated purpose (bookkeeping reconciliation, income verification)

### 8.2 Data Retention
- Active account data retained for duration of service
- Soft-delete pattern used (data marked deleted, not purged immediately)
- Deleted data purged after 90-day retention period
- Users can request full data export or deletion

### 8.3 Data Sharing
- Consumer data is NEVER sold or shared with third parties
- Data shared only with service providers necessary for platform operation (Supabase, Stripe, Plaid)
- All third-party providers are SOC 2 compliant

---

## 9. Incident Response

### 9.1 Monitoring
- Sentry error tracking deployed across all 4 web applications and mobile app
- Real-time error alerts configured
- Supabase dashboard monitoring for database health

### 9.2 Response Procedure
1. **Detect** — Automated alerts via Sentry or manual report
2. **Contain** — Isolate affected systems, revoke compromised credentials
3. **Investigate** — Root cause analysis using audit logs
4. **Remediate** — Deploy fix, verify resolution
5. **Notify** — Affected users notified within 72 hours per applicable regulations
6. **Document** — Incident logged with timeline, impact, and remediation steps

---

## 10. Vulnerability Management

- Automated dependency scanning via Dependabot (weekly)
- GitHub security alerts for known CVEs
- Critical vulnerabilities patched within 48 hours
- Regular review of OWASP Top 10 during development

---

## 11. Personnel Security

- All personnel with production access use MFA
- Access revoked immediately upon role change or departure
- Background checks conducted for employees handling financial data (via Checkr)

---

## 12. Business Continuity

- Database backups managed by Supabase (daily automated backups, point-in-time recovery)
- Source code hosted on GitHub with full version history
- Infrastructure can be redeployed from code within hours
- No single point of failure — all services are managed/hosted platforms

---

## 13. Policy Review

This policy is reviewed and updated:
- Annually at minimum
- After any security incident
- When significant infrastructure changes occur
- Before onboarding new third-party integrations handling sensitive data

---

**Approved by:** Damian Tereda, CEO, Tereda Software LLC
**Date:** February 7, 2026
