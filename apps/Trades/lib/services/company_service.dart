/// ZAFTO Company Service - Company Creation & Management
/// Sprint 7.0 - January 2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Company service provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  final authState = ref.watch(authStateProvider);
  return CompanyService(authState);
});

/// Current company provider - streams company data
final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.hasCompany) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('companies')
      .doc(authState.companyId)
      .snapshots()
      .map((doc) => doc.exists ? Company.fromJson({...doc.data()!, 'id': doc.id}) : null);
});

// ============================================================
// COMPANY MODEL
// ============================================================

enum CompanyTier { solo, team, business, enterprise }

class Company {
  final String id;
  final String name;
  final CompanyTier tier;
  final String ownerUserId;
  
  // Business Info
  final String? businessName;
  final String? ein;
  final String? phone;
  final String? email;
  final String? website;
  final String? licenseNumber;
  
  // Address
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  
  // Branding
  final String? logoUrl;
  final String? primaryColor;
  
  // Settings
  final List<String> enabledTrades;
  final double defaultTaxRate;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String? defaultNecYear;
  
  // Subscription
  final String? stripeCustomerId;
  final String? subscriptionId;
  final DateTime? subscriptionEndsAt;
  
  // Limits (enforced by tier)
  final int maxUsers;
  final int maxLocations;
  final bool hasDispatch;
  final bool hasApprovalWorkflows;
  final bool hasApiAccess;
  final bool hasAuditLogs;
  final bool hasCustomRoles;
  
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
    this.licenseNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.logoUrl,
    this.primaryColor,
    this.enabledTrades = const ['electrical'],
    this.defaultTaxRate = 0,
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.defaultNecYear,
    this.stripeCustomerId,
    this.subscriptionId,
    this.subscriptionEndsAt,
    this.maxUsers = 1,
    this.maxLocations = 1,
    this.hasDispatch = false,
    this.hasApprovalWorkflows = false,
    this.hasApiAccess = false,
    this.hasAuditLogs = false,
    this.hasCustomRoles = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tier': tier.name,
    'ownerUserId': ownerUserId,
    'businessName': businessName,
    'ein': ein,
    'phone': phone,
    'email': email,
    'website': website,
    'licenseNumber': licenseNumber,
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
    'defaultNecYear': defaultNecYear,
    'stripeCustomerId': stripeCustomerId,
    'subscriptionId': subscriptionId,
    'subscriptionEndsAt': subscriptionEndsAt?.toIso8601String(),
    'maxUsers': maxUsers,
    'maxLocations': maxLocations,
    'hasDispatch': hasDispatch,
    'hasApprovalWorkflows': hasApprovalWorkflows,
    'hasApiAccess': hasApiAccess,
    'hasAuditLogs': hasAuditLogs,
    'hasCustomRoles': hasCustomRoles,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String,
    name: json['name'] as String,
    tier: CompanyTier.values.firstWhere(
      (e) => e.name == json['tier'],
      orElse: () => CompanyTier.solo,
    ),
    ownerUserId: json['ownerUserId'] as String,
    businessName: json['businessName'] as String?,
    ein: json['ein'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    website: json['website'] as String?,
    licenseNumber: json['licenseNumber'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    zipCode: json['zipCode'] as String?,
    logoUrl: json['logoUrl'] as String?,
    primaryColor: json['primaryColor'] as String?,
    enabledTrades: (json['enabledTrades'] as List<dynamic>?)?.cast<String>() ?? ['electrical'],
    defaultTaxRate: (json['defaultTaxRate'] as num?)?.toDouble() ?? 0,
    invoicePrefix: json['invoicePrefix'] as String? ?? 'INV',
    nextInvoiceNumber: (json['nextInvoiceNumber'] as num?)?.toInt() ?? 1,
    defaultNecYear: json['defaultNecYear'] as String?,
    stripeCustomerId: json['stripeCustomerId'] as String?,
    subscriptionId: json['subscriptionId'] as String?,
    subscriptionEndsAt: json['subscriptionEndsAt'] != null 
        ? DateTime.parse(json['subscriptionEndsAt']) 
        : null,
    maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 1,
    maxLocations: (json['maxLocations'] as num?)?.toInt() ?? 1,
    hasDispatch: json['hasDispatch'] as bool? ?? false,
    hasApprovalWorkflows: json['hasApprovalWorkflows'] as bool? ?? false,
    hasApiAccess: json['hasApiAccess'] as bool? ?? false,
    hasAuditLogs: json['hasAuditLogs'] as bool? ?? false,
    hasCustomRoles: json['hasCustomRoles'] as bool? ?? false,
    createdAt: json['createdAt'] != null 
        ? (json['createdAt'] is Timestamp 
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(json['createdAt']))
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null 
        ? (json['updatedAt'] is Timestamp 
            ? (json['updatedAt'] as Timestamp).toDate()
            : DateTime.parse(json['updatedAt']))
        : DateTime.now(),
  );

  Company copyWith({
    String? name,
    CompanyTier? tier,
    String? businessName,
    String? ein,
    String? phone,
    String? email,
    String? website,
    String? licenseNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? logoUrl,
    String? primaryColor,
    List<String>? enabledTrades,
    double? defaultTaxRate,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? defaultNecYear,
  }) => Company(
    id: id,
    name: name ?? this.name,
    tier: tier ?? this.tier,
    ownerUserId: ownerUserId,
    businessName: businessName ?? this.businessName,
    ein: ein ?? this.ein,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    website: website ?? this.website,
    licenseNumber: licenseNumber ?? this.licenseNumber,
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
    defaultNecYear: defaultNecYear ?? this.defaultNecYear,
    stripeCustomerId: stripeCustomerId,
    subscriptionId: subscriptionId,
    subscriptionEndsAt: subscriptionEndsAt,
    maxUsers: maxUsers,
    maxLocations: maxLocations,
    hasDispatch: hasDispatch,
    hasApprovalWorkflows: hasApprovalWorkflows,
    hasApiAccess: hasApiAccess,
    hasAuditLogs: hasAuditLogs,
    hasCustomRoles: hasCustomRoles,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  /// Get tier limits
  static TierLimits getLimitsForTier(CompanyTier tier) {
    switch (tier) {
      case CompanyTier.solo:
        return const TierLimits(
          maxUsers: 1,
          maxLocations: 1,
          hasDispatch: false,
          hasApprovalWorkflows: false,
          hasApiAccess: false,
          hasAuditLogs: false,
          hasCustomRoles: false,
        );
      case CompanyTier.team:
        return const TierLimits(
          maxUsers: 10,
          maxLocations: 1,
          hasDispatch: false,
          hasApprovalWorkflows: false,
          hasApiAccess: false,
          hasAuditLogs: false,
          hasCustomRoles: false,
        );
      case CompanyTier.business:
        return const TierLimits(
          maxUsers: 50,
          maxLocations: 5,
          hasDispatch: true,
          hasApprovalWorkflows: true,
          hasApiAccess: false,
          hasAuditLogs: true,
          hasCustomRoles: false,
        );
      case CompanyTier.enterprise:
        return const TierLimits(
          maxUsers: -1, // unlimited
          maxLocations: -1,
          hasDispatch: true,
          hasApprovalWorkflows: true,
          hasApiAccess: true,
          hasAuditLogs: true,
          hasCustomRoles: true,
        );
    }
  }

  String get tierLabel => switch (tier) {
    CompanyTier.solo => 'Solo',
    CompanyTier.team => 'Team',
    CompanyTier.business => 'Business',
    CompanyTier.enterprise => 'Enterprise',
  };
}

class TierLimits {
  final int maxUsers;
  final int maxLocations;
  final bool hasDispatch;
  final bool hasApprovalWorkflows;
  final bool hasApiAccess;
  final bool hasAuditLogs;
  final bool hasCustomRoles;

  const TierLimits({
    required this.maxUsers,
    required this.maxLocations,
    required this.hasDispatch,
    required this.hasApprovalWorkflows,
    required this.hasApiAccess,
    required this.hasAuditLogs,
    required this.hasCustomRoles,
  });
}

// ============================================================
// COMPANY SERVICE
// ============================================================

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthState _authState;

  CompanyService(this._authState);

  String? get _userId => _authState.user?.uid;

  CollectionReference<Map<String, dynamic>> get _companiesCollection =>
      _firestore.collection('companies');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create a new company (during onboarding)
  Future<String> createCompany({
    required String name,
    required CompanyTier tier,
    String? businessName,
    String? phone,
    String? email,
    String? licenseNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final limits = Company.getLimitsForTier(tier);
    final now = DateTime.now();

    // Create company document
    final companyRef = await _companiesCollection.add({
      'name': name,
      'tier': tier.name,
      'ownerUserId': _userId,
      'businessName': businessName,
      'phone': phone,
      'email': email,
      'licenseNumber': licenseNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'enabledTrades': ['electrical'],
      'defaultTaxRate': 0,
      'invoicePrefix': 'INV',
      'nextInvoiceNumber': 1,
      'maxUsers': limits.maxUsers,
      'maxLocations': limits.maxLocations,
      'hasDispatch': limits.hasDispatch,
      'hasApprovalWorkflows': limits.hasApprovalWorkflows,
      'hasApiAccess': limits.hasApiAccess,
      'hasAuditLogs': limits.hasAuditLogs,
      'hasCustomRoles': limits.hasCustomRoles,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final companyId = companyRef.id;

    // Create default Owner role
    final ownerRoleRef = await _companiesCollection
        .doc(companyId)
        .collection('roles')
        .add({
      'name': 'Owner',
      'isSystemRole': true,
      'isDefault': false,
      'permissions': _getOwnerPermissions(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update user document with company reference
    await _usersCollection.doc(_userId).set({
      'companyId': companyId,
      'roleId': ownerRoleRef.id,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return companyId;
  }

  /// Get current company
  Future<Company?> getCurrentCompany() async {
    if (!_authState.hasCompany) return null;

    final doc = await _companiesCollection.doc(_authState.companyId).get();
    if (!doc.exists) return null;

    return Company.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Update company settings
  Future<void> updateCompany(Company company) async {
    await _companiesCollection.doc(company.id).update({
      ...company.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get and increment invoice number
  Future<String> getNextInvoiceNumber() async {
    if (!_authState.hasCompany) throw Exception('No company');

    final result = await _firestore.runTransaction<String>((transaction) async {
      final companyRef = _companiesCollection.doc(_authState.companyId);
      final doc = await transaction.get(companyRef);

      if (!doc.exists) throw Exception('Company not found');

      final prefix = doc.data()?['invoicePrefix'] as String? ?? 'INV';
      final current = (doc.data()?['nextInvoiceNumber'] as num?)?.toInt() ?? 1;
      final year = DateTime.now().year;

      transaction.update(companyRef, {
        'nextInvoiceNumber': current + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return '$prefix-$year-${current.toString().padLeft(4, '0')}';
    });

    return result;
  }

  /// Check if user is company owner
  bool isOwner() {
    return _authState.user?.uid == _authState.companyId;
  }

  /// Get all owner permissions
  Map<String, bool> _getOwnerPermissions() => {
    // Jobs
    'jobs.view.own': true,
    'jobs.view.all': true,
    'jobs.create': true,
    'jobs.edit.own': true,
    'jobs.edit.all': true,
    'jobs.delete': true,
    'jobs.assign': true,
    // Invoices
    'invoices.view.own': true,
    'invoices.view.all': true,
    'invoices.create': true,
    'invoices.edit': true,
    'invoices.send': true,
    'invoices.approve': true,
    'invoices.void': true,
    // Customers
    'customers.view': true,
    'customers.create': true,
    'customers.edit': true,
    'customers.delete': true,
    // Team
    'team.view': true,
    'team.invite': true,
    'team.edit': true,
    'team.remove': true,
    // Dispatch
    'dispatch.view': true,
    'dispatch.manage': true,
    // Reports
    'reports.view': true,
    'reports.export': true,
    // Admin
    'company.settings': true,
    'billing.manage': true,
    'roles.manage': true,
    'audit.view': true,
  };
}
