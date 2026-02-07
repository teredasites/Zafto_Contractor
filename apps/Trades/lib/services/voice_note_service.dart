// ZAFTO Voice Note Service — Supabase Backend
// Providers, notifier, and auth-enriched service for voice notes.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/voice_note.dart';
import '../repositories/voice_note_repository.dart';
import 'storage_service.dart';
import 'auth_service.dart';

// --- Providers ---

final voiceNoteRepositoryProvider = Provider<VoiceNoteRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return VoiceNoteRepository(storage);
});

final voiceNoteServiceProvider = Provider<VoiceNoteService>((ref) {
  final repo = ref.watch(voiceNoteRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return VoiceNoteService(repo, authState);
});

// Voice notes for a job — auto-dispose when screen closes.
final jobVoiceNotesProvider = StateNotifierProvider.autoDispose
    .family<JobVoiceNotesNotifier, AsyncValue<List<VoiceNote>>, String>(
  (ref, jobId) {
    final service = ref.watch(voiceNoteServiceProvider);
    return JobVoiceNotesNotifier(service, jobId);
  },
);

// Recent voice notes for current user.
final recentVoiceNotesProvider =
    FutureProvider.autoDispose<List<VoiceNote>>((ref) async {
  final service = ref.watch(voiceNoteServiceProvider);
  return service.getRecentNotes();
});

// --- Job Voice Notes Notifier ---

class JobVoiceNotesNotifier
    extends StateNotifier<AsyncValue<List<VoiceNote>>> {
  final VoiceNoteService _service;
  final String _jobId;

  JobVoiceNotesNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _service.getVoiceNotesByJob(_jobId);
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  int get noteCount => state.valueOrNull?.length ?? 0;
}

// --- Service ---

class VoiceNoteService {
  final VoiceNoteRepository _repo;
  final AuthState _authState;

  VoiceNoteService(this._repo, this._authState);

  // Create a voice note, enriching with auth context.
  Future<VoiceNote> createVoiceNote({
    String? jobId,
    required Uint8List audioBytes,
    required String fileName,
    required int durationSeconds,
    required DateTime recordedAt,
    List<String> tags = const [],
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to save voice notes.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final note = VoiceNote(
      companyId: companyId,
      jobId: jobId,
      recordedByUserId: userId,
      durationSeconds: durationSeconds,
      tags: tags,
      recordedAt: recordedAt,
    );

    return _repo.createVoiceNote(
      note: note,
      audioBytes: audioBytes,
      fileName: fileName,
    );
  }

  Future<List<VoiceNote>> getVoiceNotesByJob(String jobId) {
    return _repo.getVoiceNotesByJob(jobId);
  }

  Future<List<VoiceNote>> getRecentNotes({int limit = 50}) {
    final userId = _authState.user?.uid;
    if (userId == null) return Future.value([]);
    return _repo.getVoiceNotesByUser(userId, limit: limit);
  }

  Future<VoiceNote> updateVoiceNote(
      String id, Map<String, dynamic> updates) {
    return _repo.updateVoiceNote(id, updates);
  }

  Future<void> deleteVoiceNote(String id) {
    return _repo.deleteVoiceNote(id);
  }

  Future<String> getAudioUrl(String storagePath) {
    return _repo.getAudioUrl(storagePath);
  }
}
