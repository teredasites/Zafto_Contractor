// ZAFTO Voice Note Repository — Supabase Backend
// CRUD for the voice_notes table + audio upload to voice-notes bucket.

import 'dart:typed_data';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/voice_note.dart';
import '../services/storage_service.dart';

class VoiceNoteRepository {
  final StorageService _storage;
  static const _table = 'voice_notes';
  static const _bucket = 'voice-notes';

  VoiceNoteRepository(this._storage);

  // Create a voice note with audio upload to Storage.
  Future<VoiceNote> createVoiceNote({
    required VoiceNote note,
    required Uint8List audioBytes,
    required String fileName,
  }) async {
    try {
      // 1. Upload audio to Storage
      final storagePath = StorageService.buildPhotoPath(
        companyId: note.companyId,
        jobId: note.jobId,
        category: 'voice_notes',
        fileName: fileName,
      );

      await _storage.uploadFile(
        bucket: _bucket,
        path: storagePath,
        bytes: audioBytes,
        contentType: 'audio/m4a',
      );

      // 2. Insert row with storage path + file size
      final insertData = note
          .copyWith(
            storagePath: storagePath,
            fileSize: audioBytes.length,
          )
          .toInsertJson();

      final response = await supabase
          .from(_table)
          .insert(insertData)
          .select()
          .single();

      return VoiceNote.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create voice note',
        userMessage: 'Could not save voice note. Please try again.',
        cause: e,
      );
    }
  }

  // Get all voice notes for a job.
  Future<List<VoiceNote>> getVoiceNotesByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => VoiceNote.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load voice notes for job $jobId',
        userMessage: 'Could not load voice notes.',
        cause: e,
      );
    }
  }

  // Get voice notes by user.
  Future<List<VoiceNote>> getVoiceNotesByUser(String userId,
      {int limit = 50}) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('recorded_by_user_id', userId)
          .isFilter('deleted_at', null)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => VoiceNote.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load voice notes',
        userMessage: 'Could not load voice notes.',
        cause: e,
      );
    }
  }

  // Update a voice note (tags, transcription).
  Future<VoiceNote> updateVoiceNote(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return VoiceNote.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update voice note',
        userMessage: 'Could not update voice note.',
        cause: e,
      );
    }
  }

  // Soft delete a voice note.
  Future<void> deleteVoiceNote(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete voice note',
        userMessage: 'Could not delete voice note.',
        cause: e,
      );
    }
  }

  // Get a signed URL for audio playback.
  Future<String> getAudioUrl(String storagePath) {
    return _storage.getSignedUrl(bucket: _bucket, path: storagePath);
  }
}
