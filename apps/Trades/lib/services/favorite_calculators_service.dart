import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages user's favorite calculators for quick access.
/// Stores calculator IDs in a local Hive box.
class FavoriteCalculatorsService {
  static const String _boxName = 'favorite_calculators';

  static Box get _box => Hive.box(_boxName);

  static Set<String> getFavorites() {
    final raw = _box.get('ids', defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw.cast<String>().toSet();
    }
    return <String>{};
  }

  static Future<void> toggle(String calculatorId) async {
    final favorites = getFavorites();
    if (favorites.contains(calculatorId)) {
      favorites.remove(calculatorId);
    } else {
      favorites.add(calculatorId);
    }
    await _box.put('ids', favorites.toList());
  }

  static bool isFavorite(String calculatorId) {
    return getFavorites().contains(calculatorId);
  }
}

/// Provider that exposes the set of favorite calculator IDs.
final favoriteCalculatorsProvider =
    StateNotifierProvider<FavoriteCalculatorsNotifier, Set<String>>((ref) {
  return FavoriteCalculatorsNotifier();
});

class FavoriteCalculatorsNotifier extends StateNotifier<Set<String>> {
  FavoriteCalculatorsNotifier()
      : super(FavoriteCalculatorsService.getFavorites());

  Future<void> toggle(String calculatorId) async {
    await FavoriteCalculatorsService.toggle(calculatorId);
    state = FavoriteCalculatorsService.getFavorites();
  }

  bool isFavorite(String calculatorId) => state.contains(calculatorId);
}
