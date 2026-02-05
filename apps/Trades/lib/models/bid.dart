import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bid status progression
enum BidStatus {
  draft,      // Being created
  sent,       // Sent to customer
  viewed,     // Customer opened it
  accepted,   // Customer accepted
  declined,   // Customer declined
  expired,    // Past validity date
  converted,  // Converted to job
  cancelled   // Manually cancelled
}

/// Pricing tier for Good/Better/Best options
enum PricingTier { good, better, best }

/// Single line item on a bid
class BidLineItem extends Equatable {
  final String id;
  final String description;
  final double quantity;
  final String unit; // 'each', 'hour', 'foot', 'sqft'
  final double unitPrice;
  final double total;
  final bool isTaxable;
  final String? category; // 'labor', 'materials', 'equipment', 'permits'
  final String? notes;
  final String? calculationId; // Link to calculator result
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

  @override
  List<Object?> get props => [id, description, quantity, unitPrice];

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
        id: map['id'] as String,
        description: map['description'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'each',
        unitPrice: (map['unitPrice'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
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

  /// Recalculate total from quantity and unit price
  BidLineItem recalculate() {
    return copyWith(total: quantity * unitPrice);
  }
}

/// Good/Better/Best pricing option
class BidOption extends Equatable {
  final String id;
  final String name; // 'Good', 'Better', 'Best' or custom
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
    this.subtotal = 0.0,
    this.total = 0.0,
    this.isRecommended = false,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, tier, total];

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
        id: map['id'] as String,
        name: map['name'] as String,
        tier: PricingTier.values.firstWhere(
          (t) => t.name == map['tier'],
          orElse: () => PricingTier.good,
        ),
        description: map['description'] as String?,
        lineItems: (map['lineItems'] as List<dynamic>?)
                ?.map((e) => BidLineItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
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

  /// Recalculate totals from line items
  BidOption recalculate(double taxRate) {
    final newSubtotal = lineItems.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );
    final taxableAmount = lineItems
        .where((item) => item.isTaxable)
        .fold<double>(0.0, (sum, item) => sum + item.total);
    final taxAmount = taxableAmount * (taxRate / 100);
    return copyWith(
      subtotal: newSubtotal,
      total: newSubtotal + taxAmount,
    );
  }
}

/// Optional add-on that customer can select
class BidAddOn extends Equatable {
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

  @override
  List<Object?> get props => [id, name, price, isSelected];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'isSelected': isSelected,
        'sortOrder': sortOrder,
      };

  factory BidAddOn.fromMap(Map<String, dynamic> map) => BidAddOn(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        price: (map['price'] as num).toDouble(),
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

/// Photo attachment on a bid
class BidPhoto extends Equatable {
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

  @override
  List<Object?> get props => [id, localPath];

  Map<String, dynamic> toMap() => {
        'id': id,
        'localPath': localPath,
        'cloudUrl': cloudUrl,
        'caption': caption,
        'hasMarkup': hasMarkup,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BidPhoto.fromMap(Map<String, dynamic> map) => BidPhoto(
        id: map['id'] as String,
        localPath: map['localPath'] as String,
        cloudUrl: map['cloudUrl'] as String?,
        caption: map['caption'] as String?,
        hasMarkup: map['hasMarkup'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

/// Main Bid model
class Bid extends Equatable {
  final String id;
  final String companyId;
  final String createdByUserId;

  // Bid Number
  final String bidNumber;

  // Trade Type (for template loading)
  final String tradeType;

  // Customer (denormalized for offline/PDF)
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String customerAddress;
  final String? customerCity;
  final String? customerState;
  final String? customerZipCode;

  // Project Details
  final String? projectName;
  final String? projectDescription;
  final String? scopeOfWork;

  // Good/Better/Best Options
  final List<BidOption> options;
  final String? selectedOptionId;

  // Add-Ons
  final List<BidAddOn> addOns;

  // Photos
  final List<BidPhoto> photos;

  // Calculator Integrations
  final List<String> calculationIds;

  // Pricing
  final double subtotal;
  final double discountAmount;
  final String? discountReason;
  final double taxRate;
  final double taxAmount;
  final double addOnsTotal;
  final double total;
  final double depositAmount;
  final double depositPercent; // e.g., 50 for 50%

  // Status
  final BidStatus status;

  // Client Portal
  final String? accessToken; // Unique token for client web view
  final DateTime? viewedAt;
  final String? viewedByIp;

  // Customer Response
  final DateTime? respondedAt;
  final String? declineReason;

  // Signature
  final String? signatureData; // Base64 PNG
  final String? signedByName;
  final DateTime? signedAt;

  // Payment (deposit)
  final String? depositPaymentId; // Stripe payment ID
  final DateTime? depositPaidAt;
  final String? depositPaymentMethod;

  // Validity
  final DateTime? validUntil;

  // PDF
  final String? pdfPath;
  final String? pdfUrl;

  // Conversion
  final String? convertedJobId;
  final DateTime? convertedAt;

  // Company Branding (denormalized for PDF)
  final String? companyName;
  final String? companyLogoUrl;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyLicense;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final String? notes;
  final String? internalNotes;
  final String? terms;
  final bool syncedToCloud;

  const Bid({
    required this.id,
    required this.companyId,
    required this.createdByUserId,
    required this.bidNumber,
    this.tradeType = 'electrical',
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.customerAddress,
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
    this.calculationIds = const [],
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.discountReason,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.addOnsTotal = 0.0,
    this.total = 0.0,
    this.depositAmount = 0.0,
    this.depositPercent = 50.0,
    this.status = BidStatus.draft,
    this.accessToken,
    this.viewedAt,
    this.viewedByIp,
    this.respondedAt,
    this.declineReason,
    this.signatureData,
    this.signedByName,
    this.signedAt,
    this.depositPaymentId,
    this.depositPaidAt,
    this.depositPaymentMethod,
    this.validUntil,
    this.pdfPath,
    this.pdfUrl,
    this.convertedJobId,
    this.convertedAt,
    this.companyName,
    this.companyLogoUrl,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companyLicense,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.notes,
    this.internalNotes,
    this.terms,
    this.syncedToCloud = false,
  });

  @override
  List<Object?> get props => [id, companyId, bidNumber, status, updatedAt];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Display title - project name or customer name
  String get displayTitle => projectName ?? customerName;

  /// Check if bid is editable
  bool get isEditable =>
      status == BidStatus.draft || status == BidStatus.declined;

  /// Check if bid can be sent
  bool get canSend => status == BidStatus.draft && options.isNotEmpty;

  /// Check if bid is pending response
  bool get isPending =>
      status == BidStatus.sent || status == BidStatus.viewed;

  /// Check if bid was accepted
  bool get isAccepted => status == BidStatus.accepted;

  /// Check if bid can be converted to job
  bool get canConvert =>
      status == BidStatus.accepted && convertedJobId == null;

  /// Check if bid has been converted
  bool get isConverted => convertedJobId != null;

  /// Check if bid has signature
  bool get hasSigned => signatureData != null && signedByName != null;

  /// Check if deposit is paid
  bool get depositPaid => depositPaidAt != null;

  /// Check if bid is expired
  bool get isExpired {
    if (validUntil == null) return false;
    if (status == BidStatus.accepted || status == BidStatus.converted) {
      return false;
    }
    return DateTime.now().isAfter(validUntil!);
  }

  /// Get selected option
  BidOption? get selectedOption {
    if (selectedOptionId == null) return null;
    try {
      return options.firstWhere((o) => o.id == selectedOptionId);
    } catch (_) {
      return null;
    }
  }

  /// Get selected add-ons
  List<BidAddOn> get selectedAddOns =>
      addOns.where((a) => a.isSelected).toList();

  /// Full customer address string
  String get fullCustomerAddress {
    final parts = [customerAddress];
    if (customerCity != null) parts.add(customerCity!);
    if (customerState != null) parts.add(customerState!);
    if (customerZipCode != null) parts.add(customerZipCode!);
    return parts.join(', ');
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case BidStatus.draft:
        return 'Draft';
      case BidStatus.sent:
        return 'Sent';
      case BidStatus.viewed:
        return 'Viewed';
      case BidStatus.accepted:
        return 'Accepted';
      case BidStatus.declined:
        return 'Declined';
      case BidStatus.expired:
        return 'Expired';
      case BidStatus.converted:
        return 'Converted';
      case BidStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Format total for display
  String get totalDisplay => '\$${total.toStringAsFixed(2)}';

  /// Format deposit for display
  String get depositDisplay => '\$${depositAmount.toStringAsFixed(2)}';

  /// Client portal URL
  String? get clientPortalUrl {
    if (accessToken == null) return null;
    return 'https://zafto.cloud/bid/$accessToken';
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  /// Recalculate totals based on selected option and add-ons
  Bid recalculate() {
    // Get selected option total
    final optionTotal = selectedOption?.total ?? 0.0;

    // Calculate add-ons total
    final newAddOnsTotal = selectedAddOns.fold<double>(
      0.0,
      (sum, addon) => sum + addon.price,
    );

    // Calculate subtotal (option + addons - discount)
    final newSubtotal = optionTotal + newAddOnsTotal;
    final afterDiscount = newSubtotal - discountAmount;

    // Calculate tax
    final newTaxAmount = afterDiscount * (taxRate / 100);

    // Calculate total
    final newTotal = afterDiscount + newTaxAmount;

    // Calculate deposit
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
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'bidNumber': bidNumber,
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
      'calculationIds': calculationIds,
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
      'accessToken': accessToken,
      'viewedAt': viewedAt?.toIso8601String(),
      'viewedByIp': viewedByIp,
      'respondedAt': respondedAt?.toIso8601String(),
      'declineReason': declineReason,
      'signatureData': signatureData,
      'signedByName': signedByName,
      'signedAt': signedAt?.toIso8601String(),
      'depositPaymentId': depositPaymentId,
      'depositPaidAt': depositPaidAt?.toIso8601String(),
      'depositPaymentMethod': depositPaymentMethod,
      'validUntil': validUntil?.toIso8601String(),
      'pdfPath': pdfPath,
      'pdfUrl': pdfUrl,
      'convertedJobId': convertedJobId,
      'convertedAt': convertedAt?.toIso8601String(),
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'companyLicense': companyLicense,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'notes': notes,
      'internalNotes': internalNotes,
      'terms': terms,
      'syncedToCloud': syncedToCloud,
    };
  }

  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      createdByUserId: map['createdByUserId'] as String,
      bidNumber: map['bidNumber'] as String,
      tradeType: map['tradeType'] as String? ?? 'electrical',
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String,
      customerEmail: map['customerEmail'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerAddress: map['customerAddress'] as String,
      customerCity: map['customerCity'] as String?,
      customerState: map['customerState'] as String?,
      customerZipCode: map['customerZipCode'] as String?,
      projectName: map['projectName'] as String?,
      projectDescription: map['projectDescription'] as String?,
      scopeOfWork: map['scopeOfWork'] as String?,
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => BidOption.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectedOptionId: map['selectedOptionId'] as String?,
      addOns: (map['addOns'] as List<dynamic>?)
              ?.map((e) => BidAddOn.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      photos: (map['photos'] as List<dynamic>?)
              ?.map((e) => BidPhoto.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      calculationIds: List<String>.from(map['calculationIds'] ?? []),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountReason: map['discountReason'] as String?,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      addOnsTotal: (map['addOnsTotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0.0,
      depositPercent: (map['depositPercent'] as num?)?.toDouble() ?? 50.0,
      status: BidStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BidStatus.draft,
      ),
      accessToken: map['accessToken'] as String?,
      viewedAt:
          map['viewedAt'] != null ? _parseDateTime(map['viewedAt']) : null,
      viewedByIp: map['viewedByIp'] as String?,
      respondedAt: map['respondedAt'] != null
          ? _parseDateTime(map['respondedAt'])
          : null,
      declineReason: map['declineReason'] as String?,
      signatureData: map['signatureData'] as String?,
      signedByName: map['signedByName'] as String?,
      signedAt:
          map['signedAt'] != null ? _parseDateTime(map['signedAt']) : null,
      depositPaymentId: map['depositPaymentId'] as String?,
      depositPaidAt: map['depositPaidAt'] != null
          ? _parseDateTime(map['depositPaidAt'])
          : null,
      depositPaymentMethod: map['depositPaymentMethod'] as String?,
      validUntil: map['validUntil'] != null
          ? _parseDateTime(map['validUntil'])
          : null,
      pdfPath: map['pdfPath'] as String?,
      pdfUrl: map['pdfUrl'] as String?,
      convertedJobId: map['convertedJobId'] as String?,
      convertedAt: map['convertedAt'] != null
          ? _parseDateTime(map['convertedAt'])
          : null,
      companyName: map['companyName'] as String?,
      companyLogoUrl: map['companyLogoUrl'] as String?,
      companyAddress: map['companyAddress'] as String?,
      companyPhone: map['companyPhone'] as String?,
      companyEmail: map['companyEmail'] as String?,
      companyLicense: map['companyLicense'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      sentAt: map['sentAt'] != null ? _parseDateTime(map['sentAt']) : null,
      notes: map['notes'] as String?,
      internalNotes: map['internalNotes'] as String?,
      terms: map['terms'] as String?,
      syncedToCloud: map['syncedToCloud'] as bool? ?? false,
    );
  }

  factory Bid.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bid.fromMap({...data, 'id': doc.id});
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

  Bid copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? bidNumber,
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
    List<String>? calculationIds,
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
    String? accessToken,
    DateTime? viewedAt,
    String? viewedByIp,
    DateTime? respondedAt,
    String? declineReason,
    String? signatureData,
    String? signedByName,
    DateTime? signedAt,
    String? depositPaymentId,
    DateTime? depositPaidAt,
    String? depositPaymentMethod,
    DateTime? validUntil,
    String? pdfPath,
    String? pdfUrl,
    String? convertedJobId,
    DateTime? convertedAt,
    String? companyName,
    String? companyLogoUrl,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyLicense,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    String? notes,
    String? internalNotes,
    String? terms,
    bool? syncedToCloud,
  }) {
    return Bid(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      bidNumber: bidNumber ?? this.bidNumber,
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
      projectDescription: projectDescription ?? this.projectDescription,
      scopeOfWork: scopeOfWork ?? this.scopeOfWork,
      options: options ?? this.options,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      addOns: addOns ?? this.addOns,
      photos: photos ?? this.photos,
      calculationIds: calculationIds ?? this.calculationIds,
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
      accessToken: accessToken ?? this.accessToken,
      viewedAt: viewedAt ?? this.viewedAt,
      viewedByIp: viewedByIp ?? this.viewedByIp,
      respondedAt: respondedAt ?? this.respondedAt,
      declineReason: declineReason ?? this.declineReason,
      signatureData: signatureData ?? this.signatureData,
      signedByName: signedByName ?? this.signedByName,
      signedAt: signedAt ?? this.signedAt,
      depositPaymentId: depositPaymentId ?? this.depositPaymentId,
      depositPaidAt: depositPaidAt ?? this.depositPaidAt,
      depositPaymentMethod: depositPaymentMethod ?? this.depositPaymentMethod,
      validUntil: validUntil ?? this.validUntil,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      convertedJobId: convertedJobId ?? this.convertedJobId,
      convertedAt: convertedAt ?? this.convertedAt,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyLicense: companyLicense ?? this.companyLicense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sentAt: sentAt ?? this.sentAt,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      terms: terms ?? this.terms,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new bid draft
  factory Bid.create({
    required String id,
    required String companyId,
    required String createdByUserId,
    required String bidNumber,
    required String customerName,
    required String customerAddress,
    String? customerId,
    String? projectName,
    String tradeType = 'electrical',
    double taxRate = 0.0,
    double depositPercent = 50.0,
  }) {
    final now = DateTime.now();
    return Bid(
      id: id,
      companyId: companyId,
      createdByUserId: createdByUserId,
      bidNumber: bidNumber,
      tradeType: tradeType,
      customerId: customerId,
      customerName: customerName,
      customerAddress: customerAddress,
      projectName: projectName,
      taxRate: taxRate,
      depositPercent: depositPercent,
      validUntil: now.add(const Duration(days: 30)), // 30-day validity
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create bid from existing customer
  factory Bid.fromCustomer({
    required String id,
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
    double taxRate = 0.0,
  }) {
    final now = DateTime.now();
    return Bid(
      id: id,
      companyId: companyId,
      createdByUserId: createdByUserId,
      bidNumber: bidNumber,
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
