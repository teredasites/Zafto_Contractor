# ZAFTO INCIDENT RESPONSE PLAN
## Sprint C5 -- Operational Security

**Last Updated:** February 6, 2026
**Owner:** Robert (Damian Tereda / Tereda Software LLC)
**Contact:** admin@zafto.app

---

## 1. SEVERITY LEVELS

| Level | Definition | Response Time | Examples |
|-------|-----------|---------------|----------|
| **P0** | Platform down, data breach, security incident | 15 min | RLS bypass detected, auth system failure, data exfiltration, Supabase prod credentials leaked, payment data exposed |
| **P1** | Major feature broken, payment failure, auth degraded | 1 hour | Stripe webhook failure, Supabase connection pool exhausted, storage buckets inaccessible, Edge Function crashes |
| **P2** | Degraded performance, non-critical feature broken | 4 hours | Slow queries, Sentry error spike, single field tool failing, RevenueCat sync lag |
| **P3** | Minor issue, cosmetic, non-blocking | 24 hours | UI glitch, analytics broken, non-critical notification delay |

**Escalation rule:** Any P2 unresolved for 8 hours escalates to P1. Any P1 unresolved for 4 hours escalates to P0.

---

## 2. DATA BREACH RESPONSE

### Phase 1: Detect (0-15 min)
- Sentry alerts, Supabase logs, Cloudflare WAF alerts, or manual discovery.
- Confirm breach is real (not a false positive). Check `audit_log` table in Supabase.
- Log the exact time of detection and how it was discovered.

### Phase 2: Contain (15-60 min)
1. **Revoke compromised keys immediately** (see Section 3).
2. **Supabase:** Dashboard > Settings > API > regenerate `anon` and `service_role` keys if compromised. Update all apps.
3. **Enable Cloudflare "I'm Under Attack" mode** if active exploitation: Cloudflare Dashboard > Overview > Under Attack Mode.
4. **Disable affected Edge Functions** via Supabase Dashboard > Edge Functions > delete/redeploy.
5. **Lock affected user accounts:** `UPDATE auth.users SET banned_until = 'infinity' WHERE id = '<user_id>';` via Supabase SQL Editor.
6. **Revoke all active sessions:** Supabase Dashboard > Authentication > Users > select user > revoke sessions.
7. **Check RLS:** Run `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';` -- confirm all tables show `true`.

### Phase 3: Assess (1-4 hours)
- Determine: What data was accessed? How many users affected? What vulnerability was exploited?
- Query `audit_log`: `SELECT * FROM audit_log WHERE created_at > '<breach_start>' ORDER BY created_at;`
- Check Supabase Auth logs: Dashboard > Authentication > Logs.
- Check Cloudflare WAF logs: Dashboard > Security > Events.
- Document everything in the incident log (Section 5).

### Phase 4: Notify (within 72 hours of confirmed breach)
- **Legal requirement:** Most US states require notification within 30-72 hours of discovery.
- Notify affected users using template in Section 5.
- If payment data (Stripe): Contact Stripe support immediately via Dashboard. Stripe handles PCI notification.
- If >500 users affected in a single state: Notify that state's Attorney General.
- File records of all notifications sent.

### Phase 5: Remediate
- Patch the vulnerability. Deploy fix to prod.
- Rotate ALL keys (Section 3) -- not just the compromised one.
- Add new RLS policies or tighten existing ones as needed.
- Add Sentry alerts for the attack vector.
- Update Cloudflare WAF rules to block the exploit pattern.

### Phase 6: Post-Incident Review
- Conduct within 48 hours. Use template in Section 7.

---

## 3. KEY ROTATION PROCEDURES

### Supabase (anon key, service role key, JWT secret)
**Rotate:** Dashboard > Settings > API > Click "Generate new key" for anon/service role. JWT secret: Dashboard > Settings > API > JWT Settings.
**Update:** `web-portal/.env.local`, `team-portal/.env.local`, `client-portal/.env.local`, Flutter `env_config.dart`, GitHub Actions secrets (`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`), Cloudflare Pages env vars (if applicable).
**Verify:** Hit `/rest/v1/` with old key (should 401). Hit with new key (should 200). Run `npm run build` on all 3 portals. Run `flutter build` for mobile.
**Rollback:** Supabase does not support reverting to old keys. If new key breaks prod, fix the env vars -- the key itself cannot be undone.

### Stripe (API keys, webhook signing secrets)
**Rotate:** Stripe Dashboard > Developers > API keys > Roll key. For webhooks: Developers > Webhooks > select endpoint > Roll secret.
**Update:** `web-portal/.env.local` (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`), GitHub Actions secrets, Edge Function env vars (`supabase secrets set STRIPE_SECRET_KEY=sk_live_...`).
**Verify:** Create a test payment. Check webhook delivery in Stripe Dashboard > Developers > Webhooks > Recent deliveries.
**Rollback:** Stripe keeps old key active for 24 hours after rolling. Revert env vars to old key within that window if needed.

### Claude API (Anthropic)
**Rotate:** console.anthropic.com > API Keys > Create new key > Delete old key.
**Update:** Edge Function env vars (`supabase secrets set ANTHROPIC_API_KEY=sk-ant-...`), GitHub Actions secrets.
**Verify:** Trigger an AI feature (Dashboard query). Check Sentry for API errors.
**Rollback:** Cannot recover deleted keys. Always create the new key before deleting the old one.

### Sentry (Auth tokens, DSN)
**Rotate:** sentry.io > Settings > Auth Tokens > Create new. DSN itself is not secret (public), but auth tokens for releases/source maps are.
**Update:** GitHub Actions secrets (`SENTRY_AUTH_TOKEN`), `sentry.*.config.ts` files if DSN changed.
**Verify:** Trigger a test error. Confirm it appears in Sentry dashboard.

### GitHub (Personal access tokens)
**Rotate:** GitHub > Settings > Developer settings > Personal access tokens > Generate new token > Delete old.
**Update:** Any CI/CD scripts or local dev tooling referencing the token.
**Verify:** `gh auth status` returns authenticated.

### Cloudflare (API tokens)
**Rotate:** Cloudflare Dashboard > My Profile > API Tokens > Create Token > Delete old.
**Update:** GitHub Actions secrets (`CLOUDFLARE_API_TOKEN`), any deployment scripts.
**Verify:** `curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer <token>"` returns `"status": "active"`.

### RevenueCat (API keys)
**Rotate:** RevenueCat Dashboard > Project Settings > API Keys > Create new > Delete old.
**Update:** Flutter `env_config.dart` (`REVENUECAT_API_KEY`), GitHub Actions secrets.
**Verify:** Trigger a subscription check in the app. Confirm RevenueCat dashboard shows the request.

### MS 365 (App passwords)
**Rotate:** admin.microsoft.com > Users > Active Users > select user > Reset password.
**Update:** Any SMTP integrations or automation scripts using the password.
**Verify:** Send a test email from the affected account.

---

## 4. ROLLBACK PROCEDURES

### Database (Supabase Migrations)
- Supabase migrations are forward-only. There is no `db rollback` command.
- **Procedure:** Write a new migration that reverses the change: `DROP TABLE IF EXISTS ...`, `ALTER TABLE ... DROP COLUMN ...`, etc.
- Save as `supabase/migrations/<timestamp>_rollback_<description>.sql`.
- Push: `npx supabase db push` from `apps/Trades/`.
- **Critical:** Always test rollback SQL against dev before running on prod.

### Web Apps (Next.js -- CRM, Team Portal, Client Portal)
- **Git revert:** `git revert <commit_hash> && git push origin main` triggers CI/CD rebuild.
- **Cloudflare Pages:** Dashboard > Pages > select project > Deployments > click previous deployment > "Rollback to this deploy".
- **Verify:** Check the live URL. Confirm Sentry shows no new errors.

### Flutter Mobile App
- **TestFlight (iOS):** Previous builds remain available. Select the prior build in App Store Connect > TestFlight > Builds and re-enable it.
- **Production (iOS):** Submit the previous build as a new release through App Store Connect. Apple review required (expedited review available for critical fixes).
- **Android (future):** Google Play Console > Release Management > select track > Manage > Rollback.

### Edge Functions
- **Redeploy previous version:** `git checkout <previous_commit> -- supabase/functions/<function_name>/` then `npx supabase functions deploy <function_name>`.
- **Emergency disable:** `npx supabase functions delete <function_name>` (removes entirely -- redeploy when fixed).

### DNS (Cloudflare)
- Cloudflare Dashboard > DNS > Records. Edit or delete the problematic record.
- DNS propagation: 1-5 minutes with Cloudflare proxy enabled, up to 48 hours if proxy was disabled.
- **Keep a snapshot** of all DNS records in this doc set or export via API before making changes.

---

## 5. COMMUNICATION TEMPLATES

### Customer Notification -- Data Breach
```
Subject: Important Security Notice from ZAFTO

Dear [Customer Name],

We are writing to inform you of a security incident that may have affected your account. On [DATE], we detected unauthorized access to [DESCRIPTION OF DATA -- e.g., "contact information including names and email addresses"].

What happened: [Brief factual description].
What data was involved: [Specific data types].
What we have done: [Actions taken -- key rotation, vulnerability patched, etc.].
What you should do: [Change password, monitor accounts, etc.].

We take the security of your data seriously. If you have questions, contact us at support@zafto.app.

Robert Tereda
Founder, ZAFTO
```

### Customer Notification -- Service Outage
```
Subject: ZAFTO Service Update

We experienced [a brief / an extended] service disruption on [DATE] from [TIME] to [TIME] UTC affecting [DESCRIPTION -- e.g., "job scheduling and invoice generation"].

The issue has been resolved. No data was lost. If you notice anything unusual in your account, contact support@zafto.app.

We apologize for the inconvenience.
```

### Internal Incident Log Entry
```
INCIDENT ID: INC-[YYYY]-[###]
SEVERITY: P[0-3]
DETECTED: [YYYY-MM-DD HH:MM UTC]
DETECTED BY: [Sentry alert / manual / customer report / Cloudflare alert]
DESCRIPTION: [What happened]
AFFECTED SYSTEMS: [Supabase / Stripe / Cloudflare / etc.]
AFFECTED USERS: [Count or "all" or "none"]
ACTIONS TAKEN: [Numbered list of actions with timestamps]
RESOLVED: [YYYY-MM-DD HH:MM UTC]
RESOLUTION: [What fixed it]
POST-INCIDENT REVIEW: [Scheduled date]
```

### Status Page Update (for future status.zafto.app)
```
[DATE HH:MM UTC] -- Investigating: We are aware of issues with [FEATURE] and are investigating.
[DATE HH:MM UTC] -- Identified: The issue has been identified as [ROOT CAUSE]. We are working on a fix.
[DATE HH:MM UTC] -- Resolved: The issue has been resolved. All systems operational.
```

---

## 6. CONTACT TREE

| Incident Type | Primary Contact | Method |
|---------------|----------------|--------|
| **Any P0** | Robert (Founder) | admin@zafto.app, phone |
| **Supabase outage/breach** | Supabase Support | support@supabase.io, Dashboard > Support |
| **Stripe payment failure** | Stripe Support | Dashboard > Help, support@stripe.com |
| **Apple App Store / TestFlight** | Apple Developer | developer.apple.com > Contact Us |
| **Cloudflare DNS/WAF/CDN** | Cloudflare Support | Dashboard > Support |
| **Sentry errors** | Self-service | sentry.io Dashboard |
| **RevenueCat IAP** | RevenueCat Support | app.revenuecat.com > Support |
| **MS 365 / Email** | Microsoft Admin | admin.microsoft.com |
| **GitHub Actions / Repo** | GitHub Support | support.github.com |
| **Domain registrar** | Cloudflare Registrar | Dashboard > Domain Registration |
| **Legal counsel** | TBD -- retain before launch | -- |
| **Cyber insurance** | TBD -- obtain before launch | -- |

---

## 7. POST-INCIDENT REVIEW TEMPLATE

```
# Post-Incident Review: INC-[YYYY]-[###]
Date of review: [DATE]
Incident severity: P[0-3]
Author: [NAME]

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | [First indicator / alert] |
| HH:MM | [Incident confirmed] |
| HH:MM | [Containment action taken] |
| HH:MM | [Fix deployed] |
| HH:MM | [Incident resolved] |

## Root Cause
[Specific technical root cause. Not "human error" -- dig deeper.]

## Impact
- Users affected: [count]
- Duration: [minutes/hours]
- Data compromised: [yes/no, what type]
- Revenue impact: [estimated]

## Actions Taken During Incident
[Numbered list with timestamps]

## What Went Well
- [e.g., "Sentry alert fired within 2 minutes"]

## What Needs Improvement
- [e.g., "Key rotation took 45 minutes because env var locations were not documented"]

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Specific action] | [Name] | [Date] | Open |
```

---

## 8. EMERGENCY QUICK REFERENCE

**P0 -- First 15 minutes checklist:**
1. Confirm the incident is real (check Sentry, Supabase logs, Cloudflare).
2. If data breach: revoke compromised keys NOW (Section 3).
3. If active attack: enable Cloudflare "Under Attack Mode".
4. If auth compromised: lock affected accounts in Supabase SQL Editor.
5. Log everything with timestamps in an incident log entry (Section 5).
6. Begin containment per Section 2.

**Critical URLs (bookmark these):**
| Service | URL |
|---------|-----|
| Supabase Dev | https://supabase.com/dashboard/project/onidzgatvndkhtiubbcw |
| Supabase Prod | https://supabase.com/dashboard/project/vhbngenmiueizfecdgpf |
| Cloudflare | https://dash.cloudflare.com |
| Stripe | https://dashboard.stripe.com |
| Sentry | https://sentry.io |
| GitHub | https://github.com/TeredaDeveloper |
| RevenueCat | https://app.revenuecat.com |
| Apple Developer | https://developer.apple.com |
| MS 365 Admin | https://admin.microsoft.com |

**Key file locations for env var updates:**
| App | Env File |
|-----|----------|
| Web CRM | `apps/Trades/web-portal/.env.local` |
| Team Portal | `apps/Trades/team-portal/.env.local` |
| Client Portal | `apps/Trades/client-portal/.env.local` |
| Flutter | `apps/Trades/lib/core/config/env_config.dart` |
| Edge Functions | `supabase secrets set KEY=value` (from `apps/Trades/`) |
| CI/CD | GitHub > Settings > Secrets and variables > Actions |
