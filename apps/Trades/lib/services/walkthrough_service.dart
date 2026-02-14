// ZAFTO Walkthrough Service — Supabase Backend
// Auth-enriched wrapper around WalkthroughRepository.
// Providers for walkthroughs, rooms, photos, templates, and floor plans.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/walkthrough.dart';
import '../models/walkthrough_room.dart';
import '../models/walkthrough_photo.dart';
import '../models/walkthrough_template.dart';
import '../models/floor_plan.dart';
import '../repositories/walkthrough_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final walkthroughRepositoryProvider = Provider<WalkthroughRepository>((ref) {
  return WalkthroughRepository();
});

final walkthroughServiceProvider = Provider<WalkthroughService>((ref) {
  final repo = ref.watch(walkthroughRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return WalkthroughService(repo, authState);
});

// Walkthroughs list for the current company.
final walkthroughsProvider =
    FutureProvider.autoDispose<List<Walkthrough>>((ref) async {
  final service = ref.watch(walkthroughServiceProvider);
  return service.getWalkthroughs();
});

// Single walkthrough detail by ID.
final walkthroughDetailProvider =
    FutureProvider.autoDispose.family<Walkthrough, String>((ref, id) async {
  final service = ref.watch(walkthroughServiceProvider);
  return service.getWalkthrough(id);
});

// Rooms for a walkthrough.
final walkthroughRoomsProvider = FutureProvider.autoDispose
    .family<List<WalkthroughRoom>, String>((ref, walkthroughId) async {
  final service = ref.watch(walkthroughServiceProvider);
  return service.getRooms(walkthroughId);
});

// Photos for a walkthrough.
final walkthroughPhotosProvider = FutureProvider.autoDispose
    .family<List<WalkthroughPhoto>, String>((ref, walkthroughId) async {
  final service = ref.watch(walkthroughServiceProvider);
  return service.getPhotos(walkthroughId);
});

// Templates for current company.
final walkthroughTemplatesProvider =
    FutureProvider.autoDispose<List<WalkthroughTemplate>>((ref) async {
  final service = ref.watch(walkthroughServiceProvider);
  return service.getTemplates();
});

// --- Service ---

class WalkthroughService {
  final WalkthroughRepository _repo;
  final AuthState _authState;

  WalkthroughService(this._repo, this._authState);

  String get _companyId {
    final id = _authState.companyId;
    if (id == null || id.isEmpty) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage walkthroughs.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return id;
  }

  String get _userId {
    final uid = _authState.user?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage walkthroughs.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return uid;
  }

  // ==================== WALKTHROUGHS ====================

  Future<List<Walkthrough>> getWalkthroughs({String? status}) {
    return _repo.getWalkthroughs(_companyId, status: status);
  }

  Future<Walkthrough> getWalkthrough(String id) {
    return _repo.getWalkthrough(id);
  }

  Future<Walkthrough> createWalkthrough({
    required String name,
    String walkthroughType = 'general',
    String propertyType = 'residential',
    String address = '',
    String city = '',
    String state = '',
    String zipCode = '',
    double? latitude,
    double? longitude,
    String? customerId,
    String? jobId,
    String? bidId,
    String? propertyId,
    String? templateId,
    String? notes,
    Map<String, dynamic>? weatherConditions,
  }) {
    final walkthrough = Walkthrough(
      companyId: _companyId,
      createdBy: _userId,
      customerId: customerId,
      jobId: jobId,
      bidId: bidId,
      propertyId: propertyId,
      name: name,
      walkthroughType: walkthroughType,
      propertyType: propertyType,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      latitude: latitude,
      longitude: longitude,
      templateId: templateId,
      status: 'in_progress',
      startedAt: DateTime.now(),
      notes: notes,
      weatherConditions: weatherConditions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createWalkthrough(walkthrough);
  }

  Future<Walkthrough> updateWalkthrough(String id, Walkthrough walkthrough) {
    return _repo.updateWalkthrough(id, walkthrough);
  }

  Future<void> deleteWalkthrough(String id) {
    return _repo.deleteWalkthrough(id);
  }

  Future<Walkthrough> completeWalkthrough(String id) {
    return _repo.completeWalkthrough(id);
  }

  // ==================== ROOMS ====================

  Future<List<WalkthroughRoom>> getRooms(String walkthroughId) {
    return _repo.getRooms(walkthroughId);
  }

  Future<WalkthroughRoom> getRoom(String id) {
    return _repo.getRoom(id);
  }

  Future<WalkthroughRoom> addRoom({
    required String walkthroughId,
    required String name,
    String roomType = 'other',
    int floorLevel = 1,
    int? sortOrder,
    RoomDimensions dimensions = const RoomDimensions(),
    int? conditionRating,
    String? notes,
    Map<String, dynamic> customFields = const {},
    List<String> tags = const [],
  }) {
    final room = WalkthroughRoom(
      walkthroughId: walkthroughId,
      name: name,
      roomType: roomType,
      floorLevel: floorLevel,
      sortOrder: sortOrder,
      dimensions: dimensions,
      conditionRating: conditionRating,
      notes: notes,
      customFields: customFields,
      tags: tags,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.addRoom(room);
  }

  Future<WalkthroughRoom> updateRoom(String id, WalkthroughRoom room) {
    return _repo.updateRoom(id, room);
  }

  Future<void> deleteRoom(String id) {
    return _repo.deleteRoom(id);
  }

  Future<void> reorderRooms(String walkthroughId, List<String> roomIds) {
    return _repo.reorderRooms(walkthroughId, roomIds);
  }

  // ==================== PHOTOS ====================

  Future<List<WalkthroughPhoto>> getPhotos(
    String walkthroughId, {
    String? roomId,
  }) {
    return _repo.getPhotos(walkthroughId, roomId: roomId);
  }

  Future<WalkthroughPhoto> addPhoto({
    required String walkthroughId,
    String? roomId,
    required String storagePath,
    String? thumbnailPath,
    String? caption,
    String photoType = 'overview',
    Map<String, dynamic>? annotations,
    int? sortOrder,
    Map<String, dynamic> metadata = const {},
    double? gpsLatitude,
    double? gpsLongitude,
    double? compassHeading,
    double? altitude,
    double? accuracy,
    String? floorLevel,
  }) {
    final photo = WalkthroughPhoto(
      walkthroughId: walkthroughId,
      roomId: roomId,
      storagePath: storagePath,
      thumbnailPath: thumbnailPath,
      caption: caption,
      photoType: photoType,
      annotations: annotations,
      sortOrder: sortOrder,
      metadata: metadata,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      compassHeading: compassHeading,
      altitude: altitude,
      accuracy: accuracy,
      floorLevel: floorLevel,
      createdAt: DateTime.now(),
    );

    return _repo.addPhoto(photo);
  }

  Future<void> deletePhoto(String id) {
    return _repo.deletePhoto(id);
  }

  // ==================== TEMPLATES ====================

  Future<List<WalkthroughTemplate>> getTemplates({
    String? walkthroughType,
  }) {
    return _repo.getTemplates(
      companyId: _authState.companyId,
      walkthroughType: walkthroughType,
    );
  }

  Future<void> incrementTemplateUsage(String templateId) {
    return _repo.incrementTemplateUsage(templateId);
  }

  // ==================== FLOOR PLANS ====================

  Future<List<FloorPlan>> getFloorPlans(String propertyId) {
    return _repo.getFloorPlans(propertyId);
  }

  Future<FloorPlan> saveFloorPlan({
    String id = '',
    String? propertyId,
    String? walkthroughId,
    required String name,
    int floorLevel = 1,
    required Map<String, dynamic> planData,
    String? thumbnailPath,
    String source = 'manual_sketch',
    Map<String, dynamic> metadata = const {},
  }) {
    final floorPlan = FloorPlan(
      id: id,
      companyId: _companyId,
      propertyId: propertyId,
      walkthroughId: walkthroughId,
      name: name,
      floorLevel: floorLevel,
      planData: planData,
      thumbnailPath: thumbnailPath,
      source: source,
      metadata: metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.saveFloorPlan(floorPlan);
  }
}
