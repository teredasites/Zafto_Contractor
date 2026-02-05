# SOLAR TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Solar PV Installation |
| ZAFTO Calculators | 92 |
| Primary Code | NEC Articles 690, 705, 706 |
| Publisher | NFPA |
| Update Cycle | Every 3 years |
| Current Edition | NEC 2023 |
| Editions Still in Use | 2014, 2017, 2020, 2023 |
| Certification | NABCEP (industry standard) |

---

## GOVERNING CODES & STANDARDS

### NEC Articles for Solar

| Article | Title | Scope |
|---------|-------|-------|
| **690** | Solar Photovoltaic (PV) Systems | Primary PV requirements |
| **705** | Interconnected Electric Power Production Sources | Grid interconnection |
| **706** | Energy Storage Systems (ESS) | Battery/storage systems |
| **710** | Stand-Alone Systems | Off-grid systems |
| **712** | Direct Current Microgrids | DC microgrid requirements |

### NEC 690 Section Breakdown

| Section | Topic |
|---------|-------|
| 690.7 | Maximum Voltage |
| 690.8 | Circuit Sizing and Current |
| 690.9 | Overcurrent Protection |
| 690.12 | Rapid Shutdown |
| 690.13 | PV Disconnecting Means |
| 690.31 | Wiring Methods |
| 690.41 | System Grounding |
| 690.47 | Grounding Electrode System |

### Key Changes by NEC Edition

| Edition | Major Changes |
|---------|---------------|
| **2023** | 1500V systems in 690.31(G), string circuit terminology, ESS commissioning |
| **2020** | Rapid shutdown 30-second timer, hazard control system |
| **2017** | Rapid shutdown inside array boundary, module-level requirement |
| **2014** | Arc-fault protection, ground-fault detection expansion |

### Other Standards

| Standard | Publisher | Scope |
|----------|-----------|-------|
| UL 1703 | UL | Flat-plate PV modules |
| UL 1741 | UL | Inverters, converters |
| UL 9540 | UL | Energy storage systems |
| IEEE 1547 | IEEE | Interconnection standard |
| IEC 61215 | IEC | Module design qualification |
| IEC 61730 | IEC | Module safety qualification |

---

## CODE ADOPTION BY STATE

**Solar uses NEC adoption - see Electrical INTEL for complete state table**

### States with Solar-Specific Requirements

| State | Additional Requirements | Notes |
|-------|------------------------|-------|
| California | Title 24, NEM 3.0, Fire setbacks | Most stringent |
| Arizona | Utility interconnection standards | APS, SRP requirements |
| Florida | Permit fee caps, HOA preemption | Net metering rules |
| Hawaii | Grid supply rules, NEM phase-out | High penetration issues |
| Massachusetts | SMART program requirements | Incentive-tied |
| New York | NY-Sun requirements | Incentive programs |
| Texas | Varies by utility territory | ERCOT, AEP, Oncor rules |
| Nevada | Net metering, permit streamlining | NV Energy rules |
| Colorado | Community solar rules | Xcel requirements |
| New Jersey | SREC market, permit streamlining | Strong incentives |

### Fire Setback Requirements (Varies by Jurisdiction)

| Jurisdiction | Ridge Setback | Pathway Width | Access Width |
|--------------|---------------|---------------|--------------|
| California (CFC) | 3 ft | 3 ft | 4 ft |
| IFC Model | 3 ft | 3 ft | 4 ft |
| Some Local | 18 in | 3 ft | 3 ft |

---

## KEY FORMULAS FOR CALCULATORS

### 1. STRING SIZING - MAXIMUM (Cold Weather)

**Purpose:** Prevent exceeding inverter maximum input voltage

**Step 1 - Temperature-Corrected Module Voc:**
```
Voc_max = Voc_stc × [1 + ((T_min - 25) × (Tk_voc / 100))]

Where:
Voc_stc = Module open-circuit voltage at STC (from spec sheet)
T_min = Minimum expected temperature (°C)
Tk_voc = Temperature coefficient of Voc (%/°C, negative value)
25 = STC temperature (°C)
```

**Step 2 - Maximum Modules per String:**
```
Max_modules = Inverter_Vmax / Voc_max

Round DOWN to nearest whole number
```

**Example:**
```
Module Voc: 40.5V
Tk_voc: -0.29%/°C
Min temp: -10°C
Inverter max: 500V

Voc_max = 40.5 × [1 + ((-10 - 25) × (-0.29/100))]
Voc_max = 40.5 × [1 + ((-35) × (-0.0029))]
Voc_max = 40.5 × 1.1015 = 44.6V

Max modules = 500 / 44.6 = 11.2 → 11 modules max
```

---

### 2. STRING SIZING - MINIMUM (Hot Weather)

**Purpose:** Ensure voltage stays above inverter minimum for MPPT operation

**Step 1 - Temperature-Corrected Module Vmp:**
```
Vmp_min = Vmp_stc × [1 + ((T_max + T_adder - 25) × (Tk_vmp / 100))]

Where:
Vmp_stc = Module max power voltage at STC
T_max = Maximum expected ambient temperature (°C)
T_adder = Installation adder (see below)
Tk_vmp = Temperature coefficient of Vmp (%/°C)
```

**Temperature Adders:**
| Mount Type | Adder |
|------------|-------|
| Ground mount | +25°C |
| Rack mount (>6" standoff) | +30°C |
| Flush mount (<6" standoff) | +35°C |
| BIPV (integrated) | +40°C |

**Step 2 - Minimum Modules per String:**
```
Min_modules = Inverter_Vmin / Vmp_min

Round UP to nearest whole number
```

---

### 3. CURRENT CALCULATIONS (NEC 690.8)

**Maximum Circuit Current:**
```
Imax = Isc × 1.25

Where:
Isc = Module short-circuit current
1.25 = 125% factor for irradiance above STC
```

**Conductor Sizing (Continuous Load):**
```
Required_Ampacity = Imax × 1.25 = Isc × 1.56

Where:
1.56 = 1.25 × 1.25 (irradiance factor × continuous load factor)
```

**With Temperature Correction:**
```
Adjusted_Ampacity = Required_Ampacity / Temperature_Correction_Factor

From NEC Table 310.15(B)(1) based on conductor temperature rating and ambient
```

**Example:**
```
Module Isc: 11.5A
Ambient temp: 50°C (122°F)
Using 90°C conductor (correction factor 0.82)

Required = 11.5 × 1.56 = 17.94A
Adjusted = 17.94 / 0.82 = 21.9A minimum ampacity needed
```

---

### 4. VOLTAGE DROP CALCULATIONS

**DC Circuit Voltage Drop:**
```
VD = (2 × K × I × L) / CM

Same formula as NEC for DC circuits

Where:
K = 12.9 (copper) or 21.2 (aluminum)
I = Operating current (Imp)
L = One-way length (feet)
CM = Circular mils
```

**Recommended Limits:**
- PV source circuits: 2% max
- PV output circuits: 1% max
- Total DC side: 3% max
- AC output: 2% max

**Percentage Calculation:**
```
VD% = (VD / System_Voltage) × 100
```

---

### 5. SYSTEM SIZING / PRODUCTION

**Array Size Calculation:**
```
Array_kW = Annual_kWh_needed / (PSH × 365 × Derate)

Where:
Annual_kWh_needed = Customer's annual consumption
PSH = Peak sun hours per day (location-dependent)
Derate = System derate factor (typically 0.77-0.85)
```

**Number of Modules:**
```
Modules = Array_kW × 1000 / Module_Wattage
```

**Annual Production Estimate:**
```
kWh/year = Array_kW × PSH × 365 × Derate
```

**Peak Sun Hours by Region:**
| Region | PSH Range |
|--------|-----------|
| Southwest (AZ, NV, CA) | 5.5-7.0 |
| Southeast (FL, GA) | 4.5-5.5 |
| Midwest | 4.0-5.0 |
| Northeast | 3.5-4.5 |
| Northwest | 3.0-4.5 |

**System Derate Factors:**

| Loss Type | Typical % |
|-----------|-----------|
| Module nameplate | 1-3% |
| Inverter efficiency | 2-5% |
| DC wiring | 1-3% |
| AC wiring | 0.5-1% |
| Soiling | 2-5% |
| Shading | 0-15% |
| Temperature | 3-10% |
| Mismatch | 1-2% |
| **Total Derate** | **15-23%** |

---

### 6. INVERTER SIZING

**DC/AC Ratio:**
```
DC_AC_Ratio = Array_DC_kW / Inverter_AC_kW

Typical range: 1.1 to 1.3
Higher ratios = more clipping but better low-light performance
```

**Maximum Input Current Check:**
```
Total_Isc = Strings_in_parallel × Module_Isc × 1.25

Must be ≤ Inverter_max_input_current
```

**MPPT Sizing:**
```
Each MPPT input:
- Check voltage window (Vmp range)
- Check current limit
- Match modules with same orientation per MPPT
```

---

### 7. ENERGY STORAGE (NEC 706)

**Battery Bank Sizing:**
```
Bank_capacity_kWh = (Daily_load_kWh × Days_autonomy) / (DoD × Efficiency)

Where:
DoD = Depth of discharge (typically 80% for lithium, 50% for lead-acid)
Efficiency = Round-trip efficiency (90-95% lithium, 80-85% lead-acid)
```

**Inverter/Charger Sizing:**
```
Min_inverter_kW = Peak_load_kW × 1.25

Must handle surge loads (motors, etc.)
```

**Charge Controller Sizing:**
```
Controller_amps = Array_Isc × 1.25 × Number_of_strings
```

---

### 8. INTERCONNECTION (NEC 705.12)

**120% Rule (Load Side Connection):**
```
Max_PV_breaker = (Busbar_rating × 1.20) - Main_breaker

Example:
200A panel, 200A main
Max_PV = (200 × 1.20) - 200 = 40A PV breaker max
```

**Supply Side Connection:**
```
No 120% limitation
Must meet 705.12(B) requirements
Service entrance rated equipment required
```

**Line Side Tap:**
```
Requires utility approval
Must meet tap rules per 705.12(B)(2)
```

---

### 9. RAPID SHUTDOWN (NEC 690.12)

**2017 NEC Requirements:**
- Controlled conductors outside array boundary: 30V within 30 seconds
- Inside array boundary: Module-level shutdown required

**2020/2023 NEC Requirements:**
- Array boundary = 1 ft from array
- 80V limit within array boundary (within 30 sec)
- 30V limit outside array boundary (within 30 sec)
- Initiation at service disconnect or readily accessible location

**Compliant Methods:**
1. Module-level power electronics (MLPE) - microinverters, DC optimizers
2. PV Hazard Control System (PVHCS)
3. Listed rapid shutdown equipment

---

### 10. GROUND-FAULT & ARC-FAULT

**Ground-Fault Protection (690.41):**
```
Required for:
- Ground-mounted arrays
- Rooftop with grounded conductors
- Systems >30V

Detection level: Varies by system size
Typically 1-5A fault current threshold
```

**Arc-Fault Protection (690.11):**
```
Required for DC circuits on buildings
Listed DC arc-fault protection required
Can be at inverter or in combiner
```

---

## LICENSING & CERTIFICATION

### NABCEP Certifications

| Certification | Requirements | Validity |
|---------------|--------------|----------|
| PV Installation Professional (PVIP) | 58hr training + experience + exam | 3 years |
| PV Design Specialist | Training + experience + exam | 3 years |
| PV Technical Sales Professional | Training + exam | 3 years |
| PV System Inspector | Training + experience + exam | 3 years |
| PV Installer Specialist | Entry-level, training + exam | 3 years |

### State Licensing Requirements

| State | License Type | NABCEP Status | Notes |
|-------|--------------|---------------|-------|
| Arizona | ROC contractor | Recommended | C-11 classification |
| California | C-46 Solar | Required for rebates | Also C-10 for electrical |
| Colorado | Electrical license | Recommended | Denver separate |
| Florida | EC or solar specialty | Required | With utility interconnection |
| Hawaii | C-60 Solar Energy | Required | |
| Illinois | Distributed Generation | NABCEP pathway | Required for installation |
| Maine | Electrician + solar | Required for incentives | |
| Massachusetts | Electrician | Required for incentives | |
| Minnesota | Electrician | Required for incentives | NABCEP for Xcel rebates |
| Nevada | C-2G classification | Recommended | |
| New Jersey | Electrical contractor | Recommended | |
| New York | Varies by jurisdiction | Recommended | NYC separate |
| North Carolina | Unlimited electrical | Required | |
| Texas | Licensed electrician | Required | TDLR |
| Utah | S202 Solar PV | NABCEP required | For state license |
| Washington | Electrical (06) | Required | |
| Wisconsin | Electrician | Required for incentives | |

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Temperature Correction Factors** - NEC Table 690.7(A)
2. **Wire Ampacity by Temperature** - NEC 310.16 for solar
3. **Conduit Fill** - Standard NEC tables
4. **String Sizing Worksheet** - Min/max calculations
5. **Voltage Drop Tables** - By wire gauge and length
6. **Peak Sun Hours by Location** - NREL data
7. **System Derate Factors** - By component
8. **Fire Setback Requirements** - By jurisdiction
9. **Rapid Shutdown Requirements** - By NEC edition
10. **Battery Sizing Tables** - By technology type

---

## UTILITY INTERCONNECTION REQUIREMENTS

### Common Utility Requirements

| Requirement | Typical Standard |
|-------------|------------------|
| Anti-islanding | UL 1741 / IEEE 1547 |
| Power factor | 0.90 or better |
| Voltage range | ±5% of nominal |
| Frequency range | 59.3-60.5 Hz |
| DC injection | <0.5% of rated current |
| Harmonics | IEEE 519 limits |

### Net Metering Status by State

| Category | States |
|----------|--------|
| Full retail NEM | Most states |
| Reduced NEM | CA (NEM 3.0), HI, NV |
| No statewide NEM | TX, TN, others |
| VDER/Value-based | NY |

---

## SOURCES

### Official Sources
- [NFPA 70 - NEC](https://www.nfpa.org/)
- [NABCEP Certification](https://www.nabcep.org/)
- [NREL PVWatts](https://pvwatts.nrel.gov/)
- [DSIRE Database](https://www.dsireusa.org/)

### Reference Sources
- [Mayfield Renewables - String Sizing](https://www.mayfield.energy/)
- [Solar Permit Solutions](https://www.solarpermitsolutions.com/)
- [GreenLancer - Solar Guides](https://www.greenlancer.com/)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| NEC 690 Requirements | [VERIFIED] | Feb 1, 2026 |
| String Sizing Formulas | [VERIFIED] | Feb 1, 2026 |
| Current Calculations | [VERIFIED] | Feb 1, 2026 |
| Voltage Drop | [VERIFIED] | Feb 1, 2026 |
| System Sizing | [VERIFIED] | Feb 1, 2026 |
| Storage (706) | [VERIFIED] | Feb 1, 2026 |
| Interconnection (705) | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [NEEDS VERIFICATION] | — |

---

*This file is the master intelligence source for ZAFTO Solar calculators.*
*Always verify NEC edition adopted by state and utility interconnection requirements.*
