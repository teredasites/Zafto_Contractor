// ZAFTO Punch List Service — Supabase Backend
// Providers, notifier, and auth-enriched service for punch list items.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/punch_list_item.dart';
import '../repositories/punch_list_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final punchListRepositoryProvider = Provider<PunchListRepository>((ref) {
  return PunchListRepository();
});

final punchListServiceProvider = Provider<PunchListService>((ref) {
  final repo = ref.watch(punchListRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return PunchListService(repo, authState);
});

// Punch list items for a job — auto-dispose when screen closes.
final jobPunchListProvider = StateNotifierProvider.autoDispose
    .family<PunchListNotifier, AsyncValue<List<PunchListItem>>, String>(
  (ref, jobId) {
    final service = ref.watch(punchListServiceProvider);
    return PunchListNotifier(service, jobId);
  },
);

// --- Punch List Notifier ---

class PunchListNotifier
    extends StateNotifier<AsyncValue<List<PunchListItem>>> {
  final PunchListService _service;
  final String _jobId;

  PunchListNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getItemsByJob(_jobId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  int get totalCount => state.valueOrNull?.length ?? 0;

  int get completedCount =>
      state.valueOrNull?.where((i) => i.isDone).length ?? 0;

  int get openCount =>
      state.valueOrNull?.where((i) => !i.isDone).length ?? 0;

  double get progressPercent {
    final total = totalCount;
    if (total == 0) return 0;
    return completedCount / total;
  }
}

// --- Service ---

class PunchListService {
  final PunchListRepository _repo;
  final AuthState _authState;

  PunchListService(this._repo, this._authState);

  // Create a punch list item, enriching with auth context.
  Future<PunchListItem> createItem({
    required String jobId,
    required String title,
    String? description,
    String? category,
    PunchListPriority priority = PunchListPriority.normal,
    String? assignedToUserId,
    DateTime? dueDate,
    int sortOrder = 0,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to add tasks.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final item = PunchListItem(
      companyId: companyId,
      jobId: jobId,
      createdByUserId: userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      assignedToUserId: assignedToUserId,
      dueDate: dueDate,
      sortOrder: sortOrder,
    );

    return _repo.createItem(item);
  }

  Future<List<PunchListItem>> getItemsByJob(String jobId) {
    return _repo.getItemsByJob(jobId);
  }

  Future<PunchListItem> completeItem(String itemId) {
    final userId = _authState.user?.uid;
    if (userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return _repo.completeItem(itemId, userId);
  }

  Future<PunchListItem> reopenItem(String itemId) {
    return _repo.reopenItem(itemId);
  }

  Future<PunchListItem> updateItem(
      String id, Map<String, dynamic> updates) {
    return _repo.updateItem(id, updates);
  }

  Future<void> deleteItem(String id) {
    return _repo.deleteItem(id);
  }

  Future<({int total, int completed})> getProgress(String jobId) {
    return _repo.getProgress(jobId);
  }
}
