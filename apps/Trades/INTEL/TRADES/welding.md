# WELDING TRADE INTEL
## Complete Reference for ZAFTO Calculators
### Last Updated: February 1, 2026

---

## OVERVIEW

| Item | Value |
|------|-------|
| Trade | Welding |
| ZAFTO Calculators | 48 |
| Primary Standards | AWS (American Welding Society), ASME |
| Secondary | OSHA, API (pipelines), AISC (structural steel) |
| Certifications | AWS Certified Welder, ASME Code Welder |

---

## GOVERNING STANDARDS & CODES

### AWS (American Welding Society) Standards

| Code | Title | Scope |
|------|-------|-------|
| AWS D1.1 | Structural Welding Code - Steel | Buildings, bridges, structures |
| AWS D1.2 | Structural Welding Code - Aluminum | Aluminum structures |
| AWS D1.3 | Structural Welding Code - Sheet Steel | Light gauge |
| AWS D1.4 | Structural Welding Code - Reinforcing Steel | Rebar welding |
| AWS D1.5 | Bridge Welding Code | Highway bridges |
| AWS D1.6 | Structural Welding Code - Stainless Steel | Stainless structures |
| AWS D1.8 | Structural Welding Code - Seismic | Seismic requirements |
| AWS D9.1 | Sheet Metal Welding Code | HVAC, architectural |

### AWS D1.1 Edition History

| Edition | Status | Notes |
|---------|--------|-------|
| AWS D1.1:2020 | Current | Latest |
| AWS D1.1:2015 | In use | Previous edition |
| AWS D1.1:2010 | Legacy | Still referenced |
| AWS D1.1:2006 | Legacy | Older structures |

### ASME Standards (Pressure Vessels & Piping)

| Code | Title |
|------|-------|
| ASME BPVC Section IX | Welding, Brazing, and Fusing Qualifications |
| ASME B31.1 | Power Piping |
| ASME B31.3 | Process Piping |
| ASME B31.4 | Pipeline Transportation (Liquid) |
| ASME B31.8 | Gas Transmission and Distribution |

### API Standards (Petroleum)

| Code | Title |
|------|-------|
| API 1104 | Welding of Pipelines and Related Facilities |
| API 650 | Welded Tanks for Oil Storage |
| API 653 | Tank Inspection, Repair, Alteration |

### AISC Standards

| Code | Title |
|------|-------|
| AISC 360 | Specification for Structural Steel Buildings |
| AISC 341 | Seismic Provisions for Structural Steel |

---

## OSHA WELDING REQUIREMENTS

### General Requirements (29 CFR 1910.252-254)

| Topic | Standard |
|-------|----------|
| Fire prevention | 1910.252(a) |
| Protection of personnel | 1910.252(b) |
| Health protection | 1910.252(c) |
| Arc welding | 1910.254 |
| Resistance welding | 1910.255 |

### Construction (29 CFR 1926 Subpart J)

| Section | Topic |
|---------|-------|
| 1926.350 | Gas welding and cutting |
| 1926.351 | Arc welding and cutting |
| 1926.352 | Fire prevention |
| 1926.353 | Ventilation/protection |
| 1926.354 | Welding in confined spaces |

### PELs (Permissible Exposure Limits)

| Substance | PEL (mg/m³) |
|-----------|-------------|
| Iron oxide fume | 10 |
| Manganese | 5 (ceiling) |
| Chromium (VI) | 0.005 |
| Nickel | 1 |
| Zinc oxide | 5 |
| Copper fume | 0.1 |
| Lead | 0.05 |

---

## CERTIFICATION REQUIREMENTS

### AWS Certification Program

| Certification | Description |
|---------------|-------------|
| CW (Certified Welder) | Performance qualification |
| CWI (Certified Welding Inspector) | Inspection qualification |
| CAWI (Certified Associate) | Entry-level inspector |
| SCWI (Senior CWI) | Advanced inspector |
| CWE (Certified Welding Educator) | Education qualification |
| CWS (Certified Welding Supervisor) | Supervisory qualification |
| CWSR (Certified Welding Sales Rep) | Sales qualification |

### Welder Performance Qualification

| Element | Variables |
|---------|-----------|
| Process | SMAW, GMAW, FCAW, GTAW, SAW |
| Position | 1G, 2G, 3G, 4G, 5G, 6G |
| Material | Carbon steel, stainless, aluminum |
| Thickness | Range qualified |
| Electrode/filler | As tested |

### Position Designations

**Groove Welds:**
| Position | Description |
|----------|-------------|
| 1G | Flat - pipe rotated |
| 2G | Horizontal - pipe vertical axis |
| 3G | Vertical - plate vertical |
| 4G | Overhead - plate horizontal |
| 5G | Horizontal fixed - pipe horizontal |
| 6G | 45° fixed - most restrictive |
| 6GR | Restricted 6G |

**Fillet Welds:**
| Position | Description |
|----------|-------------|
| 1F | Flat |
| 2F | Horizontal |
| 3F | Vertical |
| 4F | Overhead |

---

## KEY FORMULAS FOR CALCULATORS

### 1. WELD METAL VOLUME

**Fillet Weld (Equal Leg):**
```
Volume (in³/in) = Leg² / 2

Or: Volume (in³/ft) = Leg² × 6

Example: 1/4" fillet
= (0.25)² / 2 = 0.03125 in³/in
= 0.375 in³/ft
```

**Fillet Weld Volume Table:**
| Leg Size | in³/ft | lbs/ft (steel) |
|----------|--------|----------------|
| 1/8" | 0.094 | 0.027 |
| 3/16" | 0.211 | 0.060 |
| 1/4" | 0.375 | 0.106 |
| 5/16" | 0.586 | 0.166 |
| 3/8" | 0.844 | 0.239 |
| 1/2" | 1.50 | 0.425 |
| 5/8" | 2.34 | 0.664 |
| 3/4" | 3.38 | 0.956 |

**V-Groove (Single):**
```
Volume = (Root opening × Plate thickness) +
         (tan(Angle/2) × Plate thickness² / 2)

Simplified for 60° included angle:
Volume (in³/in) ≈ 0.29 × T² + (R × T)

Where: T = thickness, R = root opening
```

---

### 2. FILLER METAL CALCULATIONS

**Electrode Consumption (SMAW):**
```
Electrode lbs = Weld metal lbs / Deposition efficiency

Deposition efficiency:
- E6010/E6011: 55-65%
- E7018: 65-70%
- E7024: 70-75%
```

**Wire Consumption (GMAW/FCAW):**
```
Wire lbs = Weld metal lbs / Deposition efficiency

Deposition efficiency:
- Solid wire (GMAW): 90-98%
- Flux-cored (FCAW): 80-90%
```

**Weld Metal Weight:**
```
Weight (lbs) = Volume (in³) × 0.283 (for steel)

Density factors:
- Carbon steel: 0.283 lbs/in³
- Stainless steel: 0.289 lbs/in³
- Aluminum: 0.098 lbs/in³
```

---

### 3. HEAT INPUT CALCULATIONS

**Heat Input Formula:**
```
Heat Input (kJ/in) = (Amps × Volts × 60) / (Travel Speed × 1000)

Or: HI = (A × V × 0.06) / Travel Speed (ipm)
```

**Heat Input by Process:**
| Process | Typical HI Range (kJ/in) |
|---------|-------------------------|
| GTAW | 8-40 |
| GMAW-S | 20-60 |
| GMAW-P | 15-40 |
| SMAW | 20-80 |
| FCAW | 25-80 |
| SAW | 40-150 |

**Maximum Heat Input:**
```
Often specified by WPS or code
Typically limited to prevent:
- Grain growth
- HAZ embrittlement
- Distortion
```

---

### 4. PREHEAT CALCULATIONS

**Carbon Equivalent (CE):**
```
CE (IIW) = C + Mn/6 + (Cr+Mo+V)/5 + (Ni+Cu)/15

CE > 0.45: Preheat typically required
CE > 0.60: Special procedures needed
```

**AWS D1.1 Preheat (Carbon Steel):**
| Thickness | CE ≤ 0.30 | CE 0.30-0.45 | CE > 0.45 |
|-----------|-----------|--------------|-----------|
| ≤ 3/4" | None | 50°F | 150°F |
| 3/4"-1.5" | 50°F | 100°F | 225°F |
| 1.5"-2.5" | 50°F | 150°F | 300°F |
| > 2.5" | 100°F | 225°F | 400°F |

---

### 5. AMPERAGE CALCULATIONS

**Recommended Amperage (SMAW):**
```
Amps = Electrode diameter (in) × 1000

Simplified rule: 1 amp per 0.001" diameter

E6010/E6011 (DC+):
- 1/8": 80-130 A
- 5/32": 100-150 A
- 3/16": 130-180 A

E7018 (DC+ or AC):
- 1/8": 90-140 A
- 5/32": 120-170 A
- 3/16": 150-220 A
```

**Wire Feed Speed (GMAW):**
```
WFS (ipm) = Amps / (Constant × Wire diameter)

Rule of thumb for CO2:
- 0.035" wire: Amps × 3.5 = WFS (ipm)
- 0.045" wire: Amps × 2.0 = WFS (ipm)
```

---

### 6. WELDING SPEED/TIME

**Deposition Rate (lbs/hr):**
```
DR = (WFS × Wire area × 60 × Density) / Deposition efficiency

Typical GMAW rates:
- 0.035" @ 300 ipm: ~6-8 lbs/hr
- 0.045" @ 300 ipm: ~10-12 lbs/hr
```

**Travel Speed:**
```
TS (ipm) = (Deposition Rate × Efficiency) / (Volume × Density × 60)
```

**Welding Time:**
```
Time (hrs) = Weld metal lbs / Deposition rate

Add:
- Arc-on factor: 20-40% typical efficiency
- Prep/cleanup time
```

---

### 7. GAS CONSUMPTION

**Shielding Gas Flow:**
```
Typical flow rates (CFH):
- GMAW: 30-45 CFH
- FCAW: 35-50 CFH (if gas shielded)
- GTAW: 15-25 CFH

Cylinder duration:
Hours = Cylinder volume (CF) / Flow rate (CFH)
```

**Gas Consumption:**
```
Total CF = Flow rate × Arc time

Example: 35 CFH × 4 hours = 140 CF
```

**Common Cylinder Sizes:**
| Size | Argon (CF) | CO2 (lbs) |
|------|------------|-----------|
| Small | 40 | 20 |
| Medium | 80 | 35 |
| Large | 125 | 50 |
| 300 | 300 | — |

---

### 8. JOINT PREPARATION

**Bevel Angles:**
```
Standard V-groove: 60° included (30° each side)
Standard U-groove: 20° included

Root opening: 0-1/8" typical
Root face: 0-1/8" typical
```

**Groove Weld Dimensions:**
| Type | Included Angle | Root Opening | Root Face |
|------|----------------|--------------|-----------|
| Square | 0° | 0-1/8" | Full thickness |
| Single-V | 60° | 0-1/8" | 0-1/8" |
| Double-V | 60° | 0-1/8" | 0-1/8" |
| Single-U | 20° | 0-1/8" | 1/8" |
| Single-bevel | 45° | 0-1/8" | 0-1/8" |

---

### 9. WELD STRENGTH

**Fillet Weld Strength (AWS D1.1):**
```
Allowable load per inch = 0.707 × Leg × Allowable stress

For E70 electrode:
Allowable shear = 21 ksi

Load per inch = 0.707 × Leg × 21 × 1000

Example: 1/4" fillet
= 0.707 × 0.25 × 21,000 = 3,712 lbs/inch
```

**Fillet Weld Strength Table (E70):**
| Leg Size | Allowable Load (lbs/in) |
|----------|------------------------|
| 1/8" | 1,856 |
| 3/16" | 2,784 |
| 1/4" | 3,712 |
| 5/16" | 4,640 |
| 3/8" | 5,568 |
| 1/2" | 7,424 |

**Effective Throat:**
```
Fillet: Throat = 0.707 × Leg
Groove: Throat = Depth of preparation
PJP: Less than full thickness
CJP: Full thickness
```

---

### 10. COST CALCULATIONS

**Cost per Linear Foot:**
```
Total Cost = Labor + Filler + Gas + Power + Overhead

Labor = Time × Rate
Filler = Weight × $/lb
Gas = Volume × $/CF
Power = kW × Hours × $/kWh
```

**Relative Process Costs:**
| Process | Relative Cost | Deposition Rate |
|---------|---------------|-----------------|
| SMAW | High | Low (1-3 lbs/hr) |
| GMAW | Medium | High (6-12 lbs/hr) |
| FCAW | Medium | High (8-15 lbs/hr) |
| GTAW | Very High | Very Low (1-2 lbs/hr) |
| SAW | Low | Very High (15-40 lbs/hr) |

---

### 11. DISTORTION CONTROL

**Angular Distortion:**
```
Angle ≈ k × (Heat input / Thickness²)

Where k = constant based on joint type
```

**Shrinkage:**
```
Longitudinal: 0.001" per inch of weld length (approx)
Transverse: Based on weld size and joint type
```

**Mitigation:**
- Balanced welding sequence
- Backstep technique
- Clamping/fixturing
- Preheat control

---

### 12. QUALITY/INSPECTION

**Visual Inspection Criteria (AWS D1.1):**
| Defect | Limit |
|--------|-------|
| Cracks | None permitted |
| Undercut | ≤1/32" (≤1/16" if ≤2" total) |
| Porosity | Scattered acceptable |
| Incomplete fusion | None permitted |
| Overlap | None permitted |
| Convexity | ≤1/8" over specified |
| Concavity | No undersize |

**NDE Methods:**
| Method | Abbreviation | Detects |
|--------|--------------|---------|
| Visual | VT | Surface defects |
| Magnetic particle | MT | Surface/subsurface |
| Liquid penetrant | PT | Surface breaking |
| Radiographic | RT | Internal defects |
| Ultrasonic | UT | Internal defects |

---

## LICENSING REQUIREMENTS BY STATE

**Note:** Welding is largely unregulated at the state level. Certification (AWS, ASME) is required by employers/code, not by state license.

| State | Welder License Required | Notes |
|-------|------------------------|-------|
| Alabama | No state | Employer/project requirements |
| Alaska | No state | |
| Arizona | No state | |
| Arkansas | No state | |
| California | No state | Structural certification required per code |
| Colorado | No state | |
| Connecticut | No state | |
| Delaware | No state | |
| Florida | No state | |
| Georgia | No state | |
| Hawaii | No state | |
| Idaho | No state | |
| Illinois | No state | |
| Indiana | No state | |
| Iowa | No state | |
| Kansas | No state | |
| Kentucky | No state | |
| Louisiana | No state | Pipeline/plant requirements |
| Maine | No state | |
| Maryland | No state | |
| Massachusetts | No state | |
| Michigan | No state | |
| Minnesota | No state | |
| Mississippi | No state | |
| Missouri | No state | |
| Montana | No state | |
| Nebraska | No state | |
| Nevada | No state | |
| New Hampshire | No state | |
| New Jersey | No state | |
| New Mexico | No state | |
| New York | No state | NYC building code requires certification |
| North Carolina | No state | |
| North Dakota | No state | |
| Ohio | No state | |
| Oklahoma | No state | |
| Oregon | No state | |
| Pennsylvania | No state | |
| Rhode Island | No state | |
| South Carolina | No state | |
| South Dakota | No state | |
| Tennessee | No state | |
| Texas | No state | |
| Utah | No state | |
| Vermont | No state | |
| Virginia | No state | |
| Washington | No state | |
| West Virginia | No state | |
| Wisconsin | No state | |
| Wyoming | No state | |

**Industry Requirements:**
- Structural steel: AWS D1.1 certification
- Pressure vessels/piping: ASME Section IX
- Pipelines: API 1104
- Aircraft: Per FAA specifications
- Nuclear: NQA-1, additional requirements

---

## REFERENCE TABLES NEEDED FOR ZAFTO

1. **Weld Volume Calculator** - Fillet and groove
2. **Electrode/Wire Consumption** - By weld type
3. **Heat Input Calculator** - Amps, volts, speed
4. **Preheat Temperature Table** - By CE and thickness
5. **Amperage Chart** - By electrode/wire size
6. **Gas Consumption Calculator** - Flow rate × time
7. **Weld Strength Calculator** - Load per inch
8. **Deposition Rate Table** - By process
9. **Joint Prep Dimensions** - Standard configurations
10. **Cost Estimator** - Labor + materials

---

## SOURCES

### Official Sources
- [AWS - American Welding Society](https://www.aws.org/)
- [ASME - American Society of Mechanical Engineers](https://www.asme.org/)
- [AISC - American Institute of Steel Construction](https://www.aisc.org/)
- [API - American Petroleum Institute](https://www.api.org/)
- [OSHA - Welding Safety](https://www.osha.gov/welding-cutting-brazing)

### Reference Sources
- [Lincoln Electric Welding Guide](https://www.lincolnelectric.com/)
- [Miller Electric Resources](https://www.millerwelds.com/)
- [Welding Journal](https://www.aws.org/publications/welding-journal)

---

## VERIFICATION STATUS

| Section | Status | Verified Date |
|---------|--------|---------------|
| Weld Volume Formulas | [VERIFIED] | Feb 1, 2026 |
| Heat Input Formula | [VERIFIED] | Feb 1, 2026 |
| Electrode Data | [VERIFIED] | Feb 1, 2026 |
| AWS Standards | [VERIFIED] | Feb 1, 2026 |
| Weld Strength (D1.1) | [VERIFIED] | Feb 1, 2026 |
| Licensing by State | [VERIFIED - No state licenses] | Feb 1, 2026 |

---

*This file is the master intelligence source for ZAFTO Welding calculators.*
*Welder certification (AWS, ASME) required by code/employer, not by state license.*
