# ELECTRICAL CALCULATOR BUILD PROGRESS
## Resume Point for Claude

**Started:** February 1, 2026
**Goal:** Complete all 96 electrical calculators

---

## EXISTING (55 built)
- [x] ampacity
- [x] arc_flash
- [x] bathroom_circuit
- [x] bonding_jumper
- [x] box_fill
- [x] cable_tray
- [x] commercial_load
- [x] conductor_weight
- [x] conduit_bend_radius
- [x] conduit_bending
- [x] conduit_fill
- [x] conduit_support_spacing
- [x] continuous_load
- [x] derating_advanced
- [x] disconnect
- [x] dryer_circuit
- [x] dwelling_load
- [x] electric_range
- [x] ev_charger
- [x] expansion_fitting
- [x] fault_current
- [x] generator_sizing
- [x] ground_rod
- [x] grounding
- [x] hvac_circuit
- [x] junction_box_sizing
- [x] kitchen_circuit
- [x] lighting_sqft
- [x] lumen
- [x] motor_circuit
- [x] motor_fla
- [x] motor_inrush
- [x] motor_starter
- [x] mwbc
- [x] ohms_law
- [x] parallel_conductor
- [x] pool_spa
- [x] power_converter
- [x] power_factor
- [x] pull_box
- [x] raceway
- [x] recessed_light
- [x] service_entrance
- [x] solar_pv
- [x] tap_rule
- [x] transformer
- [x] transformer_protection
- [x] unit_converter
- [x] ups_sizing
- [x] vfd_sizing
- [x] voltage_drop
- [x] water_heater
- [x] wire_pull_tension
- [x] wire_sizing
- [x] working_space

---

## TO BUILD (41 remaining)

### Load Calculators
- [ ] 1. conduit_length_estimator - Total conduit run from layout
- [ ] 2. wireway_fill - Lay-in wireway calculations
- [ ] 3. dedicated_space - NEC 110.26(F) above panel
- [ ] 4. enclosure_sizing - NEMA box size for components
- [ ] 5. demand_factor - Apply demand factors by load type
- [ ] 6. feeder_calculator - Feeder sizing with demand
- [ ] 7. optional_calculation - NEC 220.82/83 method
- [ ] 8. multifamily - Apartment building loads
- [ ] 9. restaurant_load - Commercial kitchen loads

### Motor Calculators
- [ ] 10. motor_disconnect - NEC 430.109 requirements
- [ ] 11. motor_feeder - NEC 430.24 multiple motors
- [ ] 12. soft_start - Reduced voltage starter

### Transformer Calculators
- [ ] 13. transformer_impedance - Fault current contribution
- [ ] 14. buck_boost - Voltage correction sizing
- [ ] 15. transformer_taps - Voltage adjustment taps

### Protection Calculators
- [ ] 16. selective_coordination - Breaker coordination checker
- [ ] 17. available_fault_current - Point-to-point method
- [ ] 18. series_rating - Series-rated combination

### Grounding Calculators
- [ ] 19. ground_ring - Perimeter grounding
- [ ] 20. intersystem_bonding - Communications grounding

### Specialty Calculators
- [ ] 21. emergency_standby_load - NEC 700/701/702

### Lighting Calculators
- [ ] 22. emergency_lighting - NEC 700 egress lighting
- [ ] 23. exit_sign_placement - Code-required locations
- [ ] 24. lighting_control - Dimmer and switch loads
- [ ] 25. parking_lot_lighting - Pole spacing and lumens

### Low Voltage Calculators
- [ ] 26. fire_alarm_circuit - NFPA 72 wire sizing
- [ ] 27. security_wire - Gauge by distance
- [ ] 28. network_cable - Cat5e/Cat6 run limits
- [ ] 29. audio_video_wire - Speaker wire sizing
- [ ] 30. doorbell_transformer - VA sizing
- [ ] 31. thermostat_wire - HVAC control wiring

### Power Quality Calculators
- [ ] 32. harmonics - THD and K-factor
- [ ] 33. voltage_imbalance - 3-phase imbalance %
- [ ] 34. capacitor_bank - PF correction caps
- [ ] 35. surge_protector - SPD selection

### Energy Storage Calculators
- [ ] 36. standalone_ess - kWh for backup without solar
- [ ] 37. battery_bank - Series/parallel config for off-grid
- [ ] 38. inverter_charger - Hybrid systems standalone
- [ ] 39. battery_circuit_protection - NEC 706 OCPD sizing

### EV Calculators
- [ ] 40. multi_charger_load - Load sharing for multiple EVs
- [ ] 41. fleet_charging - Commercial EV depot sizing

---

## CURRENT BUILD
**Building:** #16-21 Protection/Grounding/Emergency
**Status:** IN PROGRESS
**Completed:** 1-15 (15 calculators done)

---

## RESUME INSTRUCTIONS
Tell Claude: "Read ELECTRICAL_BUILD_PROGRESS.md and continue building from the current position"
