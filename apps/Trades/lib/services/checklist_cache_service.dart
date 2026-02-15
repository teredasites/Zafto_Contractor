import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:zafto/models/inspection.dart';

// ============================================================
// Checklist Cache Service
//
// Hive-backed local storage for Quick Checklists. Every
// checklist is saved to Hive FIRST (instant, offline-safe),
// then synced to Supabase when connectivity allows.
//
// Box layout:
//   'checklists'           — JSON-encoded checklist snapshots keyed by ID
//   'checklist_sync_meta'  — sync tracking (synced: bool, timestamp)
// ============================================================

/// Cached checklist snapshot — inspection + items serialized together.
class CachedChecklist {
  final PmInspection inspection;
  final List<PmInspectionItem> items;
  final DateTime cachedAt;
  final bool synced;

  const CachedChecklist({
    required this.inspection,
    required this.items,
    required this.cachedAt,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'inspection': inspection.toInsertJson()
          ..['id'] = inspection.id
          ..['created_at'] = inspection.createdAt.toIso8601String()
          ..['updated_at'] = inspection.updatedAt.toIso8601String(),
        'items': items.map((i) => i.toInsertJson()..['id'] = i.id).toList(),
        'cached_at': cachedAt.toIso8601String(),
        'synced': synced,
      };

  factory CachedChecklist.fromJson(Map<String, dynamic> json) {
    return CachedChecklist(
      inspection: PmInspection.fromJson(
        json['inspection'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>)
          .map((i) => PmInspectionItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }
}

class ChecklistCacheService {
  static const _boxName = 'checklists';
  static const _metaBoxName = 'checklist_sync_meta';

  Box<String> get _box => Hive.box<String>(_boxName);
  Box<String> get _metaBox => Hive.box<String>(_metaBoxName);

  // ---- Write ----

  /// Save a checklist to Hive. Call this on every check/uncheck for
  /// instant local persistence.
  Future<void> cacheChecklist(
    PmInspection inspection,
    List<PmInspectionItem> items, {
    bool synced = false,
  }) async {
    final cached = CachedChecklist(
      inspection: inspection,
      items: items,
      cachedAt: DateTime.now(),
      synced: synced,
    );
    await _box.put(inspection.id, jsonEncode(cached.toJson()));
    await _metaBox.put(
      inspection.id,
      jsonEncode({
        'synced': synced,
        'cached_at': cached.cachedAt.toIso8601String(),
      }),
    );
  }

  // ---- Read ----

  /// Get a single cached checklist by ID.
  CachedChecklist? getCachedChecklist(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return CachedChecklist.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all cached checklists, newest first.
  List<CachedChecklist> getAllCachedChecklists() {
    final results = <CachedChecklist>[];
    for (final key in _box.keys) {
      final cached = getCachedChecklist(key as String);
      if (cached != null) results.add(cached);
    }
    results.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
    return results;
  }

  /// Get checklists that haven't been synced to Supabase yet.
  List<CachedChecklist> getPendingSyncChecklists() {
    return getAllCachedChecklists().where((c) => !c.synced).toList();
  }

  // ---- Sync tracking ----

  /// Mark a checklist as synced to Supabase.
  Future<void> markSynced(String id) async {
    final cached = getCachedChecklist(id);
    if (cached == null) return;
    await cacheChecklist(cached.inspection, cached.items, synced: true);
  }

  /// Check if currently online.
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ---- Delete ----

  /// Remove a checklist from local cache.
  Future<void> deleteCachedChecklist(String id) async {
    await _box.delete(id);
    await _metaBox.delete(id);
  }

  /// Clear all cached checklists.
  Future<void> clearAll() async {
    await _box.clear();
    await _metaBox.clear();
  }

  // ---- Stats ----

  int get totalCached => _box.length;
  int get pendingSync => getPendingSyncChecklists().length;
}

// ---- Riverpod Providers ----

final checklistCacheServiceProvider = Provider<ChecklistCacheService>(
  (ref) => ChecklistCacheService(),
);

final cachedChecklistsProvider = Provider<List<CachedChecklist>>(
  (ref) => ref.watch(checklistCacheServiceProvider).getAllCachedChecklists(),
);

final pendingSyncChecklistsProvider = Provider<List<CachedChecklist>>(
  (ref) =>
      ref.watch(checklistCacheServiceProvider).getPendingSyncChecklists(),
);
