import 'dart:math' as math;
import '../data/wire_tables.dart';
import '../data/conduit_tables.dart';
import '../data/nec_tables.dart';

/// Core electrical calculations
/// 
/// All formulas validated against NEC 2023

// ============================================
// OHM'S LAW CALCULATIONS
// ============================================

/// Ohm's Law Calculator
/// 
/// V = I × R
/// I = V / R
/// R = V / I
/// P = V × I = I²R = V²/R
class OhmsLaw {
  OhmsLaw._();

  /// Calculate voltage from current and resistance
  static double voltageFromIR(double currentAmps, double resistanceOhms) {
    return currentAmps * resistanceOhms;
  }

  /// Calculate current from voltage and resistance
  static double currentFromVR(double voltage, double resistanceOhms) {
    if (resistanceOhms == 0) return double.infinity;
    return voltage / resistanceOhms;
  }

  /// Calculate resistance from voltage and current
  static double resistanceFromVI(double voltage, double currentAmps) {
    if (currentAmps == 0) return double.infinity;
    return voltage / currentAmps;
  }

  /// Calculate power from voltage and current
  static double powerFromVI(double voltage, double currentAmps) {
    return voltage * currentAmps;
  }

  /// Calculate power from current and resistance
  static double powerFromIR(double currentAmps, double resistanceOhms) {
    return currentAmps * currentAmps * resistanceOhms;
  }

  /// Calculate power from voltage and resistance
  static double powerFromVR(double voltage, double resistanceOhms) {
    if (resistanceOhms == 0) return double.infinity;
    return (voltage * voltage) / resistanceOhms;
  }

  /// Calculate current from power and voltage
  static double currentFromPV(double powerWatts, double voltage) {
    if (voltage == 0) return double.infinity;
    return powerWatts / voltage;
  }

  /// Calculate voltage from power and current
  static double voltageFromPI(double powerWatts, double currentAmps) {
    if (currentAmps == 0) return double.infinity;
    return powerWatts / currentAmps;
  }

  /// Calculate resistance from power and current
  static double resistanceFromPI(double powerWatts, double currentAmps) {
    if (currentAmps == 0) return double.infinity;
    return powerWatts / (currentAmps * currentAmps);
  }

  /// Calculate resistance from power and voltage
  static double resistanceFromPV(double powerWatts, double voltage) {
    if (powerWatts == 0) return double.infinity;
    return (voltage * voltage) / powerWatts;
  }
}

// ============================================
// SINGLE PHASE POWER
// ============================================

class SinglePhasePower {
  SinglePhasePower._();

  /// Calculate power: P = V × I × PF
  static double power(double voltage, double currentAmps, {double powerFactor = 1.0}) {
    return voltage * currentAmps * powerFactor;
  }

  /// Calculate current: I = P / (V × PF)
  static double current(double powerWatts, double voltage, {double powerFactor = 1.0}) {
    final denominator = voltage * powerFactor;
    if (denominator == 0) return double.infinity;
    return powerWatts / denominator;
  }

  /// Calculate kVA
  static double kva(double voltage, double currentAmps) {
    return (voltage * currentAmps) / 1000;
  }

  /// Calculate current from kVA
  static double currentFromKva(double kva, double voltage) {
    if (voltage == 0) return double.infinity;
    return (kva * 1000) / voltage;
  }
}

// ============================================
// THREE PHASE POWER
// ============================================

class ThreePhasePower {
  ThreePhasePower._();

  static const double sqrt3 = 1.732;

  /// Calculate power: P = √3 × V × I × PF
  static double power(double voltage, double currentAmps, {double powerFactor = 1.0}) {
    return sqrt3 * voltage * currentAmps * powerFactor;
  }

  /// Calculate current: I = P / (√3 × V × PF)
  static double current(double powerWatts, double voltage, {double powerFactor = 1.0}) {
    final denominator = sqrt3 * voltage * powerFactor;
    if (denominator == 0) return double.infinity;
    return powerWatts / denominator;
  }

  /// Calculate kVA
  static double kva(double voltage, double currentAmps) {
    return (sqrt3 * voltage * currentAmps) / 1000;
  }

  /// Calculate current from kVA
  static double currentFromKva(double kva, double voltage) {
    if (voltage == 0) return double.infinity;
    return (kva * 1000) / (sqrt3 * voltage);
  }
}

// ============================================
// VOLTAGE DROP
// ============================================

/// Voltage Drop Calculator
/// 
/// VD = (2 × K × I × D) / CM
/// Where:
///   K = resistivity (12.9 copper, 21.2 aluminum)
///   I = current in amps
///   D = one-way distance in feet
///   CM = circular mils of conductor
class VoltageDrop {
  VoltageDrop._();

  /// Calculate voltage drop in volts
  /// 
  /// [currentAmps] - Load current
  /// [distanceFeet] - One-way distance
  /// [wireSize] - Wire gauge
  /// [material] - Copper or Aluminum
  /// [phaseMultiplier] - 2 for single phase, √3 for three phase
  static double calculate({
    required double currentAmps,
    required double distanceFeet,
    required WireSize wireSize,
    ConductorMaterial material = ConductorMaterial.copper,
    double phaseMultiplier = 2.0, // 2 for 1Φ, 1.732 for 3Φ
  }) {
    final k = material.resistivityK;
    final cm = wireSize.circularMils;
    
    return (phaseMultiplier * k * currentAmps * distanceFeet) / cm;
  }

  /// Calculate voltage drop as percentage
  static double calculatePercent({
    required double currentAmps,
    required double distanceFeet,
    required WireSize wireSize,
    required double systemVoltage,
    ConductorMaterial material = ConductorMaterial.copper,
    double phaseMultiplier = 2.0,
  }) {
    final vd = calculate(
      currentAmps: currentAmps,
      distanceFeet: distanceFeet,
      wireSize: wireSize,
      material: material,
      phaseMultiplier: phaseMultiplier,
    );
    return (vd / systemVoltage) * 100;
  }

  /// Check if voltage drop is within NEC recommendations
  static bool isAcceptable(
    double vdPercent, {
    bool isBranchCircuit = true,
  }) {
    return vdPercent <= (isBranchCircuit ? 3.0 : 5.0);
  }

  /// Find minimum wire size for acceptable voltage drop
  static WireSize? findMinWireSize({
    required double currentAmps,
    required double distanceFeet,
    required double systemVoltage,
    required double maxVdPercent,
    ConductorMaterial material = ConductorMaterial.copper,
    double phaseMultiplier = 2.0,
  }) {
    // Calculate required circular mils
    final k = material.resistivityK;
    final maxVd = systemVoltage * (maxVdPercent / 100);
    final requiredCm = (phaseMultiplier * k * currentAmps * distanceFeet) / maxVd;

    // Find smallest wire that meets requirement
    for (final size in WireSize.values) {
      if (size.circularMils >= requiredCm) {
        return size;
      }
    }
    return null; // No wire size in table meets requirement
  }
}

// ============================================
// CONDUIT FILL
// ============================================

/// Conduit Fill Calculator
/// 
/// Per NEC Chapter 9:
/// - 1 wire: 53% max
/// - 2 wires: 31% max
/// - 3+ wires: 40% max
class ConduitFill {
  ConduitFill._();

  /// Calculate fill percentage
  /// 
  /// Returns (fillPercent, isCompliant, maxAllowed)
  static ({double fillPercent, bool isCompliant, double maxAllowed}) calculate({
    required ConduitType conduitType,
    required TradeSize conduitSize,
    required Map<WireSize, int> wires, // WireSize -> count
  }) {
    // Get conduit area
    final conduitArea = ConduitDimensions.getTotalArea(conduitType, conduitSize);
    if (conduitArea == null) {
      return (fillPercent: 0, isCompliant: false, maxAllowed: 0);
    }

    // Calculate total wire area
    double totalWireArea = 0;
    int totalWireCount = 0;
    
    for (final entry in wires.entries) {
      final wireArea = WireDimensions.getArea(entry.key);
      if (wireArea != null) {
        totalWireArea += wireArea * entry.value;
        totalWireCount += entry.value;
      }
    }

    // Get max fill based on wire count
    final maxFill = ConduitFillLimits.getMaxFillPercent(totalWireCount);
    final fillPercent = totalWireArea / conduitArea;
    
    return (
      fillPercent: fillPercent * 100, // Convert to percentage
      isCompliant: fillPercent <= maxFill,
      maxAllowed: maxFill * 100,
    );
  }

  /// Find minimum conduit size for given wires
  static TradeSize? findMinConduitSize({
    required ConduitType conduitType,
    required Map<WireSize, int> wires,
  }) {
    for (final size in TradeSize.values) {
      final result = calculate(
        conduitType: conduitType,
        conduitSize: size,
        wires: wires,
      );
      if (result.isCompliant) {
        return size;
      }
    }
    return null;
  }

  /// Calculate remaining capacity
  static double? remainingCapacity({
    required ConduitType conduitType,
    required TradeSize conduitSize,
    required Map<WireSize, int> wires,
  }) {
    final conduitArea = ConduitDimensions.getTotalArea(conduitType, conduitSize);
    if (conduitArea == null) return null;

    double usedArea = 0;
    int wireCount = 0;
    
    for (final entry in wires.entries) {
      final wireArea = WireDimensions.getArea(entry.key);
      if (wireArea != null) {
        usedArea += wireArea * entry.value;
        wireCount += entry.value;
      }
    }

    final maxFill = ConduitFillLimits.getMaxFillPercent(wireCount);
    final maxArea = conduitArea * maxFill;
    
    return maxArea - usedArea;
  }
}

// ============================================
// BOX FILL
// ============================================

/// Box Fill Calculator - NEC 314.16
class BoxFill {
  BoxFill._();

  /// Calculate required box volume
  /// 
  /// Per NEC 314.16(B):
  /// - Each conductor: based on AWG from Table 314.16(B)
  /// - All grounds together: count as 1 conductor (largest)
  /// - All clamps together: count as 1 conductor (largest)
  /// - Each device/yoke: count as 2 conductors (largest connected)
  /// - Equipment bonding jumpers: same as grounds
  static ({double requiredVolume, bool fits, String breakdown}) calculate({
    required double boxVolume,
    required int conductorAwg,
    required int hotCount,
    required int neutralCount,
    required int groundCount,
    bool hasInternalClamps = false,
    int deviceCount = 0,
  }) {
    final volumePer = BoxFillVolumes.getVolumePerConductor(conductorAwg) ?? 2.0;
    
    // Calculate each component
    final hotVolume = hotCount * volumePer;
    final neutralVolume = neutralCount * volumePer;
    final groundVolume = groundCount > 0 ? volumePer : 0; // All grounds = 1
    final clampVolume = hasInternalClamps ? volumePer : 0; // All clamps = 1
    final deviceVolume = deviceCount * 2 * volumePer; // Each device = 2
    
    final totalRequired = hotVolume + neutralVolume + groundVolume + 
                          clampVolume + deviceVolume;

    final breakdown = '''
Hot conductors: $hotCount × $volumePer = ${hotVolume.toStringAsFixed(2)} cu in
Neutral conductors: $neutralCount × $volumePer = ${neutralVolume.toStringAsFixed(2)} cu in
Grounds (all): ${groundCount > 0 ? 1 : 0} × $volumePer = ${groundVolume.toStringAsFixed(2)} cu in
Clamps (all): ${hasInternalClamps ? 1 : 0} × $volumePer = ${clampVolume.toStringAsFixed(2)} cu in
Devices: $deviceCount × 2 × $volumePer = ${deviceVolume.toStringAsFixed(2)} cu in
───────────────────
TOTAL REQUIRED: ${totalRequired.toStringAsFixed(2)} cu in
Box capacity: ${boxVolume.toStringAsFixed(2)} cu in
''';

    return (
      requiredVolume: totalRequired,
      fits: totalRequired <= boxVolume,
      breakdown: breakdown,
    );
  }
}

// ============================================
// AMPACITY WITH DERATING
// ============================================

/// Ampacity Calculator with Derating
class Ampacity {
  Ampacity._();

  /// Calculate derated ampacity
  /// 
  /// Corrected Ampacity = Base × TempFactor × FillFactor
  static ({
    int baseAmpacity,
    double correctedAmpacity,
    double tempFactor,
    double fillFactor,
  }) calculate({
    required WireSize wireSize,
    required TempRating tempRating,
    ConductorMaterial material = ConductorMaterial.copper,
    int ambientTempC = 30,
    int conductorCount = 3,
  }) {
    // Get base ampacity from table
    final baseAmpacity = material == ConductorMaterial.copper
        ? AmpacityTableCopper.getAmpacity(wireSize, tempRating)
        : AmpacityTableAluminum.getAmpacity(wireSize, tempRating);
    
    if (baseAmpacity == null) {
      return (
        baseAmpacity: 0,
        correctedAmpacity: 0,
        tempFactor: 1.0,
        fillFactor: 1.0,
      );
    }

    // Get correction factors
    final tempFactor = TempCorrectionFactors.getFactor(ambientTempC, tempRating);
    final fillFactor = ConduitFillAdjustment.getFactor(conductorCount);
    
    // Calculate corrected ampacity
    final corrected = baseAmpacity * tempFactor * fillFactor;

    return (
      baseAmpacity: baseAmpacity,
      correctedAmpacity: corrected,
      tempFactor: tempFactor,
      fillFactor: fillFactor,
    );
  }
}

// ============================================
// WIRE SIZING (SMART)
// ============================================

/// Smart Wire Sizing - The "killer feature"
/// 
/// Input: Load amps + distance
/// Output: Complete material list with compliance checks
class WireSizing {
  WireSizing._();

  /// Calculate complete wire sizing solution
  static WireSizingResult calculate({
    required double loadAmps,
    required double distanceFeet,
    required double systemVoltage,
    required int breakerAmps,
    TempRating tempRating = TempRating.temp75c,
    ConductorMaterial material = ConductorMaterial.copper,
    int ambientTempC = 30,
    bool isThreePhase = false,
    double maxVoltageDropPercent = 3.0,
  }) {
    // 1. Find wire size for ampacity
    WireSize? ampacityWire;
    int? ampacity;
    
    for (final size in WireSize.values) {
      final amp = material == ConductorMaterial.copper
          ? AmpacityTableCopper.getAmpacity(size, tempRating)
          : AmpacityTableAluminum.getAmpacity(size, tempRating);
      
      if (amp != null && amp >= breakerAmps) {
        ampacityWire = size;
        ampacity = amp;
        break;
      }
    }

    // 2. Find wire size for voltage drop
    final vdWire = VoltageDrop.findMinWireSize(
      currentAmps: loadAmps,
      distanceFeet: distanceFeet,
      systemVoltage: systemVoltage,
      maxVdPercent: maxVoltageDropPercent,
      material: material,
      phaseMultiplier: isThreePhase ? 1.732 : 2.0,
    );

    // 3. Use larger of the two
    WireSize? recommendedWire;
    if (ampacityWire != null && vdWire != null) {
      recommendedWire = ampacityWire.circularMils >= vdWire.circularMils 
          ? ampacityWire 
          : vdWire;
    } else {
      recommendedWire = ampacityWire ?? vdWire;
    }

    // 4. Calculate actual voltage drop with recommended wire
    double actualVdPercent = 0;
    if (recommendedWire != null) {
      actualVdPercent = VoltageDrop.calculatePercent(
        currentAmps: loadAmps,
        distanceFeet: distanceFeet,
        wireSize: recommendedWire,
        systemVoltage: systemVoltage,
        material: material,
        phaseMultiplier: isThreePhase ? 1.732 : 2.0,
      );
    }

    // 5. Get ground wire size
    final groundSize = EquipmentGroundingConductor.getSize(breakerAmps);

    // 6. Find conduit size (assuming THHN for now)
    TradeSize? conduitSize;
    if (recommendedWire != null) {
      final wireCount = isThreePhase ? 4 : 3; // 3Φ = 3 hots + ground, 1Φ = 2 hots + ground
      // Simplified - real app would parse ground wire size to WireSize enum
      conduitSize = ConduitFill.findMinConduitSize(
        conduitType: ConduitType.emt,
        wires: {recommendedWire: wireCount},
      );
    }

    return WireSizingResult(
      loadAmps: loadAmps,
      breakerAmps: breakerAmps,
      distanceFeet: distanceFeet,
      systemVoltage: systemVoltage,
      
      recommendedWire: recommendedWire,
      wireAmpacity: ampacity,
      ampacityPasses: ampacity != null && ampacity >= breakerAmps,
      
      voltageDropPercent: actualVdPercent,
      voltageDropVolts: (actualVdPercent / 100) * systemVoltage,
      voltageDropPasses: actualVdPercent <= maxVoltageDropPercent,
      
      groundWireCopper: groundSize?.$1,
      groundWireAluminum: groundSize?.$2,
      
      recommendedConduit: conduitSize,
      conduitType: ConduitType.emt,
      
      material: material,
      tempRating: tempRating,
      isThreePhase: isThreePhase,
    );
  }
}

/// Result of wire sizing calculation
class WireSizingResult {
  final double loadAmps;
  final int breakerAmps;
  final double distanceFeet;
  final double systemVoltage;
  
  final WireSize? recommendedWire;
  final int? wireAmpacity;
  final bool ampacityPasses;
  
  final double voltageDropPercent;
  final double voltageDropVolts;
  final bool voltageDropPasses;
  
  final String? groundWireCopper;
  final String? groundWireAluminum;
  
  final TradeSize? recommendedConduit;
  final ConduitType conduitType;
  
  final ConductorMaterial material;
  final TempRating tempRating;
  final bool isThreePhase;

  const WireSizingResult({
    required this.loadAmps,
    required this.breakerAmps,
    required this.distanceFeet,
    required this.systemVoltage,
    required this.recommendedWire,
    required this.wireAmpacity,
    required this.ampacityPasses,
    required this.voltageDropPercent,
    required this.voltageDropVolts,
    required this.voltageDropPasses,
    required this.groundWireCopper,
    required this.groundWireAluminum,
    required this.recommendedConduit,
    required this.conduitType,
    required this.material,
    required this.tempRating,
    required this.isThreePhase,
  });

  bool get allChecksPassed => ampacityPasses && voltageDropPasses;
}
