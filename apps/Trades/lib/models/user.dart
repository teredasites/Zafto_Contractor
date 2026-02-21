import 'package:equatable/equatable.dart';

/// User status for account management
enum UserStatus {
  active,     // Normal active user
  invited,    // Invited but hasn't completed signup
  suspended,  // Temporarily disabled
  deleted     // Soft deleted
}

/// User model with company and role references for multi-tenant RBAC
class User extends Equatable {
  final String id;              // Firebase Auth UID
  final String companyId;       // Tenant reference
  final String roleId;          // Role reference

  // Profile
  final String email;
  final String displayName;
  final String? phone;
  final String? avatarUrl;

  // Work Info
  final String? employeeId;     // Company's internal ID
  final String? title;          // 'Journeyman Electrician'
  final List<String> trades;    // Trades this user works
  final String? teamId;         // Team/location assignment

  // Status
  final UserStatus status;
  final DateTime? lastActiveAt;

  // Device
  final String? fcmToken;       // Push notifications
  final String? deviceId;

  // Time Clock Status (Session 23)
  final bool clockedIn;         // Currently on the clock
  final DateTime? clockedInAt;  // When they clocked in
  final Map<String, double>? lastLocation;  // {lat, lng} for live tracking

  // Preferences
  final String preferredNecYear;
  final bool darkMode;
  final bool hapticFeedback;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invitedBy;      // User who sent invite

  const User({
    required this.id,
    required this.companyId,
    required this.roleId,
    required this.email,
    required this.displayName,
    this.phone,
    this.avatarUrl,
    this.employeeId,
    this.title,
    this.trades = const ['electrical'],
    this.teamId,
    this.status = UserStatus.active,
    this.lastActiveAt,
    this.fcmToken,
    this.deviceId,
    this.clockedIn = false,
    this.clockedInAt,
    this.lastLocation,
    this.preferredNecYear = '2023',
    this.darkMode = true,
    this.hapticFeedback = true,
    required this.createdAt,
    required this.updatedAt,
    this.invitedBy,
  });

  @override
  List<Object?> get props => [id, companyId, roleId, email, updatedAt];

  /// Check if user is the company owner (for permission checks)
  bool isOwnerOf(String ownerUserId) => id == ownerUserId;

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Get initials for avatar fallback
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'roleId': roleId,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'employeeId': employeeId,
      'title': title,
      'trades': trades,
      'teamId': teamId,
      'status': status.name,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'clockedIn': clockedIn,
      'clockedInAt': clockedInAt?.toIso8601String(),
      'lastLocation': lastLocation,
      'preferredNecYear': preferredNecYear,
      'darkMode': darkMode,
      'hapticFeedback': hapticFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'invitedBy': invitedBy,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      roleId: map['roleId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? 'Unknown',
      phone: map['phone'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      employeeId: map['employeeId'] as String?,
      title: map['title'] as String?,
      trades: List<String>.from(map['trades'] ?? ['electrical']),
      teamId: map['teamId'] as String?,
      status: UserStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      lastActiveAt: map['lastActiveAt'] != null
          ? _parseDateTime(map['lastActiveAt'])
          : null,
      fcmToken: map['fcmToken'] as String?,
      deviceId: map['deviceId'] as String?,
      clockedIn: map['clockedIn'] as bool? ?? false,
      clockedInAt: map['clockedInAt'] != null
          ? _parseDateTime(map['clockedInAt'])
          : null,
      lastLocation: map['lastLocation'] != null
          ? Map<String, double>.from(map['lastLocation'])
          : null,
      preferredNecYear: map['preferredNecYear'] as String? ?? '2023',
      darkMode: map['darkMode'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      invitedBy: map['invitedBy'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  User copyWith({
    String? id,
    String? companyId,
    String? roleId,
    String? email,
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? employeeId,
    String? title,
    List<String>? trades,
    String? teamId,
    UserStatus? status,
    DateTime? lastActiveAt,
    String? fcmToken,
    String? deviceId,
    bool? clockedIn,
    DateTime? clockedInAt,
    Map<String, double>? lastLocation,
    String? preferredNecYear,
    bool? darkMode,
    bool? hapticFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? invitedBy,
  }) {
    return User(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      roleId: roleId ?? this.roleId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      employeeId: employeeId ?? this.employeeId,
      title: title ?? this.title,
      trades: trades ?? this.trades,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceId: deviceId ?? this.deviceId,
      clockedIn: clockedIn ?? this.clockedIn,
      clockedInAt: clockedInAt ?? this.clockedInAt,
      lastLocation: lastLocation ?? this.lastLocation,
      preferredNecYear: preferredNecYear ?? this.preferredNecYear,
      darkMode: darkMode ?? this.darkMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new user when signing up (becomes company owner)
  factory User.createOwner({
    required String id,
    required String companyId,
    required String roleId,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now();
    return User(
      id: id,
      companyId: companyId,
      roleId: roleId,
      email: email,
      displayName: displayName ?? email.split('@').first,
      status: UserStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create an invited user (pending signup)
  factory User.createInvited({
    required String id,
    required String companyId,
    required String roleId,
    required String email,
    required String invitedBy,
  }) {
    final now = DateTime.now();
    return User(
      id: id,
      companyId: companyId,
      roleId: roleId,
      email: email,
      displayName: email.split('@').first,
      status: UserStatus.invited,
      invitedBy: invitedBy,
      createdAt: now,
      updatedAt: now,
    );
  }
}
