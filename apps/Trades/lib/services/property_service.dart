// ZAFTO Property Service — Property Management
// Created: Property Management Feature
//
// Manages properties and units for the contractor-owned
// property portfolio. Wraps PropertyRepository with auth
// enrichment. Provides Riverpod providers for all PM screens.
//
// Providers: propertyRepositoryProvider, propertyServiceProvider,
//   propertiesProvider, unitsProvider, allUnitsProvider, propertyStatsProvider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../repositories/property_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository();
});

final propertyServiceProvider = Provider<PropertyService>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return PropertyService(repo, authState);
});

// Properties list (main portfolio)
final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>(
        (ref) {
  final service = ref.watch(propertyServiceProvider);
  return PropertiesNotifier(service);
});

// Units for a specific property
final unitsProvider = StateNotifierProvider.family<UnitsNotifier,
    AsyncValue<List<Unit>>, String?>((ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return UnitsNotifier(service, propertyId);
});

// All units (for dashboard stats)
final allUnitsProvider =
    StateNotifierProvider<AllUnitsNotifier, AsyncValue<List<Unit>>>((ref) {
  final service = ref.watch(propertyServiceProvider);
  return AllUnitsNotifier(service);
});

// Computed stats
final propertyStatsProvider = Provider<PropertyStats>((ref) {
  final properties = ref.watch(propertiesProvider);
  final units = ref.watch(allUnitsProvider);
  return properties.maybeWhen(
    data: (props) {
      final unitList =
          units.maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
      final occupied =
          unitList.where((u) => u.status == UnitStatus.occupied).length;
      return PropertyStats(
        totalProperties: props.length,
        totalUnits: unitList.length,
        vacantUnits:
            unitList.where((u) => u.status == UnitStatus.vacant).length,
        occupancyRate: unitList.isEmpty
            ? 0
            : (occupied / unitList.length * 100).round(),
      );
    },
    orElse: () => PropertyStats.empty(),
  );
});

// ============================================================
// STATS MODEL
// ============================================================

class PropertyStats {
  final int totalProperties;
  final int totalUnits;
  final int vacantUnits;
  final int occupancyRate;

  const PropertyStats({
    required this.totalProperties,
    required this.totalUnits,
    required this.vacantUnits,
    required this.occupancyRate,
  });

  factory PropertyStats.empty() => const PropertyStats(
        totalProperties: 0,
        totalUnits: 0,
        vacantUnits: 0,
        occupancyRate: 0,
      );
}

// ============================================================
// PROPERTY SERVICE (business logic)
// ============================================================

class PropertyService {
  final PropertyRepository _repo;
  final AuthState _authState;

  PropertyService(this._repo, this._authState);

  // Properties
  Future<List<Property>> getProperties() => _repo.getProperties();

  Future<Property?> getProperty(String id) => _repo.getProperty(id);

  Future<Property> createProperty(Property p) {
    final enriched = p.copyWith(
      companyId: _authState.companyId ?? '',
    );
    return _repo.createProperty(enriched);
  }

  Future<Property> updateProperty(String id, Property p) =>
      _repo.updateProperty(id, p);

  Future<void> deleteProperty(String id) => _repo.deleteProperty(id);

  // Units
  Future<List<Unit>> getUnits({String? propertyId}) =>
      _repo.getUnits(propertyId: propertyId);

  Future<Unit> createUnit(Unit u) => _repo.createUnit(u);

  Future<Unit> updateUnit(String id, Unit u) => _repo.updateUnit(id, u);

  Future<void> updateUnitStatus(String id, UnitStatus status) =>
      _repo.updateUnitStatus(id, status);

  Future<void> deleteUnit(String id) => _repo.deleteUnit(id);
}

// ============================================================
// PROPERTIES NOTIFIER
// ============================================================

class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final PropertyService _service;

  PropertiesNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final properties = await _service.getProperties();
      state = AsyncValue.data(properties);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Property property) async {
    try {
      await _service.createProperty(property);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(String id, Property property) async {
    try {
      await _service.updateProperty(id, property);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.deleteProperty(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============================================================
// UNITS NOTIFIER (scoped to a single property)
// ============================================================

class UnitsNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final PropertyService _service;
  final String? _propertyId;

  UnitsNotifier(this._service, this._propertyId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final units = await _service.getUnits(propertyId: _propertyId);
      state = AsyncValue.data(units);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Unit unit) async {
    try {
      await _service.createUnit(unit);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(String id, Unit unit) async {
    try {
      await _service.updateUnit(id, unit);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, UnitStatus status) async {
    try {
      await _service.updateUnitStatus(id, status);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.deleteUnit(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============================================================
// ALL UNITS NOTIFIER (dashboard aggregate)
// ============================================================

class AllUnitsNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final PropertyService _service;

  AllUnitsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final units = await _service.getUnits();
      state = AsyncValue.data(units);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
