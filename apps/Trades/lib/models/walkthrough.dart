// ZAFTO Walkthrough Model — Supabase Backend
// Maps to `walkthroughs` table. Represents a full property walkthrough
// with rooms, photos, and optional template/floor plan links.

class Walkthrough {
  final String id;
  final String companyId;
  final String createdBy;
  final String? customerId;
  final String? jobId;
  final String? bidId;
  final String? propertyId;
  final String name;
  final String walkthroughType;
  final String propertyType;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final String? templateId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final Map<String, dynamic>? weatherConditions;
  final int totalRooms;
  final int totalPhotos;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Walkthrough({
    this.id = '',
    this.companyId = '',
    this.createdBy = '',
    this.customerId,
    this.jobId,
    this.bidId,
    this.propertyId,
    this.name = '',
    this.walkthroughType = 'general',
    this.propertyType = 'residential',
    this.address = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.latitude,
    this.longitude,
    this.templateId,
    this.status = 'in_progress',
    this.startedAt,
    this.completedAt,
    this.notes,
    this.weatherConditions,
    this.totalRooms = 0,
    this.totalPhotos = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed: is walkthrough complete
  bool get isComplete => status == 'completed' || status == 'uploaded';

  // Computed: formatted display address
  String get displayAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty && zipCode.isNotEmpty) {
      parts.add('$state $zipCode');
    } else if (state.isNotEmpty) {
      parts.add(state);
    } else if (zipCode.isNotEmpty) {
      parts.add(zipCode);
    }
    return parts.join(', ');
  }

  // Computed: duration in minutes between started and completed (or now)
  int? get durationMinutes {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!).inMinutes;
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'created_by': createdBy,
        if (customerId != null) 'customer_id': customerId,
        if (jobId != null) 'job_id': jobId,
        if (bidId != null) 'bid_id': bidId,
        if (propertyId != null) 'property_id': propertyId,
        'name': name,
        'walkthrough_type': walkthroughType,
        'property_type': propertyType,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (templateId != null) 'template_id': templateId,
        'status': status,
        if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (weatherConditions != null) 'weather_conditions': weatherConditions,
        'total_rooms': totalRooms,
        'total_photos': totalPhotos,
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        if (customerId != null) 'customer_id': customerId,
        if (jobId != null) 'job_id': jobId,
        if (bidId != null) 'bid_id': bidId,
        if (propertyId != null) 'property_id': propertyId,
        'name': name,
        'walkthrough_type': walkthroughType,
        'property_type': propertyType,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'latitude': latitude,
        'longitude': longitude,
        'template_id': templateId,
        'status': status,
        'notes': notes,
        'weather_conditions': weatherConditions,
        'total_rooms': totalRooms,
        'total_photos': totalPhotos,
        'metadata': metadata,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Walkthrough.fromJson(Map<String, dynamic> json) {
    return Walkthrough(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      jobId: json['job_id'] as String?,
      bidId: json['bid_id'] as String?,
      propertyId: json['property_id'] as String?,
      name: json['name'] as String? ?? '',
      walkthroughType: json['walkthrough_type'] as String? ?? 'general',
      propertyType: json['property_type'] as String? ?? 'residential',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      templateId: json['template_id'] as String?,
      status: json['status'] as String? ?? 'in_progress',
      startedAt: _parseNullableDate(json['started_at']),
      completedAt: _parseNullableDate(json['completed_at']),
      notes: json['notes'] as String?,
      weatherConditions: json['weather_conditions'] as Map<String, dynamic>?,
      totalRooms: json['total_rooms'] as int? ?? 0,
      totalPhotos: json['total_photos'] as int? ?? 0,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Walkthrough copyWith({
    String? id,
    String? companyId,
    String? createdBy,
    String? customerId,
    String? jobId,
    String? bidId,
    String? propertyId,
    String? name,
    String? walkthroughType,
    String? propertyType,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? templateId,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    Map<String, dynamic>? weatherConditions,
    int? totalRooms,
    int? totalPhotos,
    Map<String, dynamic>? metadata,
  }) {
    return Walkthrough(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdBy: createdBy ?? this.createdBy,
      customerId: customerId ?? this.customerId,
      jobId: jobId ?? this.jobId,
      bidId: bidId ?? this.bidId,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      walkthroughType: walkthroughType ?? this.walkthroughType,
      propertyType: propertyType ?? this.propertyType,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      totalRooms: totalRooms ?? this.totalRooms,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
