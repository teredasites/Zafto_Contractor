/// Unit Converter - Comprehensive unit conversion for all trades

class UnitConverter {
  // ============================================
  // LENGTH
  // ============================================

  static double feetToMeters(double feet) => feet * 0.3048;
  static double metersToFeet(double meters) => meters / 0.3048;
  static double inchesToCentimeters(double inches) => inches * 2.54;
  static double centimetersToInches(double cm) => cm / 2.54;
  static double feetToInches(double feet) => feet * 12;
  static double inchesToFeet(double inches) => inches / 12;
  static double milesToKilometers(double miles) => miles * 1.60934;
  static double kilometersToMiles(double km) => km / 1.60934;
  static double yardsToMeters(double yards) => yards * 0.9144;
  static double metersToYards(double meters) => meters / 0.9144;

  // ============================================
  // AREA
  // ============================================

  static double sqFeetToSqMeters(double sqFt) => sqFt * 0.092903;
  static double sqMetersToSqFeet(double sqM) => sqM / 0.092903;
  static double sqInchesToSqCm(double sqIn) => sqIn * 6.4516;
  static double sqCmToSqInches(double sqCm) => sqCm / 6.4516;
  static double acresToSqFeet(double acres) => acres * 43560;
  static double sqFeetToAcres(double sqFt) => sqFt / 43560;

  // ============================================
  // VOLUME
  // ============================================

  static double gallonsToLiters(double gallons) => gallons * 3.78541;
  static double litersToGallons(double liters) => liters / 3.78541;
  static double cubicFeetToGallons(double cuFt) => cuFt * 7.48052;
  static double gallonsToCubicFeet(double gallons) => gallons / 7.48052;
  static double cubicFeetToLiters(double cuFt) => cuFt * 28.3168;
  static double litersToCubicFeet(double liters) => liters / 28.3168;
  static double cubicInchesToCubicCm(double cuIn) => cuIn * 16.3871;
  static double cubicCmToCubicInches(double cuCm) => cuCm / 16.3871;

  // ============================================
  // TEMPERATURE
  // ============================================

  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;
  static double celsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
  static double celsiusToKelvin(double c) => c + 273.15;
  static double kelvinToCelsius(double k) => k - 273.15;

  // ============================================
  // PRESSURE
  // ============================================

  static double psiToBar(double psi) => psi * 0.0689476;
  static double barToPsi(double bar) => bar / 0.0689476;
  static double psiToKpa(double psi) => psi * 6.89476;
  static double kpaToPsi(double kpa) => kpa / 6.89476;
  static double inWcToPsi(double inWc) => inWc * 0.0361273;
  static double psiToInWc(double psi) => psi / 0.0361273;
  static double inHgToPsi(double inHg) => inHg * 0.491154;
  static double psiToInHg(double psi) => psi / 0.491154;

  // ============================================
  // ELECTRICAL
  // ============================================

  static double wattsToKilowatts(double watts) => watts / 1000;
  static double kilowattsToWatts(double kw) => kw * 1000;
  static double wattsToHorsepower(double watts) => watts / 746;
  static double horsepowerToWatts(double hp) => hp * 746;
  static double vaToWatts(double va, double powerFactor) => va * powerFactor;
  static double wattsToVa(double watts, double powerFactor) => watts / powerFactor;
  static double kvaToKw(double kva, double powerFactor) => kva * powerFactor;
  static double kwToKva(double kw, double powerFactor) => kw / powerFactor;
  static double cmilToSqMm(double cmil) => cmil * 0.0005067;
  static double sqMmToCmil(double sqMm) => sqMm / 0.0005067;

  // ============================================
  // HVAC / THERMAL
  // ============================================

  static double btuToWatts(double btu) => btu * 0.293071;
  static double wattsToBtu(double watts) => watts / 0.293071;
  static double btuHrToTons(double btuHr) => btuHr / 12000;
  static double tonsToBtuHr(double tons) => tons * 12000;
  static double btuHrToKw(double btuHr) => btuHr * 0.000293071;
  static double kwToBtuHr(double kw) => kw / 0.000293071;
  static double cfmToLps(double cfm) => cfm * 0.471947;
  static double lpsToCfm(double lps) => lps / 0.471947;

  // ============================================
  // FLOW RATE (PLUMBING)
  // ============================================

  static double gpmToLpm(double gpm) => gpm * 3.78541;
  static double lpmToGpm(double lpm) => lpm / 3.78541;
  static double gpmToCfs(double gpm) => gpm / 448.831;
  static double cfsToGpm(double cfs) => cfs * 448.831;

  // ============================================
  // WEIGHT / MASS
  // ============================================

  static double poundsToKilograms(double lbs) => lbs * 0.453592;
  static double kilogramsToPounds(double kg) => kg / 0.453592;
  static double ouncesToGrams(double oz) => oz * 28.3495;
  static double gramsToOunces(double g) => g / 28.3495;
  static double tonsToKilograms(double tons) => tons * 907.185;
  static double kilogramsToTons(double kg) => kg / 907.185;

  // ============================================
  // GENERIC CONVERTER
  // ============================================

  /// Convert between any two units of the same type
  static double convert(double value, String fromUnit, String toUnit) {
    // Normalize unit names
    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();

    if (from == to) return value;

    // Length conversions
    if (_isLengthUnit(from) && _isLengthUnit(to)) {
      final meters = _toMeters(value, from);
      return _fromMeters(meters, to);
    }

    // Temperature conversions
    if (_isTempUnit(from) && _isTempUnit(to)) {
      final celsius = _toCelsius(value, from);
      return _fromCelsius(celsius, to);
    }

    // Add more unit type handlers as needed...

    throw ArgumentError('Cannot convert from $fromUnit to $toUnit');
  }

  static bool _isLengthUnit(String unit) {
    return ['ft', 'feet', 'm', 'meters', 'in', 'inches', 'cm', 'mm', 'yd', 'yards']
        .contains(unit);
  }

  static bool _isTempUnit(String unit) {
    return ['f', 'fahrenheit', 'c', 'celsius', 'k', 'kelvin'].contains(unit);
  }

  static double _toMeters(double value, String unit) {
    switch (unit) {
      case 'ft':
      case 'feet':
        return feetToMeters(value);
      case 'm':
      case 'meters':
        return value;
      case 'in':
      case 'inches':
        return inchesToCentimeters(value) / 100;
      case 'cm':
        return value / 100;
      case 'mm':
        return value / 1000;
      case 'yd':
      case 'yards':
        return yardsToMeters(value);
      default:
        throw ArgumentError('Unknown length unit: $unit');
    }
  }

  static double _fromMeters(double meters, String unit) {
    switch (unit) {
      case 'ft':
      case 'feet':
        return metersToFeet(meters);
      case 'm':
      case 'meters':
        return meters;
      case 'in':
      case 'inches':
        return centimetersToInches(meters * 100);
      case 'cm':
        return meters * 100;
      case 'mm':
        return meters * 1000;
      case 'yd':
      case 'yards':
        return metersToYards(meters);
      default:
        throw ArgumentError('Unknown length unit: $unit');
    }
  }

  static double _toCelsius(double value, String unit) {
    switch (unit) {
      case 'c':
      case 'celsius':
        return value;
      case 'f':
      case 'fahrenheit':
        return fahrenheitToCelsius(value);
      case 'k':
      case 'kelvin':
        return kelvinToCelsius(value);
      default:
        throw ArgumentError('Unknown temperature unit: $unit');
    }
  }

  static double _fromCelsius(double celsius, String unit) {
    switch (unit) {
      case 'c':
      case 'celsius':
        return celsius;
      case 'f':
      case 'fahrenheit':
        return celsiusToFahrenheit(celsius);
      case 'k':
      case 'kelvin':
        return celsiusToKelvin(celsius);
      default:
        throw ArgumentError('Unknown temperature unit: $unit');
    }
  }
}

/// Wire size utilities for electrical calculations
class WireSizeUtils {
  /// AWG to circular mils mapping
  static const Map<int, int> awgToCmil = {
    18: 1620,
    16: 2580,
    14: 4110,
    12: 6530,
    10: 10380,
    8: 16510,
    6: 26240,
    4: 41740,
    3: 52620,
    2: 66360,
    1: 83690,
  };

  /// AWG to kcmil for larger sizes (expressed as negative AWG)
  static const Map<String, int> kcmilSizes = {
    '1/0': 105600,
    '2/0': 133100,
    '3/0': 167800,
    '4/0': 211600,
    '250': 250000,
    '300': 300000,
    '350': 350000,
    '400': 400000,
    '500': 500000,
    '600': 600000,
    '700': 700000,
    '750': 750000,
    '800': 800000,
    '900': 900000,
    '1000': 1000000,
  };

  /// Get circular mils for a wire size
  static int? getCmil(String size) {
    // Check if it's a standard AWG size
    final awg = int.tryParse(size);
    if (awg != null && awgToCmil.containsKey(awg)) {
      return awgToCmil[awg];
    }

    // Check kcmil sizes
    if (kcmilSizes.containsKey(size)) {
      return kcmilSizes[size];
    }

    return null;
  }
}
