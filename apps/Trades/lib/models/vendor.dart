// ZAFTO Vendor Model — Supabase Backend
// Maps to `vendors` table in Supabase PostgreSQL.
// Tracks vendor/supplier information for expense tracking and 1099 reporting.

class Vendor {
  final String id;
  final String companyId;
  final String vendorName;
  final String? contactName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final String? taxId;
  final bool is1099Eligible;
  final String? paymentTerms;
  final String? notes;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const Vendor({
    this.id = '',
    this.companyId = '',
    required this.vendorName,
    this.contactName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.taxId,
    this.is1099Eligible = false,
    this.paymentTerms,
    this.notes,
    this.isActive = true,
    this.deletedAt,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'vendor_name': vendorName,
        if (contactName != null) 'contact_name': contactName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zip != null) 'zip': zip,
        if (taxId != null) 'tax_id': taxId,
        'is_1099_eligible': is1099Eligible,
        if (paymentTerms != null) 'payment_terms': paymentTerms,
        if (notes != null) 'notes': notes,
        'is_active': isActive,
      };

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      vendorName: json['vendor_name'] as String? ?? '',
      contactName: json['contact_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      taxId: json['tax_id'] as String?,
      is1099Eligible: json['is_1099_eligible'] as bool? ?? false,
      paymentTerms: json['payment_terms'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      deletedAt: _parseOptionalDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Vendor copyWith({
    String? id,
    String? companyId,
    String? vendorName,
    String? contactName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? taxId,
    bool? is1099Eligible,
    String? paymentTerms,
    String? notes,
    bool? isActive,
  }) {
    return Vendor(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vendorName: vendorName ?? this.vendorName,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      taxId: taxId ?? this.taxId,
      is1099Eligible: is1099Eligible ?? this.is1099Eligible,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
