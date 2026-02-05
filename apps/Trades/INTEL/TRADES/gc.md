# GENERAL CONTRACTOR TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | General Contractor (GC) |
| ZAFTO Calculators | 101 |
| Primary Codes | IRC (Residential), IBC (Commercial) |
| Secondary | OSHA 29 CFR 1926 (Construction Safety) |
| Publisher | ICC |
| Update Cycle | Every 3 years |
| Current Editions | IRC 2024, IBC 2024 |
| Editions Still in Use | 2012, 2015, 2018, 2021, 2024 |

---

## GOVERNING CODES & STANDARDS

### International Residential Code (IRC)

| Chapter | Topic |
|---------|-------|
| 1-2 | Administration, Definitions |
| 3 | Building Planning |
| 4 | Foundations |
| 5 | Floors |
| 6 | Wall Construction |
| 7 | Wall Covering |
| 8 | Roof-Ceiling Construction |
| 9 | Roof Assemblies |
| 10 | Chimneys & Fireplaces |
| 11 | Energy Efficiency |

### International Building Code (IBC)

| Chapter | Topic |
|---------|-------|
| 1-2 | Administration, Definitions |
| 3-6 | Use Groups, Heights, Construction Types |
| 7-10 | Fire, Interior Finish, Fire Protection |
| 11-12 | Accessibility, Interior Environment |
| 13-15 | Energy, Exterior Walls, Roof |
| 16-19 | Structural Design, Special Inspections |
| 20-26 | Aluminum, Masonry, Wood, Glass, Gypsum, Plastics |
| 27-34 | Electrical, Mechanical, Plumbing, Elevators |

### OSHA Construction Standards (29 CFR 1926)

| Subpart | Topic |
|---------|-------|
| C | General Safety & Health |
| D | Occupational Health & Environmental Controls |
| E | Personal Protective Equipment |
| F | Fire Protection |
| H | Materials Handling |
| I | Tools (Hand & Power) |
| J | Welding & Cutting |
| K | Electrical |
| L | Scaffolds |
| M | Fall Protection |
| N | Cranes & Derricks |
| O | Motor Vehicles |
| P | Excavations |
| Q | Concrete & Masonry |
| R | Steel Erection |
| X | Stairways & Ladders |

---

## IRC/IBC ADOPTION BY STATE

| State | Residential Code | Edition | Commercial Code | Edition |
|-------|------------------|---------|-----------------|---------|
| Alabama | IRC | 2021 | IBC | 2021 |
| Alaska | IRC | 2018 | IBC | 2018 |
| Arizona | IRC | Local | IBC | Local |
| Arkansas | IRC | 2021 | IBC | 2021 |
| California | CBC (IRC-based) | 2022 | CBC (IBC-based) | 2022 |
| Colorado | IRC | 2021 | IBC | 2021 |
| Connecticut | IRC | 2021 | IBC | 2021 |
| Delaware | IRC | 2018 | IBC | 2018 |
| DC | IRC | 2018 | IBC | 2018 |
| Florida | FBC-R | 8th Ed | FBC-B | 8th Ed |
| Georgia | IRC | 2021 | IBC | 2021 |
| Hawaii | IRC | 2018 | IBC | 2018 |
| Idaho | IRC | 2021 | IBC | 2021 |
| Illinois | IRC | Local | IBC | Local |
| Indiana | IRC | 2018 | IBC | 2018 |
| Iowa | IRC | 2021 | IBC | 2021 |
| Kansas | IRC | Local | IBC | Local |
| Kentucky | IRC | 2018 | IBC | 2018 |
| Louisiana | IRC | 2021 | IBC | 2021 |
| Maine | IRC | 2021 | IBC | 2021 |
| Maryland | IRC | 2021 | IBC | 2021 |
| Massachusetts | IRC | 2021 | IBC | 2021 |
| Michigan | IRC | 2021 | IBC | 2021 |
| Minnesota | MN Res Code | 2020 | MN Building Code | 2020 |
| Mississippi | IRC | Local | IBC | Local |
| Missouri | IRC | Local | IBC | Local |
| Montana | IRC | 2021 | IBC | 2021 |
| Nebraska | IRC | Local | IBC | Local |
| Nevada | IRC | Local | IBC | Local |
| New Hampshire | IRC | 2018 | IBC | 2018 |
| New Jersey | IRC | 2021 | IBC | 2021 |
| New Mexico | IRC | 2021 | IBC | 2021 |
| New York | IRC | 2020 | IBC | 2020 |
| North Carolina | NC Res Code | 2018 | NC Building Code | 2018 |
| North Dakota | IRC | 2021 | IBC | 2021 |
| Ohio | IRC | 2021 | IBC | 2021 |
| Oklahoma | IRC | 2021 | IBC | 2021 |
| Oregon | ORSC | 2021 | OSSC | 2021 |
| Pennsylvania | IRC | Local | IBC | Local |
| Rhode Island | IRC | 2021 | IBC | 2021 |
| South Carolina | IRC | 2021 | IBC | 2021 |
| South Dakota | IRC | Local | IBC | Local |
| Tennessee | IRC | 2018 | IBC | 2018 |
| Texas | IRC | Local | IBC | Local |
| Utah | IRC | 2021 | IBC | 2021 |
| Vermont | IRC | 2021 | IBC | 2021 |
| Virginia | IRC | 2021 | IBC | 2021 |
| Washington | IRC | 2021 | IBC | 2021 |
| West Virginia | IRC | 2018 | IBC | 2018 |
| Wisconsin | IRC | 2018 | IBC | 2018 |
| Wyoming | IRC | 2021 | IBC | 2021 |

### States with Custom Codes
- **California**: California Building Code (CBC) based on IBC/IRC with Title 24 amendments
- **Florida**: Florida Building Code (FBC) - one of the strongest codes
- **Minnesota**: Minnesota State Building Code
- **North Carolina**: NC Building Code
- **Oregon**: Oregon Structural Specialty Code (OSSC)

---

## KEY FORMULAS FOR CALCULATORS

### 1. CONCRETE CALCULATIONS

**Volume (Cubic Yards):**
```
Cubic Yards = (Length × Width × Depth) / 27

All measurements in feet
27 cu ft = 1 cu yd
```

**Slab:**
```
CY = (L × W × Thickness) / 27

Example: 20' × 30' × 4" thick
= (20 × 30 × 0.333) / 27 = 7.4 CY
```

**Footing:**
```
CY = (Width × Depth × Length) / 27

Continuous footing: Calculate linear feet × cross-section area
```

**Column/Pier:**
```
Round: CY = (π × r² × Height) / 27
Square: CY = (Side² × Height) / 27
```

**Waste Factor:**
```
Order = Calculated CY × 1.05 to 1.10

5-10% waste typical
```

---

### 2. LUMBER/FRAMING CALCULATIONS

**Board Feet:**
```
Board Feet = (Thickness × Width × Length) / 12

Where dimensions are in inches for T & W, feet for L

Or: BF = (T" × W" × L") / 144
```

**Studs per Wall:**
```
Studs = (Wall Length / Spacing) + 1 + Extras

Extras:
- 3 per corner
- 2 per window/door (each side)
- 2 per intersection
```

**Common Stud Spacing:**
- 16" OC (on center) - standard
- 24" OC - allowed in some applications
- 12" OC - heavy-duty

**Plates:**
```
Linear Feet = Wall Length × 3 (top plate doubled + bottom)
```

**Headers:**
```
Header Length = Opening Width + 6" (3" each side for jack studs)

Header Sizes (Rule of Thumb):
- Up to 4' span: 2×6 or 2×8
- 4-6' span: 2×8 or 2×10
- 6-8' span: 2×10 or 2×12
- 8-10' span: 2×12 or engineered
```

**Joist Count:**
```
Joists = (Span Length / Spacing) + 1

Add extras for doubled at openings, blocking
```

---

### 3. SHEATHING/PANEL CALCULATIONS

**4×8 Panels Needed:**
```
Panels = Area / 32

Add waste factor:
- Walls: 10-15%
- Floors: 5-10%
- Roofs: 10-15%
```

**Wall Sheathing:**
```
Panels = (Wall Length × Wall Height) / 32

Subtract 50% of opening area (waste and framing)
```

---

### 4. DRYWALL CALCULATIONS

**Sheets Needed:**
```
Sheets (4×8) = Wall Area / 32
Sheets (4×12) = Wall Area / 48

Add 10% waste
```

**Ceiling:**
```
Sheets = Ceiling Area / Sheet Area
```

**Joint Compound:**
```
Gallons = Total SF / 200-300 SF per gallon (depending on level)
```

**Tape:**
```
Linear Feet = Perimeter + (Sheets × 16') for seams
```

**Screws:**
```
Screws = SF / 3-4 (approx 1 screw per 3-4 sq ft)
```

---

### 5. EXCAVATION CALCULATIONS

**Volume (Cubic Yards):**
```
CY = (L × W × D) / 27

For irregular shapes: Break into rectangles or use average dimensions
```

**Trench:**
```
CY = (Width × Depth × Length) / 27
```

**Swell Factor:**
```
Excavated Volume = In-ground Volume × Swell Factor

Common Swell Factors:
- Sand/gravel: 1.12 (12% swell)
- Common earth: 1.25 (25% swell)
- Clay: 1.30 (30% swell)
- Rock: 1.50 (50% swell)
```

**Backfill:**
```
Backfill CY = Excavation CY - Structure Volume

Account for compaction (add 10-20%)
```

---

### 6. PAINT CALCULATIONS

**Coverage:**
```
Gallons = Surface Area / Coverage Rate

Typical Coverage:
- Primer: 300-400 SF/gallon
- Flat paint: 350-400 SF/gallon
- Semi-gloss: 350-400 SF/gallon
- Trim: 100-150 SF/quart
```

**Wall Area:**
```
Wall SF = Perimeter × Height - Opening Area
```

---

### 7. STAIRS CALCULATIONS

**Rise/Run (IRC Compliant):**
```
Max Rise: 7-3/4" (IRC 2021)
Min Tread: 10" (IRC 2021)
Min Headroom: 6'-8"
```

**Number of Risers:**
```
Risers = Total Rise / Individual Rise

Example: 108" total rise / 7.5" = 14.4 → 15 risers
Actual rise = 108 / 15 = 7.2" per riser
```

**Number of Treads:**
```
Treads = Risers - 1

15 risers = 14 treads
```

**Stair Run:**
```
Total Run = Treads × Tread Depth

14 × 10" = 140" = 11'-8" horizontal run
```

**Stringer Length:**
```
Stringer = √(Total Rise² + Total Run²)
```

---

### 8. GRADE/SLOPE CALCULATIONS

**Slope Percentage:**
```
Slope % = (Rise / Run) × 100
```

**Grade for Drainage:**
```
Minimum away from foundation: 6" drop in 10' (5% slope)
Or: 1/4" per foot minimum
```

**Ramp Slopes (ADA):**
```
Max slope: 1:12 (8.33%)
For every 1" rise, need 12" run
```

---

### 9. AREA/VOLUME CONVERSIONS

**Common Conversions:**
```
1 square foot = 144 square inches
1 cubic foot = 1,728 cubic inches
1 cubic yard = 27 cubic feet
1 board foot = 144 cubic inches
1 acre = 43,560 square feet
```

**Material Weights:**
```
Concrete: 150 lbs/cu ft
Water: 62.4 lbs/cu ft
Sand (dry): 100 lbs/cu ft
Gravel: 105 lbs/cu ft
Soil (loose): 75-80 lbs/cu ft
Lumber (pine): 30-35 lbs/cu ft
Drywall (1/2"): 1.5-1.8 lbs/sq ft
```

---

### 10. ESTIMATING FORMULAS

**Labor Hours:**
```
Total Hours = Quantity × Production Rate

Production rates vary by trade and task
```

**Markup/Margin:**
```
Selling Price = Cost / (1 - Margin%)

Or: Selling Price = Cost × (1 + Markup%)

Example:
$10,000 cost with 20% margin = $10,000 / 0.80 = $12,500
$10,000 cost with 20% markup = $10,000 × 1.20 = $12,000
```

**Overhead Allocation:**
```
Overhead % = Annual Overhead / Annual Revenue × 100
```

---

## LICENSING REQUIREMENTS BY STATE

| State | License Required | Type | Threshold | Notes |
|-------|------------------|------|-----------|-------|
| Alabama | Yes | General Contractor | >$50,000 | |
| Alaska | Yes | General Contractor | All work | |
| Arizona | Yes | ROC License | >$1,000 | |
| Arkansas | Yes | Contractor | >$20,000 | |
| California | Yes | B License | >$500 | 4 years exp |
| Colorado | No state | Local only | | |
| Connecticut | Yes | HIC + Contractor | Varies | |
| Delaware | Yes | General Contractor | | |
| Florida | Yes | CGC or CBC | | |
| Georgia | Yes | General/Residential | >$2,500 | |
| Hawaii | Yes | General Contractor | | B classification |
| Idaho | Yes | Contractor Registration | | |
| Illinois | No state | Local only | | Chicago requires |
| Indiana | No state | Local only | | |
| Iowa | No state | Registration | | |
| Kansas | No state | Local only | | |
| Kentucky | No state | Local only | | |
| Louisiana | Yes | General Contractor | >$50,000 | |
| Maine | No state | Local only | | |
| Maryland | Yes | MHIC | HIC work | |
| Massachusetts | Yes | CSL + HIC | | |
| Michigan | Yes | Residential Builder | Residential | 60 hrs education |
| Minnesota | Yes | Residential Contractor | Residential | |
| Mississippi | Yes | General Contractor | >$50,000 | |
| Missouri | No state | Local only | | |
| Montana | No state | Registration | | |
| Nebraska | No state | Local only | | |
| Nevada | Yes | Contractor | All work | |
| New Hampshire | No state | Local only | | |
| New Jersey | Yes | HIC Registration | HIC | |
| New Mexico | Yes | GB-98 or GB-2 | | |
| New York | No state | Local only | | NYC, Westchester |
| North Carolina | Yes | General Contractor | >$30,000 | |
| North Dakota | Yes | Contractor | | |
| Ohio | No state | Local only | | |
| Oklahoma | Yes | Contractor | | |
| Oregon | Yes | CCB License | | |
| Pennsylvania | No state | Local only | | |
| Rhode Island | Yes | Contractor Reg | | |
| South Carolina | Yes | General Contractor | >$5,000 | |
| South Dakota | No state | Local only | | |
| Tennessee | Yes | Contractor | >$25,000 | |
| Texas | No state | Local only | | |
| Utah | Yes | Contractor | | |
| Vermont | No state | Registration | | |
| Virginia | Yes | Contractor | | Class A, B, C |
| Washington | Yes | General Contractor | | |
| West Virginia | Yes | Contractor | | |
| Wisconsin | No state | Dwelling Contractor | Dwellings | |
| Wyoming | No state | Local only | | |

### License Types
- **General Contractor (GC)**: Can do all construction work
- **Building Contractor**: Limited to buildings under certain size
- **Residential Contractor**: Limited to residential work
- **Home Improvement Contractor (HIC)**: Repairs/remodeling only

---

## OSHA REQUIREMENTS

### Fall Protection (1926.501)
```
Required at 6 feet or more in construction
Methods: Guardrails, safety nets, personal fall arrest
```

### Scaffolding (1926.451)
```
Max height without stabilization: 4× minimum base width
Must support 4× intended load
Full planking within 14" of face
```

### Excavations (1926.651)
```
Protective system required at 5' depth
Competent person required on site
Soil classification required
```

### Ladders (1926.1053)
```
Extend 3' above landing
1:4 ratio (1' out for every 4' up)
Max length: 30' (extension)
```

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Lumber Span Tables** - By species, grade, spacing
2. **Concrete Mix Ratios** - PSI to proportions
3. **Fastener Schedules** - Nails, screws by application
4. **Insulation R-Values** - By type and thickness
5. **Live/Dead Load Tables** - By occupancy
6. **Stair Code Requirements** - By jurisdiction
7. **Production Rates** - By trade task
8. **Material Weights** - Common materials
9. **Excavation Swell Factors** - By soil type
10. **Markup/Margin Tables** - Industry standards

---

## SOURCES

### Official Sources
- [ICC - International Code Council](https://www.iccsafe.org/)
- [OSHA Construction Standards](https://www.osha.gov/construction)
- [NAHB - National Association of Home Builders](https://www.nahb.org/)

### Reference Sources
- [Procore - Construction Estimating](https://www.procore.com/library/)
- [OmniCalculator - Construction](https://www.omnicalculator.com/construction)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| IRC/IBC Adoption | [VERIFIED] | Feb 1, 2026 |
| Concrete Formulas | [VERIFIED] | Feb 1, 2026 |
| Lumber Calculations | [VERIFIED] | Feb 1, 2026 |
| Estimating Formulas | [VERIFIED] | Feb 1, 2026 |
| OSHA Requirements | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [VERIFIED] | Feb 1, 2026 |

---

*This file is the master intelligence source for ZAFTO General Contractor calculators.*
*Always verify local code adoption and amendments.*
