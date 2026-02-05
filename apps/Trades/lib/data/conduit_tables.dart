/// NEC Conduit Tables
/// 
/// Source: NEC 2023 Chapter 9
/// Tables 1 (fill %), Table 4 (conduit dimensions)

/// Conduit type enum
enum ConduitType {
  emt('EMT', 'Electrical Metallic Tubing'),
  imc('IMC', 'Intermediate Metal Conduit'),
  rmc('RMC', 'Rigid Metal Conduit'),
  pvc40('PVC Sch 40', 'PVC Schedule 40'),
  pvc80('PVC Sch 80', 'PVC Schedule 80'),
  fmc('FMC', 'Flexible Metal Conduit'),
  lfmc('LFMC', 'Liquidtight Flexible Metal Conduit');

  const ConduitType(this.shortName, this.fullName);
  
  final String shortName;
  final String fullName;
  
  // Alias for screen compatibility
  String get displayName => shortName;
}

/// Conduit size enum - alias for TradeSize
enum ConduitSize {
  half('1/2"', 0.5),
  threeQuarter('3/4"', 0.75),
  one('1"', 1.0),
  oneAndQuarter('1-1/4"', 1.25),
  oneAndHalf('1-1/2"', 1.5),
  two('2"', 2.0),
  twoAndHalf('2-1/2"', 2.5),
  three('3"', 3.0),
  threeAndHalf('3-1/2"', 3.5),
  four('4"', 4.0);

  const ConduitSize(this.displayName, this.numericValue);
  
  final String displayName;
  final double numericValue;
}

/// Trade size for conduit (original name)
typedef TradeSize = ConduitSize;

/// Maximum conduit fill percentages - NEC Chapter 9 Table 1
class ConduitFillLimits {
  ConduitFillLimits._();

  static double getMaxFillPercent(int conductorCount) {
    if (conductorCount == 1) return 0.53;
    if (conductorCount == 2) return 0.31;
    return 0.40;
  }
}

/// Compatibility class for screens
class ConduitTables {
  ConduitTables._();
  
  /// Get internal area for conduit type and size
  static double? getInternalArea(ConduitType type, ConduitSize size) {
    return switch (type) {
      ConduitType.emt => _emtAreas[size],
      ConduitType.imc => _imcAreas[size],
      ConduitType.rmc => _rmcAreas[size],
      ConduitType.pvc40 => _pvc40Areas[size],
      ConduitType.pvc80 => _pvc80Areas[size],
      _ => _emtAreas[size], // Default to EMT for FMC/LFMC
    };
  }

  static const Map<ConduitSize, double> _emtAreas = {
    ConduitSize.half: 0.304,
    ConduitSize.threeQuarter: 0.533,
    ConduitSize.one: 0.864,
    ConduitSize.oneAndQuarter: 1.496,
    ConduitSize.oneAndHalf: 2.036,
    ConduitSize.two: 3.356,
    ConduitSize.twoAndHalf: 5.858,
    ConduitSize.three: 8.846,
    ConduitSize.threeAndHalf: 11.545,
    ConduitSize.four: 14.753,
  };

  static const Map<ConduitSize, double> _imcAreas = {
    ConduitSize.half: 0.342,
    ConduitSize.threeQuarter: 0.586,
    ConduitSize.one: 0.959,
    ConduitSize.oneAndQuarter: 1.647,
    ConduitSize.oneAndHalf: 2.225,
    ConduitSize.two: 3.630,
    ConduitSize.twoAndHalf: 5.135,
    ConduitSize.three: 7.922,
    ConduitSize.threeAndHalf: 10.584,
    ConduitSize.four: 13.631,
  };

  static const Map<ConduitSize, double> _rmcAreas = {
    ConduitSize.half: 0.314,
    ConduitSize.threeQuarter: 0.549,
    ConduitSize.one: 0.887,
    ConduitSize.oneAndQuarter: 1.526,
    ConduitSize.oneAndHalf: 2.071,
    ConduitSize.two: 3.408,
    ConduitSize.twoAndHalf: 4.866,
    ConduitSize.three: 7.499,
    ConduitSize.threeAndHalf: 10.010,
    ConduitSize.four: 12.882,
  };

  static const Map<ConduitSize, double> _pvc40Areas = {
    ConduitSize.half: 0.285,
    ConduitSize.threeQuarter: 0.508,
    ConduitSize.one: 0.832,
    ConduitSize.oneAndQuarter: 1.453,
    ConduitSize.oneAndHalf: 1.986,
    ConduitSize.two: 3.291,
    ConduitSize.twoAndHalf: 4.695,
    ConduitSize.three: 7.268,
    ConduitSize.threeAndHalf: 9.737,
    ConduitSize.four: 12.554,
  };

  static const Map<ConduitSize, double> _pvc80Areas = {
    ConduitSize.half: 0.217,
    ConduitSize.threeQuarter: 0.409,
    ConduitSize.one: 0.688,
    ConduitSize.oneAndQuarter: 1.237,
    ConduitSize.oneAndHalf: 1.711,
    ConduitSize.two: 2.874,
    ConduitSize.twoAndHalf: 4.119,
    ConduitSize.three: 6.442,
    ConduitSize.threeAndHalf: 8.688,
    ConduitSize.four: 11.258,
  };
}

/// Alias for legacy code
class ConduitDimensions {
  ConduitDimensions._();

  static double? getTotalArea(ConduitType type, ConduitSize size) {
    return ConduitTables.getInternalArea(type, size);
  }
}
