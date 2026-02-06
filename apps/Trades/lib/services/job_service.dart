// ZAFTO Job Service — Supabase Backend
// Rewritten: Sprint B1c (Session 42 — crash recovery)
//
// Replaces Hive + Firestore sync with direct Supabase queries.
// Same provider names so all consuming screens keep working.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../repositories/job_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

final jobServiceProvider = Provider<JobService>((ref) {
  final repo = ref.watch(jobRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return JobService(repo, authState);
});

final jobsProvider =
    StateNotifierProvider<JobsNotifier, AsyncValue<List<Job>>>((ref) {
  final service = ref.watch(jobServiceProvider);
  return JobsNotifier(service);
});

final activeJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobsProvider);
  return jobs.maybeWhen(
    data: (list) => list.where((j) => j.isActive).toList(),
    orElse: () => [],
  );
});

final jobStatsProvider = Provider<JobStats>((ref) {
  final jobs = ref.watch(jobsProvider);
  return jobs.maybeWhen(
    data: (list) => JobStats(
      totalJobs: list.length,
      activeJobs: list.where((j) => j.isActive).length,
      completedJobs: list
          .where((j) =>
              j.status == JobStatus.completed ||
              j.status == JobStatus.invoiced)
          .length,
      totalRevenue: list
          .where((j) => j.status == JobStatus.invoiced)
          .fold(0.0, (sum, j) => sum + (j.actualAmount ?? j.estimatedAmount)),
      pendingRevenue: list
          .where((j) => j.status == JobStatus.completed)
          .fold(0.0, (sum, j) => sum + (j.actualAmount ?? j.estimatedAmount)),
    ),
    orElse: () => JobStats.empty(),
  );
});

final jobCountProvider = Provider<int>((ref) {
  final stats = ref.watch(jobStatsProvider);
  return stats.totalJobs;
});

// ============================================================
// STATS MODEL
// ============================================================

class JobStats {
  final int totalJobs;
  final int activeJobs;
  final int completedJobs;
  final double totalRevenue;
  final double pendingRevenue;

  const JobStats({
    required this.totalJobs,
    required this.activeJobs,
    required this.completedJobs,
    required this.totalRevenue,
    required this.pendingRevenue,
  });

  int get active => activeJobs;

  factory JobStats.empty() => const JobStats(
        totalJobs: 0,
        activeJobs: 0,
        completedJobs: 0,
        totalRevenue: 0,
        pendingRevenue: 0,
      );
}

// ============================================================
// JOBS NOTIFIER
// ============================================================

class JobsNotifier extends StateNotifier<AsyncValue<List<Job>>> {
  final JobService _service;

  JobsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    state = const AsyncValue.loading();
    try {
      final jobs = await _service.getAllJobs();
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addJob(Job job) async {
    try {
      await _service.createJob(job);
      await loadJobs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateJob(Job job) async {
    try {
      await _service.updateJob(job);
      await loadJobs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateJobStatus(String id, JobStatus status) async {
    try {
      await _service.updateJobStatus(id, status);
      await loadJobs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      await _service.deleteJob(id);
      await loadJobs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Job> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list
            .where((c) =>
                (c.title?.toLowerCase().contains(q) ?? false) ||
                c.customerName.toLowerCase().contains(q) ||
                c.address.toLowerCase().contains(q) ||
                (c.description?.toLowerCase().contains(q) ?? false))
            .toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// JOB SERVICE (business logic)
// ============================================================

class JobService {
  final JobRepository _repo;
  final AuthState _authState;

  JobService(this._repo, this._authState);

  Future<List<Job>> getAllJobs() => _repo.getJobs();

  Future<Job?> getJob(String id) => _repo.getJob(id);

  Future<List<Job>> getJobsByStatus(JobStatus status) =>
      _repo.getJobsByStatus(status);

  Future<List<Job>> getJobsByCustomer(String customerId) =>
      _repo.getJobsByCustomer(customerId);

  Future<Job> createJob(Job job) {
    final enriched = job.copyWith(
      companyId: _authState.companyId ?? '',
      createdByUserId: _authState.user?.uid ?? '',
    );
    return _repo.createJob(enriched);
  }

  Future<Job> updateJob(Job job) => _repo.updateJob(job.id, job);

  Future<Job> updateJobStatus(String id, JobStatus status) =>
      _repo.updateJobStatus(id, status);

  Future<void> deleteJob(String id) => _repo.deleteJob(id);

  Future<List<Job>> searchJobs(String query) => _repo.searchJobs(query);

  // Kept for backward compat.
  String generateId() => 'job_${DateTime.now().millisecondsSinceEpoch}';
}
