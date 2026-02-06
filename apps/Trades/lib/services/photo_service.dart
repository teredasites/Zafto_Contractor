// ZAFTO Photo Service — Supabase Backend
// Providers, notifier, and service for photo operations.
// Replaces the deleted photo_service.dart (A1 cleanup) with Supabase wiring.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/photo.dart';
import '../repositories/photo_repository.dart';
import '../services/storage_service.dart';
import 'auth_service.dart';

// --- Providers ---

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PhotoRepository(storage);
});

final photoServiceProvider = Provider<PhotoService>((ref) {
  final repo = ref.watch(photoRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return PhotoService(repo, authState);
});

// Photos for a specific job — auto-dispose when screen closes.
final jobPhotosProvider = StateNotifierProvider.autoDispose
    .family<JobPhotosNotifier, AsyncValue<List<Photo>>, String>(
  (ref, jobId) {
    final service = ref.watch(photoServiceProvider);
    return JobPhotosNotifier(service, jobId);
  },
);

// Photos for a specific job + category combo.
final photosByCategoryProvider = FutureProvider.autoDispose.family<
    List<Photo>, ({String jobId, PhotoCategory category})>(
  (ref, params) async {
    final repo = ref.watch(photoRepositoryProvider);
    return repo.getPhotosByCategory(params.jobId, params.category);
  },
);

// Photo upload state for UI progress tracking.
final photoUploadProvider =
    StateNotifierProvider.autoDispose<PhotoUploadNotifier, PhotoUploadState>(
  (ref) {
    final service = ref.watch(photoServiceProvider);
    return PhotoUploadNotifier(service);
  },
);

// --- Upload State ---

enum UploadStatus { idle, uploading, success, error }

class PhotoUploadState {
  final UploadStatus status;
  final String? errorMessage;
  final Photo? lastUploadedPhoto;

  const PhotoUploadState({
    this.status = UploadStatus.idle,
    this.errorMessage,
    this.lastUploadedPhoto,
  });

  PhotoUploadState copyWith({
    UploadStatus? status,
    String? errorMessage,
    Photo? lastUploadedPhoto,
  }) {
    return PhotoUploadState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastUploadedPhoto: lastUploadedPhoto ?? this.lastUploadedPhoto,
    );
  }

  bool get isUploading => status == UploadStatus.uploading;
}

// --- Upload Notifier ---

class PhotoUploadNotifier extends StateNotifier<PhotoUploadState> {
  final PhotoService _service;

  PhotoUploadNotifier(this._service) : super(const PhotoUploadState());

  Future<Photo?> upload({
    required Uint8List bytes,
    String? jobId,
    PhotoCategory category = PhotoCategory.general,
    String? caption,
    String fileName = 'photo.jpg',
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    Map<String, dynamic> metadata = const {},
  }) async {
    state = state.copyWith(status: UploadStatus.uploading);
    try {
      final photo = await _service.uploadPhoto(
        bytes: bytes,
        jobId: jobId,
        category: category,
        caption: caption,
        fileName: fileName,
        takenAt: takenAt,
        latitude: latitude,
        longitude: longitude,
        metadata: metadata,
      );
      state = PhotoUploadState(
        status: UploadStatus.success,
        lastUploadedPhoto: photo,
      );
      return photo;
    } catch (e) {
      final message =
          e is AppError ? (e.userMessage ?? e.message) : 'Upload failed';
      state = PhotoUploadState(
        status: UploadStatus.error,
        errorMessage: message,
      );
      return null;
    }
  }

  void reset() {
    state = const PhotoUploadState();
  }
}

// --- Job Photos Notifier ---

class JobPhotosNotifier extends StateNotifier<AsyncValue<List<Photo>>> {
  final PhotoService _service;
  final String _jobId;

  JobPhotosNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    state = const AsyncValue.loading();
    try {
      final photos = await _service.getPhotosForJob(_jobId);
      state = AsyncValue.data(photos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Photo?> addPhoto({
    required Uint8List bytes,
    PhotoCategory category = PhotoCategory.general,
    String? caption,
    String fileName = 'photo.jpg',
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final photo = await _service.uploadPhoto(
        bytes: bytes,
        jobId: _jobId,
        category: category,
        caption: caption,
        fileName: fileName,
        takenAt: takenAt,
        latitude: latitude,
        longitude: longitude,
        metadata: metadata,
      );
      await loadPhotos();
      return photo;
    } catch (e) {
      return null;
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await _service.deletePhoto(photoId);
      await loadPhotos();
    } catch (_) {}
  }

  List<Photo> filterByCategory(PhotoCategory category) {
    return state.valueOrNull
            ?.where((p) => p.category == category)
            .toList() ??
        [];
  }
}

// --- Service ---

class PhotoService {
  final PhotoRepository _repo;
  final AuthState _authState;

  PhotoService(this._repo, this._authState);

  Future<Photo> uploadPhoto({
    required Uint8List bytes,
    String? jobId,
    PhotoCategory category = PhotoCategory.general,
    String? caption,
    String fileName = 'photo.jpg',
    String contentType = 'image/jpeg',
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    Map<String, dynamic> metadata = const {},
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to upload photos.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    return _repo.uploadPhoto(
      bytes: bytes,
      companyId: companyId,
      uploadedByUserId: userId,
      jobId: jobId,
      category: category,
      caption: caption,
      fileName: fileName,
      contentType: contentType,
      takenAt: takenAt,
      latitude: latitude,
      longitude: longitude,
      metadata: metadata,
    );
  }

  Future<List<Photo>> getPhotosForJob(String jobId) {
    return _repo.getPhotosForJob(jobId);
  }

  Future<List<Photo>> getPhotosByCategory(
      String jobId, PhotoCategory category) {
    return _repo.getPhotosByCategory(jobId, category);
  }

  Future<Photo> updatePhoto(String id, Photo photo) {
    return _repo.updatePhoto(id, photo);
  }

  Future<void> deletePhoto(String id) {
    return _repo.deletePhoto(id);
  }

  Future<String> getPhotoUrl(String storagePath) {
    return _repo.getPhotoUrl(storagePath);
  }

  Future<List<Photo>> getRecentPhotos({int limit = 50}) {
    return _repo.getRecentPhotos(limit: limit);
  }
}
