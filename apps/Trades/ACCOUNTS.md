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
| Firebase (NEW) | console.firebase.google.com | tereda.dev@gmail.com | Backend - AI, Auth, Firestore | 2026-01-30 | ✅ Active |
| Firebase (OLD) | console.firebase.google.com | teredasoftware@gmail.com | DEPRECATED | 2026-01-27 | ❌ Inaccessible |
| Cloudflare | dash.cloudflare.com | tereda.dev@gmail.com | DNS, hosting, domains | 2026-01-30 | ✅ Active |
| Claude AI | claude.ai | teredasoftware@gmail.com | Development assistant | Existing | ⚠️ At risk |
| Google Cloud | console.cloud.google.com | tereda.dev@gmail.com | $1,300 credits | 2026-01-30 | ✅ Active |

---

## 🔥 FIREBASE CONFIGURATION

**NEW Project (Active):**
- Project ID: `zafto-2b563`
- Project Name: Zafto
- Region: nam5 (US Central)
- Database: `zaftodatabase` (Firestore)
- Plan: Blaze (pay-as-you-go)

**Config Values:**
```
apiKey: AIzaSyCZYl97ZFbBtHjfcSqbJk_tdsMPftaW1oY
authDomain: zafto-2b563.firebaseapp.com
projectId: zafto-2b563
storageBucket: zafto-2b563.firebasestorage.app
messagingSenderId: 325142344687
appId: 1:325142344687:web:7cf5e57761ab82347e7c1a
measurementId: G-BN35YMC95B
```

**Services Enabled:**
- [x] Authentication (Email/Password)
- [x] Firestore Database (Production mode)
- [ ] Cloud Functions (needs Anthropic API key)
- [ ] Storage

**OLD Project (Deprecated):**
- Project ID: `zafto-5c3f2`
- Status: Inaccessible (tied to disabled Gmail)

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
- zafto.cloud → Firebase Hosting (web app/dashboard)

---

## 🔑 API KEYS & SECRETS

| Service | Key Name | Location | Status |
|---------|----------|----------|--------|
| Anthropic | Claude API Key | Firebase Functions Config | ❌ NOT SET - Need to create at console.anthropic.com |

**To set Anthropic key:**
```bash
firebase login
firebase functions:config:set anthropic.key="YOUR_KEY"
firebase deploy --only functions
```

---

## 📱 APP STORE ACCOUNTS

| Service | Email | Purpose | Status |
|---------|-------|---------|--------|
| Apple Developer | (existing) | iOS App Store | Converting Individual → Organization (LLC) |
| Google Play | TBD | Android distribution | Not created yet |

---

## 💳 BILLING NOTES

- **Firebase:** Blaze plan (pay-as-you-go), ~$1,300 in Google Cloud credits available
- **Anthropic:** Pay-per-use API ($5 free credits for new accounts)
- **Apple Developer:** $99/year (existing)
- **Cloudflare:** Free tier (domains at cost)
- **Claude AI Max:** $200/month (at risk due to email issue)

---

## 🔒 REDUNDANCY CHECKLIST

Add backup owners/admins to all critical services:

- [ ] Firebase: Add backup owner (tereda.dev + one more)
- [ ] Cloudflare: Add team member
- [ ] GitHub: Already has access
- [ ] Apple Developer: Will be org account under LLC

---

*Update this file whenever a new account or service is added.*
