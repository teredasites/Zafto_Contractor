// Property Management Models — Supabase Backend
// Maps to `properties`, `units`, `tenants`, `leases` tables in Supabase PostgreSQL.
// Core entities for the ZAFTO Property Management feature.

enum PropertyType {
  singleFamily,
  multiFamily,
  apartment,
  condo,
  townhouse,
  duplex,
  commercial,
  mixedUse,
  other,
}

enum PropertyStatus {
  active,
  inactive,
  sold,
}

enum UnitStatus {
  vacant,
  occupied,
  unitTurn,
  listed,
  maintenance,
  offline,
}

enum TenantStatus {
  active,
  inactive,
  evicted,
  pastTenant,
}

enum LeaseType {
  fixedTerm,
  monthToMonth,
  shortTerm,
}

enum LeaseStatus {
  draft,
  active,
  expiring,
  expired,
  terminated,
  renewed,
}

class Property {
  final String id;
  final String companyId;
  final String name;
  final PropertyType propertyType;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zip;
  final String? country;
  final int totalUnits;
  final String? ownerEntity;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? mortgageBalance;
  final double? mortgagePayment;
  final String? insurancePolicyNumber;
  final String? insuranceProvider;
  final double? insurancePremium;
  final double? taxAssessment;
  final double? annualTax;
  final double? managementFeePct;
  final String? notes;
  final PropertyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Property({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.propertyType = PropertyType.singleFamily,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zip,
    this.country,
    this.totalUnits = 1,
    this.ownerEntity,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.mortgageBalance,
    this.mortgagePayment,
    this.insurancePolicyNumber,
    this.insuranceProvider,
    this.insurancePremium,
    this.taxAssessment,
    this.annualTax,
    this.managementFeePct,
    this.notes,
    this.status = PropertyStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress =>
      [addressLine1, city, state, zip]
          .where((s) => s.isNotEmpty)
          .join(', ');

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        'property_type': _enumToDb(propertyType),
        'address_line1': addressLine1,
        if (addressLine2 != null) 'address_line2': addressLine2,
        'city': city,
        'state': state,
        'zip': zip,
        if (country != null) 'country': country,
        'total_units': totalUnits,
        if (ownerEntity != null) 'owner_entity': ownerEntity,
        if (purchaseDate != null)
          'purchase_date': purchaseDate!.toUtc().toIso8601String(),
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (currentValue != null) 'current_value': currentValue,
        if (mortgageBalance != null) 'mortgage_balance': mortgageBalance,
        if (mortgagePayment != null) 'mortgage_payment': mortgagePayment,
        if (insurancePolicyNumber != null)
          'insurance_policy_number': insurancePolicyNumber,
        if (insuranceProvider != null) 'insurance_provider': insuranceProvider,
        if (insurancePremium != null) 'insurance_premium': insurancePremium,
        if (taxAssessment != null) 'tax_assessment': taxAssessment,
        if (annualTax != null) 'annual_tax': annualTax,
        if (managementFeePct != null) 'management_fee_pct': managementFeePct,
        if (notes != null) 'notes': notes,
        'status': _enumToDb(status),
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'property_type': _enumToDb(propertyType),
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
        'total_units': totalUnits,
        'owner_entity': ownerEntity,
        'purchase_date': purchaseDate?.toUtc().toIso8601String(),
        'purchase_price': purchasePrice,
        'current_value': currentValue,
        'mortgage_balance': mortgageBalance,
        'mortgage_payment': mortgagePayment,
        'insurance_policy_number': insurancePolicyNumber,
        'insurance_provider': insuranceProvider,
        'insurance_premium': insurancePremium,
        'tax_assessment': taxAssessment,
        'annual_tax': annualTax,
        'management_fee_pct': managementFeePct,
        'notes': notes,
        'status': _enumToDb(status),
      };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? '',
      companyId: (json['company_id'] ?? json['companyId']) as String? ?? '',
      name: (json['name'] as String?) ?? '',
      propertyType: _parseEnum(
        (json['property_type'] ?? json['propertyType']) as String?,
        PropertyType.values,
        PropertyType.singleFamily,
      ),
      addressLine1:
          (json['address_line1'] ?? json['addressLine1']) as String? ?? '',
      addressLine2:
          (json['address_line2'] ?? json['addressLine2']) as String?,
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      zip: (json['zip'] as String?) ?? '',
      country: json['country'] as String?,
      totalUnits:
          (json['total_units'] ?? json['totalUnits'] as num?)?.toInt() ?? 1,
      ownerEntity:
          (json['owner_entity'] ?? json['ownerEntity']) as String?,
      purchaseDate:
          _parseDate(json['purchase_date'] ?? json['purchaseDate']),
      purchasePrice:
          (json['purchase_price'] ?? json['purchasePrice'] as num?)
              ?.toDouble(),
      currentValue:
          (json['current_value'] ?? json['currentValue'] as num?)
              ?.toDouble(),
      mortgageBalance:
          (json['mortgage_balance'] ?? json['mortgageBalance'] as num?)
              ?.toDouble(),
      mortgagePayment:
          (json['mortgage_payment'] ?? json['mortgagePayment'] as num?)
              ?.toDouble(),
      insurancePolicyNumber:
          (json['insurance_policy_number'] ?? json['insurancePolicyNumber'])
              as String?,
      insuranceProvider:
          (json['insurance_provider'] ?? json['insuranceProvider'])
              as String?,
      insurancePremium:
          (json['insurance_premium'] ?? json['insurancePremium'] as num?)
              ?.toDouble(),
      taxAssessment:
          (json['tax_assessment'] ?? json['taxAssessment'] as num?)
              ?.toDouble(),
      annualTax:
          (json['annual_tax'] ?? json['annualTax'] as num?)?.toDouble(),
      managementFeePct:
          (json['management_fee_pct'] ?? json['managementFeePct'] as num?)
              ?.toDouble(),
      notes: json['notes'] as String?,
      status: _parseEnum(
        json['status'] as String?,
        PropertyStatus.values,
        PropertyStatus.active,
      ),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
    );
  }

  Property copyWith({
    String? id,
    String? companyId,
    String? name,
    PropertyType? propertyType,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zip,
    String? country,
    int? totalUnits,
    String? ownerEntity,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    double? mortgageBalance,
    double? mortgagePayment,
    String? insurancePolicyNumber,
    String? insuranceProvider,
    double? insurancePremium,
    double? taxAssessment,
    double? annualTax,
    double? managementFeePct,
    String? notes,
    PropertyStatus? status,
  }) {
    return Property(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      propertyType: propertyType ?? this.propertyType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      country: country ?? this.country,
      totalUnits: totalUnits ?? this.totalUnits,
      ownerEntity: ownerEntity ?? this.ownerEntity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      mortgageBalance: mortgageBalance ?? this.mortgageBalance,
      mortgagePayment: mortgagePayment ?? this.mortgagePayment,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePremium: insurancePremium ?? this.insurancePremium,
      taxAssessment: taxAssessment ?? this.taxAssessment,
      annualTax: annualTax ?? this.annualTax,
      managementFeePct: managementFeePct ?? this.managementFeePct,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static T _parseEnum<T extends Enum>(
    String? value,
    List<T> values,
    T defaultValue,
  ) {
    if (value == null || value.isEmpty) return defaultValue;
    // Try direct match on enum name (camelCase).
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Try snake_case → camelCase conversion.
    final camel = _snakeToCamel(value);
    for (final v in values) {
      if (v.name == camel) return v;
    }
    return defaultValue;
  }

  static String _snakeToCamel(String value) {
    final parts = value.split('_');
    if (parts.length <= 1) return value;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty
            ? ''
            : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }

  static String _enumToDb<T extends Enum>(T value) {
    // Convert camelCase to snake_case.
    return value.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

class Unit {
  final String id;
  final String propertyId;
  final String unitNumber;
  final int? bedrooms;
  final double? bathrooms;
  final int? squareFeet;
  final int? floorLevel;
  final List<String> features;
  final double monthlyRent;
  final double? securityDeposit;
  final UnitStatus status;
  final DateTime? availableDate;
  final String? currentTenantId;
  final String? currentLeaseId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Unit({
    this.id = '',
    this.propertyId = '',
    required this.unitNumber,
    this.bedrooms,
    this.bathrooms,
    this.squareFeet,
    this.floorLevel,
    this.features = const [],
    this.monthlyRent = 0,
    this.securityDeposit,
    this.status = UnitStatus.vacant,
    this.availableDate,
    this.currentTenantId,
    this.currentLeaseId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'property_id': propertyId,
        'unit_number': unitNumber,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (squareFeet != null) 'square_feet': squareFeet,
        if (floorLevel != null) 'floor_level': floorLevel,
        'features': features,
        'monthly_rent': monthlyRent,
        if (securityDeposit != null) 'security_deposit': securityDeposit,
        'status': Property._enumToDb(status),
        if (availableDate != null)
          'available_date': availableDate!.toUtc().toIso8601String(),
        if (currentTenantId != null) 'current_tenant_id': currentTenantId,
        if (currentLeaseId != null) 'current_lease_id': currentLeaseId,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_number': unitNumber,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'square_feet': squareFeet,
        'floor_level': floorLevel,
        'features': features,
        'monthly_rent': monthlyRent,
        'security_deposit': securityDeposit,
        'status': Property._enumToDb(status),
        'available_date': availableDate?.toUtc().toIso8601String(),
        'current_tenant_id': currentTenantId,
        'current_lease_id': currentLeaseId,
        'notes': notes,
      };

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitNumber:
          (json['unit_number'] ?? json['unitNumber']) as String? ?? '',
      bedrooms:
          (json['bedrooms'] as num?)?.toInt(),
      bathrooms:
          (json['bathrooms'] as num?)?.toDouble(),
      squareFeet:
          (json['square_feet'] ?? json['squareFeet'] as num?)?.toInt(),
      floorLevel:
          (json['floor_level'] ?? json['floorLevel'] as num?)?.toInt(),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      monthlyRent:
          (json['monthly_rent'] ?? json['monthlyRent'] as num?)
              ?.toDouble() ??
          0,
      securityDeposit:
          (json['security_deposit'] ?? json['securityDeposit'] as num?)
              ?.toDouble(),
      status: Property._parseEnum(
        json['status'] as String?,
        UnitStatus.values,
        UnitStatus.vacant,
      ),
      availableDate: Property._parseDate(
          json['available_date'] ?? json['availableDate']),
      currentTenantId:
          (json['current_tenant_id'] ?? json['currentTenantId']) as String?,
      currentLeaseId:
          (json['current_lease_id'] ?? json['currentLeaseId']) as String?,
      notes: json['notes'] as String?,
      createdAt:
          Property._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          Property._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  Unit copyWith({
    String? id,
    String? propertyId,
    String? unitNumber,
    int? bedrooms,
    double? bathrooms,
    int? squareFeet,
    int? floorLevel,
    List<String>? features,
    double? monthlyRent,
    double? securityDeposit,
    UnitStatus? status,
    DateTime? availableDate,
    String? currentTenantId,
    String? currentLeaseId,
    String? notes,
  }) {
    return Unit(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFeet: squareFeet ?? this.squareFeet,
      floorLevel: floorLevel ?? this.floorLevel,
      features: features ?? this.features,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      availableDate: availableDate ?? this.availableDate,
      currentTenantId: currentTenantId ?? this.currentTenantId,
      currentLeaseId: currentLeaseId ?? this.currentLeaseId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Tenant {
  final String id;
  final String companyId;
  final String name;
  final String? email;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? dateOfBirth;
  final String? ssnLast4;
  final String? employer;
  final String? employerPhone;
  final double? monthlyIncome;
  final int? creditScore;
  final String? backgroundCheckStatus;
  final DateTime? moveInDate;
  final DateTime? moveOutDate;
  final TenantStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tenant({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.email,
    this.phone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.dateOfBirth,
    this.ssnLast4,
    this.employer,
    this.employerPhone,
    this.monthlyIncome,
    this.creditScore,
    this.backgroundCheckStatus,
    this.moveInDate,
    this.moveOutDate,
    this.status = TenantStatus.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName =>
      name.isNotEmpty ? name : email ?? 'Unknown';

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toUtc().toIso8601String(),
        if (ssnLast4 != null) 'ssn_last4': ssnLast4,
        if (employer != null) 'employer': employer,
        if (employerPhone != null) 'employer_phone': employerPhone,
        if (monthlyIncome != null) 'monthly_income': monthlyIncome,
        if (creditScore != null) 'credit_score': creditScore,
        if (backgroundCheckStatus != null)
          'background_check_status': backgroundCheckStatus,
        if (moveInDate != null)
          'move_in_date': moveInDate!.toUtc().toIso8601String(),
        if (moveOutDate != null)
          'move_out_date': moveOutDate!.toUtc().toIso8601String(),
        'status': Property._enumToDb(status),
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'date_of_birth': dateOfBirth?.toUtc().toIso8601String(),
        'ssn_last4': ssnLast4,
        'employer': employer,
        'employer_phone': employerPhone,
        'monthly_income': monthlyIncome,
        'credit_score': creditScore,
        'background_check_status': backgroundCheckStatus,
        'move_in_date': moveInDate?.toUtc().toIso8601String(),
        'move_out_date': moveOutDate?.toUtc().toIso8601String(),
        'status': Property._enumToDb(status),
        'notes': notes,
      };

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String? ?? '',
      companyId: (json['company_id'] ?? json['companyId']) as String? ?? '',
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      emergencyContactName:
          (json['emergency_contact_name'] ?? json['emergencyContactName'])
              as String?,
      emergencyContactPhone:
          (json['emergency_contact_phone'] ?? json['emergencyContactPhone'])
              as String?,
      dateOfBirth: Property._parseDate(
          json['date_of_birth'] ?? json['dateOfBirth']),
      ssnLast4:
          (json['ssn_last4'] ?? json['ssnLast4']) as String?,
      employer: json['employer'] as String?,
      employerPhone:
          (json['employer_phone'] ?? json['employerPhone']) as String?,
      monthlyIncome:
          (json['monthly_income'] ?? json['monthlyIncome'] as num?)
              ?.toDouble(),
      creditScore:
          (json['credit_score'] ?? json['creditScore'] as num?)?.toInt(),
      backgroundCheckStatus:
          (json['background_check_status'] ?? json['backgroundCheckStatus'])
              as String?,
      moveInDate: Property._parseDate(
          json['move_in_date'] ?? json['moveInDate']),
      moveOutDate: Property._parseDate(
          json['move_out_date'] ?? json['moveOutDate']),
      status: Property._parseEnum(
        json['status'] as String?,
        TenantStatus.values,
        TenantStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt:
          Property._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          Property._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  Tenant copyWith({
    String? id,
    String? companyId,
    String? name,
    String? email,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? dateOfBirth,
    String? ssnLast4,
    String? employer,
    String? employerPhone,
    double? monthlyIncome,
    int? creditScore,
    String? backgroundCheckStatus,
    DateTime? moveInDate,
    DateTime? moveOutDate,
    TenantStatus? status,
    String? notes,
  }) {
    return Tenant(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ssnLast4: ssnLast4 ?? this.ssnLast4,
      employer: employer ?? this.employer,
      employerPhone: employerPhone ?? this.employerPhone,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      creditScore: creditScore ?? this.creditScore,
      backgroundCheckStatus:
          backgroundCheckStatus ?? this.backgroundCheckStatus,
      moveInDate: moveInDate ?? this.moveInDate,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Lease {
  final String id;
  final String companyId;
  final String unitId;
  final String tenantId;
  final String propertyId;
  final LeaseType leaseType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double? securityDeposit;
  final double? lateFeeAmount;
  final int? lateFeeGraceDays;
  final double? petDeposit;
  final double? petRent;
  final int? paymentDueDay;
  final bool autoRenew;
  final String? renewalTerms;
  final DateTime? signedDate;
  final String? signedDocumentUrl;
  final LeaseStatus status;
  final DateTime? terminationDate;
  final String? terminationReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lease({
    this.id = '',
    this.companyId = '',
    this.unitId = '',
    this.tenantId = '',
    this.propertyId = '',
    this.leaseType = LeaseType.fixedTerm,
    this.startDate,
    this.endDate,
    this.monthlyRent = 0,
    this.securityDeposit,
    this.lateFeeAmount,
    this.lateFeeGraceDays,
    this.petDeposit,
    this.petRent,
    this.paymentDueDay,
    this.autoRenew = false,
    this.renewalTerms,
    this.signedDate,
    this.signedDocumentUrl,
    this.status = LeaseStatus.draft,
    this.terminationDate,
    this.terminationReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpiringSoon {
    if (endDate == null) return false;
    return endDate!.difference(DateTime.now()).inDays <= 30;
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'unit_id': unitId,
        'tenant_id': tenantId,
        'property_id': propertyId,
        'lease_type': Property._enumToDb(leaseType),
        if (startDate != null)
          'start_date': startDate!.toUtc().toIso8601String(),
        if (endDate != null)
          'end_date': endDate!.toUtc().toIso8601String(),
        'monthly_rent': monthlyRent,
        if (securityDeposit != null) 'security_deposit': securityDeposit,
        if (lateFeeAmount != null) 'late_fee_amount': lateFeeAmount,
        if (lateFeeGraceDays != null) 'late_fee_grace_days': lateFeeGraceDays,
        if (petDeposit != null) 'pet_deposit': petDeposit,
        if (petRent != null) 'pet_rent': petRent,
        if (paymentDueDay != null) 'payment_due_day': paymentDueDay,
        'auto_renew': autoRenew,
        if (renewalTerms != null) 'renewal_terms': renewalTerms,
        if (signedDate != null)
          'signed_date': signedDate!.toUtc().toIso8601String(),
        if (signedDocumentUrl != null)
          'signed_document_url': signedDocumentUrl,
        'status': Property._enumToDb(status),
        if (terminationDate != null)
          'termination_date': terminationDate!.toUtc().toIso8601String(),
        if (terminationReason != null)
          'termination_reason': terminationReason,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_id': unitId,
        'tenant_id': tenantId,
        'property_id': propertyId,
        'lease_type': Property._enumToDb(leaseType),
        'start_date': startDate?.toUtc().toIso8601String(),
        'end_date': endDate?.toUtc().toIso8601String(),
        'monthly_rent': monthlyRent,
        'security_deposit': securityDeposit,
        'late_fee_amount': lateFeeAmount,
        'late_fee_grace_days': lateFeeGraceDays,
        'pet_deposit': petDeposit,
        'pet_rent': petRent,
        'payment_due_day': paymentDueDay,
        'auto_renew': autoRenew,
        'renewal_terms': renewalTerms,
        'signed_date': signedDate?.toUtc().toIso8601String(),
        'signed_document_url': signedDocumentUrl,
        'status': Property._enumToDb(status),
        'termination_date': terminationDate?.toUtc().toIso8601String(),
        'termination_reason': terminationReason,
        'notes': notes,
      };

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'] as String? ?? '',
      companyId: (json['company_id'] ?? json['companyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String? ?? '',
      tenantId: (json['tenant_id'] ?? json['tenantId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      leaseType: Property._parseEnum(
        (json['lease_type'] ?? json['leaseType']) as String?,
        LeaseType.values,
        LeaseType.fixedTerm,
      ),
      startDate: Property._parseDate(
          json['start_date'] ?? json['startDate']),
      endDate: Property._parseDate(
          json['end_date'] ?? json['endDate']),
      monthlyRent:
          (json['monthly_rent'] ?? json['monthlyRent'] as num?)
              ?.toDouble() ??
          0,
      securityDeposit:
          (json['security_deposit'] ?? json['securityDeposit'] as num?)
              ?.toDouble(),
      lateFeeAmount:
          (json['late_fee_amount'] ?? json['lateFeeAmount'] as num?)
              ?.toDouble(),
      lateFeeGraceDays:
          (json['late_fee_grace_days'] ?? json['lateFeeGraceDays'] as num?)
              ?.toInt(),
      petDeposit:
          (json['pet_deposit'] ?? json['petDeposit'] as num?)?.toDouble(),
      petRent:
          (json['pet_rent'] ?? json['petRent'] as num?)?.toDouble(),
      paymentDueDay:
          (json['payment_due_day'] ?? json['paymentDueDay'] as num?)
              ?.toInt(),
      autoRenew:
          (json['auto_renew'] ?? json['autoRenew']) as bool? ?? false,
      renewalTerms:
          (json['renewal_terms'] ?? json['renewalTerms']) as String?,
      signedDate: Property._parseDate(
          json['signed_date'] ?? json['signedDate']),
      signedDocumentUrl:
          (json['signed_document_url'] ?? json['signedDocumentUrl'])
              as String?,
      status: Property._parseEnum(
        json['status'] as String?,
        LeaseStatus.values,
        LeaseStatus.draft,
      ),
      terminationDate: Property._parseDate(
          json['termination_date'] ?? json['terminationDate']),
      terminationReason:
          (json['termination_reason'] ?? json['terminationReason'])
              as String?,
      notes: json['notes'] as String?,
      createdAt:
          Property._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          Property._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  Lease copyWith({
    String? id,
    String? companyId,
    String? unitId,
    String? tenantId,
    String? propertyId,
    LeaseType? leaseType,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
    double? securityDeposit,
    double? lateFeeAmount,
    int? lateFeeGraceDays,
    double? petDeposit,
    double? petRent,
    int? paymentDueDay,
    bool? autoRenew,
    String? renewalTerms,
    DateTime? signedDate,
    String? signedDocumentUrl,
    LeaseStatus? status,
    DateTime? terminationDate,
    String? terminationReason,
    String? notes,
  }) {
    return Lease(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      leaseType: leaseType ?? this.leaseType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      lateFeeAmount: lateFeeAmount ?? this.lateFeeAmount,
      lateFeeGraceDays: lateFeeGraceDays ?? this.lateFeeGraceDays,
      petDeposit: petDeposit ?? this.petDeposit,
      petRent: petRent ?? this.petRent,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      autoRenew: autoRenew ?? this.autoRenew,
      renewalTerms: renewalTerms ?? this.renewalTerms,
      signedDate: signedDate ?? this.signedDate,
      signedDocumentUrl: signedDocumentUrl ?? this.signedDocumentUrl,
      status: status ?? this.status,
      terminationDate: terminationDate ?? this.terminationDate,
      terminationReason: terminationReason ?? this.terminationReason,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
