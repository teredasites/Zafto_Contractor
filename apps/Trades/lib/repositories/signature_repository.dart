// ZAFTO Signature Repository — Supabase Backend
// CRUD for the signatures table + Storage upload for signature images.

import 'dart:typed_data';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/signature.dart';
import '../services/storage_service.dart';

class SignatureRepository {
  final StorageService _storage;
  static const _table = 'signatures';
  static const _bucket = 'signatures';

  SignatureRepository(this._storage);

  // Upload signature PNG + create DB row.
  Future<Signature> createSignature({
    required Signature signature,
    required Uint8List imageBytes,
    required String companyId,
  }) async {
    try {
      // Upload PNG to storage
      final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = StorageService.buildPhotoPath(
        companyId: companyId,
        jobId: signature.jobId,
        category: 'signatures',
        fileName: fileName,
      );
      await _storage.uploadFile(
        bucket: _bucket,
        path: storagePath,
        bytes: imageBytes,
        contentType: 'image/png',
      );

      // Insert with storage path
      final insertData = signature.toInsertJson();
      insertData['storage_path'] = storagePath;

      final response = await supabase
          .from(_table)
          .insert(insertData)
          .select()
          .single();

      return Signature.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to save signature',
        userMessage: 'Could not save signature. Please try again.',
        cause: e,
      );
    }
  }

  // Get all signatures for a job.
  Future<List<Signature>> getSignaturesByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Signature.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load signatures for job $jobId',
        userMessage: 'Could not load signatures.',
        cause: e,
      );
    }
  }

  // Get signatures by purpose.
  Future<List<Signature>> getSignaturesByPurpose(
      String jobId, SignaturePurpose purpose) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('purpose', purpose.dbValue)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Signature.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load signatures',
        userMessage: 'Could not load signatures.',
        cause: e,
      );
    }
  }

  // Get a single signature by ID.
  Future<Signature?> getSignature(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Signature.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load signature $id',
        userMessage: 'Could not load signature.',
        cause: e,
      );
    }
  }

  // Get signed URL for a signature image.
  Future<String> getSignatureImageUrl(String storagePath) async {
    return _storage.getSignedUrl(bucket: _bucket, path: storagePath);
  }
}
