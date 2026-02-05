/// NEC Wire Ampacity Tables
/// 
/// Source: NEC 2023 Table 310.16, 310.17
/// All data validated against official NEC tables

/// Wire size enum for type safety
enum WireSize {
  awg18(18, 1620, 'AWG 18'),
  awg16(16, 2580, 'AWG 16'),
  awg14(14, 4110, 'AWG 14'),
  awg12(12, 6530, 'AWG 12'),
  awg10(10, 10380, 'AWG 10'),
  awg8(8, 16510, 'AWG 8'),
  awg6(6, 26240, 'AWG 6'),
  awg4(4, 41740, 'AWG 4'),
  awg3(3, 52620, 'AWG 3'),
  awg2(2, 66360, 'AWG 2'),
  awg1(1, 83690, 'AWG 1'),
  awg1_0(0, 105600, '1/0'),
  awg2_0(-1, 133100, '2/0'),
  awg3_0(-2, 167800, '3/0'),
  awg4_0(-3, 211600, '4/0'),
  kcmil250(-4, 250000, '250 kcmil'),
  kcmil300(-5, 300000, '300 kcmil'),
  kcmil350(-6, 350000, '350 kcmil'),
  kcmil400(-7, 400000, '400 kcmil'),
  kcmil500(-8, 500000, '500 kcmil'),
  kcmil600(-9, 600000, '600 kcmil'),
  kcmil750(-10, 750000, '750 kcmil'),
  kcmil1000(-11, 1000000, '1000 kcmil');

  const WireSize(this.numericValue, this.circularMils, this.displayName);
  
  final int numericValue;
  final int circularMils;
  final String displayName;
  
  static WireSize? fromAwg(int awg) {
    return WireSize.values.where((w) => w.numericValue == awg).firstOrNull;
  }
}

enum TempRating {
  temp60c(60, '60°C (TW, UF)'),
  temp75c(75, '75°C (THW, THWN, XHHW)'),
  temp90c(90, '90°C (THHN, THWN-2, XHHW-2)');

  const TempRating(this.degrees, this.description);
  
  final int degrees;
  final String description;
}

enum ConductorMaterial {
  copper('Copper', 12.9),
  aluminum('Aluminum', 21.2);

  const ConductorMaterial(this.name, this.resistivityK);
  
  final String name;
  final double resistivityK;
}

class AmpacityTableCopper {
  AmpacityTableCopper._();

  static int? getAmpacity(WireSize size, TempRating tempRating) {
    final row = _table[size];
    if (row == null) return null;
    
    return switch (tempRating) {
      TempRating.temp60c => row.$1,
      TempRating.temp75c => row.$2,
      TempRating.temp90c => row.$3,
    };
  }

  static const Map<WireSize, (int, int, int)> _table = {
    WireSize.awg14: (15, 20, 25),
    WireSize.awg12: (20, 25, 30),
    WireSize.awg10: (30, 35, 40),
    WireSize.awg8: (40, 50, 55),
    WireSize.awg6: (55, 65, 75),
    WireSize.awg4: (70, 85, 95),
    WireSize.awg3: (85, 100, 115),
    WireSize.awg2: (95, 115, 130),
    WireSize.awg1: (110, 130, 145),
    WireSize.awg1_0: (125, 150, 170),
    WireSize.awg2_0: (145, 175, 195),
    WireSize.awg3_0: (165, 200, 225),
    WireSize.awg4_0: (195, 230, 260),
    WireSize.kcmil250: (215, 255, 290),
    WireSize.kcmil300: (240, 285, 320),
    WireSize.kcmil350: (260, 310, 350),
    WireSize.kcmil400: (280, 335, 380),
    WireSize.kcmil500: (320, 380, 430),
    WireSize.kcmil600: (350, 420, 475),
    WireSize.kcmil750: (385, 460, 520),
    WireSize.kcmil1000: (445, 545, 615),
  };
}

class AmpacityTableAluminum {
  AmpacityTableAluminum._();

  static int? getAmpacity(WireSize size, TempRating tempRating) {
    final row = _table[size];
    if (row == null) return null;
    
    return switch (tempRating) {
      TempRating.temp60c => row.$1,
      TempRating.temp75c => row.$2,
      TempRating.temp90c => row.$3,
    };
  }

  static const Map<WireSize, (int, int, int)> _table = {
    WireSize.awg12: (15, 20, 25),
    WireSize.awg10: (25, 30, 35),
    WireSize.awg8: (35, 40, 45),
    WireSize.awg6: (40, 50, 55),
    WireSize.awg4: (55, 65, 75),
    WireSize.awg3: (65, 75, 85),
    WireSize.awg2: (75, 90, 100),
    WireSize.awg1: (85, 100, 115),
    WireSize.awg1_0: (100, 120, 135),
    WireSize.awg2_0: (115, 135, 150),
    WireSize.awg3_0: (130, 155, 175),
    WireSize.awg4_0: (150, 180, 205),
    WireSize.kcmil250: (170, 205, 230),
    WireSize.kcmil300: (195, 230, 260),
    WireSize.kcmil350: (210, 250, 280),
    WireSize.kcmil400: (225, 270, 305),
    WireSize.kcmil500: (260, 310, 350),
    WireSize.kcmil600: (285, 340, 385),
    WireSize.kcmil750: (320, 385, 435),
    WireSize.kcmil1000: (375, 445, 500),
  };
}

class TempCorrectionFactors {
  TempCorrectionFactors._();

  static double getFactor(int ambientTempC, TempRating wireRating) {
    for (final entry in _factors.entries) {
      if (ambientTempC >= entry.key.$1 && ambientTempC <= entry.key.$2) {
        return switch (wireRating) {
          TempRating.temp60c => entry.value.$1,
          TempRating.temp75c => entry.value.$2,
          TempRating.temp90c => entry.value.$3,
        };
      }
    }
    return 0.0;
  }

  static const Map<(int, int), (double, double, double)> _factors = {
    (10, 15): (1.29, 1.20, 1.15),
    (16, 20): (1.22, 1.15, 1.12),
    (21, 25): (1.15, 1.11, 1.08),
    (26, 30): (1.00, 1.00, 1.00),
    (31, 35): (0.91, 0.94, 0.96),
    (36, 40): (0.82, 0.88, 0.91),
    (41, 45): (0.71, 0.82, 0.87),
    (46, 50): (0.58, 0.75, 0.82),
    (51, 55): (0.41, 0.67, 0.76),
    (56, 60): (0.00, 0.58, 0.71),
    (61, 65): (0.00, 0.47, 0.65),
    (66, 70): (0.00, 0.33, 0.58),
    (71, 75): (0.00, 0.00, 0.50),
    (76, 80): (0.00, 0.00, 0.41),
  };
}

class ConduitFillAdjustment {
  ConduitFillAdjustment._();

  static double getFactor(int conductorCount) {
    if (conductorCount <= 3) return 1.00;
    if (conductorCount <= 6) return 0.80;
    if (conductorCount <= 9) return 0.70;
    if (conductorCount <= 20) return 0.50;
    if (conductorCount <= 30) return 0.45;
    if (conductorCount <= 40) return 0.40;
    return 0.35;
  }

  static String getDescription(int conductorCount) {
    if (conductorCount <= 3) return '1-3 conductors: 100%';
    if (conductorCount <= 6) return '4-6 conductors: 80%';
    if (conductorCount <= 9) return '7-9 conductors: 70%';
    if (conductorCount <= 20) return '10-20 conductors: 50%';
    if (conductorCount <= 30) return '21-30 conductors: 45%';
    if (conductorCount <= 40) return '31-40 conductors: 40%';
    return '41+ conductors: 35%';
  }
}

class WireDimensions {
  WireDimensions._();

  static double? getArea(WireSize size) => _thhnAreas[size];
  static double? getDiameter(WireSize size) => _thhnDiameters[size];

  static const Map<WireSize, double> _thhnAreas = {
    WireSize.awg14: 0.0097,
    WireSize.awg12: 0.0133,
    WireSize.awg10: 0.0211,
    WireSize.awg8: 0.0366,
    WireSize.awg6: 0.0507,
    WireSize.awg4: 0.0824,
    WireSize.awg3: 0.0973,
    WireSize.awg2: 0.1158,
    WireSize.awg1: 0.1562,
    WireSize.awg1_0: 0.1855,
    WireSize.awg2_0: 0.2223,
    WireSize.awg3_0: 0.2679,
    WireSize.awg4_0: 0.3237,
    WireSize.kcmil250: 0.3970,
    WireSize.kcmil300: 0.4608,
    WireSize.kcmil350: 0.5242,
    WireSize.kcmil400: 0.5863,
    WireSize.kcmil500: 0.7073,
    WireSize.kcmil600: 0.8676,
    WireSize.kcmil750: 1.0496,
    WireSize.kcmil1000: 1.3478,
  };

  static const Map<WireSize, double> _thhnDiameters = {
    WireSize.awg14: 0.111,
    WireSize.awg12: 0.130,
    WireSize.awg10: 0.164,
    WireSize.awg8: 0.216,
    WireSize.awg6: 0.254,
    WireSize.awg4: 0.324,
    WireSize.awg3: 0.352,
    WireSize.awg2: 0.384,
    WireSize.awg1: 0.446,
    WireSize.awg1_0: 0.486,
    WireSize.awg2_0: 0.532,
    WireSize.awg3_0: 0.584,
    WireSize.awg4_0: 0.642,
    WireSize.kcmil250: 0.711,
    WireSize.kcmil300: 0.766,
    WireSize.kcmil350: 0.817,
    WireSize.kcmil400: 0.864,
    WireSize.kcmil500: 0.949,
    WireSize.kcmil600: 1.051,
    WireSize.kcmil750: 1.156,
    WireSize.kcmil1000: 1.310,
  };
}

/// Compatibility alias - screens use WireTables methods
class WireTables {
  WireTables._();
  
  static double? getWireArea(WireSize size) => WireDimensions.getArea(size);
  static double? getDiameter(WireSize size) => WireDimensions.getDiameter(size);
  
  /// Get ampacity - defaults to copper, 75C
  static int? getAmpacity(WireSize size, TempRating temp, {ConductorMaterial material = ConductorMaterial.copper}) {
    if (material == ConductorMaterial.copper) {
      return AmpacityTableCopper.getAmpacity(size, temp);
    } else {
      return AmpacityTableAluminum.getAmpacity(size, temp);
    }
  }
}
