// ZAFTO Customer Model — Supabase Schema
// Rewritten: Sprint B1b (Session 41)
//
// Matches public.customers table exactly.
// Replaces both models/customer.dart (Firebase) and models/business/customer.dart.

enum CustomerType { residential, commercial }

class Customer {
  final String id;
  final String companyId;
  final String createdByUserId;

  // Contact
  final String name;
  final String? email;
  final String? phone;
  final String? alternatePhone;

  // Address
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;

  // Type
  final CustomerType type;
  final String? companyName;

  // Relationship
  final List<String> tags;
  final String? notes;
  final String? accessInstructions;
  final String? referredBy;
  final String? preferredTechId;

  // Communication preferences
  final bool emailOptIn;
  final bool smsOptIn;

  // Denormalized stats (updated by triggers/edge functions)
  final int jobCount;
  final int invoiceCount;
  final double totalRevenue;
  final double outstandingBalance;
  final DateTime? lastJobDate;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Customer({
    this.id = '',
    this.companyId = '',
    this.createdByUserId = '',
    required this.name,
    this.email,
    this.phone,
    this.alternatePhone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.type = CustomerType.residential,
    this.companyName,
    this.tags = const [],
    this.notes,
    this.accessInstructions,
    this.referredBy,
    this.preferredTechId,
    this.emailOptIn = true,
    this.smsOptIn = false,
    this.jobCount = 0,
    this.invoiceCount = 0,
    this.totalRevenue = 0.0,
    this.outstandingBalance = 0.0,
    this.lastJobDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  // Generic JSON output (camelCase — used by legacy Firestore code).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'companyName': companyName,
      'tags': tags,
      'notes': notes,
      'accessInstructions': accessInstructions,
      'referredBy': referredBy,
      'preferredTechId': preferredTechId,
      'emailOptIn': emailOptIn,
      'smsOptIn': smsOptIn,
      'jobCount': jobCount,
      'invoiceCount': invoiceCount,
      'totalRevenue': totalRevenue,
      'outstandingBalance': outstandingBalance,
      'lastJobDate': lastJobDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Insert payload (snake_case for Supabase) — excludes server-managed fields.
  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'created_by_user_id': createdByUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'company_name': companyName,
      'tags': tags,
      'notes': notes,
      'access_instructions': accessInstructions,
      'referred_by': referredBy,
      'preferred_tech_id': preferredTechId,
      'email_opt_in': emailOptIn,
      'sms_opt_in': smsOptIn,
    };
  }

  // Update payload — only user-editable fields.
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'company_name': companyName,
      'tags': tags,
      'notes': notes,
      'access_instructions': accessInstructions,
      'referred_by': referredBy,
      'preferred_tech_id': preferredTechId,
      'email_opt_in': emailOptIn,
      'sms_opt_in': smsOptIn,
    };
  }

  // Handles both snake_case (Supabase) and camelCase (legacy Firestore/Hive).
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      companyId: (json['company_id'] ?? json['companyId']) as String? ?? '',
      createdByUserId:
          (json['created_by_user_id'] ?? json['createdByUserId']) as String? ??
              '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      alternatePhone:
          (json['alternate_phone'] ?? json['alternatePhone']) as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: (json['zip_code'] ?? json['zipCode']) as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: CustomerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CustomerType.residential,
      ),
      companyName:
          (json['company_name'] ?? json['companyName']) as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      accessInstructions: (json['access_instructions'] ??
          json['accessInstructions']) as String?,
      referredBy:
          (json['referred_by'] ?? json['referredBy']) as String?,
      preferredTechId:
          (json['preferred_tech_id'] ?? json['preferredTechId']) as String?,
      emailOptIn:
          (json['email_opt_in'] ?? json['emailOptIn']) as bool? ?? true,
      smsOptIn: (json['sms_opt_in'] ?? json['smsOptIn']) as bool? ?? false,
      jobCount:
          ((json['job_count'] ?? json['jobCount']) as num?)?.toInt() ?? 0,
      invoiceCount:
          ((json['invoice_count'] ?? json['invoiceCount']) as num?)?.toInt() ??
              0,
      totalRevenue:
          ((json['total_revenue'] ?? json['totalRevenue']) as num?)
                  ?.toDouble() ??
              0.0,
      outstandingBalance:
          ((json['outstanding_balance'] ?? json['outstandingBalance']) as num?)
                  ?.toDouble() ??
              0.0,
      lastJobDate: _parseOptionalDate(
          json['last_job_date'] ?? json['lastJobDate']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      deletedAt: _parseOptionalDate(
          json['deleted_at'] ?? json['deletedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  String get displayName =>
      type == CustomerType.commercial && companyName != null
          ? companyName!
          : name;

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }

  bool get hasAddress => address != null && address!.isNotEmpty;

  bool get hasContactInfo =>
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);

  bool get hasBalance => outstandingBalance > 0;

  String get initials {
    final displayText = displayName;
    final parts = displayText.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayText.isNotEmpty ? displayText[0].toUpperCase() : '?';
  }

  String get typeLabel =>
      type == CustomerType.commercial ? 'Commercial' : 'Residential';

  // ============================================================
  // COPY WITH
  // ============================================================

  Customer copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? name,
    String? email,
    String? phone,
    String? alternatePhone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    CustomerType? type,
    String? companyName,
    List<String>? tags,
    String? notes,
    String? accessInstructions,
    String? referredBy,
    String? preferredTechId,
    bool? emailOptIn,
    bool? smsOptIn,
    int? jobCount,
    int? invoiceCount,
    double? totalRevenue,
    double? outstandingBalance,
    DateTime? lastJobDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      companyName: companyName ?? this.companyName,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      accessInstructions: accessInstructions ?? this.accessInstructions,
      referredBy: referredBy ?? this.referredBy,
      preferredTechId: preferredTechId ?? this.preferredTechId,
      emailOptIn: emailOptIn ?? this.emailOptIn,
      smsOptIn: smsOptIn ?? this.smsOptIn,
      jobCount: jobCount ?? this.jobCount,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      lastJobDate: lastJobDate ?? this.lastJobDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
