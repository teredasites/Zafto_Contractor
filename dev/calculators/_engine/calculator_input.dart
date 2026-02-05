/// Calculator Input - Defines input field structure for calculators

enum InputType {
  number,
  text,
  select,
  toggle,
  chip,
  slider,
}

class CalculatorInput {
  final String id;
  final String label;
  final InputType type;
  final String? hint;
  final String? unit;
  final bool required;
  final dynamic defaultValue;
  final double? min;
  final double? max;
  final double? step;
  final List<SelectOption>? options;
  final List<String>? chipValues;
  final bool advanced; // Hidden under "Advanced Options" by default

  CalculatorInput({
    required this.id,
    required this.label,
    required this.type,
    this.hint,
    this.unit,
    this.required = true,
    this.defaultValue,
    this.min,
    this.max,
    this.step,
    this.options,
    this.chipValues,
    this.advanced = false,
  });

  /// Number input with unit
  factory CalculatorInput.number({
    required String id,
    required String label,
    String? hint,
    String? unit,
    bool required = true,
    double? defaultValue,
    double? min,
    double? max,
    double? step,
    bool advanced = false,
  }) {
    return CalculatorInput(
      id: id,
      label: label,
      type: InputType.number,
      hint: hint,
      unit: unit,
      required: required,
      defaultValue: defaultValue,
      min: min,
      max: max,
      step: step,
      advanced: advanced,
    );
  }

  /// Dropdown select
  factory CalculatorInput.select({
    required String id,
    required String label,
    required List<SelectOption> options,
    String? hint,
    bool required = true,
    String? defaultValue,
    bool advanced = false,
  }) {
    return CalculatorInput(
      id: id,
      label: label,
      type: InputType.select,
      hint: hint,
      options: options,
      required: required,
      defaultValue: defaultValue,
      advanced: advanced,
    );
  }

  /// Chip selector for common values
  factory CalculatorInput.chip({
    required String id,
    required String label,
    required List<String> values,
    String? hint,
    String? unit,
    bool required = true,
    String? defaultValue,
    bool advanced = false,
  }) {
    return CalculatorInput(
      id: id,
      label: label,
      type: InputType.chip,
      hint: hint,
      unit: unit,
      chipValues: values,
      required: required,
      defaultValue: defaultValue,
      advanced: advanced,
    );
  }

  /// Toggle switch
  factory CalculatorInput.toggle({
    required String id,
    required String label,
    String? hint,
    bool defaultValue = false,
    bool advanced = false,
  }) {
    return CalculatorInput(
      id: id,
      label: label,
      type: InputType.toggle,
      hint: hint,
      required: false,
      defaultValue: defaultValue,
      advanced: advanced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'hint': hint,
    'unit': unit,
    'required': required,
    'default_value': defaultValue,
    'min': min,
    'max': max,
    'step': step,
    'options': options?.map((o) => o.toJson()).toList(),
    'chip_values': chipValues,
    'advanced': advanced,
  };
}

class SelectOption {
  final String value;
  final String label;
  final String? description;

  SelectOption({
    required this.value,
    required this.label,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'description': description,
  };
}
