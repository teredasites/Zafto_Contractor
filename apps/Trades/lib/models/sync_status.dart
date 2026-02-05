import 'package:equatable/equatable.dart';

/// Sync state enum
enum SyncState {
  idle,
  syncing,
  synced,
  error,
  offline,
}

/// Sync status model for tracking synchronization state
class SyncStatus extends Equatable {
  final SyncState state;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final String? errorMessage;
  final double? progress;

  const SyncStatus({
    this.state = SyncState.idle,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.errorMessage,
    this.progress,
  });

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncTime,
    int? pendingChanges,
    String? errorMessage,
    double? progress,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      errorMessage: errorMessage,
      progress: progress,
    );
  }

  bool get isSyncing => state == SyncState.syncing;
  bool get isSynced => state == SyncState.synced;
  bool get isOffline => state == SyncState.offline;
  bool get hasError => state == SyncState.error;
  bool get hasPendingChanges => pendingChanges > 0;

  String get statusText {
    switch (state) {
      case SyncState.idle:
        return 'Ready to sync';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.synced:
        return 'All changes synced';
      case SyncState.error:
        return errorMessage ?? 'Sync failed';
      case SyncState.offline:
        return 'Offline - changes saved locally';
    }
  }

  @override
  List<Object?> get props => [state, lastSyncTime, pendingChanges, errorMessage, progress];
}

/// Data types that can be synced
enum SyncDataType {
  examProgress,
  favorites,
  calculationHistory,
  settings,
  aiCredits,
  jobDocuments,
}

/// Pending sync operation for offline queue
class PendingSyncOperation extends Equatable {
  final String id;
  final SyncDataType dataType;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  const PendingSyncOperation({
    required this.id,
    required this.dataType,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  PendingSyncOperation copyWith({
    String? id,
    SyncDataType? dataType,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingSyncOperation(
      id: id ?? this.id,
      dataType: dataType ?? this.dataType,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType.name,
      'operation': operation,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      dataType: SyncDataType.values.firstWhere(
        (e) => e.name == json['dataType'],
        orElse: () => SyncDataType.settings,
      ),
      operation: json['operation'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, dataType, operation, data, createdAt, retryCount];
}

/// User data document structure for Firestore
class UserSyncData extends Equatable {
  final String oderId;
  final Map<String, dynamic> examProgress;
  final List<String> favorites;
  final Map<String, dynamic> settings;
  final int aiCredits;
  final DateTime lastModified;
  final int schemaVersion;

  const UserSyncData({
    required this.oderId,
    this.examProgress = const {},
    this.favorites = const [],
    this.settings = const {},
    this.aiCredits = 20,
    required this.lastModified,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'oderId': oderId,
      'examProgress': examProgress,
      'favorites': favorites,
      'settings': settings,
      'aiCredits': aiCredits,
      'lastModified': lastModified.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  factory UserSyncData.fromJson(Map<String, dynamic> json) {
    return UserSyncData(
      oderId: json['oderId'] as String? ?? '',
      examProgress: Map<String, dynamic>.from(json['examProgress'] as Map? ?? {}),
      favorites: List<String>.from(json['favorites'] as List? ?? []),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      aiCredits: json['aiCredits'] as int? ?? 20,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  UserSyncData copyWith({
    String? oderId,
    Map<String, dynamic>? examProgress,
    List<String>? favorites,
    Map<String, dynamic>? settings,
    int? aiCredits,
    DateTime? lastModified,
    int? schemaVersion,
  }) {
    return UserSyncData(
      oderId: oderId ?? this.oderId,
      examProgress: examProgress ?? this.examProgress,
      favorites: favorites ?? this.favorites,
      settings: settings ?? this.settings,
      aiCredits: aiCredits ?? this.aiCredits,
      lastModified: lastModified ?? this.lastModified,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  List<Object?> get props => [
        oderId,
        examProgress,
        favorites,
        settings,
        aiCredits,
        lastModified,
        schemaVersion,
      ];
}
