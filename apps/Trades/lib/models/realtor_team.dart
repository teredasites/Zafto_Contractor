import 'package:equatable/equatable.dart';

/// Realtor team — belongs to a brokerage company.
/// Maps to `realtor_teams` table.
class RealtorTeam extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? teamLeadUserId;
  final String? parentTeamId;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const RealtorTeam({
    this.id = '',
    this.companyId = '',
    required this.name,
    this.description,
    this.teamLeadUserId,
    this.parentTeamId,
    this.isActive = true,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, companyId, name, updatedAt];

  factory RealtorTeam.fromJson(Map<String, dynamic> json) {
    return RealtorTeam(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      teamLeadUserId: json['team_lead_user_id'] as String?,
      parentTeamId: json['parent_team_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (description != null) 'description': description,
        if (teamLeadUserId != null) 'team_lead_user_id': teamLeadUserId,
        if (parentTeamId != null) 'parent_team_id': parentTeamId,
        'is_active': isActive,
        'settings': settings,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'team_lead_user_id': teamLeadUserId,
        'parent_team_id': parentTeamId,
        'is_active': isActive,
        'settings': settings,
      };

  RealtorTeam copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? teamLeadUserId,
    String? parentTeamId,
    bool? isActive,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RealtorTeam(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      teamLeadUserId: teamLeadUserId ?? this.teamLeadUserId,
      parentTeamId: parentTeamId ?? this.parentTeamId,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
