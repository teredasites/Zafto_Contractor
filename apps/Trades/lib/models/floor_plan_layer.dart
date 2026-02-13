// ZAFTO Floor Plan Layer Model — Supabase Backend
// Maps to `floor_plan_layers` table. Trade-specific overlay layers
// (electrical, plumbing, HVAC, damage, custom) per floor plan.

enum LayerType { electrical, plumbing, hvac, damage, custom }

class FloorPlanLayer {
  final String id;
  final String floorPlanId;
  final String companyId;
  final LayerType layerType;
  final String layerName;
  final Map<String, dynamic> layerData;
  final bool visible;
  final bool locked;
  final double opacity;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FloorPlanLayer({
    this.id = '',
    required this.floorPlanId,
    required this.companyId,
    this.layerType = LayerType.custom,
    required this.layerName,
    this.layerData = const {},
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Computed
  bool get isEditable => !locked && deletedAt == null;
  bool get isTradeLayer => layerType != LayerType.custom;

  /// Default layer name for a given trade type
  static String defaultName(LayerType type) {
    switch (type) {
      case LayerType.electrical:
        return 'Electrical';
      case LayerType.plumbing:
        return 'Plumbing';
      case LayerType.hvac:
        return 'HVAC';
      case LayerType.damage:
        return 'Damage';
      case LayerType.custom:
        return 'Custom Layer';
    }
  }

  /// Default color for layer type (ARGB hex)
  static int defaultColor(LayerType type) {
    switch (type) {
      case LayerType.electrical:
        return 0xFFFF9800; // Orange
      case LayerType.plumbing:
        return 0xFF2196F3; // Blue
      case LayerType.hvac:
        return 0xFF4CAF50; // Green
      case LayerType.damage:
        return 0xFFF44336; // Red
      case LayerType.custom:
        return 0xFF9C27B0; // Purple
    }
  }

  Map<String, dynamic> toInsertJson() => {
        'floor_plan_id': floorPlanId,
        'company_id': companyId,
        'layer_type': layerType.name,
        'layer_name': layerName,
        'layer_data': layerData,
        'visible': visible,
        'locked': locked,
        'opacity': opacity,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'layer_name': layerName,
        'layer_data': layerData,
        'visible': visible,
        'locked': locked,
        'opacity': opacity,
        'sort_order': sortOrder,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory FloorPlanLayer.fromJson(Map<String, dynamic> json) {
    return FloorPlanLayer(
      id: json['id'] as String? ?? '',
      floorPlanId: json['floor_plan_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      layerType: _parseLayerType(json['layer_type'] as String?),
      layerName: json['layer_name'] as String? ?? 'Layer',
      layerData: (json['layer_data'] as Map<String, dynamic>?) ?? const {},
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: _parseDouble(json['opacity']) ?? 1.0,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  FloorPlanLayer copyWith({
    String? id,
    String? floorPlanId,
    String? companyId,
    LayerType? layerType,
    String? layerName,
    Map<String, dynamic>? layerData,
    bool? visible,
    bool? locked,
    double? opacity,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FloorPlanLayer(
      id: id ?? this.id,
      floorPlanId: floorPlanId ?? this.floorPlanId,
      companyId: companyId ?? this.companyId,
      layerType: layerType ?? this.layerType,
      layerName: layerName ?? this.layerName,
      layerData: layerData ?? this.layerData,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static LayerType _parseLayerType(String? value) {
    if (value == null) return LayerType.custom;
    return LayerType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => LayerType.custom,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
