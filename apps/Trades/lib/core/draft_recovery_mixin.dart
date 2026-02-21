import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_recovery_provider.dart';
import '../services/draft_recovery_service.dart';

// ============================================================
// DraftRecoveryMixin — DEPTH27
//
// Mixin for any ConsumerStatefulWidget to add auto-save/restore.
// Subclass must implement serializeDraftState() and
// restoreDraftState(Map<String, dynamic>).
//
// Usage:
//   class _BidScreenState extends ConsumerState<BidScreen>
//       with DraftRecoveryMixin {
//
//     @override String get draftFeature => 'bid';
//     @override String get draftKey => widget.bidId ?? 'new';
//     @override String get draftScreenRoute => '/bids/${widget.bidId ?? "new"}';
//
//     @override
//     Map<String, dynamic> serializeDraftState() => {
//       'title': _title,
//       'amount': _amount,
//     };
//
//     @override
//     void restoreDraftState(Map<String, dynamic> state) {
//       setState(() {
//         _title = state['title'] as String? ?? '';
//         _amount = state['amount'] as double? ?? 0;
//       });
//     }
//   }
// ============================================================

mixin DraftRecoveryMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Timer? _autoSaveTimer;
  bool _draftRestored = false;
  bool _hasPendingChanges = false;

  /// Feature category (e.g., 'bid', 'invoice', 'sketch', 'walkthrough')
  String get draftFeature;

  /// Unique key within feature (e.g., ID or 'new')
  String get draftKey;

  /// Screen route for display in recovery UI
  String get draftScreenRoute;

  /// Auto-save interval (default 3 seconds)
  Duration get autoSaveInterval => const Duration(seconds: 3);

  /// Serialize current screen state to JSON map
  Map<String, dynamic> serializeDraftState();

  /// Restore screen state from JSON map
  void restoreDraftState(Map<String, dynamic> state);

  DraftRecoveryService get _service =>
      ref.read(draftRecoveryServiceProvider);

  @override
  void initState() {
    super.initState();
    // Auto-restore on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryRestore();
    });
    // Start auto-save timer
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (_) {
      if (_hasPendingChanges) {
        _saveDraft();
        _hasPendingChanges = false;
      }
    });
  }

  @override
  void dispose() {
    // Final save before dispose
    if (_hasPendingChanges) {
      _saveDraft();
    }
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Call this whenever state changes to mark as dirty
  void markDraftDirty() {
    _hasPendingChanges = true;
  }

  /// Force immediate save (e.g., before navigating away)
  Future<void> forceSaveDraft() async {
    await _saveDraft();
    _hasPendingChanges = false;
  }

  /// Discard the current draft
  Future<void> discardDraft() async {
    await _service.deleteDraft(draftFeature, draftKey);
  }

  /// Check if a draft exists for this feature+key
  Future<bool> hasDraft() async {
    final draft = await _service.loadDraft(draftFeature, draftKey);
    return draft != null;
  }

  Future<void> _saveDraft() async {
    try {
      final state = serializeDraftState();
      await _service.saveDraft(
        draftFeature,
        draftKey,
        draftScreenRoute,
        state,
      );
    } catch (_) {
      // Silently fail — don't disrupt user
    }
  }

  Future<void> _tryRestore() async {
    if (_draftRestored) return;
    _draftRestored = true;

    try {
      final draft = await _service.loadDraft(draftFeature, draftKey);
      if (draft != null && mounted) {
        restoreDraftState(draft.stateJson);
      }
    } catch (_) {
      // Silently fail — user starts fresh
    }
  }
}
