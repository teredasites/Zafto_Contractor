# IRONWORKER
## ZAFTO Intelligence File
### Last Updated: February 1, 2026

---

## OVERVIEW

**What they do:** Install structural steel, reinforcing steel (rebar), ornamental iron, and precast concrete. Includes structural ironworkers, reinforcing ironworkers (rodbusters), and ornamental ironworkers.

**Market size:** ~90,000 ironworkers in US, cyclical with construction economy.

**Why it matters for ZAFTO:** High-paying trade ($60-90k+), complex rigging/load calculations, safety-critical work.

**Calculator target:** 70-85 calculators

---

## GOVERNING CODES & STANDARDS

### Primary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| AISC 360 | AISC | Specification for Structural Steel Buildings |
| AISC 341 | AISC | Seismic Provisions for Structural Steel |
| AISC 303 | AISC | Code of Standard Practice |
| ACI 318 | ACI | Building Code for Structural Concrete (rebar) |
| AWS D1.1 | AWS | Structural Welding Code - Steel |

### Secondary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| OSHA 1926 Subpart R | OSHA | Steel Erection |
| OSHA 1926 Subpart CC | OSHA | Cranes and Derricks |
| ASME B30.9 | ASME | Slings |
| ASME B30.26 | ASME | Rigging Hardware |
| CRSI Manual | CRSI | Reinforcing Steel Placing |
| AWS D1.4 | AWS | Welding Reinforcing Steel |

### Rigging Standards
| Standard | Scope |
|----------|-------|
| ASME B30.5 | Mobile and Locomotive Cranes |
| ASME B30.9 | Slings (wire rope, synthetic, chain) |
| ASME B30.20 | Below-the-Hook Lifting Devices |
| ASME B30.26 | Rigging Hardware |

---

## STATE LICENSING

**Ironworkers are NOT typically licensed by states** - certification is through union apprenticeship and industry certifications.

| State | License Required | Notes |
|-------|------------------|-------|
| Most States | No | Union/apprenticeship certification |
| Some localities | Yes | Rigger/signalperson may require cert |

### Certifications (More Important Than State License)

| Certification | Issuer | Requirements |
|---------------|--------|--------------|
| Journeyman Ironworker | IMPACT/Ironworkers Union | 3-4 year apprenticeship |
| Certified Welder | AWS | Welding test (various positions) |
| Certified Rigger | NCCCO | Written + practical exam |
| Certified Signalperson | NCCCO | Written + practical exam |
| OSHA 10/30 | OSHA | Safety training |
| Fall Protection Competent Person | Various | Fall protection training |

### Apprenticeship Structure
| Year | Focus | Hours |
|------|-------|-------|
| 1st | Safety, tools, basic rigging | 2,000 |
| 2nd | Structural steel, welding intro | 2,000 |
| 3rd | Advanced rigging, crane signals | 2,000 |
| 4th | Specialty work, leadership | Varies |
| **Total** | | **6,000-8,000** |

---

## EXAM/CERTIFICATION CONTENT

### NCCCO Rigger Certification
| Level | Content |
|-------|---------|
| Rigger I | Basic rigging, sling angles, hitch types |
| Rigger II | Complex loads, engineered lifts, load charts |

**Exam Topics:**
- Rigging hardware inspection
- Load weight estimation
- Sling capacity and angles
- Center of gravity
- Crane load charts
- Signal communication
- OSHA regulations

### AWS Welder Certification
| Test | Content |
|------|---------|
| Written | Welding theory, symbols, procedures |
| Practical | Weld test plates in specified positions |

**Common Positions:**
- 1G (flat)
- 2G (horizontal)
- 3G (vertical)
- 4G (overhead)
- 6G (pipe - all positions)

---

## KEY FORMULAS & CALCULATIONS

### Load Weight Estimation

**Steel Weight**
```
Weight (lbs) = Volume (in³) × 0.2833

Or by shape:
- Plate: W = L × W × T × 0.2833
- Round bar: W = π × r² × L × 0.2833
- Pipe: W = π × ((OD/2)² - (ID/2)²) × L × 0.2833
```

**Quick Steel Weights (per linear foot)**
| Shape | Weight |
|-------|--------|
| W8×31 | 31 lb/ft |
| W10×49 | 49 lb/ft |
| W12×65 | 65 lb/ft |
| W14×90 | 90 lb/ft |
| #4 rebar | 0.668 lb/ft |
| #5 rebar | 1.043 lb/ft |
| #6 rebar | 1.502 lb/ft |
| #8 rebar | 2.670 lb/ft |

### Sling Capacity

**Sling Angle Factor**
```
Capacity = Rated Capacity × Sling Angle Factor

| Angle from Horizontal | Factor |
|----------------------|--------|
| 90° (vertical) | 1.000 |
| 60° | 0.866 |
| 45° | 0.707 |
| 30° | 0.500 |
```

**Two-Leg Sling Capacity**
```
Capacity = 2 × Single Leg Capacity × sin(θ)

Where θ = angle from horizontal
```

**D/d Ratio (Wire Rope)**
```
Efficiency = Based on D/d ratio
D = Diameter of bend (pin, hook)
d = Rope diameter

| D/d Ratio | Efficiency |
|-----------|------------|
| 1 | 50% |
| 2 | 65% |
| 5 | 85% |
| 10 | 90% |
| 25+ | 100% |
```

### Rigging Calculations

**Center of Gravity**
```
CG = Σ(Wi × Di) / ΣWi

Where:
- Wi = Weight of each section
- Di = Distance from reference point
```

**Headroom Required**
```
H = Sling Length × cos(θ) + Hook Block + Clearance

Where θ = angle from vertical
```

**Choker Hitch Capacity**
```
Choker Capacity = Vertical Capacity × 0.75

(Approximate - varies by angle)
```

### Bolt Calculations

**Bolt Tension**
```
T = K × D × F

Where:
- T = Torque (ft-lbs)
- K = Nut factor (typically 0.20)
- D = Bolt diameter (inches)
- F = Desired tension (lbs)
```

**Bolt Pretension (AISC)**
| Bolt Size | A325 Min Tension | A490 Min Tension |
|-----------|------------------|------------------|
| 1/2" | 12,000 lbs | 15,000 lbs |
| 5/8" | 19,000 lbs | 24,000 lbs |
| 3/4" | 28,000 lbs | 35,000 lbs |
| 7/8" | 39,000 lbs | 49,000 lbs |
| 1" | 51,000 lbs | 64,000 lbs |
| 1-1/8" | 56,000 lbs | 80,000 lbs |
| 1-1/4" | 71,000 lbs | 102,000 lbs |

### Reinforcing Steel (Rebar)

**Rebar Weight**
```
Weight (lb/ft) = (Bar Size #)² × 0.167 / 8

Simplified:
#3 = 0.376 lb/ft
#4 = 0.668 lb/ft
#5 = 1.043 lb/ft
#6 = 1.502 lb/ft
#7 = 2.044 lb/ft
#8 = 2.670 lb/ft
#9 = 3.400 lb/ft
#10 = 4.303 lb/ft
#11 = 5.313 lb/ft
```

**Development Length (Simplified)**
```
Ld = (fy × db) / (25 × √f'c)

Where:
- fy = Yield strength of rebar (psi)
- db = Bar diameter (inches)
- f'c = Concrete compressive strength (psi)
```

**Lap Splice Length**
```
Class A splice = 1.0 × Ld
Class B splice = 1.3 × Ld
```

---

## CALCULATOR IDEAS (70-85)

### Load Weight Estimation (15)
1. Structural steel weight (W shapes)
2. Steel plate weight
3. Steel pipe weight
4. Steel tube weight (HSS)
5. Steel angle weight
6. Steel channel weight
7. Steel beam weight (S shapes)
8. Rebar weight calculator
9. Rebar bundle weight
10. Mesh weight calculator
11. Combined load weight
12. Concrete weight estimator
13. Precast panel weight
14. Equipment weight estimator
15. Total lift weight

### Sling & Rigging (20)
16. Wire rope sling capacity
17. Chain sling capacity
18. Synthetic sling capacity
19. Sling angle factor
20. Two-leg sling calculator
21. Three-leg sling calculator
22. Four-leg sling calculator
23. Basket hitch capacity
24. Choker hitch capacity
25. D/d ratio efficiency
26. Minimum sling length
27. Headroom calculator
28. Spreader bar sizing
29. Equalizer beam design
30. Shackle selection
31. Hook capacity check
32. Turnbuckle sizing
33. Eyebolt capacity
34. Lifting lug design
35. Rigging hardware selector

### Center of Gravity & Balance (8)
36. Center of gravity (2D)
37. Center of gravity (3D)
38. Tailing point location
39. Load shift calculator
40. Balance point finder
41. Tilt-up panel CG
42. Unbalanced load correction
43. Multiple pick points

### Crane & Signals (10)
44. Crane load chart reader
45. Lift radius calculator
46. Boom angle calculator
47. Net capacity (deductions)
48. Crane setup position
49. Pick and place planning
50. Critical lift percentage
51. Wind load on load
52. Dynamic loading factor
53. Signal reference guide

### Bolting (8)
54. Bolt torque calculator
55. Bolt pretension
56. Bolt pattern layout
57. Bolt quantity estimator
58. Bolt tensioner pressure
59. Turn-of-nut method
60. Bolt elongation
61. Bolt grip length

### Welding (Reference) (7)
62. Weld size calculator
63. Weld length required
64. Electrode selection
65. Heat input calculator
66. Preheat temperature
67. Welding symbols decoder
68. Weld inspection criteria

### Rebar (12)
69. Rebar development length
70. Rebar lap splice length
71. Rebar hook dimensions
72. Rebar spacing calculator
73. Rebar quantity estimator
74. Rebar bend allowance
75. Rebar cutlist generator
76. Stirrup/tie dimensions
77. Column rebar calculator
78. Beam rebar calculator
79. Slab rebar calculator
80. Wall rebar calculator

### Miscellaneous (5)
81. Safety factor calculator
82. Fall distance calculator
83. OSHA steel erection rules
84. Decimal/fraction converter
85. Unit converter (ironwork)

---

## REFERENCE TABLES NEEDED

1. Wide flange (W shape) properties
2. HSS/tube properties
3. Angle properties
4. Channel properties
5. Rebar sizes and weights
6. Wire rope capacities
7. Chain sling capacities
8. Shackle capacities
9. Bolt torque tables
10. Crane hand signals

---

## SOURCES

- AISC (American Institute of Steel Construction): https://www.aisc.org
- ACI (American Concrete Institute): https://www.concrete.org
- CRSI (Concrete Reinforcing Steel Institute): https://www.crsi.org
- AWS (American Welding Society): https://www.aws.org
- NCCCO (National Commission for Certification of Crane Operators): https://www.nccco.org
- IMPACT (Ironworkers Training): https://www.ironworkers.org
- OSHA Steel Erection: https://www.osha.gov/steel-erection
- ASME B30 Standards: https://www.asme.org

---

## NOTES

- Strong union presence (International Association of Bridge, Structural, Ornamental and Reinforcing Iron Workers)
- Work is physically demanding and at heights
- Connector (working at height connecting steel) is highest-risk position
- Rodbusters (rebar workers) are a subset of ironworkers
- Rigger certification (NCCCO) increasingly required
- Seasonal/weather-dependent in many regions
- Travel to job sites is common (per diem work)
