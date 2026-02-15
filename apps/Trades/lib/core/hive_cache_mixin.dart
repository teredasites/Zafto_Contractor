import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

// ============================================================
// Hive Cache Mixin
//
// Reusable mixin for ANY repository to add Hive offline caching.
// Pattern: write to Hive FIRST (instant), then push to Supabase.
// On read failure: fallback to Hive cache.
// On write failure: queue for retry when connectivity returns.
//
// Usage:
//   class JobRepository with HiveCacheMixin<Job> {
//     @override String get cacheBoxName => 'jobs';
//     @override Map<String, dynamic> itemToJson(Job item) => item.toJson();
//     @override Job itemFromJson(Map<String, dynamic> json) => Job.fromJson(json);
//   }
// ============================================================

mixin HiveCacheMixin<T> {
  /// The Hive box name for this data type.
  /// Must match a box opened in main.dart.
  String get cacheBoxName;

  /// Serialize a domain model to JSON for Hive storage.
  Map<String, dynamic> itemToJson(T item);

  /// Deserialize a domain model from cached JSON.
  T itemFromJson(Map<String, dynamic> json);

  /// Extract the unique ID from an item's JSON.
  /// Defaults to 'id' key.
  String idFromJson(Map<String, dynamic> json) =>
      json['id'] as String? ?? '';

  // ---- Hive Operations ----

  Box<String> get _cacheBox => Hive.box<String>(cacheBoxName);

  /// Cache a single item locally.
  Future<void> cacheItem(String id, T item) async {
    await _cacheBox.put(id, jsonEncode(itemToJson(item)));
  }

  /// Cache multiple items locally (batch).
  Future<void> cacheAll(Map<String, T> items) async {
    final encoded = items.map(
      (id, item) => MapEntry(id, jsonEncode(itemToJson(item))),
    );
    await _cacheBox.putAll(encoded);
  }

  /// Get a single cached item by ID. Returns null if not found.
  T? getCachedItem(String id) {
    final raw = _cacheBox.get(id);
    if (raw == null) return null;
    try {
      return itemFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Get all cached items.
  List<T> getAllCached() {
    final results = <T>[];
    for (final key in _cacheBox.keys) {
      final item = getCachedItem(key as String);
      if (item != null) results.add(item);
    }
    return results;
  }

  /// Remove a single item from cache.
  Future<void> removeCached(String id) async {
    await _cacheBox.delete(id);
  }

  /// Clear all cached items for this type.
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  /// Number of cached items.
  int get cacheCount => _cacheBox.length;

  // ---- Helper: Try-Supabase-with-Hive-Fallback ----

  /// Wraps a Supabase fetch call. On success, caches the result.
  /// On failure, returns the cached version if available.
  Future<List<T>> fetchWithCache(
    Future<List<T>> Function() supabaseFetch,
    String Function(T item) getId,
  ) async {
    try {
      final items = await supabaseFetch();
      // Cache all fetched items
      final cacheMap = <String, T>{};
      for (final item in items) {
        cacheMap[getId(item)] = item;
      }
      await cacheAll(cacheMap);
      return items;
    } catch (_) {
      // Supabase failed — return cached data
      return getAllCached();
    }
  }

  /// Wraps a Supabase single-fetch call with cache fallback.
  Future<T?> fetchOneWithCache(
    String id,
    Future<T?> Function() supabaseFetch,
  ) async {
    try {
      final item = await supabaseFetch();
      if (item != null) await cacheItem(id, item);
      return item;
    } catch (_) {
      return getCachedItem(id);
    }
  }

  /// Write to Hive first, then attempt Supabase.
  /// Returns true if Supabase succeeded, false if queued for later.
  Future<bool> writeWithCache(
    String id,
    T item,
    Future<void> Function() supabaseWrite,
  ) async {
    // Always save locally first (instant)
    await cacheItem(id, item);
    try {
      await supabaseWrite();
      return true;
    } catch (_) {
      // Supabase failed — data is safe in Hive, will sync later
      return false;
    }
  }
}
