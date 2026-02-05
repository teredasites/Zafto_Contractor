# DIESEL MECHANIC (Diesel Technician)
## ZAFTO Intelligence File
### Last Updated: February 1, 2026

---

## OVERVIEW

**What they do:** Diagnose, repair, and maintain diesel engines and vehicles - trucks, buses, construction equipment, agricultural equipment, marine vessels, and generators.

**Market size:** ~280,000 diesel technicians in US, strong growth due to freight demand and equipment complexity.

**Why it matters for ZAFTO:** Large trade, ASE certification path, EPA requirements, complex diagnostics.

**Calculator target:** 75-90 calculators

---

## GOVERNING STANDARDS & REGULATIONS

### Primary Standards
| Standard | Publisher | Scope |
|----------|-----------|-------|
| EPA Emissions | EPA | Emission standards (Tier 4, etc.) |
| DOT FMCSA | DOT | Commercial vehicle safety |
| OSHA | DOL | Workplace safety |
| SAE Standards | SAE | Technical standards |
| OEM Specifications | Varies | Manufacturer requirements |

### Emissions Regulations
| Tier | Application | Requirements |
|------|-------------|--------------|
| Tier 4 Final | Off-road diesel | DPF, SCR, very low NOx/PM |
| EPA 2010+ | On-road trucks | DPF, SCR, OBD |
| IMO Tier III | Marine | NOx reduction |
| CARB | California | Stricter than federal |

### Key Technical Standards
| Standard | Scope |
|----------|-------|
| SAE J1939 | Heavy-duty vehicle networks (CAN) |
| SAE J1587/J1708 | Legacy diagnostic protocols |
| SAE J1979 | OBD-II diagnostic modes |
| SAE J2012 | Diagnostic trouble codes |

---

## STATE LICENSING

**Diesel mechanics are NOT typically licensed by states** - certification is through ASE and manufacturer training.

| State | License Required | Notes |
|-------|------------------|-------|
| Most States | No | ASE certification voluntary but expected |
| California | Smog License | For emission repairs |
| Some localities | Business license | Shop licensing only |

### ASE Certification (Primary Credential)

**Medium/Heavy Truck Series (T-Series)**
| Test | Content |
|------|---------|
| T1 | Gasoline Engines |
| T2 | Diesel Engines |
| T3 | Drive Train |
| T4 | Brakes |
| T5 | Suspension and Steering |
| T6 | Electrical/Electronic Systems |
| T7 | Heating, Ventilation, and A/C |
| T8 | Preventive Maintenance Inspection |

**Specialty Tests**
| Test | Content |
|------|---------|
| H1 | Compressed Natural Gas Vehicles |
| H2 | Diesel Engines (Transit Bus) |
| H3-H8 | Transit Bus Specialty |
| S1 | School Bus |
| E3 | Auxiliary Power Systems (APU) |

**Master Technician:** Pass all T1-T8 tests

### Other Certifications
| Certification | Issuer | Purpose |
|---------------|--------|---------|
| EPA 608 | EPA | Refrigerant handling (A/C) |
| DOT Brake Inspector | DOT | Commercial vehicle brakes |
| OEM Certification | Cummins, Caterpillar, etc. | Brand-specific |
| Forklift Certification | OSHA | Powered industrial trucks |
| CDL Class A/B | State | Test driving repaired vehicles |

---

## EXAM CONTENT

### ASE T2 (Diesel Engines) - Primary
| Topic | Questions | Weight |
|-------|-----------|--------|
| General Engine Diagnosis | 12 | 24% |
| Cylinder Head and Valve Train | 9 | 18% |
| Engine Block | 8 | 16% |
| Lubrication and Cooling Systems | 8 | 16% |
| Air Induction and Exhaust Systems | 6 | 12% |
| Fuel System | 7 | 14% |
| **Total** | **50** | **100%** |

### ASE T6 (Electrical/Electronic)
| Topic | Weight |
|-------|--------|
| General Electrical System Diagnosis | 14% |
| Battery and Starting System | 16% |
| Charging System | 14% |
| Lighting Systems | 14% |
| Gauges and Warning Devices | 12% |
| Related Electrical Systems | 16% |
| Data Bus Systems | 14% |

---

## KEY FORMULAS & CALCULATIONS

### Engine Performance

**Horsepower**
```
HP = (Torque × RPM) / 5252

Where:
- HP = Horsepower
- Torque = lb-ft
- RPM = Engine speed
```

**Brake Specific Fuel Consumption**
```
BSFC = Fuel Flow (lb/hr) / HP

Good diesel: 0.30-0.35 lb/hp-hr
```

**Engine Displacement**
```
Displacement = π × (Bore/2)² × Stroke × Cylinders

In cubic inches or liters
```

**Compression Ratio**
```
CR = (Swept Volume + Clearance Volume) / Clearance Volume

Typical diesel: 15:1 to 22:1
```

### Fuel System

**Fuel Injection Timing**
```
Timing (degrees BTDC) = Per OEM specification
Typically 8-20° BTDC
```

**Fuel Pressure**
```
Common rail: 20,000-30,000 psi
Unit injector: 20,000-30,000 psi
Mechanical: 2,000-5,000 psi
```

**Fuel Consumption**
```
GPH = (HP × BSFC) / 7.1

Where:
- GPH = Gallons per hour
- HP = Actual horsepower
- BSFC = Brake specific fuel consumption
- 7.1 = lbs per gallon (diesel)
```

### Electrical Calculations

**Ohm's Law**
```
V = I × R
I = V / R
R = V / I
P = V × I = I²R = V²/R
```

**Battery Capacity**
```
Reserve Capacity (RC) = Minutes at 25A to 10.5V
CCA = Amps for 30 sec at 0°F to 7.2V

Truck batteries: typically 500-1000+ CCA
```

**Voltage Drop**
```
Max allowable:
- Starter circuit: 0.5V
- Ground circuit: 0.1V
- Control circuits: 0.2V
```

**Wire Sizing**
```
Circular Mils = (Current × Distance × 10.75) / Allowable Drop

Or use SAE wire gauge tables
```

### Cooling System

**Coolant Flow Rate**
```
GPM = BTU/hr / (500 × ΔT)

Where ΔT = temperature rise through engine
```

**Thermostat Testing**
```
Opening temp: Typically 180-195°F
Full open: 20°F above opening
```

**Pressure Cap Testing**
```
Typical range: 7-16 psi
Test at specified pressure
```

### Lubrication

**Oil Pressure**
```
Typical idle: 10-15 psi minimum
Typical operating: 30-70 psi
Rule: 10 psi per 1000 RPM (minimum)
```

**Oil Consumption**
```
Normal: <1 qt per 500-1000 miles (varies by engine)
Calculate: Miles / Quarts Added
```

### Air System (Brakes)

**Air Pressure**
```
Governor cut-in: ~100 psi
Governor cut-out: ~125 psi
Low pressure warning: 60 psi
DOT minimum: 100 psi to release parking brake
```

**Air Tank Capacity**
```
Must have enough for multiple full brake applications
Typical: 12+ applications before 60 psi
```

### Turbocharger

**Boost Pressure**
```
Typical: 15-40 psi depending on engine
Wastegate setting: Per OEM
VGT position: % open
```

**Compressor Efficiency**
```
η = (Ideal temp rise) / (Actual temp rise)
Typical: 65-75%
```

### DEF/SCR System

**DEF Consumption**
```
Typical: 2-3% of diesel consumption
DEF freeze point: 12°F (-11°C)
```

**NOx Conversion Efficiency**
```
Target: >90%
Measured via OBD or analyzer
```

---

## CALCULATOR IDEAS (75-90)

### Engine Performance (15)
1. Horsepower calculator
2. Torque calculator
3. Displacement calculator
4. Compression ratio
5. BSFC calculator
6. Fuel consumption (GPH)
7. Air/fuel ratio
8. Volumetric efficiency
9. Mean effective pressure
10. Engine speed from gear/tire
11. Power loss (altitude)
12. Power loss (temperature)
13. Dynamometer correction
14. HP to kW converter
15. Engine efficiency

### Fuel System (10)
16. Injector flow rate
17. Fuel pressure conversion
18. Fuel return volume
19. Injector timing
20. Fuel filter restriction
21. Fuel tank capacity
22. Range calculator
23. Fuel cost per mile
24. Fuel density/temperature
25. Common rail pressure

### Electrical (15)
26. Ohm's law calculator
27. Voltage drop calculator
28. Wire size calculator
29. Battery CCA requirements
30. Parasitic draw test
31. Alternator output
32. Starter current draw
33. Circuit resistance
34. Fuse sizing
35. Relay coil current
36. LED conversion
37. PWM duty cycle
38. CAN bus diagnostics
39. Injector pulse width
40. Sensor voltage conversion

### Cooling System (8)
41. Coolant flow rate
42. Coolant mixture ratio
43. Pressure cap test
44. Thermostat test temp
45. Fan clutch engagement
46. Radiator capacity
47. Coolant freeze point
48. Heat rejection

### Lubrication (6)
49. Oil pressure check
50. Oil consumption rate
51. Oil change interval
52. Oil capacity calculator
53. Oil viscosity selector
54. Oil sample analysis

### Air/Brakes (10)
55. Air system capacity
56. Governor settings
57. Brake stroke adjustment
58. Brake torque
59. Stopping distance
60. Air leak down test
61. Compressor efficiency
62. Brake balance
63. ABS diagnostics
64. Spring brake release

### Turbo/Emissions (10)
65. Boost pressure check
66. Turbo speed calculator
67. Intercooler efficiency
68. EGR flow rate
69. DPF soot load
70. DPF regen interval
71. DEF consumption
72. SCR efficiency
73. NOx conversion
74. Opacity/smoke reading

### Drivetrain (8)
75. Gear ratio calculator
76. Final drive ratio
77. Tire revolutions/mile
78. Speedometer calibration
79. Driveline angle
80. U-joint working angle
81. Axle capacity
82. GVW/GCWR check

### Diagnostics (7)
83. DTC lookup (J1939)
84. PID value reference
85. Scan tool data analysis
86. Fault tree guide
87. TSB lookup helper
88. Component locator
89. Wiring diagram reference

### General (3)
90. Unit converter (diesel)
91. Torque converter (fasteners)
92. Decimal/metric converter

---

## REFERENCE TABLES NEEDED

1. Engine specifications (Cummins, Cat, Detroit, etc.)
2. Torque specifications
3. Wire gauge tables
4. SAE J1939 PID list
5. DTC definitions
6. Fluid capacities
7. Tire size calculator
8. Gear ratios
9. Filter cross-reference
10. DEF specifications

---

## SOURCES

- ASE (Automotive Service Excellence): https://www.ase.com
- SAE International: https://www.sae.org
- EPA Heavy-Duty Vehicles: https://www.epa.gov/regulations-emissions-vehicles-and-engines
- DOT FMCSA: https://www.fmcsa.dot.gov
- Cummins: https://www.cummins.com
- Caterpillar: https://www.cat.com
- Detroit Diesel: https://www.demanddetroit.com

---

## NOTES

- ASE T-series certification is industry standard
- OEM training (Cummins, Cat, Detroit, Paccar) often required for dealer work
- CDL helpful for test drives and shop moves
- EPA 608 required for A/C work
- Emissions systems (DPF, SCR, EGR) are major service area
- Telematics/diagnostics increasingly computer-based
- Electric/hybrid trucks emerging (new skill set needed)
- Fleet work vs independent shop vs dealer = different specializations
