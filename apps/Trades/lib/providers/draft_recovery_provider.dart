// ZAFTO Draft Recovery Provider
// Created: Sprint DEPTH27
//
// Riverpod providers for crash recovery + zero-loss auto-save.
// Exposes DraftRecoveryService as singleton, active drafts list,
// and per-feature draft state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/draft_recovery_service.dart';

// ════════════════════════════════════════════════════════════════
// SERVICE SINGLETON
// ════════════════════════════════════════════════════════════════

final draftRecoveryServiceProvider = Provider<DraftRecoveryService>((ref) {
  return DraftRecoveryService();
});

// ════════════════════════════════════════════════════════════════
// ALL ACTIVE DRAFTS
// ════════════════════════════════════════════════════════════════

final activeDraftsProvider =
    FutureProvider.autoDispose<List<DraftRecord>>((ref) async {
  final svc = ref.read(draftRecoveryServiceProvider);
  return svc.listDrafts();
});

// ════════════════════════════════════════════════════════════════
// DRAFTS BY FEATURE
// ════════════════════════════════════════════════════════════════

final draftsByFeatureProvider =
    FutureProvider.autoDispose.family<List<DraftRecord>, String>(
  (ref, feature) async {
    final svc = ref.read(draftRecoveryServiceProvider);
    return svc.listDrafts(feature: feature);
  },
);

// ════════════════════════════════════════════════════════════════
// SINGLE DRAFT (by feature + key)
// ════════════════════════════════════════════════════════════════

final singleDraftProvider = FutureProvider.autoDispose
    .family<DraftRecord?, ({String feature, String key})>(
  (ref, params) async {
    final svc = ref.read(draftRecoveryServiceProvider);
    return svc.loadDraft(params.feature, params.key);
  },
);

// ════════════════════════════════════════════════════════════════
// DRAFT COUNT (for badge in app shell)
// ════════════════════════════════════════════════════════════════

final draftCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final svc = ref.read(draftRecoveryServiceProvider);
  return svc.listDrafts().length;
});

// ════════════════════════════════════════════════════════════════
// STORAGE USAGE
// ════════════════════════════════════════════════════════════════

final draftStorageUsageProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final svc = ref.read(draftRecoveryServiceProvider);
  return svc.getStorageBytes();
});
