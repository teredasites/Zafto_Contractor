# ELECTRICAL TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Electrical |
| ZAFTO Calculators | 96 |
| Primary Code | NEC (NFPA 70) |
| Publisher | National Fire Protection Association (NFPA) |
| Update Cycle | Every 3 years |
| Current Edition | NEC 2023 |
| Editions Still in Use | 2008, 2014, 2017, 2020, 2023 |

---

## GOVERNING CODES & STANDARDS

### Primary: National Electrical Code (NEC) - NFPA 70

| Edition | Release Date | Key Changes |
|---------|--------------|-------------|
| **NEC 2023** | Aug 2022 | All definitions to Art 100, GFCI all kitchen receptacles, 10A branch circuits, surge protection expanded |
| **NEC 2020** | Aug 2019 | Emergency disconnects required, surge protection Art 242, GFCI within 6ft of sinks, outdoor GFCI expanded |
| **NEC 2017** | Aug 2016 | AFCI expansion, GFCI in laundry areas, reconditioned equipment rules |
| **NEC 2014** | Aug 2013 | Arc-fault requirements expanded, GFCI in laundry |
| **NEC 2008** | Sep 2007 | Tamper-resistant receptacles, AFCI bedrooms |

### Secondary Standards

| Standard | Publisher | Scope |
|----------|-----------|-------|
| NFPA 70E | NFPA | Electrical safety in workplace, arc flash |
| NFPA 79 | NFPA | Industrial machinery electrical |
| UL Standards | UL | Equipment listings and testing |
| IEEE Standards | IEEE | Power systems, grounding |
| OSHA 29 CFR 1910 Subpart S | OSHA | Electrical safety requirements |

---

## NEC ADOPTION BY STATE

**Data Source:** mikeholt.com, verified January 2024

| State | NEC Edition | Effective Date | Amendments | Notes |
|-------|-------------|----------------|------------|-------|
| Alabama | 2020 | 7/1/22 | Yes | State amendments apply |
| Alaska | 2020 | 4/16/20 | Minimal | |
| Arizona | Local | Varies | Varies | No statewide adoption |
| Arkansas | 2020 | 8/1/22 | Yes | |
| California | 2020 | 1/1/23 | **Heavy** | Title 24 Part 3 - significant amendments |
| Colorado | 2023 | 8/1/23 | Minimal | Early adopter |
| Connecticut | 2020 | 10/1/22 | Yes | |
| Delaware | 2020 | 9/1/21 | Minimal | |
| District of Columbia | 2014 | 5/29/20 | Yes | Significantly behind |
| Florida | 2020 | 12/31/23 | Yes | FBC Electrical |
| Georgia | 2023 | 1/1/25 | Minimal | |
| Hawaii | 2020 | 3/4/23 | Yes | |
| Idaho | 2023 | 7/1/24 | Minimal | |
| Illinois | Local | Varies | Varies | No statewide - Chicago has own code |
| Indiana | **2008** | 6/2/09 | Yes | **Significantly behind** |
| Iowa | 2023 | 7/1/25 | Minimal | |
| Kansas | Local | Varies | Varies | No statewide adoption |
| Kentucky | 2023 | 1/1/25 | Minimal | |
| Louisiana | 2020 | 1/1/23 | Yes | |
| Maine | 2023 | 7/1/24 | Minimal | |
| Maryland | 2020 | 5/29/23 | Yes | |
| Massachusetts | 2023 | 2/17/23 | **Heavy** | 527 CMR - significant amendments |
| Michigan | 2023 | 3/12/24 | Yes | |
| Minnesota | 2023 | 7/1/23 | Yes | |
| Mississippi | Local | Varies | Varies | No statewide adoption |
| Missouri | Local | Varies | Varies | No statewide adoption |
| Montana | 2020 | 6/10/22 | Minimal | |
| Nebraska | 2023 | 8/1/24 | Minimal | |
| Nevada | Local | Varies | Varies | No statewide - Clark County uses 2020 |
| New Hampshire | 2023 | 7/1/25 | Minimal | |
| New Jersey | 2020 | 9/6/22 | Yes | |
| New Mexico | 2020 | 3/28/23 | Minimal | |
| New York | **2017** | 5/12/20 | **Heavy** | NYC has separate electrical code |
| North Carolina | 2020 | 11/1/21 | Yes | |
| North Dakota | 2023 | 7/1/24 | Minimal | |
| Ohio | 2023 | 3/1/24 | Yes | |
| Oklahoma | 2023 | 9/14/24 | Minimal | |
| Oregon | 2023 | 10/1/23 | Yes | |
| Pennsylvania | **2017** | 2/14/22 | Yes | Behind by 2 cycles |
| Rhode Island | 2020 | 2/1/22 | Minimal | |
| South Carolina | 2020 | 1/1/23 | Yes | |
| South Dakota | 2023 | 11/12/24 | Minimal | |
| Tennessee | **2017** | 10/1/18 | Yes | Behind by 2 cycles |
| Texas | 2023 | 9/1/23 | Yes | |
| Utah | 2023 | 7/1/25 | Minimal | |
| Vermont | 2020 | 4/15/22 | Minimal | |
| Virginia | 2020 | 1/18/24 | Yes | |
| Washington | 2023 | 4/1/24 | Yes | |
| West Virginia | 2020 | 8/1/22 | Minimal | |
| Wisconsin | **2017** | 8/1/18 | Yes | Behind by 2 cycles |
| Wyoming | 2023 | 7/1/23 | Minimal | Early adopter |

### Summary by Edition Currently Enforced

| NEC Edition | States Using | Count |
|-------------|--------------|-------|
| 2023 | CO, GA, ID, IA, KY, ME, MA, MI, MN, NE, NH, ND, OH, OK, OR, SD, TX, UT, WA, WY | 20 |
| 2020 | AL, AK, AR, CA, CT, DE, FL, HI, LA, MD, MT, NJ, NM, NC, RI, SC, VT, VA, WV | 19 |
| 2017 | NY, PA, TN, WI | 4 |
| 2014 | DC | 1 |
| 2008 | IN | 1 |
| Local Only | AZ, IL, KS, MS, MO, NV | 6 |

---

## KEY FORMULAS FOR CALCULATORS

### 1. VOLTAGE DROP CALCULATIONS

**Single-Phase:**
```
VD = (2 × K × I × L) / CM

Where:
VD = Voltage drop (volts)
K = Resistivity constant (12.9 for copper, 21.2 for aluminum)
I = Current (amps)
L = One-way length (feet)
CM = Circular mils of conductor (from NEC Chapter 9, Table 8)
```

**Three-Phase:**
```
VD = (1.732 × K × I × L) / CM

(√3 = 1.732 accounts for three-phase)
```

**NEC Recommendations (Informational Notes):**
- Branch circuits: 3% max voltage drop
- Feeders: 3% max voltage drop
- Total (service to outlet): 5% max combined
- Reference: NEC 210.19(A)(1), 215.2(A)(1)

**K Factor Values:**
| Material | K Value | Source |
|----------|---------|--------|
| Copper (uncoated) | 12.9 | NEC Chapter 9 |
| Copper (coated) | 12.9 | NEC Chapter 9 |
| Aluminum | 21.2 | NEC Chapter 9 |

---

### 2. WIRE SIZING / AMPACITY

**Base Formula:**
```
Required Ampacity = Load Current × 1.25 (for continuous loads)

Reference: NEC 210.19, 215.2
```

**Derating for Temperature (NEC Table 310.15(B)(1)):**
```
Adjusted Ampacity = Base Ampacity × Temperature Correction Factor

Example correction factors for 90°C wire:
- 86°F (30°C): 1.00
- 95°F (35°C): 0.96
- 104°F (40°C): 0.91
- 113°F (45°C): 0.87
- 122°F (50°C): 0.82
```

**Derating for Bundling (NEC 310.15(C)(1)):**
```
Adjusted Ampacity = Base Ampacity × Adjustment Factor

Conductors in raceway:
- 1-3: 100%
- 4-6: 80%
- 7-9: 70%
- 10-20: 50%
- 21-30: 45%
- 31-40: 40%
- 41+: 35%
```

**NEC Table 310.16 Ampacity Values (75°C Column - Most Common):**

| AWG/kcmil | Copper | Aluminum |
|-----------|--------|----------|
| 14 | 15A | — |
| 12 | 20A | 15A |
| 10 | 30A | 25A |
| 8 | 40A | 35A |
| 6 | 55A | 45A |
| 4 | 70A | 55A |
| 3 | 85A | 65A |
| 2 | 95A | 75A |
| 1 | 110A | 85A |
| 1/0 | 125A | 100A |
| 2/0 | 145A | 115A |
| 3/0 | 165A | 130A |
| 4/0 | 195A | 150A |
| 250 | 215A | 170A |
| 300 | 240A | 190A |
| 350 | 260A | 210A |
| 400 | 280A | 225A |
| 500 | 320A | 260A |

**Terminal Temperature Rules (NEC 110.14(C)):**
- Equipment ≤100A: Use 60°C column
- Equipment >100A: May use 75°C column
- 90°C wire can be used but sized from 75°C column (derate benefit only)

---

### 3. BOX FILL CALCULATIONS (NEC 314.16)

**Formula:**
```
Total Volume Required = Sum of all volume allowances

Volume Allowances (Table 314.16(B)):
- Each conductor: Based on largest wire size
- Clamps: 1× largest conductor (all clamps combined)
- Devices: 2× largest conductor connected to device
- Equipment grounds: 1× largest EGC (all EGCs combined)
- Equipment bonding jumpers: 1× largest (2023 NEC change)
```

**Volume per Conductor (Table 314.16(B)):**

| AWG | Volume (cu in) |
|-----|----------------|
| 18 | 1.50 |
| 16 | 1.75 |
| 14 | 2.00 |
| 12 | 2.25 |
| 10 | 2.50 |
| 8 | 3.00 |
| 6 | 5.00 |

**Standard Box Volumes (Table 314.16(A)):**

| Box Type | Dimensions | Volume (cu in) |
|----------|------------|----------------|
| 4" square | 1-1/4" deep | 18.0 |
| 4" square | 1-1/2" deep | 21.0 |
| 4" square | 2-1/8" deep | 30.3 |
| 4-11/16" square | 1-1/4" deep | 25.5 |
| 4-11/16" square | 1-1/2" deep | 29.5 |
| 4-11/16" square | 2-1/8" deep | 42.0 |
| Single gang | 2" × 3" × 2-1/4" | 10.5 |
| Single gang | 2" × 3" × 2-1/2" | 12.5 |
| Single gang | 2" × 3" × 3-1/2" | 18.0 |

---

### 4. CONDUIT FILL (NEC Chapter 9)

**Formula:**
```
Fill % = (Total Conductor Area / Conduit Internal Area) × 100
```

**Maximum Fill (NEC Chapter 9, Table 1):**

| Number of Conductors | Max Fill % |
|---------------------|------------|
| 1 | 53% |
| 2 | 31% |
| 3+ | 40% |
| Nipple (≤24") | 60% |

**Conductor Areas - THHN/THWN (Table 5):**

| AWG | Area (sq in) |
|-----|--------------|
| 14 | 0.0097 |
| 12 | 0.0133 |
| 10 | 0.0211 |
| 8 | 0.0366 |
| 6 | 0.0507 |
| 4 | 0.0824 |
| 3 | 0.0973 |
| 2 | 0.1158 |
| 1 | 0.1562 |
| 1/0 | 0.1855 |
| 2/0 | 0.2223 |
| 3/0 | 0.2679 |
| 4/0 | 0.3237 |

**EMT Conduit Areas (Table 4):**

| Trade Size | Internal Area (sq in) | 40% Fill |
|------------|----------------------|----------|
| 1/2" | 0.304 | 0.122 |
| 3/4" | 0.533 | 0.213 |
| 1" | 0.864 | 0.346 |
| 1-1/4" | 1.496 | 0.598 |
| 1-1/2" | 2.036 | 0.814 |
| 2" | 3.356 | 1.342 |
| 2-1/2" | 5.858 | 2.343 |
| 3" | 8.846 | 3.538 |
| 3-1/2" | 11.545 | 4.618 |
| 4" | 14.753 | 5.901 |

---

### 5. DWELLING UNIT LOAD CALCULATIONS

#### Standard Method (NEC 220.40-220.60)

**General Lighting Load:**
```
VA = Floor Area (sq ft) × 3 VA/sq ft

Demand Factors (Table 220.42):
- First 3,000 VA: 100%
- Next 117,000 VA: 35%
- Over 120,000 VA: 25%
```

**Small Appliance Circuits:**
```
2 circuits × 1,500 VA = 3,000 VA minimum
```

**Laundry Circuit:**
```
1 circuit × 1,500 VA = 1,500 VA minimum
```

#### Optional Method (NEC 220.82) - For 100A+ Services

**Step 1 - General Loads:**
```
Total = (Floor Area × 3 VA) + 4,500 VA (small appliance + laundry) + All appliances
```

**Step 2 - Apply Demand:**
```
First 10 kVA: 100%
Remainder: 40%
```

**Step 3 - HVAC (Largest Only):**
```
A/C: 100%
Heat pump (no aux): 100%
Heat pump + aux: 100% HP + 65% aux
Electric heat (<4 units): 65%
Electric heat (4+ units): 40%
```

---

### 6. MOTOR CALCULATIONS

**Branch Circuit Conductor Sizing (NEC 430.22):**
```
Conductor Ampacity ≥ 125% × FLC (Full Load Current)

Use NEC Table 430.248 (single-phase) or 430.250 (three-phase) for FLC
NOT nameplate current
```

**Overload Protection (NEC 430.32):**
```
Standard motors: 125% × nameplate FLA
Motors marked SF ≥1.15 or temp rise ≤40°C: 125%
All other motors: 115%
```

**Branch Circuit Short-Circuit Protection (NEC 430.52):**
```
Max fuse/breaker size varies by type:
- Dual-element fuse: 175% FLC
- Inverse-time breaker: 250% FLC
- Instantaneous breaker: 800% FLC (max 1300% for Design E)
```

**Motor Full Load Current Tables:**

*Single-Phase (Table 430.248):*
| HP | 115V | 230V |
|----|------|------|
| 1/4 | 5.8A | 2.9A |
| 1/3 | 7.2A | 3.6A |
| 1/2 | 9.8A | 4.9A |
| 3/4 | 13.8A | 6.9A |
| 1 | 16A | 8A |
| 1-1/2 | 20A | 10A |
| 2 | 24A | 12A |
| 3 | 34A | 17A |
| 5 | 56A | 28A |

*Three-Phase (Table 430.250):*
| HP | 208V | 230V | 460V |
|----|------|------|------|
| 1 | 4.6A | 4.2A | 2.1A |
| 1-1/2 | 6.6A | 6.0A | 3.0A |
| 2 | 7.5A | 6.8A | 3.4A |
| 3 | 10.6A | 9.6A | 4.8A |
| 5 | 16.7A | 15.2A | 7.6A |
| 7-1/2 | 24.2A | 22A | 11A |
| 10 | 30.8A | 28A | 14A |
| 15 | 46.2A | 42A | 21A |
| 20 | 59.4A | 54A | 27A |
| 25 | 74.8A | 68A | 34A |
| 30 | 88A | 80A | 40A |
| 40 | 114A | 104A | 52A |
| 50 | 143A | 130A | 65A |

---

### 7. TRANSFORMER CALCULATIONS

**Primary Current:**
```
I_primary = VA / V_primary

For 3-phase:
I_primary = VA / (V_primary × 1.732)
```

**Secondary Current:**
```
I_secondary = VA / V_secondary

For 3-phase:
I_secondary = VA / (V_secondary × 1.732)
```

**Overcurrent Protection (NEC 450.3):**

*Transformers Over 1000V:*
| Location | Max Primary | Max Secondary |
|----------|-------------|---------------|
| Supervised | 250% | 225% |
| Unsupervised | 125% | 125% |

*Transformers 1000V and Less (Table 450.3(B)):*
| Primary Current | Max Primary OCP | Max Secondary OCP |
|-----------------|-----------------|-------------------|
| ≥9A | 125% | 125% |
| 2-9A | 167% | 167% |
| <2A | 300% | 167% |

---

### 8. SERVICE CALCULATIONS

**Minimum Service Size:**
```
Per NEC 230.79:
- Single branch circuit: 15A
- Two-circuit systems: 30A
- One-family dwelling: 100A minimum
- All other installations: 60A minimum
```

**Service Conductor Sizing (NEC 230.42):**
```
Ampacity ≥ Maximum load to be served

Use demand calculations from NEC Article 220
```

---

### 9. GROUNDING & BONDING

**Grounding Electrode Conductor (NEC 250.66):**

| Service Conductor Size (Cu) | GEC Size (Cu) | GEC Size (Al) |
|-----------------------------|---------------|---------------|
| 2 AWG or smaller | 8 AWG | 6 AWG |
| 1 or 1/0 AWG | 6 AWG | 4 AWG |
| 2/0 or 3/0 AWG | 4 AWG | 2 AWG |
| Over 3/0 to 350 kcmil | 2 AWG | 1/0 AWG |
| Over 350 to 600 kcmil | 1/0 AWG | 3/0 AWG |
| Over 600 to 1100 kcmil | 2/0 AWG | 4/0 AWG |
| Over 1100 kcmil | 3/0 AWG | 250 kcmil |

**Equipment Grounding Conductor (NEC 250.122):**

| Overcurrent Device (Amps) | EGC Cu | EGC Al |
|---------------------------|--------|--------|
| 15 | 14 AWG | 12 AWG |
| 20 | 12 AWG | 10 AWG |
| 30 | 10 AWG | 8 AWG |
| 40 | 10 AWG | 8 AWG |
| 60 | 10 AWG | 8 AWG |
| 100 | 8 AWG | 6 AWG |
| 200 | 6 AWG | 4 AWG |
| 300 | 4 AWG | 2 AWG |
| 400 | 3 AWG | 1 AWG |
| 500 | 2 AWG | 1/0 AWG |
| 600 | 1 AWG | 2/0 AWG |
| 800 | 1/0 AWG | 3/0 AWG |
| 1000 | 2/0 AWG | 4/0 AWG |
| 1200 | 3/0 AWG | 250 kcmil |

---

### 10. GFCI REQUIREMENTS BY NEC EDITION

| Location | 2017 | 2020 | 2023 |
|----------|------|------|------|
| Bathrooms | All 125V | All 125V | All 125-250V |
| Kitchens (countertop) | All 125V | All 125V | All 125-250V |
| Kitchens (all receptacles) | No | No | **Yes** |
| Outdoors | All 125V | All 125V | All 125-250V |
| Garages | All 125V | All 125V | All 125-250V |
| Crawl spaces | All 125V | All 125V | All 125-250V |
| Basements | All 125V | All 125V | All 125-250V |
| Laundry areas | All 125V | All 125V | All 125-250V |
| Within 6' of sink | All 125V | All 125V | All 125-250V |
| Boathouses | All 125V | All 125V | All 125-250V |
| Outdoor HVAC equipment | — | Required | **Removed** |

---

### 11. AFCI REQUIREMENTS BY NEC EDITION

| Location | 2017 | 2020 | 2023 |
|----------|------|------|------|
| Bedrooms | Required | Required | Required |
| Living rooms | Required | Required | Required |
| Family rooms | Required | Required | Required |
| Dining rooms | Required | Required | Required |
| Libraries/dens | Required | Required | Required |
| Sunrooms | Required | Required | Required |
| Recreation rooms | Required | Required | Required |
| Closets | Required | Required | Required |
| Hallways | Required | Required | Required |
| Laundry areas | Required | Required | Required |
| Kitchens | — | Required | Required |

---

## LICENSING REQUIREMENTS BY STATE

| State | License Required | Types | Exam | Reciprocity |
|-------|------------------|-------|------|-------------|
| Alabama | Yes | JW, Master, Contractor | Yes | Limited |
| Alaska | Yes | JW, Administrator | Yes | None |
| Arizona | Local | Varies | Varies | N/A |
| Arkansas | Yes | JW, Master, Contractor | Yes | None |
| California | Yes | Certified, C-10 Contractor | Yes | None |
| Colorado | Yes | JW, Master, Contractor | Yes | Limited |
| Connecticut | Yes | E-1, E-2, Contractor | Yes | None |
| Delaware | Yes | JW, Master | Yes | None |
| Florida | Yes | JW, Contractor | Yes | None |
| Georgia | Yes | JW, Master, Contractor | Yes | Limited |
| Hawaii | Yes | JW, Contractor | Yes | None |
| Idaho | Yes | JW, Master | Yes | Limited |
| Illinois | Local | Varies | Varies | N/A |
| Indiana | Yes | JW, Contractor | Yes | Limited |
| Iowa | Yes | JW, Master | Yes | None |
| Kansas | Local | Varies | Varies | N/A |
| Kentucky | Yes | JW, Master | Yes | None |
| Louisiana | Yes | JW, Master | Yes | None |
| Maine | Yes | JW, Master | Yes | Limited |
| Maryland | Yes | JW, Master | Yes | None |
| Massachusetts | Yes | JW, Master, Contractor | Yes | None |
| Michigan | Yes | JW, Master, Contractor | Yes | None |
| Minnesota | Yes | JW, Master, Contractor | Yes | MN/ND |
| Mississippi | Local | Varies | Varies | N/A |
| Missouri | Local | Varies | Varies | N/A |
| Montana | Yes | JW, Master | Yes | Limited |
| Nebraska | Yes | JW, Contractor | Yes | None |
| Nevada | Local | Varies | Varies | N/A |
| New Hampshire | Yes | JW, Master | Yes | None |
| New Jersey | Yes | JW, Contractor | Yes | None |
| New Mexico | Yes | JW, Contractor | Yes | Limited |
| New York | Local/State | Varies | Varies | NYC separate |
| North Carolina | Yes | JW, Contractor | Yes | Limited |
| North Dakota | Yes | JW, Master | Yes | MN/ND |
| Ohio | Yes | JW, Contractor | Yes | None |
| Oklahoma | Yes | JW, Contractor | Yes | None |
| Oregon | Yes | JW, Supervisor | Yes | None |
| Pennsylvania | Local | Varies | Varies | N/A |
| Rhode Island | Yes | JW, Master | Yes | None |
| South Carolina | Yes | JW, Contractor | Yes | None |
| South Dakota | Yes | JW, Master | Yes | Limited |
| Tennessee | Yes | JW, Contractor | Yes | None |
| Texas | Yes | JW, Master | Yes | None |
| Utah | Yes | JW, Master | Yes | None |
| Vermont | Yes | JW, Master | Yes | None |
| Virginia | Yes | JW, Master | Yes | None |
| Washington | Yes | JW, Administrator | Yes | None |
| West Virginia | Yes | JW, Master | Yes | None |
| Wisconsin | Yes | JW, Master | Yes | None |
| Wyoming | Yes | JW, Master | Yes | Limited |

**Common Requirements:**
- Journeyman: 4,000-8,000 hours experience + exam
- Master: Journeyman license + 2-4 years + exam
- Contractor: Master license or employ Master + business license + bond/insurance

---

## REFERENCE TABLES NEEDED FOR ZAFTO

### Tables to Include in App:

1. **NEC Table 310.16** - Ampacity (all temperature columns)
2. **NEC Table 310.15(B)(1)** - Temperature correction factors
3. **NEC Table 310.15(C)(1)** - Bundling adjustment factors
4. **NEC Chapter 9, Table 1** - Conduit fill percentages
5. **NEC Chapter 9, Table 4** - Conduit dimensions (EMT, IMC, RMC, PVC)
6. **NEC Chapter 9, Table 5** - Conductor dimensions
7. **NEC Chapter 9, Table 8** - Conductor properties (CM, resistance)
8. **NEC Table 314.16(A)** - Box volumes
9. **NEC Table 314.16(B)** - Conductor volumes
10. **NEC Table 220.42** - General lighting demand factors
11. **NEC Table 220.55** - Cooking equipment demand
12. **NEC Table 250.66** - GEC sizing
13. **NEC Table 250.122** - EGC sizing
14. **NEC Table 430.248** - Motor FLC single-phase
15. **NEC Table 430.250** - Motor FLC three-phase
16. **NEC Table 430.52** - Motor branch circuit protection

---

## EDITION DIFFERENCES AFFECTING CALCULATORS

### Critical Changes Between Editions:

| Calculator | 2017 | 2020 | 2023 | Notes |
|------------|------|------|------|-------|
| GFCI Requirements | Art 210.8 | Expanded | All kitchen | Check edition |
| Surge Protection | Optional | Required 230.67 | Expanded | Dwelling service |
| Box Fill (EGC) | Per 314.16(B)(5) | Same | Revised | EBJ now counted |
| Emergency Disconnect | Not required | Required | Required | Outdoor service |
| Table 310.16 | Table 310.15(B)(16) | Same | Renamed 310.16 | Table renumbered |
| Definitions | Throughout code | Same | All in Art 100 | Location changed |

### When Edition Matters Most:

1. **GFCI calculations** - 2023 requires all kitchen receptacles
2. **Surge protection** - 2020+ requires at dwelling service
3. **Service disconnects** - 2020+ requires outdoor emergency disconnect
4. **Table references** - 2023 renumbered several tables

---

## SOURCES

### Official Sources
- [NFPA 70 - National Electrical Code](https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70)
- [Mike Holt NEC Adoption List](https://www.mikeholt.com/necadoptionlist.php)
- [IAEI NEC Adoption Map](https://www.iaei.org/page/nec-code-adoption)

### Reference Sources
- [Jade Learning - NEC Adoptions by State](https://www.jadelearning.com/nec-code-adoptions-by-state/)
- [EC&M - NEC Changes](https://www.ecmweb.com/national-electrical-code)
- [ExpertCE - NEC Formulas](https://expertce.com/learn-articles/)

### Calculator Sources
- [Voltage Drop Calculator](https://voltagedropcalculator.net/)
- [Box Fill Calculator](https://boxfillcalculator.com/)
- [EleCalculator](https://elecalculator.com/)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| NEC Adoption by State | [VERIFIED] | Feb 1, 2026 |
| Voltage Drop Formulas | [VERIFIED] | Feb 1, 2026 |
| Wire Sizing/Ampacity | [VERIFIED] | Feb 1, 2026 |
| Box Fill Formulas | [VERIFIED] | Feb 1, 2026 |
| Conduit Fill | [VERIFIED] | Feb 1, 2026 |
| Dwelling Calculations | [VERIFIED] | Feb 1, 2026 |
| Motor Calculations | [VERIFIED] | Feb 1, 2026 |
| GFCI/AFCI Requirements | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [NEEDS VERIFICATION] | — |

---

*This file is the master intelligence source for ZAFTO Electrical calculators.*
*Always check state-specific NEC edition before applying formulas.*
