import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sync_status.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);
  return SyncService(firestoreService, authState);
});

/// Sync status provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncStatusNotifier(syncService);
});

/// Sync status notifier
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final SyncService _syncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncStatusNotifier(this._syncService) : super(const SyncStatus()) {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivityChange(results);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Check if any connectivity is available
    final hasConnection = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (!hasConnection) {
      state = state.copyWith(state: SyncState.offline);
    } else if (state.isOffline) {
      // Coming back online - trigger sync
      state = state.copyWith(state: SyncState.idle);
      syncNow();
    }
  }

  /// Trigger manual sync
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(state: SyncState.syncing, progress: 0.0);

    try {
      await _syncService.syncAll(
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = SyncStatus(
        state: SyncState.synced,
        lastSyncTime: DateTime.now(),
        pendingChanges: 0,
      );
    } catch (e) {
      state = SyncStatus(
        state: SyncState.error,
        errorMessage: e.toString(),
        pendingChanges: state.pendingChanges,
      );
    }
  }

  /// Queue a change for sync
  void queueChange(SyncDataType dataType, String operation, Map<String, dynamic> data) {
    _syncService.queueOperation(dataType, operation, data);
    state = state.copyWith(
      pendingChanges: state.pendingChanges + 1,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Core sync service - offline-first with background sync
class SyncService {
  final FirestoreService _firestoreService;
  final AuthState _authState;

  static const String _pendingOpsBoxName = 'pending_sync_ops';
  static const String _localDataBoxName = 'local_sync_data';
  static const int _maxRetries = 3;

  SyncService(this._firestoreService, this._authState);

  String? get _userId => _authState.user?.uid;

  // ==================== SYNC OPERATIONS ====================

  /// Sync all data with server
  Future<void> syncAll({Function(double)? onProgress}) async {
    if (_userId == null) return;

    // Step 1: Process pending operations (30%)
    onProgress?.call(0.1);
    await _processPendingOperations();
    onProgress?.call(0.3);

    // Step 2: Fetch server data (60%)
    final serverData = await _firestoreService.getUserData(_userId!);
    onProgress?.call(0.6);

    // Step 3: Merge with local data (80%)
    await _mergeData(serverData);
    onProgress?.call(0.8);

    // Step 4: Push merged data to server (100%)
    await _pushLocalData();
    onProgress?.call(1.0);
  }

  /// Queue an operation for later sync
  Future<void> queueOperation(
    SyncDataType dataType,
    String operation,
    Map<String, dynamic> data,
  ) async {
    final box = await Hive.openBox<String>(_pendingOpsBoxName);

    final op = PendingSyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataType: dataType,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    await box.put(op.id, jsonEncode(op.toJson()));
  }

  /// Process all pending operations
  Future<void> _processPendingOperations() async {
    if (_userId == null) return;

    final box = await Hive.openBox<String>(_pendingOpsBoxName);
    final keys = box.keys.toList();

    for (final key in keys) {
      final json = box.get(key);
      if (json == null) continue;

      try {
        final op = PendingSyncOperation.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );

        await _executeOperation(op);
        await box.delete(key);
      } catch (e) {
        // Increment retry count or remove if max retries exceeded
        final op = PendingSyncOperation.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );

        if (op.retryCount >= _maxRetries) {
          await box.delete(key);
        } else {
          final updated = op.copyWith(retryCount: op.retryCount + 1);
          await box.put(key, jsonEncode(updated.toJson()));
        }
      }
    }
  }

  /// Execute a single sync operation
  Future<void> _executeOperation(PendingSyncOperation op) async {
    if (_userId == null) return;

    switch (op.dataType) {
      case SyncDataType.examProgress:
        await _firestoreService.saveExamProgress(
          _userId!,
          op.data['topicId'] as String,
          op.data,
        );
        break;

      case SyncDataType.favorites:
        if (op.operation == 'create') {
          await _firestoreService.addFavorite(
            _userId!,
            op.data['screenId'] as String,
          );
        } else if (op.operation == 'delete') {
          await _firestoreService.removeFavorite(
            _userId!,
            op.data['screenId'] as String,
          );
        }
        break;

      case SyncDataType.calculationHistory:
        if (op.operation == 'create') {
          await _firestoreService.saveCalculation(_userId!, op.data);
        } else if (op.operation == 'delete') {
          await _firestoreService.deleteCalculation(
            _userId!,
            op.data['id'] as String,
          );
        }
        break;

      case SyncDataType.settings:
        await _firestoreService.saveSettings(_userId!, op.data);
        break;

      case SyncDataType.aiCredits:
        await _firestoreService.updateAiCredits(
          _userId!,
          op.data['credits'] as int,
        );
        break;

      case SyncDataType.jobDocuments:
        // Job documents are stored in Supabase storage + documents table.
        // This sync path is unused — documents sync directly via Supabase real-time.
        debugPrint('[SyncService] jobDocuments sync skipped — handled by Supabase directly');
        break;
    }
  }

  // ==================== LOCAL DATA ====================

  /// Get local data box
  Future<Box<String>> _getLocalDataBox() async {
    return Hive.openBox<String>(_localDataBoxName);
  }

  /// Save data locally
  Future<void> saveLocal(String key, Map<String, dynamic> data) async {
    final box = await _getLocalDataBox();
    await box.put(key, jsonEncode(data));
  }

  /// Get local data
  Future<Map<String, dynamic>?> getLocal(String key) async {
    final box = await _getLocalDataBox();
    final json = box.get(key);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Delete local data
  Future<void> deleteLocal(String key) async {
    final box = await _getLocalDataBox();
    await box.delete(key);
  }

  // ==================== MERGE LOGIC ====================

  /// Merge server data with local data (last-write-wins)
  Future<void> _mergeData(UserSyncData? serverData) async {
    final localDataBox = await _getLocalDataBox();
    final localJson = localDataBox.get('userData');

    if (serverData == null && localJson == null) return;

    UserSyncData local;
    if (localJson != null) {
      local = UserSyncData.fromJson(
        jsonDecode(localJson) as Map<String, dynamic>,
      );
    } else {
      local = UserSyncData(
        oderId: _userId!,
        lastModified: DateTime.now(),
      );
    }

    // If no server data, keep local
    if (serverData == null) return;

    // Last-write-wins merge
    final merged = serverData.lastModified.isAfter(local.lastModified)
        ? serverData
        : local;

    // Save merged data locally
    await localDataBox.put('userData', jsonEncode(merged.toJson()));
  }

  /// Push local data to server
  Future<void> _pushLocalData() async {
    if (_userId == null) return;

    final localDataBox = await _getLocalDataBox();
    final localJson = localDataBox.get('userData');

    if (localJson == null) return;

    final local = UserSyncData.fromJson(
      jsonDecode(localJson) as Map<String, dynamic>,
    );

    await _firestoreService.syncAllData(_userId!, local);
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Save exam progress (local + queue sync)
  Future<void> saveExamProgress(String topicId, Map<String, dynamic> progress) async {
    // Save locally first
    await saveLocal('examProgress_$topicId', progress);

    // Queue for server sync
    await queueOperation(
      SyncDataType.examProgress,
      'update',
      {'topicId': topicId, ...progress},
    );
  }

  /// Add favorite (local + queue sync)
  Future<void> addFavorite(String screenId) async {
    final box = await _getLocalDataBox();
    final favoritesJson = box.get('favorites');
    final favorites = favoritesJson != null
        ? List<String>.from(jsonDecode(favoritesJson) as List)
        : <String>[];

    if (!favorites.contains(screenId)) {
      favorites.add(screenId);
      await box.put('favorites', jsonEncode(favorites));
    }

    await queueOperation(
      SyncDataType.favorites,
      'create',
      {'screenId': screenId},
    );
  }

  /// Remove favorite (local + queue sync)
  Future<void> removeFavorite(String screenId) async {
    final box = await _getLocalDataBox();
    final favoritesJson = box.get('favorites');

    if (favoritesJson != null) {
      final favorites = List<String>.from(jsonDecode(favoritesJson) as List);
      favorites.remove(screenId);
      await box.put('favorites', jsonEncode(favorites));
    }

    await queueOperation(
      SyncDataType.favorites,
      'delete',
      {'screenId': screenId},
    );
  }

  /// Get favorites (local)
  Future<List<String>> getFavorites() async {
    final box = await _getLocalDataBox();
    final favoritesJson = box.get('favorites');
    if (favoritesJson == null) return [];
    return List<String>.from(jsonDecode(favoritesJson) as List);
  }

  /// Save settings (local + queue sync)
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await saveLocal('settings', settings);
    await queueOperation(SyncDataType.settings, 'update', settings);
  }

  /// Get settings (local)
  Future<Map<String, dynamic>> getSettings() async {
    return await getLocal('settings') ?? {};
  }

  /// Get pending operations count
  Future<int> getPendingCount() async {
    final box = await Hive.openBox<String>(_pendingOpsBoxName);
    return box.length;
  }

  /// Clear all local data (for logout)
  Future<void> clearLocalData() async {
    final localBox = await _getLocalDataBox();
    final pendingBox = await Hive.openBox<String>(_pendingOpsBoxName);

    await localBox.clear();
    await pendingBox.clear();
  }
}
