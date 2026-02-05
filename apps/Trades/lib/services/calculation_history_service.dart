import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/saved_calculation.dart';
import '../models/sync_status.dart';
import 'sync_service.dart';

/// Calculation history service provider
final calculationHistoryServiceProvider = Provider<CalculationHistoryService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return CalculationHistoryService(syncService);
});

/// Calculation history state provider
final calculationHistoryProvider =
    StateNotifierProvider<CalculationHistoryNotifier, List<SavedCalculation>>((ref) {
  final service = ref.watch(calculationHistoryServiceProvider);
  return CalculationHistoryNotifier(service);
});

/// Recent calculations provider (last 5)
final recentCalculationsProvider = Provider<List<SavedCalculation>>((ref) {
  final history = ref.watch(calculationHistoryProvider);
  return history.take(5).toList();
});

/// Favorite calculations provider
final favoriteCalculationsProvider = Provider<List<SavedCalculation>>((ref) {
  final history = ref.watch(calculationHistoryProvider);
  return history.where((c) => c.isFavorite).toList();
});

/// Calculations by type provider
final calculationsByTypeProvider =
    Provider.family<List<SavedCalculation>, CalculatorType>((ref, type) {
  final history = ref.watch(calculationHistoryProvider);
  return history.where((c) => c.calculatorType == type).toList();
});

/// Calculations by job provider
final calculationsByJobProvider =
    Provider.family<List<SavedCalculation>, String>((ref, jobId) {
  final history = ref.watch(calculationHistoryProvider);
  return history.where((c) => c.jobId == jobId).toList();
});

/// Calculation history state notifier
class CalculationHistoryNotifier extends StateNotifier<List<SavedCalculation>> {
  final CalculationHistoryService _service;
  bool _initialized = false;

  CalculationHistoryNotifier(this._service) : super([]) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    state = await _service.getAllCalculations();
  }

  /// Save a new calculation
  Future<SavedCalculation> save(SavedCalculation calculation) async {
    final saved = await _service.saveCalculation(calculation);
    state = [saved, ...state];
    return saved;
  }

  /// Update an existing calculation
  Future<void> update(SavedCalculation calculation) async {
    await _service.updateCalculation(calculation);
    state = state.map((c) => c.id == calculation.id ? calculation : c).toList();
  }

  /// Delete a calculation
  Future<void> delete(String id) async {
    await _service.deleteCalculation(id);
    state = state.where((c) => c.id != id).toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final calculation = state.firstWhere((c) => c.id == id);
    final updated = calculation.copyWith(isFavorite: !calculation.isFavorite);
    await _service.updateCalculation(updated);
    state = state.map((c) => c.id == id ? updated : c).toList();
  }

  /// Clear all history
  Future<void> clearAll() async {
    await _service.clearAllCalculations();
    state = [];
  }

  /// Refresh from storage
  Future<void> refresh() async {
    state = await _service.getAllCalculations();
  }
}

/// Core calculation history service with Hive persistence
class CalculationHistoryService {
  static const String _boxName = 'calculation_history';
  static const int _maxCalculations = 100;

  final SyncService _syncService;

  CalculationHistoryService(this._syncService);

  /// Get Hive box
  Future<Box<SavedCalculation>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<SavedCalculation>(_boxName);
    }
    return Hive.box<SavedCalculation>(_boxName);
  }

  /// Save a calculation
  Future<SavedCalculation> saveCalculation(SavedCalculation calculation) async {
    final box = await _getBox();

    // Enforce max limit - remove oldest if at capacity
    if (box.length >= _maxCalculations) {
      final oldest = box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Remove oldest non-favorite calculations
      for (final calc in oldest) {
        if (!calc.isFavorite && box.length >= _maxCalculations) {
          await box.delete(calc.id);
        }
      }
    }

    await box.put(calculation.id, calculation);

    // Queue for cloud sync
    _syncService.queueOperation(
      SyncDataType.calculationHistory,
      'create',
      calculation.toJson(),
    );

    return calculation;
  }

  /// Update a calculation
  Future<void> updateCalculation(SavedCalculation calculation) async {
    final box = await _getBox();
    final updated = calculation.copyWith(updatedAt: DateTime.now());
    await box.put(calculation.id, updated);

    // Queue for cloud sync
    _syncService.queueOperation(
      SyncDataType.calculationHistory,
      'update',
      updated.toJson(),
    );
  }

  /// Delete a calculation
  Future<void> deleteCalculation(String id) async {
    final box = await _getBox();
    await box.delete(id);

    // Queue for cloud sync
    _syncService.queueOperation(
      SyncDataType.calculationHistory,
      'delete',
      {'id': id},
    );
  }

  /// Get all calculations (sorted by date, newest first)
  Future<List<SavedCalculation>> getAllCalculations() async {
    final box = await _getBox();
    final calculations = box.values.toList();
    calculations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return calculations;
  }

  /// Get calculation by ID
  Future<SavedCalculation?> getCalculation(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  /// Get calculations by type
  Future<List<SavedCalculation>> getByType(CalculatorType type) async {
    final all = await getAllCalculations();
    return all.where((c) => c.calculatorType == type).toList();
  }

  /// Get calculations by job
  Future<List<SavedCalculation>> getByJob(String jobId) async {
    final all = await getAllCalculations();
    return all.where((c) => c.jobId == jobId).toList();
  }

  /// Get favorite calculations
  Future<List<SavedCalculation>> getFavorites() async {
    final all = await getAllCalculations();
    return all.where((c) => c.isFavorite).toList();
  }

  /// Get recent calculations
  Future<List<SavedCalculation>> getRecent({int limit = 10}) async {
    final all = await getAllCalculations();
    return all.take(limit).toList();
  }

  /// Search calculations
  Future<List<SavedCalculation>> search(String query) async {
    final all = await getAllCalculations();
    final lowerQuery = query.toLowerCase();

    return all.where((calc) {
      // Search in name
      if (calc.name?.toLowerCase().contains(lowerQuery) ?? false) return true;

      // Search in notes
      if (calc.notes?.toLowerCase().contains(lowerQuery) ?? false) return true;

      // Search in job address
      if (calc.jobAddress?.toLowerCase().contains(lowerQuery) ?? false) return true;

      // Search in calculator type
      if (calc.calculatorType.displayName.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search in tags
      if (calc.tags.any((t) => t.toLowerCase().contains(lowerQuery))) return true;

      return false;
    }).toList();
  }

  /// Clear all calculations
  Future<void> clearAllCalculations() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Get statistics
  Future<CalculationStats> getStats() async {
    final all = await getAllCalculations();

    // Count by type
    final byType = <CalculatorType, int>{};
    for (final calc in all) {
      byType[calc.calculatorType] = (byType[calc.calculatorType] ?? 0) + 1;
    }

    // Find most used
    CalculatorType? mostUsed;
    int mostUsedCount = 0;
    for (final entry in byType.entries) {
      if (entry.value > mostUsedCount) {
        mostUsedCount = entry.value;
        mostUsed = entry.key;
      }
    }

    return CalculationStats(
      totalCount: all.length,
      favoriteCount: all.where((c) => c.isFavorite).length,
      byType: byType,
      mostUsedType: mostUsed,
      oldestCalculation: all.isNotEmpty ? all.last.createdAt : null,
      newestCalculation: all.isNotEmpty ? all.first.createdAt : null,
    );
  }

  /// Export all calculations as JSON
  Future<List<Map<String, dynamic>>> exportAll() async {
    final all = await getAllCalculations();
    return all.map((c) => c.toJson()).toList();
  }

  /// Import calculations from JSON
  Future<int> importAll(List<Map<String, dynamic>> data) async {
    final box = await _getBox();
    int imported = 0;

    for (final json in data) {
      try {
        final calc = SavedCalculation.fromJson(json);
        // Don't overwrite existing
        if (!box.containsKey(calc.id)) {
          await box.put(calc.id, calc);
          imported++;
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    return imported;
  }
}

/// Statistics about calculation history
class CalculationStats {
  final int totalCount;
  final int favoriteCount;
  final Map<CalculatorType, int> byType;
  final CalculatorType? mostUsedType;
  final DateTime? oldestCalculation;
  final DateTime? newestCalculation;

  const CalculationStats({
    required this.totalCount,
    required this.favoriteCount,
    required this.byType,
    this.mostUsedType,
    this.oldestCalculation,
    this.newestCalculation,
  });
}

/// Register Hive adapters for calculation history
Future<void> registerCalculationHistoryAdapters() async {
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(CalculatorTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(SavedCalculationAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(MapAdapter());
  }
}
