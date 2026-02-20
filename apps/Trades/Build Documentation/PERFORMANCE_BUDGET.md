# Zafto Performance Budget

## Response Time Targets

| Metric | Target (p95) | Measured Baseline |
|--------|-------------|-------------------|
| Page Load (TTI) | < 2.0s | TBD — measure after Vercel deploy |
| API Response (CRUD) | < 500ms | TBD |
| List Query (10K rows) | < 200ms | TBD |
| Full-Text Search | < 300ms | TBD |
| Real-time Event Delivery | < 2.0s | TBD |
| PDF Generation | < 5.0s | TBD |
| Edge Function Cold Start | < 1.0s | TBD |

## Database Query Targets

| Query Type | Target | Index Strategy |
|-----------|--------|----------------|
| Company-scoped list (jobs, customers, invoices) | < 100ms | B-tree on company_id + partial WHERE deleted_at IS NULL |
| Text search (Cmd+K) | < 300ms | GIN on search_vector TSVECTOR |
| Dashboard aggregates (revenue, pipeline) | < 500ms | Materialized views (mv_company_revenue_summary, mv_job_pipeline) |
| Audit log queries | < 200ms | BRIN on created_at (append-only table) |
| JSONB filter (settings, metadata) | < 200ms | GIN on JSONB columns |

## Bundle Size Targets

| Portal | Target (gzip) | Notes |
|--------|--------------|-------|
| web-portal | < 500KB first load | Largest portal, most features |
| team-portal | < 300KB first load | Focused on field worker flows |
| client-portal | < 200KB first load | Simplest portal, public-facing |
| ops-portal | < 300KB first load | Admin-only, fewer users |
| Flutter APK | < 50MB | Includes all trade assets |

## Index Strategy (S143 — INFRA-4)

- **30 tables** received missing `company_id` B-tree indexes (Migration 123)
- **8 tables** received BRIN indexes on `created_at` (append-only audit/log tables)
- **7 tables** received partial indexes (active records WHERE deleted_at IS NULL)
- **5 tables** received GIN indexes on JSONB columns
- **6 tables** received search_vector TSVECTOR + GIN indexes (Migration 124)
- Auth helper functions (requesting_user_id, requesting_user_role, requesting_company_id) marked STABLE for initPlan caching

## Materialized Views

| View | Refresh Interval | Purpose |
|------|-----------------|---------|
| mv_company_revenue_summary | 15 min (pg_cron) | Invoice aggregates per company/month |
| mv_job_pipeline | 15 min (pg_cron) | Job counts/values by status per company |

## Monitoring

- Sentry Performance Monitoring: 10% trace sampling on all 4 portals
- Health check endpoint: `/functions/v1/health-check` (no auth, uptime monitoring)
- pg_cron materialized view refresh: every 15 minutes CONCURRENTLY
