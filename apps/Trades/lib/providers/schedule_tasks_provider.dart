// ZAFTO Schedule Tasks Provider
// GC4: Riverpod providers for schedule tasks + dependencies.
// FutureProvider.family by project_id for reactive task loading.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_task.dart';
import '../models/schedule_dependency.dart';
import '../repositories/schedule_task_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final scheduleTaskRepoProvider = Provider<ScheduleTaskRepository>((ref) {
  return ScheduleTaskRepository();
});

// ════════════════════════════════════════════════════════════════
// TASKS BY PROJECT (.family by project_id)
// ════════════════════════════════════════════════════════════════

final scheduleTasksProvider =
    FutureProvider.autoDispose.family<List<ScheduleTask>, String>((ref, projectId) async {
  final repo = ref.read(scheduleTaskRepoProvider);
  return repo.getTasksForProject(projectId);
});

// ════════════════════════════════════════════════════════════════
// SINGLE TASK
// ════════════════════════════════════════════════════════════════

final scheduleTaskProvider =
    FutureProvider.autoDispose.family<ScheduleTask?, String>((ref, taskId) async {
  final repo = ref.read(scheduleTaskRepoProvider);
  return repo.getTask(taskId);
});

// ════════════════════════════════════════════════════════════════
// CRITICAL TASKS (.family by project_id)
// ════════════════════════════════════════════════════════════════

final scheduleCriticalTasksProvider =
    FutureProvider.autoDispose.family<List<ScheduleTask>, String>((ref, projectId) async {
  final repo = ref.read(scheduleTaskRepoProvider);
  return repo.getCriticalTasks(projectId);
});

// ════════════════════════════════════════════════════════════════
// DEPENDENCIES BY PROJECT (.family by project_id)
// ════════════════════════════════════════════════════════════════

final scheduleDependenciesProvider =
    FutureProvider.autoDispose.family<List<ScheduleDependency>, String>((ref, projectId) async {
  final repo = ref.read(scheduleTaskRepoProvider);
  return repo.getDependencies(projectId);
});
