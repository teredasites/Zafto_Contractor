# ZAFTO Platform

**Multi-Trade Professional App Ecosystem**

## Overview

ZAFTO is a platform for skilled trades professionals combining:
- Field reference tools (calculators, code tables, diagrams)
- Job management (create, track, complete)
- Invoicing (generate, send, track payments)
- Customer management (CRM)
- Exam preparation (trade-specific licensing exams)
- AI scanning (equipment identification, code compliance)

## Structure

```
Zafto/
├── packages/                    # SHARED CODE
│   ├── zafto_core/              # Business logic, models, services
│   │   ├── models/              # Job, Invoice, Customer, User
│   │   ├── services/            # Auth, sync, payments
│   │   └── providers/           # Riverpod state management
│   │
│   ├── zafto_ui/                # Design System v2.6
│   │   ├── theme/               # ZaftoColors, themes, builder
│   │   ├── widgets/             # Shared UI components
│   │   └── screens/             # Settings, profile, jobs, invoices
│   │
│   └── zafto_exam/              # Exam engine
│       ├── models/              # Question, Quiz, Progress
│       ├── services/            # Progress tracking, scoring
│       └── screens/             # Quiz UI, results, dashboard
│
├── apps/                        # INDIVIDUAL TRADE APPS
│   ├── electrical/              # ZAFTO Electrical
│   │   ├── calculators/         # 35 electrical calculators
│   │   ├── diagrams/            # Wiring diagrams
│   │   ├── data/                # NEC tables, exam questions
│   │   └── ...
│   │
│   ├── plumbing/                # ZAFTO Plumbing (future)
│   ├── hvac/                    # ZAFTO HVAC (future)
│   └── spellbook/               # Spellbook Legal (future)
│
├── web/                         # WEB PORTAL
│   └── zafto_portal/            # zafto.app - Office dashboard
│       ├── dashboard/           # Job overview, stats
│       ├── dispatch/            # Team scheduling
│       └── reports/             # Analytics, revenue
│
└── melos.yaml                   # Monorepo configuration
```

## Shared vs Trade-Specific

| Shared (packages/)              | Trade-Specific (apps/)           |
|---------------------------------|----------------------------------|
| Job/Invoice/Customer models     | Calculators                      |
| Auth & user management          | Code tables (NEC, IPC, etc.)     |
| Design system (10 themes)       | Diagrams                         |
| Exam engine (framework)         | Exam questions                   |
| Payment processing              | Trade-specific AI prompts        |

## Tech Stack

- **Framework:** Flutter (iOS, Android, Web, Desktop)
- **State:** Riverpod
- **Local Storage:** Hive
- **Cloud:** Supabase (Auth, PostgreSQL + RLS, Edge Functions, Storage, Realtime)
- **AI:** Claude API (equipment scanning)
- **Monorepo:** Melos

## Getting Started

```bash
# Install melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run electrical app
melos run:electrical

# Analyze all packages
melos analyze

# Run all tests
melos test
```

## Bundle IDs

| App | Bundle ID |
|-----|-----------|
| Electrical | com.teredasoftware.zafto.electrical |
| Plumbing | com.teredasoftware.zafto.plumbing |
| HVAC | com.teredasoftware.zafto.hvac |
| Spellbook | com.teredasoftware.spellbook |

## Backend (Supabase)

Single Supabase project with multi-tenant architecture:
- Users create ONE account, access all purchased trades
- Data syncs across apps via Supabase Realtime
- PostgreSQL + RLS for all business data, 92 Edge Functions

---

**Owner:** Tereda Software LLC
**Repository:** https://github.com/teredasoftware/Zafto
