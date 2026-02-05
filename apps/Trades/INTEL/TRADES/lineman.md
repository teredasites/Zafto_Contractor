# LINEMAN (Power Line Worker)
## ZAFTO Intelligence File
### Last Updated: February 1, 2026

---

## OVERVIEW

**What they do:** Install, maintain, and repair electrical power lines and equipment on the electrical grid - transmission (high voltage), distribution (to homes/businesses), and substations.

**Market size:** ~120,000 lineworkers in US, growing due to grid modernization and renewable integration.

**Why it matters for ZAFTO:** High-paying trade ($70-100k+), dangerous work, lots of field calculations, underserved by mobile apps.

**Calculator target:** 85-100 calculators

---

## GOVERNING BODIES & STANDARDS

### Primary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| NESC (National Electrical Safety Code) | IEEE/ANSI C2 | Safety for utility workers, clearances, grounding |
| OSHA 1910.269 | US Dept of Labor | Electric power generation/transmission/distribution |
| OSHA 1926 Subpart V | US Dept of Labor | Power transmission & distribution (construction) |
| RUS (Rural Utilities Service) | USDA | Construction standards for rural utilities |

### Secondary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| IEEE C2 | IEEE | National Electrical Safety Code |
| ANSI C84.1 | ANSI | Voltage ratings |
| IEEE 80 | IEEE | Substation grounding |
| IEEE 81 | IEEE | Ground testing |
| IEEE 1584 | IEEE | Arc flash (applies to linework too) |

**Key difference from NEC:** The NEC (NFPA 70) covers premises wiring. The NESC (IEEE C2) covers utility systems. Linemen work under NESC, not NEC.

---

## LICENSING & CERTIFICATION

### State Licensing
**Most states do NOT license linemen directly** - they work under utility company training programs. However, some states require:

| State | License Required? | Type | Notes |
|-------|-------------------|------|-------|
| California | No | - | IBEW apprenticeship common |
| Texas | No | - | Utility company certs |
| Florida | No | - | Utility company certs |
| Most States | No | - | Apprenticeship-based |

### Industry Certifications (More Important Than State License)

| Certification | Issuer | Requirements | Validity |
|---------------|--------|--------------|----------|
| Journeyman Lineman | IBEW/Utility | 4-year apprenticeship (7,000+ hrs) | Career |
| CDL Class A | State DMV | Written + driving test | 4-5 years |
| Qualified Electrical Worker | Employer | OSHA 1910.269 training | Annual |
| First Aid/CPR | Red Cross/AHA | Training course | 2 years |
| Pole Top/Bucket Rescue | Employer | Annual training | Annual |
| Flagger Certification | State DOT | Training course | 3-5 years |

### Apprenticeship Structure (IBEW/NEAT)
| Year | Focus | Hours |
|------|-------|-------|
| 1st | Ground work, flagging, materials | 2,000 |
| 2nd | Climbing, basic overhead | 2,000 |
| 3rd | Hot work introduction, transformers | 2,000 |
| 4th | Advanced hot work, leadership | 1,000+ |
| **Total** | | **7,000+** |

---

## EXAM REQUIREMENTS

### Apprenticeship Exams
| Exam | Content | Format |
|------|---------|--------|
| NEAT (Northwest Lineman College) Aptitude | Reading, math, mechanical aptitude | Multiple choice |
| IBEW Aptitude Test (NJATC) | Algebra, reading comprehension | Multiple choice |
| CDL Written | General knowledge, air brakes, combinations | Multiple choice |
| CDL Skills | Pre-trip, basic controls, road test | Practical |

### On-the-Job Certifications
| Cert | Content | Format |
|------|---------|--------|
| Qualified Electrical Worker | OSHA 1910.269, hazard recognition | Written + practical |
| Live Line (Hot Stick) | Minimum approach distance, PPE | Practical demo |
| Rubber Glove Work | Insulating equipment, testing | Practical demo |

**ZAFTO Exam Prep Opportunity:** Aptitude test prep, CDL prep, OSHA knowledge

---

## KEY FORMULAS & CALCULATIONS

### Sag & Tension
```
Sag = (W × L²) / (8 × T)

Where:
- W = Weight per unit length (lb/ft)
- L = Span length (ft)
- T = Horizontal tension (lbs)
- Sag = Vertical sag at mid-span (ft)
```

### Catenary Constant
```
C = T / W

Where:
- C = Catenary constant (ft)
- T = Horizontal tension (lbs)
- W = Conductor weight (lb/ft)
```

### Conductor Ampacity (Overhead)
```
Uses IEEE 738 standard
Factors: ambient temp, wind speed, solar radiation, conductor properties
```

### Pole Loading
```
Ground Line Moment = Force × Height
Safety Factor = Ultimate Strength / Applied Load (typically 4:1 for wood)
```

### Guy Wire Tension
```
T = P / (2 × sin(θ))

Where:
- T = Guy wire tension (lbs)
- P = Horizontal force on pole (lbs)
- θ = Guy wire angle from horizontal
```

### Transformer Sizing (Distribution)
```
kVA = (Connected Load × Demand Factor) / Power Factor
```

### Voltage Drop (Distribution)
```
Vd = (2 × K × I × D) / cmil

Where:
- K = Resistivity constant (12.9 for copper, 21.2 for aluminum)
- I = Current (amps)
- D = Distance (feet)
- cmil = Circular mils of conductor
```

### Fault Current (Simplified)
```
If = V / Z

Where:
- If = Fault current
- V = System voltage
- Z = Total impedance to fault
```

### Minimum Approach Distance (MAD)
| Voltage (kV) | Phase-to-Ground (ft) | Phase-to-Phase (ft) |
|--------------|---------------------|---------------------|
| 0.05-1.0 | Avoid Contact | Avoid Contact |
| 1.1-15.0 | 2.2 | 2.3 |
| 15.1-36.0 | 2.6 | 2.8 |
| 36.1-46.0 | 2.8 | 3.0 |
| 46.1-72.5 | 3.3 | 3.6 |
| 72.6-121 | 3.6 | 4.0 |
| 138-145 | 4.2 | 4.6 |
| 161-169 | 4.6 | 5.3 |
| 230-242 | 5.8 | 6.8 |
| 345-362 | 8.2 | 10.8 |
| 500-550 | 11.8 | 16.4 |
| 765-800 | 15.4 | 21.8 |

*Source: OSHA 1910.269 Table R-3*

---

## CALCULATOR IDEAS (85-100)

### Sag & Tension (15)
1. Basic sag calculator
2. Ruling span calculator
3. Catenary constant
4. Tension at temperature
5. Sag at temperature
6. Stringing chart generator
7. Slack calculator
8. Uplift check
9. Clearance at mid-span
10. Sag with ice loading
11. Sag with wind loading
12. Combined ice + wind
13. Creep calculation
14. Initial vs final sag
15. Span length from sag

### Pole & Structure (15)
16. Pole class selection
17. Ground line moment
18. Pole setting depth
19. Guy wire tension
20. Guy wire angle
21. Anchor holding capacity
22. Deadend tension
23. Vertical load calculation
24. Transverse load calculation
25. Pole circumference to class
26. Wood pole decay assessment
27. Steel pole selection
28. Crossarm loading
29. Insulator selection
30. Conductor attachment height

### Electrical Calculations (20)
31. Overhead conductor ampacity
32. Voltage drop (single phase)
33. Voltage drop (three phase)
34. Transformer sizing (distribution)
35. Transformer connections (wye/delta)
36. Fault current estimation
37. Fuse coordination
38. Recloser settings
39. Sectionalizer settings
40. Capacitor bank sizing
41. Power factor correction
42. kVA to amps conversion
43. Primary to secondary conversion
44. CT/PT ratios
45. Meter multiplier
46. Demand calculation
47. Load balancing (three phase)
48. Neutral current calculation
49. Voltage regulation
50. Line loss calculation

### Safety & Clearances (15)
51. Minimum approach distance
52. Working clearance calculator
53. Ground clearance (road crossing)
54. Ground clearance (rail crossing)
55. Clearance to buildings
56. Clearance to swimming pools
57. Vertical clearance calculator
58. Horizontal clearance calculator
59. Step potential
60. Touch potential
61. Ground grid resistance
62. Ground rod resistance
63. Arc flash boundary (utility)
64. PPE category selector
65. Hot stick length selector

### Grounding (10)
66. Ground rod resistance (single)
67. Ground rod resistance (parallel)
68. Ground grid design
69. Grounding conductor size
70. Counterpoise length
71. System grounding calculator
72. Ground fault current
73. Ground potential rise
74. Ground mat voltage
75. Soil resistivity conversion

### Rigging & Equipment (10)
76. Rope/sling capacity
77. Digger derrick reach
78. Bucket truck working height
79. Load chart calculator
80. Rigging angle factor
81. Wire rope strength
82. Grip strength (hot line)
83. Block & tackle MA
84. Capstan equation
85. Pulling tension

### Miscellaneous (10)
86. Conductor weight per foot
87. Conductor diameter
88. Temperature conversion
89. Distance conversion
90. Unit converter (utility)
91. Wire size conversion
92. Voltage class identifier
93. Phase color code
94. Bill of materials estimator
95. Time/labor estimator

---

## REFERENCE TABLES NEEDED

1. Conductor properties (ACSR, AAC, AAAC, copper)
2. Pole classes (wood, steel, concrete)
3. Insulator ratings
4. Transformer standard sizes
5. Fuse ratings and curves
6. Guy wire strengths
7. Anchor types and capacities
8. Minimum approach distances
9. Ground clearances by voltage
10. NESC loading districts

---

## SOURCES

- IEEE C2 (NESC): https://standards.ieee.org/ieee/C2/7656/
- OSHA 1910.269: https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.269
- OSHA 1926 Subpart V: https://www.osha.gov/laws-regs/regulations/standardnumber/1926/1926SubpartV
- IEEE 738 (Ampacity): https://standards.ieee.org/ieee/738/6686/
- USDA RUS: https://www.rd.usda.gov/about-rd/agencies/rural-utilities-service
- IBEW/NECA: https://www.ibew.org
- Northwest Lineman College: https://www.lineman.edu

---

## NOTES

- Linemen are often IBEW union members
- Apprenticeship is primary path (not school + license like electrician)
- Very different from inside electrician - outdoor, high voltage, weather
- CDL is essentially required (need to drive bucket trucks, digger derricks)
- "Storm work" is lucrative but grueling - travel to disaster areas
- Hot work (energized) pays more than cold work (de-energized)
