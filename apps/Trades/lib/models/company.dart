import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Company tier determines feature access and pricing
enum CompanyTier {
  solo,       // $19.99 one-time - single user
  team,       // $29.99/mo - up to 10 users
  business,   // $79.99/mo - up to 50 users
  enterprise  // Custom - unlimited users
}

/// UI complexity mode - Simple shows core features, Pro shows full CRM
enum UiMode {
  simple,  // Core flow: Bid -> Job -> Invoice
  pro,     // Full CRM: Leads, Tasks, Automations, etc.
}

/// Multi-tenant root model - every user belongs to exactly one company
class Company extends Equatable {
  final String id;
  final String name;
  final CompanyTier tier;

  // Owner
  final String ownerUserId;

  // Business Info
  final String? businessName;
  final String? ein;
  final String? phone;
  final String? email;
  final String? website;

  // Address
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  // Branding (Team+ tiers)
  final String? logoUrl;
  final String? primaryColor;

  // Settings
  final List<String> enabledTrades;
  final String defaultTaxRate;
  final String invoicePrefix;
  final int nextInvoiceNumber;

  // UI Mode (Session 23) - Simple vs Pro complexity
  final UiMode uiMode;
  final List<String> enabledProFeatures; // Granular feature toggles

  // Subscription
  final String? stripeCustomerId;
  final String? subscriptionId;
  final DateTime? subscriptionEndsAt;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    required this.tier,
    required this.ownerUserId,
    this.businessName,
    this.ein,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.logoUrl,
    this.primaryColor,
    this.enabledTrades = const ['electrical'],
    this.defaultTaxRate = '0.00',
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.uiMode = UiMode.simple,
    this.enabledProFeatures = const [],
    this.stripeCustomerId,
    this.subscriptionId,
    this.subscriptionEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, tier, ownerUserId, updatedAt];

  // ============================================================
  // TIER LIMITS - Enforced throughout the app
  // ============================================================

  int get maxUsers {
    switch (tier) {
      case CompanyTier.solo:
        return 1;
      case CompanyTier.team:
        return 10;
      case CompanyTier.business:
        return 50;
      case CompanyTier.enterprise:
        return 999999; // Effectively unlimited
    }
  }

  int get maxLocations {
    switch (tier) {
      case CompanyTier.solo:
        return 1;
      case CompanyTier.team:
        return 1;
      case CompanyTier.business:
        return 5;
      case CompanyTier.enterprise:
        return 999999;
    }
  }

  bool get hasTeamFeatures =>
      tier == CompanyTier.team ||
      tier == CompanyTier.business ||
      tier == CompanyTier.enterprise;

  bool get hasDispatch =>
      tier == CompanyTier.business || tier == CompanyTier.enterprise;

  bool get hasApprovalWorkflows =>
      tier == CompanyTier.business || tier == CompanyTier.enterprise;

  bool get hasReporting =>
      tier == CompanyTier.business || tier == CompanyTier.enterprise;

  bool get hasApiAccess => tier == CompanyTier.enterprise;

  bool get hasAuditLogs =>
      tier == CompanyTier.business || tier == CompanyTier.enterprise;

  bool get hasCustomRoles => tier == CompanyTier.enterprise;

  bool get hasSso => tier == CompanyTier.enterprise;

  bool get hasDedicatedSupport => tier == CompanyTier.enterprise;

  // ============================================================
  // UI MODE HELPERS (Session 23)
  // ============================================================

  /// Check if Pro Mode is enabled
  bool get isProMode => uiMode == UiMode.pro;

  /// Check if a specific pro feature is enabled
  bool hasProFeature(String feature) {
    if (uiMode == UiMode.simple) return false;
    // In pro mode, all features are on unless explicitly disabled
    if (enabledProFeatures.isEmpty) return true;
    return enabledProFeatures.contains(feature);
  }

  /// Pro features list (for reference)
  static const List<String> allProFeatures = [
    'leads',           // Lead pipeline
    'tasks',           // Tasks & follow-ups
    'communications',  // Communication hub
    'timeClock',       // Time clock dashboard (admin view)
    'serviceAgreements', // Recurring contracts
    'equipment',       // Equipment tracking
    'multiProperty',   // Multi-property support
    'automations',     // Workflow automations
    'advancedReports', // Advanced reporting
  ];

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tier': tier.name,
      'ownerUserId': ownerUserId,
      'businessName': businessName,
      'ein': ein,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'enabledTrades': enabledTrades,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'uiMode': uiMode.name,
      'enabledProFeatures': enabledProFeatures,
      'stripeCustomerId': stripeCustomerId,
      'subscriptionId': subscriptionId,
      'subscriptionEndsAt': subscriptionEndsAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as String,
      name: map['name'] as String,
      tier: CompanyTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => CompanyTier.solo,
      ),
      ownerUserId: map['ownerUserId'] as String,
      businessName: map['businessName'] as String?,
      ein: map['ein'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zipCode'] as String?,
      logoUrl: map['logoUrl'] as String?,
      primaryColor: map['primaryColor'] as String?,
      enabledTrades: List<String>.from(map['enabledTrades'] ?? ['electrical']),
      defaultTaxRate: map['defaultTaxRate'] as String? ?? '0.00',
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      nextInvoiceNumber: map['nextInvoiceNumber'] as int? ?? 1,
      uiMode: UiMode.values.firstWhere(
        (m) => m.name == map['uiMode'],
        orElse: () => UiMode.simple,
      ),
      enabledProFeatures: List<String>.from(map['enabledProFeatures'] ?? []),
      stripeCustomerId: map['stripeCustomerId'] as String?,
      subscriptionId: map['subscriptionId'] as String?,
      subscriptionEndsAt: map['subscriptionEndsAt'] != null
          ? DateTime.parse(map['subscriptionEndsAt'] as String)
          : null,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Company.fromMap({...data, 'id': doc.id});
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

  Company copyWith({
    String? id,
    String? name,
    CompanyTier? tier,
    String? ownerUserId,
    String? businessName,
    String? ein,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? logoUrl,
    String? primaryColor,
    List<String>? enabledTrades,
    String? defaultTaxRate,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    UiMode? uiMode,
    List<String>? enabledProFeatures,
    String? stripeCustomerId,
    String? subscriptionId,
    DateTime? subscriptionEndsAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      businessName: businessName ?? this.businessName,
      ein: ein ?? this.ein,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      enabledTrades: enabledTrades ?? this.enabledTrades,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      uiMode: uiMode ?? this.uiMode,
      enabledProFeatures: enabledProFeatures ?? this.enabledProFeatures,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new solo company for a user signing up
  factory Company.createSolo({
    required String id,
    required String ownerUserId,
    required String name,
    String? email,
  }) {
    final now = DateTime.now();
    return Company(
      id: id,
      name: name,
      tier: CompanyTier.solo,
      ownerUserId: ownerUserId,
      email: email,
      enabledTrades: const ['electrical'],
      createdAt: now,
      updatedAt: now,
    );
  }
}
