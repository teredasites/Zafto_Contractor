// ZAFTO Floor Plan Thumbnail Service — SK7
// Generates 512x512 PNG thumbnails from floor plan canvas.
// Flutter: RepaintBoundary → toImage → upload to Supabase Storage.
// Updates property_floor_plans.thumbnail_path.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/errors.dart';
import '../repositories/floor_plan_repository.dart';
import 'storage_service.dart';

class FloorPlanThumbnailService {
  static const String _bucket = 'floor-plan-thumbnails';
  static const int _thumbnailSize = 512;

  final StorageService _storage;
  final FloorPlanRepository _repo;

  FloorPlanThumbnailService({
    StorageService? storage,
    FloorPlanRepository? repo,
  })  : _storage = storage ?? StorageService(),
        _repo = repo ?? FloorPlanRepository();

  /// Capture a thumbnail from a RepaintBoundary and upload it.
  /// Returns the storage path on success, null on failure.
  /// Designed to be called on save — failures are non-blocking (graceful).
  Future<String?> captureAndUpload({
    required GlobalKey repaintBoundaryKey,
    required String planId,
    required String companyId,
  }) async {
    try {
      // 1. Capture image from RepaintBoundary
      final bytes = await _captureFromBoundary(repaintBoundaryKey);
      if (bytes == null) return null;

      // 2. Build storage path
      final storagePath = _buildThumbnailPath(companyId, planId);

      // 3. Upload to Supabase Storage (upsert-style — delete old first)
      try {
        await _storage.deleteFile(bucket: _bucket, path: storagePath);
      } catch (_) {
        // File may not exist yet — that's fine
      }

      await _storage.uploadFile(
        bucket: _bucket,
        path: storagePath,
        bytes: bytes,
        contentType: 'image/png',
      );

      // 4. Update the floor plan record with thumbnail path
      await _repo.updateThumbnailPath(planId, storagePath);

      return storagePath;
    } catch (e) {
      // Thumbnail failure is non-critical — log but don't crash
      debugPrint('Thumbnail generation failed: $e');
      return null;
    }
  }

  /// Capture bytes from RepaintBoundary at 512x512 resolution.
  Future<List<int>?> _captureFromBoundary(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Get the render size and compute pixel ratio to fit 512x512
      final renderSize = boundary.size;
      if (renderSize.width <= 0 || renderSize.height <= 0) return null;

      final maxDimension =
          renderSize.width > renderSize.height
              ? renderSize.width
              : renderSize.height;
      final pixelRatio = _thumbnailSize / maxDimension;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to capture RepaintBoundary: $e');
      return null;
    }
  }

  /// Build storage path: {companyId}/thumbnails/{planId}.png
  static String _buildThumbnailPath(String companyId, String planId) {
    return '$companyId/thumbnails/$planId.png';
  }

  /// Get a signed URL for a thumbnail (1-hour expiry).
  Future<String?> getThumbnailUrl(String thumbnailPath) async {
    if (thumbnailPath.isEmpty) return null;
    try {
      return await _storage.getSignedUrl(
        bucket: _bucket,
        path: thumbnailPath,
      );
    } catch (e) {
      if (e is DatabaseError) {
        debugPrint('Thumbnail URL error: ${e.message}');
      }
      return null;
    }
  }
}
