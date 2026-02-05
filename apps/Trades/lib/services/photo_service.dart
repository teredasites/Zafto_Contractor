import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
// NOTE: Removed 'package:image/image.dart' - causes dart:io crash on web
import '../models/job_photo.dart';
import '../models/role.dart';
import 'permission_service.dart';

/// Service for photo upload, storage, and management
class PhotoService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PermissionService _permissions;
  final Uuid _uuid = const Uuid();

  // Thumbnail dimensions
  static const int thumbnailWidth = 300;
  static const int thumbnailHeight = 300;

  // Max file size (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  PhotoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required PermissionService permissions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _permissions = permissions;

  // ============================================================
  // COLLECTIONS & REFERENCES
  // ============================================================

  CollectionReference<Map<String, dynamic>> _photosRef(String companyId) =>
      _firestore.collection('companies').doc(companyId).collection('photos');

  Reference _storageRef(String companyId, String jobId, String fileName) =>
      _storage.ref().child('companies/$companyId/jobs/$jobId/photos/$fileName');

  Reference _thumbnailRef(String companyId, String jobId, String fileName) =>
      _storage.ref().child('companies/$companyId/jobs/$jobId/thumbnails/$fileName');

  // ============================================================
  // UPLOAD
  // ============================================================

  /// Upload a photo for a job
  Future<JobPhoto> uploadPhoto({
    required String companyId,
    required String jobId,
    required String uploadedByUserId,
    required Uint8List imageBytes,
    required String originalFileName,
    required PhotoType type,
    String? caption,
    String? notes,
    double? latitude,
    double? longitude,
    DateTime? takenAt,
    bool isPrivate = false,
  }) async {
    // Check file size
    if (imageBytes.length > maxFileSizeBytes) {
      throw Exception('File size exceeds maximum of 10MB');
    }

    final photoId = _uuid.v4();
    final now = DateTime.now();
    final extension = _getExtension(originalFileName);
    final fileName = '$photoId$extension';

    // Upload original image
    final uploadRef = _storageRef(companyId, jobId, fileName);
    final metadata = SettableMetadata(
      contentType: _getMimeType(extension),
      customMetadata: {
        'uploadedBy': uploadedByUserId,
        'jobId': jobId,
        'photoId': photoId,
      },
    );

    final uploadTask = await uploadRef.putData(imageBytes, metadata);
    final storageUrl = await uploadTask.ref.getDownloadURL();

    // Generate and upload thumbnail
    String? thumbnailUrl;
    try {
      final thumbnailBytes = await _generateThumbnail(imageBytes);
      if (thumbnailBytes != null) {
        final thumbRef = _thumbnailRef(companyId, jobId, fileName);
        await thumbRef.putData(thumbnailBytes, SettableMetadata(
          contentType: 'image/jpeg',
        ));
        thumbnailUrl = await thumbRef.getDownloadURL();
      }
    } catch (e) {
      // Thumbnail generation failed, continue without it
    }

    // Create photo record
    final photo = JobPhoto(
      id: photoId,
      companyId: companyId,
      jobId: jobId,
      uploadedByUserId: uploadedByUserId,
      fileName: fileName,
      storageUrl: storageUrl,
      thumbnailUrl: thumbnailUrl,
      fileSize: imageBytes.length,
      mimeType: _getMimeType(extension),
      type: type,
      caption: caption,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      takenAt: takenAt ?? now,
      uploadedAt: now,
      isPrivate: isPrivate,
    );

    // Save to Firestore
    await _photosRef(companyId).doc(photoId).set(photo.toMap());

    // Update job photo count
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs')
        .doc(jobId)
        .update({
      'photoCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return photo;
  }

  /// Upload multiple photos at once
  Future<List<JobPhoto>> uploadPhotos({
    required String companyId,
    required String jobId,
    required String uploadedByUserId,
    required List<({Uint8List bytes, String fileName})> images,
    required PhotoType type,
    double? latitude,
    double? longitude,
  }) async {
    final photos = <JobPhoto>[];

    for (final image in images) {
      try {
        final photo = await uploadPhoto(
          companyId: companyId,
          jobId: jobId,
          uploadedByUserId: uploadedByUserId,
          imageBytes: image.bytes,
          originalFileName: image.fileName,
          type: type,
          latitude: latitude,
          longitude: longitude,
        );
        photos.add(photo);
      } catch (e) {
        // Continue with other photos if one fails
      }
    }

    return photos;
  }

  // ============================================================
  // READ
  // ============================================================

  /// Get all photos for a job
  Future<List<JobPhoto>> getJobPhotos(String companyId, String jobId) async {
    final snapshot = await _photosRef(companyId)
        .where('jobId', isEqualTo: jobId)
        .orderBy('takenAt')
        .get();

    return snapshot.docs.map((doc) => JobPhoto.fromFirestore(doc)).toList();
  }

  /// Get photos by type
  Future<List<JobPhoto>> getPhotosByType(
    String companyId,
    String jobId,
    PhotoType type,
  ) async {
    final snapshot = await _photosRef(companyId)
        .where('jobId', isEqualTo: jobId)
        .where('type', isEqualTo: type.name)
        .orderBy('takenAt')
        .get();

    return snapshot.docs.map((doc) => JobPhoto.fromFirestore(doc)).toList();
  }

  /// Get before/after photo pairs
  Future<Map<String, List<JobPhoto>>> getBeforeAfterPhotos(
    String companyId,
    String jobId,
  ) async {
    final photos = await getJobPhotos(companyId, jobId);

    return {
      'before': photos.where((p) => p.type == PhotoType.before).toList(),
      'after': photos.where((p) => p.type == PhotoType.after).toList(),
    };
  }

  /// Get a single photo
  Future<JobPhoto?> getPhoto(String companyId, String photoId) async {
    final doc = await _photosRef(companyId).doc(photoId).get();
    if (!doc.exists) return null;
    return JobPhoto.fromFirestore(doc);
  }

  /// Stream photos for real-time updates
  Stream<List<JobPhoto>> watchJobPhotos(String companyId, String jobId) {
    return _photosRef(companyId)
        .where('jobId', isEqualTo: jobId)
        .orderBy('takenAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobPhoto.fromFirestore(doc)).toList();
    });
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// Update photo metadata
  Future<JobPhoto> updatePhoto(JobPhoto photo) async {
    await _photosRef(photo.companyId).doc(photo.id).update(photo.toMap());
    return photo;
  }

  /// Add caption to photo
  Future<JobPhoto> addCaption(
    String companyId,
    String photoId,
    String caption,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    return updatePhoto(photo.copyWith(caption: caption));
  }

  /// Add annotation to photo
  Future<JobPhoto> addAnnotation(
    String companyId,
    String photoId,
    PhotoAnnotation annotation,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    final updatedAnnotations = [...photo.annotations, annotation];
    return updatePhoto(photo.copyWith(annotations: updatedAnnotations));
  }

  /// Remove annotation from photo
  Future<JobPhoto> removeAnnotation(
    String companyId,
    String photoId,
    String annotationId,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    final updatedAnnotations = photo.annotations
        .where((a) => a.id != annotationId)
        .toList();
    return updatePhoto(photo.copyWith(annotations: updatedAnnotations));
  }

  /// Clear all annotations
  Future<JobPhoto> clearAnnotations(
    String companyId,
    String photoId,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    return updatePhoto(photo.copyWith(annotations: []));
  }

  /// Set AI analysis results
  Future<JobPhoto> setAiAnalysis(
    String companyId,
    String photoId, {
    required String analysis,
    List<String>? detectedIssues,
    List<String>? detectedEquipment,
  }) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    return updatePhoto(photo.copyWith(
      aiAnalysis: analysis,
      detectedIssues: detectedIssues,
      detectedEquipment: detectedEquipment,
    ));
  }

  /// Change photo type
  Future<JobPhoto> changePhotoType(
    String companyId,
    String photoId,
    PhotoType newType,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    return updatePhoto(photo.copyWith(type: newType));
  }

  /// Toggle photo privacy
  Future<JobPhoto> togglePrivacy(
    String companyId,
    String photoId,
  ) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    return updatePhoto(photo.copyWith(isPrivate: !photo.isPrivate));
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete a photo
  Future<void> deletePhoto(String companyId, String photoId) async {
    final photo = await getPhoto(companyId, photoId);
    if (photo == null) throw Exception('Photo not found');

    // Delete from Storage
    try {
      final storageRef = _storageRef(companyId, photo.jobId, photo.fileName);
      await storageRef.delete();
    } catch (e) {
      // File might already be deleted
    }

    // Delete thumbnail
    try {
      final thumbRef = _thumbnailRef(companyId, photo.jobId, photo.fileName);
      await thumbRef.delete();
    } catch (e) {
      // Thumbnail might not exist
    }

    // Delete from Firestore
    await _photosRef(companyId).doc(photoId).delete();

    // Update job photo count
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs')
        .doc(photo.jobId)
        .update({
      'photoCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete all photos for a job
  Future<void> deleteJobPhotos(String companyId, String jobId) async {
    final photos = await getJobPhotos(companyId, jobId);

    for (final photo in photos) {
      await deletePhoto(companyId, photo.id);
    }
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  /// Generate thumbnail from image bytes
  /// NOTE: Disabled - image package causes dart:io crash on web
  /// TODO: Use server-side thumbnail generation via Cloud Functions
  Future<Uint8List?> _generateThumbnail(Uint8List imageBytes) async {
    // Skip client-side thumbnail generation for web compatibility
    // Firebase Cloud Functions can generate thumbnails server-side
    return null;
  }

  /// Get file extension from filename
  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last.toLowerCase()}';
    }
    return '.jpg';
  }

  /// Get MIME type from extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Get storage usage for a job
  Future<int> getJobStorageUsage(String companyId, String jobId) async {
    final photos = await getJobPhotos(companyId, jobId);
    return photos.fold<int>(0, (sum, photo) => sum + photo.fileSize);
  }

  /// Get storage usage for a company
  Future<int> getCompanyStorageUsage(String companyId) async {
    final snapshot = await _photosRef(companyId).get();
    int total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['fileSize'] as int?) ?? 0;
    }
    return total;
  }

  /// Get photo count for a company
  Future<int> getCompanyPhotoCount(String companyId) async {
    final snapshot = await _photosRef(companyId).count().get();
    return snapshot.count ?? 0;
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for PhotoService
final photoServiceProvider = Provider<PhotoService>((ref) {
  final permissions = ref.watch(permissionServiceProvider);
  return PhotoService(permissions: permissions);
});

/// Provider for job photos
final jobPhotosProvider = FutureProvider.family<List<JobPhoto>,
    ({String companyId, String jobId})>((ref, params) {
  return ref
      .watch(photoServiceProvider)
      .getJobPhotos(params.companyId, params.jobId);
});

/// Provider for job photos stream
final jobPhotosStreamProvider = StreamProvider.family<List<JobPhoto>,
    ({String companyId, String jobId})>((ref, params) {
  return ref
      .watch(photoServiceProvider)
      .watchJobPhotos(params.companyId, params.jobId);
});

/// Provider for before/after photos
final beforeAfterPhotosProvider = FutureProvider.family<Map<String, List<JobPhoto>>,
    ({String companyId, String jobId})>((ref, params) {
  return ref
      .watch(photoServiceProvider)
      .getBeforeAfterPhotos(params.companyId, params.jobId);
});

/// Provider for job storage usage
final jobStorageUsageProvider = FutureProvider.family<int,
    ({String companyId, String jobId})>((ref, params) {
  return ref
      .watch(photoServiceProvider)
      .getJobStorageUsage(params.companyId, params.jobId);
});
