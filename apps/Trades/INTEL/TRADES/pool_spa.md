# POOL & SPA TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Pool & Spa (Swimming Pool Contractor) |
| ZAFTO Calculators | 54 |
| Primary Codes | NEC Article 680, IRC Appendix G, IBC Chapter 31 |
| Secondary | State/Local Health Codes, APSP/ICC |
| Certifications | CPO (Certified Pool Operator), CBP (Certified Building Professional) |

---

## GOVERNING CODES & STANDARDS

### NEC Article 680 - Swimming Pools, Fountains, and Similar Installations

| Section | Topic |
|---------|-------|
| 680.1 | Scope |
| 680.2 | Definitions |
| 680.21 | Motors |
| 680.22 | Area lighting, receptacles, switching |
| 680.23 | Underwater luminaires |
| 680.24 | Junction boxes/enclosures |
| 680.25 | Feeders |
| 680.26 | Equipotential bonding |
| 680.27 | Specialized pool equipment |

### NEC 680 Edition Variations

| Edition | Key Changes |
|---------|-------------|
| NEC 2023 | GFCI requirements expanded |
| NEC 2020 | 680.26 bonding clarified |
| NEC 2017 | Listed bonding conductors |
| NEC 2014 | Barrier/cover requirements |

### IRC Appendix G - Swimming Pools, Spas, and Hot Tubs

| Section | Topic |
|---------|-------|
| AG101 | General |
| AG102 | Definitions |
| AG103 | Spas and hot tubs |
| AG104 | Barriers |
| AG105 | Entrapment protection |
| AG106 | Suction outlet requirements |

### APSP/ICC Standards (Now PHTA)

| Standard | Title |
|----------|-------|
| ANSI/APSP-1 | Public Swimming Pools |
| ANSI/APSP-2 | Public Spas |
| ANSI/APSP-3 | Permanently Installed Residential Spas |
| ANSI/APSP-4 | Above-ground/On-ground Pools |
| ANSI/APSP-5 | Residential Inground Pools |
| ANSI/APSP-7 | Suction Entrapment Avoidance |
| ANSI/APSP-15 | Residential Hot Tubs |

### Virginia Graeme Baker Act (Federal)

| Requirement | Details |
|-------------|---------|
| Applies to | Public pools and spas |
| Requirement | ANSI/APSP-16 compliant drain covers |
| Effective | December 19, 2008 |
| Enforcement | CPSC |

---

## NEC 680 KEY REQUIREMENTS

### Equipotential Bonding (680.26)

**Bonded Items:**
```
- Conductive pool shell (poured/gunite)
- Perimeter surfaces (3 feet)
- Metallic components (within 5 feet)
- Metal fittings
- Electrical equipment
- Metal parts of pool structure
- Metal parts of pool cover
- Forming shells
- Metal deck boxes
```

**Bonding Conductor:**
```
Minimum: 8 AWG solid copper

Bonding grid (perimeter surface):
- #8 AWG copper
- Within 18-24" of pool edge
- Or listed bonding assembly

Connection: Listed compression, exothermic, or listed
```

**Pool Water Bonding:**
```
Required per 680.26(C)
Methods:
- Conductive pool shell (grounded)
- Listed equipment with water bonding
- Listed components for water contact
```

### GFCI Protection Requirements

**Receptacles:**
```
Within 20 feet of pool/spa:
- GFCI protected
- No closer than 6 feet from water's edge
- At least one 125V receptacle 6-20 feet from edge
```

**Equipment:**
```
GFCI required for:
- Pool pump motors
- All 120V equipment within 20 feet
- Underwater luminaires (except >15V listed)
- Cord-connected pool equipment
```

### Wiring Methods

**Underground:**
```
Minimum burial:
- Rigid metal conduit: 6"
- IMC: 6"
- PVC/RTRC: 18"
- Type UF: 18"
Under concrete: 6" below slab
```

**Motor Connections:**
```
Junction box: 4" minimum above deck
Or: Elevated location approved
Listed motor cord allowed where applicable
```

### Underwater Luminaires

**Voltage Limits:**
```
Low voltage (15V or less): No GFCI required if listed
Over 15V: GFCI required
Transformer: Listed for pool use
```

**Forming Shell:**
```
No-niche: Listed assemblies
Wet-niche: Forming shell grounded/bonded
Dry-niche: Must be accessible
```

---

## BARRIER REQUIREMENTS (IRC App G)

### Residential Pool Barriers

**Fence/Wall Height:**
```
Minimum: 48 inches (4 feet)
Measured from: Finished grade (outside)
```

**Fence Construction:**
```
Opening limit: Cannot pass 4" sphere
Solid fence: No openings >1/4" (if climbable)
Chain link: Max 1-3/4" diamond openings

No footholds 45" from grade
```

**Gate Requirements:**
```
Self-closing: Yes
Self-latching: Yes
Latch release: 54" minimum from grade (exterior)
           Or: 3" below top on pool side
Opens: Away from pool (outward)
```

**House as Barrier:**
```
Door to pool: Alarm required
Alarm: Sound for 20 seconds minimum
Deactivation: Can be up to 15 seconds delay
```

---

## KEY FORMULAS FOR CALCULATORS

### 1. POOL VOLUME CALCULATIONS

**Rectangular Pool:**
```
Gallons = Length × Width × Average Depth × 7.5

Example:
40' × 20' × 5' average = 40 × 20 × 5 × 7.5 = 30,000 gallons
```

**Circular Pool:**
```
Gallons = π × Radius² × Average Depth × 7.5

Or: Diameter² × Average Depth × 5.9

Example:
24' diameter × 4' = 24² × 4 × 5.9 = 13,594 gallons
```

**Oval Pool:**
```
Gallons = Length × Width × Average Depth × 5.9

(Uses 5.9 instead of 7.5 due to shape)
```

**Kidney/Freeform Pool:**
```
Approximate: (L × W × 0.85) × Depth × 7.5

Or: Calculate by sections and sum
```

**Average Depth (Sloped Bottom):**
```
Average Depth = (Shallow End + Deep End) / 2

Example: 3' to 8' = (3 + 8) / 2 = 5.5' average
```

---

### 2. TURNOVER RATE & PUMP SIZING

**Turnover Time:**
```
Residential: 8-12 hours typical
Commercial: 6-8 hours (or per code)
Spa: 30 minutes

Flow Rate (GPM) = Pool Gallons / (Turnover Hours × 60)

Example:
30,000 gallons / (8 hours × 60) = 62.5 GPM required
```

**Pump Sizing:**
```
Pump must deliver required GPM at system head

System head = Static head + Friction loss + Equipment losses
```

**Piping Velocity:**
```
Suction: 6 fps maximum (8 fps code max)
Return: 8-10 fps

GPM = Flow velocity (fps) × Pipe area (sq ft) × 448.8

Flow by pipe size (at 6 fps):
- 1.5" pipe: ~35 GPM
- 2" pipe: ~60 GPM
- 2.5" pipe: ~95 GPM
- 3" pipe: ~140 GPM
```

---

### 3. FILTER SIZING

**Filter Flow Rate:**
```
Filter capacity ≥ Required GPM × 1.5 (safety factor)

Or: Design flow = Pool volume / (Turnover × 60)
```

**Filter Types:**
| Type | Flow Rate | Filtration |
|------|-----------|------------|
| Sand | 15-20 GPM/SF | 20-40 microns |
| Cartridge | 0.375 GPM/SF | 10-20 microns |
| DE | 1-2 GPM/SF | 3-5 microns |

**Filter Area Calculation:**
```
Sand: Area (SF) = GPM / 15
Cartridge: Area (SF) = GPM / 0.375
DE: Area (SF) = GPM / 1.5
```

---

### 4. HEATER SIZING

**BTU Requirement:**
```
BTU/hr = Pool Gallons × 8.34 × ΔT / Desired hours

Where:
8.34 = lbs per gallon of water
ΔT = Temperature rise desired

Example:
20,000 gal × 8.34 × 20°F rise / 12 hours = 278,000 BTU
```

**Rough Sizing Rules:**
```
50 BTU per gallon (for reasonable rise time)

Or: Surface area × 12 BTU (per SF, per degree rise, per hour)
```

**Gas Heater Sizing:**
| Pool Volume | Heater Size |
|-------------|-------------|
| 10,000 gal | 150,000-200,000 BTU |
| 20,000 gal | 250,000-400,000 BTU |
| 40,000 gal | 400,000+ BTU |

**Heat Pump (Electric):**
```
Sizing similar but rated in BTU output
COP (efficiency) = Output BTU / Input BTU
Typical COP: 5-7
```

---

### 5. CHEMICAL CALCULATIONS

**Chlorine Dosing:**
```
Pounds = (Pool Gallons × ppm desired) / 10,000 × Factor

Factors:
- Calcium hypochlorite (67%): 1.5
- Sodium hypochlorite (12%): 10.5 (liquid oz per 10k gal)
- Trichlor (90%): 1.1
```

**pH Adjustment:**
```
Muriatic acid (to lower pH):
Gallons = Pool volume / 10,000 × Acid factor

Soda ash (to raise pH):
Pounds = Pool volume / 10,000 × Factor
```

**Alkalinity Adjustment:**
```
Baking soda (sodium bicarbonate):
1.5 lbs per 10,000 gallons raises TA by 10 ppm
```

**Calcium Hardness:**
```
Calcium chloride:
1.25 lbs per 10,000 gallons raises CH by 10 ppm
```

**Cyanuric Acid (Stabilizer):**
```
1.3 lbs per 10,000 gallons raises CYA by 10 ppm
```

---

### 6. WATER CHEMISTRY TARGETS

**Ideal Ranges:**
| Parameter | Pools | Spas |
|-----------|-------|------|
| Free Chlorine | 1-3 ppm | 2-4 ppm |
| Combined Chlorine | <0.5 ppm | <0.5 ppm |
| pH | 7.2-7.6 | 7.2-7.6 |
| Total Alkalinity | 80-120 ppm | 80-120 ppm |
| Calcium Hardness | 200-400 ppm | 150-250 ppm |
| Cyanuric Acid | 30-50 ppm | 30-50 ppm |
| Total Dissolved Solids | <2000 ppm | <1500 ppm |

**Saturation Index (Langelier):**
```
LSI = pH - pHs

pHs = (9.3 + A + B) - (C + D)

Where:
A = (Log(TDS) - 1) / 10
B = -13.12 × Log(°C + 273) + 34.55
C = Log(Calcium Hardness) - 0.4
D = Log(Alkalinity)

Target LSI: -0.3 to +0.3
```

---

### 7. ELECTRICAL LOAD CALCULATIONS

**Pool Equipment Loads:**
| Equipment | Typical Load |
|-----------|--------------|
| Pool pump (1 HP) | 1,500 W |
| Pool pump (1.5 HP) | 2,200 W |
| Pool pump (2 HP) | 2,800 W |
| Variable speed pump | 300-2,400 W |
| Heater (gas) | 400 W (blower) |
| Heat pump | 4,000-7,000 W |
| Salt cell | 200-400 W |
| Pool light | 300-500 W |
| Automatic cleaner | 200-1,500 W |

**Circuit Requirements:**
```
Pool pump: Dedicated circuit, GFCI protected
Heater: May require larger circuit (check nameplate)
Lights: Branch circuit, transformer for low voltage
```

---

### 8. PLUMBING CALCULATIONS

**Friction Loss:**
```
Use Hazen-Williams or equivalent
C value for PVC: 150
C value for copper: 130

Higher flow = More friction loss
```

**Approximate Friction Loss (PVC Schedule 40):**
| Pipe Size | 30 GPM | 60 GPM | 100 GPM |
|-----------|--------|--------|---------|
| 1.5" | 3.5' per 100' | 12' per 100' | N/A |
| 2" | 1.2' per 100' | 4' per 100' | 10' per 100' |
| 3" | 0.3' per 100' | 0.8' per 100' | 2' per 100' |

**Total Dynamic Head (TDH):**
```
TDH = Static lift + Friction loss + Equipment loss

Equipment losses (estimated):
- Filter (clean): 5-10 feet
- Heater: 3-5 feet
- Salt cell: 2-5 feet
- Fittings: 1-2 feet each elbow
```

---

### 9. GUNITE/SHOTCRETE CALCULATIONS

**Shell Volume:**
```
CY = (Surface Area × Thickness) / 27

Typical thickness: 6-9 inches (0.5-0.75 feet)
```

**Surface Area (Rectangular):**
```
SA = Floor + Walls

Floor = L × W
Walls = 2(L × D) + 2(W × D)
```

**Rebar Quantity:**
```
#3 @ 12" OC both ways typical

Bars = (Dimension / Spacing) + 1
Add lap splices: 40 × diameter
```

**Plaster Coverage:**
```
50 lb bag covers: 40-50 SF
Cubic yards per 100 SF (at 1/2" thick): 0.15 CY
```

---

### 10. DECK AREA CALCULATIONS

**Deck Square Footage:**
```
Total area - Pool footprint = Deck area
```

**Concrete Volume:**
```
CY = (Deck SF × Thickness) / 324

Standard deck: 4" thick minimum
Pool deck: Often 5-6" thick
```

**Coping Linear Feet:**
```
LF = Pool perimeter
Add 10% for waste/cuts
```

---

### 11. SPA SPECIFICS

**Spa Volume:**
```
Gallons = Length × Width × Depth × 7.5

Typical spa: 400-800 gallons
```

**Spa Turnover:**
```
Required: 30 minutes (complete turnover)
Flow rate = Gallons / 30 = GPM required

Example: 500 gallons / 30 = 16.7 GPM
```

**Jets:**
```
Typical flow per jet: 12-15 GPM
Multiple jets share pump capacity
```

**Temperature:**
```
Maximum: 104°F (per CPSC guidance)
Typical operation: 100-102°F
```

---

## LICENSING REQUIREMENTS BY STATE

| State | Pool Contractor License | Type | Notes |
|-------|------------------------|------|-------|
| Alabama | Yes | Swimming Pool Contractor | |
| Alaska | No state | General may apply | |
| Arizona | Yes | A-11, B-5 | ROC License |
| Arkansas | No state | | |
| California | Yes | C-53 Swimming Pool | CSLB |
| Colorado | No state | Local varies | |
| Connecticut | HIC | Home improvement | |
| Delaware | Yes | | |
| Florida | Yes | CPC (Certified Pool) | State license |
| Georgia | Yes | Pool Contractor | |
| Hawaii | Yes | C-57 | |
| Idaho | No state | Registration | |
| Illinois | No state | Local varies | |
| Indiana | No state | | |
| Iowa | No state | | |
| Kansas | No state | | |
| Kentucky | No state | | |
| Louisiana | Yes | Pool contractor | |
| Maine | No state | | |
| Maryland | MHIC | | |
| Massachusetts | HIC | | |
| Michigan | Yes | Residential Builder | |
| Minnesota | Yes | | |
| Mississippi | Yes | >$50k | |
| Missouri | No state | Local varies | |
| Montana | No state | | |
| Nebraska | No state | | |
| Nevada | Yes | A-10, C-10 | Pool/Spa specialty |
| New Hampshire | No state | | |
| New Jersey | Yes | HIC + Pool specialty | |
| New Mexico | Yes | GB-2 | |
| New York | No state | Local varies | |
| North Carolina | Yes | Swimming Pool | |
| North Dakota | No state | | |
| Ohio | No state | Local varies | |
| Oklahoma | No state | | |
| Oregon | Yes | CCB | |
| Pennsylvania | No state | Local varies | |
| Rhode Island | Yes | | |
| South Carolina | Yes | Pool builder | |
| South Dakota | No state | | |
| Tennessee | Yes | Pool contractor | |
| Texas | No state | Local varies | |
| Utah | Yes | E-100, S-310 | |
| Vermont | No state | | |
| Virginia | Yes | Class A, B | |
| Washington | Yes | Specialty | |
| West Virginia | No state | | |
| Wisconsin | No state | | |
| Wyoming | No state | | |

---

## CERTIFICATIONS

### CPO (Certified Pool Operator)

| Item | Details |
|------|---------|
| Provider | Pool & Hot Tub Alliance |
| Duration | 5 years |
| Renewal | Re-exam or continuing education |
| Scope | Water chemistry, operations, health codes |
| Required | Many jurisdictions for commercial pools |

### Other Certifications

| Certification | Provider | Scope |
|---------------|----------|-------|
| AFO (Aquatic Facility Operator) | NRPA | Operations |
| CBP (Certified Building Professional) | PHTA | Construction |
| CMS (Certified Maintenance Specialist) | PHTA | Service |
| CSP (Certified Service Professional) | PHTA | Service/Repair |

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Pool Volume Calculator** - All shapes
2. **Pump Sizing Calculator** - GPM by turnover
3. **Filter Sizing Calculator** - By type
4. **Heater BTU Calculator** - By volume/temp rise
5. **Chemical Dosing Calculator** - All chemicals
6. **Water Balance Calculator** - Saturation index
7. **Friction Loss Calculator** - TDH
8. **Equipment Load Calculator** - Electrical
9. **Concrete/Gunite Calculator** - Shell volume
10. **Spa Calculator** - Volume and turnover

---

## SOURCES

### Official Sources
- [NFPA 70 - NEC Article 680](https://www.nfpa.org/)
- [ICC - IRC Appendix G](https://www.iccsafe.org/)
- [PHTA (Pool & Hot Tub Alliance)](https://www.phta.org/)
- [CPSC - Pool Safety](https://www.cpsc.gov/safety-education/safety-guides/pools-and-spas)

### Reference Sources
- [Pool & Spa News](https://www.poolspanews.com/)
- [Orenda Technologies (Chemistry)](https://www.orendatech.com/)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| Pool Volume Formulas | [VERIFIED] | Feb 1, 2026 |
| NEC 680 Requirements | [VERIFIED] | Feb 1, 2026 |
| Barrier Requirements | [VERIFIED - IRC] | Feb 1, 2026 |
| Chemical Calculations | [VERIFIED] | Feb 1, 2026 |
| Turnover/Pump Sizing | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [NEEDS VERIFICATION] | — |

---

*This file is the master intelligence source for ZAFTO Pool & Spa calculators.*
*NEC Article 680 bonding and GFCI requirements are critical safety items.*
