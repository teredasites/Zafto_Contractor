// ZAFTO Bid Model — Supabase Schema
// Rewritten: Sprint B1d (Session 42)
//
// Matches public.bids table (core columns).
// Replaces models/bid.dart (Firebase/Equatable).
// Sub-models (BidLineItem, BidOption, BidAddOn, BidPhoto) stored
// as structured JSONB in the line_items column.

enum BidStatus {
  draft,
  sent,
  viewed,
  accepted,
  rejected,
  expired,
  converted,
  cancelled;

  // DB CHECK constraint only allows: draft, sent, viewed, accepted, rejected, expired.
  // converted → 'accepted', cancelled → 'expired' for DB writes.
  String get dbValue => switch (this) {
        BidStatus.converted => 'accepted',
        BidStatus.cancelled => 'expired',
        _ => name,
      };
}

enum PricingTier { good, better, best }

// ============================================================
// SUB-MODELS (stored in line_items JSONB)
// ============================================================

class BidLineItem {
  final String id;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;
  final bool isTaxable;
  final String? category;
  final String? notes;
  final String? calculationId;
  final int sortOrder;

  const BidLineItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit = 'each',
    required this.unitPrice,
    required this.total,
    this.isTaxable = true,
    this.category,
    this.notes,
    this.calculationId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'total': total,
        'isTaxable': isTaxable,
        'category': category,
        'notes': notes,
        'calculationId': calculationId,
        'sortOrder': sortOrder,
      };

  factory BidLineItem.fromMap(Map<String, dynamic> map) => BidLineItem(
        id: map['id'] as String? ?? '',
        description: map['description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String? ?? 'each',
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        isTaxable: map['isTaxable'] as bool? ?? true,
        category: map['category'] as String?,
        notes: map['notes'] as String?,
        calculationId: map['calculationId'] as String?,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  BidLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? total,
    bool? isTaxable,
    String? category,
    String? notes,
    String? calculationId,
    int? sortOrder,
  }) {
    return BidLineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      isTaxable: isTaxable ?? this.isTaxable,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      calculationId: calculationId ?? this.calculationId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  BidLineItem recalculate() => copyWith(total: quantity * unitPrice);
}

class BidOption {
  final String id;
  final String name;
  final PricingTier tier;
  final String? description;
  final List<BidLineItem> lineItems;
  final double subtotal;
  final double total;
  final bool isRecommended;
  final int sortOrder;

  const BidOption({
    required this.id,
    required this.name,
    required this.tier,
    this.description,
    this.lineItems = const [],
    this.subtotal = 0,
    this.total = 0,
    this.isRecommended = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tier': tier.name,
        'description': description,
        'lineItems': lineItems.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'total': total,
        'isRecommended': isRecommended,
        'sortOrder': sortOrder,
      };

  factory BidOption.fromMap(Map<String, dynamic> map) => BidOption(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        tier: PricingTier.values.firstWhere(
          (t) => t.name == map['tier'],
          orElse: () => PricingTier.good,
        ),
        description: map['description'] as String?,
        lineItems: (map['lineItems'] as List<dynamic>?)
                ?.map((e) =>
                    BidLineItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        isRecommended: map['isRecommended'] as bool? ?? false,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  BidOption copyWith({
    String? id,
    String? name,
    PricingTier? tier,
    String? description,
    List<BidLineItem>? lineItems,
    double? subtotal,
    double? total,
    bool? isRecommended,
    int? sortOrder,
  }) {
    return BidOption(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      description: description ?? this.description,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      isRecommended: isRecommended ?? this.isRecommended,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  BidOption recalculate(double taxRate) {
    final newSubtotal = lineItems.fold<double>(
        0.0, (sum, item) => sum + item.total);
    final taxableAmount = lineItems
        .where((item) => item.isTaxable)
        .fold<double>(0.0, (sum, item) => sum + item.total);
    final taxAmount = taxableAmount * (taxRate / 100);
    return copyWith(subtotal: newSubtotal, total: newSubtotal + taxAmount);
  }
}

class BidAddOn {
  final String id;
  final String name;
  final String? description;
  final double price;
  final bool isSelected;
  final int sortOrder;

  const BidAddOn({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.isSelected = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'isSelected': isSelected,
        'sortOrder': sortOrder,
      };

  factory BidAddOn.fromMap(Map<String, dynamic> map) => BidAddOn(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        isSelected: map['isSelected'] as bool? ?? false,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  BidAddOn copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isSelected,
    int? sortOrder,
  }) {
    return BidAddOn(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isSelected: isSelected ?? this.isSelected,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class BidPhoto {
  final String id;
  final String localPath;
  final String? cloudUrl;
  final String? caption;
  final bool hasMarkup;
  final DateTime createdAt;

  const BidPhoto({
    required this.id,
    required this.localPath,
    this.cloudUrl,
    this.caption,
    this.hasMarkup = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'localPath': localPath,
        'cloudUrl': cloudUrl,
        'caption': caption,
        'hasMarkup': hasMarkup,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BidPhoto.fromMap(Map<String, dynamic> map) => BidPhoto(
        id: map['id'] as String? ?? '',
        localPath: map['localPath'] as String? ?? '',
        cloudUrl: map['cloudUrl'] as String?,
        caption: map['caption'] as String?,
        hasMarkup: map['hasMarkup'] as bool? ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}

// ============================================================
// MAIN BID MODEL
// ============================================================

class Bid {
  final String id;
  final String companyId;
  final String createdByUserId;

  // Identifiers
  final String bidNumber;
  final String title;
  final String tradeType;

  // Customer (denormalized)
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String customerAddress;
  final String? customerCity;
  final String? customerState;
  final String? customerZipCode;

  // Project
  final String? projectName;
  final String? projectDescription;
  final String? scopeOfWork;

  // Good/Better/Best options (stored in line_items JSONB)
  final List<BidOption> options;
  final String? selectedOptionId;

  // Add-ons (stored in line_items JSONB)
  final List<BidAddOn> addOns;

  // Photos (stored in line_items JSONB)
  final List<BidPhoto> photos;

  // Pricing
  final double subtotal;
  final double discountAmount;
  final String? discountReason;
  final double taxRate;
  final double taxAmount;
  final double addOnsTotal;
  final double total;
  final double depositAmount;
  final double depositPercent;

  // Status
  final BidStatus status;

  // Dates
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? validUntil;

  // Signature
  final String? signatureData;
  final String? signedByName;
  final DateTime? signedAt;

  // PDF
  final String? pdfPath;
  final String? pdfUrl;

  // Relationships
  final String? jobId;

  // Notes
  final String? notes;
  final String? internalNotes;
  final String? terms;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Bid({
    this.id = '',
    this.companyId = '',
    this.createdByUserId = '',
    this.bidNumber = '',
    this.title = '',
    this.tradeType = 'electrical',
    this.customerId,
    this.customerName = '',
    this.customerEmail,
    this.customerPhone,
    this.customerAddress = '',
    this.customerCity,
    this.customerState,
    this.customerZipCode,
    this.projectName,
    this.projectDescription,
    this.scopeOfWork,
    this.options = const [],
    this.selectedOptionId,
    this.addOns = const [],
    this.photos = const [],
    this.subtotal = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.addOnsTotal = 0,
    this.total = 0,
    this.depositAmount = 0,
    this.depositPercent = 50,
    this.status = BidStatus.draft,
    this.sentAt,
    this.viewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.validUntil,
    this.signatureData,
    this.signedByName,
    this.signedAt,
    this.pdfPath,
    this.pdfUrl,
    this.jobId,
    this.notes,
    this.internalNotes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  // Generic JSON (camelCase for legacy code).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'bidNumber': bidNumber,
      'title': title,
      'tradeType': tradeType,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCity': customerCity,
      'customerState': customerState,
      'customerZipCode': customerZipCode,
      'projectName': projectName,
      'projectDescription': projectDescription,
      'scopeOfWork': scopeOfWork,
      'options': options.map((e) => e.toMap()).toList(),
      'selectedOptionId': selectedOptionId,
      'addOns': addOns.map((e) => e.toMap()).toList(),
      'photos': photos.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountReason': discountReason,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'addOnsTotal': addOnsTotal,
      'total': total,
      'depositAmount': depositAmount,
      'depositPercent': depositPercent,
      'status': status.name,
      'sentAt': sentAt?.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'validUntil': validUntil?.toIso8601String(),
      'signatureData': signatureData,
      'signedByName': signedByName,
      'signedAt': signedAt?.toIso8601String(),
      'pdfPath': pdfPath,
      'pdfUrl': pdfUrl,
      'jobId': jobId,
      'notes': notes,
      'internalNotes': internalNotes,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Backward compat alias for Firestore callers.
  Map<String, dynamic> toMap() => toJson();

  // Insert payload (snake_case, DB columns only).
  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'created_by_user_id': createdByUserId,
      'customer_id': customerId,
      'job_id': jobId,
      'bid_number': bidNumber,
      'title': title.isNotEmpty ? title : (projectName ?? customerName),
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      // Store options/addons/photos in line_items JSONB
      'line_items': {
        'options': options.map((o) => o.toMap()).toList(),
        'addOns': addOns.map((a) => a.toMap()).toList(),
        'photos': photos.map((p) => p.toMap()).toList(),
      },
      'scope_of_work': scopeOfWork,
      'terms': terms,
      'valid_until': validUntil?.toUtc().toIso8601String(),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'status': status.dbValue,
      'notes': notes,
    };
  }

  // Update payload (snake_case, DB columns only).
  Map<String, dynamic> toUpdateJson() {
    return {
      'customer_id': customerId,
      'job_id': jobId,
      'bid_number': bidNumber,
      'title': title.isNotEmpty ? title : (projectName ?? customerName),
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'line_items': {
        'options': options.map((o) => o.toMap()).toList(),
        'addOns': addOns.map((a) => a.toMap()).toList(),
        'photos': photos.map((p) => p.toMap()).toList(),
      },
      'scope_of_work': scopeOfWork,
      'terms': terms,
      'valid_until': validUntil?.toUtc().toIso8601String(),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'status': status.dbValue,
      'sent_at': sentAt?.toUtc().toIso8601String(),
      'viewed_at': viewedAt?.toUtc().toIso8601String(),
      'accepted_at': acceptedAt?.toUtc().toIso8601String(),
      'rejected_at': rejectedAt?.toUtc().toIso8601String(),
      'rejection_reason': rejectionReason,
      'signature_data': signatureData,
      'signed_by_name': signedByName,
      'signed_at': signedAt?.toUtc().toIso8601String(),
      'pdf_path': pdfPath,
      'pdf_url': pdfUrl,
      'notes': notes,
    };
  }

  // Handles both snake_case (Supabase) and camelCase (legacy).
  factory Bid.fromJson(Map<String, dynamic> json) {
    // Parse structured line_items JSONB
    final lineItemsData = json['line_items'] ?? json['lineItems'];
    List<BidOption> options = const [];
    List<BidAddOn> addOns = const [];
    List<BidPhoto> photos = const [];

    if (lineItemsData is Map<String, dynamic>) {
      options = (lineItemsData['options'] as List<dynamic>?)
              ?.map((e) =>
                  BidOption.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [];
      addOns = (lineItemsData['addOns'] as List<dynamic>?)
              ?.map((e) =>
                  BidAddOn.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [];
      photos = (lineItemsData['photos'] as List<dynamic>?)
              ?.map((e) =>
                  BidPhoto.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [];
    }

    // Also handle legacy format where options/addOns are top-level
    if (options.isEmpty && json['options'] is List) {
      options = (json['options'] as List<dynamic>)
          .map((e) => BidOption.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    if (addOns.isEmpty && json['addOns'] is List) {
      addOns = (json['addOns'] as List<dynamic>)
          .map((e) => BidAddOn.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    if (photos.isEmpty && json['photos'] is List) {
      photos = (json['photos'] as List<dynamic>)
          .map((e) => BidPhoto.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Bid(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      createdByUserId:
          (json['created_by_user_id'] ?? json['createdByUserId'])
              as String? ??
              '',
      bidNumber:
          (json['bid_number'] ?? json['bidNumber']) as String? ?? '',
      title: json['title'] as String? ?? '',
      tradeType:
          (json['trade_type'] ?? json['tradeType']) as String? ??
              'electrical',
      customerId:
          (json['customer_id'] ?? json['customerId']) as String?,
      customerName:
          (json['customer_name'] ?? json['customerName'])
              as String? ??
              '',
      customerEmail:
          (json['customer_email'] ?? json['customerEmail'])
              as String?,
      customerPhone:
          (json['customer_phone'] ?? json['customerPhone'])
              as String?,
      customerAddress:
          (json['customer_address'] ?? json['customerAddress'])
              as String? ??
              '',
      customerCity:
          (json['customer_city'] ?? json['customerCity'])
              as String?,
      customerState:
          (json['customer_state'] ?? json['customerState'])
              as String?,
      customerZipCode:
          (json['customer_zip_code'] ?? json['customerZipCode'])
              as String?,
      projectName:
          (json['project_name'] ?? json['projectName']) as String?,
      projectDescription:
          (json['project_description'] ?? json['projectDescription'])
              as String?,
      scopeOfWork:
          (json['scope_of_work'] ?? json['scopeOfWork']) as String?,
      options: options,
      selectedOptionId:
          (json['selected_option_id'] ?? json['selectedOptionId'])
              as String?,
      addOns: addOns,
      photos: photos,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount:
          ((json['discount_amount'] ?? json['discountAmount'])
                  as num?)
              ?.toDouble() ??
              0,
      discountReason:
          (json['discount_reason'] ?? json['discountReason'])
              as String?,
      taxRate:
          ((json['tax_rate'] ?? json['taxRate']) as num?)
              ?.toDouble() ??
              0,
      taxAmount:
          ((json['tax_amount'] ?? json['taxAmount']) as num?)
              ?.toDouble() ??
              0,
      addOnsTotal:
          ((json['add_ons_total'] ?? json['addOnsTotal']) as num?)
              ?.toDouble() ??
              0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      depositAmount:
          ((json['deposit_amount'] ?? json['depositAmount'])
                  as num?)
              ?.toDouble() ??
              0,
      depositPercent:
          ((json['deposit_percent'] ?? json['depositPercent'])
                  as num?)
              ?.toDouble() ??
              50,
      status: _parseStatus(json['status'] as String?),
      sentAt: _parseOptionalDate(
          json['sent_at'] ?? json['sentAt']),
      viewedAt: _parseOptionalDate(
          json['viewed_at'] ?? json['viewedAt']),
      acceptedAt: _parseOptionalDate(
          json['accepted_at'] ?? json['acceptedAt'] ??
          json['respondedAt']),
      rejectedAt: _parseOptionalDate(
          json['rejected_at'] ?? json['rejectedAt']),
      rejectionReason:
          (json['rejection_reason'] ?? json['rejectionReason'] ??
           json['declineReason']) as String?,
      validUntil: _parseOptionalDate(
          json['valid_until'] ?? json['validUntil']),
      signatureData:
          (json['signature_data'] ?? json['signatureData'])
              as String?,
      signedByName:
          (json['signed_by_name'] ?? json['signedByName'])
              as String?,
      signedAt: _parseOptionalDate(
          json['signed_at'] ?? json['signedAt']),
      pdfPath:
          (json['pdf_path'] ?? json['pdfPath']) as String?,
      pdfUrl:
          (json['pdf_url'] ?? json['pdfUrl']) as String?,
      jobId:
          (json['job_id'] ?? json['jobId'] ?? json['convertedJobId'])
              as String?,
      notes: json['notes'] as String?,
      internalNotes:
          (json['internal_notes'] ?? json['internalNotes'])
              as String?,
      terms: json['terms'] as String?,
      createdAt: _parseDate(
          json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(
          json['updated_at'] ?? json['updatedAt']),
      deletedAt: _parseOptionalDate(
          json['deleted_at'] ?? json['deletedAt']),
    );
  }

  // Backward compat alias.
  factory Bid.fromMap(Map<String, dynamic> map) => Bid.fromJson(map);

  static BidStatus _parseStatus(String? value) {
    if (value == null) return BidStatus.draft;
    // Handle DB 'rejected' → BidStatus.rejected
    // Handle legacy 'declined' → BidStatus.rejected
    if (value == 'declined') return BidStatus.rejected;
    return BidStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BidStatus.draft,
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

  String get displayTitle {
    if (title.isNotEmpty) return title;
    return projectName ?? customerName;
  }

  String get statusLabel => switch (status) {
        BidStatus.draft => 'Draft',
        BidStatus.sent => 'Sent',
        BidStatus.viewed => 'Viewed',
        BidStatus.accepted => 'Accepted',
        BidStatus.rejected => 'Rejected',
        BidStatus.expired => 'Expired',
        BidStatus.converted => 'Converted',
        BidStatus.cancelled => 'Cancelled',
      };

  // Alias for old code that used statusDisplay.
  String get statusDisplay => statusLabel;

  bool get isEditable =>
      status == BidStatus.draft || status == BidStatus.rejected;

  bool get canSend =>
      status == BidStatus.draft && options.isNotEmpty;

  bool get isPending =>
      status == BidStatus.sent || status == BidStatus.viewed;

  bool get isAccepted => status == BidStatus.accepted;

  bool get canConvert =>
      status == BidStatus.accepted && jobId == null;

  bool get isConverted => jobId != null &&
      (status == BidStatus.accepted ||
       status == BidStatus.converted);

  bool get hasSigned =>
      signatureData != null && signedByName != null;

  bool get isExpired {
    if (validUntil == null) return false;
    if (status == BidStatus.accepted ||
        status == BidStatus.converted) {
      return false;
    }
    return DateTime.now().isAfter(validUntil!);
  }

  BidOption? get selectedOption {
    if (selectedOptionId == null) return null;
    try {
      return options.firstWhere((o) => o.id == selectedOptionId);
    } catch (_) {
      return null;
    }
  }

  List<BidAddOn> get selectedAddOns =>
      addOns.where((a) => a.isSelected).toList();

  String get fullCustomerAddress {
    final parts = <String>[];
    if (customerAddress.isNotEmpty) parts.add(customerAddress);
    if (customerCity != null) parts.add(customerCity!);
    if (customerState != null) parts.add(customerState!);
    if (customerZipCode != null) parts.add(customerZipCode!);
    return parts.join(', ');
  }

  String get totalDisplay => '\$${total.toStringAsFixed(2)}';

  String get depositDisplay =>
      '\$${depositAmount.toStringAsFixed(2)}';

  // ============================================================
  // CALCULATIONS
  // ============================================================

  Bid recalculate() {
    final optionTotal = selectedOption?.total ?? 0;
    final newAddOnsTotal = selectedAddOns.fold<double>(
        0.0, (sum, addon) => sum + addon.price);
    final newSubtotal = optionTotal + newAddOnsTotal;
    final afterDiscount = newSubtotal - discountAmount;
    final newTaxAmount = afterDiscount * (taxRate / 100);
    final newTotal = afterDiscount + newTaxAmount;
    final newDepositAmount = newTotal * (depositPercent / 100);

    return copyWith(
      subtotal: newSubtotal,
      addOnsTotal: newAddOnsTotal,
      taxAmount: newTaxAmount,
      total: newTotal,
      depositAmount: newDepositAmount,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Bid copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? bidNumber,
    String? title,
    String? tradeType,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    String? customerCity,
    String? customerState,
    String? customerZipCode,
    String? projectName,
    String? projectDescription,
    String? scopeOfWork,
    List<BidOption>? options,
    String? selectedOptionId,
    List<BidAddOn>? addOns,
    List<BidPhoto>? photos,
    double? subtotal,
    double? discountAmount,
    String? discountReason,
    double? taxRate,
    double? taxAmount,
    double? addOnsTotal,
    double? total,
    double? depositAmount,
    double? depositPercent,
    BidStatus? status,
    DateTime? sentAt,
    DateTime? viewedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? validUntil,
    String? signatureData,
    String? signedByName,
    DateTime? signedAt,
    String? pdfPath,
    String? pdfUrl,
    String? jobId,
    String? notes,
    String? internalNotes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Bid(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      bidNumber: bidNumber ?? this.bidNumber,
      title: title ?? this.title,
      tradeType: tradeType ?? this.tradeType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerCity: customerCity ?? this.customerCity,
      customerState: customerState ?? this.customerState,
      customerZipCode: customerZipCode ?? this.customerZipCode,
      projectName: projectName ?? this.projectName,
      projectDescription:
          projectDescription ?? this.projectDescription,
      scopeOfWork: scopeOfWork ?? this.scopeOfWork,
      options: options ?? this.options,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      addOns: addOns ?? this.addOns,
      photos: photos ?? this.photos,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      addOnsTotal: addOnsTotal ?? this.addOnsTotal,
      total: total ?? this.total,
      depositAmount: depositAmount ?? this.depositAmount,
      depositPercent: depositPercent ?? this.depositPercent,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      validUntil: validUntil ?? this.validUntil,
      signatureData: signatureData ?? this.signatureData,
      signedByName: signedByName ?? this.signedByName,
      signedAt: signedAt ?? this.signedAt,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  factory Bid.create({
    required String companyId,
    required String createdByUserId,
    required String bidNumber,
    required String customerName,
    required String customerAddress,
    String? customerId,
    String? projectName,
    String tradeType = 'electrical',
    double taxRate = 0,
    double depositPercent = 50,
  }) {
    final now = DateTime.now();
    return Bid(
      companyId: companyId,
      createdByUserId: createdByUserId,
      bidNumber: bidNumber,
      title: projectName ?? customerName,
      tradeType: tradeType,
      customerId: customerId,
      customerName: customerName,
      customerAddress: customerAddress,
      projectName: projectName,
      taxRate: taxRate,
      depositPercent: depositPercent,
      validUntil: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Bid.fromCustomer({
    required String companyId,
    required String createdByUserId,
    required String bidNumber,
    required String customerId,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    required String customerAddress,
    String? customerCity,
    String? customerState,
    String? customerZipCode,
    String tradeType = 'electrical',
    double taxRate = 0,
  }) {
    final now = DateTime.now();
    return Bid(
      companyId: companyId,
      createdByUserId: createdByUserId,
      bidNumber: bidNumber,
      title: customerName,
      tradeType: tradeType,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerCity: customerCity,
      customerState: customerState,
      customerZipCode: customerZipCode,
      taxRate: taxRate,
      validUntil: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }
}
