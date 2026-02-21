# ZAFTO ELECTRICAL - ACCOUNTS & SERVICES TRACKER
**Primary Email:** tereda.dev@gmail.com (NEW - Jan 30, 2026)
**Legacy Email:** teredasoftware@gmail.com (DISABLED by Google - Jan 29, 2026)
**Last Updated:** January 30, 2026

---

## ⚠️ CRITICAL ACCOUNT NOTES

**teredasoftware@gmail.com was disabled by Google on Jan 29, 2026**
- Google flagged it as "bot account" (false positive)
- Appeal submitted - awaiting review (2 business days)
- If appeal fails, can submit ONE more appeal
- This affected: Old Firebase project, Claude AI account

**LESSON LEARNED:** Always add multiple admin/owners to critical services

---

## 🔐 ACCOUNTS CREATED

| Service | URL | Email/Login | Purpose | Created | Status |
|---------|-----|-------------|---------|---------|--------|
| GitHub | github.com/teredasoftware | TeredaDeveloper | Source control | Existing | ✅ Active |
| Firebase (DEPRECATED) | console.firebase.google.com | tereda.dev@gmail.com | REMOVED S151 — migrated to Supabase | 2026-01-30 | ❌ Deprecated |
| Supabase | supabase.com | tereda.dev@gmail.com | Backend - Auth, DB, Storage, Edge Functions | 2026-02 | ✅ Active |
| Cloudflare | dash.cloudflare.com | tereda.dev@gmail.com | DNS, hosting, domains | 2026-01-30 | ✅ Active |
| Claude AI | claude.ai | teredasoftware@gmail.com | Development assistant | Existing | ⚠️ At risk |
| Google Cloud | console.cloud.google.com | tereda.dev@gmail.com | $1,300 credits | 2026-01-30 | ✅ Active |

---

## 🔥 FIREBASE — DEPRECATED (S151)

> **Firebase fully removed from codebase in S151 (2026-02-21).**
> All services migrated to Supabase. Firebase project `zafto-2b563` kept for reference only.
> Stripe keys recovered before removal. No data loss.

## ☁️ SUPABASE CONFIGURATION

- **Project:** onidzgatvndkhtiubbcw
- **URL:** https://onidzgatvndkhtiubbcw.supabase.co
- **Region:** US East
- **Services:** Auth, PostgreSQL + RLS, Storage, Realtime, 92 Edge Functions
- **Plan:** Pro

---

## ☁️ CLOUDFLARE CONFIGURATION

**Nameservers (same for all domains):**
- owen.ns.cloudflare.com
- priscilla.ns.cloudflare.com

**Domains:**
| Domain | Purpose | Status | Registrar |
|--------|---------|--------|-----------|
| zafto.cloud | Web dashboard/portal | Pending NS propagation | Porkbun |
| zafto.app | Marketing website | Not yet added | TBD |
| zafto.pro | Defensive/redirect | Not yet added | TBD |
| teredasoftware.com | Company page/redirect | Added to Cloudflare | Porkbun |

**Architecture:**
- zafto.app → Cloudflare Pages (marketing site)
- zafto.cloud → Vercel (web CRM dashboard)

---

## 🔑 API KEYS & SECRETS

| Service | Key Name | Location | Status |
|---------|----------|----------|--------|
| Anthropic | Claude API Key | Supabase Edge Function secrets | ❌ NOT SET - Phase E paused |

---

## 📱 APP STORE ACCOUNTS

| Service | Email | Purpose | Status |
|---------|-------|---------|--------|
| Apple Developer | (existing) | iOS App Store | Converting Individual → Organization (LLC) |
| Google Play | TBD | Android distribution | Not created yet |

---

## 💳 BILLING NOTES

- **Supabase:** Pro plan
- **Anthropic:** Pay-per-use API (Phase E paused)
- **Apple Developer:** $99/year (existing)
- **Cloudflare:** Free tier (domains at cost)
- **Claude AI Max:** $200/month (at risk due to email issue)

---

## 🔒 REDUNDANCY CHECKLIST

Add backup owners/admins to all critical services:

- [x] Firebase: REMOVED — migrated to Supabase (S151)
- [ ] Cloudflare: Add team member
- [ ] GitHub: Already has access
- [ ] Apple Developer: Will be org account under LLC

---

*Update this file whenever a new account or service is added.*
