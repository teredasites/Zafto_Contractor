import 'package:equatable/equatable.dart';

/// A supported marketplace platform (Craigslist, eBay, HD, etc.)
class MarketplaceSource extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String sourceType;
  final String? baseUrl;
  final Map<String, dynamic> apiConfig;
  final bool isActive;
  final String? iconName;
  final DateTime createdAt;

  const MarketplaceSource({
    required this.id,
    required this.name,
    required this.slug,
    required this.sourceType,
    this.baseUrl,
    this.apiConfig = const {},
    this.isActive = true,
    this.iconName,
    required this.createdAt,
  });

  factory MarketplaceSource.fromJson(Map<String, dynamic> json) {
    return MarketplaceSource(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sourceType: json['source_type'] as String,
      baseUrl: json['base_url'] as String?,
      apiConfig: (json['api_config'] as Map<String, dynamic>?) ?? {},
      isActive: json['is_active'] as bool? ?? true,
      iconName: json['icon_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'source_type': sourceType,
        'base_url': baseUrl,
        'api_config': apiConfig,
        'is_active': isActive,
        'icon_name': iconName,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, name, slug, sourceType, baseUrl, isActive, iconName];
}

/// A normalized listing from any marketplace source.
class MarketplaceListing extends Equatable {
  final String id;
  final String companyId;
  final String sourceId;

  // Listing info
  final String? externalId;
  final String externalUrl;
  final String title;
  final String? description;
  final int? priceCents;
  final String currency;
  final String? condition;

  // Seller
  final String? sellerName;
  final String? sellerLocation;
  final double? sellerRating;

  // Location
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? distanceMiles;

  // Photos
  final List<dynamic> photos;
  final int photoCount;

  // Categorization
  final String? tradeCategory;
  final String? itemCategory;
  final String? brand;
  final String? model;
  final int? year;

  // CPSC recall
  final bool recallChecked;
  final bool recallFound;
  final String? recallId;
  final String? recallDescription;

  // Status
  final String status;
  final DateTime importedAt;

  // Metadata
  final Map<String, dynamic>? rawData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const MarketplaceListing({
    required this.id,
    required this.companyId,
    required this.sourceId,
    this.externalId,
    required this.externalUrl,
    required this.title,
    this.description,
    this.priceCents,
    this.currency = 'USD',
    this.condition,
    this.sellerName,
    this.sellerLocation,
    this.sellerRating,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.zipCode,
    this.distanceMiles,
    this.photos = const [],
    this.photoCount = 0,
    this.tradeCategory,
    this.itemCategory,
    this.brand,
    this.model,
    this.year,
    this.recallChecked = false,
    this.recallFound = false,
    this.recallId,
    this.recallDescription,
    this.status = 'active',
    required this.importedAt,
    this.rawData,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      sourceId: json['source_id'] as String,
      externalId: json['external_id'] as String?,
      externalUrl: json['external_url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: json['price_cents'] as int?,
      currency: json['currency'] as String? ?? 'USD',
      condition: json['condition'] as String?,
      sellerName: json['seller_name'] as String?,
      sellerLocation: json['seller_location'] as String?,
      sellerRating: (json['seller_rating'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      distanceMiles: (json['distance_miles'] as num?)?.toDouble(),
      photos: (json['photos'] as List<dynamic>?) ?? [],
      photoCount: json['photo_count'] as int? ?? 0,
      tradeCategory: json['trade_category'] as String?,
      itemCategory: json['item_category'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      recallChecked: json['recall_checked'] as bool? ?? false,
      recallFound: json['recall_found'] as bool? ?? false,
      recallId: json['recall_id'] as String?,
      recallDescription: json['recall_description'] as String?,
      status: json['status'] as String? ?? 'active',
      importedAt: DateTime.parse(json['imported_at'] as String),
      rawData: json['raw_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'source_id': sourceId,
        'external_id': externalId,
        'external_url': externalUrl,
        'title': title,
        'description': description,
        'price_cents': priceCents,
        'currency': currency,
        'condition': condition,
        'seller_name': sellerName,
        'seller_location': sellerLocation,
        'seller_rating': sellerRating,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'distance_miles': distanceMiles,
        'photos': photos,
        'photo_count': photoCount,
        'trade_category': tradeCategory,
        'item_category': itemCategory,
        'brand': brand,
        'model': model,
        'year': year,
        'recall_checked': recallChecked,
        'recall_found': recallFound,
        'recall_id': recallId,
        'recall_description': recallDescription,
        'status': status,
        'imported_at': importedAt.toIso8601String(),
        'raw_data': rawData,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  MarketplaceListing copyWith({
    String? id,
    String? companyId,
    String? sourceId,
    String? externalId,
    String? externalUrl,
    String? title,
    String? description,
    int? priceCents,
    String? currency,
    String? condition,
    String? sellerName,
    String? sellerLocation,
    double? sellerRating,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? zipCode,
    double? distanceMiles,
    List<dynamic>? photos,
    int? photoCount,
    String? tradeCategory,
    String? itemCategory,
    String? brand,
    String? model,
    int? year,
    bool? recallChecked,
    bool? recallFound,
    String? recallId,
    String? recallDescription,
    String? status,
    DateTime? importedAt,
    Map<String, dynamic>? rawData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      sourceId: sourceId ?? this.sourceId,
      externalId: externalId ?? this.externalId,
      externalUrl: externalUrl ?? this.externalUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      condition: condition ?? this.condition,
      sellerName: sellerName ?? this.sellerName,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      sellerRating: sellerRating ?? this.sellerRating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      photos: photos ?? this.photos,
      photoCount: photoCount ?? this.photoCount,
      tradeCategory: tradeCategory ?? this.tradeCategory,
      itemCategory: itemCategory ?? this.itemCategory,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      recallChecked: recallChecked ?? this.recallChecked,
      recallFound: recallFound ?? this.recallFound,
      recallId: recallId ?? this.recallId,
      recallDescription: recallDescription ?? this.recallDescription,
      status: status ?? this.status,
      importedAt: importedAt ?? this.importedAt,
      rawData: rawData ?? this.rawData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Display price formatted as dollars.
  String get displayPrice {
    if (priceCents == null) return 'Contact for pricing';
    return '\$${(priceCents! / 100).toStringAsFixed(2)}';
  }

  bool get isActive => status == 'active';
  bool get hasRecall => recallFound;
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        companyId,
        sourceId,
        externalUrl,
        title,
        priceCents,
        status,
        recallFound,
      ];
}

/// A saved/favorited/watched listing.
class MarketplaceSavedListing extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String listingId;
  final String savedType;
  final String? notes;
  final int? priceAtSave;
  final int? priceAlertThreshold;
  final DateTime createdAt;

  const MarketplaceSavedListing({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.listingId,
    this.savedType = 'favorite',
    this.notes,
    this.priceAtSave,
    this.priceAlertThreshold,
    required this.createdAt,
  });

  factory MarketplaceSavedListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceSavedListing(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      listingId: json['listing_id'] as String,
      savedType: json['saved_type'] as String? ?? 'favorite',
      notes: json['notes'] as String?,
      priceAtSave: json['price_at_save'] as int?,
      priceAlertThreshold: json['price_alert_threshold'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'user_id': userId,
        'listing_id': listingId,
        'saved_type': savedType,
        'notes': notes,
        'price_at_save': priceAtSave,
        'price_alert_threshold': priceAlertThreshold,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, companyId, userId, listingId, savedType];
}

/// A saved search with alert configuration.
class MarketplaceSearch extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String name;
  final String? query;
  final String? tradeCategory;
  final String? itemCategory;
  final int? minPriceCents;
  final int? maxPriceCents;
  final List<dynamic>? conditionFilter;
  final int? maxDistanceMiles;
  final List<dynamic>? sourceFilter;
  final List<dynamic>? brandFilter;
  final bool alertEnabled;
  final String alertFrequency;
  final DateTime? lastAlertAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const MarketplaceSearch({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.name,
    this.query,
    this.tradeCategory,
    this.itemCategory,
    this.minPriceCents,
    this.maxPriceCents,
    this.conditionFilter,
    this.maxDistanceMiles,
    this.sourceFilter,
    this.brandFilter,
    this.alertEnabled = true,
    this.alertFrequency = 'daily',
    this.lastAlertAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory MarketplaceSearch.fromJson(Map<String, dynamic> json) {
    return MarketplaceSearch(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      query: json['query'] as String?,
      tradeCategory: json['trade_category'] as String?,
      itemCategory: json['item_category'] as String?,
      minPriceCents: json['min_price_cents'] as int?,
      maxPriceCents: json['max_price_cents'] as int?,
      conditionFilter: json['condition_filter'] as List<dynamic>?,
      maxDistanceMiles: json['max_distance_miles'] as int?,
      sourceFilter: json['source_filter'] as List<dynamic>?,
      brandFilter: json['brand_filter'] as List<dynamic>?,
      alertEnabled: json['alert_enabled'] as bool? ?? true,
      alertFrequency: json['alert_frequency'] as String? ?? 'daily',
      lastAlertAt: json['last_alert_at'] != null
          ? DateTime.parse(json['last_alert_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'user_id': userId,
        'name': name,
        'query': query,
        'trade_category': tradeCategory,
        'item_category': itemCategory,
        'min_price_cents': minPriceCents,
        'max_price_cents': maxPriceCents,
        'condition_filter': conditionFilter,
        'max_distance_miles': maxDistanceMiles,
        'source_filter': sourceFilter,
        'brand_filter': brandFilter,
        'alert_enabled': alertEnabled,
        'alert_frequency': alertFrequency,
        'last_alert_at': lastAlertAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  MarketplaceSearch copyWith({
    String? name,
    String? query,
    String? tradeCategory,
    String? itemCategory,
    int? minPriceCents,
    int? maxPriceCents,
    List<dynamic>? conditionFilter,
    int? maxDistanceMiles,
    List<dynamic>? sourceFilter,
    List<dynamic>? brandFilter,
    bool? alertEnabled,
    String? alertFrequency,
  }) {
    return MarketplaceSearch(
      id: id,
      companyId: companyId,
      userId: userId,
      name: name ?? this.name,
      query: query ?? this.query,
      tradeCategory: tradeCategory ?? this.tradeCategory,
      itemCategory: itemCategory ?? this.itemCategory,
      minPriceCents: minPriceCents ?? this.minPriceCents,
      maxPriceCents: maxPriceCents ?? this.maxPriceCents,
      conditionFilter: conditionFilter ?? this.conditionFilter,
      maxDistanceMiles: maxDistanceMiles ?? this.maxDistanceMiles,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      brandFilter: brandFilter ?? this.brandFilter,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertFrequency: alertFrequency ?? this.alertFrequency,
      lastAlertAt: lastAlertAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, userId, name, alertEnabled];
}

/// Cached CPSC recall record.
class CpscRecallRecord extends Equatable {
  final String id;
  final String recallNumber;
  final String productName;
  final String? description;
  final String? hazard;
  final String? remedy;
  final String? manufacturer;
  final String? productType;
  final List<dynamic> categories;
  final List<dynamic> images;
  final DateTime? recallDate;
  final DateTime lastFetchedAt;
  final DateTime createdAt;

  const CpscRecallRecord({
    required this.id,
    required this.recallNumber,
    required this.productName,
    this.description,
    this.hazard,
    this.remedy,
    this.manufacturer,
    this.productType,
    this.categories = const [],
    this.images = const [],
    this.recallDate,
    required this.lastFetchedAt,
    required this.createdAt,
  });

  factory CpscRecallRecord.fromJson(Map<String, dynamic> json) {
    return CpscRecallRecord(
      id: json['id'] as String,
      recallNumber: json['recall_number'] as String,
      productName: json['product_name'] as String,
      description: json['description'] as String?,
      hazard: json['hazard'] as String?,
      remedy: json['remedy'] as String?,
      manufacturer: json['manufacturer'] as String?,
      productType: json['product_type'] as String?,
      categories: (json['categories'] as List<dynamic>?) ?? [],
      images: (json['images'] as List<dynamic>?) ?? [],
      recallDate: json['recall_date'] != null
          ? DateTime.parse(json['recall_date'] as String)
          : null,
      lastFetchedAt: DateTime.parse(json['last_fetched_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recall_number': recallNumber,
        'product_name': productName,
        'description': description,
        'hazard': hazard,
        'remedy': remedy,
        'manufacturer': manufacturer,
        'product_type': productType,
        'categories': categories,
        'images': images,
        'recall_date': recallDate?.toIso8601String(),
        'last_fetched_at': lastFetchedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, recallNumber, productName, manufacturer];
}
