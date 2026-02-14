// ZAFTO Schedule Resources Provider
// GC4: Riverpod providers for schedule resources + task assignments.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_resource.dart';
import '../models/schedule_task_resource.dart';
import '../repositories/schedule_resource_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final scheduleResourceRepoProvider = Provider<ScheduleResourceRepository>((ref) {
  return ScheduleResourceRepository();
});

// ════════════════════════════════════════════════════════════════
// ALL RESOURCES
// ════════════════════════════════════════════════════════════════

final scheduleResourcesProvider =
    FutureProvider.autoDispose<List<ScheduleResource>>((ref) async {
  final repo = ref.read(scheduleResourceRepoProvider);
  return repo.getResources();
});

// ════════════════════════════════════════════════════════════════
// RESOURCES BY TYPE (.family by type string)
// ════════════════════════════════════════════════════════════════

final scheduleResourcesByTypeProvider =
    FutureProvider.autoDispose.family<List<ScheduleResource>, String>((ref, type) async {
  final repo = ref.read(scheduleResourceRepoProvider);
  return repo.getResourcesByType(type);
});

// ════════════════════════════════════════════════════════════════
// TASK RESOURCES (.family by task_id)
// ════════════════════════════════════════════════════════════════

final scheduleTaskResourcesProvider =
    FutureProvider.autoDispose.family<List<ScheduleTaskResource>, String>((ref, taskId) async {
  final repo = ref.read(scheduleResourceRepoProvider);
  return repo.getTaskResources(taskId);
});
