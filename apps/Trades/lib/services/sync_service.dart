import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_status.dart';
import 'auth_service.dart';

/// Sync service provider (S151: Firebase removed, uses Supabase)
final syncServiceProvider = Provider<SyncService>((ref) {
  final authState = ref.watch(authStateProvider);
  return SyncService(authState);
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
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivityChange(results);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (!hasConnection) {
      state = state.copyWith(state: SyncState.offline);
    } else if (state.isOffline) {
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

/// Core sync service - offline-first with background sync via Supabase
class SyncService {
  final AuthState _authState;

  static const String _pendingOpsBoxName = 'pending_sync_ops';
  static const String _localDataBoxName = 'local_sync_data';
  static const int _maxRetries = 3;

  SyncService(this._authState);

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _userId => _authState.user?.uid;

  // ==================== SYNC OPERATIONS ====================

  /// Sync all data with server
  Future<void> syncAll({Function(double)? onProgress}) async {
    if (_userId == null) return;

    // Step 1: Process pending operations (50%)
    onProgress?.call(0.1);
    await _processPendingOperations();
    onProgress?.call(0.5);

    // Step 2: Supabase handles real-time sync natively
    // No need to pull/merge/push like Firestore required
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

  /// Execute a single sync operation via Supabase
  Future<void> _executeOperation(PendingSyncOperation op) async {
    if (_userId == null) return;

    switch (op.dataType) {
      case SyncDataType.examProgress:
        await _supabase.from('exam_progress').upsert({
          'user_id': _userId,
          'topic_id': op.data['topicId'],
          ...op.data,
          'updated_at': DateTime.now().toIso8601String(),
        });
        break;

      case SyncDataType.favorites:
        if (op.operation == 'create') {
          await _supabase.from('favorites').insert({
            'user_id': _userId,
            'screen_id': op.data['screenId'],
            'created_at': DateTime.now().toIso8601String(),
          });
        } else if (op.operation == 'delete') {
          await _supabase.from('favorites')
              .delete()
              .eq('user_id', _userId!)
              .eq('screen_id', op.data['screenId']);
        }
        break;

      case SyncDataType.calculationHistory:
        if (op.operation == 'create') {
          await _supabase.from('calculation_history').insert({
            'user_id': _userId,
            ...op.data,
            'created_at': DateTime.now().toIso8601String(),
          });
        } else if (op.operation == 'delete') {
          await _supabase.from('calculation_history')
              .delete()
              .eq('id', op.data['id']);
        }
        break;

      case SyncDataType.settings:
        await _supabase.from('user_settings').upsert({
          'user_id': _userId,
          'settings': op.data,
          'updated_at': DateTime.now().toIso8601String(),
        });
        break;

      case SyncDataType.aiCredits:
        await _supabase.from('users').update({
          'ai_credits': op.data['credits'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _userId!);
        break;

      case SyncDataType.jobDocuments:
        debugPrint('[SyncService] jobDocuments sync handled by Supabase directly');
        break;
    }
  }

  // ==================== LOCAL DATA ====================

  Future<Box<String>> _getLocalDataBox() async {
    return Hive.openBox<String>(_localDataBoxName);
  }

  Future<void> saveLocal(String key, Map<String, dynamic> data) async {
    final box = await _getLocalDataBox();
    await box.put(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getLocal(String key) async {
    final box = await _getLocalDataBox();
    final json = box.get(key);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> deleteLocal(String key) async {
    final box = await _getLocalDataBox();
    await box.delete(key);
  }

  // ==================== CONVENIENCE METHODS ====================

  Future<void> saveExamProgress(String topicId, Map<String, dynamic> progress) async {
    await saveLocal('examProgress_$topicId', progress);
    await queueOperation(
      SyncDataType.examProgress,
      'update',
      {'topicId': topicId, ...progress},
    );
  }

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

    await queueOperation(SyncDataType.favorites, 'create', {'screenId': screenId});
  }

  Future<void> removeFavorite(String screenId) async {
    final box = await _getLocalDataBox();
    final favoritesJson = box.get('favorites');

    if (favoritesJson != null) {
      final favorites = List<String>.from(jsonDecode(favoritesJson) as List);
      favorites.remove(screenId);
      await box.put('favorites', jsonEncode(favorites));
    }

    await queueOperation(SyncDataType.favorites, 'delete', {'screenId': screenId});
  }

  Future<List<String>> getFavorites() async {
    final box = await _getLocalDataBox();
    final favoritesJson = box.get('favorites');
    if (favoritesJson == null) return [];
    return List<String>.from(jsonDecode(favoritesJson) as List);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await saveLocal('settings', settings);
    await queueOperation(SyncDataType.settings, 'update', settings);
  }

  Future<Map<String, dynamic>> getSettings() async {
    return await getLocal('settings') ?? {};
  }

  Future<int> getPendingCount() async {
    final box = await Hive.openBox<String>(_pendingOpsBoxName);
    return box.length;
  }

  Future<void> clearLocalData() async {
    final localBox = await _getLocalDataBox();
    final pendingBox = await Hive.openBox<String>(_pendingOpsBoxName);
    await localBox.clear();
    await pendingBox.clear();
  }
}
