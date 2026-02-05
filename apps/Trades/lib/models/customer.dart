import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer type classification
enum CustomerType { residential, commercial }

/// Customer CRM model
class Customer extends Equatable {
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
  final String? companyName; // For commercial customers

  // History (denormalized for quick access)
  final int jobCount;
  final int invoiceCount;
  final double totalRevenue;
  final double outstandingBalance;
  final DateTime? lastJobDate;

  // Relationship
  final String? referredBy;
  final String? preferredTechId;
  final List<String> tags;

  // Notes
  final String? notes;
  final String? accessInstructions; // Gate code, etc.

  // Communication Preferences
  final bool emailOptIn;
  final bool smsOptIn;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.companyId,
    required this.createdByUserId,
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
    this.jobCount = 0,
    this.invoiceCount = 0,
    this.totalRevenue = 0.0,
    this.outstandingBalance = 0.0,
    this.lastJobDate,
    this.referredBy,
    this.preferredTechId,
    this.tags = const [],
    this.notes,
    this.accessInstructions,
    this.emailOptIn = true,
    this.smsOptIn = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, companyId, name, updatedAt];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Display name - company name for commercial, name for residential
  String get displayName =>
      type == CustomerType.commercial && companyName != null
          ? companyName!
          : name;

  /// Full address string
  String get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  /// Check if customer has an address
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Check if customer has contact info
  bool get hasContactInfo =>
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);

  /// Check if customer has outstanding balance
  bool get hasBalance => outstandingBalance > 0;

  /// Get initials for avatar
  String get initials {
    final displayText = displayName;
    final parts = displayText.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayText.isNotEmpty ? displayText[0].toUpperCase() : '?';
  }

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
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
      'jobCount': jobCount,
      'invoiceCount': invoiceCount,
      'totalRevenue': totalRevenue,
      'outstandingBalance': outstandingBalance,
      'lastJobDate': lastJobDate?.toIso8601String(),
      'referredBy': referredBy,
      'preferredTechId': preferredTechId,
      'tags': tags,
      'notes': notes,
      'accessInstructions': accessInstructions,
      'emailOptIn': emailOptIn,
      'smsOptIn': smsOptIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      createdByUserId: map['createdByUserId'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      alternatePhone: map['alternatePhone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zipCode'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      type: CustomerType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CustomerType.residential,
      ),
      companyName: map['companyName'] as String?,
      jobCount: map['jobCount'] as int? ?? 0,
      invoiceCount: map['invoiceCount'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance:
          (map['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      lastJobDate: map['lastJobDate'] != null
          ? _parseDateTime(map['lastJobDate'])
          : null,
      referredBy: map['referredBy'] as String?,
      preferredTechId: map['preferredTechId'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      notes: map['notes'] as String?,
      accessInstructions: map['accessInstructions'] as String?,
      emailOptIn: map['emailOptIn'] as bool? ?? true,
      smsOptIn: map['smsOptIn'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer.fromMap({...data, 'id': doc.id});
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

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
    int? jobCount,
    int? invoiceCount,
    double? totalRevenue,
    double? outstandingBalance,
    DateTime? lastJobDate,
    String? referredBy,
    String? preferredTechId,
    List<String>? tags,
    String? notes,
    String? accessInstructions,
    bool? emailOptIn,
    bool? smsOptIn,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      jobCount: jobCount ?? this.jobCount,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      lastJobDate: lastJobDate ?? this.lastJobDate,
      referredBy: referredBy ?? this.referredBy,
      preferredTechId: preferredTechId ?? this.preferredTechId,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      accessInstructions: accessInstructions ?? this.accessInstructions,
      emailOptIn: emailOptIn ?? this.emailOptIn,
      smsOptIn: smsOptIn ?? this.smsOptIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new customer
  factory Customer.create({
    required String id,
    required String companyId,
    required String createdByUserId,
    required String name,
    String? email,
    String? phone,
    String? address,
    CustomerType type = CustomerType.residential,
  }) {
    final now = DateTime.now();
    return Customer(
      id: id,
      companyId: companyId,
      createdByUserId: createdByUserId,
      name: name,
      email: email,
      phone: phone,
      address: address,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
  }
}
