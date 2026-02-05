# CONCRETE & MASONRY TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Concrete & Masonry |
| ZAFTO Calculators | 67 |
| Primary Codes | ACI 318 (Concrete), TMS 402/602 (Masonry), IRC |
| Secondary | OSHA, ASTM Standards |
| Publisher | ACI, TMS, ICC |
| Update Cycle | ACI: 5 years, IRC: 3 years |

---

## GOVERNING CODES & STANDARDS

### ACI (American Concrete Institute) Standards

| Standard | Title | Scope |
|----------|-------|-------|
| ACI 318 | Building Code for Structural Concrete | Primary design code |
| ACI 301 | Specifications for Structural Concrete | Construction specs |
| ACI 211.1 | Mix Design | Proportioning normal concrete |
| ACI 302.1R | Concrete Floor and Slab Construction | Floors |
| ACI 304R | Measuring, Mixing, Transporting, Placing | Operations |
| ACI 305R | Hot Weather Concreting | >77°F conditions |
| ACI 306R | Cold Weather Concreting | <40°F conditions |
| ACI 308R | Curing Concrete | Curing methods |
| ACI 347 | Formwork for Concrete | Form design |
| ACI 117 | Tolerances | Placement tolerances |

### ACI 318 Edition History

| Edition | Status | Notes |
|---------|--------|-------|
| ACI 318-19 | Current | Referenced by 2021/2024 IBC |
| ACI 318-14 | In use | Referenced by 2018 IBC |
| ACI 318-11 | Legacy | Referenced by 2015 IBC |
| ACI 318-08 | Legacy | Referenced by 2012 IBC |

### TMS (The Masonry Society) Standards

| Standard | Title |
|----------|-------|
| TMS 402 | Building Code for Masonry Structures |
| TMS 602 | Specification for Masonry Structures |
| TMS 302 | Grout Specifications |
| TMS 404 | Standards for Floor and Roof Systems |

### IRC Concrete & Masonry Chapters

| Chapter | Topic |
|---------|-------|
| Chapter 4 | Foundations |
| R403 | Footings |
| R404 | Foundation walls |
| R405 | Drainage |
| R406 | Waterproofing |

### ASTM Concrete Standards

| Standard | Description |
|----------|-------------|
| ASTM C31 | Making and curing test specimens |
| ASTM C39 | Compressive strength cylinders |
| ASTM C94 | Ready-mixed concrete |
| ASTM C136 | Aggregate gradation |
| ASTM C143 | Slump test |
| ASTM C150 | Portland cement |
| ASTM C172 | Sampling fresh concrete |

### ASTM Masonry Standards

| Standard | Description |
|----------|-------------|
| ASTM C90 | Load-bearing CMU |
| ASTM C140 | CMU sampling and testing |
| ASTM C270 | Mortar for unit masonry |
| ASTM C476 | Grout for masonry |
| ASTM C1019 | Grout sampling |

---

## IRC FOUNDATION REQUIREMENTS

### Minimum Footing Dimensions (IRC Table R403.1)

**Continuous Footings (1-Story):**
| Soil Type | Width | Thickness |
|-----------|-------|-----------|
| 1500 psf | 16" | 6" |
| 2000 psf | 12" | 6" |
| 2500 psf | 10" | 6" |
| 3000 psf | 8" | 6" |
| 4000 psf | 6" | 6" |

**Continuous Footings (2-Story):**
| Soil Type | Width | Thickness |
|-----------|-------|-----------|
| 1500 psf | 23" | 8" |
| 2000 psf | 17" | 7" |
| 2500 psf | 14" | 6" |
| 3000 psf | 11" | 6" |
| 4000 psf | 8" | 6" |

### Foundation Wall Thickness (IRC R404.1.1)

| Wall Height | Unbalanced Fill | CMU Thickness | Concrete |
|-------------|-----------------|---------------|----------|
| ≤7' | ≤5' | 8" | 6" |
| ≤7' | ≤6' | 8" | 8" |
| ≤7' | ≤7' | 10" | 8" |
| 7'-8' | ≤6' | 10" | 8" |
| 7'-8' | ≤8' | 12" | 10" |

### Reinforcement Requirements (IRC R404.1.2)

**Minimum Horizontal:**
- CMU: #4 @ top course, #4 @ bottom course
- Concrete: Per design/table

**Minimum Vertical:**
- CMU: #4 @ 48" OC (varies by conditions)
- Concrete: Per design/table

---

## KEY FORMULAS FOR CALCULATORS

### 1. VOLUME CALCULATIONS

**Rectangular Slab:**
```
Cubic Yards = (Length' × Width' × Thickness") / 324

Or: CY = (L × W × T) / 27 (all in feet)

Example:
20' × 30' × 4" = (20 × 30 × 4) / 324 = 7.41 CY
```

**Circular Slab:**
```
CY = (π × r² × T) / 324

r = radius in feet
T = thickness in inches
```

**Footing (Continuous):**
```
CY = (Length' × Width' × Depth') / 27

Example:
100 LF × 16" wide × 8" deep
= (100 × 1.33 × 0.67) / 27 = 3.3 CY
```

**Column Footing (Pad):**
```
CY = (L × W × D) / 27

All dimensions in feet
```

---

### 2. CONCRETE ORDERING

**Order Quantity:**
```
Order CY = Calculated CY × Waste Factor

Waste Factors:
- Slab on grade: 1.05-1.10 (5-10%)
- Walls: 1.05-1.10
- Footings: 1.10-1.15 (10-15%)
- Columns: 1.10-1.15
- Over uneven subgrade: 1.15-1.20
```

**Ready Mix Truck Capacity:**
```
Standard truck: 8-10 CY
Mini mixer: 2-4 CY
Bag mix: 0.015 CY per 60 lb bag
```

**Bags to Cubic Yards:**
```
60 lb bag = 0.017 CY (0.45 CF)
80 lb bag = 0.022 CY (0.60 CF)

Bags for 1 CY:
60 lb: ~60 bags
80 lb: ~45 bags
```

---

### 3. MIX DESIGN BASICS

**Water-Cement Ratio:**
```
w/c = Water (lbs) / Cement (lbs)

Typical:
- High strength: 0.35-0.40
- Standard: 0.45-0.50
- Lower strength: 0.55-0.60
```

**Strength vs Water-Cement:**
```
w/c 0.40 → ~5500 psi
w/c 0.45 → ~4500 psi
w/c 0.50 → ~3500-4000 psi
w/c 0.55 → ~3000 psi
w/c 0.60 → ~2500 psi
```

**Typical Mix (per CY):**
```
5-bag mix (2500 psi):
- Cement: 470 lbs (5 bags)
- Sand: 1550 lbs
- Gravel: 1850 lbs
- Water: ~30 gal

6-bag mix (3000-3500 psi):
- Cement: 564 lbs (6 bags)
- Sand: 1450 lbs
- Gravel: 1900 lbs
- Water: ~33 gal
```

---

### 4. SLUMP & WORKABILITY

**Slump Ranges (inches):**
```
Footings/foundations: 2-4"
Slabs: 3-4"
Walls: 3-4"
Columns: 3-4"
Pavements: 2-3"
Mass concrete: 1-2"
```

**Slump Test:**
```
Cone: 12" high × 8" base × 4" top
Fill in 3 layers, rod 25 times each
Measure drop from 12"
```

---

### 5. REINFORCEMENT CALCULATIONS

**Rebar Weight:**
```
#3 (3/8"): 0.376 lbs/LF
#4 (1/2"): 0.668 lbs/LF
#5 (5/8"): 1.043 lbs/LF
#6 (3/4"): 1.502 lbs/LF
#7 (7/8"): 2.044 lbs/LF
#8 (1"): 2.670 lbs/LF
#9 (1-1/8"): 3.400 lbs/LF
#10 (1-1/4"): 4.303 lbs/LF
```

**Rebar Area:**
```
#3: 0.11 sq in
#4: 0.20 sq in
#5: 0.31 sq in
#6: 0.44 sq in
#7: 0.60 sq in
#8: 0.79 sq in
#9: 1.00 sq in
#10: 1.27 sq in
```

**Rebar Quantity (Grid):**
```
Bars in one direction = (Length / Spacing) + 1

Example: 20' × 30' slab, #4 @ 12" OC both ways
20' direction: (30' × 12" / 12") + 1 = 31 bars × 20' = 620 LF
30' direction: (20' × 12" / 12") + 1 = 21 bars × 30' = 630 LF
Total: 1,250 LF #4

Add 10-15% for lap splices
```

**Lap Splice Length:**
```
Standard: 40 × bar diameter (minimum)

#3: 15" min
#4: 20" min
#5: 25" min
#6: 30" min
```

**Wire Mesh:**
```
6×6 - W1.4×W1.4 (6×6 - 10/10):
- Covers 150-200 SF per roll (5'×150')
- Weight: 21 lbs per 100 SF

6×6 - W2.9×W2.9 (6×6 - 6/6):
- Heavier gauge
- Weight: 42 lbs per 100 SF
```

---

### 6. CONCRETE BLOCK (CMU) CALCULATIONS

**Blocks per Square Foot:**
```
Standard 8×8×16 CMU:
1.125 blocks per SF of wall (with 3/8" mortar)

Or: 112.5 blocks per 100 SF
```

**Blocks per Course:**
```
Blocks per course = Wall length (inches) / 16"

Example: 40' wall = 480" / 16 = 30 blocks per course
```

**Courses to Height:**
```
Courses = Wall height (inches) / 8"

Example: 8' wall = 96" / 8 = 12 courses
```

**Total Blocks:**
```
Blocks = (Wall SF / 0.89) or (Wall SF × 1.125)

Add 5-10% waste
```

**Mortar for CMU:**
```
Approximately:
8.5 bags (Type S or N) per 100 SF wall
Or: 3.5 bags per 100 blocks
```

**Grout for CMU:**
```
Fill cores:
- 8" wall: 0.5 CF per SF (solid grouted)
- 8" wall: 0.25 CF per SF (alternate cores)
- 12" wall: 0.75 CF per SF (solid grouted)

Or: 1.0 CF per LF of wall (8" solid grout)
```

---

### 7. BRICK CALCULATIONS

**Standard Brick Size:**
```
Standard modular: 3-5/8" × 2-1/4" × 7-5/8"
With mortar: 4" × 2-2/3" × 8"
```

**Bricks per Square Foot:**
```
Standard modular: 6.75 bricks per SF (3/8" joint)

Other sizes:
- King size: 4.5 per SF
- Queen size: 5.76 per SF
- Roman: 6.0 per SF
- Utility: 3.0 per SF
```

**Mortar for Brick:**
```
Type S/N mortar:
7 bags per 1000 brick (standard modular)
Or: 0.5 CF mortar per SF of wall
```

---

### 8. WALL CALCULATIONS

**Concrete Wall Volume:**
```
CY = (Length × Height × Thickness) / 27

All in feet

Example: 40' long × 8' high × 8" thick
= (40 × 8 × 0.67) / 27 = 7.9 CY
```

**Form Surface Area:**
```
Both sides: Length × Height × 2

Example: 40' × 8' = 320 SF × 2 = 640 SF forms
```

**Form Pressure:**
```
Pressure = 150 × Rate of pour (ft/hr) × Temperature factor

Max pressure = 150 × Height (for slow pours)
```

---

### 9. STEP/STAIR CALCULATIONS

**Concrete Steps:**
```
Volume = (Tread × Rise × Width × Steps) / 27

Average step: 0.08-0.12 CY per step (36" width)
```

**Rise/Run Standards:**
```
Riser: 7" - 7-3/4" typical
Tread: 11" minimum (nosing not counted)
```

**Stair Layout:**
```
Total rise / Riser height = Number of risers
Number of treads = Risers - 1
Total run = Treads × Tread depth
```

---

### 10. CURING REQUIREMENTS

**Minimum Curing Time:**
```
Normal conditions: 7 days minimum
ACI 301: 7 days or until 70% f'c

Cold weather: Extended time required
Hot weather: Begin immediately, protect from drying
```

**Curing Methods:**
```
- Water ponding/spray
- Wet burlap
- Plastic sheeting
- Curing compound (white pigmented)
- Membrane-forming compounds
```

**Strength Gain:**
```
Day 1: 20% of f'c
Day 3: 40-50% of f'c
Day 7: 65-70% of f'c
Day 14: 85-90% of f'c
Day 28: 100% of f'c (design strength)
```

---

### 11. ESTIMATING LABOR

**Production Rates (per 8-hour day):**
```
Form work:
- Slab edge forms: 200-300 LF
- Wall forms: 400-600 SF
- Footing forms: 150-250 LF

Placing:
- Slab (pump): 50-100 CY
- Slab (direct): 25-50 CY
- Walls: 25-40 CY
- Footings: 30-50 CY

Finishing:
- Broom finish: 300-500 SF/hr
- Trowel finish: 100-200 SF/hr
- Stamped: 50-100 SF/hr

Masonry:
- CMU: 100-150 blocks/day per mason
- Brick: 300-500 bricks/day per mason
```

---

### 12. CONCRETE COVERAGE CALCULATIONS

**Form Release Agent:**
```
300-600 SF per gallon
```

**Sealer:**
```
200-400 SF per gallon (varies by product)
```

**Stamped Concrete:**
```
Release powder: 3-6 lbs per 100 SF
Sealer: 200-300 SF per gallon
```

---

## LICENSING REQUIREMENTS BY STATE

| State | Concrete/Masonry License | Type | Notes |
|-------|-------------------------|------|-------|
| Alabama | Yes | Specialty | >$2,500 |
| Alaska | Yes | General/Specialty | |
| Arizona | ROC | A (engineering) or B-1/B-5 | |
| Arkansas | Yes | Contractor | |
| California | A (general) or C-8 (concrete) | Specialty | C-29 masonry |
| Colorado | No state | Local varies | |
| Connecticut | HIC | Home improvement | |
| Delaware | Yes | Contractor | |
| Florida | Yes | CGC, Specialty | |
| Georgia | Yes | >$2,500 | |
| Hawaii | Yes | A, B, C-32 | |
| Idaho | Yes | Registration | |
| Illinois | No state | Local varies | |
| Indiana | No state | Local varies | |
| Iowa | No state | Registration | |
| Kansas | No state | Local varies | |
| Kentucky | No state | Local varies | |
| Louisiana | Yes | Contractor | |
| Maine | No state | | |
| Maryland | MHIC | | |
| Massachusetts | HIC + CSL | | |
| Michigan | Yes | Residential builder | |
| Minnesota | Yes | Contractor | |
| Mississippi | Yes | >$50k | |
| Missouri | No state | Local varies | |
| Montana | No state | Registration | |
| Nebraska | No state | Local varies | |
| Nevada | Yes | C-5 Concrete, C-18 Masonry | |
| New Hampshire | No state | | |
| New Jersey | HIC | Registration | |
| New Mexico | Yes | GB-2, GB-98 | |
| New York | No state | Local varies | NYC requires |
| North Carolina | Yes | >$30k GC | |
| North Dakota | Yes | Contractor | |
| Ohio | No state | Local varies | |
| Oklahoma | Yes | Contractor | |
| Oregon | CCB | | |
| Pennsylvania | No state | Local varies | |
| Rhode Island | Yes | Registration | |
| South Carolina | Yes | >$5k | |
| South Dakota | No state | Local varies | |
| Tennessee | Yes | >$25k | HIC for smaller |
| Texas | No state | Local varies | |
| Utah | Yes | S210 Concrete, S220 Masonry | |
| Vermont | No state | Registration | |
| Virginia | Yes | Class A, B, C | |
| Washington | Yes | Specialty | |
| West Virginia | Yes | Contractor | |
| Wisconsin | No state | | |
| Wyoming | No state | Local varies | |

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Volume Calculator** - Slab, footing, wall
2. **Concrete Quantity Calculator** - CY with waste
3. **Bag Mix Calculator** - Bags to CY
4. **CMU Block Calculator** - Blocks per wall
5. **Brick Calculator** - Bricks + mortar
6. **Rebar Weight/Quantity Calculator** - By size
7. **Footing Size Table** - IRC reference
8. **Mix Design Reference** - Strength/water ratio
9. **Cure Time Calculator** - Strength gain
10. **Labor Estimator** - Production rates

---

## SOURCES

### Official Sources
- [ACI - American Concrete Institute](https://www.concrete.org/)
- [TMS - The Masonry Society](https://www.masonrysociety.org/)
- [PCA - Portland Cement Association](https://www.cement.org/)
- [ICC - International Code Council](https://www.iccsafe.org/)
- [NCMA - National Concrete Masonry Association](https://www.ncma.org/)

### Reference Sources
- [NRMCA - National Ready Mixed Concrete Association](https://www.nrmca.org/)
- [Concrete Construction Magazine](https://www.concreteconstruction.net/)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| Volume Formulas | [VERIFIED] | Feb 1, 2026 |
| Rebar Calculations | [VERIFIED] | Feb 1, 2026 |
| CMU/Brick Formulas | [VERIFIED] | Feb 1, 2026 |
| IRC Tables | [VERIFIED - 2021 IRC] | Feb 1, 2026 |
| ACI References | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [NEEDS VERIFICATION] | — |

---

*This file is the master intelligence source for ZAFTO Concrete & Masonry calculators.*
*Always verify structural requirements with local code and engineer for load-bearing applications.*
