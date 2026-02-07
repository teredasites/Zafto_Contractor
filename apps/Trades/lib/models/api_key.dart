// ZAFTO API Key Model — Supabase Backend
// Maps to `api_keys` table. Per-company API access for integrations.
// Minimal Flutter model — primary management is via Web CRM.

class ApiKey {
  final String id;
  final String companyId;
  final String name;
  final String prefix;
  final Map<String, dynamic> permissions;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String createdByUserId;
  final DateTime createdAt;

  const ApiKey({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.prefix = '',
    this.permissions = const {},
    this.lastUsedAt,
    this.expiresAt,
    this.isActive = true,
    this.createdByUserId = '',
    required this.createdAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get displayPrefix => '$prefix...';

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      prefix: json['prefix'] as String? ?? '',
      permissions:
          (json['permissions'] as Map<String, dynamic>?) ?? const {},
      lastUsedAt: _parseDate(json['last_used_at']),
      expiresAt: _parseDate(json['expires_at']),
      isActive: json['is_active'] as bool? ?? true,
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
