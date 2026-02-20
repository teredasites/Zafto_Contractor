# Sprint Security Verification Template

Copy this checklist into every new sprint. NO sprint is complete without every item checked.

---

## Security Verification (MANDATORY — NO EXCEPTIONS)

### Database (for sprints creating new tables)
- [ ] RLS enabled on every new table
- [ ] Separate SELECT/INSERT/UPDATE/DELETE policies (NOT `FOR ALL`)
- [ ] DELETE restricted to owner/admin roles on business data
- [ ] `company_id UUID NOT NULL REFERENCES companies(id)` on every new table
- [ ] `company_id` B-tree index on every new table
- [ ] `audit_trigger_fn` trigger on every new business table
- [ ] `deleted_at TIMESTAMPTZ` column on every new business table (soft delete)
- [ ] `update_updated_at()` trigger on every new table
- [ ] All RLS policies use `requesting_company_id()` (NOT subquery)
- [ ] All RLS policies use `requesting_user_role()` for role checks
- [ ] New columns on Flutter-writable tables: nullable with DEFAULT (mobile backward compat)

### Edge Functions (for sprints creating new EFs)
- [ ] Auth via `supabase.auth.getUser()` from Authorization header
- [ ] `company_id` extracted from JWT `app_metadata` (NOT from request body)
- [ ] Role check where needed (`requesting_user_role()` pattern)
- [ ] Rate limiting via `_shared/rate-limiter.ts` on public-facing EFs
- [ ] CORS via `_shared/cors.ts` (NOT hardcoded `*`)
- [ ] Input validation on all user-provided parameters
- [ ] Error responses: typed errors, no raw stack traces, no internal details
- [ ] Webhook EFs: signature verification + fail-closed if secret missing

### Next.js Hooks (for sprints creating new hooks)
- [ ] Soft delete: `.update({ deleted_at })` NOT `.delete()` on business data
- [ ] List queries include `.is('deleted_at', null)` filter
- [ ] Error state returned: `{ data, loading, error, mutations }`
- [ ] Real-time subscription cleanup in useEffect return
- [ ] Company_id scoping via authenticated Supabase client (RLS handles it)

### Flutter Screens (for sprints creating new screens)
- [ ] All 4 states handled: loading, error, empty, data
- [ ] NO direct Supabase imports — use repositories/providers only (3-layer architecture)
- [ ] `Semantics` widgets on custom interactive elements
- [ ] Error handling: try/catch on all async operations, typed errors

### Cross-Cutting
- [ ] All new UI strings added to all 10 locale files (i18n flawlessness)
- [ ] `dart analyze` — 0 errors
- [ ] All 4 portals: `npm run build` — 0 errors
- [ ] Shared types regenerated: `npm run gen-types` after migration changes

### Accessibility Verification (MANDATORY — WCAG 2.2 AA)
- [ ] All new pages: semantic HTML (landmarks, headings hierarchy, labels on inputs)
- [ ] All new interactive elements: keyboard focusable + visible focus indicator
- [ ] All new icon-only buttons: aria-label present
- [ ] All new forms: labels linked, errors announced via aria-live, required fields marked
- [ ] All new status indicators: not color-only (include text/icon)
- [ ] All new images: alt text present (decorative = alt="")
- [ ] All new modals: focus trapped, Escape closes, focus returns on close
- [ ] Color contrast: all text meets 4.5:1 (normal) or 3:1 (large)
- [ ] axe-core: zero violations on new pages
- [ ] Flutter: Semantics widgets on all new custom widgets
- [ ] Toast notifications: use ToastProvider (useToast hook) — NOT alert(). Errors use role="alert", success/info use role="status"
- [ ] Loading states: aria-busy="true" on loading containers, aria-label="Loading" on spinners
- [ ] Real-time updates: announced via aria-live="polite" region — don't move focus
- [ ] PDF outputs: document properties set (title, subject, author), alt text on images/logos
- [ ] Text scaling: no overflow at 1.5x font scale (Flutter) or 200% browser zoom (Next.js)

### Legal Defense Verification (MANDATORY for sprints with user-facing outputs)
- [ ] All calculators/estimators: result area includes source attribution + disclaimer footer
- [ ] All code references: edition year + "verify with local AHJ" in result metadata
- [ ] All inspection outputs: standard reference + report footer disclaimer
- [ ] All pricing/labor data: source + date shown (BLS, market data, etc.)
- [ ] All property data: source attribution per data point
- [ ] All PDF exports: professional footer with appropriate disclaimer text
- [ ] Data freshness visible — user can see when data was last updated

### Depth Verification Gate (MANDATORY)
- [ ] Would a real professional in this trade use this feature on a real job site on day one?
- [ ] Is EVERY sub-feature complete, not just scaffolded?
- [ ] Does it save data, link to jobs, produce useful output?
