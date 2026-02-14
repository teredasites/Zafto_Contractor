// ZAFTO Schedule Baselines Provider
// GC6: Riverpod providers for baseline CRUD + task snapshots.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_baseline.dart';
import '../models/schedule_baseline_task.dart';
import '../repositories/schedule_baseline_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final scheduleBaselineRepoProvider = Provider<ScheduleBaselineRepository>((ref) {
  return ScheduleBaselineRepository();
});

// ════════════════════════════════════════════════════════════════
// BASELINES BY PROJECT (.family by project_id)
// ════════════════════════════════════════════════════════════════

final scheduleBaselinesProvider =
    FutureProvider.autoDispose.family<List<ScheduleBaseline>, String>((ref, projectId) async {
  final repo = ref.read(scheduleBaselineRepoProvider);
  return repo.getBaselines(projectId);
});

// ════════════════════════════════════════════════════════════════
// ACTIVE BASELINE (.family by project_id)
// ════════════════════════════════════════════════════════════════

final scheduleActiveBaselineProvider =
    FutureProvider.autoDispose.family<ScheduleBaseline?, String>((ref, projectId) async {
  final repo = ref.read(scheduleBaselineRepoProvider);
  return repo.getActiveBaseline(projectId);
});

// ════════════════════════════════════════════════════════════════
// BASELINE TASKS (.family by baseline_id)
// ════════════════════════════════════════════════════════════════

final scheduleBaselineTasksProvider =
    FutureProvider.autoDispose.family<List<ScheduleBaselineTask>, String>((ref, baselineId) async {
  final repo = ref.read(scheduleBaselineRepoProvider);
  return repo.getBaselineTasks(baselineId);
});
