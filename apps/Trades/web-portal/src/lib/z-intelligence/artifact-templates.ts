import type { ZArtifact } from './types';

export const MOCK_BID_ARTIFACT: ZArtifact = {
  id: 'mock-bid-1',
  type: 'bid',
  title: 'Bid #BID-2026-0042 — Whole House Rewire',
  content: `# Bid #BID-2026-0042

**Prepared for:** David Park
**Property:** 1847 Elm Street, Hartford, CT 06103
**Date:** February 6, 2026
**Valid until:** March 8, 2026

---

## Scope of Work

Complete whole-house rewire of 2,400 sq ft colonial home (built 1968). Replace existing aluminum wiring with copper throughout. Upgrade electrical panel from 100A to 200A. Install whole-house surge protection. Bring all circuits to current NEC 2023 code compliance.

### Work Includes:
- Remove existing aluminum branch circuits (all floors)
- Install new 12/2 and 14/2 copper Romex throughout
- Upgrade main panel to 200A Square D QO series
- Install 20 new AFCI/GFCI protected circuits
- Install whole-house surge protection (Eaton CHSPT2ULTRA)
- Install new receptacles and switches (Leviton Decora, white)
- Patch and paint all access points (drywall contractor to finish)
- City of Hartford electrical inspection coordination
- 1-year workmanship warranty

---

## Pricing Options

### Option A — Good
Standard rewire with basic fixtures and devices.

| Item | Qty | Unit Price | Total |
|------|:---:|----------:|------:|
| 200A Panel Upgrade (Square D QO) | 1 | $2,850.00 | $2,850.00 |
| Copper Romex 12/2 (250ft rolls) | 8 | $89.00 | $712.00 |
| Copper Romex 14/2 (250ft rolls) | 6 | $72.00 | $432.00 |
| AFCI/GFCI Breakers | 20 | $42.00 | $840.00 |
| Receptacles & Switches (Leviton) | 65 | $3.50 | $227.50 |
| Surge Protection (Eaton) | 1 | $185.00 | $185.00 |
| Miscellaneous Materials | 1 | $340.00 | $340.00 |
| **Labor** (3 electricians × 4 days) | 96 hrs | $85.00 | $8,160.00 |
| Permit & Inspection Fees | 1 | $275.00 | $275.00 |
| **Total** | | | **$14,021.50** |

### Option B — Better (Recommended)
Includes tamper-resistant receptacles, USB outlets in key locations, LED recessed lighting package.

| Item | Qty | Unit Price | Total |
|------|:---:|----------:|------:|
| Everything in Option A | — | — | $14,021.50 |
| Upgrade to TR Receptacles | 65 | $2.50 | $162.50 |
| USB-A/C Combo Outlets (kitchen, office, bedrooms) | 12 | $28.00 | $336.00 |
| LED Recessed Lighting (6") | 16 | $45.00 | $720.00 |
| Dimmer Switches (Lutron Caseta) | 6 | $65.00 | $390.00 |
| Additional Labor | 8 hrs | $85.00 | $680.00 |
| **Total** | | | **$16,310.00** |

### Option C — Best
Full smart home electrical package with EV charger prep and generator interlock.

| Item | Qty | Unit Price | Total |
|------|:---:|----------:|------:|
| Everything in Option B | — | — | $16,310.00 |
| EV Charger Circuit (50A, NEMA 14-50) | 1 | $850.00 | $850.00 |
| Generator Interlock Kit + Inlet | 1 | $475.00 | $475.00 |
| Smart Switches (Lutron Caseta Pro) | 24 | $72.00 | $1,728.00 |
| Smart Hub + Bridge | 1 | $120.00 | $120.00 |
| Outdoor Weatherproof Outlets (GFCI) | 4 | $35.00 | $140.00 |
| Additional Labor | 12 hrs | $85.00 | $1,020.00 |
| **Total** | | | **$20,643.00** |

---

## Terms & Conditions

- **Payment:** 40% deposit due upon acceptance. 30% at rough-in inspection. 30% upon final inspection and completion.
- **Timeline:** Estimated 4-5 business days once materials arrive (7-10 day lead time on panel).
- **Warranty:** 1-year workmanship warranty. All materials carry manufacturer warranty.
- **Permits:** All permit fees included. ZAFTO handles scheduling with City of Hartford.
- **Changes:** Any scope changes must be documented via change order before work proceeds.

---

## Acceptance

By signing below, you accept the terms of this bid and authorize ZAFTO to proceed with the selected option.

**Selected Option:** ☐ Good ($14,021.50)  ☐ Better ($16,310.00)  ☐ Best ($20,643.00)

**Customer Signature:** ___________________________  **Date:** ___________

**Contractor Signature:** ___________________________  **Date:** ___________`,
  data: {
    customer: { name: 'David Park', address: '1847 Elm Street, Hartford, CT 06103' },
    options: [
      { name: 'Good', total: 14021.50 },
      { name: 'Better', total: 16310.00, recommended: true },
      { name: 'Best', total: 20643.00 },
    ],
    validUntil: '2026-03-08',
    estimatedStart: '2026-02-17',
  },
  versions: [{
    version: 1,
    content: '',
    data: {},
    editDescription: 'Initial generation',
    createdAt: new Date().toISOString(),
  }],
  currentVersion: 1,
  status: 'ready',
  createdAt: new Date().toISOString(),
};

export const MOCK_INVOICE_ARTIFACT: ZArtifact = {
  id: 'mock-invoice-1',
  type: 'invoice',
  title: 'Invoice #INV-2026-0089 — EV Charger Installation',
  content: `# Invoice #INV-2026-0089

**Bill To:** James Torres
**Address:** 2341 Oak Avenue, Hartford, CT 06106
**Invoice Date:** February 6, 2026
**Due Date:** February 20, 2026
**Job:** EV Charger Installation — Level 2 (Tesla Wall Connector)

---

## Line Items

| Description | Qty | Rate | Amount |
|-------------|:---:|-----:|-------:|
| Tesla Wall Connector Gen 3 | 1 | $475.00 | $475.00 |
| 60A Dedicated Circuit (copper, 40ft run) | 1 | $680.00 | $680.00 |
| NEMA 14-50 Outlet + Weatherproof Box | 1 | $85.00 | $85.00 |
| Permit Fee (City of Hartford) | 1 | $125.00 | $125.00 |
| Labor (2 electricians × 4 hours) | 8 hrs | $85.00 | $680.00 |
| Load Calculation & Panel Assessment | 1 | $150.00 | $150.00 |

---

| | |
|---|---:|
| **Subtotal** | **$2,195.00** |
| **Tax (6.35% CT)** | **$139.38** |
| **Total** | **$2,334.38** |
| Deposit Paid (Feb 3) | -$934.00 |
| **Balance Due** | **$1,400.38** |

---

## Payment Methods

- **Online:** Pay securely via your ZAFTO client portal
- **ACH/Bank Transfer:** Routing 021000089, Account ending 4521
- **Check:** Made payable to "ZAFTO Electrical LLC"

**Net 14 terms.** Late payments subject to 1.5% monthly finance charge per CT General Statutes.

Thank you for your business.`,
  data: {
    customer: { name: 'James Torres', address: '2341 Oak Avenue, Hartford, CT 06106' },
    subtotal: 2195.00,
    tax: 139.38,
    total: 2334.38,
    deposit: 934.00,
    balanceDue: 1400.38,
    dueDate: '2026-02-20',
  },
  versions: [{
    version: 1,
    content: '',
    data: {},
    editDescription: 'Initial generation',
    createdAt: new Date().toISOString(),
  }],
  currentVersion: 1,
  status: 'ready',
  createdAt: new Date().toISOString(),
};

export const STORAGE_BROWSER_ARTIFACT: ZArtifact = {
  id: 'storage-browser',
  type: 'generic',
  title: 'File Manager',
  content: 'Browse and manage your files stored in ZAFTO.',
  data: {},
  versions: [{
    version: 1,
    content: '',
    data: {},
    editDescription: 'Storage browser',
    createdAt: new Date().toISOString(),
  }],
  currentVersion: 1,
  status: 'ready',
  createdAt: new Date().toISOString(),
};

export const MOCK_REPORT_ARTIFACT: ZArtifact = {
  id: 'mock-report-1',
  type: 'report',
  title: 'Revenue Report — February 2026',
  content: `# Revenue Report — February 2026

**Generated:** February 6, 2026
**Period:** February 1–6, 2026 (MTD)

---

## Summary

| Metric | This Month | Last Month | Change |
|--------|----------:|----------:|-------:|
| **Revenue** | $18,450 | $16,480 | +12.0% |
| **Jobs Completed** | 6 | 8 | -2 |
| **Avg Job Value** | $3,075 | $2,060 | +49.3% |
| **Outstanding** | $4,250 | $2,100 | +102.4% |
| **Avg Margin** | 34.2% | 31.8% | +2.4pts |

---

## Revenue by Job Type

| Job Type | Revenue | % of Total | Jobs |
|----------|--------:|-----------:|:----:|
| Residential Rewire | $8,200 | 44.4% | 1 |
| EV Charger Install | $4,700 | 25.5% | 2 |
| Panel Upgrade | $3,250 | 17.6% | 2 |
| Service Call | $2,300 | 12.5% | 1 |

---

## Outstanding Invoices

| Invoice | Customer | Amount | Days Overdue |
|---------|----------|-------:|:------------:|
| INV-2026-0082 | Maria Lopez | $2,750 | 8 days |
| INV-2026-0078 | Robert Kim | $1,500 | 14 days |
| **Total Outstanding** | | **$4,250** | |

---

## Team Performance

| Tech | Jobs | Revenue | Avg Rating |
|------|:----:|--------:|:----------:|
| Mike Rodriguez | 4 | $11,200 | 4.9 |
| You | 3 | $7,250 | 5.0 |

---

*Recommendation: Follow up on the Lopez and Kim invoices — they're past your 7-day standard. Want me to draft reminder emails?*`,
  data: {
    period: 'February 2026',
    revenue: 18450,
    jobsCompleted: 6,
    avgJobValue: 3075,
    outstanding: 4250,
    avgMargin: 34.2,
  },
  versions: [{
    version: 1,
    content: '',
    data: {},
    editDescription: 'Initial generation',
    createdAt: new Date().toISOString(),
  }],
  currentVersion: 1,
  status: 'ready',
  createdAt: new Date().toISOString(),
};
