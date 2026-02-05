# zafto_portal

**ZAFTO.APP - Web Portal for Office/Desktop Use**

## Purpose

Web-based dashboard for office staff, back-office management, and desktop users. Connects to the SAME Firebase backend as mobile apps.

## Status

🔴 **NOT YET BUILT** - Planned for Sprint 8-9

## URL

**Production:** https://zafto.app
**Domain:** Already owned ✅

## What Will Live Here

```
zafto_portal/
├── lib/
│   ├── main.dart
│   ├── router.dart              # Go Router navigation
│   │
│   ├── screens/
│   │   ├── login/               # Auth screens
│   │   ├── dashboard/           # Main dashboard
│   │   ├── jobs/                # Job management
│   │   ├── invoices/            # Invoice management
│   │   ├── customers/           # CRM
│   │   ├── dispatch/            # Team scheduling (Business tier)
│   │   ├── reports/             # Analytics & reporting
│   │   └── settings/            # Account settings
│   │
│   └── widgets/                 # Web-specific widgets
│
├── web/
│   ├── index.html
│   └── manifest.json
│
├── pubspec.yaml
└── README.md
```

## Features (Planned)

### All Users
- `/login` - Email/password (same Firebase Auth as mobile)
- `/dashboard` - Today's jobs, quick stats
- `/jobs` - Full job list, filters, search
- `/jobs/:id` - Job detail with photos, notes
- `/invoices` - Invoice list, send, mark paid
- `/customers` - Customer database

### Business Tier Only
- `/team` - Team member management
- `/dispatch` - Map view, assign jobs to techs
- `/reports` - Revenue reports, performance metrics
- `/settings/company` - Company branding, invoice templates

## Tech Stack

- **Framework:** Flutter Web (same codebase as mobile)
- **Hosting:** Firebase Hosting
- **Auth:** Firebase Auth (shared with mobile)
- **Database:** Firestore (shared with mobile)
- **State:** Riverpod

## Architecture

```
Mobile App (field use)        Web Portal (office use)
        │                              │
        └──────────┬───────────────────┘
                   ▼
           Firebase Backend
           ├── Auth (shared users)
           ├── Firestore (shared data)
           └── Storage (shared photos)
```

Real-time sync: Changes in mobile appear instantly in web portal and vice versa.

## Dependencies

Will import from shared packages:
```yaml
dependencies:
  zafto_core:
    path: ../../packages/zafto_core
  zafto_ui:
    path: ../../packages/zafto_ui
```

## Deployment

```bash
# Build for web
cd web/zafto_portal
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Timeline

- Sprint 8: Core portal (jobs, invoices, customers)
- Sprint 9: Business features (dispatch, reports, team)
