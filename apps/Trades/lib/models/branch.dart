// ZAFTO Branch Model — Supabase Backend
// Maps to `branches` table. Multi-location support for enterprise companies.

class Branch {
  final String id;
  final String companyId;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? managerUserId;
  final String timezone;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Branch({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.managerUserId,
    this.timezone = 'America/New_York',
    this.isActive = true,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zip_code': zipCode,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (managerUserId != null) 'manager_user_id': managerUserId,
        'timezone': timezone,
        'is_active': isActive,
        'settings': settings,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'phone': phone,
        'email': email,
        'manager_user_id': managerUserId,
        'timezone': timezone,
        'is_active': isActive,
        'settings': settings,
      };

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      managerUserId: json['manager_user_id'] as String?,
      timezone: json['timezone'] as String? ?? 'America/New_York',
      isActive: json['is_active'] as bool? ?? true,
      settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Branch copyWith({
    String? id,
    String? companyId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? managerUserId,
    String? timezone,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return Branch(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      managerUserId: managerUserId ?? this.managerUserId,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
