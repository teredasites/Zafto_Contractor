// ZAFTO Receipt Repository — Supabase Backend
// CRUD for the receipts table + Storage upload for receipt images.

import 'dart:typed_data';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/receipt.dart';
import '../services/storage_service.dart';

class ReceiptRepository {
  final StorageService _storage;
  static const _table = 'receipts';
  static const _bucket = 'receipts';

  ReceiptRepository(this._storage);

  // Upload receipt image + create DB row.
  Future<Receipt> createReceipt({
    required Receipt receipt,
    Uint8List? imageBytes,
    String? companyId,
  }) async {
    try {
      String? storagePath;

      // Upload image if provided
      if (imageBytes != null && companyId != null) {
        final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        storagePath = StorageService.buildPhotoPath(
          companyId: companyId,
          jobId: receipt.jobId,
          category: 'receipts',
          fileName: fileName,
        );
        await _storage.uploadFile(
          bucket: _bucket,
          path: storagePath,
          bytes: imageBytes,
          contentType: 'image/jpeg',
        );
      }

      // Insert with storage path
      final insertData = receipt.toInsertJson();
      if (storagePath != null) {
        insertData['storage_path'] = storagePath;
      }

      final response = await supabase
          .from(_table)
          .insert(insertData)
          .select()
          .single();

      return Receipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create receipt',
        userMessage: 'Could not save receipt. Please try again.',
        cause: e,
      );
    }
  }

  // Get all receipts for a job.
  Future<List<Receipt>> getReceiptsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Receipt.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipts for job $jobId',
        userMessage: 'Could not load receipts.',
        cause: e,
      );
    }
  }

  // Get all receipts for a company.
  Future<List<Receipt>> getReceiptsByCompany({int limit = 100}) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => Receipt.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipts',
        userMessage: 'Could not load receipts.',
        cause: e,
      );
    }
  }

  // Get a single receipt by ID.
  Future<Receipt?> getReceipt(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Receipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipt $id',
        userMessage: 'Could not load receipt.',
        cause: e,
      );
    }
  }

  // Update receipt fields (after OCR or manual edit).
  Future<Receipt> updateReceipt(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Receipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update receipt $id',
        userMessage: 'Could not update receipt.',
        cause: e,
      );
    }
  }

  // Soft delete (set deleted_at).
  Future<void> deleteReceipt(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete receipt $id',
        userMessage: 'Could not delete receipt.',
        cause: e,
      );
    }
  }

  // Get signed URL for a receipt image.
  Future<String> getReceiptImageUrl(String storagePath) async {
    return _storage.getSignedUrl(bucket: _bucket, path: storagePath);
  }
}
