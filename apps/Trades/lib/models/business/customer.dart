/// ZAFTO Business Models - Customer
/// Sprint 7.0 - January 2026

enum CustomerType { residential, commercial }

class Customer {
  final String id;
  final String name;
  final CustomerType type;
  final String? companyName;  // For commercial customers
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? notes;
  
  // Aggregated stats (denormalized for quick access)
  final int jobCount;
  final int invoiceCount;
  final double totalRevenue;
  final double outstandingBalance;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.type = CustomerType.residential,
    this.companyName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.notes,
    this.jobCount = 0,
    this.invoiceCount = 0,
    this.totalRevenue = 0,
    this.outstandingBalance = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    CustomerType? type,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? notes,
    int? jobCount,
    int? invoiceCount,
    double? totalRevenue,
    double? outstandingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    companyName: companyName ?? this.companyName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    notes: notes ?? this.notes,
    jobCount: jobCount ?? this.jobCount,
    invoiceCount: invoiceCount ?? this.invoiceCount,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'companyName': companyName,
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'notes': notes,
    'jobCount': jobCount,
    'invoiceCount': invoiceCount,
    'totalRevenue': totalRevenue,
    'outstandingBalance': outstandingBalance,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    type: CustomerType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => CustomerType.residential,
    ),
    companyName: json['companyName'] as String? ?? json['company'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    zipCode: json['zipCode'] as String?,
    notes: json['notes'] as String?,
    jobCount: (json['jobCount'] as num?)?.toInt() ?? 0,
    invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
  );

  /// Display name - shows company for commercial, name for residential
  String get displayName => type == CustomerType.commercial && companyName != null 
      ? companyName! 
      : name;

  /// Full address formatted
  String? get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Type label
  String get typeLabel => type == CustomerType.commercial ? 'Commercial' : 'Residential';
}
