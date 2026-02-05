# zafto_core

**Shared Business Logic Package**

## Purpose

Trade-agnostic business logic that ALL ZAFTO apps share.

## Status

🔴 **NOT YET EXTRACTED** - Code currently lives in apps/electrical/

## What Will Live Here

```
zafto_core/
├── lib/
│   ├── models/
│   │   ├── job.dart              # Job model with status workflow
│   │   ├── invoice.dart          # Invoice with line items, tax
│   │   ├── customer.dart         # Customer profile
│   │   ├── user.dart             # User account, subscriptions
│   │   └── company.dart          # Business profile for invoices
│   │
│   ├── services/
│   │   ├── auth_service.dart     # Firebase Auth wrapper
│   │   ├── job_service.dart      # Job CRUD operations
│   │   ├── invoice_service.dart  # Invoice management
│   │   ├── customer_service.dart # Customer management
│   │   ├── sync_service.dart     # Firestore sync
│   │   └── payment_service.dart  # Stripe/IAP
│   │
│   └── providers/
│       ├── auth_provider.dart    # Auth state
│       ├── job_provider.dart     # Jobs state
│       ├── invoice_provider.dart # Invoices state
│       └── customer_provider.dart# Customers state
│
├── pubspec.yaml
└── README.md
```

## When to Extract

Extract when building the SECOND app (plumbing). Until then, keep code in electrical to avoid premature abstraction.

## Current Location

These files currently exist in:
- `apps/electrical/lib/models/business/`
- `apps/electrical/lib/services/`
