/// NEC Motor Tables and Additional Reference Data
/// 
/// Source: NEC 2023 Tables 430.248, 430.250, 250.122, 250.66, 314.16, 240.6

// ============================================
// MOTOR FLA TABLES
// ============================================

/// Single Phase Motor Full Load Amps - NEC Table 430.248
class SinglePhaseMotorFla {
  SinglePhaseMotorFla._();

  /// Get FLA for single phase motor
  /// Returns null if HP/voltage combination not in table
  static double? getFla(double hp, int voltage) {
    final hpKey = _normalizeHp(hp);
    final row = _table[hpKey];
    if (row == null) return null;
    
    return switch (voltage) {
      115 => row.$1,
      200 => row.$2,
      208 => row.$3,
      230 => row.$4,
      _ => null,
    };
  }

  static String _normalizeHp(double hp) {
    // Handle fractional HP - return string key
    if (hp <= 0.167) return '0.167'; // 1/6 HP
    if (hp <= 0.25) return '0.25';   // 1/4 HP
    if (hp <= 0.333) return '0.333'; // 1/3 HP
    if (hp <= 0.5) return '0.5';     // 1/2 HP
    if (hp <= 0.75) return '0.75';   // 3/4 HP
    return hp.toString();
  }

  // (115V, 200V, 208V, 230V) - using String keys for const map compatibility
  static const Map<String, (double, double, double, double)> _table = {
    '0.167': (4.4, 2.5, 2.4, 2.2),      // 1/6 HP
    '0.25': (5.8, 3.3, 3.2, 2.9),       // 1/4 HP
    '0.333': (7.2, 4.1, 4.0, 3.6),      // 1/3 HP
    '0.5': (9.8, 5.6, 5.4, 4.9),        // 1/2 HP
    '0.75': (13.8, 7.9, 7.6, 6.9),      // 3/4 HP
    '1.0': (16.0, 9.2, 8.8, 8.0),       // 1 HP
    '1.5': (20.0, 11.5, 11.0, 10.0),    // 1-1/2 HP
    '2.0': (24.0, 13.8, 13.2, 12.0),    // 2 HP
    '3.0': (34.0, 19.6, 18.7, 17.0),    // 3 HP
    '5.0': (56.0, 32.2, 30.8, 28.0),    // 5 HP
    '7.5': (80.0, 46.0, 44.0, 40.0),    // 7-1/2 HP
    '10.0': (100.0, 57.5, 55.0, 50.0),  // 10 HP
  };

  /// Get available HP values
  static List<double> get availableHp => 
      _table.keys.map((k) => double.parse(k)).toList()..sort();
  
  /// Get available voltages
  static List<int> get availableVoltages => [115, 200, 208, 230];
}

/// Three Phase Motor Full Load Amps - NEC Table 430.250
class ThreePhaseMotorFla {
  ThreePhaseMotorFla._();

  /// Get FLA for three phase induction motor
  static double? getFla(double hp, int voltage) {
    final row = _table[hp.toString()];
    if (row == null) return null;
    
    return switch (voltage) {
      200 => row.$1,
      208 => row.$2,
      230 => row.$3,
      460 => row.$4,
      575 => row.$5,
      _ => null,
    };
  }

  // (200V, 208V, 230V, 460V, 575V) - using String keys
  static const Map<String, (double, double, double, double, double)> _table = {
    '0.5': (2.5, 2.4, 2.2, 1.1, 0.9),
    '0.75': (3.7, 3.5, 3.2, 1.6, 1.3),
    '1.0': (4.8, 4.6, 4.2, 2.1, 1.7),
    '1.5': (6.9, 6.6, 6.0, 3.0, 2.4),
    '2.0': (7.8, 7.5, 6.8, 3.4, 2.7),
    '3.0': (11.0, 10.6, 9.6, 4.8, 3.9),
    '5.0': (17.5, 16.7, 15.2, 7.6, 6.1),
    '7.5': (25.3, 24.2, 22.0, 11.0, 9.0),
    '10.0': (32.2, 30.8, 28.0, 14.0, 11.0),
    '15.0': (48.3, 46.2, 42.0, 21.0, 17.0),
    '20.0': (62.1, 59.4, 54.0, 27.0, 22.0),
    '25.0': (78.2, 74.8, 68.0, 34.0, 27.0),
    '30.0': (92.0, 88.0, 80.0, 40.0, 32.0),
    '40.0': (120.0, 114.0, 104.0, 52.0, 41.0),
    '50.0': (150.0, 143.0, 130.0, 65.0, 52.0),
    '60.0': (177.0, 169.0, 154.0, 77.0, 62.0),
    '75.0': (221.0, 211.0, 192.0, 96.0, 77.0),
    '100.0': (285.0, 273.0, 248.0, 124.0, 99.0),
    '125.0': (359.0, 343.0, 312.0, 156.0, 125.0),
    '150.0': (414.0, 396.0, 360.0, 180.0, 144.0),
    '200.0': (552.0, 528.0, 480.0, 240.0, 192.0),
  };

  static List<double> get availableHp => 
      _table.keys.map((k) => double.parse(k)).toList()..sort();
  static List<int> get availableVoltages => [200, 208, 230, 460, 575];
}

// ============================================
// GROUNDING TABLES
// ============================================

/// Equipment Grounding Conductor - NEC Table 250.122
class EquipmentGroundingConductor {
  EquipmentGroundingConductor._();

  /// Get minimum EGC size based on overcurrent device rating
  /// Returns wire size as AWG string
  static (String copper, String aluminum)? getSize(int ocdAmps) {
    // Find the next size up if not exact match
    for (final entry in _table.entries) {
      if (ocdAmps <= entry.key) {
        return entry.value;
      }
    }
    return null; // Above table range
  }

  // Key: Max OCD rating, Value: (Copper AWG, Aluminum AWG)
  static const Map<int, (String, String)> _table = {
    15: ('14', '12'),
    20: ('12', '10'),
    30: ('10', '8'),
    40: ('10', '8'),
    60: ('10', '8'),
    100: ('8', '6'),
    200: ('6', '4'),
    300: ('4', '2'),
    400: ('3', '1'),
    500: ('2', '1/0'),
    600: ('1', '2/0'),
    800: ('1/0', '3/0'),
    1000: ('2/0', '4/0'),
    1200: ('3/0', '250 kcmil'),
    1600: ('4/0', '350 kcmil'),
    2000: ('250 kcmil', '400 kcmil'),
    2500: ('350 kcmil', '600 kcmil'),
    3000: ('400 kcmil', '600 kcmil'),
    4000: ('500 kcmil', '750 kcmil'),
    5000: ('700 kcmil', '1200 kcmil'),
    6000: ('800 kcmil', '1200 kcmil'),
  };
}

/// Grounding Electrode Conductor - NEC Table 250.66
class GroundingElectrodeConductor {
  GroundingElectrodeConductor._();

  /// Get GEC size based on largest service entrance conductor
  /// [serviceConductor] - Size of largest ungrounded service conductor (AWG string)
  static (String copperGec, String aluminumGec)? getSize(String serviceConductor) {
    return _table[serviceConductor];
  }

  // Key: Service conductor size, Value: (Copper GEC, Aluminum GEC)
  static const Map<String, (String, String)> _table = {
    '2': ('8', '6'),
    '1': ('8', '6'),
    '1/0': ('6', '4'),
    '2/0': ('4', '2'),
    '3/0': ('4', '2'),
    '350 kcmil': ('2', '1/0'),
    '500 kcmil': ('1/0', '3/0'),
    '600 kcmil': ('1/0', '3/0'),
    '750 kcmil': ('2/0', '4/0'),
    '900 kcmil': ('2/0', '4/0'),
    '1000 kcmil': ('2/0', '4/0'),
    '1100 kcmil': ('3/0', '250 kcmil'),
    '1750 kcmil': ('3/0', '250 kcmil'),
  };
}

// ============================================
// BOX FILL
// ============================================

/// Box Fill Volumes - NEC Table 314.16(B)
class BoxFillVolumes {
  BoxFillVolumes._();

  /// Get required volume per conductor in cubic inches
  static double? getVolumePerConductor(int awg) {
    return _volumes[awg];
  }

  // AWG -> cubic inches per conductor
  static const Map<int, double> _volumes = {
    18: 1.50,
    16: 1.75,
    14: 2.00,
    12: 2.25,
    10: 2.50,
    8: 3.00,
    6: 5.00,
  };
}

/// Standard Metal Box Volumes - NEC Table 314.16(A)
class StandardBoxVolumes {
  StandardBoxVolumes._();

  /// Common box sizes and their volumes
  static const Map<String, double> boxes = {
    // Round/Octagonal
    '4" x 1-1/4" round': 12.5,
    '4" x 1-1/2" round': 15.5,
    '4" x 2-1/8" round': 21.5,
    
    // Square
    '4" x 1-1/4" square': 18.0,
    '4" x 1-1/2" square': 21.0,
    '4" x 2-1/8" square': 30.3,
    '4-11/16" x 1-1/4" square': 25.5,
    '4-11/16" x 1-1/2" square': 29.5,
    '4-11/16" x 2-1/8" square': 42.0,
    
    // Device (handy) boxes
    '3" x 2" x 2" device': 10.0,
    '3" x 2" x 2-1/2" device': 12.5,
    '3" x 2" x 2-3/4" device': 14.0,
    '3" x 2" x 3-1/2" device': 18.0,
    
    // Masonry boxes
    '3-3/4" x 2" x 2-1/2" masonry': 14.0,
    '3-3/4" x 2" x 3-1/2" masonry': 21.0,
    
    // FS/FD boxes
    'FS single gang': 13.5,
    'FD single gang': 18.0,
    'FS double gang': 24.0,
    'FD double gang': 36.0,
  };
}

// ============================================
// STANDARD SIZES
// ============================================

/// Standard Breaker/Fuse Sizes - NEC 240.6(A)
class StandardBreakerSizes {
  StandardBreakerSizes._();

  static const List<int> sizes = [
    15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100,
    110, 125, 150, 175, 200, 225, 250, 300, 350, 400,
    450, 500, 600, 700, 800, 1000, 1200, 1600, 2000,
    2500, 3000, 4000, 5000, 6000,
  ];

  /// Get next standard size up from given amperage
  static int? getNextSizeUp(double amps) {
    for (final size in sizes) {
      if (size >= amps) return size;
    }
    return null;
  }

  /// Get next standard size down from given amperage
  static int? getNextSizeDown(double amps) {
    for (int i = sizes.length - 1; i >= 0; i--) {
      if (sizes[i] <= amps) return sizes[i];
    }
    return null;
  }
}

/// Wire Color Codes (Standard practice)
class WireColorCodes {
  WireColorCodes._();

  static const Map<String, String> codes = {
    'Black': 'Hot (ungrounded)',
    'Red': 'Hot (ungrounded)',
    'Blue': 'Hot (3-phase)',
    'Orange': 'Hot (high-leg delta)',
    'Brown': 'Hot (3-phase)',
    'Yellow': 'Hot (3-phase)',
    'White': 'Neutral (grounded)',
    'Gray': 'Neutral (grounded)',
    'Green': 'Equipment ground',
    'Green/Yellow': 'Equipment ground (ISO)',
    'Bare': 'Equipment ground',
  };
}

/// Voltage Drop Limits - NEC recommendations
class VoltageDropLimits {
  VoltageDropLimits._();

  /// Max voltage drop for branch circuits
  static const double branchCircuit = 0.03; // 3%
  
  /// Max voltage drop for feeders
  static const double feeder = 0.03; // 3%
  
  /// Max combined voltage drop
  static const double combined = 0.05; // 5%
  
  /// Check if voltage drop is acceptable
  static bool isAcceptable(double vdPercent, {bool isBranchCircuit = true}) {
    return vdPercent <= (isBranchCircuit ? branchCircuit : feeder);
  }
}
