// ZAFTO Photo Repository — Supabase Backend
// CRUD operations for the photos table + Storage uploads.

import 'dart:typed_data';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/photo.dart';
import '../services/storage_service.dart';

class PhotoRepository {
  final StorageService _storage;

  PhotoRepository(this._storage);

  static const _table = 'photos';
  static const _bucket = 'photos';

  // Upload photo bytes to Storage, insert row in photos table, return Photo.
  Future<Photo> uploadPhoto({
    required Uint8List bytes,
    required String companyId,
    required String uploadedByUserId,
    String? jobId,
    required PhotoCategory category,
    String? caption,
    String fileName = 'photo.jpg',
    String contentType = 'image/jpeg',
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Build storage path
      final storagePath = StorageService.buildPhotoPath(
        companyId: companyId,
        jobId: jobId,
        category: category.dbValue,
        fileName: fileName,
      );

      // Upload to Storage
      await _storage.uploadFile(
        bucket: _bucket,
        path: storagePath,
        bytes: bytes,
        contentType: contentType,
      );

      // Build photo record
      final photo = Photo(
        companyId: companyId,
        jobId: jobId,
        uploadedByUserId: uploadedByUserId,
        storagePath: storagePath,
        fileName: fileName,
        fileSize: bytes.length,
        mimeType: contentType,
        category: category,
        caption: caption,
        takenAt: takenAt,
        latitude: latitude,
        longitude: longitude,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      // Insert into photos table
      final response = await supabase
          .from(_table)
          .insert(photo.toInsertJson())
          .select()
          .single();

      return Photo.fromJson(response);
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw DatabaseError(
        'Failed to upload photo',
        userMessage: 'Could not save photo. Please try again.',
        cause: e,
      );
    }
  }

  // Get all photos for a job (non-deleted).
  Future<List<Photo>> getPhotosForJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Photo.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load photos for job $jobId',
        userMessage: 'Could not load photos.',
        cause: e,
      );
    }
  }

  // Get photos for a job filtered by category.
  Future<List<Photo>> getPhotosByCategory(
      String jobId, PhotoCategory category) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('category', category.dbValue)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Photo.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${category.name} photos for job $jobId',
        userMessage: 'Could not load photos.',
        cause: e,
      );
    }
  }

  // Get a single photo by ID.
  Future<Photo?> getPhoto(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return Photo.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load photo $id',
        userMessage: 'Could not load photo.',
        cause: e,
      );
    }
  }

  // Update photo metadata (caption, tags, category, client visibility).
  Future<Photo> updatePhoto(String id, Photo photo) async {
    try {
      final response = await supabase
          .from(_table)
          .update(photo.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return Photo.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update photo $id',
        userMessage: 'Could not update photo.',
        cause: e,
      );
    }
  }

  // Soft delete a photo (sets deleted_at, RLS hides from future queries).
  Future<void> deletePhoto(String id) async {
    try {
      await supabase.from(_table).update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete photo $id',
        userMessage: 'Could not delete photo.',
        cause: e,
      );
    }
  }

  // Get a signed URL for a photo's storage path.
  Future<String> getPhotoUrl(String storagePath) async {
    return _storage.getSignedUrl(
      bucket: _bucket,
      path: storagePath,
      expiresInSeconds: 3600,
    );
  }

  // Get a signed URL for a photo's thumbnail.
  Future<String?> getThumbnailUrl(String? thumbnailPath) async {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return null;
    return _storage.getSignedUrl(
      bucket: _bucket,
      path: thumbnailPath,
      expiresInSeconds: 3600,
    );
  }

  // Get all photos for the current company (no job filter).
  Future<List<Photo>> getRecentPhotos({int limit = 50}) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => Photo.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load recent photos',
        userMessage: 'Could not load photos.',
        cause: e,
      );
    }
  }
}
