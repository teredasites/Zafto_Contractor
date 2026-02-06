// ZAFTO Storage Service — Supabase Storage
// Generic file upload/download for all storage buckets.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../core/supabase_client.dart';
import '../core/errors.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  // Upload file bytes to a Supabase Storage bucket.
  // Returns the storage path (not a URL — use getSignedUrl for access).
  // Path format: {company_id}/{job_id}/{category}/{timestamp}_{filename}
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
      return path;
    } catch (e) {
      throw DatabaseError(
        'Failed to upload file to $bucket/$path',
        userMessage: 'Could not upload file. Please try again.',
        cause: e,
      );
    }
  }

  // Delete a file from storage.
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete file from $bucket/$path',
        userMessage: 'Could not delete file.',
        cause: e,
      );
    }
  }

  // Get a time-limited signed URL for private bucket access.
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await supabase.storage.from(bucket).createSignedUrl(
            path,
            expiresInSeconds,
          );
      return url;
    } catch (e) {
      throw DatabaseError(
        'Failed to get signed URL for $bucket/$path',
        userMessage: 'Could not load file.',
        cause: e,
      );
    }
  }

  // Build a standard storage path for photos.
  // Format: {companyId}/{jobId|no_job}/{category}/{timestamp}_{fileName}
  static String buildPhotoPath({
    required String companyId,
    String? jobId,
    required String category,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final jobSegment = jobId ?? 'no_job';
    return '$companyId/$jobSegment/$category/${timestamp}_$fileName';
  }

  // Build thumbnail path from a photo path (prefixes filename with thumb_).
  static String buildThumbnailPath(String photoPath) {
    final lastSlash = photoPath.lastIndexOf('/');
    if (lastSlash == -1) return 'thumb_$photoPath';
    return '${photoPath.substring(0, lastSlash + 1)}thumb_${photoPath.substring(lastSlash + 1)}';
  }
}
