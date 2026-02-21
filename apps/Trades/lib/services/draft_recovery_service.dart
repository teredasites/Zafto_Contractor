import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// DraftRecoveryService — DEPTH27
//
// 4-Layer persistence for Flutter:
//   Layer 1: In-memory (caller holds state)
//   Layer 2: Hive local (this service)
//   Layer 3: Supabase cloud (periodic sync)
//   Layer 4: Snapshot archive (deferred)
//
// Usage:
//   final svc = DraftRecoveryService();
//   await svc.saveDraft('bid', 'new', '/bids/new', {'title': 'Roof repair'});
//   final draft = await svc.loadDraft('bid', 'new');
//   if (draft != null) { /* restore state */ }
// ============================================================

class DraftRecord {
  final String feature;
  final String key;
  final String screenRoute;
  final Map<String, dynamic> stateJson;
  final int version;
  final String checksum;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  DraftRecord({
    required this.feature,
    required this.key,
    required this.screenRoute,
    required this.stateJson,
    required this.version,
    required this.checksum,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'feature': feature,
        'key': key,
        'screen_route': screenRoute,
        'state_json': stateJson,
        'version': version,
        'checksum': checksum,
        'is_pinned': isPinned,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DraftRecord.fromJson(Map<String, dynamic> json) {
    return DraftRecord(
      feature: json['feature'] as String? ?? '',
      key: json['key'] as String? ?? '',
      screenRoute: json['screen_route'] as String? ?? '',
      stateJson: json['state_json'] as Map<String, dynamic>? ?? {},
      version: json['version'] as int? ?? 1,
      checksum: json['checksum'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get compositeKey => '$feature::$key';
}

class DraftRecoveryService {
  static const String _boxName = 'draft_recovery';
  static const String _walBoxName = 'draft_recovery_wal';
  static const int _maxVersions = 5;
  static const int _maxStorageBytes = 50 * 1024 * 1024; // 50MB
  static const Duration _staleDuration = Duration(days: 30);

  Timer? _cloudSyncTimer;
  final Set<String> _dirtyKeys = {};

  /// Hive boxes — opened in main.dart before app starts
  Box<String> get _box => Hive.box<String>(_boxName);
  Box<String> get _walBox => Hive.box<String>(_walBoxName);

  /// Compute SHA-256 checksum of state JSON
  String _computeChecksum(Map<String, dynamic> state) {
    final bytes = utf8.encode(jsonEncode(state));
    return sha256.convert(bytes).toString();
  }

  /// Save a draft to Hive (Layer 2)
  Future<void> saveDraft(
    String feature,
    String key,
    String screenRoute,
    Map<String, dynamic> state,
  ) async {
    final box = _box;

    final compositeKey = '$feature::$key';
    final checksum = _computeChecksum(state);

    // Check if state actually changed (skip if identical)
    final existing = _loadFromBox(compositeKey);
    if (existing != null && existing.checksum == checksum) return;

    // Quota check — evict stale if over limit
    if (getStorageBytes() > _maxStorageBytes) {
      await evictStaleDrafts();
    }

    final now = DateTime.now();
    final record = DraftRecord(
      feature: feature,
      key: key,
      screenRoute: screenRoute,
      stateJson: state,
      version: (existing?.version ?? 0) + 1,
      checksum: checksum,
      isPinned: existing?.isPinned ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    // WAL: write intent first
    final walEntry = {
      'action': 'save',
      'key': compositeKey,
      'timestamp': now.toIso8601String(),
    };
    _walBox.put('wal_${now.millisecondsSinceEpoch}', jsonEncode(walEntry));

    // Save current version
    await box.put(compositeKey, jsonEncode(record.toJson()));

    // Save to version history (keep last N)
    await _saveVersion(compositeKey, record);

    // Clear WAL entry
    await _walBox.delete('wal_${now.millisecondsSinceEpoch}');

    // Mark dirty for cloud sync
    _dirtyKeys.add(compositeKey);
  }

  /// Load a draft from Hive
  Future<DraftRecord?> loadDraft(String feature, String key) async {
    final compositeKey = '$feature::$key';
    final record = _loadFromBox(compositeKey);
    if (record == null) return null;

    // Validate checksum
    final actualChecksum = _computeChecksum(record.stateJson);
    if (actualChecksum != record.checksum) {
      // Corrupted — try previous version
      final prev = await _loadPreviousVersion(compositeKey);
      if (prev != null) return prev;
      // All versions corrupt — delete
      await deleteDraft(feature, key);
      return null;
    }
    return record;
  }

  /// List all active drafts
  List<DraftRecord> listDrafts({String? feature}) {
    final box = _box;

    final results = <DraftRecord>[];
    for (final key in box.keys) {
      final k = key as String;
      if (k.startsWith('version_')) continue; // skip version history
      final record = _loadFromBox(k);
      if (record == null) continue;
      if (feature != null && record.feature != feature) continue;
      results.add(record);
    }
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  /// Delete a draft from Hive
  Future<void> deleteDraft(String feature, String key) async {
    final compositeKey = '$feature::$key';
    await _box.delete(compositeKey);
    // Also clear version history
    final versionKeys = _box.keys
            .where((k) => (k as String).startsWith('version_$compositeKey::'))
            .toList();
    for (final vk in versionKeys) {
      await _box.delete(vk);
    }
    _dirtyKeys.remove(compositeKey);
  }

  /// Pin/unpin a draft (pinned = never auto-expires, always syncs)
  Future<void> togglePin(String feature, String key) async {
    final compositeKey = '$feature::$key';
    final record = _loadFromBox(compositeKey);
    if (record == null) return;

    final updated = DraftRecord(
      feature: record.feature,
      key: record.key,
      screenRoute: record.screenRoute,
      stateJson: record.stateJson,
      version: record.version,
      checksum: record.checksum,
      isPinned: !record.isPinned,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
    await _box.put(compositeKey, jsonEncode(updated.toJson()));
  }

  /// Clear all drafts for the current user (on logout)
  Future<void> clearAllDrafts() async {
    await _box.clear();
    await _walBox.clear();
    _dirtyKeys.clear();
  }

  /// Start periodic cloud sync (call after login)
  void startCloudSync({Duration interval = const Duration(seconds: 60)}) {
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(interval, (_) => syncToCloud());
  }

  /// Stop cloud sync (call before logout or app pause)
  void stopCloudSync() {
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = null;
  }

  /// Sync dirty drafts to Supabase cloud (Layer 3)
  Future<void> syncToCloud() async {
    if (_dirtyKeys.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) return;

      final userId = session.user.id;
      final companyId =
          session.user.appMetadata['company_id'] as String? ?? '';
      if (companyId.isEmpty) return;

      final keysToSync = List<String>.from(_dirtyKeys);
      for (final compositeKey in keysToSync) {
        final record = _loadFromBox(compositeKey);
        if (record == null) {
          _dirtyKeys.remove(compositeKey);
          continue;
        }

        final stateBytes =
            utf8.encode(jsonEncode(record.stateJson)).length;

        await supabase.from('draft_recovery').upsert(
          {
            'company_id': companyId,
            'user_id': userId,
            'feature': record.feature,
            'screen_route': record.screenRoute,
            'state_json': record.stateJson,
            'state_size_bytes': stateBytes,
            'device_type': 'mobile',
            'version': record.version,
            'is_active': true,
            'is_pinned': record.isPinned,
            'checksum': record.checksum,
          },
          onConflict: 'user_id,feature,screen_route',
        );

        _dirtyKeys.remove(compositeKey);
      }
    } catch (_) {
      // Cloud sync failed — will retry next interval
    }
  }

  /// Force immediate cloud sync of all dirty drafts
  Future<void> forceSyncToCloud() async {
    await syncToCloud();
  }

  /// Check for cloud drafts newer than local (cross-device recovery)
  Future<List<DraftRecord>> checkCloudDrafts() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) return [];

      final userId = session.user.id;
      final data = await supabase
          .from('draft_recovery')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false)
          .limit(20);

      final cloudDrafts = <DraftRecord>[];
      for (final row in data) {
        final feature = row['feature'] as String? ?? '';
        final screenRoute = row['screen_route'] as String? ?? '';
        final key = screenRoute; // Use screen_route as key for cloud
        final cloudUpdated =
            DateTime.tryParse(row['updated_at'] as String? ?? '');
        if (cloudUpdated == null) continue;

        // Compare with local
        final compositeKey = '$feature::$key';
        final local = _loadFromBox(compositeKey);

        if (local == null || cloudUpdated.isAfter(local.updatedAt)) {
          cloudDrafts.add(DraftRecord(
            feature: feature,
            key: key,
            screenRoute: screenRoute,
            stateJson: row['state_json'] as Map<String, dynamic>? ?? {},
            version: row['version'] as int? ?? 1,
            checksum: row['checksum'] as String? ?? '',
            isPinned: row['is_pinned'] as bool? ?? false,
            createdAt:
                DateTime.tryParse(row['created_at'] as String? ?? '') ??
                    DateTime.now(),
            updatedAt: cloudUpdated,
          ));
        }
      }
      return cloudDrafts;
    } catch (_) {
      return [];
    }
  }

  /// Evict stale drafts (older than 30 days, not pinned)
  Future<void> evictStaleDrafts() async {
    final box = _box;

    final now = DateTime.now();
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      final k = key as String;
      if (k.startsWith('version_')) continue;
      final record = _loadFromBox(k);
      if (record == null || record.isPinned) continue;

      if (now.difference(record.updatedAt) > _staleDuration) {
        keysToDelete.add(k);
      }
    }

    for (final k in keysToDelete) {
      await box.delete(k);
    }
  }

  /// Get total storage used by drafts
  int getStorageBytes() {
    final box = _box;

    int total = 0;
    for (final key in box.keys) {
      final raw = box.get(key as String);
      if (raw != null) total += utf8.encode(raw).length;
    }
    return total;
  }

  // ── Private helpers ──

  DraftRecord? _loadFromBox(String compositeKey) {
    final raw = _box.get(compositeKey);
    if (raw == null) return null;
    try {
      return DraftRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveVersion(String compositeKey, DraftRecord record) async {
    final versionKey =
        'version_$compositeKey::${record.version}';
    await _box.put(versionKey, jsonEncode(record.toJson()));

    // Prune old versions
    final allVersionKeys = _box.keys
            .where((k) =>
                (k as String).startsWith('version_$compositeKey::'))
            .cast<String>()
            .toList();
    if (allVersionKeys.length > _maxVersions) {
      // Sort by version number, remove oldest
      allVersionKeys.sort();
      for (int i = 0; i < allVersionKeys.length - _maxVersions; i++) {
        await _box.delete(allVersionKeys[i]);
      }
    }
  }

  Future<DraftRecord?> _loadPreviousVersion(String compositeKey) async {
    final allVersionKeys = _box.keys
            .where((k) =>
                (k as String).startsWith('version_$compositeKey::'))
            .cast<String>()
            .toList();
    if (allVersionKeys.isEmpty) return null;

    allVersionKeys.sort();
    // Try versions from newest to oldest
    for (int i = allVersionKeys.length - 1; i >= 0; i--) {
      final raw = _box.get(allVersionKeys[i]);
      if (raw == null) continue;
      try {
        final record = DraftRecord.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        final actualChecksum = _computeChecksum(record.stateJson);
        if (actualChecksum == record.checksum) return record;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Replay any incomplete WAL entries (call on app restart)
  Future<void> replayWAL() async {
    if (_walBox.isEmpty) return;

    // WAL entries are informational — they indicate a write was in progress
    // If the main box has the data, the WAL entry is stale and can be cleared
    final keysToDelete = _walBox.keys.toList();
    for (final key in keysToDelete) {
      await _walBox.delete(key);
    }
  }
}
