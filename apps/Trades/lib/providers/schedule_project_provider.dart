// ZAFTO Schedule Project Provider
// GC4: Riverpod providers for schedule project state management.
// Repository = Provider (singleton). Data = FutureProvider.autoDispose (reactive).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_project.dart';
import '../repositories/schedule_project_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final scheduleProjectRepoProvider = Provider<ScheduleProjectRepository>((ref) {
  return ScheduleProjectRepository();
});

// ════════════════════════════════════════════════════════════════
// ALL PROJECTS
// ════════════════════════════════════════════════════════════════

final scheduleProjectsProvider =
    FutureProvider.autoDispose<List<ScheduleProject>>((ref) async {
  final repo = ref.read(scheduleProjectRepoProvider);
  return repo.getProjects();
});

// ════════════════════════════════════════════════════════════════
// SINGLE PROJECT (.family by project ID)
// ════════════════════════════════════════════════════════════════

final scheduleProjectProvider =
    FutureProvider.autoDispose.family<ScheduleProject?, String>((ref, projectId) async {
  final repo = ref.read(scheduleProjectRepoProvider);
  return repo.getProject(projectId);
});

// ════════════════════════════════════════════════════════════════
// PROJECTS BY JOB (.family by job ID)
// ════════════════════════════════════════════════════════════════

final scheduleProjectsByJobProvider =
    FutureProvider.autoDispose.family<List<ScheduleProject>, String>((ref, jobId) async {
  final repo = ref.read(scheduleProjectRepoProvider);
  return repo.getProjectsForJob(jobId);
});
