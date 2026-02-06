// ZAFTO Mileage Service — Supabase Backend
// Providers, notifier, and service for mileage trip operations.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/mileage_trip.dart';
import '../repositories/mileage_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final mileageRepositoryProvider = Provider<MileageRepository>((ref) {
  return MileageRepository();
});

final mileageServiceProvider = Provider<MileageService>((ref) {
  final repo = ref.watch(mileageRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return MileageService(repo, authState);
});

// Trips for current user — auto-dispose when screen closes.
final userTripsProvider = StateNotifierProvider.autoDispose<
    UserTripsNotifier, AsyncValue<List<MileageTrip>>>(
  (ref) {
    final service = ref.watch(mileageServiceProvider);
    return UserTripsNotifier(service);
  },
);

// Trips for a specific job.
final jobTripsProvider = FutureProvider.autoDispose
    .family<List<MileageTrip>, String>(
  (ref, jobId) async {
    final repo = ref.watch(mileageRepositoryProvider);
    return repo.getTripsByJob(jobId);
  },
);

// --- User Trips Notifier ---

class UserTripsNotifier
    extends StateNotifier<AsyncValue<List<MileageTrip>>> {
  final MileageService _service;

  UserTripsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    state = const AsyncValue.loading();
    try {
      final trips = await _service.getTrips();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<MileageTrip?> addTrip({
    String? jobId,
    String? startAddress,
    String? endAddress,
    required double distanceMiles,
    String? purpose,
    required DateTime tripDate,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    int? durationSeconds,
  }) async {
    try {
      final trip = await _service.createTrip(
        jobId: jobId,
        startAddress: startAddress,
        endAddress: endAddress,
        distanceMiles: distanceMiles,
        purpose: purpose,
        tripDate: tripDate,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        durationSeconds: durationSeconds,
      );
      await loadTrips();
      return trip;
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePurpose(String tripId, String purpose) async {
    try {
      await _service.updateTrip(tripId, {'purpose': purpose});
      await loadTrips();
    } catch (_) {}
  }

  double get totalMiles =>
      state.valueOrNull?.fold<double>(0.0, (sum, t) => sum + t.distanceMiles) ?? 0;

  double get totalDeduction => totalMiles * MileageTrip.irsRate;
}

// --- Service ---

class MileageService {
  final MileageRepository _repo;
  final AuthState _authState;

  MileageService(this._repo, this._authState);

  Future<MileageTrip> createTrip({
    String? jobId,
    String? startAddress,
    String? endAddress,
    required double distanceMiles,
    String? purpose,
    required DateTime tripDate,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    int? durationSeconds,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to save trips.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final trip = MileageTrip(
      companyId: companyId,
      jobId: jobId,
      userId: userId,
      startAddress: startAddress,
      endAddress: endAddress,
      distanceMiles: distanceMiles,
      purpose: purpose,
      tripDate: tripDate,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
    );

    return _repo.createTrip(trip);
  }

  Future<List<MileageTrip>> getTrips({int limit = 100}) {
    return _repo.getTripsByUser(limit: limit);
  }

  Future<List<MileageTrip>> getTripsByJob(String jobId) {
    return _repo.getTripsByJob(jobId);
  }

  Future<List<MileageTrip>> getTripsByDateRange(
      DateTime start, DateTime end) {
    return _repo.getTripsByDateRange(start, end);
  }

  Future<MileageTrip> updateTrip(
      String id, Map<String, dynamic> updates) {
    return _repo.updateTrip(id, updates);
  }

  Future<void> deleteTrip(String id) {
    return _repo.deleteTrip(id);
  }
}
