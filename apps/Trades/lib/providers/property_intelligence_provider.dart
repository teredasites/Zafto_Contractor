// ZAFTO Property Intelligence Provider
// Created: DEPTH28 — Property Recon Mega-Expansion
//
// Riverpod providers for property profiles, weather, permits, auto-scopes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property_intelligence.dart';
import '../repositories/property_intelligence_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final propertyIntelligenceRepoProvider =
    Provider<PropertyIntelligenceRepository>((ref) {
  return PropertyIntelligenceRepository();
});

// ════════════════════════════════════════════════════════════════
// PROPERTY PROFILE (.family by scan ID)
// ════════════════════════════════════════════════════════════════

final propertyProfileProvider =
    FutureProvider.autoDispose.family<PropertyProfile?, String>((ref, scanId) async {
  final repo = ref.read(propertyIntelligenceRepoProvider);
  return repo.getProfile(scanId);
});

// ════════════════════════════════════════════════════════════════
// WEATHER INTELLIGENCE (.family by scan ID)
// ════════════════════════════════════════════════════════════════

final weatherIntelligenceProvider =
    FutureProvider.autoDispose.family<WeatherIntelligence?, String>((ref, scanId) async {
  final repo = ref.read(propertyIntelligenceRepoProvider);
  return repo.getWeather(scanId);
});

// ════════════════════════════════════════════════════════════════
// PERMIT HISTORY (.family by scan ID)
// ════════════════════════════════════════════════════════════════

final permitHistoryProvider =
    FutureProvider.autoDispose.family<List<PermitRecord>, String>((ref, scanId) async {
  final repo = ref.read(propertyIntelligenceRepoProvider);
  return repo.getPermits(scanId);
});

// ════════════════════════════════════════════════════════════════
// TRADE AUTO-SCOPES (.family by scan ID)
// ════════════════════════════════════════════════════════════════

final tradeAutoScopeProvider =
    FutureProvider.autoDispose.family<List<TradeAutoScope>, String>((ref, scanId) async {
  final repo = ref.read(propertyIntelligenceRepoProvider);
  return repo.getScopes(scanId);
});

// ════════════════════════════════════════════════════════════════
// COMBINED INTELLIGENCE (all data for a scan)
// ════════════════════════════════════════════════════════════════

class PropertyIntelligenceState {
  final PropertyProfile? profile;
  final WeatherIntelligence? weather;
  final List<PermitRecord> permits;
  final List<TradeAutoScope> scopes;
  final bool loading;
  final String? error;

  const PropertyIntelligenceState({
    this.profile,
    this.weather,
    this.permits = const [],
    this.scopes = const [],
    this.loading = false,
    this.error,
  });

  bool get hasData => profile != null || weather != null || permits.isNotEmpty || scopes.isNotEmpty;
}

final propertyIntelligenceCombinedProvider = FutureProvider.autoDispose
    .family<PropertyIntelligenceState, String>((ref, scanId) async {
  final repo = ref.read(propertyIntelligenceRepoProvider);
  try {
    final results = await Future.wait([
      repo.getProfile(scanId),
      repo.getWeather(scanId),
      repo.getPermits(scanId),
      repo.getScopes(scanId),
    ]);

    return PropertyIntelligenceState(
      profile: results[0] as PropertyProfile?,
      weather: results[1] as WeatherIntelligence?,
      permits: results[2] as List<PermitRecord>,
      scopes: results[3] as List<TradeAutoScope>,
    );
  } catch (e) {
    return PropertyIntelligenceState(error: e.toString());
  }
});
