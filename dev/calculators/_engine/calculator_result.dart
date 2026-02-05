/// Calculator Result - Standardized result model for all calculators

class CalculatorResult {
  /// Primary result value (the BIG number)
  final ResultValue primary;

  /// Supporting/secondary values
  final List<ResultValue> secondary;

  /// Code reference for this result
  final String? codeReference;

  /// Additional notes or warnings
  final List<String>? notes;

  /// Warning messages (e.g., "Exceeds 3% voltage drop recommendation")
  final List<ResultWarning>? warnings;

  /// Raw calculation data for debugging/export
  final Map<String, dynamic>? rawData;

  CalculatorResult({
    required this.primary,
    this.secondary = const [],
    this.codeReference,
    this.notes,
    this.warnings,
    this.rawData,
  });

  /// Check if result has any warnings
  bool get hasWarnings => warnings != null && warnings!.isNotEmpty;

  /// Check if result has critical warnings
  bool get hasCriticalWarnings =>
      warnings?.any((w) => w.severity == WarningSeverity.critical) ?? false;

  Map<String, dynamic> toJson() => {
    'primary': primary.toJson(),
    'secondary': secondary.map((v) => v.toJson()).toList(),
    'code_reference': codeReference,
    'notes': notes,
    'warnings': warnings?.map((w) => w.toJson()).toList(),
    'raw_data': rawData,
  };
}

class ResultValue {
  final String label;
  final dynamic value;
  final String? unit;
  final String? description;
  final ResultFormat format;

  ResultValue({
    required this.label,
    required this.value,
    this.unit,
    this.description,
    this.format = ResultFormat.standard,
  });

  /// Format the value for display
  String get displayValue {
    if (value == null) return 'N/A';

    switch (format) {
      case ResultFormat.standard:
        return value.toString();
      case ResultFormat.decimal1:
        return (value as num).toStringAsFixed(1);
      case ResultFormat.decimal2:
        return (value as num).toStringAsFixed(2);
      case ResultFormat.percent:
        return '${(value as num).toStringAsFixed(2)}%';
      case ResultFormat.currency:
        return '\$${(value as num).toStringAsFixed(2)}';
      case ResultFormat.integer:
        return (value as num).round().toString();
      case ResultFormat.fraction:
        return _toFraction(value as double);
    }
  }

  /// Format value with unit
  String get displayWithUnit {
    final display = displayValue;
    if (unit == null || unit!.isEmpty) return display;
    return '$display $unit';
  }

  String _toFraction(double value) {
    // Common fractions for construction
    const fractions = {
      0.125: '1/8',
      0.25: '1/4',
      0.375: '3/8',
      0.5: '1/2',
      0.625: '5/8',
      0.75: '3/4',
      0.875: '7/8',
    };

    final whole = value.floor();
    final decimal = value - whole;

    if (decimal == 0) return whole.toString();

    final fraction = fractions.entries
        .firstWhere(
          (e) => (e.key - decimal).abs() < 0.01,
          orElse: () => MapEntry(decimal, decimal.toStringAsFixed(2)),
        )
        .value;

    return whole > 0 ? '$whole $fraction' : fraction;
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    'unit': unit,
    'description': description,
    'format': format.name,
    'display_value': displayValue,
    'display_with_unit': displayWithUnit,
  };
}

enum ResultFormat {
  standard,
  decimal1,
  decimal2,
  percent,
  currency,
  integer,
  fraction,
}

class ResultWarning {
  final String message;
  final WarningSeverity severity;
  final String? codeReference;

  ResultWarning({
    required this.message,
    this.severity = WarningSeverity.warning,
    this.codeReference,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'severity': severity.name,
    'code_reference': codeReference,
  };
}

enum WarningSeverity {
  info,
  warning,
  critical,
}
