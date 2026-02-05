/// Validation Engine - Input validation and code compliance checking

class ValidationEngine {
  /// Validate a numeric value is within range
  static ValidationMessage? validateRange({
    required double value,
    required String fieldName,
    double? min,
    double? max,
    String? unit,
  }) {
    if (min != null && value < min) {
      return ValidationMessage(
        type: ValidationType.error,
        field: fieldName,
        message: '$fieldName must be at least $min${unit != null ? ' $unit' : ''}',
      );
    }
    if (max != null && value > max) {
      return ValidationMessage(
        type: ValidationType.error,
        field: fieldName,
        message: '$fieldName must be at most $max${unit != null ? ' $unit' : ''}',
      );
    }
    return null;
  }

  /// Validate a required field
  static ValidationMessage? validateRequired(dynamic value, String fieldName) {
    if (value == null || (value is String && value.isEmpty)) {
      return ValidationMessage(
        type: ValidationType.error,
        field: fieldName,
        message: '$fieldName is required',
      );
    }
    return null;
  }

  /// Validate voltage drop percentage
  static ValidationMessage? validateVoltageDrop(double percentDrop) {
    if (percentDrop > 5) {
      return ValidationMessage(
        type: ValidationType.error,
        field: 'voltage_drop',
        message: 'Voltage drop exceeds 5% maximum per NEC 210.19(A) Informational Note',
        codeReference: 'NEC 210.19(A)',
      );
    }
    if (percentDrop > 3) {
      return ValidationMessage(
        type: ValidationType.warning,
        field: 'voltage_drop',
        message: 'Voltage drop exceeds 3% recommendation per NEC 210.19(A) Informational Note',
        codeReference: 'NEC 210.19(A)',
      );
    }
    return null;
  }

  /// Validate conduit fill percentage
  static ValidationMessage? validateConduitFill(double fillPercent, int conductorCount) {
    final maxFill = conductorCount == 1 ? 53 : (conductorCount == 2 ? 31 : 40);

    if (fillPercent > maxFill) {
      return ValidationMessage(
        type: ValidationType.error,
        field: 'conduit_fill',
        message: 'Conduit fill exceeds $maxFill% maximum for $conductorCount conductors per NEC Chapter 9 Table 1',
        codeReference: 'NEC Chapter 9 Table 1',
      );
    }
    return null;
  }

  /// Validate pipe slope (plumbing)
  static ValidationMessage? validateDrainSlope(double slopeInchPerFoot, double pipeSizeInches) {
    final minSlope = pipeSizeInches >= 3 ? 0.125 : 0.25;

    if (slopeInchPerFoot < minSlope) {
      return ValidationMessage(
        type: ValidationType.error,
        field: 'slope',
        message: 'Slope must be at least $minSlope inch per foot for ${pipeSizeInches}" pipe per IPC 704.1',
        codeReference: 'IPC 704.1',
      );
    }
    return null;
  }

  /// Validate refrigerant charge
  static ValidationMessage? validateSuperheat(double superheat, String systemType) {
    if (systemType == 'fixed_orifice') {
      // Fixed orifice: superheat should be 10-15F
      if (superheat < 5) {
        return ValidationMessage(
          type: ValidationType.error,
          field: 'superheat',
          message: 'Superheat too low - risk of liquid floodback to compressor',
        );
      }
      if (superheat > 20) {
        return ValidationMessage(
          type: ValidationType.warning,
          field: 'superheat',
          message: 'Superheat high - system may be undercharged or have airflow issues',
        );
      }
    } else if (systemType == 'txv') {
      // TXV: subcooling is primary indicator
      if (superheat < 3) {
        return ValidationMessage(
          type: ValidationType.warning,
          field: 'superheat',
          message: 'Superheat low for TXV system - check valve operation',
        );
      }
    }
    return null;
  }

  /// Validate solar string voltage
  static ValidationMessage? validateStringVoltage(double vocMax, double inverterMaxVin) {
    if (vocMax > inverterMaxVin) {
      return ValidationMessage(
        type: ValidationType.error,
        field: 'string_voltage',
        message: 'String VOC ($vocMax V) exceeds inverter max input ($inverterMaxVin V) per NEC 690.7',
        codeReference: 'NEC 690.7',
      );
    }
    if (vocMax > inverterMaxVin * 0.95) {
      return ValidationMessage(
        type: ValidationType.warning,
        field: 'string_voltage',
        message: 'String VOC near inverter limit - verify temperature correction',
      );
    }
    return null;
  }

  /// Run all validations and collect messages
  static List<ValidationMessage> runValidations(List<ValidationMessage?> checks) {
    return checks.whereType<ValidationMessage>().toList();
  }
}

class ValidationMessage {
  final ValidationType type;
  final String field;
  final String message;
  final String? codeReference;
  final String? suggestion;

  ValidationMessage({
    required this.type,
    required this.field,
    required this.message,
    this.codeReference,
    this.suggestion,
  });

  bool get isError => type == ValidationType.error;
  bool get isWarning => type == ValidationType.warning;
  bool get isInfo => type == ValidationType.info;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'field': field,
    'message': message,
    'code_reference': codeReference,
    'suggestion': suggestion,
  };
}

enum ValidationType {
  error,
  warning,
  info,
}
