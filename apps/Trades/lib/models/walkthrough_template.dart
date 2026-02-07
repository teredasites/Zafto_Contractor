// ZAFTO Walkthrough Template Model — Supabase Backend
// Maps to `walkthrough_templates` table. Templates define pre-configured
// room sets and checklists for common walkthrough scenarios.

// Helper class for room definitions in the rooms JSONB array
class TemplateRoom {
  final String name;
  final String roomType;
  final int floorLevel;
  final int sortOrder;
  final Map<String, dynamic> customFields;

  const TemplateRoom({
    this.name = '',
    this.roomType = 'other',
    this.floorLevel = 1,
    this.sortOrder = 0,
    this.customFields = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'room_type': roomType,
        'floor_level': floorLevel,
        'sort_order': sortOrder,
        if (customFields.isNotEmpty) 'custom_fields': customFields,
      };

  factory TemplateRoom.fromJson(Map<String, dynamic> json) {
    return TemplateRoom(
      name: json['name'] as String? ?? '',
      roomType: json['room_type'] as String? ?? 'other',
      floorLevel: json['floor_level'] as int? ?? 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      customFields:
          (json['custom_fields'] as Map<String, dynamic>?) ?? const {},
    );
  }

  TemplateRoom copyWith({
    String? name,
    String? roomType,
    int? floorLevel,
    int? sortOrder,
    Map<String, dynamic>? customFields,
  }) {
    return TemplateRoom(
      name: name ?? this.name,
      roomType: roomType ?? this.roomType,
      floorLevel: floorLevel ?? this.floorLevel,
      sortOrder: sortOrder ?? this.sortOrder,
      customFields: customFields ?? this.customFields,
    );
  }
}

class WalkthroughTemplate {
  final String id;
  final String? companyId;
  final String name;
  final String? description;
  final String? walkthroughType;
  final String? propertyType;
  final List<TemplateRoom> rooms;
  final Map<String, dynamic> customFields;
  final List<dynamic>? checklist;
  final String? aiInstructions;
  final bool isSystem;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalkthroughTemplate({
    this.id = '',
    this.companyId,
    this.name = '',
    this.description,
    this.walkthroughType,
    this.propertyType,
    this.rooms = const [],
    this.customFields = const {},
    this.checklist,
    this.aiInstructions,
    this.isSystem = false,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        if (companyId != null) 'company_id': companyId,
        'name': name,
        if (description != null) 'description': description,
        if (walkthroughType != null) 'walkthrough_type': walkthroughType,
        if (propertyType != null) 'property_type': propertyType,
        'rooms': rooms.map((r) => r.toJson()).toList(),
        'custom_fields': customFields,
        if (checklist != null) 'checklist': checklist,
        if (aiInstructions != null) 'ai_instructions': aiInstructions,
        'is_system': isSystem,
        'usage_count': usageCount,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'walkthrough_type': walkthroughType,
        'property_type': propertyType,
        'rooms': rooms.map((r) => r.toJson()).toList(),
        'custom_fields': customFields,
        'checklist': checklist,
        'ai_instructions': aiInstructions,
        'is_system': isSystem,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory WalkthroughTemplate.fromJson(Map<String, dynamic> json) {
    return WalkthroughTemplate(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      walkthroughType: json['walkthrough_type'] as String?,
      propertyType: json['property_type'] as String?,
      rooms: _parseRooms(json['rooms']),
      customFields:
          (json['custom_fields'] as Map<String, dynamic>?) ?? const {},
      checklist: json['checklist'] as List<dynamic>?,
      aiInstructions: json['ai_instructions'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  WalkthroughTemplate copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? walkthroughType,
    String? propertyType,
    List<TemplateRoom>? rooms,
    Map<String, dynamic>? customFields,
    List<dynamic>? checklist,
    String? aiInstructions,
    bool? isSystem,
    int? usageCount,
  }) {
    return WalkthroughTemplate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      walkthroughType: walkthroughType ?? this.walkthroughType,
      propertyType: propertyType ?? this.propertyType,
      rooms: rooms ?? this.rooms,
      customFields: customFields ?? this.customFields,
      checklist: checklist ?? this.checklist,
      aiInstructions: aiInstructions ?? this.aiInstructions,
      isSystem: isSystem ?? this.isSystem,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<TemplateRoom> _parseRooms(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((r) => TemplateRoom.fromJson(r))
          .toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
