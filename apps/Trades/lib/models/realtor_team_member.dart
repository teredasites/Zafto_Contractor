import 'package:equatable/equatable.dart';

/// Realtor team member — junction between user and realtor team.
/// Maps to `realtor_team_members` table.
class RealtorTeamMember extends Equatable {
  final String id;
  final String companyId;
  final String teamId;
  final String userId;
  final String role; // 'lead', 'member', 'isa', 'tc', 'admin'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const RealtorTeamMember({
    this.id = '',
    this.companyId = '',
    required this.teamId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, teamId, userId, role, updatedAt];

  factory RealtorTeamMember.fromJson(Map<String, dynamic> json) {
    return RealtorTeamMember(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
      leftAt: json['left_at'] != null
          ? DateTime.tryParse(json['left_at'].toString())
          : null,
      isActive: json['is_active'] as bool? ?? true,
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
        'team_id': teamId,
        'user_id': userId,
        'role': role,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'role': role,
        'is_active': isActive,
        'left_at': leftAt?.toIso8601String(),
      };

  RealtorTeamMember copyWith({
    String? id,
    String? companyId,
    String? teamId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RealtorTeamMember(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
