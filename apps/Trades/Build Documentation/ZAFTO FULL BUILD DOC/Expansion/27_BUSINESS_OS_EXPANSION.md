# ZAFTO BUSINESS OS EXPANSION
## Complete Specifications for 9 New Core Systems
### February 5, 2026 — Session 29

---

> **⚠️ DATABASE MIGRATION NOTE (Session 29):**
> All "Firestore" collections → Supabase PostgreSQL tables. All "Cloud Functions" → Supabase Edge Functions.
> See `Locked/29_DATABASE_MIGRATION.md`. Firebase fully decommissioned.

---

## EXECUTIVE SUMMARY

These 9 systems transform ZAFTO from "CRM + Field Tools" into an **inescapable business operating system**. Each system is designed with:

1. **Integration First** — Every system feeds into and draws from existing systems
2. **Moats Everywhere** — Lock-in features that make switching painful
3. **AI Leverage** — Claude-powered intelligence across all systems
4. **Data Gravity** — The more you use, the more valuable it becomes

Once a contractor is using ZAFTO for payroll + fleet + procurement + phone + HR + marketing + accounting... they're not leaving. Ever. The switching cost is infinite.

---

## SYSTEM INTERDEPENDENCY MAP

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ZAFTO BUSINESS OPERATING SYSTEM                           │
│                                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │   PAYROLL   │◄──►│ TIME CLOCK  │◄──►│   HR SUITE  │◄──►│  TRAINING   │          │
│  │             │    │ + GPS Track │    │             │    │             │          │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └─────────────┘          │
│         │                  │                  │                                     │
│         ▼                  ▼                  ▼                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │ZAFTO BOOKS  │◄──►│    JOBS     │◄──►│   FLEET     │◄──►│    ROUTE    │          │
│  │ Accounting  │    │ + Materials │    │ Management  │    │ Optimizer   │          │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘          │
│         │                  │                  │                  │                  │
│         ▼                  ▼                  ▼                  ▼                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │ CPA PORTAL  │◄──►│ PROCUREMENT │◄──►│   VoIP      │◄──►│   EMAIL     │          │
│  │ Accountants │    │ + Vendors   │    │ Call Center │    │ Marketing   │          │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘          │
│                                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DOCUMENT TEMPLATE ENGINE                              │  │
│  │    Contracts • Proposals • Agreements • Lien Notices • Change Orders         │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                              AI LAYER (Claude)                                │  │
│  │    Every system feeds data → AI provides insights across ALL systems          │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

# SYSTEM 1: CPA/ACCOUNTANT PORTAL
## The Distribution Channel That Sells Itself

### THE MOAT

CPAs have 50-500 small business clients. If a CPA recommends ZAFTO to their contractor clients, that's 50-500 warm leads delivered on a silver platter. But they'll only do it if ZAFTO makes THEIR job easier. This portal does that.

**Why CPAs Will Push ZAFTO:**
- Books are already clean when they arrive (no shoebox of receipts)
- Real-time access to client financials (no waiting for quarterly exports)
- AI-categorized transactions (90% less manual work)
- Multi-client dashboard (one login, all their ZAFTO contractors)
- Tax prep data pre-formatted (1099s, payroll summaries, expense categories)

**The Lock-In:**
- CPA becomes the contractor's "accountant of record" in ZAFTO
- CPA can configure chart of accounts, approval workflows
- Historical financial data lives in ZAFTO (contractor won't leave and lose years of clean books)
- CPA's clients are sticky because the CPA is sticky

### PORTAL FEATURES

```
CPA PORTAL (cpa.zafto.cloud)
├── Multi-Client Dashboard
│   ├── All ZAFTO contractor clients in one view
│   ├── Financial health scores (cash flow, AR aging, profitability)
│   ├── Alerts: "Mike's Electric has 3 invoices 60+ days overdue"
│   ├── Alerts: "Sarah's Plumbing quarterly taxes due in 14 days"
│   └── Quick-switch between clients (no re-login)
│
├── Client Financial Access (Per Client)
│   ├── Full P&L, Balance Sheet, Cash Flow statements
│   ├── Transaction ledger with AI categorization
│   ├── Receipt/invoice image attachments
│   ├── Bank reconciliation status
│   ├── Payroll summaries and tax liabilities
│   └── Job profitability reports
│
├── Tax Prep Tools
│   ├── 1099 generation for subcontractors
│   ├── Quarterly estimated tax calculations
│   ├── Year-end tax package export
│   ├── Depreciation schedules (for equipment)
│   └── State-specific tax reports
│
├── Chart of Accounts Management
│   ├── Configure client's chart of accounts
│   ├── Set categorization rules (auto-categorize "Home Depot" → Materials)
│   ├── Define approval thresholds
│   └── Sync mappings to QuickBooks/Xero (if client uses both)
│
├── Client Onboarding
│   ├── Invite contractor clients to ZAFTO
│   ├── Pre-configure their books setup
│   ├── Import historical data from QuickBooks/Xero
│   └── Training resources for clients
│
└── CPA Firm Settings
    ├── Firm branding on client-facing reports
    ├── Staff accounts with permission levels
    ├── Billing integration (if CPA charges for ZAFTO access)
    └── Referral tracking and commission dashboard
```

### COLLECTIONS

```
cpaFirms/{firmId}/
  ├── name, address, phone, email
  ├── logoUrl, brandingConfig
  ├── stripeCustomerId (for CPA subscription)
  ├── primaryContact (userId)
  ├── staffIds []
  └── referralCode, referralStats

cpaFirms/{firmId}/clients/{clientId}/
  ├── companyId (link to contractor's company)
  ├── accessLevel: "full" | "readonly" | "tax_only"
  ├── chartOfAccountsConfig
  ├── categorizationRules []
  ├── assignedStaffId
  ├── onboardedAt
  └── lastAccessAt

cpaFirms/{firmId}/staff/{staffId}/
  ├── userId, name, email
  ├── role: "admin" | "accountant" | "bookkeeper" | "readonly"
  ├── assignedClientIds []
  └── permissions {}

cpaReferrals/{referralId}/
  ├── cpaFirmId, referralCode
  ├── referredCompanyId
  ├── status: "pending" | "active" | "paid"
  ├── commissionAmount, commissionPaidAt
  └── createdAt
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `cpaClientInvite` | HTTP | Send invite email to contractor |
| `cpaGenerateTaxPackage` | HTTP | Compile year-end tax documents |
| `cpaGenerate1099s` | HTTP | Generate 1099 forms for subs |
| `cpaReferralTrack` | Firestore trigger | Track referral → conversion |
| `cpaReferralPayout` | Scheduled | Monthly commission payouts |
| `cpaClientHealthCheck` | Scheduled | Generate health scores, alerts |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| ZAFTO Books | Full read access to transactions, P&L, balance sheet |
| Payroll | View payroll summaries, tax liabilities, 1099 data |
| Time Clock | View labor hours for payroll verification |
| Invoices | View AR aging, payment history |
| Receipts | View expense receipts with categorization |
| Jobs | View job profitability for client advisory |

---

# SYSTEM 2: PAYROLL
## Because Hours Without Pay = Half a System

### THE MOAT

Payroll is the stickiest SaaS category in existence. Once your payroll is running through a system, you're not switching mid-year. Tax filings, W-2 history, direct deposit setup, compliance records — it's all too risky to migrate.

**ZAFTO Payroll Advantages:**
- Time Clock data flows directly in (no duplicate entry)
- GPS-verified hours (auditable, defensible)
- Job costing automatic (labor cost per job calculated real-time)
- Overtime rules applied automatically
- Contractor vs employee handled correctly (1099 vs W-2)
- Integrates with ZAFTO Books (payroll expense auto-posted)

**The Lock-In:**
- All historical payroll data in one place
- Tax filings (941, 940, state) processed through ZAFTO
- W-2 and 1099 generation
- Moving payroll mid-year is an accounting nightmare

### PAYROLL FEATURES

```
PAYROLL MODULE (CRM → Team → Payroll)
├── Pay Runs
│   ├── Create pay run (select period, employees)
│   ├── Auto-import hours from Time Clock
│   ├── Review and adjust (add bonuses, deductions)
│   ├── Preview paychecks with all calculations
│   ├── Approve and process
│   ├── Direct deposit or check generation
│   └── Pay stub delivery (email/app/portal)
│
├── Employee Setup
│   ├── W-4 information collection
│   ├── Direct deposit setup (bank account, routing)
│   ├── Pay rate(s) — hourly, salary, per-job, commission
│   ├── Overtime rules (state-specific)
│   ├── Deductions (health insurance, 401k, garnishments)
│   ├── Benefits enrollment
│   └── Emergency contact
│
├── Tax Management
│   ├── Federal tax deposits (auto-calculate, remind)
│   ├── State tax deposits
│   ├── Quarterly 941 filing
│   ├── Annual 940, W-2, W-3 filing
│   ├── State unemployment (SUTA)
│   └── Workers' comp integration
│
├── Contractor Payments (1099)
│   ├── Subcontractor profiles
│   ├── W-9 collection and storage
│   ├── Payment tracking
│   ├── 1099-NEC generation
│   └── Send to CPA portal automatically
│
├── Reports
│   ├── Payroll journal (for ZAFTO Books)
│   ├── Tax liability summary
│   ├── Labor cost by job/customer/employee
│   ├── Overtime analysis
│   ├── Pay history by employee
│   └── YTD earnings statements
│
└── Compliance
    ├── I-9 verification
    ├── New hire reporting (state-specific)
    ├── Pay equity reports
    └── Audit trail for all changes
```

### COLLECTIONS

```
companies/{companyId}/employees/{empId}/
  ├── userId (link to user account)
  ├── type: "w2" | "1099"
  ├── status: "active" | "terminated" | "onleave"
  │
  ├── COMPENSATION
  │   ├── payType: "hourly" | "salary" | "per_job" | "commission"
  │   ├── payRate: double
  │   ├── overtimeRate: double (default 1.5)
  │   ├── payFrequency: "weekly" | "biweekly" | "semimonthly" | "monthly"
  │   └── effectiveDate
  │
  ├── TAX INFO
  │   ├── ssn (encrypted)
  │   ├── filingStatus
  │   ├── federalAllowances
  │   ├── additionalWithholding
  │   ├── stateWithholdings {}
  │   └── w4DocumentUrl
  │
  ├── BANKING
  │   ├── directDeposits [] (can split: 80% checking, 20% savings)
  │   │   └── { accountType, routingNumber (encrypted), accountNumber (encrypted), amount/percent }
  │   └── paymentMethod: "direct_deposit" | "check" | "cash"
  │
  ├── DEDUCTIONS
  │   ├── preTax [] (401k, health insurance, HSA, FSA)
  │   └── postTax [] (garnishments, Roth 401k, life insurance)
  │
  ├── EMERGENCY
  │   ├── emergencyContacts [] (name, phone, relationship)
  │
  └── DATES
      ├── hireDate
      ├── terminationDate
      └── lastPayDate

companies/{companyId}/payRuns/{runId}/
  ├── periodStart, periodEnd
  ├── payDate
  ├── status: "draft" | "pending_approval" | "approved" | "processing" | "completed" | "failed"
  ├── createdBy, approvedBy
  ├── totalGross, totalNet, totalTaxes, totalDeductions
  ├── directDepositBatchId
  ├── checkNumbers [] (if any checks)
  └── processingErrors []

companies/{companyId}/payRuns/{runId}/paychecks/{checkId}/
  ├── employeeId
  │
  ├── HOURS
  │   ├── regularHours, overtimeHours, doubleTimeHours
  │   ├── ptoHours, sickHours, holidayHours
  │   ├── timeEntryIds [] (link to time clock entries)
  │   └── manualAdjustments []
  │
  ├── EARNINGS
  │   ├── regularPay, overtimePay
  │   ├── bonuses [], commissions []
  │   ├── reimbursements []
  │   └── grossPay
  │
  ├── TAXES
  │   ├── federalIncomeTax
  │   ├── socialSecurity, medicare
  │   ├── stateIncomeTax
  │   ├── localTaxes {}
  │   └── totalTaxes
  │
  ├── DEDUCTIONS
  │   ├── preTaxDeductions []
  │   ├── postTaxDeductions []
  │   └── totalDeductions
  │
  ├── NET
  │   ├── netPay
  │   ├── paymentMethod
  │   └── directDepositStatus / checkNumber
  │
  └── ALLOCATIONS (job costing)
      └── jobAllocations [] { jobId, hours, laborCost }

companies/{companyId}/taxDeposits/{depositId}/
  ├── type: "federal_941" | "state" | "suta" | "futa"
  ├── period
  ├── amount
  ├── dueDate
  ├── paidDate
  ├── confirmationNumber
  └── status: "pending" | "paid" | "late"

companies/{companyId}/subcontractors/{subId}/
  ├── name, businessName
  ├── ein, ssn (encrypted) — one or other based on entity type
  ├── w9DocumentUrl, w9CollectedAt
  ├── address, phone, email
  ├── defaultRate
  ├── ytdPayments (for 1099 threshold)
  ├── insuranceVerified, insuranceExpiry
  └── status: "active" | "inactive"

companies/{companyId}/subcontractorPayments/{paymentId}/
  ├── subcontractorId
  ├── amount, date
  ├── invoiceNumber
  ├── jobId (if applicable)
  ├── paymentMethod
  └── included1099Year
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `calculatePaycheck` | HTTP | Run payroll calculations with tax lookups |
| `processDirectDeposit` | HTTP | Submit ACH batch to banking partner |
| `generatePayStub` | HTTP | Create PDF pay stub |
| `taxDepositReminder` | Scheduled | Alert when deposits are due |
| `generate941` | HTTP | Create quarterly 941 form |
| `generateW2s` | HTTP | Year-end W-2 generation |
| `generate1099s` | HTTP | 1099-NEC for subcontractors |
| `newHireReporting` | Firestore trigger | Submit to state new hire registry |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Time Clock | Pull hours automatically for pay period |
| Jobs | Allocate labor cost to specific jobs |
| ZAFTO Books | Post payroll journal entries automatically |
| CPA Portal | Expose payroll summaries, tax liabilities |
| HR Suite | Employee records, PTO balances |
| Fleet | Mileage reimbursement calculations |

---

# SYSTEM 3: FLEET MANAGEMENT
## Track Every Truck, Every Mile, Every Dollar

### THE MOAT

Every contractor has trucks. None of them know the true cost of operating them. ZAFTO Fleet shows:
- True cost per mile (fuel + maintenance + insurance + depreciation)
- Which trucks are money pits
- When maintenance is due (before breakdowns)
- Where every vehicle is right now

**Data Gravity:** The longer you track, the more accurate the predictive maintenance. 2 years of history = AI knows your vehicles better than you do.

**The Lock-In:**
- Complete vehicle history lives in ZAFTO
- Maintenance schedules, recall tracking
- Insurance/registration expiration alerts
- Can't take this data to another system easily

### FLEET FEATURES

```
FLEET MANAGEMENT (CRM → Resources → Fleet)
├── Vehicle Dashboard
│   ├── All vehicles in one view (card + map)
│   ├── Status badges: Active, In Shop, Out of Service
│   ├── Live GPS location (during business hours)
│   ├── Current driver assignment
│   └── Health indicators (maintenance due, recalls)
│
├── Vehicle Profile (Per Vehicle)
│   ├── Make, model, year, VIN, license plate
│   ├── Photo gallery
│   ├── Purchase info (date, price, financing)
│   ├── Current mileage (auto-updated from GPS or manual)
│   ├── Assigned driver (default tech who uses it)
│   │
│   ├── MAINTENANCE TAB
│   │   ├── Maintenance schedule (oil change every 5k, brakes every 30k, etc.)
│   │   ├── Upcoming maintenance alerts
│   │   ├── Complete service history (every oil change, repair, tire rotation)
│   │   ├── Receipts attached to each service record
│   │   ├── Recall status (pulled from NHTSA database)
│   │   └── Warranty status
│   │
│   ├── EXPENSES TAB
│   │   ├── Fuel purchases (linked from receipts or fuel card import)
│   │   ├── Maintenance costs
│   │   ├── Insurance premiums (pro-rated)
│   │   ├── Registration/inspection costs
│   │   ├── Depreciation (calculated)
│   │   └── TRUE COST PER MILE (all-in)
│   │
│   ├── GPS HISTORY TAB
│   │   ├── Trip log (start, end, miles, duration, driver)
│   │   ├── Route playback on map
│   │   ├── Idle time reports
│   │   ├── Speed alerts
│   │   └── Geofence events
│   │
│   └── DOCUMENTS TAB
│       ├── Registration
│       ├── Insurance card
│       ├── Inspection certificates
│       └── Title
│
├── Live Map
│   ├── All vehicles on map with real-time location
│   ├── Filter by status, driver, vehicle type
│   ├── Click vehicle → see driver, current job, ETA
│   ├── Geofences (job sites, HQ, no-go zones)
│   └── Traffic layer
│
├── Fuel Management
│   ├── Fuel card integration (WEX, Fuelman, FleetCor)
│   ├── Manual fuel log entry
│   ├── MPG tracking and alerts (sudden drop = problem)
│   ├── Fuel cost allocation to jobs
│   └── Fuel budget vs actual
│
├── Reports
│   ├── Cost per mile by vehicle
│   ├── Maintenance spending by vehicle/period
│   ├── Fuel efficiency trends
│   ├── Driver behavior (speeding, idling, hard braking)
│   ├── Vehicle utilization (hours in use vs sitting)
│   └── Fleet TCO (total cost of ownership)
│
└── Alerts
    ├── Maintenance due in X days/miles
    ├── Registration expiring
    ├── Insurance expiring
    ├── Recall issued
    ├── Speeding/idling/geofence breach
    └── MPG dropped significantly
```

### COLLECTIONS

```
companies/{companyId}/vehicles/{vehicleId}/
  ├── vin, make, model, year, color
  ├── licensePlate, state
  ├── type: "truck" | "van" | "trailer" | "equipment"
  ├── status: "active" | "in_shop" | "out_of_service" | "sold"
  │
  ├── OWNERSHIP
  │   ├── purchaseDate, purchasePrice
  │   ├── financingType: "owned" | "leased" | "financed"
  │   ├── monthlyPayment
  │   ├── payoffDate
  │   └── currentValue (for depreciation)
  │
  ├── ASSIGNMENTS
  │   ├── defaultDriverId (userId)
  │   ├── currentDriverId
  │   └── lastKnownLocation { lat, lng, timestamp }
  │
  ├── METRICS
  │   ├── currentOdometer
  │   ├── lastOdometerUpdate
  │   ├── totalMilesDriven (since added to ZAFTO)
  │   └── avgMpg
  │
  ├── DOCUMENTS
  │   ├── registrationUrl, registrationExpiry
  │   ├── insuranceUrl, insuranceExpiry
  │   ├── inspectionUrl, inspectionExpiry
  │   └── titleUrl
  │
  └── REMINDERS
      ├── nextOilChange (mileage or date)
      ├── nextInspection
      ├── nextRegistrationRenewal
      └── customReminders []

companies/{companyId}/vehicles/{vehicleId}/maintenanceRecords/{recordId}/
  ├── date, mileage
  ├── type: "oil_change" | "tires" | "brakes" | "repair" | "inspection" | "other"
  ├── description
  ├── vendor, cost
  ├── receiptUrl
  ├── performedBy: "self" | "shop"
  ├── parts [] { name, partNumber, cost }
  ├── laborHours, laborCost
  └── warrantyWork: bool

companies/{companyId}/vehicles/{vehicleId}/fuelLogs/{logId}/
  ├── date, time
  ├── gallons, pricePerGallon, totalCost
  ├── odometer
  ├── fuelType
  ├── stationName, stationAddress
  ├── paymentMethod: "fuel_card" | "credit_card" | "cash" | "reimbursement"
  ├── fuelCardTransactionId
  ├── receiptUrl
  └── mpgSinceLastFill (calculated)

companies/{companyId}/vehicles/{vehicleId}/trips/{tripId}/
  ├── driverId
  ├── startTime, endTime
  ├── startLocation { lat, lng, address }
  ├── endLocation { lat, lng, address }
  ├── distanceMiles
  ├── durationMinutes
  ├── maxSpeed, avgSpeed
  ├── idleMinutes
  ├── hardBrakingEvents, hardAccelerationEvents
  ├── jobId (if trip was for a job)
  └── purpose: "job" | "supply_run" | "commute" | "personal"

companies/{companyId}/vehicles/{vehicleId}/gpsHistory/{pingId}/
  ├── timestamp
  ├── lat, lng, accuracy
  ├── speed, heading
  ├── engineOn: bool
  ├── driverId
  └── eventType: "ping" | "ignition_on" | "ignition_off" | "geofence_enter" | "geofence_exit"

companies/{companyId}/geofences/{fenceId}/
  ├── name
  ├── type: "circle" | "polygon"
  ├── center { lat, lng } (for circle)
  ├── radiusMeters (for circle)
  ├── coordinates [] (for polygon)
  ├── alertOnEnter, alertOnExit
  ├── linkedJobId (optional — job site geofence)
  └── activeHours { start, end }

companies/{companyId}/vehicleRecalls/{recallId}/
  ├── vehicleId
  ├── nhtsaCampaignNumber
  ├── component, summary, consequence
  ├── remedy
  ├── status: "open" | "scheduled" | "completed"
  ├── notifiedAt
  └── completedAt
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `syncFuelCards` | Scheduled | Import transactions from WEX/Fuelman |
| `checkVehicleRecalls` | Scheduled | Query NHTSA for recalls by VIN |
| `maintenanceReminder` | Scheduled | Check mileage/date, send alerts |
| `documentExpiryAlert` | Scheduled | Warn about expiring registration/insurance |
| `calculateVehicleTCO` | HTTP | Total cost of ownership calculation |
| `geofenceEvent` | HTTP | Process geofence enter/exit |
| `tripAnalysis` | Firestore trigger | Calculate MPG, driver score after trip |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Time Clock GPS | When tech clocks in, vehicle location = their location |
| Jobs | Link trips to jobs, calculate transport costs per job |
| Procurement | Fuel and maintenance receipts flow in |
| Route Optimizer | Current vehicle locations feed routing decisions |
| ZAFTO Books | Vehicle expenses post to ledger |
| Payroll | Mileage reimbursements for personal vehicle use |
| CPA Portal | Fleet expenses, depreciation for tax prep |

---


# SYSTEM 4: ROUTE OPTIMIZATION / SMART DISPATCH
## The AI That Plans Better Than Any Dispatcher

### THE MOAT

Every service company has the same problem: 5 techs, 20 jobs, 100 ways to route them. Most guess. The good ones use experience. ZAFTO uses AI + real-time data to make routing decisions no human could make.

**ZAFTO Route Advantages:**
- Considers everything: tech skills, job type, traffic, parts on truck, customer preference
- Real-time re-routing when jobs run long or emergencies come in
- Learns from history: "Tech A is 20% faster at panel upgrades"
- Customer ETA updates automatically ("Your tech is 15 minutes away")
- Integrates with Live Job Tracker in Client Portal

**The Lock-In:**
- The longer you use it, the smarter it gets
- Routing intelligence is based on YOUR job history, YOUR techs, YOUR territory
- Switching means starting from zero

### ROUTE FEATURES

```
SMART DISPATCH (CRM → Operations → Dispatch)
├── Dispatch Board (Main View)
│   ├── Timeline view: horizontal timeline per tech
│   ├── Map view: all jobs and techs on map
│   ├── List view: all jobs sorted by priority/time
│   │
│   ├── UNASSIGNED JOBS
│   │   ├── Jobs that need scheduling
│   │   ├── Drag-drop onto tech timeline
│   │   ├── Or: "Auto-assign" button (AI assigns)
│   │   └── Priority badges (emergency, VIP, overdue)
│   │
│   ├── TECH CARDS
│   │   ├── Tech name, photo, current status
│   │   ├── Current location (GPS from app or fleet)
│   │   ├── Today's schedule (list of jobs)
│   │   ├── Available capacity (hours remaining)
│   │   └── Skills/certifications (for matching)
│   │
│   └── REAL-TIME UPDATES
│       ├── Job status changes update board instantly
│       ├── Running late? Board shows red warning
│       ├── Job completed early? Show green with extra capacity
│       └── New emergency job? AI suggests re-route
│
├── AI Route Optimizer
│   ├── One-click "Optimize Today's Routes"
│   ├── Considers:
│   │   ├── Tech location (current or home address)
│   │   ├── Job locations and durations
│   │   ├── Traffic patterns (Google Maps API)
│   │   ├── Tech skills vs job requirements
│   │   ├── Parts on truck vs job needs
│   │   ├── Customer time windows ("only mornings")
│   │   ├── Job priority/SLA requirements
│   │   └── Historical data (how long this job type ACTUALLY takes)
│   ├── Shows before/after comparison
│   │   └── "Optimized route saves 47 minutes and 23 miles"
│   └── Apply or tweak manually
│
├── Real-Time Re-Routing
│   ├── Job running 30 min over → AI recalculates remaining jobs
│   ├── Emergency comes in → AI finds best tech to divert
│   ├── Tech calls in sick → AI reassigns their jobs
│   ├── All affected customers get updated ETAs automatically
│   └── Dispatcher sees recommended changes, approves with one click
│
├── Customer ETA Updates
│   ├── "On my way" button in tech app → customer gets SMS + portal update
│   ├── ETA recalculates based on traffic
│   ├── Auto-notify if ETA slips by more than 15 min
│   └── Feeds Live Job Tracker in Client Portal
│
├── Territory Management
│   ├── Define service areas (zip codes or draw on map)
│   ├── Assign techs to territories
│   ├── Auto-route prefers keeping techs in their territory
│   ├── Cross-territory alerts if no option
│   └── Territory performance analytics
│
└── Reports
    ├── Drive time vs job time ratio
    ├── Miles driven per job (trending)
    ├── On-time arrival rate
    ├── Route efficiency score (actual vs optimal)
    ├── Tech utilization (productive hours / available hours)
    └── Customer wait time (job request to completion)
```

### COLLECTIONS

```
companies/{companyId}/dispatchSchedules/{scheduleId}/
  ├── date
  ├── status: "draft" | "published" | "in_progress" | "completed"
  ├── createdBy, publishedAt
  ├── optimizationRuns [] { timestamp, algorithm, savings }
  └── notes

companies/{companyId}/dispatchSchedules/{scheduleId}/assignments/{assignmentId}/
  ├── techUserId
  ├── jobId
  ├── scheduledStart, scheduledEnd
  ├── scheduledOrder (sequence for the day)
  ├── status: "scheduled" | "en_route" | "in_progress" | "completed" | "cancelled"
  ├── actualStart, actualEnd
  ├── travelTimeMinutes (estimated), actualTravelTime
  ├── etaNotificationSent: bool
  └── customerNotified: bool

companies/{companyId}/territories/{territoryId}/
  ├── name
  ├── type: "zip_codes" | "polygon"
  ├── zipCodes [] (if type=zip_codes)
  ├── coordinates [] (if type=polygon)
  ├── assignedTechIds []
  ├── color (for map display)
  └── priority (for overlapping territories)

companies/{companyId}/routeHistory/{historyId}/
  ├── date, techUserId
  ├── plannedJobs [], actualJobs []
  ├── plannedMiles, actualMiles
  ├── plannedDriveMinutes, actualDriveMinutes
  ├── plannedJobMinutes, actualJobMinutes
  ├── efficiencyScore (0-100)
  └── deviationReasons []

companies/{companyId}/techMetrics/{techUserId}/
  ├── avgJobDurationByType {} (job_type → minutes)
  ├── onTimeArrivalRate
  ├── avgDriveTimePerJob
  ├── territoryPerformance {} (territory → score)
  ├── skills [], certifications []
  ├── preferredJobTypes []
  └── lastUpdated
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `optimizeRoutes` | HTTP | Run AI route optimization |
| `rerouteOnDelay` | Firestore trigger | When job runs over, recalculate |
| `sendETAUpdate` | Firestore trigger | Notify customer of ETA changes |
| `calculateTechMetrics` | Scheduled (nightly) | Update tech performance stats |
| `dispatchEmergency` | HTTP | Find and assign best tech for emergency |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Jobs | Jobs feed dispatch board, status updates flow back |
| Time Clock | Clock-in triggers tech "available", clock-out ends availability |
| Fleet GPS | Vehicle location = tech location for routing |
| Client Portal | Live Job Tracker shows ETA, tech name, status |
| SMS (Twilio) | ETA notifications to customers |
| Calendar | Blocked time (meetings, appointments) affects availability |

---

# SYSTEM 5: PROCUREMENT / VENDOR MANAGEMENT
## Know What You're Spending Before It Kills Your Margins

### THE MOAT

Most contractors have no idea what they spent on materials until tax time. ZAFTO Procurement gives real-time visibility into every dollar leaving the company.

**ZAFTO Procurement Advantages:**
- Vendor price comparison (same SKU, who has it cheaper?)
- Purchase order workflow (request → approve → order → receive)
- Inventory tracking (what's on the truck, what's in the warehouse)
- Job-linked purchasing (materials tie back to specific jobs)
- AI cost predictions ("This job type typically uses $X in materials")

**The Lock-In:**
- Vendor relationships and pricing history
- Multi-year spending analytics
- Inventory data (can't leave and rebuild that)
- Approved vendor list with negotiated terms

### PROCUREMENT FEATURES

```
PROCUREMENT (CRM → Operations → Procurement)
├── Purchase Orders
│   ├── Create PO (select vendor, add line items)
│   ├── Link to job (materials for specific project)
│   ├── Approval workflow (if amount > threshold)
│   ├── Send to vendor (email/fax/portal integration)
│   ├── Track status: Sent → Confirmed → Shipped → Received
│   ├── Receive inventory (partial receipts allowed)
│   └── Three-way match (PO vs Invoice vs Receipt)
│
├── Vendor Management
│   ├── Vendor profiles (contact, terms, payment info)
│   ├── Approved vendor list (required for POs)
│   ├── Vendor scorecard (on-time delivery, quality, pricing)
│   ├── Price catalogs per vendor
│   ├── Document storage (W-9, contracts, certificates)
│   └── Insurance certificate tracking (with expiry alerts)
│
├── Price Comparison
│   ├── Search for part/material
│   ├── See prices across all vendors
│   ├── Historical pricing trends
│   ├── "Last purchased from X at $Y"
│   ├── AI recommendations ("Vendor B is 12% cheaper for this item")
│   └── One-click create PO from comparison
│
├── Inventory Management
│   ├── WAREHOUSE INVENTORY
│   │   ├── Item catalog (SKU, description, reorder point)
│   │   ├── Current quantities
│   │   ├── Location tracking (Shelf A, Bin 3)
│   │   ├── Reorder alerts
│   │   └── Physical count workflow
│   │
│   ├── TRUCK INVENTORY (Per Vehicle)
│   │   ├── Standard load list (what should be on truck)
│   │   ├── Current load (what IS on truck)
│   │   ├── Consumption tracking (when used on job)
│   │   ├── Restock requests
│   │   └── Transfer between trucks
│   │
│   └── MATERIAL USAGE (Per Job)
│       ├── Materials used on this job
│       ├── Link to PO or truck inventory
│       ├── Cost tracking
│       └── Return handling
│
├── Receipts & Invoices
│   ├── Upload vendor invoices
│   ├── AI extraction (vendor, amount, line items, date)
│   ├── Match to PO
│   ├── Approval workflow
│   ├── Send to ZAFTO Books for payment
│   └── Dispute tracking
│
├── Reports
│   ├── Spending by vendor (MTD, YTD, trends)
│   ├── Spending by category (electrical, plumbing, etc.)
│   ├── Spending by job (job profitability input)
│   ├── Inventory valuation
│   ├── Stock turnover rate
│   ├── Outstanding POs
│   └── Price variance analysis
│
└── Supply Chain Insights (AI)
    ├── "You spend $X/month on wire. Bulk order could save 15%"
    ├── "This vendor's prices increased 8% this year. Consider alternatives."
    ├── "You're low on [X]. Previous orders took 3 days to arrive."
    └── "Job type Y typically uses materials worth $Z. Quote accordingly."
```

### COLLECTIONS

```
companies/{companyId}/vendors/{vendorId}/
  ├── name, dba
  ├── type: "supplier" | "distributor" | "manufacturer"
  ├── contactPerson, phone, email
  ├── address
  ├── accountNumber (our account with them)
  ├── paymentTerms: "net30" | "net60" | "due_on_receipt" | "cod"
  ├── taxExempt: bool
  ├── preferredPaymentMethod
  │
  ├── DOCUMENTS
  │   ├── w9Url, w9CollectedAt
  │   ├── insuranceCertUrl, insuranceExpiry
  │   ├── contractUrl
  │   └── creditApplicationUrl
  │
  ├── SCORECARD
  │   ├── onTimeDeliveryRate
  │   ├── qualityScore
  │   ├── priceCompetitiveness
  │   ├── totalSpendYTD, totalSpendAllTime
  │   └── lastOrderDate
  │
  └── STATUS
      ├── status: "approved" | "pending" | "suspended" | "inactive"
      ├── approvedBy, approvedAt
      └── notes

companies/{companyId}/purchaseOrders/{poId}/
  ├── poNumber
  ├── vendorId
  ├── status: "draft" | "pending_approval" | "approved" | "sent" | "confirmed" | "partial" | "received" | "cancelled"
  ├── jobId (optional — if for specific job)
  │
  ├── DETAILS
  │   ├── orderDate
  │   ├── expectedDeliveryDate
  │   ├── deliveryAddress (job site or warehouse)
  │   ├── shippingMethod
  │   └── specialInstructions
  │
  ├── FINANCIALS
  │   ├── subtotal, tax, shipping, total
  │   ├── linkedVendorInvoiceId
  │   ├── paymentStatus
  │   └── variance (PO vs actual invoice)
  │
  ├── APPROVAL
  │   ├── requestedBy
  │   ├── approvalRequired: bool
  │   ├── approvedBy, approvedAt
  │   └── rejectedReason
  │
  └── TIMESTAMPS
      ├── createdAt, sentAt, receivedAt

companies/{companyId}/purchaseOrders/{poId}/lineItems/{lineId}/
  ├── inventoryItemId (if from catalog)
  ├── description
  ├── sku, manufacturerPartNumber
  ├── quantity, unitPrice, totalPrice
  ├── quantityReceived
  └── receivedAt

companies/{companyId}/inventory/{itemId}/
  ├── sku, description
  ├── category: "wire" | "conduit" | "breakers" | "tools" | "safety" | "other"
  ├── manufacturer, manufacturerPartNumber
  ├── unitOfMeasure
  ├── standardCost (average purchase price)
  ├── reorderPoint
  ├── reorderQuantity
  ├── preferredVendorId
  │
  ├── TRACKING
  │   ├── totalQuantityOnHand
  │   ├── lastCountDate
  │   └── lastPurchaseDate

companies/{companyId}/inventoryLocations/{locationId}/
  ├── name (Warehouse A, Truck 101, etc.)
  ├── type: "warehouse" | "truck" | "job_site"
  ├── vehicleId (if truck)
  ├── address (if warehouse)
  └── managerId

companies/{companyId}/inventoryStock/{stockId}/
  ├── inventoryItemId
  ├── locationId
  ├── quantity
  ├── binLocation (optional, for warehouse)
  └── lastUpdated

companies/{companyId}/inventoryTransactions/{txId}/
  ├── type: "receive" | "consume" | "transfer" | "adjust" | "return"
  ├── inventoryItemId
  ├── quantity (positive or negative)
  ├── fromLocationId, toLocationId (for transfers)
  ├── poId (for receives)
  ├── jobId (for consumption)
  ├── notes
  ├── performedBy
  └── timestamp
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `vendorInsuranceAlert` | Scheduled | Check for expiring vendor insurance |
| `inventoryReorderAlert` | Firestore trigger | Alert when stock hits reorder point |
| `purchaseOrderToVendor` | HTTP | Email/fax PO to vendor |
| `vendorInvoiceOCR` | HTTP | Extract data from uploaded invoices |
| `priceComparisonEngine` | HTTP | Query prices across vendors |
| `materialUsagePrediction` | HTTP | AI estimate materials for job type |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Jobs | Link POs and material usage to jobs for costing |
| Fleet | Truck inventory tied to vehicle records |
| ZAFTO Books | Vendor invoices → AP → payment tracking |
| Receipts | Field receipt capture → PO matching |
| CPA Portal | Purchasing analytics for advisors |
| Price Book | Material costs inform service pricing |

---

# SYSTEM 6: EMAIL MARKETING / CAMPAIGNS
## Stay Top of Mind Without Lifting a Finger

### THE MOAT

Email is the highest-ROI marketing channel. Most contractors don't do it because it's "too complicated." ZAFTO makes it dead simple: pre-built campaigns, AI-written content, and automation triggers.

**ZAFTO Email Advantages:**
- Pre-built campaigns for trades (seasonal reminders, maintenance alerts)
- AI writes the emails (just approve and send)
- Automation triggers (job completed → send review request → send referral ask)
- Segmentation built on REAL data (customers, job types, equipment age)
- Performance analytics (opens, clicks, conversions)

**The Lock-In:**
- Contact lists and segments live in ZAFTO
- Campaign performance history
- Automation sequences (years of refinement)
- Integration with job/customer data

### EMAIL FEATURES

```
EMAIL MARKETING (CRM → Marketing → Campaigns)
├── Campaign Builder
│   ├── Campaign types:
│   │   ├── One-time blast (announcement, promotion)
│   │   ├── Drip sequence (multi-email over time)
│   │   ├── Trigger-based (event-driven automation)
│   │   └── Recurring (monthly newsletter)
│   │
│   ├── Email Editor
│   │   ├── Drag-drop template builder
│   │   ├── Pre-built templates by trade
│   │   ├── Merge fields (Hi {{first_name}}, your {{equipment_type}}...)
│   │   ├── AI content generator ("Write a summer AC tune-up email")
│   │   ├── Image library
│   │   └── Mobile preview
│   │
│   ├── Audience Selection
│   │   ├── All contacts
│   │   ├── Custom segments (build from filters)
│   │   ├── Smart segments:
│   │   │   ├── "Haven't had service in 12+ months"
│   │   │   ├── "Water heater > 8 years old"
│   │   │   ├── "Commercial customers"
│   │   │   ├── "VIP customers (lifetime revenue > $10k)"
│   │   │   └── "Past due invoices"
│   │   └── Exclusions (unsubscribed, bounced, recent contact)
│   │
│   ├── Scheduling
│   │   ├── Send now
│   │   ├── Schedule for specific date/time
│   │   ├── Smart send (AI picks best time per recipient)
│   │   └── Send in batches (for large lists)
│   │
│   └── A/B Testing
│       ├── Test subject lines
│       ├── Test send times
│       ├── Test content variations
│       └── Auto-select winner after X% sent
│
├── Automation Studio
│   ├── TRIGGER TYPES
│   │   ├── Job completed
│   │   ├── Estimate sent (follow up if no response)
│   │   ├── Invoice paid (thank you + referral ask)
│   │   ├── Customer created
│   │   ├── Equipment age threshold
│   │   ├── Time since last service
│   │   ├── Birthday/anniversary
│   │   └── Custom date field
│   │
│   ├── ACTION TYPES
│   │   ├── Send email
│   │   ├── Wait X days
│   │   ├── Branch (if opened → path A, if not → path B)
│   │   ├── Update contact field
│   │   ├── Add tag
│   │   ├── Create task
│   │   ├── Send SMS (via Twilio)
│   │   └── Stop sequence
│   │
│   └── PRE-BUILT AUTOMATIONS (One-Click Enable)
│       ├── Post-job review request sequence
│       ├── Estimate follow-up (3-7-14 day)
│       ├── Annual maintenance reminder
│       ├── Seasonal tune-up campaigns
│       ├── Welcome sequence for new customers
│       ├── Re-engagement (dormant customers)
│       └── Equipment end-of-life notification
│
├── Templates Library
│   ├── By Industry (Electrical, Plumbing, HVAC, etc.)
│   ├── By Purpose (Promotional, Informational, Transactional)
│   ├── Seasonal (Spring AC prep, Winter heating, etc.)
│   ├── Custom templates (save your own)
│   └── AI template generator ("Create a holiday promotion email")
│
├── Analytics
│   ├── Campaign performance (sent, delivered, opens, clicks)
│   ├── Conversion tracking (email → appointment → job)
│   ├── List health (growth, bounces, unsubscribes)
│   ├── Best performing subject lines
│   ├── Best performing send times
│   ├── Revenue attributed to email
│   └── Comparison by campaign/segment
│
└── Compliance
    ├── CAN-SPAM compliance built-in
    ├── Unsubscribe handling
    ├── Bounce management
    ├── Preference center (customers choose frequency)
    └── Suppression list management
```

### COLLECTIONS

```
companies/{companyId}/emailCampaigns/{campaignId}/
  ├── name
  ├── type: "blast" | "drip" | "triggered" | "recurring"
  ├── status: "draft" | "scheduled" | "sending" | "sent" | "paused"
  │
  ├── CONTENT
  │   ├── subject (supports A/B variants)
  │   ├── preheaderText
  │   ├── htmlContent
  │   ├── plainTextContent
  │   └── templateId (if from template)
  │
  ├── AUDIENCE
  │   ├── segmentIds []
  │   ├── excludeSegmentIds []
  │   ├── estimatedRecipients
  │   └── actualRecipients
  │
  ├── SCHEDULE
  │   ├── scheduledAt
  │   ├── sentAt
  │   ├── completedAt
  │   └── timezone
  │
  └── STATS
      ├── sent, delivered, bounced
      ├── opens, uniqueOpens, openRate
      ├── clicks, uniqueClicks, clickRate
      ├── unsubscribes
      ├── complaints (spam reports)
      └── revenue (attributed)

companies/{companyId}/emailAutomations/{automationId}/
  ├── name
  ├── trigger: { type, conditions }
  ├── status: "active" | "paused" | "draft"
  ├── steps [] (sequence of actions)
  │   └── { order, type, config, waitDays }
  ├── enrolledCount
  ├── completedCount
  └── stats {}

companies/{companyId}/emailContacts/{contactId}/
  ├── email
  ├── customerId (link to CRM customer)
  ├── firstName, lastName
  ├── status: "subscribed" | "unsubscribed" | "bounced" | "complained"
  ├── tags []
  ├── segmentIds []
  ├── emailStats { sent, opens, clicks, lastOpenAt }
  ├── automationEnrollments [] { automationId, step, enrolledAt }
  └── preferences { frequency, categories }

companies/{companyId}/emailSegments/{segmentId}/
  ├── name
  ├── type: "static" | "dynamic"
  ├── filters {} (for dynamic: rules that define membership)
  ├── memberCount
  └── lastCalculatedAt

companies/{companyId}/emailTemplates/{templateId}/
  ├── name
  ├── category
  ├── industry
  ├── htmlContent
  ├── thumbnail
  └── isDefault
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `sendEmail` | HTTP | Send via SendGrid/Mailgun |
| `processEmailWebhook` | HTTP | Handle open/click/bounce events |
| `automationEnroll` | Firestore trigger | Enroll contacts in automations |
| `automationStep` | Scheduled | Process automation steps |
| `segmentCalculate` | Scheduled | Recalculate dynamic segment members |
| `aiEmailWriter` | HTTP | Claude generates email content |
| `emailRevenueAttribution` | Firestore trigger | Link jobs to email campaigns |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Customers | Customer data → contact list, merge fields |
| Jobs | Job completion triggers, revenue attribution |
| Equipment | Equipment age drives maintenance campaigns |
| Invoices | Invoice payment triggers thank-you sequences |
| SMS (Twilio) | Multi-channel sequences (email + SMS) |
| Home Portal | Homeowner equipment data for targeting |

---


# SYSTEM 7: VoIP / CALL CENTER
## Phone Is Still King — Own It

### THE MOAT

For all the talk about digital, trades customers still call. A lot. And most contractors have zero visibility into those calls. ZAFTO VoIP changes that.

**ZAFTO VoIP Advantages:**
- Every call logged automatically (who called, when, how long)
- Call recording (with consent) for training and disputes
- Click-to-call from anywhere in CRM
- Voicemail transcription (AI reads your voicemails)
- Call routing (after-hours to on-call tech, emergency to owner)
- Missed call alerts with callback reminders
- Call analytics (who's calling, when, conversion rates)

**The Lock-In:**
- Business phone number lives in ZAFTO
- Call history and recordings (can't take those)
- Customer caller ID matching (knows who's calling before you answer)
- IVR menus and routing rules

### VoIP FEATURES

```
VoIP CALL CENTER (CRM → Communications → Phone)
├── Phone Dashboard
│   ├── Live call activity (who's on a call right now)
│   ├── Today's call stats (inbound, outbound, missed, avg duration)
│   ├── Callback queue (missed calls needing follow-up)
│   ├── Voicemail inbox (with transcriptions)
│   └── Recent calls list
│
├── Company Phone Numbers
│   ├── Main business line
│   ├── Dedicated lines (sales, service, emergency)
│   ├── Local numbers for different territories
│   ├── Toll-free option
│   ├── Port existing numbers in
│   └── Number assignment to users/teams
│
├── Call Handling
│   ├── INBOUND
│   │   ├── Caller ID lookup (match to customer record)
│   │   ├── Screen pop (customer info appears when ringing)
│   │   ├── Call routing rules:
│   │   │   ├── Time-based (business hours → office, after-hours → on-call)
│   │   │   ├── Caller-based (VIP customers → direct to owner)
│   │   │   ├── Round-robin (distribute evenly across team)
│   │   │   └── Skills-based (route to right department)
│   │   ├── IVR menu builder ("Press 1 for service, 2 for billing...")
│   │   ├── Hold music/message
│   │   └── Voicemail with transcription
│   │
│   ├── OUTBOUND
│   │   ├── Click-to-call from any phone field in CRM
│   │   ├── Power dialer (for follow-up campaigns)
│   │   ├── Caller ID selection (show main number or direct line)
│   │   └── Call scheduling ("Call back at 3pm")
│   │
│   └── DURING CALL
│       ├── Quick actions (create job, schedule appointment, send estimate)
│       ├── Transfer to another user
│       ├── Conference in third party
│       ├── Call recording controls
│       └── Notes field (auto-saved to customer record)
│
├── Voicemail
│   ├── Visual voicemail inbox
│   ├── AI transcription (text version of each voicemail)
│   ├── Voicemail-to-email (audio + transcription)
│   ├── Custom greetings (per number, per time of day)
│   ├── Voicemail drop (leave pre-recorded message)
│   └── Callback button (one-click return call)
│
├── Call Recording
│   ├── Automatic recording (with consent announcement)
│   ├── Selective recording (record only certain call types)
│   ├── Recording storage (cloud, searchable)
│   ├── Playback with speed controls
│   ├── Download recordings
│   ├── Share recording (internal or with customer)
│   └── Retention policies (auto-delete after X months)
│
├── Mobile App Integration
│   ├── Make/receive calls from mobile using business number
│   ├── Push notifications for incoming calls
│   ├── Seamless handoff (office → mobile)
│   ├── SMS from business number
│   └── Do not disturb scheduling
│
├── Analytics
│   ├── Call volume by hour/day/week
│   ├── Average handle time
│   ├── Missed call rate
│   ├── First call resolution rate
│   ├── Calls by customer segment
│   ├── Agent performance (calls handled, duration, outcomes)
│   ├── Call-to-job conversion rate
│   └── Peak time analysis
│
└── Emergency Handling
    ├── Emergency keyword detection ("my house is flooding")
    ├── Priority routing for emergencies
    ├── Auto-escalation if no answer
    ├── Emergency on-call rotation
    └── After-hours emergency line
```

### COLLECTIONS

```
companies/{companyId}/phoneNumbers/{numberId}/
  ├── number (E.164 format)
  ├── type: "main" | "sales" | "service" | "emergency" | "personal"
  ├── assignedTo: userId | "queue" | "ivr"
  ├── twilioSid
  ├── forwardingNumber (optional)
  ├── voicemailGreetingUrl
  ├── recordingEnabled: bool
  └── status: "active" | "porting" | "released"

companies/{companyId}/calls/{callId}/
  ├── direction: "inbound" | "outbound"
  ├── status: "ringing" | "in_progress" | "completed" | "missed" | "voicemail" | "failed"
  │
  ├── PARTICIPANTS
  │   ├── fromNumber, toNumber
  │   ├── customerId (if matched)
  │   ├── userId (internal user who handled)
  │   └── callerName (caller ID)
  │
  ├── TIMING
  │   ├── startedAt, answeredAt, endedAt
  │   ├── ringDuration, talkDuration
  │   └── holdDuration
  │
  ├── RECORDING
  │   ├── recordingUrl
  │   ├── recordingDuration
  │   └── transcription (AI-generated)
  │
  ├── OUTCOME
  │   ├── disposition: "job_created" | "estimate_sent" | "callback_scheduled" | "resolved" | "spam" | "wrong_number"
  │   ├── linkedJobId
  │   ├── linkedEstimateId
  │   └── notes
  │
  └── VOICEMAIL (if applicable)
      ├── voicemailUrl
      ├── voicemailDuration
      ├── voicemailTranscription
      └── callbackStatus: "pending" | "completed" | "no_answer"

companies/{companyId}/callRoutes/{routeId}/
  ├── name
  ├── phoneNumberId (which number this route applies to)
  ├── priority (order of evaluation)
  ├── conditions {} (time, caller, etc.)
  ├── action: "ring_user" | "ring_group" | "ivr" | "voicemail" | "forward"
  ├── actionConfig {}
  └── isActive

companies/{companyId}/ivrMenus/{menuId}/
  ├── name
  ├── greetingUrl
  ├── options [] 
  │   └── { digit, action, actionConfig }
  ├── timeoutAction
  └── invalidInputAction

companies/{companyId}/callQueues/{queueId}/
  ├── name
  ├── memberUserIds []
  ├── strategy: "round_robin" | "ring_all" | "least_recent" | "random"
  ├── holdMusicUrl
  ├── maxWaitMinutes
  └── overflowAction
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `twilioInboundCall` | HTTP (Twilio webhook) | Handle incoming calls |
| `twilioCallStatus` | HTTP (Twilio webhook) | Call status updates |
| `twilioRecordingReady` | HTTP (Twilio webhook) | Process completed recordings |
| `transcribeVoicemail` | Firestore trigger | AI transcription of voicemail |
| `transcribeRecording` | HTTP | AI transcription of call recordings |
| `missedCallAlert` | Firestore trigger | Notify about missed calls |
| `callbackReminder` | Scheduled | Remind about pending callbacks |
| `emergencyDetection` | HTTP | AI detects emergency keywords |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Customers | Caller ID lookup, screen pop, auto-create customer |
| Jobs | Create job from call, link call to existing job |
| Calendar | Schedule appointments during call |
| SMS (Twilio) | Same number for voice and text |
| Route Optimizer | Emergency calls trigger dispatch |
| Email Marketing | "Tried to call" triggers email sequence |

---

# SYSTEM 8: FULL HR SUITE
## Your Team Is Your Business — Manage It Properly

### THE MOAT

HR is a mess for small contractors. Onboarding docs in email, training records in a binder, performance reviews never happen. ZAFTO HR brings it all together.

**ZAFTO HR Advantages:**
- Digital onboarding (I-9, W-4, direct deposit, policies — all paperless)
- PTO tracking (request, approve, balance visible)
- Performance reviews (templates, scheduling, history)
- Training/certification tracking (alerts before expiry)
- Employee self-service portal
- Document storage (signed policies, certifications, etc.)

**The Lock-In:**
- Complete employee files live in ZAFTO
- Training and certification history
- Performance review archives
- PTO balances and history
- Can't just export this to another system

### HR FEATURES

```
HR SUITE (CRM → Team → HR)
├── Employee Lifecycle
│   ├── RECRUITING (Future)
│   │   ├── Job postings
│   │   ├── Application tracking
│   │   └── Interview scheduling
│   │
│   ├── ONBOARDING
│   │   ├── Digital offer letter (e-sign)
│   │   ├── I-9 verification workflow
│   │   ├── W-4 / state tax form collection
│   │   ├── Direct deposit setup
│   │   ├── Policy acknowledgments (handbook, safety, etc.)
│   │   ├── Equipment assignment
│   │   ├── Training assignment
│   │   ├── Mentor/buddy assignment
│   │   └── First day checklist
│   │
│   ├── ACTIVE EMPLOYMENT
│   │   ├── Employee directory
│   │   ├── Org chart
│   │   ├── Role changes / promotions
│   │   ├── Compensation changes
│   │   └── Transfers between locations
│   │
│   └── OFFBOARDING
│       ├── Exit interview
│       ├── Equipment return checklist
│       ├── Access revocation
│       ├── Final paycheck calculation
│       ├── COBRA notifications
│       └── Reference policy
│
├── Time Off Management
│   ├── PTO POLICIES
│   │   ├── Policy types (PTO, sick, vacation, personal, bereavement)
│   │   ├── Accrual rules (X hours per pay period)
│   │   ├── Carryover limits
│   │   ├── Blackout dates
│   │   └── Approval workflow
│   │
│   ├── REQUESTS
│   │   ├── Employee submits request (dates, type, notes)
│   │   ├── Manager approval/denial
│   │   ├── Calendar visibility (who's out when)
│   │   ├── Conflict detection ("Mike is already off that day")
│   │   └── Balance tracking
│   │
│   └── REPORTS
│       ├── PTO balances by employee
│       ├── Upcoming time off
│       ├── PTO usage trends
│       └── Liability report (accrued PTO value)
│
├── Performance Management
│   ├── REVIEWS
│   │   ├── Review templates (annual, 90-day, project-based)
│   │   ├── Self-assessment
│   │   ├── Manager assessment
│   │   ├── 360 feedback (optional)
│   │   ├── Rating scales
│   │   ├── Goal setting
│   │   └── Development plans
│   │
│   ├── CONTINUOUS FEEDBACK
│   │   ├── Kudos/recognition (peer-to-peer)
│   │   ├── Quick feedback notes
│   │   └── 1:1 meeting notes
│   │
│   └── PERFORMANCE DATA
│       ├── Jobs completed
│       ├── Customer ratings
│       ├── On-time arrival rate
│       ├── Callback rate
│       └── Revenue generated
│
├── Training & Certifications
│   ├── TRAINING PROGRAMS
│   │   ├── Required training (safety, harassment, etc.)
│   │   ├── Role-based training
│   │   ├── Video/document content
│   │   ├── Quizzes/assessments
│   │   ├── Completion tracking
│   │   └── Recurring training (annual refreshers)
│   │
│   ├── CERTIFICATIONS
│   │   ├── License tracking (trade licenses, driver's license)
│   │   ├── Certification tracking (OSHA, EPA, manufacturer certs)
│   │   ├── Expiration dates
│   │   ├── Renewal reminders (90, 60, 30 days)
│   │   ├── Document upload (cert images)
│   │   └── Verification status
│   │
│   └── SKILLS MATRIX
│       ├── Skills inventory by employee
│       ├── Skill gaps analysis
│       └── Training recommendations
│
├── Employee Self-Service
│   ├── View and update personal info
│   ├── View pay stubs
│   ├── Request time off
│   ├── View PTO balance
│   ├── Complete assigned training
│   ├── Upload certifications
│   ├── View company directory
│   └── Access employee handbook
│
├── Documents & Compliance
│   ├── EMPLOYEE FILE
│   │   ├── Personal info, emergency contacts
│   │   ├── Signed documents (offer letter, policies, etc.)
│   │   ├── Performance reviews
│   │   ├── Disciplinary records
│   │   ├── Training records
│   │   └── Certifications
│   │
│   ├── COMPANY POLICIES
│   │   ├── Employee handbook
│   │   ├── Safety manual
│   │   ├── Policy acknowledgment tracking
│   │   └── Version control
│   │
│   └── COMPLIANCE
│       ├── I-9 compliance audit
│       ├── Training compliance (who's overdue)
│       ├── Certification compliance (who's expired)
│       └── Labor law posters (digital versions)
│
└── Reports
    ├── Headcount (by role, location, tenure)
    ├── Turnover rate
    ├── Training compliance
    ├── Certification status
    ├── PTO liability
    ├── Compensation analysis
    └── Diversity metrics
```

### COLLECTIONS

```
companies/{companyId}/employees/{empId}/
  (extends payroll employee record with HR fields)
  │
  ├── HR DETAILS
  │   ├── department, reportingTo
  │   ├── workLocation
  │   ├── employmentType: "full_time" | "part_time" | "seasonal"
  │   ├── jobTitle
  │   └── jobDescription
  │
  ├── ONBOARDING
  │   ├── onboardingStatus: "pending" | "in_progress" | "complete"
  │   ├── onboardingChecklistId
  │   ├── i9Status: "pending" | "submitted" | "verified"
  │   ├── w4Collected: bool
  │   ├── directDepositSetup: bool
  │   ├── handbookAcknowledged: bool
  │   └── startDate
  │
  ├── EQUIPMENT
  │   └── assignedEquipment [] { type, serialNumber, assignedAt }
  │
  └── OFFBOARDING (if terminated)
      ├── terminationType: "voluntary" | "involuntary"
      ├── terminationReason
      ├── lastDay
      ├── exitInterviewCompleted
      ├── equipmentReturned
      └── finalPaycheckDate

companies/{companyId}/ptoRequests/{requestId}/
  ├── employeeId
  ├── type: "pto" | "sick" | "vacation" | "personal" | "bereavement" | "jury_duty"
  ├── startDate, endDate
  ├── hours (partial days)
  ├── status: "pending" | "approved" | "denied" | "cancelled"
  ├── notes
  ├── approvedBy, approvedAt
  └── denialReason

companies/{companyId}/ptoBalances/{empId}/
  ├── balances {} (type → hours available)
  ├── accrued {} (type → hours accrued this year)
  ├── used {} (type → hours used this year)
  ├── carryover {} (type → hours carried from last year)
  └── asOfDate

companies/{companyId}/performanceReviews/{reviewId}/
  ├── employeeId
  ├── reviewerId
  ├── reviewType: "annual" | "90_day" | "mid_year" | "project"
  ├── reviewPeriod { start, end }
  ├── status: "draft" | "self_assessment" | "manager_review" | "meeting_scheduled" | "completed"
  │
  ├── ASSESSMENTS
  │   ├── selfAssessment {}
  │   ├── managerAssessment {}
  │   ├── ratings {} (competency → rating)
  │   └── overallRating
  │
  ├── CONTENT
  │   ├── strengths
  │   ├── areasForImprovement
  │   ├── goals [] { goal, dueDate, status }
  │   ├── developmentPlan
  │   └── employeeComments
  │
  ├── MEETING
  │   ├── scheduledAt
  │   ├── completedAt
  │   └── meetingNotes
  │
  └── SIGNATURES
      ├── employeeSignedAt
      └── managerSignedAt

companies/{companyId}/trainingPrograms/{programId}/
  ├── name, description
  ├── type: "required" | "role_based" | "optional"
  ├── applicableRoles []
  ├── contentType: "video" | "document" | "scorm" | "external"
  ├── contentUrl
  ├── durationMinutes
  ├── hasQuiz: bool
  ├── passingScore (if quiz)
  ├── recurrence: null | "annual" | "biannual"
  └── isActive

companies/{companyId}/trainingAssignments/{assignmentId}/
  ├── employeeId
  ├── programId
  ├── status: "assigned" | "in_progress" | "completed" | "overdue"
  ├── assignedAt, dueDate
  ├── startedAt, completedAt
  ├── quizScore (if applicable)
  ├── attempts
  └── certificateUrl (if issued)

companies/{companyId}/certifications/{certId}/
  ├── employeeId
  ├── type: "license" | "certification" | "training_cert"
  ├── name (e.g., "Master Electrician License", "EPA 608")
  ├── issuingAuthority
  ├── number
  ├── issueDate, expirationDate
  ├── documentUrl
  ├── verificationStatus: "pending" | "verified" | "expired"
  └── remindersSent []
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `certExpirationAlert` | Scheduled | Check certs, send reminders |
| `trainingDueAlert` | Scheduled | Remind about overdue training |
| `ptoAccrual` | Scheduled (per pay period) | Calculate and add PTO accrual |
| `onboardingReminder` | Scheduled | Nudge incomplete onboarding |
| `performanceReviewScheduler` | Scheduled | Auto-schedule annual reviews |
| `i9Verification` | HTTP | E-Verify integration (future) |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Payroll | Employee records shared, PTO affects pay calculations |
| Time Clock | Certifications determine what jobs tech can do |
| Route Optimizer | Skills/certs affect job assignment |
| Jobs | Performance metrics pulled from job completion data |
| CPA Portal | Headcount, labor costs for advisors |

---

# SYSTEM 9: DOCUMENT TEMPLATE ENGINE
## Never Write a Contract From Scratch Again

### THE MOAT

Every contractor needs contracts, proposals, change orders, lien notices. Most copy-paste from Word docs and miss critical clauses. ZAFTO Templates are:

**ZAFTO Template Advantages:**
- Legally reviewed templates by trade and state
- Auto-populated from job/customer data
- E-signature built in
- Version control (what did they sign?)
- Clause library (add standard clauses with one click)
- AI customization ("Add a clause about permit delays")

**The Lock-In:**
- Custom templates refined over years
- All signed documents stored in ZAFTO
- Can't recreate clause library elsewhere
- Legal audit trail

### TEMPLATE FEATURES

```
DOCUMENT TEMPLATES (CRM → Settings → Documents)
├── Template Library
│   ├── BY DOCUMENT TYPE
│   │   ├── Proposals / Estimates
│   │   ├── Service Agreements
│   │   ├── Contracts (residential, commercial)
│   │   ├── Change Orders
│   │   ├── Lien Notices (preliminary, mechanic's lien)
│   │   ├── Waiver of Lien
│   │   ├── Work Authorization
│   │   ├── Completion Certificates
│   │   ├── Warranty Documents
│   │   └── Scope of Work
│   │
│   ├── BY TRADE
│   │   ├── Electrical
│   │   ├── Plumbing
│   │   ├── HVAC
│   │   ├── General Contractor
│   │   ├── Roofing
│   │   ├── Solar
│   │   └── Landscaping
│   │
│   ├── BY STATE (for legal compliance)
│   │   └── State-specific clauses auto-included
│   │
│   └── CUSTOM TEMPLATES
│       └── User-created templates
│
├── Template Builder
│   ├── Visual editor (WYSIWYG)
│   ├── Merge fields ({{customer.name}}, {{job.address}}, etc.)
│   ├── Conditional blocks (if job.type == "commercial" show X)
│   ├── Clause library (drag-drop standard clauses)
│   ├── Table builder (line items, pricing)
│   ├── Signature blocks (single or multiple signers)
│   ├── Initial fields (for specific clauses)
│   ├── Date fields (auto-fill or manual)
│   └── Attachment areas
│
├── Clause Library
│   ├── Standard clauses by category:
│   │   ├── Payment terms
│   │   ├── Warranty
│   │   ├── Liability limitations
│   │   ├── Permit responsibilities
│   │   ├── Change order procedures
│   │   ├── Dispute resolution
│   │   ├── Cancellation
│   │   ├── Insurance requirements
│   │   ├── Indemnification
│   │   └── Force majeure
│   │
│   ├── AI clause generator
│   │   └── "Write a clause about delayed material deliveries"
│   │
│   └── Custom clause creation
│       └── Save frequently used language
│
├── Document Generation
│   ├── Select template
│   ├── Select job/customer (auto-populates fields)
│   ├── Preview and edit
│   ├── Add/remove clauses
│   ├── Send for signature or download PDF
│   └── Track status
│
├── E-Signature Workflow
│   ├── Send to customer for signature
│   ├── Multiple signers (customer + contractor)
│   ├── Signing order (customer first, then contractor)
│   ├── Reminders for unsigned documents
│   ├── Decline with reason
│   ├── Audit trail (IP, timestamp, device)
│   └── Completed document stored automatically
│
├── AI Document Assistant
│   ├── "Review this contract for risks" (existing feature extended)
│   ├── "Simplify this clause for customer understanding"
│   ├── "Add protection for [specific scenario]"
│   ├── "Compare to industry standard"
│   └── "Translate to plain English"
│
└── Document Management
    ├── All generated documents searchable
    ├── Filter by type, status, customer, job
    ├── Version history
    ├── Renewal reminders (for recurring agreements)
    └── Bulk document generation
```

### COLLECTIONS

```
companies/{companyId}/documentTemplates/{templateId}/
  ├── name
  ├── type: "proposal" | "contract" | "change_order" | "lien_notice" | "warranty" | "other"
  ├── trade: "electrical" | "plumbing" | "hvac" | "general" | etc.
  ├── state (for state-specific compliance)
  ├── htmlContent (with merge field placeholders)
  ├── mergeFields [] (list of available fields)
  ├── clauseIds [] (clauses included)
  ├── signatureBlocks [] { id, label, required, order }
  ├── isActive
  ├── isDefault (for this document type)
  └── version, lastUpdatedBy

companies/{companyId}/clauses/{clauseId}/
  ├── name
  ├── category
  ├── text
  ├── isRequired (always include)
  ├── applicableTrades []
  ├── applicableStates []
  ├── source: "system" | "custom" | "ai_generated"
  └── version

companies/{companyId}/documents/{documentId}/
  ├── templateId
  ├── name
  ├── type
  ├── status: "draft" | "sent" | "viewed" | "signed" | "declined" | "expired"
  │
  ├── LINKED RECORDS
  │   ├── customerId
  │   ├── jobId
  │   ├── bidId
  │   └── invoiceId
  │
  ├── CONTENT
  │   ├── htmlContent (final merged content)
  │   ├── pdfUrl (generated PDF)
  │   └── mergedData {} (snapshot of data used)
  │
  ├── SIGNATURES
  │   ├── signatureRequests []
  │   │   └── { recipientEmail, recipientName, role, order, status, signedAt, ipAddress }
  │   ├── allSigned: bool
  │   └── signedPdfUrl
  │
  ├── TIMELINE
  │   ├── createdAt, createdBy
  │   ├── sentAt
  │   ├── viewedAt
  │   ├── signedAt
  │   └── expiresAt
  │
  └── REMINDERS
      ├── remindersSent []
      └── nextReminderAt

documentLibrary/{docId}/ (system-wide legal templates)
  ├── name, type, trade, state
  ├── htmlContent
  ├── clauses []
  ├── lastLegalReview
  └── version
```

### CLOUD FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `generateDocumentPdf` | HTTP | Create PDF from template |
| `sendForSignature` | HTTP | Email signature request |
| `signatureWebhook` | HTTP | Handle signature completion |
| `signatureReminder` | Scheduled | Remind about unsigned docs |
| `documentExpiry` | Scheduled | Expire old unsigned documents |
| `aiClauseGenerator` | HTTP | Claude generates custom clause |
| `lienDeadlineCalculator` | HTTP | Calculate lien deadlines by state |

### INTEGRATION POINTS

| Connects To | How |
|-------------|-----|
| Jobs | Auto-populate job details, link signed docs to job |
| Customers | Customer info populates templates |
| Bids | Proposal templates, bid → signed contract flow |
| Invoices | Completion certificates trigger invoice |
| ZAFTO Books | Signed amounts flow to revenue recognition |
| CPA Portal | Contract values for revenue forecasting |
| Client Portal | Customer views and signs from portal |

---

# SUMMARY: THE COMPLETE ZAFTO BUSINESS OS

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                 ZAFTO BUSINESS OS                                   │
│                          "The contractor never leaves"                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ALREADY BUILT (UI)          │  SESSION 29 ADDITIONS                               │
│  ─────────────────           │  ────────────────────                               │
│  ✅ Mobile Field App          │  📋 CPA/Accountant Portal                           │
│  ✅ CRM Web Portal            │  💰 Payroll System                                  │
│  ✅ Client Portal             │  🚛 Fleet Management                                │
│  ✅ ZAFTO Books (schema)      │  🗺️ Route Optimization                              │
│  ✅ Time Clock + GPS          │  📦 Procurement / Vendors                           │
│  ✅ 14 Field Tools            │  📧 Email Marketing                                 │
│  ✅ AI Features (5)           │  📞 VoIP Call Center                                │
│                               │  👥 Full HR Suite                                   │
│                               │  📄 Document Templates                              │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                            INTEGRATION WEB                                          │
│                                                                                     │
│  Every system feeds every other system:                                            │
│                                                                                     │
│  Time Clock → Payroll → ZAFTO Books → CPA Portal                                   │
│  Fleet GPS → Route Optimizer → Jobs → Invoices                                     │
│  VoIP Calls → Customers → Jobs → Email Marketing                                   │
│  HR Certs → Job Assignment → Performance → Payroll                                 │
│  Procurement → Inventory → Jobs → Job Costing                                      │
│  Templates → Contracts → Jobs → ZAFTO Books                                        │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                               MOAT SUMMARY                                          │
│                                                                                     │
│  SYSTEM              │  WHY THEY CAN'T LEAVE                                       │
│  ────────────────    │  ─────────────────────                                       │
│  CPA Portal          │  CPA brings 50-500 contractor clients                        │
│  Payroll             │  Tax filings, W-2 history, mid-year switch = nightmare       │
│  Fleet               │  Years of vehicle history, predictive maintenance data       │
│  Route Optimizer     │  AI trained on YOUR techs, YOUR jobs, YOUR territory         │
│  Procurement         │  Vendor relationships, pricing history, inventory data       │
│  Email Marketing     │  Campaigns, automations, segment data = years of work        │
│  VoIP                │  Business phone number lives here                            │
│  HR Suite            │  Complete employee files, training records, reviews          │
│  Templates           │  Custom legal docs, clause library, signed contract archive  │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## NEW COLLECTION TOTALS

Adding to existing 17 missing collections from Session 28:

| System | New Collections | Count |
|--------|-----------------|:-----:|
| CPA Portal | cpaFirms/, clients/, staff/, referrals/ | 4 |
| Payroll | employees/ (extended), payRuns/, paychecks/, taxDeposits/, subcontractors/, subcontractorPayments/ | 6 |
| Fleet | vehicles/, maintenanceRecords/, fuelLogs/, trips/, gpsHistory/, geofences/, vehicleRecalls/ | 7 |
| Route Optimizer | dispatchSchedules/, assignments/, territories/, routeHistory/, techMetrics/ | 5 |
| Procurement | vendors/, purchaseOrders/, lineItems/, inventory/, inventoryLocations/, inventoryStock/, inventoryTransactions/ | 7 |
| Email Marketing | emailCampaigns/, emailAutomations/, emailContacts/, emailSegments/, emailTemplates/ | 5 |
| VoIP | phoneNumbers/, calls/, callRoutes/, ivrMenus/, callQueues/ | 5 |
| HR Suite | employees/ (extended), ptoRequests/, ptoBalances/, performanceReviews/, trainingPrograms/, trainingAssignments/, certifications/ | 7 |
| Document Templates | documentTemplates/, clauses/, documents/, documentLibrary/ | 4 |
| **TOTAL NEW** | | **50** |

**Grand Total Collections: 67 (17 existing missing + 50 new)**

---

## NEW CLOUD FUNCTIONS

| System | Functions | Count |
|--------|-----------|:-----:|
| CPA Portal | cpaClientInvite, cpaGenerateTaxPackage, cpaGenerate1099s, cpaReferralTrack, cpaReferralPayout, cpaClientHealthCheck | 6 |
| Payroll | calculatePaycheck, processDirectDeposit, generatePayStub, taxDepositReminder, generate941, generateW2s, generate1099s, newHireReporting | 8 |
| Fleet | syncFuelCards, checkVehicleRecalls, maintenanceReminder, documentExpiryAlert, calculateVehicleTCO, geofenceEvent, tripAnalysis | 7 |
| Route Optimizer | optimizeRoutes, rerouteOnDelay, sendETAUpdate, calculateTechMetrics, dispatchEmergency | 5 |
| Procurement | vendorInsuranceAlert, inventoryReorderAlert, purchaseOrderToVendor, vendorInvoiceOCR, priceComparisonEngine, materialUsagePrediction | 6 |
| Email Marketing | sendEmail, processEmailWebhook, automationEnroll, automationStep, segmentCalculate, aiEmailWriter, emailRevenueAttribution | 7 |
| VoIP | twilioInboundCall, twilioCallStatus, twilioRecordingReady, transcribeVoicemail, transcribeRecording, missedCallAlert, callbackReminder, emergencyDetection | 8 |
| HR Suite | certExpirationAlert, trainingDueAlert, ptoAccrual, onboardingReminder, performanceReviewScheduler, i9Verification | 6 |
| Document Templates | generateDocumentPdf, sendForSignature, signatureWebhook, signatureReminder, documentExpiry, aiClauseGenerator, lienDeadlineCalculator | 7 |
| **TOTAL NEW** | | **60** |

**Grand Total Cloud Functions: 71 (11 existing + 60 new)**

---

## WIRING PHASE UPDATES

These systems integrate into the existing wiring phases:

| Phase | Original Scope | Add From Session 29 |
|-------|---------------|---------------------|
| W1 | Core pipeline (jobs, invoices, customers) | Employee extensions, basic payroll fields |
| W2 | Field tools → backend | Fleet GPS integration with Time Clock |
| W3 | Missing P0 tools | Inventory management (Procurement) |
| W4 | Web Portal wiring | Full CRM integration for all 9 systems |
| W5 | Client Portal wiring | Document signatures from portal |
| W6 | NEW | CPA Portal (standalone, could be parallel) |
| W7 | NEW | Payroll + HR (tightly coupled) |
| W8 | NEW | Fleet + Route Optimization |
| W9 | NEW | Procurement + Inventory |
| W10 | NEW | Communications (VoIP + Email) |
| W11 | NEW | Document Templates |

**Estimated Additional Hours: ~180 hours for all 9 systems**

---

**END OF BUSINESS OS EXPANSION — FEBRUARY 5, 2026 (Session 29)**
**NEXT: Update Circuit Blueprint with references to this document**
