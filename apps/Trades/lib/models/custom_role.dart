// ZAFTO Custom Role Model — Supabase Backend
// Maps to `custom_roles` table. Company-defined permission sets.

class CustomRole {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String baseRole;
  final Map<String, dynamic> permissions;
  final bool isSystemRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomRole({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.description,
    this.baseRole = 'technician',
    this.permissions = const {},
    this.isSystemRole = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (description != null) 'description': description,
        'base_role': baseRole,
        'permissions': permissions,
        'is_system_role': isSystemRole,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'base_role': baseRole,
        'permissions': permissions,
      };

  factory CustomRole.fromJson(Map<String, dynamic> json) {
    return CustomRole(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      baseRole: json['base_role'] as String? ?? 'technician',
      permissions:
          (json['permissions'] as Map<String, dynamic>?) ?? const {},
      isSystemRole: json['is_system_role'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  CustomRole copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? baseRole,
    Map<String, dynamic>? permissions,
    bool? isSystemRole,
  }) {
    return CustomRole(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      baseRole: baseRole ?? this.baseRole,
      permissions: permissions ?? this.permissions,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool hasPermission(String key) {
    return permissions[key] == true;
  }
}
