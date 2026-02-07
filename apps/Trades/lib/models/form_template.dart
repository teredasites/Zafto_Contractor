// ZAFTO Form Template Model — Supabase Backend
// Maps to `form_templates` table. Configurable compliance form schemas.
// Fields are stored as JSONB array of FormFieldDefinition objects.

enum FormFieldType {
  text,
  number,
  select,
  multiselect,
  checkbox,
  date,
  time,
  photo,
  signature,
  gps,
  textarea,
  calculated;

  static FormFieldType fromString(String? value) {
    if (value == null) return FormFieldType.text;
    for (final type in FormFieldType.values) {
      if (type.name == value) return type;
    }
    return FormFieldType.text;
  }
}

enum FormCategory {
  safety,
  compliance,
  inspection,
  certification,
  quality,
  lienWaiver;

  String get dbValue {
    switch (this) {
      case FormCategory.safety:
        return 'safety';
      case FormCategory.compliance:
        return 'compliance';
      case FormCategory.inspection:
        return 'inspection';
      case FormCategory.certification:
        return 'certification';
      case FormCategory.quality:
        return 'quality';
      case FormCategory.lienWaiver:
        return 'lien_waiver';
    }
  }

  String get label {
    switch (this) {
      case FormCategory.safety:
        return 'Safety';
      case FormCategory.compliance:
        return 'Compliance';
      case FormCategory.inspection:
        return 'Inspection';
      case FormCategory.certification:
        return 'Certification';
      case FormCategory.quality:
        return 'Quality';
      case FormCategory.lienWaiver:
        return 'Lien Waiver';
    }
  }

  static FormCategory fromString(String? value) {
    if (value == null) return FormCategory.compliance;
    switch (value) {
      case 'safety':
        return FormCategory.safety;
      case 'compliance':
        return FormCategory.compliance;
      case 'inspection':
        return FormCategory.inspection;
      case 'certification':
        return FormCategory.certification;
      case 'quality':
        return FormCategory.quality;
      case 'lien_waiver':
        return FormCategory.lienWaiver;
      default:
        return FormCategory.compliance;
    }
  }
}

class FormFieldDefinition {
  final String key;
  final FormFieldType type;
  final String label;
  final bool required;
  final List<String> options;
  final String? placeholder;
  final Map<String, dynamic>? validation;
  final String? computedFrom;

  const FormFieldDefinition({
    required this.key,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const [],
    this.placeholder,
    this.validation,
    this.computedFrom,
  });

  factory FormFieldDefinition.fromJson(Map<String, dynamic> json) {
    return FormFieldDefinition(
      key: json['key'] as String? ?? '',
      type: FormFieldType.fromString(json['type'] as String?),
      label: json['label'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      placeholder: json['placeholder'] as String?,
      validation: json['validation'] as Map<String, dynamic>?,
      computedFrom: json['computed_from'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type.name,
        'label': label,
        if (required) 'required': true,
        if (options.isNotEmpty) 'options': options,
        if (placeholder != null) 'placeholder': placeholder,
        if (validation != null) 'validation': validation,
        if (computedFrom != null) 'computed_from': computedFrom,
      };
}

class FormTemplate {
  final String id;
  final String? companyId;
  final String? trade;
  final String name;
  final String? description;
  final FormCategory category;
  final String? regulationReference;
  final List<FormFieldDefinition> fields;
  final bool isActive;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormTemplate({
    this.id = '',
    this.companyId,
    this.trade,
    required this.name,
    this.description,
    this.category = FormCategory.compliance,
    this.regulationReference,
    this.fields = const [],
    this.isActive = true,
    this.isSystem = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSystemTemplate => companyId == null || isSystem;

  Map<String, dynamic> toInsertJson() => {
        if (companyId != null) 'company_id': companyId,
        if (trade != null) 'trade': trade,
        'name': name,
        if (description != null) 'description': description,
        'category': category.dbValue,
        if (regulationReference != null)
          'regulation_reference': regulationReference,
        'fields': fields.map((f) => f.toJson()).toList(),
        'is_active': isActive,
        'is_system': isSystem,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'category': category.dbValue,
        'regulation_reference': regulationReference,
        'fields': fields.map((f) => f.toJson()).toList(),
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      trade: json['trade'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: FormCategory.fromString(json['category'] as String?),
      regulationReference: json['regulation_reference'] as String?,
      fields: _parseFields(json['fields']),
      isActive: json['is_active'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  FormTemplate copyWith({
    String? id,
    String? companyId,
    String? trade,
    String? name,
    String? description,
    FormCategory? category,
    String? regulationReference,
    List<FormFieldDefinition>? fields,
    bool? isActive,
    bool? isSystem,
    int? sortOrder,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      trade: trade ?? this.trade,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      regulationReference: regulationReference ?? this.regulationReference,
      fields: fields ?? this.fields,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<FormFieldDefinition> _parseFields(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => FormFieldDefinition.fromJson(e))
          .toList();
    }
    return const [];
  }
}
