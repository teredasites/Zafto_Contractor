# ZAFTO OPS PORTAL — Founder OS + Marketing Engine
## Created: February 5, 2026 (Session 31)
## Status: LOCKED — Build LAST (after all customer-facing features wired + debugged)

---

## PURPOSE

Single sign-in command center for running the entire ZAFTO operation AND the entire
business behind it. Customer management, support, platform health, revenue, AI operations,
content management, marketing engine, unified email, banking, legal, dev terminal, and a
private Claude instance that knows everything and talks like a co-founder.

One person. One portal. Full control. Zero tab-switching.

**URL:** `ops.zafto.cloud`
**Tech:** Next.js 15, TypeScript, Tailwind CSS, Supabase (same stack as CRM/Client Portal)
**Auth:** `super_admin` role — cross-tenant read access, restricted write permissions
**AI:** Private Claude instance with full platform + business context (NOT the customer-facing Z Intelligence)
**Design accent:** Deep navy/teal (distinct from contractor orange and client Stripe purple)
**Design quality:** Same "Linear meets Stripe" standard — internal doesn't mean ugly

---

## WHAT THIS REPLACES

Without this portal, running ZAFTO means juggling:

| Tool | What You'd Use It For | Replaced By |
|------|----------------------|-------------|
| Supabase Dashboard | Database queries, user management | Ops Portal — Accounts |
| Stripe Dashboard | Revenue, failed payments, subscriptions | Ops Portal — Revenue |
| Sentry Dashboard | Error monitoring, crash reports | Ops Portal — Health |
| Gmail / Zendesk | Customer support + personal email | Ops Portal — Unified Inbox |
| Mailchimp / SendGrid | Email campaigns | Ops Portal — Marketing Engine |
| Google Analytics | Traffic, conversion funnels | Ops Portal — Analytics |
| Google Ads / Meta Ads | Ad campaigns | Ops Portal — Ad Manager |
| Ahrefs / SEMrush | SEO monitoring | Ops Portal — SEO Dashboard |
| Notion / Sheets | Prospect tracking | Ops Portal — Prospect Pipeline |
| Manual research | Finding contractor emails | Ops Portal — Contractor Discovery Engine |
| HubSpot / Salesforce | CRM for YOUR sales pipeline | Ops Portal — Growth CRM |
| Gmail + Outlook + ProtonMail | Multiple email accounts | Ops Portal — Unified Inbox |
| Bank websites (Chase, etc.) | Check balances, transactions | Ops Portal — Banking & Treasury |
| QuickBooks (for Tereda LLC) | Your own books | Ops Portal — Treasury (Plaid-powered) |
| GitHub Desktop / CLI | Code management, deploys | Ops Portal — Dev Terminal |
| VS Code terminal | Claude Code, testing, debugging | Ops Portal — Dev Terminal |
| LegalZoom / Rocket Lawyer | Entity management, compliance | Ops Portal — Legal Department |
| 1Password / Bitwarden | Service credentials | Ops Portal — Credential Vault |
| Apple Developer Console | App Store submissions, certs | Ops Portal — Service Hub (deep link + status) |
| Google Play Console | Play Store submissions | Ops Portal — Service Hub (deep link + status) |

**Total replaced: 17+ tools. Thousands per year in subscriptions. Zero context switching.**
**The AI assistant in this portal talks like a co-founder — full context, direct, gets it done.**

---

## ARCHITECTURE

```
ops.zafto.cloud (Next.js 15)
       │
       ├── Supabase PostgreSQL ──── Same database as contractor CRM
       │     (super_admin role bypasses tenant RLS for READ)
       │     (write operations scoped + audit-logged)
       │
       ├── Stripe API ──────────── Revenue, subscriptions, failed payments
       │
       ├── Sentry API ──────────── Errors, performance, crash reports
       │
       ├── Claude API ──────────── Private ops AI (full business context)
       │     - Drafts emails, analyzes data, writes code
       │     - Runs terminal commands (sandboxed)
       │     - Generates legal docs, marketing copy, support responses
       │
       ├── Telnyx API ──────────── Phone system health, call logs
       │
       ├── Cloudflare API ─────── Domain health, WAF events, traffic
       │
       ├── SendGrid API ────────── Email campaigns, deliverability
       │
       ├── Plaid API ───────────── YOUR bank accounts (business treasury)
       │
       ├── IMAP/SMTP ──────────── Unified inbox (all email accounts)
       │
       ├── GitHub API ──────────── Repos, PRs, deployments, Actions status
       │
       ├── State License APIs ──── Contractor discovery (public databases)
       │
       ├── Google Ads API ─────── Ad campaign management
       │
       ├── Meta Ads API ────────── Facebook/Instagram ad management
       │
       ├── Google Search Console ─ SEO performance, indexing
       │
       ├── Apple App Store Connect API ── App status, reviews, crashes
       │
       └── Google Play Developer API ──── App status, reviews, crashes
```

### Security Model

```sql
-- New role: super_admin (Robert / platform operator)
-- Cross-tenant READ on all ZAFTO platform tables
-- Restricted WRITE (support actions, content updates, announcements)
-- ALL actions audit-logged with reason field
-- MFA required (hardware key recommended)
-- IP allowlist optional (home + mobile IPs)
-- Session timeout: 4 hours

CREATE POLICY ops_super_admin_read ON ALL TABLES
  FOR SELECT USING (
    auth.jwt()->>'role' = 'super_admin'
  );

-- Write operations go through Edge Functions with audit logging
-- No direct table writes — everything through controlled endpoints
```

### Credential Vault

Every external service credential stored encrypted in Supabase Vault:

| Service | Credentials Stored | Auto-Refresh |
|---------|-------------------|:------------:|
| Stripe | API keys (test + live) | No |
| Supabase | Service role key, anon key | No |
| Claude/Anthropic | API key | No |
| Cloudflare | API token, Zone IDs | No |
| Telnyx | API key, connection IDs | No |
| SendGrid | API key | No |
| Plaid | Client ID, Secret (sandbox + production) | No |
| GitHub | Personal access token | Yes (90 days) |
| Google Ads | OAuth refresh token | Yes |
| Meta Ads | OAuth access token | Yes (60 days) |
| Apple App Store Connect | API key + Issuer ID | No |
| Google Play | Service account JSON | No |
| Google Search Console | OAuth refresh token | Yes |
| IMAP/SMTP | Email passwords per account | No |

All credentials encrypted at rest (AES-256). Never exposed in UI — only used server-side.
One-click rotation with deployment verification for each service.

---

## SECTION 1: COMMAND CENTER (Home Dashboard)

**Route:** `/`

The first thing you see every morning. Everything that needs attention, AI-summarized.

### Morning Briefing Card
Claude generates a daily briefing from ALL data sources:
- New signups overnight (count + breakdown by trade/tier)
- Revenue collected overnight (Stripe)
- Failed payments needing attention
- Support tickets waiting
- Platform errors in last 24 hours
- Marketing campaign performance
- Churn risk alerts
- Marketplace health (when live)
- Bank account balances + overnight transactions
- Email inbox summary (what needs response)
- GitHub: open PRs, failed CI runs, Dependabot alerts
- App Store: new reviews, rating changes
- Legal: upcoming deadlines, expiring documents

### Real-Time Metrics Bar

| Metric | Source |
|--------|--------|
| Active Companies | Supabase |
| MRR | Stripe |
| Active Users (24h) | Supabase sessions |
| Open Support Tickets | Supabase |
| Platform Error Rate | Sentry |
| AI API Cost (MTD) | Claude API |
| Cash Position | Plaid (all accounts) |
| Unread Emails | IMAP |
| Prospect Pipeline Value | Growth CRM |
| App Store Rating | ASC + Google Play |

### Action Queue
Priority-sorted list of things needing human attention:
- Failed payments (auto-retried 3x, needs manual intervention)
- Support tickets older than 4 hours
- Sentry errors with >10 occurrences
- Companies that haven't logged in for 7+ days (churn risk)
- Expiring trials (3 days left, no conversion)
- Marketplace complaints
- Content corrections flagged by users
- Emails flagged as needing personal response
- Legal deadlines approaching
- Bank transactions needing categorization
- App Store reviews needing response (especially negative)

---

## SECTION 2: UNIFIED INBOX

**Route:** `/inbox`

Every email account in one view. Claude pre-triages everything.

### Connected Accounts
All your email accounts displayed in a single unified inbox:

| Account | Type | Purpose |
|---------|------|---------|
| robert@tereditasoftware.com | Business | Primary business email |
| support@zafto.app | Support | Customer support inbound |
| info@zafto.app | General | Marketing, partnerships |
| hello@zafto.app | Sales | Inbound sales inquiries |
| Personal Gmail | Personal | Personal (filtered separately) |

**Tech:** IMAP/SMTP connections stored encrypted. Emails fetched server-side via
Supabase Edge Function on a 1-minute poll cycle. Full-text search indexed in PostgreSQL.

### AI Triage
Every incoming email gets auto-classified by Claude:

| Category | Action | Example |
|----------|--------|---------|
| **Support** | Creates support ticket, drafts response | "My invoices won't send" |
| **Sales Inquiry** | Creates prospect record, drafts response | "How much does ZAFTO cost?" |
| **Partnership** | Flags for personal review, summarizes | "We'd like to integrate with..." |
| **Legal** | Flags HIGH priority, routes to Legal section | "Cease and desist", "Terms update" |
| **Financial** | Routes to Treasury, categorizes | Bank notifications, Stripe receipts |
| **Marketing** | Archives or flags | Newsletter replies, PR pitches |
| **Spam/Noise** | Auto-archives | Promotions, automated notifications |
| **Personal** | Separate tab, no AI processing | Personal Gmail items |

### Inbox UI

```
┌──────────────────────────────────────────────────────────────┐
│  INBOX          [All] [Support] [Sales] [Legal] [Personal]  │
│                 [Compose]  [Search]                          │
├──────────────────────────────────────────────────────────────┤
│  ● HIGH  Legal Notice — Trademark inquiry from...     2h    │
│  ● MED   Sales — "Interested in ZAFTO for my HVAC..."  4h  │
│  ● MED   Support — [Ticket #127] "Can't clock in..."   5h  │
│  ● LOW   Partnership — "SaaS integration proposal..."  8h  │
│  ○        Bank of America — Direct deposit received   12h   │
│  ○        GitHub — Dependabot: 3 security updates     14h   │
└──────────────────────────────────────────────────────────────┘
```

### Compose + AI Drafting
- Compose from any connected account
- Claude drafts responses based on context (who sent it, what they want, relevant data)
- Rich text + attachments
- Templates for common responses
- Schedule send
- Follow-up reminders ("remind me if no response in 3 days")

### Email-to-Action
Emails can trigger workflows:
- Support email → auto-creates support ticket
- Sales inquiry → auto-creates prospect in Growth CRM
- Invoice from vendor → auto-categorizes in Treasury
- Legal notice → creates Legal task with deadline
- App Store review notification → surfaces in App Store section

---

## SECTION 3: ACCOUNTS + CUSTOMER MANAGEMENT

**Route:** `/accounts`

### Company Directory
**Route:** `/accounts/companies`

Every company on the platform in one searchable, filterable view.

| Column | Data |
|--------|------|
| Company Name | From companies table |
| Owner Name | Primary user |
| Trade(s) | Electrical, Plumbing, etc. |
| Tier | Solo / Pro / Team / Business / Enterprise |
| MRR | From Stripe |
| Users | Active / Total |
| Signup Date | From companies table |
| Last Active | Most recent session |
| Health Score | Calculated (usage + payments + support history) |
| Status | Active / Trial / Past Due / Churned / Suspended |

Filters: Trade, tier, status, signup date range, state/region, health score range
Sort: Any column
Search: Company name, owner name, email, domain
Export: CSV for any filtered view

### Company Detail
**Route:** `/accounts/companies/[id]`

Click into any company and see everything.

**Overview Tab:**
- Company info (name, address, trade, tier, subscription)
- Account health score with breakdown
- Owner + team members (names, roles, last active)
- Subscription history (upgrades, downgrades, pauses)
- Total lifetime value
- Referral source

**Usage Tab:**
- Feature usage heatmap
- Jobs created / completed this month
- Invoices sent / paid
- AI queries used vs limit
- Calculator usage patterns, field tool usage
- Storage used (photos, documents)
- Login frequency graph

**Financial Tab:**
- Payment history (every Stripe charge)
- Current payment method status
- Failed payment history
- Upcoming renewal
- Discounts / coupons applied
- Revenue attribution (which campaign brought them)

**Support Tab:**
- All support tickets for this company
- Resolution history, satisfaction scores
- Internal notes

**Impersonation (Read-Only):**
- "View as this company" button
- Opens their CRM dashboard in read-only mode
- See exactly what they see — their data, their layout, their experience
- NEVER write/modify — read-only with audit log entry

**Actions:**
- Extend trial, apply discount/coupon, change tier
- Suspend account (with reason, reversible)
- Send direct message (in-app notification)
- Add internal note, flag for churn risk
- Export their data (data portability requests)

### User Directory
**Route:** `/accounts/users`

Every individual user across all companies.

| Column | Data |
|--------|------|
| Name | Full name |
| Email | Login email |
| Company | Linked company |
| Role | Owner / Admin / Office / Tech / CPA / Client |
| Last Login | Timestamp |
| MFA Enabled | Yes / No |
| Status | Active / Invited / Suspended / Deleted |

Actions: Reset password, force MFA, unlock account, revoke sessions, view login history + IPs, view audit log

---

## SECTION 4: SUPPORT CENTER

**Route:** `/support`

### Ticket Queue
**Route:** `/support/tickets`

All inbound support in one queue — email, in-app, chat.

| Column | Data |
|--------|------|
| Ticket # | Auto-generated |
| Company | Linked account |
| Subject | User's description |
| Category | Billing / Bug / Feature Request / How-To / Account / Emergency |
| Priority | Low / Medium / High / Critical |
| Status | New / In Progress / Waiting on Customer / Resolved / Closed |
| Age | Time since created |
| AI Draft | Claude's suggested response (pre-generated) |

**Auto-categorization:** Claude reads the ticket, assigns category + priority, drafts response before you open it.

**Context panel (right side):**
- Company details (tier, trade, health)
- Their recent activity
- Recent errors in their account (Sentry)
- Past tickets from this company
- Related knowledge base articles

### AI Response Drafting
For every ticket, Claude pre-generates:
1. Category + Priority (auto-assigned, overridable)
2. Root Cause Analysis (checks their account for probable issue)
3. Draft Response (ready to send, you review and click)
4. Internal Note (what Claude thinks is actually going on)
5. Follow-Up Suggestion

Target: 2 minutes per ticket (vs 10-15 without AI)

### Auto-Resolution (Zero-Touch)

| Trigger | Auto-Response | Auto-Action |
|---------|--------------|-------------|
| "Reset my password" | Reset email sent | Reset link generated |
| "How do I [common question]" | KB article linked | None |
| "My payment failed" | Payment update instructions | Stripe retry triggered |
| "Cancel my account" | Retention offer + cancel link | Flag for review |

Auto-resolved tickets go to "Reviewed" queue — scan daily to verify Claude handled correctly.

### Knowledge Base Manager
**Route:** `/support/knowledge-base`

Articles Claude references for drafting AND customers can browse.
- Create/edit with rich text, tag by category/feature/trade
- Track most-referenced articles
- AI suggests new articles: "This question asked 14 times this month — create article?"

### Customer Satisfaction
**Route:** `/support/satisfaction`

Post-resolution survey (1-5 stars + optional comment). Satisfaction trend, per-category scores,
low-satisfaction tickets flagged, NPS calculation (quarterly).

---

## SECTION 5: PLATFORM HEALTH

**Route:** `/health`

### System Status
**Route:** `/health/status`

Real-time status of every system component:

| Component | Source | Metrics |
|-----------|--------|---------|
| Supabase Database | Supabase API | Connection pool, query latency, storage |
| Supabase Auth | Supabase API | Login success rate, MFA adoption |
| Supabase Edge Functions | Supabase API | Invocations, errors, cold starts |
| Supabase Storage | Supabase API | Bandwidth, storage, signed URLs |
| PowerSync | PowerSync API | Sync queue depth, conflict rate |
| Stripe | Stripe API | Webhook delivery, payment success rate |
| Claude API | Anthropic API | Latency, error rate, tokens, cost |
| Telnyx | Telnyx API | Call quality, SMS delivery |
| SendGrid | SendGrid API | Deliverability, bounces, spam |
| Cloudflare | Cloudflare API | Cache hits, WAF blocks, DDoS |
| Sentry | Sentry API | Error count, unresolved, affected users |
| GitHub Actions | GitHub API | CI/CD status, test results |
| Apple App Store | ASC API | App review status, crashes |
| Google Play | GP API | App review status, ANRs |

Auto-generated public status page at `status.zafto.app`.

### Error Dashboard
**Route:** `/health/errors`

Sentry errors with context — grouped by frequency, filtered by severity, linked to affected
companies/users, stack traces, resolution tracking. One-click "create fix task."

### Performance Dashboard
**Route:** `/health/performance`

API response time percentiles (p50, p95, p99), page load times by route, slow database
queries highlighted, Edge Function times, mobile crash rate (by OS/device/version),
Web Vitals (LCP, FID, CLS) for CRM + Client Portal.

### Infrastructure Costs
**Route:** `/health/costs`

Monthly cost tracking with projections at 500, 5,000, and 50,000 companies.
Cost-per-customer calculation, margin analysis, alerts on cost spikes.
Covers: Supabase, Claude API, Telnyx, SendGrid, Stripe fees, Cloudflare, Sentry, Plaid.

---

## SECTION 6: REVENUE + FINANCIAL INTELLIGENCE

**Route:** `/revenue`

### Revenue Dashboard
**Route:** `/revenue/dashboard`

| Metric | Visualization |
|--------|--------------|
| MRR / ARR | Line graph + current |
| MRR Growth Rate | Month-over-month % |
| Net Revenue Retention | Expansion - contraction - churn |
| ARPA (Avg Revenue Per Account) | MRR / active companies |
| Customer Lifetime Value | Historical average |
| CAC (Customer Acquisition Cost) | Marketing spend / new customers |
| LTV:CAC Ratio | Target: >3:1 |
| Monthly Churn Rate | Lost MRR / Starting MRR |
| Trial-to-Paid Conversion | By cohort |
| Time to First Value | Days from signup to first job created |

### Subscription Management
**Route:** `/revenue/subscriptions`

Every active subscription with Stripe details. Upcoming renewals (30 days), failed payments
with retry status, cancellations with reasons, downgrades (flag for outreach), upgrades
(flag for case study). Revenue by tier, trade, region.

### Churn Analysis
**Route:** `/revenue/churn`

AI-powered churn prediction with weighted scoring:
- Login frequency declining (14-day comparison)
- Feature usage declining
- Support tickets increasing
- Payment failures
- Team member removals
- No new jobs created in X days
- Competitor mentions in support tickets

Dashboard: companies ranked by churn probability, recommended intervention,
one-click outreach, win-back campaigns for recently churned.

### Cohort Analysis
**Route:** `/revenue/cohorts`

Monthly signup cohorts, retention curves (1/3/6/12 months), revenue retention by cohort,
feature adoption by cohort. Identify what separates sticky vs churning cohorts.

---

## SECTION 7: BANKING & TREASURY

**Route:** `/treasury`

Your actual business finances. Not contractor finances — YOUR company books.

### Bank Connections (Plaid)
**Route:** `/treasury/accounts`

Connect all Tereda Software LLC bank accounts:

| Account | Type | What It Shows |
|---------|------|--------------|
| Business Checking | Primary operating | Revenue deposits, expenses, payroll |
| Business Savings | Reserve | Tax reserves, emergency fund |
| Business Credit Card | Expenses | All business purchases |
| Additional accounts | As needed | Investment, secondary checking |

Real-time balances updated every 15 minutes via Plaid.
Transaction history with full-text search.

### Cash Flow Dashboard
**Route:** `/treasury/cash-flow`

| Metric | Source |
|--------|--------|
| Current Cash Position | Plaid (all accounts summed) |
| Monthly Burn Rate | Calculated from transactions |
| Runway | Cash / Burn rate |
| Revenue This Month | Stripe |
| Expenses This Month | Plaid (categorized) |
| Net Income (MTD) | Revenue - Expenses |
| Tax Reserve Status | % of revenue set aside |
| Upcoming Bills | Recurring transaction detection |

### Auto-Categorization
Every bank transaction auto-categorized by Claude:

| Category | Examples |
|----------|---------|
| Infrastructure | Supabase, Cloudflare, Sentry |
| AI Services | Anthropic API charges |
| Communications | Telnyx, SendGrid |
| Payment Processing | Stripe fees |
| Development | GitHub, Apple Developer, domain renewals |
| Marketing | Google Ads, Meta Ads |
| Legal | Attorney fees, trademark filings |
| Office | Software subscriptions, equipment |
| Tax Payments | Quarterly estimates, state fees |

One-click override if Claude categorizes wrong. Learns from corrections.

### Tax Intelligence
**Route:** `/treasury/taxes`

- Quarterly estimated tax calculation (federal + CT state)
- Tax reserve tracking (is enough set aside?)
- Deduction identification (home office, equipment, software, mileage)
- Year-end prep checklist
- CPA export (CSV/PDF of all categorized transactions)
- 1099 tracking for any contractors you hire

### Financial Projections
**Route:** `/treasury/projections`

AI-powered forecasting:
- Revenue projection (3/6/12 months based on growth rate)
- Expense projection (infrastructure scales with users)
- Runway calculation at current burn
- Break-even analysis
- Scenario modeling ("what if MRR doubles?" "what if churn drops 2%?")

---

## SECTION 8: LEGAL DEPARTMENT

**Route:** `/legal`

Everything a solo founder needs to stay protected without a full-time attorney.

### Entity Management
**Route:** `/legal/entities`

| Entity | State | Type | Status |
|--------|-------|------|--------|
| Tereda Software LLC | CT | LLC | Active |
| (Future entities) | — | — | — |

For each entity:
- Filing dates, registration numbers, registered agent
- Annual report deadlines with auto-reminders
- State filing requirements tracker
- EIN, tax classification
- Operating agreement (stored in Document Vault)
- Good standing status check (auto-verify with CT SOS)

### Contract Vault
**Route:** `/legal/contracts`

Every contract the business touches:

| Type | Examples |
|------|---------|
| Service Agreements | Supabase, Cloudflare, Stripe ToS |
| Vendor Contracts | Telnyx, SendGrid, Plaid agreements |
| Customer Terms | ZAFTO Terms of Service (versioned) |
| Privacy Policies | ZAFTO Privacy Policy (versioned) |
| NDA Templates | For partnerships, contractors, employees |
| IP Assignments | If you hire developers |
| App Store Agreements | Apple Developer, Google Play |

Each contract tracked with:
- Effective date, expiration date, auto-renewal date
- Key terms summary (AI-generated)
- Obligation tracker (what you owe, what they owe)
- Termination clauses highlighted
- Reminder alerts before renewal/expiration

### Terms & Privacy Generator
**Route:** `/legal/terms-generator`

AI-powered legal document generation for ZAFTO:

| Document | Purpose | Auto-Updates |
|----------|---------|:------------:|
| Terms of Service | Customer-facing | On feature changes |
| Privacy Policy | GDPR/CCPA compliant | On data practice changes |
| Acceptable Use Policy | AI usage, content rules | On AI feature changes |
| Data Processing Agreement | Enterprise/GDPR | On request |
| Cookie Policy | Website compliance | On tracking changes |
| DMCA Policy | Content takedown | Static |
| Refund Policy | Cancellation terms | On pricing changes |
| SLA (Enterprise) | Uptime guarantees | On infrastructure changes |

Versioned — every change tracked, old versions archived, customers notified of material changes.
Generated by Claude with trade-specific and SaaS-specific legal language.
**Not a substitute for attorney review on critical documents.** But 90% of legal docs a SaaS
needs are templated — Claude generates the draft, attorney reviews the important ones.

### IP Protection
**Route:** `/legal/ip`

| Asset | Status | Action Needed |
|-------|--------|--------------|
| ZAFTO Trademark | Filed / Registered / Monitoring | Auto-check USPTO |
| Tereda Software Trademark | Status | Auto-check |
| zafto.app Domain | Registered (Cloudflare) | Auto-renew tracking |
| zafto.cloud Domain | Registered | Auto-renew tracking |
| Copyright (codebase) | Automatic | Documented |
| Trade Secrets (AI prompts, algorithms) | Protected | NDA enforcement |

Trademark monitoring: Alert if anyone files a confusingly similar mark.
Domain monitoring: Alert if anyone registers similar domains.

### Compliance Dashboard
**Route:** `/legal/compliance`

| Regulation | Status | What It Means |
|------------|--------|--------------|
| GDPR | Compliant / Action Needed | EU data protection |
| CCPA | Compliant / Action Needed | California privacy |
| CAN-SPAM | Compliant | Email marketing rules |
| PCI DSS | Stripe handles | Payment card data |
| SOC 2 | Roadmap (Phase 3 DevOps) | Enterprise requirement |
| COPPA | N/A | No children's data |
| ADA/WCAG | Website accessibility | Audit status |
| State Data Breach Laws | Notification plan ready | All 50 states |

Each regulation shows: current compliance status, last audit date, action items,
responsible documents, and next review date.

### Dispute & Issue Tracker
**Route:** `/legal/disputes`

Track any legal issues:
- Customer disputes (chargebacks, complaints)
- IP infringement claims (inbound or outbound)
- Regulatory inquiries
- Competitor issues
- Insurance claims
- Status tracking with timeline, documents, attorney notes
- AI-drafted response letters for common disputes

### Attorney Contacts
**Route:** `/legal/attorneys`

Rolodex of legal contacts:
- Business attorney (entity, contracts)
- IP attorney (trademarks, patents)
- Employment attorney (when hiring)
- Tax attorney/CPA
- Contact info, hourly rates, specialties, last engagement date

---

## SECTION 9: DEV TERMINAL

**Route:** `/dev`

Full development environment inside the portal. Code, deploy, test, debug — without
switching to VS Code or a separate terminal.

### Claude Code Terminal
**Route:** `/dev/terminal`

Embedded terminal with Claude Code integration:

- Full terminal emulator (xterm.js or similar)
- Claude Code CLI pre-installed and authenticated
- SSH into dev/staging/prod environments
- Run Flutter builds, Next.js builds, Supabase CLI commands
- Git operations (commit, push, pull, branch, merge)
- Database queries (Supabase CLI or psql)
- File editing with syntax highlighting

**AI-Powered Terminal:**
```
You: "fix the bug in bid_service.dart where deposits aren't calculating"
Claude: [reads the file, identifies the issue, generates fix, shows diff]
        "Found it — line 142 uses `subtotal` instead of `total` for deposit
         calculation. Here's the fix: [diff]. Apply?"
You: "yes, deploy to staging"
Claude: [applies fix, runs tests, commits, pushes, triggers staging deploy]
        "Fix applied. Tests passing. Deployed to staging. Verify at staging.zafto.cloud"
```

### Deployment Dashboard
**Route:** `/dev/deployments`

| Environment | URL | Status | Last Deploy | Branch |
|-------------|-----|--------|-------------|--------|
| Production | zafto.cloud | Green | 2h ago | main |
| Staging | staging.zafto.cloud | Green | 30m ago | develop |
| Dev | dev.zafto.cloud | Yellow | Building... | feature/x |
| Mobile (iOS) | TestFlight | v2.1.3 | Yesterday | main |
| Mobile (Android) | Internal Track | v2.1.3 | Yesterday | main |
| Client Portal | client.zafto.cloud | Green | 2h ago | main |

One-click deploy, one-click rollback, deployment logs, build times.

### CI/CD Monitor
**Route:** `/dev/ci`

GitHub Actions status for all workflows:
- Test suite results (pass/fail with details)
- Build times trending
- Flaky test detection
- Coverage reports
- Dependabot alerts and auto-merge status

### Database Explorer
**Route:** `/dev/database`

Visual database browser (like Supabase Studio but integrated):
- Browse tables, run queries
- View RLS policy status per table
- Row counts, storage per table
- Quick SQL runner for investigations
- Export query results

### Code Review Queue
**Route:** `/dev/reviews`

If you ever have contributors or hire devs:
- Open PRs with AI-generated summaries
- Claude reviews code for security issues, performance, style
- One-click approve + merge
- Linked to deployment pipeline

### App Store Management
**Route:** `/dev/app-stores`

| Platform | Data |
|----------|------|
| Apple App Store Connect | App status, review queue, crash reports, ratings, reviews |
| Google Play Console | App status, pre-launch reports, ANRs, ratings, reviews |

- Submit new builds (trigger from deployment)
- Respond to reviews (Claude drafts responses)
- Track rating trends
- Screenshot and metadata management
- Release notes editor (AI-generated from git commits)

### Test Runner
**Route:** `/dev/tests`

- Run test suites from the portal
- All 1,186 calculator tests
- RLS policy verification tests
- Integration tests
- View results, failures, coverage
- Historical test trends

---

## SECTION 10: AI OPERATIONS

**Route:** `/ai`

### Usage Dashboard
**Route:** `/ai/usage`

Total API calls (today/week/month), token consumption (input vs output),
cost breakdown by feature (scans, chat, bid gen, contract review),
cost per company, projected monthly cost, model usage breakdown.

### Query Analytics
**Route:** `/ai/analytics`

Anonymized patterns from contractor AI usage:
- Most common question categories
- Most requested calculator topics
- Feature requests embedded in conversations
- Confusion patterns (what do users struggle with?)
- AI quality metrics (follow-up "that's wrong" detection)

Privacy: No individual query logging. Aggregated category patterns only.

### Cost Optimization
**Route:** `/ai/costs`

Prompt efficiency analysis, cache hit rates, model routing analysis
(should some queries use Haiku instead of Sonnet?), projected cost at growth scenarios,
alert thresholds.

### Scan Intelligence
**Route:** `/ai/scans`

Scan volume by type, success rate, credit consumption patterns,
most scanned equipment categories, error patterns.

---

## SECTION 11: CONTENT MANAGEMENT

**Route:** `/content`

### Calculator Manager — `/content/calculators`
All 1,186 calculators. Search, edit formulas/descriptions/units, version history,
user-reported issues, usage analytics, bulk operations.

### Exam Question Manager — `/content/exams`
All 5,080 questions. Search by trade/topic/difficulty, edit, flag incorrect,
pass/fail rates per question, add new, bulk import CSV.

### Diagram + Guide Manager — `/content/diagrams`
111 diagrams + 21 guides. View, edit, replace images, track views.

### Release Notes — `/content/releases`
Write and publish in-app release notes. Rich text, schedule publication,
target audience (tier/trade), track read rates.

---

## SECTION 12: MARKETING ENGINE

**Route:** `/marketing`

This section alone replaces an entire growth team.

### 12A: Contractor Discovery Engine
**Route:** `/marketing/discovery`

**The weapon nobody else has.** Every state has a public licensing board database.
Licensed electricians, plumbers, HVAC techs, GCs, roofers, solar — all public record.

**Data Sources (public, legal):**
State licensing boards (all 50 states), Google Business Profiles, BBB listings,
LinkedIn, Secretary of State business filings.

**Email addresses are NOT in licensing databases.** Discovery pipeline:
1. State License Board → Licensed Contractor List
2. Company Name → Google Search → Website Found?
3. Yes: Extract email, phone from website
4. No: LinkedIn / BBB / SoS lookup
5. Prospect Record Created with all enrichment data

**Prospect Record Fields:**
- Identity: owner name, company name, trade(s)
- Contact: email, phone, website, LinkedIn, address, city, state, zip
- Licensing: license number, state, type, status, expiry
- Enrichment: company size estimate, estimated revenue, years in business
- Online: review count, avg rating, website quality score, social media
- Software: current detected tools (ServiceTitan, QuickBooks, etc.)
- Discovery: source, date, enrichment completeness
- Pipeline: stage (discovered → enriched → contacted → responded → demo → trial → converted → lost)
- Outreach: emails sent/opened/clicked, calls made, opted out status
- AI Scoring: fit score (0-100), intent score (0-100), priority score (0-100)

**AI Scoring Model:**
Fit Score: Licensed active (+20), supported trade (+15), 2-15 employees (+15),
low website quality (+10), no CRM detected (+15), good reviews (+10), launched state (+15).
Intent Score: Job ad mentioning "software" (+25), visited zafto.app (+30),
clicked ad (+20), responded to outreach (+15), clicked Zafto Lead email (+20).
Priority = (Fit × 0.6) + (Intent × 0.4).

### 12B: Campaign Engine
**Route:** `/marketing/campaigns`

Multi-channel outreach campaigns:

| Type | Channel | Use Case |
|------|---------|----------|
| Cold Outreach | Email | Introduce ZAFTO to discovered contractors |
| Warm Nurture | Email sequence | Multi-touch 30-60 day follow-up |
| Re-Engagement | Email + SMS | Win back churned or stale prospects |
| Marketplace Conversion | Email | Convert "Zafto Lead" recipients |
| Referral | In-app + Email | Encourage existing customer referrals |
| Trade-Specific | Email | Target one trade |
| Regional | Email | Launch in new state/metro |
| Seasonal | Email | AC season, heating season pushes |

**Campaign Builder Steps:**
1. Define Audience (filter prospects by trade/state/score/stage)
2. Create Content (AI generates personalized copy, A/B subject lines)
3. Schedule (drip sequences, optimal send time, stop conditions)
4. Launch + Monitor (real-time tracking, auto-pipeline movement)

CAN-SPAM compliant. Unsubscribe honored within 24 hours. Rate limiting for deliverability.

### Email Template Library
**Route:** `/marketing/templates`

Pre-built, AI-customizable templates:

| Template | Purpose |
|----------|---------|
| The Introduction | Cold outreach — who ZAFTO is |
| The Pain Point | "Still using spreadsheets for bids?" |
| The Social Proof | Testimonials + metrics |
| The Feature Spotlight | Deep dive, trade-specific |
| The Calculator Hook | "Free access to 1,186 trade calculators" |
| The Website Offer | "Your website looks like it was built in 2008" |
| The Price Comparison | Side-by-side vs ServiceTitan/Jobber |
| The Marketplace Lead | "You have a lead waiting" (Zafto Lead) |
| The Win-Back | "We miss you — here's what's new" |
| The Referral Ask | "Know another contractor who'd benefit?" |
| The Trial Expiring | "Your trial ends in 3 days" |
| The Onboarding | "Welcome + here's how to get started" (5-email) |

All personalized per prospect: company name, trade, region, size, competitor-aware.

### 12C: Ad Manager
**Route:** `/marketing/ads`

Google Ads + Meta Ads from one interface:
- Campaign creation with AI-generated copy/creative briefs
- Keyword research (trade-specific long-tail)
- Audience building (trade, location, interests, lookalikes)
- Performance tracking, budget pacing
- Unified spend dashboard, ROAS by campaign
- Attribution: ad → landing page → signup → subscription
- AI recommendations ("Google converts electricians at $45. Meta at $120. Shift budget.")

### 12D: SEO Command Center
**Route:** `/marketing/seo`

Google Search Console integration. Keyword rankings, organic traffic trends,
top pages, technical SEO health, content gaps, blog post generator (AI SEO content),
backlink tracking, local SEO for metro launches.

### 12E: Landing Page Manager
**Route:** `/marketing/landing-pages`

Campaign-specific landing pages without touching code:
- Template library (pricing, trade-specific, feature, webinar)
- AI content generation, A/B testing built in
- Form builder (auto-creates prospect records)
- Conversion tracking, deploy to zafto.app subpaths

### 12F: Referral Program
**Route:** `/marketing/referrals`

Referral link generation, tracking, reward management (credits/free months/cash),
leaderboard, automated referral requests timed after positive milestones,
double-sided rewards.

---

## SECTION 13: GROWTH CRM (Your Sales Pipeline)

**Route:** `/growth`

YOUR CRM for selling ZAFTO. Separate from contractor CRM.

### Pipeline Board — `/growth/pipeline`
Kanban: DISCOVERED → ENRICHED → CONTACTED → RESPONDED → DEMO → TRIAL → CONVERTED | LOST
Drag-and-drop cards, filter by trade/state/score/campaign, total pipeline value per stage.

### Prospect Detail — `/growth/prospects/[id]`
Full profile: contact, scores, all interactions, campaign membership,
AI recommendations, timeline, quick actions.

### Demo Scheduler — `/growth/demos`
Calendar integration, prospect books via link, pre-demo brief auto-generated,
post-demo follow-up template, outcome tracking.

### Daily Growth Tasks — `/growth/tasks`
AI-generated: follow-ups needed, trial check-ins, conversion deadlines,
new enriched prospects ready, marketplace lead recipients who clicked but didn't sign up.

---

## SECTION 14: SERVICE HUB

**Route:** `/services`

One-stop view of every external service ZAFTO depends on.

### Service Directory
**Route:** `/services/directory`

| Service | Status | Monthly Cost | Contract Renewal | Quick Link |
|---------|:------:|:------------:|:----------------:|:----------:|
| Supabase | Green | $25 | Monthly | Dashboard → |
| Stripe | Green | 2.9% + $0.30 | None | Dashboard → |
| Cloudflare | Green | $0 (Free) | None | Dashboard → |
| Anthropic (Claude) | Green | ~$X/mo | None | Console → |
| Telnyx | Green | ~$X/mo | Monthly | Portal → |
| SendGrid | Green | $0 (Free tier) | None | Dashboard → |
| Sentry | Green | $0 (Free tier) | None | Dashboard → |
| GitHub | Green | $0 (Free tier) | None | Repo → |
| Plaid | Green | ~$X/mo | Monthly | Dashboard → |
| Apple Developer | Green | $99/yr | Annual (auto) | ASC → |
| Google Play | Green | $25 one-time | None | Console → |
| Namecheap/Cloudflare | Green | ~$X/yr | Annual | Domains → |
| PowerSync | Green | $0 (Free tier) | Monthly | Dashboard → |

Each service shows:
- Real-time status (auto-checked every 5 min)
- Monthly cost (pulled from bank transactions or API)
- API key expiration / rotation schedule
- One-click deep link to their dashboard
- Usage metrics relevant to that service
- Dependency map (what breaks if this goes down)
- Alternative service noted (e.g., Telnyx → Twilio fallback)

### Cost Rollup
Total monthly infrastructure cost, trending over time, projected at user milestones.

---

## SECTION 15: MARKETPLACE OPERATIONS

**Route:** `/marketplace`
*(Active after marketplace launch)*

### Lead Dashboard — `/marketplace/leads`
Volume, quality distribution, avg bids per lead, conversion rate, time to first bid,
geographic + trade distribution.

### Dispute Resolution — `/marketplace/disputes`
Homeowner complaints, contractor complaints, no-shows, quality issues, refunds, bans.

### Equipment Knowledge Base — `/marketplace/equipment`
Browse/edit AI-generated entries, add manufacturer bulletins, data quality scores,
merge duplicates, flag models needing more data.

### Contractor Discovery (Marketplace) — `/marketplace/contractors`
Non-subscriber contractors: response rates, conversion tracking, email engagement,
geographic coverage gaps, underserved trades.

---

## SECTION 16: COMMUNICATIONS HUB

**Route:** `/comms`

### Announcements — `/comms/announcements`
Push in-app announcements. Rich text, target (all/tier/trade/company), schedule, pin, read rates.

### Email Broadcasts — `/comms/broadcasts`
Non-campaign emails: product updates, feature launches, maintenance notices, surveys.

### Maintenance Windows — `/comms/maintenance`
Schedule maintenance, auto-notify users (email + in-app banner), status page auto-updates,
post-maintenance all-clear.

---

## SECTION 17: ANALYTICS + INTELLIGENCE

**Route:** `/analytics`

### Product Analytics — `/analytics/product`
Feature adoption rates, user flow analysis, drop-off points, power user profiles,
feature correlation with retention.

### Market Intelligence — `/analytics/market`
TAM by trade + state, penetration rate, competitor monitoring (ServiceTitan, Jobber,
Housecall Pro pricing/feature changes), industry news (AI curated), seasonal trends.

### Financial Projections — `/analytics/projections`
Revenue/churn/marketing ROI/infrastructure cost projections. Runway calculation.
Scenario modeling.

---

## SECTION 18: DOCUMENT VAULT

**Route:** `/vault`

Every business document organized and searchable.

### Categories

| Category | Examples |
|----------|---------|
| Legal | Operating agreement, contracts, terms, policies, trademarks |
| Financial | Tax returns, quarterly estimates, bank statements, invoices |
| Corporate | Articles of organization, EIN letter, good standing certs |
| Insurance | Business insurance policies, certificates |
| Development | Architecture docs, API specs, security audits |
| Marketing | Brand assets, press kit, case studies |
| HR (future) | Offer letters, handbooks, NDAs |

Features:
- Full-text search across all documents (OCR for scanned PDFs)
- Version history on all documents
- Expiration tracking with reminders
- Tags and custom categories
- Secure sharing with external parties (signed URLs, expiring)
- AI summaries on upload ("This is a 3-year hosting agreement with Cloudflare...")

---

## SECTION 19: OPS AI ASSISTANT

**Route:** Floating panel, available on every page

Your private Claude instance. Full context on everything. Talks like a co-founder, not a chatbot.

### What It Knows
- Entire Supabase database (all tenants, read-only)
- Stripe revenue data
- Sentry error data
- Bank account balances and transactions
- Prospect pipeline
- Campaign performance
- Email inbox context
- All documentation
- Legal documents and deadlines
- GitHub repo state
- App Store status

### What It Can Do

| Category | Examples |
|----------|---------|
| Customer Intel | "Which companies haven't logged in this week?" |
| Revenue | "What's our churn rate for HVAC vs electrical?" |
| Support | "Draft a response to this ticket" |
| Marketing | "Write a cold email for plumbers in Texas" |
| Email | "Reply to this partnership inquiry" |
| Banking | "What's our runway at current burn?" |
| Legal | "Draft a cease and desist for [trademark issue]" |
| Dev | "What Sentry errors are affecting the most users?" |
| Growth | "Prospects with fit >80 not yet contacted" |
| Strategy | "What should I focus on this week?" |
| Competitor | "What did ServiceTitan announce?" (web search) |
| Content | "Which calculators have the most error reports?" |
| Forecasting | "When do we hit 1,000 companies at current growth?" |

### Personality

The AI talks like we talk. Direct. No hedging. Full context. Gets things done.

```
You: "Anything on fire?"
AI: "Two things. A plumbing company in Texas has 3 failed payments — their card
     expired and auto-retry isn't catching it. I drafted a personal email.
     Second, there's a Sentry error hitting 8 companies — the bid PDF
     generation is failing on jobs with more than 20 line items. I found the
     bug in pdf_service.dart line 340 — buffer overflow on the table renderer.
     Want me to fix it and deploy to staging?"
```

```
You: "How's this month looking?"
AI: "MRR is $12,400, up 8% from last month. 14 new signups, 2 churned.
     Net revenue retention is 106%. Cash position is $47,200, runway is 11 months
     at current burn. The Google Ads campaign for electricians is crushing it —
     $38 CAC with 4.2:1 LTV ratio. Meta campaign for plumbers is underperforming,
     recommend pausing and reallocating to Google. Three trial companies are at
     risk of not converting — want me to send personalized check-in emails?"
```

### Actions (with confirmation)
- Send drafted emails (you approve)
- Update prospect pipeline stages
- Create support tickets from error patterns
- Generate campaign content
- Schedule announcements
- Run terminal commands (sandboxed)
- Deploy to staging (not prod without explicit confirmation)
- Generate legal document drafts

---

## SECTION 20: AI SUPPORT SANDBOX — AUTONOMOUS DEBUGGING + AUTO-RESOLUTION

**Route:** `/support/sandbox`

The support center already drafts responses and auto-resolves simple tickets (Section 4). This section
goes further — giving the AI a sandboxed environment to actually DIAGNOSE and FIX issues autonomously,
without human intervention on Tier 1, and with one-click approval on Tier 2.

### Why This Matters
ZAFTO has 1,186 calculators, 5,080 exam questions, 14 field tools, and a business pipeline across
90 screens. The most common support ticket is "this number looks wrong." Without an AI sandbox,
every ticket like that requires Robert to manually open the calculator, punch in the user's inputs,
check against NEC code, and reply. That's 20 minutes per ticket. At scale, that's a full-time job.

An AI sandbox can reproduce the issue, verify the math, and respond in seconds — or confirm a real
bug, create a GitHub issue with reproduction steps, and draft a code fix. One person running a
platform this large cannot survive without this.

### The Three Tiers

#### TIER 1: FULL AUTO — Zero Human Touch
Deterministic issues where there is one objectively correct answer. The AI resolves and responds
without waiting for approval. Auto-resolved tickets go to a "Reviewed" queue for daily spot-checks.

| Trigger Pattern | AI Action | Response |
|----------------|-----------|----------|
| "This calculator gives wrong answer" | Run calculator in sandbox with user's exact inputs. Compare output against formula spec. | If correct: "Here's the math step by step: [shows work]. The result is correct because [NEC reference]." If bug found: Auto-creates GitHub issue + notifies Robert. |
| "How do I [common task]" | Search knowledge base. If match >90% confidence, respond. | Links KB article with contextual excerpt. |
| "Password reset" / "Can't log in" | Check user's auth state in Supabase. Trigger reset if appropriate. | Reset link sent. Logs action. |
| "My payment failed" | Check Stripe for payment status, card expiry, retry history. | "Your card ending 4242 expired. Here's how to update: [deep link]." Triggers Stripe retry. |
| "App is slow / not loading" | Check Sentry for errors on user's account. Check service health status. | If known issue: "We're aware of [issue], fix deploying in [time]." If user-side: "Try [steps]." |
| "Where is [feature]" | Check user's tier + role permissions. | "That feature is under [nav path]." OR "That's available on the Pro tier — here's what it includes." |
| "Exam question seems wrong" | Look up question by ID. Check against source material (NEC code year, section). | If correct: "The answer is [X] per NEC [section]. Here's why [explanation]." If wrong: flags for content review. |

**Confidence threshold:** Auto-respond only when AI confidence is ≥95%. Below that → Tier 2.
**Daily audit:** Robert scans the "Reviewed" queue once daily (~5 min) to verify quality. AI tracks any corrections and improves.

#### TIER 2: AI DOES THE WORK — Robert Approves with One Click
Complex issues where the AI can investigate and propose a solution, but a human makes the final call.

| Scenario | AI Investigation | Approval Queue |
|----------|-----------------|----------------|
| Bug reproduction | AI runs the exact user flow in a sandboxed staging environment. Captures the error, identifies root cause in code, drafts a fix as a PR. | Shows: bug description, reproduction steps, proposed fix diff, customer response draft. Robert clicks "Approve Fix + Send Response" or "Edit." |
| Refund / credit request | AI checks subscription history, usage patterns, support history, payment failures. Recommends approve/deny with dollar amount. | Shows: recommendation, reasoning, customer impact, financial impact. Robert clicks Approve/Deny. |
| Account modification | AI prepares the change (tier change, trial extension, feature unlock). | Shows: what changes, why, customer response. Robert confirms. |
| Complex troubleshooting | AI queries read-only database replica. Checks user's data for inconsistencies, missing records, permission issues. | Shows: diagnosis, recommended fix (data correction or code fix), customer response. |
| Data export / deletion request | AI compiles the data package or identifies records to delete. | Shows: what's included/deleted, compliance check, customer confirmation draft. |
| Feature request (recurring) | AI searches all tickets for similar requests, counts occurrences, estimates implementation effort. | Shows: "This is the 14th request for [feature]. Here's a summary. Create roadmap item?" |

**Approval UI:**
```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2 APPROVAL QUEUE                              3 pending  │
├─────────────────────────────────────────────────────────────────┤
│  🔧 BUG FIX — Calculator #847 (Wire Fill Calc)      15 min ago │
│  AI found: Rounding error in conduit_fill_service.dart:234     │
│  Fix: Math.round() → toStringAsFixed(2) on fill percentage     │
│  PR: #142 (staged, tests passing)                              │
│  Customer response: "Good catch — this was a rounding..."      │
│  [✓ Approve Fix + Send]  [✎ Edit Response]  [✗ Reject]        │
├─────────────────────────────────────────────────────────────────┤
│  💰 REFUND — Acme Electric ($29 Pro subscription)     1 hr ago │
│  Reason: Customer reports they were charged after cancelling    │
│  AI found: Cancellation processed 2 hours AFTER renewal        │
│  Recommendation: Full refund ($29) — Stripe shows overlap      │
│  [✓ Approve Refund]  [✎ Counter-Offer]  [✗ Deny]              │
├─────────────────────────────────────────────────────────────────┤
│  🔍 DATA ISSUE — Johnson HVAC missing 3 invoices     2 hrs ago │
│  AI found: Invoices exist but company_id mismatch (migration?) │
│  Fix: UPDATE invoices SET company_id = 'xxx' WHERE id IN (...) │
│  [✓ Approve Fix + Notify]  [✎ Investigate More]  [✗ Escalate] │
└─────────────────────────────────────────────────────────────────┘
```

#### TIER 3: HUMAN ONLY — AI Routes, Does Not Act
The AI provides full context and routing but takes zero action. These are things where mistakes
are irreversible or have legal/security implications.

| Category | AI Role | Why Human Only |
|----------|---------|---------------|
| Security incidents | Surfaces all relevant data, timeline of events, affected accounts. Does NOT take remediation action. | Wrong move = data breach escalation. |
| Encryption key issues | Identifies the problem, shows which keys/accounts are affected. | Touching encryption = catastrophic risk. |
| RLS policy concerns | Tests the policy in sandbox, reports findings. | Tenant isolation is the #1 security guarantee. |
| Billing disputes over $100 | Compiles full history, recommends action. | Financial decisions above threshold = human judgment. |
| Legal / compliance | Summarizes the issue, pulls relevant legal docs, drafts response for review. | Legal liability requires human sign-off. |
| Account termination | Prepares the full picture (payment history, usage, communications). | Permanent actions = permanent consequences. |
| Data deletion (GDPR/CCPA) | Compiles affected data, creates deletion plan, generates compliance report. | Regulatory compliance requires documented human authorization. |
| Suspected fraud | Flags patterns, compiles evidence, locks nothing. | False positive = lost customer. |

### The Sandbox Environment

**Architecture:**
```
Production (Supabase)
       │
       ├── READ-ONLY REPLICA ──── AI can query ANY customer data
       │     (no writes, no modifications, zero production risk)
       │
       ├── STAGING ENVIRONMENT ── AI can reproduce bugs here
       │     (real schema, test data, write access)
       │     (from DevOps doc: dev/staging/prod separation)
       │
       ├── CALCULATOR TEST RUNNER ── Containerized execution
       │     (all 1,186 calculators executable with arbitrary inputs)
       │     (output compared against formula spec + NEC tables)
       │     (deterministic — same input always same output)
       │
       ├── EXAM VERIFICATION ──── Question + answer validation
       │     (cross-reference NEC code year/section/table)
       │     (flag outdated questions after code cycle updates)
       │
       └── CODE ANALYSIS ──────── AI reads source code (read-only)
             (can identify bug location, propose fix)
             (creates PR to staging — NEVER merges to prod)
```

**What the sandbox CAN do:**
- Query the read-only production replica (any table, any tenant, for diagnosis)
- Execute calculators with arbitrary inputs and validate outputs
- Reproduce user-reported flows in the staging environment
- Read source code from the GitHub repo
- Create pull requests to staging branch
- Run automated tests against staging
- Generate test data in staging for reproduction
- Cross-reference NEC code tables for calculator/exam verification

**What the sandbox CANNOT do:**
- Write to production database (physically impossible — read-only connection)
- Merge PRs to main/production (requires Robert's GitHub approval)
- Modify encryption keys or auth configuration
- Access decrypted SSNs, bank accounts, or other Layer 4 encrypted fields
- Delete any production data
- Modify RLS policies
- Push code to production deployment

### Metrics + Learning

The sandbox tracks everything for continuous improvement:

| Metric | Target | Why |
|--------|--------|-----|
| Tier 1 auto-resolution rate | 60-70% of all tickets | Higher = fewer interruptions for Robert |
| Tier 1 accuracy (spot-check) | >98% correct responses | Below this → tighten confidence threshold |
| Tier 2 approval rate | >85% approved as-is | Below this → AI needs better investigation prompts |
| Avg time to resolution (Tier 1) | <2 minutes | Customer sees near-instant response |
| Avg time to resolution (Tier 2) | <30 minutes | Bottleneck is Robert checking the queue |
| False positive bug reports | <5% | AI wrongly identifying correct behavior as bugs |
| Customer satisfaction (auto-resolved) | ≥4.0/5.0 stars | If lower → too aggressive on auto-resolution |

AI learns from every Robert correction:
- Rejected Tier 2 actions → adjusts investigation approach
- Overridden Tier 1 responses → raises confidence threshold for that pattern
- New KB articles → incorporated into Tier 1 auto-response corpus
- Calculator formula corrections → updates validation spec

### Database Additions (Sandbox)

```sql
-- AI sandbox execution log (every investigation the AI runs)
CREATE TABLE sandbox_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES support_tickets(id),
  tier INTEGER NOT NULL, -- 1, 2, or 3
  execution_type TEXT NOT NULL, -- 'calculator_test', 'bug_reproduction', 'data_query', 'code_analysis', 'exam_verification'
  inputs JSONB NOT NULL, -- what the AI was given
  outputs JSONB NOT NULL, -- what the AI found
  confidence FLOAT, -- 0.0 to 1.0
  auto_resolved BOOLEAN DEFAULT false,
  approved_by UUID, -- null if Tier 1 auto, Robert's ID if Tier 2
  approved_at TIMESTAMPTZ,
  rejected BOOLEAN DEFAULT false,
  rejection_reason TEXT,
  customer_response_sent TEXT,
  github_pr_url TEXT, -- if a code fix was proposed
  execution_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Calculator verification results (reusable — same inputs = same expected output)
CREATE TABLE calculator_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculator_id TEXT NOT NULL, -- which of the 1,186 calculators
  calculator_name TEXT NOT NULL,
  inputs JSONB NOT NULL,
  expected_output JSONB NOT NULL,
  actual_output JSONB NOT NULL,
  is_correct BOOLEAN NOT NULL,
  nec_reference TEXT, -- NEC code section for verification
  discrepancy_details TEXT, -- if incorrect, what went wrong
  verified_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Edge Functions (Sandbox)

| Function | Trigger | What It Does |
|----------|---------|-------------|
| `ops-sandbox-execute` | New Tier 1/2 ticket | Spins up sandbox investigation based on ticket type |
| `ops-calculator-verify` | Calculator complaint ticket | Runs calculator with user inputs, validates against spec |
| `ops-exam-verify` | Exam question complaint | Cross-references question against NEC code tables |
| `ops-bug-reproduce` | Bug report ticket | Attempts reproduction in staging environment |
| `ops-sandbox-metrics` | Daily cron | Calculates resolution rates, accuracy, satisfaction scores |

### Build Phase
**Phase 2 (Month 1 after launch, with Ops Portal Phase 2, ~8-12 additional hours):**
- Sandbox infrastructure (read-only replica connection, staging write access)
- Calculator test runner (containerized, all 1,186 calculators)
- Tier 1 auto-resolution engine (confidence-gated)
- Tier 2 approval queue UI
- Sandbox execution logging
- Integration with existing support ticket flow (Section 4)

**Phase 3 (Month 2-3):**
- Code analysis + PR generation (GitHub API integration)
- Exam verification engine (NEC cross-reference)
- Learning loop (corrections feed back into confidence tuning)
- Sandbox metrics dashboard

---

## DATABASE ADDITIONS

### New Tables (Ops Portal specific)

```sql
-- Support tickets
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  user_id UUID REFERENCES users(id),
  ticket_number TEXT UNIQUE NOT NULL,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT, -- 'billing', 'bug', 'feature_request', 'how_to', 'account', 'emergency'
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'new', -- 'new', 'in_progress', 'waiting_customer', 'resolved', 'closed'
  ai_category TEXT,
  ai_priority TEXT,
  ai_draft_response TEXT,
  ai_root_cause TEXT,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  satisfaction_rating INTEGER, -- 1-5
  satisfaction_comment TEXT,
  source TEXT DEFAULT 'in_app', -- 'in_app', 'email', 'chat', 'phone'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support ticket messages
CREATE TABLE support_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES support_tickets(id),
  sender_type TEXT NOT NULL, -- 'customer', 'admin', 'ai_auto'
  sender_id UUID,
  message TEXT NOT NULL,
  attachments JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Knowledge base articles
CREATE TABLE knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  tags JSONB DEFAULT '[]',
  is_published BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Announcements
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  target_audience JSONB DEFAULT '{"all": true}',
  is_pinned BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  read_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prospect database (marketing engine)
CREATE TABLE prospects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_name TEXT,
  company_name TEXT NOT NULL,
  trade TEXT NOT NULL,
  trades JSONB DEFAULT '[]',
  email TEXT,
  phone TEXT,
  website TEXT,
  linkedin_url TEXT,
  address TEXT,
  city TEXT,
  state TEXT NOT NULL,
  zip_code TEXT,
  license_number TEXT,
  license_state TEXT,
  license_type TEXT,
  license_status TEXT,
  license_expiry DATE,
  additional_licenses JSONB DEFAULT '[]',
  company_size_estimate TEXT,
  estimated_revenue TEXT,
  years_in_business INTEGER,
  review_count INTEGER,
  avg_rating FLOAT,
  has_website BOOLEAN DEFAULT false,
  website_quality_score INTEGER,
  social_media JSONB DEFAULT '{}',
  current_software JSONB DEFAULT '[]',
  online_presence_score INTEGER,
  discovery_source TEXT,
  discovered_at TIMESTAMPTZ DEFAULT NOW(),
  enriched_at TIMESTAMPTZ,
  enrichment_completeness INTEGER,
  pipeline_stage TEXT DEFAULT 'discovered',
  pipeline_updated_at TIMESTAMPTZ,
  assigned_campaign_id UUID,
  emails_sent INTEGER DEFAULT 0,
  emails_opened INTEGER DEFAULT 0,
  emails_clicked INTEGER DEFAULT 0,
  last_email_sent_at TIMESTAMPTZ,
  last_email_opened_at TIMESTAMPTZ,
  email_opted_out BOOLEAN DEFAULT false,
  phone_calls_made INTEGER DEFAULT 0,
  last_call_at TIMESTAMPTZ,
  converted BOOLEAN DEFAULT false,
  converted_at TIMESTAMPTZ,
  converted_company_id UUID REFERENCES companies(id),
  conversion_campaign_id UUID,
  conversion_value FLOAT,
  fit_score INTEGER,
  intent_score INTEGER,
  priority_score INTEGER,
  notes JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prospect interactions
CREATE TABLE prospect_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id UUID REFERENCES prospects(id),
  type TEXT NOT NULL, -- 'email_sent', 'email_opened', 'email_clicked', 'call', 'demo', 'note', 'website_visit'
  subject TEXT,
  content TEXT,
  campaign_id UUID,
  template_id UUID,
  response_received BOOLEAN DEFAULT false,
  response_text TEXT,
  response_sentiment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Marketing campaigns
CREATE TABLE marketing_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  audience_filters JSONB NOT NULL,
  audience_count INTEGER,
  email_sequence JSONB DEFAULT '[]',
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  total_sent INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  total_responded INTEGER DEFAULT 0,
  total_converted INTEGER DEFAULT 0,
  total_unsubscribed INTEGER DEFAULT 0,
  total_bounced INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Email templates
CREATE TABLE email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  variables JSONB DEFAULT '[]',
  a_b_variants JSONB DEFAULT '[]',
  send_count INTEGER DEFAULT 0,
  open_rate FLOAT,
  click_rate FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ad campaigns (Google + Meta)
CREATE TABLE ad_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL,
  external_campaign_id TEXT,
  name TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  daily_budget FLOAT,
  total_budget FLOAT,
  total_spent FLOAT DEFAULT 0,
  targeting JSONB,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  cost_per_click FLOAT,
  cost_per_conversion FLOAT,
  signups_attributed INTEGER DEFAULT 0,
  revenue_attributed FLOAT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unified email (inbox)
CREATE TABLE inbox_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account TEXT NOT NULL, -- which email account
  message_id TEXT UNIQUE, -- IMAP message ID
  thread_id TEXT, -- conversation threading
  from_address TEXT NOT NULL,
  from_name TEXT,
  to_address TEXT,
  subject TEXT,
  body_text TEXT,
  body_html TEXT,
  attachments JSONB DEFAULT '[]',
  is_read BOOLEAN DEFAULT false,
  is_starred BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  ai_category TEXT, -- 'support', 'sales', 'legal', 'financial', 'marketing', 'personal', 'spam'
  ai_priority TEXT, -- 'high', 'medium', 'low'
  ai_summary TEXT,
  ai_draft_response TEXT,
  linked_ticket_id UUID REFERENCES support_tickets(id),
  linked_prospect_id UUID REFERENCES prospects(id),
  received_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bank transactions (from Plaid)
CREATE TABLE bank_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_transaction_id TEXT UNIQUE,
  account_id TEXT NOT NULL,
  account_name TEXT,
  amount FLOAT NOT NULL,
  date DATE NOT NULL,
  name TEXT,
  merchant_name TEXT,
  category TEXT, -- AI or Plaid auto-categorized
  category_override TEXT, -- manual override
  is_recurring BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Legal documents
CREATE TABLE legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  category TEXT NOT NULL, -- 'contract', 'policy', 'corporate', 'ip', 'insurance', 'financial'
  subcategory TEXT,
  file_path TEXT, -- Supabase Storage path
  version INTEGER DEFAULT 1,
  effective_date DATE,
  expiration_date DATE,
  auto_renew BOOLEAN DEFAULT false,
  renewal_date DATE,
  counterparty TEXT, -- other party (if contract)
  key_terms TEXT, -- AI-generated summary
  obligation_tracker JSONB DEFAULT '[]',
  status TEXT DEFAULT 'active', -- 'draft', 'active', 'expired', 'terminated'
  reminder_days_before INTEGER DEFAULT 30,
  tags JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ops audit log (separate from customer audit_log)
CREATE TABLE ops_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  reason TEXT,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service credentials vault (encrypted)
CREATE TABLE service_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT UNIQUE NOT NULL,
  credentials JSONB NOT NULL, -- encrypted via Supabase Vault
  last_rotated_at TIMESTAMPTZ,
  rotation_interval_days INTEGER,
  next_rotation_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Total new tables: 14** (+ 2 sandbox tables: sandbox_executions, calculator_verifications = **16 total**)

---

## EDGE FUNCTIONS (Ops Portal)

| Function | Trigger | What It Does |
|----------|---------|-------------|
| `ops-morning-briefing` | Daily 7am cron | AI morning briefing from all data sources |
| `ops-churn-scoring` | Daily cron | Recalculate churn risk for all companies |
| `ops-prospect-enrichment` | After discovery | Google + website + LinkedIn lookup |
| `ops-license-board-sync` | Weekly cron | Pull new licenses from state board APIs |
| `ops-campaign-executor` | Scheduled | Send campaign emails, respect rate limits |
| `ops-email-webhook` | SendGrid webhook | Track opens, clicks, bounces, unsubscribes |
| `ops-ai-ticket-triage` | New ticket | Claude categorizes, prioritizes, drafts |
| `ops-auto-resolve` | New ticket | Check auto-resolution patterns |
| `ops-satisfaction-survey` | Ticket resolved | Send satisfaction survey after 24h |
| `ops-ad-sync` | Hourly | Sync Google + Meta ad performance |
| `ops-revenue-sync` | Hourly | Sync Stripe data for revenue dashboard |
| `ops-health-check` | Every 5 min | Check all service endpoints, update status page |
| `ops-prospect-scoring` | After enrichment | Calculate fit/intent/priority scores |
| `ops-inbox-sync` | Every 1 min | IMAP poll all email accounts |
| `ops-inbox-triage` | New email | Claude categorizes, summarizes, drafts |
| `ops-bank-sync` | Every 15 min | Plaid transaction sync |
| `ops-bank-categorize` | New transaction | AI auto-categorize bank transactions |
| `ops-legal-reminders` | Daily cron | Check contract expirations, filing deadlines |
| `ops-app-store-sync` | Every 30 min | Pull reviews, ratings, crash data from ASC + GP |
| `ops-service-status` | Every 5 min | Check all external service APIs for health |
| `ops-sandbox-execute` | New Tier 1/2 ticket | Spins up sandbox investigation based on ticket type |
| `ops-calculator-verify` | Calculator complaint ticket | Runs calculator with user inputs, validates against spec |
| `ops-exam-verify` | Exam question complaint | Cross-references question against NEC code tables |
| `ops-bug-reproduce` | Bug report ticket | Attempts reproduction in staging environment |
| `ops-sandbox-metrics` | Daily cron | Calculates resolution rates, accuracy, satisfaction scores |

**Total: 25 Edge Functions**

---

## BUILD PHASES

### Phase 1: Foundation (Before Launch) — ~40 hours
*Cannot launch ZAFTO without this — flying blind otherwise*

| Section | Pages | Hours |
|---------|:-----:|:-----:|
| Command Center (dashboard + briefing) | 1 | 3 |
| Unified Inbox (basic — 2 accounts) | 2 | 6 |
| Account Management (companies, users, detail) | 4 | 8 |
| Support Center (tickets, KB, auto-triage) | 4 | 8 |
| Platform Health (status, errors) | 2 | 4 |
| Revenue Dashboard (MRR, subscriptions, churn) | 3 | 5 |
| Service Hub (directory + status) | 1 | 2 |
| Ops AI Assistant (floating panel) | 1 | 4 |
| **TOTAL PHASE 1** | **18** | **~40** |

### Phase 2: Growth Engine (Post-Launch Month 1) — ~45 hours
*When you're ready to actively acquire customers*

| Section | Pages | Hours |
|---------|:-----:|:-----:|
| Contractor Discovery Engine | 3 | 10 |
| Campaign Engine + Templates | 4 | 10 |
| Growth CRM (pipeline, prospects) | 4 | 8 |
| Banking & Treasury (Plaid integration) | 4 | 8 |
| Email deliverability + tracking | 2 | 5 |
| Landing Page Manager | 2 | 4 |
| **TOTAL PHASE 2** | **19** | **~45** |

### Phase 3: Enterprise Suite (Month 2-3) — ~45 hours
*Build when you have data worth analyzing + legal needs grow*

| Section | Pages | Hours |
|---------|:-----:|:-----:|
| Legal Department (entities, contracts, compliance, IP) | 6 | 12 |
| Dev Terminal (Claude Code, deployments, CI/CD, DB) | 5 | 10 |
| Ad Manager (Google + Meta) | 3 | 8 |
| SEO Command Center | 2 | 5 |
| Document Vault | 2 | 4 |
| Referral Program | 2 | 3 |
| Analytics (product, market, projections) | 3 | 3 |
| **TOTAL PHASE 3** | **23** | **~45** |

### Phase 4: Marketplace Ops (When Marketplace Launches)

| Section | Pages | Hours |
|---------|:-----:|:-----:|
| Lead Dashboard | 2 | 4 |
| Dispute Resolution | 2 | 5 |
| Equipment Knowledge Base Manager | 2 | 4 |
| Marketplace Contractor Tracking | 2 | 4 |
| **TOTAL PHASE 4** | **8** | **~17** |

### Grand Total

| Phase | Pages | Hours | When |
|-------|:-----:|:-----:|------|
| Phase 1 | 18 | ~40 | Before launch (Sprint 7B) |
| Phase 2 | 23 | ~57 | Post-launch, month 1 (includes AI sandbox Tier 1+2) |
| Phase 3 | 23 | ~49 | Month 2-3 (includes sandbox code analysis + learning loop) |
| Phase 4 | 8 | ~17 | Marketplace launch |
| **TOTAL** | **72** | **~163** | |

---

## COMPLETE PAGE INVENTORY (All Routes)

### Command Center
| Route | Page |
|-------|------|
| `/` | Morning Briefing + Action Queue + Metrics Bar |

### Unified Inbox
| Route | Page |
|-------|------|
| `/inbox` | Unified Inbox (all accounts) |
| `/inbox/compose` | Compose Email |

### Accounts
| Route | Page |
|-------|------|
| `/accounts/companies` | Company Directory |
| `/accounts/companies/[id]` | Company Detail (Overview / Usage / Financial / Support) |
| `/accounts/users` | User Directory |
| `/accounts/users/[id]` | User Detail |

### Support
| Route | Page |
|-------|------|
| `/support/tickets` | Ticket Queue |
| `/support/tickets/[id]` | Ticket Detail + Thread |
| `/support/knowledge-base` | Article List |
| `/support/knowledge-base/[id]` | Article Editor |
| `/support/satisfaction` | Satisfaction Dashboard |
| `/support/sandbox` | AI Support Sandbox Dashboard |
| `/support/sandbox/approvals` | Tier 2 Approval Queue |
| `/support/sandbox/metrics` | Sandbox Performance + Learning Metrics |
| `/support/sandbox/calculator-tests` | Calculator Verification Log |

### Health
| Route | Page |
|-------|------|
| `/health/status` | System Status |
| `/health/errors` | Error Dashboard (Sentry) |
| `/health/performance` | Performance Metrics |
| `/health/costs` | Infrastructure Costs |

### Revenue
| Route | Page |
|-------|------|
| `/revenue/dashboard` | Revenue Dashboard |
| `/revenue/subscriptions` | Subscription Management |
| `/revenue/churn` | Churn Analysis |
| `/revenue/cohorts` | Cohort Analysis |

### Banking & Treasury
| Route | Page |
|-------|------|
| `/treasury/accounts` | Bank Accounts (Plaid) |
| `/treasury/cash-flow` | Cash Flow Dashboard |
| `/treasury/taxes` | Tax Intelligence |
| `/treasury/projections` | Financial Projections |

### Legal
| Route | Page |
|-------|------|
| `/legal/entities` | Entity Management |
| `/legal/contracts` | Contract Vault |
| `/legal/terms-generator` | Terms & Privacy Generator |
| `/legal/ip` | IP Protection |
| `/legal/compliance` | Compliance Dashboard |
| `/legal/disputes` | Dispute Tracker |

### Dev Terminal
| Route | Page |
|-------|------|
| `/dev/terminal` | Claude Code Terminal |
| `/dev/deployments` | Deployment Dashboard |
| `/dev/ci` | CI/CD Monitor |
| `/dev/database` | Database Explorer |
| `/dev/app-stores` | App Store Management |

### AI Operations
| Route | Page |
|-------|------|
| `/ai/usage` | Usage Dashboard |
| `/ai/analytics` | Query Analytics |
| `/ai/costs` | Cost Optimization |
| `/ai/scans` | Scan Intelligence |

### Content
| Route | Page |
|-------|------|
| `/content/calculators` | Calculator Manager |
| `/content/exams` | Exam Question Manager |
| `/content/diagrams` | Diagram + Guide Manager |
| `/content/releases` | Release Notes |

### Marketing
| Route | Page |
|-------|------|
| `/marketing/discovery` | Contractor Discovery Engine |
| `/marketing/discovery/prospects` | Prospect Database |
| `/marketing/discovery/prospects/[id]` | Prospect Detail |
| `/marketing/campaigns` | Campaign List |
| `/marketing/campaigns/[id]` | Campaign Builder / Detail |
| `/marketing/templates` | Email Template Library |
| `/marketing/templates/[id]` | Template Editor |
| `/marketing/ads` | Ad Dashboard (Google + Meta) |
| `/marketing/ads/[id]` | Ad Campaign Detail |
| `/marketing/seo` | SEO Command Center |
| `/marketing/landing-pages` | Landing Page Manager |
| `/marketing/landing-pages/[id]` | Landing Page Editor |
| `/marketing/referrals` | Referral Program |

### Growth CRM
| Route | Page |
|-------|------|
| `/growth/pipeline` | Pipeline Board (Kanban) |
| `/growth/prospects/[id]` | Prospect Detail |
| `/growth/demos` | Demo Scheduler |
| `/growth/tasks` | Daily Growth Tasks |

### Services
| Route | Page |
|-------|------|
| `/services/directory` | Service Directory + Status |

### Marketplace Ops
| Route | Page |
|-------|------|
| `/marketplace/leads` | Lead Dashboard |
| `/marketplace/disputes` | Dispute Resolution |
| `/marketplace/equipment` | Equipment Knowledge Base |
| `/marketplace/contractors` | Non-Subscriber Tracking |

### Communications
| Route | Page |
|-------|------|
| `/comms/announcements` | Announcement Manager |
| `/comms/broadcasts` | Email Broadcasts |
| `/comms/maintenance` | Maintenance Windows |

### Analytics
| Route | Page |
|-------|------|
| `/analytics/product` | Product Analytics |
| `/analytics/market` | Market Intelligence |
| `/analytics/projections` | Financial Projections |

### Document Vault
| Route | Page |
|-------|------|
| `/vault` | Document Vault (all categories) |
| `/vault/[id]` | Document Detail |

---

## BUILD ORDER (Updated Platform-Wide)

```
CURRENT PLAN:
1. DevOps Phase 1 (environments + secrets)                    ~2 hrs
2. Database Migration (Supabase + RLS + PowerSync)             ~17-25 hrs
3. Wire W1-W6 (core business → field tools → CRM → portal)    ~120 hrs
4. DevOps Phase 2 (Sentry + tests + CI/CD)                    ~8-12 hrs
5. OPS PORTAL PHASE 1 (accounts + support + inbox + health)    ~40 hrs    ← NEW
6. LAUNCH
7. OPS PORTAL PHASE 2 (marketing engine + growth + treasury)   ~45 hrs    ← NEW
8. Business OS Expansion (9 systems)                           Ongoing
9. OPS PORTAL PHASE 3 (legal + dev terminal + ads + analytics) ~45 hrs    ← NEW
10. Marketplace Launch (Doc 33)
11. OPS PORTAL PHASE 4 (marketplace ops)                        ~17 hrs    ← NEW
```

---

## RULES

1. **This portal is INTERNAL ONLY.** Never expose to customers. `super_admin` role only.
2. **Read-only impersonation.** View any company's data. CANNOT modify business data. Support actions go through controlled Edge Functions with audit logging.
3. **Every action is audit-logged.** ops_audit_log records every modification with who, what, when, why.
4. **Customer data privacy.** Account-level data visible. AI query content NOT visible (aggregated patterns only). Call recordings require explicit access. Financial data (SSNs, bank accounts) remains encrypted — super_admin sees that encryption exists, not the values.
5. **Marketing compliance.** CAN-SPAM. Unsubscribe honored within 24 hours. No purchased email lists. All prospect data from public sources only.
6. **Prospect data is separate from customer data.** Different tables, different lifecycle. converted_company_id links on conversion.
7. **Build Phase 1 before launch.** Cannot operate a SaaS without account management, support, health monitoring, and revenue tracking.
8. **The Ops AI is NOT the customer AI.** Different system prompt, different context, different permissions. Customer Z Intelligence sees one company. Ops AI sees everything.
9. **State licensing board access: legal and respectful.** Rate limit scraping. Cache results. Public records but fragile government infrastructure.
10. **Ad platforms require verified business accounts.** Google Ads and Meta Ads API access needs business verification — 1-2 weeks lead time.
11. **Design accent:** Deep navy or teal. NOT Stripe purple, NOT contractor orange. Same "Linear meets Stripe" quality standard — internal doesn't mean ugly.
12. **Bank data (Plaid) is YOUR data, not customer data.** Separate from the contractor Plaid integration in ZAFTO Books. Different Plaid environments.
13. **Legal documents are NOT legal advice.** Claude generates drafts. Attorney reviews the critical ones. The portal tracks and organizes — it doesn't replace a lawyer.
14. **Dev Terminal is sandboxed.** Claude Code can execute in dev/staging environments. Production deployments require explicit double-confirmation.
15. **Email inbox respects privacy.** Personal email in a separate tab. No AI processing on personal emails unless you explicitly route them.
16. **Credential vault: zero plaintext storage.** All API keys encrypted via Supabase Vault. Never displayed in UI — only "last 4 chars" shown for identification.
17. **The AI personality: co-founder, not chatbot.** Direct. Full context. No hedging. No "I'm just an AI." It knows the business, it knows the numbers, it knows what needs to happen. It talks like we talk.

---

## URL STRUCTURE (Updated)

```
zafto.app              → Marketing landing page
zafto.cloud            → Contractor CRM (web portal)
client.zafto.cloud     → ZAFTO Home (homeowner portal)
ops.zafto.cloud        → Founder OS (THIS — internal operations)
status.zafto.app       → Public status page (auto-generated from health checks)
home.zafto.app         → ZAFTO Home marketing (future)
yourco.zafto.cloud     → Contractor websites (future)
```

---

## THE PHILOSOPHY

ZAFTO tells contractors to stop using 12 different tools. The Ops Portal is Robert
practicing what he preaches. One login. One screen. Everything.

The alternative is this:
- Tab 1: Supabase
- Tab 2: Stripe
- Tab 3: Sentry
- Tab 4: Gmail (support)
- Tab 5: Gmail (personal)
- Tab 6: GitHub
- Tab 7: Cloudflare
- Tab 8: SendGrid
- Tab 9: Google Ads
- Tab 10: Bank website
- Tab 11: Apple Developer
- Tab 12: Google Play
- Tab 13: Some legal doc somewhere
- Tab 14: A spreadsheet tracking prospects
- Tab 15: VS Code terminal

That's exactly what ZAFTO's customers deal with before they find ZAFTO.
The founder of the solution shouldn't have the same problem.

---

*This is Founder OS. The command center for running ZAFTO and Tereda Software LLC.
Every email, every dollar, every customer, every line of code, every legal document,
every marketing campaign — one login, one AI co-pilot, zero context switching.*
