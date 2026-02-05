/// Calculator Base - Abstract base class for all Zafto calculators
/// All trade calculators inherit from this class

import 'calculator_input.dart';
import 'calculator_result.dart';

abstract class CalculatorBase {
  /// Unique identifier for this calculator
  String get id;

  /// Display name
  String get name;

  /// Short description
  String get description;

  /// Trade this calculator belongs to
  String get trade;

  /// Category within the trade
  String get category;

  /// Code reference (e.g., "NEC 220.12", "IPC 704.1")
  String? get codeReference;

  /// List of input field definitions
  List<CalculatorInput> get inputs;

  /// Perform the calculation
  CalculatorResult calculate(Map<String, dynamic> values);

  /// Validate inputs before calculation
  ValidationResult validateInputs(Map<String, dynamic> values) {
    final errors = <String, String>{};

    for (final input in inputs) {
      final value = values[input.id];

      // Check required fields
      if (input.required && (value == null || value.toString().isEmpty)) {
        errors[input.id] = '${input.label} is required';
        continue;
      }

      // Skip validation if value is empty and not required
      if (value == null || value.toString().isEmpty) continue;

      // Type-specific validation
      if (input.type == InputType.number) {
        final numValue = double.tryParse(value.toString());
        if (numValue == null) {
          errors[input.id] = '${input.label} must be a number';
          continue;
        }
        if (input.min != null && numValue < input.min!) {
          errors[input.id] = '${input.label} must be at least ${input.min}';
        }
        if (input.max != null && numValue > input.max!) {
          errors[input.id] = '${input.label} must be at most ${input.max}';
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Get default values for all inputs
  Map<String, dynamic> getDefaults() {
    final defaults = <String, dynamic>{};
    for (final input in inputs) {
      if (input.defaultValue != null) {
        defaults[input.id] = input.defaultValue;
      }
    }
    return defaults;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'trade': trade,
    'category': category,
    'code_reference': codeReference,
    'inputs': inputs.map((i) => i.toJson()).toList(),
  };
}

class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  ValidationResult({
    required this.isValid,
    this.errors = const {},
  });
}

/// Mixin for calculators that support "Add to Estimate" functionality
mixin EstimateSupport on CalculatorBase {
  /// Generate an estimate item from the calculation result
  EstimateItem toEstimateItem(CalculatorResult result);
}

class EstimateItem {
  final String description;
  final String quantity;
  final String unit;
  final double? unitPrice;
  final String? notes;
  final String calculatorId;
  final Map<String, dynamic> calculatorInputs;

  EstimateItem({
    required this.description,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.notes,
    required this.calculatorId,
    required this.calculatorInputs,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'notes': notes,
    'calculator_id': calculatorId,
    'calculator_inputs': calculatorInputs,
  };
}
