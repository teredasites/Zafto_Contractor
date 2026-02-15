# ZAFTO — DevOps & Operational Security Infrastructure
## Created: February 5, 2026 (Session 30)

---

## PURPOSE

The database and application security architecture (docs 29 + 30) is enterprise-grade. This document covers the **operational infrastructure** that wraps around it — CI/CD, environments, monitoring, testing, secrets management, and compliance. Without this layer, the security architecture has gaps that would fail an enterprise audit and create blind spots in production.

**This is not optional.** Every item in Phase 1 and Phase 2 must be completed before launch. Phase 3 items are pre-enterprise-sales requirements.

---

## PHASED IMPLEMENTATION TIMELINE

| Phase | When | Effort | What |
|-------|------|--------|------|
| **Phase 1** | **NOW — Before database migration (Sprint 5)** | ~2 hours | Dev/staging/prod environments, secrets management, Dependabot |
| **Phase 2** | **During wiring (Sprint 6) + Launch prep** | ~8-12 hours | Crash reporting, automated tests, CI/CD pipeline, incident response |
| **Phase 3** | **Pre-enterprise sales / when revenue justifies** | Varies | SOC 2 audit, DNSSEC/DMARC/SPF/DKIM, pen testing |

---

## PHASE 1 — DO NOW (Before Database Migration)

### 1A. Environment Separation (Dev / Staging / Prod)

**Three Supabase projects. Same schema. Same RLS. Different data.**

| Environment | Purpose | Who touches it |
|-------------|---------|---------------|
| `zafto-dev` | Break things here. Test new features, experiment with schema changes. | You during development |
| `zafto-staging` | Verify here. Mirror of prod with test data. Pre-launch validation. | You before deploying to prod |
| `zafto-prod` | Customers touch this. Real data. Protected. | Live users only |

**Setup (one-time, ~30 minutes):**
1. Create 3 Supabase projects under the same org
2. Run the same migration SQL (from `Locked/29_DATABASE_MIGRATION.md`) on all three
3. Apply identical RLS policies to all three
4. Configure PowerSync to point at dev by default, staging/prod via env variable
5. Flutter app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from environment config
6. Next.js apps (web-portal, client-portal) read from `.env.local` / `.env.staging` / `.env.production`

**Rules:**
- NEVER develop against prod
- NEVER put real customer data in dev
- Schema changes go: dev → staging → prod (never skip staging once it exists)
- Each environment has its own Supabase Auth, Storage, and Edge Functions

**Once set up, you never think about this again.** You develop against dev. When ready to ship, promote to staging, verify, promote to prod.

### 1B. Secrets Management

**Problem:** API keys (Stripe, Anthropic, Telnyx, Supabase service role) currently live in local files. Laptop theft = full compromise.

**Solution:** Move all secrets to Supabase Vault + platform environment variables.

| Secret | Where It Lives Now | Where It Should Live |
|--------|--------------------|---------------------|
| STRIPE_SECRET_KEY | env.dart / .env | Supabase Vault (prod), env vars (dev/staging) |
| STRIPE_WEBHOOK_SECRET | env.dart / .env | Supabase Vault (prod), env vars (dev/staging) |
| ANTHROPIC_API_KEY | env.dart / .env | Supabase Vault (prod), env vars (dev/staging) |
| SUPABASE_SERVICE_ROLE_KEY | .env | Supabase Dashboard only (never in code) |
| TELNYX_API_KEY | Not yet configured | Supabase Vault when phone system goes live |
| CHECK_COM_API_KEY | Not yet configured | Supabase Vault when payroll goes live |

**Setup (one-time, ~30 minutes):**
1. Enable Supabase Vault on prod project
2. Store each secret in Vault with descriptive names
3. Edge Functions read secrets from Vault at runtime (not from env files)
4. Remove ALL secrets from local files — `.gitignore` already blocks them
5. Dev/staging use environment variables set in Supabase Dashboard (not in code)

**Key rule:** The service role key NEVER appears in client-side code. Only Edge Functions use it server-side.

### 1C. Dependency Scanning (Dependabot)

**Setup (one-time, ~5 minutes):**
1. Go to `github.com/teredasites/Zafto_Contractor` → Settings → Code security → Enable Dependabot
2. Enable: Dependabot alerts + Dependabot security updates
3. Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  # Flutter/Dart (pub)
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # Web Portal (npm)
  - package-ecosystem: "npm"
    directory: "/web-portal"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # Client Portal (npm)
  - package-ecosystem: "npm"
    directory: "/client-portal"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # GitHub Actions (when CI/CD is set up)
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Once enabled:** GitHub emails you when a dependency has a known vulnerability. It auto-creates a PR with the fix. You review and merge. 2 minutes per occurrence. Runs forever.

---

## PHASE 2 — DURING WIRING + LAUNCH PREP

### 2A. Crash Reporting & Monitoring (During Sprint 6 Wiring)

**Tool:** Sentry (free tier covers early stage — 5K errors/month, 10K transactions/month)

**Setup per app (~15 minutes each):**

| App | Integration |
|-----|-------------|
| Flutter mobile | `sentry_flutter` package — wrap `runApp()` in `SentryFlutter.init()` |
| Web Portal (Next.js) | `@sentry/nextjs` — auto-instruments pages, API routes, server components |
| Client Portal (Next.js) | `@sentry/nextjs` — same as web portal |
| Edge Functions | `@sentry/node` or Supabase built-in logging |

**What it gives you:**
- Every unhandled exception captured with full stack trace
- User context (which company, which role, which screen)
- Performance monitoring (slow API calls, slow page loads)
- Email alerts when new errors appear
- Release tracking (which deploy introduced a bug)

**You do NOT need to watch dashboards.** Sentry emails you when something new breaks. You check it, fix it, move on. If nothing breaks, you never hear from it.

**Add during wiring because:** Each service you wire is a new failure point. Having Sentry in place means you catch issues immediately as you connect real data.

### 2B. Automated Tests (Write During Wiring, Not Separately)

**Strategy:** Don't write tests as a separate phase. Write them AS you wire each system.

| Wiring Phase | Tests to Write | Priority |
|-------------|----------------|----------|
| W1: Core business | Jobs CRUD, Invoices CRUD, Customer CRUD, Auth flows, RBAC enforcement | HIGH |
| W1: Calculators | All 1,186 calculator formulas — input/expected output | **CRITICAL (LIABILITY)** |
| W2: Field tools | Data persistence (capture → offline store → sync → verify), Photo upload | HIGH |
| W3: Missing tools | Same pattern as W2 | HIGH |
| W4: Web portal | Page loads with real data, form submissions, data integrity | MEDIUM |
| W5: Client portal | Same pattern as W4 | MEDIUM |
| W6: Polish | Integration tests, offline/online sync scenarios | MEDIUM |

**Calculator tests are non-negotiable.** A wrong amperage or voltage calculation on a job site is a safety issue and a lawsuit. Every calculator gets a test with known inputs and verified outputs.

**Test tooling:**
- Flutter: `flutter_test` (built-in) + `integration_test`
- Next.js: `vitest` or `jest` + `@testing-library/react`
- Edge Functions: `vitest` or `deno test`
- Supabase RLS: pgTAP (SQL-level tests that verify RLS policies work correctly)

**RLS tests are critical.** Write tests that prove:
- Company A cannot read Company B's data
- Tech role cannot access financial data
- CPA can only see assigned clients
- Client can only see their own projects

**Target by launch:** 80%+ coverage on business logic, 100% on calculators, 100% on RLS policies.

### 2C. CI/CD Pipeline (Launch Prep)

**Tool:** GitHub Actions (free for private repos up to 2,000 minutes/month)

**Set up when preparing to ship to real users.** While it's just you building locally, the overhead isn't justified. At launch, this REPLACES your manual process — less work, not more.

**Pipeline: `.github/workflows/ci.yml`**

```
Trigger: Push to main or PR

Step 1: Run Flutter tests
Step 2: Run calculator tests (ALL 1,186)
Step 3: Run Next.js tests (web portal)
Step 4: Run Next.js tests (client portal)
Step 5: Run RLS policy tests against staging Supabase
Step 6: Build Flutter web
Step 7: Build Next.js apps
Step 8: If all pass + push to main → Deploy to staging
Step 9: Manual approval gate → Deploy to prod
```

**What this means in practice:**
- You push code to GitHub
- GitHub automatically runs all tests
- If anything fails, it blocks the deploy and emails you
- If everything passes, it deploys to staging
- You verify staging, click approve, it deploys to prod
- You never manually build and deploy again

**Flutter mobile (iOS/Android) builds:**
- Add Fastlane for automated App Store / Play Store builds
- Push to `release` branch → builds IPA + APK → uploads to TestFlight / Play Console
- Configure when preparing for app store submission

### 2D. Incident Response Plan (Pre-Launch Document)

**Write this before launch. It's a document, not infrastructure. ~2-3 hours of work.**

Contents:
1. **Severity levels** — S1 (data breach, service down), S2 (feature broken, data integrity), S3 (UI bug, performance), S4 (cosmetic)
2. **Notification timeline** — Who gets notified at each severity, within what window
3. **Breach response** — Step-by-step playbook for data breach:
   - Identify scope (which companies, which data types)
   - Contain (revoke compromised keys, disable affected accounts)
   - Notify affected companies within 72 hours (GDPR) / "without unreasonable delay" (CCPA)
   - Notify state AG if required (varies by state — Connecticut has specific requirements)
   - Document everything in append-only audit log
4. **Key rotation procedure** — How to rotate each API key and secret
5. **Rollback procedure** — How to revert a bad deploy
6. **Contact list** — Your phone, Supabase support, Stripe support, Cloudflare support, legal counsel
7. **Post-incident review** — Template for documenting what happened, why, how to prevent recurrence

**Store this in Build Documentation (it's excluded from the repo by .gitignore). It contains sensitive operational details.**

---

## PHASE 3 — PRE-ENTERPRISE SALES

These items become necessary when large GCs, property management companies, or enterprise clients require compliance documentation before signing.

### 3A. SOC 2 Type II

**When:** When revenue justifies the $15-50K audit cost, or when an enterprise deal requires it.

**Why you're ahead:** The security architecture (doc 30) already gives you:
- ✅ Append-only audit log (controls AC-1, AC-2)
- ✅ RBAC with principle of least privilege (AC-3, AC-5, AC-6)
- ✅ Encryption at rest and in transit (SC-8, SC-28)
- ✅ MFA (IA-2)
- ✅ Session management + brute force protection (AC-7, SC-10)
- ✅ RLS tenant isolation (AC-4)

**What you'll still need:**
- Formal security policies documented (information security policy, acceptable use, etc.)
- Employee background checks and security training (when you hire)
- Vendor risk assessments (for Supabase, Stripe, Cloudflare, etc.)
- Business continuity / disaster recovery plan
- Penetration test results
- 6-12 months of audit evidence (logs proving controls work over time)

**Action now:** Nothing. Just keep building with the security architecture as spec'd. The audit log collects evidence automatically. When the time comes, you're documenting what already exists.

### 3B. Domain Security (When Phone System + Email Go Live)

**DNSSEC:**
- Enable in Cloudflare for all ZAFTO domains
- Prevents DNS spoofing/hijacking
- One toggle in Cloudflare dashboard

**Email Authentication (when professional email launches per doc 28):**

| Record | Purpose | Setup |
|--------|---------|-------|
| SPF | Declares which servers can send email for your domain | TXT record in DNS |
| DKIM | Cryptographically signs outgoing email | Generated by email provider (Cloudflare Email Routing / SendGrid) |
| DMARC | Policy for what to do with email that fails SPF/DKIM | TXT record: start with `p=none` (monitor), move to `p=reject` |

**Why this matters:** When contractors send invoices and estimates from `info@theircompany.com` via ZAFTO, email spoofing could let attackers send fake invoices from that address. DMARC prevents this.

**Setup:** One-time DNS configuration per domain. ~15 minutes per contractor domain (automate this in the Website Builder domain setup flow).

### 3C. Penetration Testing

**When:** Before first enterprise contract, or before handling significant volume of financial data.

**What:** Hire a third-party security firm to attempt to breach your platform. They test:
- API endpoint security
- RLS bypass attempts
- Authentication weaknesses
- OWASP Top 10 vulnerabilities
- Mobile app reverse engineering
- Edge Function security

**Cost:** $5-25K depending on scope.

**Action now:** Nothing. Build with the security architecture. When you're ready, the pen testers validate what you've built rather than finding fundamental flaws.

---

## CHECKLIST FORMAT

### ☐ Phase 1 — Before Database Migration
- [ ] Create 3 Supabase projects (dev / staging / prod)
- [ ] Run migration SQL on all three environments
- [ ] Apply RLS policies to all three
- [ ] Configure environment-specific connection strings
- [ ] Move all API secrets to Supabase Vault (prod) / Dashboard env vars (dev/staging)
- [ ] Remove all secrets from local code files
- [ ] Verify `.gitignore` blocks all secret patterns (DONE — already in place)
- [ ] Enable Dependabot on Zafto_Contractor repo
- [ ] Create `.github/dependabot.yml`

### ☐ Phase 2A — During Wiring (Sprint 6)
- [ ] Add `sentry_flutter` to mobile app
- [ ] Add `@sentry/nextjs` to web portal
- [ ] Add `@sentry/nextjs` to client portal
- [ ] Configure Sentry email alerts
- [ ] Write calculator tests (ALL 1,186 — non-negotiable)
- [ ] Write CRUD tests for each system as it's wired
- [ ] Write RLS policy tests (pgTAP)
- [ ] Write auth flow tests (login, MFA, session, role enforcement)

### ☐ Phase 2B — Launch Prep
- [ ] Create `.github/workflows/ci.yml` (CI/CD pipeline)
- [ ] Configure staging auto-deploy
- [ ] Configure prod manual-approval deploy
- [ ] Write incident response plan
- [ ] Set up key rotation procedures
- [ ] Set up rollback procedures
- [ ] Configure Fastlane for mobile builds (when submitting to app stores)

### ☐ Phase 3 — Pre-Enterprise Sales
- [ ] Enable DNSSEC on all ZAFTO domains
- [ ] Configure SPF/DKIM/DMARC for email domains
- [ ] Automate email auth in Website Builder domain setup
- [ ] Commission penetration test
- [ ] Begin SOC 2 readiness assessment
- [ ] Document formal security policies
- [ ] Vendor risk assessments

---

## MONITORING SUMMARY — WHAT RUNS ITSELF

| System | What It Does | Your Involvement |
|--------|-------------|-----------------|
| Dependabot | Scans dependencies weekly, auto-creates PRs for vulnerabilities | Review + merge PRs (~2 min each, occasional) |
| Sentry | Captures every crash, slow query, unhandled error across all apps | Check email when alert fires, fix the bug |
| CI/CD Pipeline | Runs all tests on every push, blocks bad deploys automatically | Push code normally — pipeline handles the rest |
| Supabase Audit Log | Records every data change, login, permission check | Only review when investigating an incident |
| RLS Policies | Enforces tenant isolation at database level, every query, always | Never — it's automatic, can't be bypassed |

**None of this requires you watching dashboards.** Everything is event-driven — it only contacts you when something needs attention.

---

## RULES

1. **Phase 1 items are BLOCKERS for database migration.** Do not proceed to Sprint 5 without environment separation and secrets management.
2. **Calculator tests are non-negotiable before launch.** Wrong calculations = safety hazard + lawsuit.
3. **RLS tests are non-negotiable before launch.** Untested tenant isolation = data breach waiting to happen.
4. **Write tests DURING wiring, not as a separate phase.** Every service wired = tests written for that service.
5. **CI/CD replaces manual deploys at launch.** It's less work, not more.
6. **Incident response plan must exist before first paying customer.**
7. **SOC 2 and pen testing wait until revenue justifies the cost.**
8. **This document is part of Build Documentation and is excluded from the repo by .gitignore.**
