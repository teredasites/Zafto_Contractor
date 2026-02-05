# MILLWRIGHT
## ZAFTO Intelligence File
### Last Updated: February 1, 2026

---

## OVERVIEW

**What they do:** Install, maintain, repair, and dismantle industrial machinery - conveyor systems, turbines, pumps, compressors, manufacturing equipment. Precision alignment and rigging specialists.

**Market size:** ~45,000 millwrights in US, strong demand in manufacturing and energy sectors.

**Why it matters for ZAFTO:** Precision alignment calculations, rigging, complex machinery work.

**Calculator target:** 70-85 calculators

---

## GOVERNING STANDARDS

### Primary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| ANSI/ASA S2.75 | ASA | Shaft alignment |
| ISO 1940-1 | ISO | Balance quality |
| API 610 | API | Centrifugal pumps |
| API 617 | API | Compressors |
| API 686 | API | Machinery installation |

### Secondary Standards
| Standard | Scope |
|----------|-------|
| ASME B30.9 | Slings |
| ASME B30.26 | Rigging hardware |
| AGMA Standards | Gearing |
| ABMA Standards | Bearings |
| NEMA Standards | Motors |
| OSHA 1910.147 | Lockout/Tagout |
| OSHA 1910.184 | Slings |

---

## STATE LICENSING

**Millwrights are NOT typically licensed by states** - certification is through union apprenticeship and industry certifications.

| State | License Required | Notes |
|-------|------------------|-------|
| Most States | No | Union apprenticeship |
| Some localities | Contractor license | Business licensing |

### Certifications
| Certification | Issuer | Purpose |
|---------------|--------|---------|
| Journeyman Millwright | UBC | Apprenticeship completion |
| Certified Rigger | NCCCO | Rigging operations |
| Vibration Analyst | Vibration Institute | Predictive maintenance |
| Machinery Lubrication Tech | ICML | Lubrication |
| Infrared Thermographer | Various | Thermal imaging |
| AWS Welder | AWS | Welding qualifications |
| OSHA 10/30 | OSHA | Safety |

### Apprenticeship (UBC)
| Year | Focus | Hours |
|------|-------|-------|
| 1st | Safety, hand tools, basic fitting | 2,000 |
| 2nd | Rigging, machinery components | 2,000 |
| 3rd | Precision alignment, bearings | 2,000 |
| 4th | Troubleshooting, specialty | 2,000 |
| **Total** | | **8,000** |

---

## KEY FORMULAS & CALCULATIONS

### Shaft Alignment

**Dial Indicator Method**
```
Angularity (per inch) = (TIR Top-Bottom) / Diameter

Offset = (TIR Side-Side) / 2

Move = Measured value × (Foot distance / Dial distance)
```

**Reverse Indicator Method**
```
Coupling angularity = (S₁ - S₂) / (2 × C)
Coupling offset = (S₁ + S₂) / 2

Where:
- S₁, S₂ = Sag-corrected readings
- C = Coupling span
```

**Thermal Growth**
```
ΔH = α × L × ΔT

Where:
- ΔH = Height change (inches)
- α = Coefficient of expansion
- L = Length (inches)
- ΔT = Temperature change (°F)

Steel: α = 6.5 × 10⁻⁶ in/in/°F
Cast iron: α = 5.9 × 10⁻⁶ in/in/°F
Stainless: α = 9.6 × 10⁻⁶ in/in/°F
```

### Vibration Analysis

**Vibration Velocity**
```
V = 2π × f × D

Where:
- V = Velocity (in/sec)
- f = Frequency (Hz)
- D = Displacement (inches)
```

**CPM to Hz**
```
Hz = CPM / 60
CPM = Hz × 60
```

**1× RPM = Running speed
2× RPM = Misalignment or looseness
BPFO, BPFI = Bearing frequencies**

### Balancing

**Balance Quality Grade (ISO 1940)**
```
G = ω × e

Where:
- G = Balance quality grade (mm/s)
- ω = Angular velocity (rad/s)
- e = Specific unbalance (eccentricity)
```

**Permissible Residual Unbalance**
```
Uper = (G × M × 9549) / N

Where:
- Uper = Permissible unbalance (g-mm)
- G = Balance grade
- M = Rotor mass (kg)
- N = RPM
```

**Single Plane Balance**
```
Correction = Trial weight × (Original / Trial result)
Angle = Measured phase shift
```

### Rigging & Lifting

**Load Weight**
```
Steel: Weight = Volume × 490 lb/ft³
Cast iron: Weight = Volume × 450 lb/ft³
Aluminum: Weight = Volume × 165 lb/ft³
```

**Sling Angle Factor**
Same as Ironworker calculations:
- 90° = 1.000
- 60° = 0.866
- 45° = 0.707
- 30° = 0.500

### Bearings

**Bearing Life (L10)**
```
L10 = (C/P)^n × 10⁶ revolutions

Where:
- C = Dynamic load rating
- P = Equivalent load
- n = 3 for ball, 10/3 for roller
```

**Bearing Fit**
```
Shaft tolerance: j5, k5, m5, n5 (interference)
Housing tolerance: H7, J7, K7 (clearance to interference)
```

### Belt Drives

**Belt Length**
```
L = 2C + 1.57(D + d) + (D - d)² / (4C)

Where:
- C = Center distance
- D = Large pulley diameter
- d = Small pulley diameter
```

**Belt Speed**
```
V = π × D × RPM / 12

Where V = ft/min
```

**Speed Ratio**
```
Ratio = D_driven / D_driver = RPM_driver / RPM_driven
```

### Gear Calculations

**Gear Ratio**
```
Ratio = N_driven / N_driver = D_driven / D_driver
```

**Pitch Diameter**
```
PD = N / DP

Where:
- PD = Pitch diameter
- N = Number of teeth
- DP = Diametral pitch
```

**Center Distance**
```
C = (PD₁ + PD₂) / 2
```

---

## CALCULATOR IDEAS (70-85)

### Shaft Alignment (15)
1. Dial indicator calculator
2. Reverse indicator calculator
3. Rim and face method
4. Laser alignment input
5. Thermal growth calculator
6. Soft foot check
7. Shim calculator
8. Move calculator (horizontal)
9. Move calculator (vertical)
10. Coupling gap check
11. Angular misalignment
12. Offset misalignment
13. Target values by coupling type
14. Alignment tolerance lookup
15. Pre-alignment checklist

### Vibration (10)
16. CPM to Hz converter
17. Velocity to displacement
18. Displacement to acceleration
19. Bearing frequency calculator (BPFO, BPFI, BSF, FTF)
20. Balance grade calculator
21. Permissible unbalance
22. Single plane balance
23. Two plane balance
24. Phase angle calculator
25. Vibration severity (ISO 10816)

### Rigging (12)
26. Load weight estimator
27. Sling capacity calculator
28. Sling angle factor
29. Center of gravity
30. Lift plan calculator
31. Rigging hardware selector
32. Spreader bar sizing
33. Come-along capacity
34. Jack capacity
35. Cribbing load
36. Skate roller capacity
37. Hydraulic gantry capacity

### Bearings (8)
38. Bearing life calculator (L10)
39. Equivalent load
40. Fit/tolerance selector
41. Bearing clearance
42. Lubrication interval
43. Grease quantity
44. Bearing temperature limit
45. Bearing replacement criteria

### Belt Drives (8)
46. Belt length calculator
47. Belt speed
48. Speed ratio
49. Belt tension
50. Pulley diameter selector
51. Center distance adjustment
52. Belt selection
53. Sheave alignment

### Gear/Chain Drives (8)
54. Gear ratio calculator
55. Pitch diameter
56. Center distance (gears)
57. Gear tooth calculator
58. Chain length
59. Sprocket sizing
60. Chain tension
61. Lubrication requirements

### Pumps & Compressors (8)
62. Pump curve reading
63. NPSH calculation
64. Impeller diameter trim
65. Affinity laws
66. Specific speed
67. Compressor capacity
68. Seal flush requirements
69. Coupling selection

### General Machinery (8)
70. Foundation bolt sizing
71. Grout volume calculator
72. Leveling wedge calculator
73. Motor frame dimensions
74. Baseplate flatness
75. Pipe strain check
76. Coupling alignment tolerance
77. Runout measurement

### Maintenance (5)
78. PM schedule generator
79. Oil analysis interpretation
80. MTBF calculator
81. Parts inventory calculator
82. Downtime cost calculator

---

## REFERENCE TABLES NEEDED

1. Alignment tolerances by speed
2. Vibration severity charts
3. Balance quality grades
4. Bearing fit tables
5. Belt selection charts
6. Coupling specifications
7. Motor frame dimensions
8. Rigging hardware capacities
9. Material weights
10. Thermal expansion coefficients

---

## SOURCES

- ASA (Alignment Standards Alliance): Shaft alignment standards
- Vibration Institute: https://www.vi-institute.org
- API (American Petroleum Institute): https://www.api.org
- NCCCO: https://www.nccco.org
- UBC (United Brotherhood of Carpenters - Millwrights): https://www.carpenters.org
- ISO Standards: https://www.iso.org
- SKF Bearing Handbook: https://www.skf.com
- Gates Belt Drive Manual: https://www.gates.com

---

## NOTES

- Millwrights are in UBC (Carpenters union) not a separate union
- Precision alignment is the core differentiating skill
- Laser alignment tools common but understanding fundamentals is critical
- Vibration analysis certification adds value
- Shutdown/turnaround work in refineries and plants is lucrative
- Heavy rigging skills overlap with ironworkers
- Travel to job sites is common
- Often work closely with electricians, pipefitters
