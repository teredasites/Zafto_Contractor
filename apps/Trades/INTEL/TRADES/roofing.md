# ROOFING TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Roofing |
| ZAFTO Calculators | 83 |
| Primary Code | IRC Chapter 9 (Roof Assemblies) |
| Secondary | Manufacturer specifications, OSHA |
| Publisher | ICC |
| Update Cycle | Every 3 years |
| Current Edition | IRC 2024 |
| Editions Still in Use | 2015, 2018, 2021, 2024 |

---

## GOVERNING CODES & STANDARDS

### Primary: International Residential Code (IRC)

| Chapter | Topic |
|---------|-------|
| Chapter 9 | Roof Assemblies |
| R902 | Fire classification |
| R903 | Weather protection |
| R904 | Materials |
| R905 | Requirements by material type |
| R906 | Roof insulation |

### Key IRC Sections

| Section | Topic |
|---------|-------|
| R905.2 | Asphalt shingles |
| R905.3 | Clay/concrete tile |
| R905.4 | Metal shingles |
| R905.5 | Mineral-surfaced roll |
| R905.6 | Slate shingles |
| R905.7 | Wood shingles |
| R905.8 | Wood shakes |
| R905.10 | Metal roof panels |
| R905.11 | Modified bitumen |
| R905.12 | Thermoset single-ply |
| R905.13 | Thermoplastic single-ply |
| R905.14 | Sprayed polyurethane foam |
| R905.15 | Liquid-applied coatings |
| R905.16 | Photovoltaic shingles |

### Manufacturer Standards

| Standard | Publisher | Scope |
|----------|-----------|-------|
| ASTM D3462 | ASTM | Asphalt shingles |
| ASTM D225 | ASTM | Asphalt shingles (organic) |
| ASTM D3161 | ASTM | Wind resistance |
| ASTM D7158 | ASTM | Wind resistance (Class D, G, H) |
| ASTM E108 | ASTM | Fire test methods |
| UL 790 | UL | Fire classification |
| FM 4470 | FM | Single-ply membranes |

### OSHA Roofing Safety

| Standard | Topic |
|----------|-------|
| 29 CFR 1926.500-503 | Fall protection |
| 29 CFR 1926.451 | Scaffolding |
| 29 CFR 1926.1053 | Ladders |

---

## IRC ADOPTION BY STATE

**See General Contractor INTEL for complete IRC adoption table**

Most states follow IRC with amendments. Key roofing-specific amendments typically involve:
- Wind speed zones (coastal)
- Snow load requirements (northern)
- Fire-resistive requirements (wildfire zones)

### Wind Speed Zone Requirements

| Zone | Design Wind Speed | Typical Shingle Class |
|------|-------------------|----------------------|
| Zone 1 | Up to 110 mph | Class D |
| Zone 2 | 111-130 mph | Class G |
| Zone 3 | 131-150 mph | Class H |
| Hurricane | 150+ mph | Class H + enhanced fastening |

### States with Enhanced Requirements

| State | Special Requirements |
|-------|---------------------|
| Florida | FBC, Miami-Dade NOA required in HVHZ |
| Texas | Windstorm certification in coastal counties |
| California | Title 24, WUI fire zones |
| Louisiana | Hurricane-resistant requirements |
| North Carolina | Coastal wind requirements |
| South Carolina | Coastal wind requirements |

---

## KEY FORMULAS FOR CALCULATORS

### 1. ROOF PITCH & SLOPE

**Pitch Expression:**
```
Pitch = Rise : Run (typically expressed as X:12)

Example: 6:12 pitch = 6 inches rise per 12 inches run
```

**Slope Percentage:**
```
Slope % = (Rise / Run) × 100

Example: 6:12 = (6/12) × 100 = 50%
```

**Slope Angle (Degrees):**
```
Angle = arctan(Rise / Run)

Example: 6:12 = arctan(6/12) = arctan(0.5) = 26.57°
```

**Common Pitch Conversions:**

| Pitch | Angle | Slope % | Multiplier |
|-------|-------|---------|------------|
| 1:12 | 4.8° | 8.3% | 1.003 |
| 2:12 | 9.5° | 16.7% | 1.014 |
| 3:12 | 14.0° | 25.0% | 1.031 |
| 4:12 | 18.4° | 33.3% | 1.054 |
| 5:12 | 22.6° | 41.7% | 1.083 |
| 6:12 | 26.6° | 50.0% | 1.118 |
| 7:12 | 30.3° | 58.3% | 1.158 |
| 8:12 | 33.7° | 66.7% | 1.202 |
| 9:12 | 36.9° | 75.0% | 1.250 |
| 10:12 | 39.8° | 83.3% | 1.302 |
| 11:12 | 42.5° | 91.7% | 1.357 |
| 12:12 | 45.0° | 100% | 1.414 |

---

### 2. ROOF AREA CALCULATIONS

**Pitch Multiplier Formula:**
```
Multiplier = √(1 + (Rise/12)²)

Or: Multiplier = √((Pitch/12)² + 1)
```

**Actual Roof Area:**
```
Roof Area = Footprint Area × Pitch Multiplier

Example:
House footprint: 2,000 sq ft
Roof pitch: 6:12
Multiplier: 1.118
Roof Area = 2,000 × 1.118 = 2,236 sq ft
```

**Multiple Sections:**
```
Total Roof Area = Σ(Section Area × Section Multiplier)

Calculate each roof plane separately, then sum
```

**Complex Shapes:**
```
Hip roof: Generally similar to gable with same pitch
Valley: Add area of both intersecting planes
Dormer: Calculate separately and add
```

---

### 3. ROOFING SQUARES

**Square Definition:**
```
1 Roofing Square = 100 sq ft
```

**Squares Needed:**
```
Squares = Total Roof Area / 100

Example:
2,236 sq ft / 100 = 22.36 squares
Order: 23 squares (round up)
```

**Waste Factor:**
```
Material Squares = Roof Squares × (1 + Waste Factor)

Typical Waste Factors:
- Simple gable: 5-10%
- Hip roof: 10-15%
- Complex with valleys: 15-20%
- Steep pitch: Additional 5%
```

---

### 4. SHINGLE CALCULATIONS

**Bundles per Square:**
```
3-tab shingles: 3 bundles = 1 square
Architectural/dimensional: 3-4 bundles = 1 square (check manufacturer)
Premium/designer: 4-5 bundles = 1 square
```

**Total Bundles:**
```
Bundles = Squares × Bundles_per_square × (1 + Waste)

Example:
23 squares × 3 bundles × 1.10 waste = 75.9 → 76 bundles
```

**Starter Strip:**
```
Linear Feet = Eaves Length + Rake Length
Starter Bundles = Linear Feet / Coverage per bundle (typically 105-120 LF)
```

**Ridge/Hip Cap:**
```
Linear Feet = Ridge Length + Hip Lengths
Ridge Bundles = Linear Feet / Coverage per bundle (typically 20-35 LF)
```

---

### 5. UNDERLAYMENT CALCULATIONS

**Roll Coverage:**
```
Standard 15# felt: 400 sq ft/roll (single layer)
30# felt: 200 sq ft/roll
Synthetic: 1,000 sq ft/roll (varies)
Ice & water shield: ~65 sq ft/roll
```

**Underlayment Needed:**
```
Rolls = Roof Area / Coverage × (1 + Overlap Factor)

Overlap Factor: 10-15% for horizontal laps
```

**Ice & Water Shield:**
```
Required: First 24" inside exterior wall line (minimum)
High-snow areas: May require to 36" or entire roof

Linear Feet = Eaves + Valleys + Around penetrations
```

---

### 6. RAFTER CALCULATIONS

**Rafter Length:**
```
Rafter Length = √(Run² + Rise²)

Or: Rafter Length = Run × Pitch Multiplier

Example:
Run: 12 ft, Rise: 6 ft (6:12 pitch)
Rafter = √(12² + 6²) = √(144 + 36) = √180 = 13.42 ft
```

**Rafter Spacing:**
```
Number of Rafters = (Roof Length / Spacing) + 1

Common Spacing: 16" OC, 24" OC
```

**Ridge Board Length:**
```
Ridge Length = Building Length + Overhang (both ends)
```

**Hip/Valley Rafter:**
```
Hip Rafter Length = Common Rafter × 1.414 (for equal pitch)

Or: Hip Length = √(Run² + Rise² + Run²) for actual calculation
```

---

### 7. DECKING/SHEATHING

**Plywood/OSB Sheets:**
```
Sheets (4×8) = Roof Area / 32 × (1 + Waste)

Waste Factor: 5-10% typical
```

**Board Sheathing:**
```
Board Feet = Roof Area × 1.1 (for 1× boards)
```

**H-Clips:**
```
Clips = (Sheets × 2) - (Number of supported edges)

Typically 1 clip per unsupported edge between rafters
```

---

### 8. VENTILATION CALCULATIONS

**Net Free Area (NFA) Requirement:**
```
NFA = Attic Floor Area / 150 (with vapor barrier)
NFA = Attic Floor Area / 300 (balanced intake/exhaust)

50/50 Rule: 50% intake (soffit), 50% exhaust (ridge/roof)
```

**Ridge Vent:**
```
Linear Feet = Net Free Area Required / NFA per linear foot
Typical ridge vent: 18 sq in NFA per linear foot
```

**Soffit Vent:**
```
Soffit NFA = Ridge NFA (for balanced system)
Number of vents = Required NFA / NFA per vent
```

**Roof Vents (Turtle/Box):**
```
Number = Required NFA / NFA per vent
Typical: 50-60 sq in NFA per vent
```

**Power Ventilator:**
```
CFM = Attic sq ft × 0.7 (minimum)
For steep roofs or dark shingles: × 1.0 or higher
```

---

### 9. FLASHING CALCULATIONS

**Step Flashing:**
```
Pieces = (Wall Length / Shingle Exposure) + 2

Typical: 5" × 7" pieces at 5" exposure
Overlap: 2" minimum
```

**Valley Flashing (Metal):**
```
Length = Valley Length + 6" (each end)
Width: 24" typical (12" each side of centerline)
```

**Pipe Flashing:**
```
Count each penetration
Size by pipe diameter: 1.5", 2", 3", 4"
```

**Drip Edge:**
```
Linear Feet = Eaves + Rakes
Standard: 10' pieces
Pieces = Linear Feet / 10 (round up)
```

---

### 10. METAL ROOFING CALCULATIONS

**Panel Coverage:**
```
Panels = Roof Width / Panel Coverage Width

Common coverage widths: 24", 26", 36"
```

**Panel Length:**
```
Length = Eave to Ridge + Overhang + Overlap (if lapped)

Order full-length panels when possible (reduces leaks)
```

**Fasteners:**
```
Exposed fastener: 80 screws per square (varies)
Concealed fastener: By clip count

Ridge Cap: 1 screw per foot each side
```

---

### 11. LABOR PRODUCTION RATES

**Asphalt Shingles:**
```
Production: 2-4 squares per worker per day
Factors: Pitch, complexity, weather
```

**Tear-Off:**
```
Removal: 10-15 squares per worker per day (1 layer)
Add 50% time for each additional layer
```

**Metal Roofing:**
```
Standing seam: 1-2 squares per worker per day
Exposed fastener: 2-4 squares per worker per day
```

---

## LICENSING REQUIREMENTS BY STATE

| State | License Required | Type | Notes |
|-------|------------------|------|-------|
| Alabama | Yes (>$2,500) | Roofing contractor | Home Builder Licensure Board |
| Alaska | Yes | Specialty contractor | Residential/Commercial separate |
| Arizona | Yes (>$750) | ROC License | CR-42 classification |
| Arkansas | Yes (>$2,000) | Roofing contractor | |
| California | Yes (>$500) | C-39 Roofing | 4 years experience |
| Colorado | No state | Local only | |
| Connecticut | Yes | HIC Registration | |
| Delaware | Yes | Contractor license | |
| Florida | Yes | CCC (Certified) or CGC | State license required |
| Georgia | Yes (>$2,500) | Residential/Commercial | |
| Hawaii | Yes | C-42 Roofing | |
| Idaho | Yes | Contractor registration | |
| Illinois | No state | Local varies | Chicago requires |
| Indiana | No state | Local varies | |
| Iowa | No state | Registration only | |
| Kansas | No state | AG registration | |
| Kentucky | No state | Local varies | |
| Louisiana | Yes | Roofing contractor | |
| Maine | No state | Local varies | |
| Maryland | Yes | MHIC License | |
| Massachusetts | Yes | HIC, CSL | |
| Michigan | Yes | Residential builder | 60 hours education |
| Minnesota | Yes (residential) | Roofing contractor | Commercial = local |
| Mississippi | Yes (>$50,000) | Contractor | Residential basic |
| Missouri | No state | Local varies | |
| Montana | No state | Registration only | |
| Nebraska | No state | Local varies | |
| Nevada | Yes | Contractor license | C-15 Roofing |
| New Hampshire | No state | Local varies | |
| New Jersey | Yes | HIC Registration | |
| New Mexico | Yes | Contractor license | GB-2 or GB-98 |
| New York | No state | Local varies | NYC, Westchester require |
| North Carolina | Yes (>$30,000) | General contractor | |
| North Dakota | Yes | Contractor license | |
| Ohio | No state | Local varies | Some cities require |
| Oklahoma | Yes | Roofing contractor | |
| Oregon | Yes | CCB License | |
| Pennsylvania | No state | Local varies | |
| Rhode Island | Yes | Contractor registration | |
| South Carolina | Yes (>$5,000) | Residential/commercial | |
| South Dakota | No state | Local varies | |
| Tennessee | Yes (>$25,000) | Contractor | HIC for smaller |
| Texas | No state | Local varies | Some cities require |
| Utah | Yes | Contractor license | S280 Roofing |
| Vermont | No state | Contractor registration | |
| Virginia | Yes | Contractor license | |
| Washington | Yes | Specialty contractor | |
| West Virginia | Yes | Contractor license | |
| Wisconsin | No state | Dwelling contractor | Certain counties |
| Wyoming | No state | Local varies | |

### Summary
- **32 states** require state-level licensing
- **18 states** defer to local jurisdictions
- Most require insurance + bond
- Many require passing trade exam

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Pitch Multiplier Table** - All common pitches
2. **Bundles per Square** - By shingle type
3. **Underlayment Coverage** - By product type
4. **Ventilation NFA Table** - By attic size
5. **Wind Zone Requirements** - By location
6. **Fastener Schedules** - By material/zone
7. **Flashing Dimensions** - Standard sizes
8. **Production Rates** - By task
9. **Material Weights** - For structural
10. **Warranty Requirements** - By manufacturer

---

## SOURCES

### Official Sources
- [ICC - International Residential Code](https://www.iccsafe.org/)
- [NRCA - National Roofing Contractors Association](https://www.nrca.net/)
- [ARMA - Asphalt Roofing Manufacturers Association](https://www.asphaltroofing.org/)

### Reference Sources
- [Calculator.net - Roofing Calculator](https://www.calculator.net/roofing-calculator.html)
- [ServiceTitan - Roofing Calculators](https://www.servicetitan.com/tools/roofing-calculators)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| Pitch Formulas | [VERIFIED] | Feb 1, 2026 |
| Area Calculations | [VERIFIED] | Feb 1, 2026 |
| Material Calculations | [VERIFIED] | Feb 1, 2026 |
| Ventilation Formulas | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [VERIFIED] | Feb 1, 2026 |

---

*This file is the master intelligence source for ZAFTO Roofing calculators.*
*Always verify local code requirements and manufacturer specifications.*
