# ZAFTO INTELLIGENCE DATABASE
## AI Knowledge Base for All Trades
### Last Updated: February 1, 2026

---

## PURPOSE

This folder is the **master intelligence source** for the ZAFTO AI system.

**Designed for:**
- Claude Opus 4.5 real-time queries
- Future offline models (dead zone coverage)
- RAG (Retrieval Augmented Generation) systems
- Context injection for calculator explanations
- Exam question generation
- Code compliance checking

---

## MASTER TRADE LIST (29 TRADES)

### Tier 1: Original Construction Trades (15)

| # | Trade | File | Target Calcs | State License? |
|---|-------|------|--------------|----------------|
| 1 | Electrical | electrical.md | 96 | YES (all states) |
| 2 | Plumbing | plumbing.md | 108 | YES (all states) |
| 3 | HVAC | hvac.md | 116 | YES (most states) |
| 4 | Solar | solar.md | 92 | YES + NABCEP |
| 5 | Roofing | roofing.md | 83 | Some states |
| 6 | General Contractor | gc.md | 101 | YES (most states) |
| 7 | Remodeler | remodeler.md | 110 | Some states |
| 8 | Landscaping | landscaping.md | 148 | Pesticide cert |
| 9 | Carpentry | carpentry.md | 155 | Some states |
| 10 | Auto Mechanic | auto_mechanic.md | 178 | ASE certification |
| 11 | Painting | painting.md | 52 | RRP certification |
| 12 | Flooring | flooring.md | 58 | No |
| 13 | Concrete/Masonry | concrete_masonry.md | 67 | Some states |
| 14 | Welding | welding.md | 48 | AWS certification |
| 15 | Pool/Spa | pool_spa.md | 54 | YES (most states) |

### Tier 2: Expansion Trades (14 NEW)

| # | Trade | File | Target Calcs | State License? |
|---|-------|------|--------------|----------------|
| 16 | Lineman | lineman.md | 95 | Union apprenticeship |
| 17 | Fire Sprinkler | fire_sprinkler.md | 85 | YES (~42 states) |
| 18 | Elevator Mechanic | elevator_mechanic.md | 75 | YES (~45 states) |
| 19 | Ironworker | ironworker.md | 85 | NCCCO certification |
| 20 | Pipefitter | pipefitter.md | 95 | ~20 states |
| 21 | Diesel Mechanic | diesel_mechanic.md | 90 | ASE certification |
| 22 | Low Voltage | low_voltage.md | 75 | YES (~45 states) |
| 23 | Glazier | glazier.md | 55 | Few states |
| 24 | Insulator | insulator.md | 65 | Union certification |
| 25 | Millwright | millwright.md | 85 | Industry certs |
| 26 | Drywall | drywall.md | 50 | Few states |
| 27 | Tile Setter | tile_setter.md | 55 | CTI certification |
| 28 | Cabinet Maker | cabinet_maker.md | 60 | Few states |
| 29 | Appliance Repair | appliance_repair.md | 50 | EPA 608 required |

---

## CURRENT STATUS

| Category | Count | Status |
|----------|-------|--------|
| Trade INTEL Files | 29/29 | COMPLETE |
| Code Adoption Files | 0/5 | Not Started |
| Licensing Matrix | 0/1 | Not Started |
| Formula Database | 0/1 | Not Started |

### CALCULATOR BUILD STATUS

| Category | Target | Built | % |
|----------|--------|-------|---|
| Original 15 trades | 1,466 | 203 | 14% |
| Expansion 14 trades | 1,020 | 0 | 0% |
| **TOTAL** | **2,486** | **203** | **8%** |

---

## EXAM PREP OPPORTUNITY

### HIGH VALUE (State License Required)
- Electrical - All 50 states
- Plumbing - All 50 states
- HVAC - Most states
- Fire Sprinkler - ~42 states + NICET
- Elevator Mechanic - ~45 states + QEI
- Low Voltage/Fire Alarm - ~45 states + NICET
- General Contractor - Most states
- Pool/Spa - Most states
- Solar - NABCEP certification

### MEDIUM VALUE (Industry Certification)
- Auto Mechanic - ASE
- Diesel Mechanic - ASE T-series
- Welding - AWS
- Ironworker - NCCCO Rigger
- Tile Setter - CTI
- Appliance Repair - EPA 608
- Lineman - IBEW apprenticeship

### LOWER VALUE (Minimal Licensing)
- Roofing, Landscaping, Carpentry, Painting, Flooring
- Concrete/Masonry, Glazier, Insulator, Millwright
- Drywall, Cabinet Maker, Remodeler

---

## FILE STRUCTURE

```
INTEL/
├── 00_INTEL_INDEX.md           <- You are here
├── 01_INTEL_SPRINT.md          <- Sprint tracker
│
├── TRADES/                     <- 29 trade files
│   ├── electrical.md
│   ├── plumbing.md
│   ├── hvac.md
│   ├── solar.md
│   ├── roofing.md
│   ├── gc.md
│   ├── remodeler.md
│   ├── landscaping.md
│   ├── carpentry.md
│   ├── auto_mechanic.md
│   ├── painting.md
│   ├── flooring.md
│   ├── concrete_masonry.md
│   ├── welding.md
│   ├── pool_spa.md
│   ├── lineman.md              <- NEW
│   ├── fire_sprinkler.md       <- NEW
│   ├── elevator_mechanic.md    <- NEW
│   ├── ironworker.md           <- NEW
│   ├── pipefitter.md           <- NEW
│   ├── diesel_mechanic.md      <- NEW
│   ├── low_voltage.md          <- NEW
│   ├── glazier.md              <- NEW
│   ├── insulator.md            <- NEW
│   ├── millwright.md           <- NEW
│   ├── drywall.md              <- NEW
│   ├── tile_setter.md          <- NEW
│   ├── cabinet_maker.md        <- NEW
│   └── appliance_repair.md     <- NEW
│
├── CODES/                      <- State code adoption
│   ├── nec_by_state.md
│   ├── plumbing_by_state.md
│   ├── mechanical_by_state.md
│   ├── building_by_state.md
│   └── state_amendments.md
│
├── LICENSING/                  <- License requirements
│   └── licensing_matrix.md
│
└── FORMULAS/                   <- Calculator formulas
    └── master_formulas.md
```

---

## RETRIEVAL PATTERNS

**By trade:**
```
INTEL/TRADES/electrical.md
INTEL/TRADES/fire_sprinkler.md
```

**By state code adoption:**
```
INTEL/CODES/nec_by_state.md -> find "Connecticut"
```

**By licensing:**
```
INTEL/LICENSING/licensing_matrix.md -> find state + trade
```

---

## UPDATE PROTOCOL

1. Always include `Last Updated: [DATE]` at top
2. Always cite sources with URLs
3. Always note code edition years
4. Mark unverified data with `[UNVERIFIED]`
5. Mark verified data with `[VERIFIED: DATE]`

---

*ZAFTO Intelligence Database - 29 Trades*
*All trade INTEL files complete*
