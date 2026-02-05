/// ZAFTO Job Service - Offline-First with Cloud Sync
/// Sprint 7.0 - January 2026

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/business/job.dart';
import 'business_firestore_service.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final jobServiceProvider = Provider<JobService>((ref) {
  final businessFirestore = ref.watch(businessFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  return JobService(businessFirestore, authState);
});

final jobsProvider = StateNotifierProvider<JobsNotifier, AsyncValue<List<Job>>>((ref) {
  final service = ref.watch(jobServiceProvider);
  return JobsNotifier(service, ref);
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
      completedJobs: list.where((j) => 
        j.status == JobStatus.completed || j.status == JobStatus.invoiced
      ).length,
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

/// Sync status for jobs
final jobSyncStatusProvider = StateProvider<JobSyncStatus>((ref) => JobSyncStatus.idle);

enum JobSyncStatus { idle, syncing, synced, error, offline }

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

  /// Alias for activeJobs
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
  final Ref _ref;

  JobsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    state = const AsyncValue.loading();
    try {
      final jobs = await _service.getAllJobs();
      state = AsyncValue.data(jobs);
      
      // Try to sync with cloud in background
      _syncInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncInBackground() async {
    try {
      _ref.read(jobSyncStatusProvider.notifier).state = JobSyncStatus.syncing;
      await _service.syncWithCloud();
      
      // Reload after sync
      final jobs = await _service.getAllJobs();
      state = AsyncValue.data(jobs);
      
      _ref.read(jobSyncStatusProvider.notifier).state = JobSyncStatus.synced;
    } catch (e) {
      _ref.read(jobSyncStatusProvider.notifier).state = JobSyncStatus.error;
    }
  }

  Future<void> addJob(Job job) async {
    await _service.saveJob(job);
    await loadJobs();
  }

  Future<void> updateJob(Job job) async {
    await _service.saveJob(job);
    await loadJobs();
  }

  Future<void> deleteJob(String id) async {
    await _service.deleteJob(id);
    await loadJobs();
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }
}

// ============================================================
// JOB SERVICE
// ============================================================

class JobService {
  static const _boxName = 'jobs';
  static const _syncMetaBox = 'jobs_sync_meta';
  
  final BusinessFirestoreService _cloudService;
  final AuthState _authState;

  JobService(this._cloudService, this._authState);

  bool get _isLoggedIn => _authState.isAuthenticated && _authState.hasCompany;

  // ==================== LOCAL STORAGE ====================

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  Future<Box<String>> _getSyncMetaBox() async {
    if (!Hive.isBoxOpen(_syncMetaBox)) {
      return await Hive.openBox<String>(_syncMetaBox);
    }
    return Hive.box<String>(_syncMetaBox);
  }

  /// Get all jobs from local storage
  Future<List<Job>> getAllJobs() async {
    final box = await _getBox();
    final jobs = <Job>[];
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          jobs.add(Job.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
    }
    
    jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return jobs;
  }

  /// Get a single job
  Future<Job?> getJob(String id) async {
    final box = await _getBox();
    final json = box.get(id);
    if (json == null) return null;
    return Job.fromJson(jsonDecode(json));
  }

  /// Save job locally (and queue for cloud sync)
  Future<void> saveJob(Job job) async {
    final box = await _getBox();
    
    // Mark as needing sync
    final jobWithSync = job.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await box.put(job.id, jsonEncode(jobWithSync.toJson()));
    
    // Mark for sync
    await _markForSync(job.id);
    
    // Try immediate cloud sync if online
    if (_isLoggedIn) {
      _trySyncJob(jobWithSync);
    }
  }

  /// Delete job locally (and queue deletion for cloud)
  Future<void> deleteJob(String id) async {
    final box = await _getBox();
    await box.delete(id);
    
    // Mark deletion for sync
    await _markDeletionForSync(id);
    
    // Try immediate cloud delete if online
    if (_isLoggedIn) {
      try {
        await _cloudService.deleteJob(id);
      } catch (_) {}
    }
  }

  String generateId() => 'job_${DateTime.now().millisecondsSinceEpoch}';

  // ==================== SYNC OPERATIONS ====================

  /// Mark a job as needing sync
  Future<void> _markForSync(String jobId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$jobId', DateTime.now().toIso8601String());
  }

  /// Mark a job deletion for sync
  Future<void> _markDeletionForSync(String jobId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('delete_$jobId', DateTime.now().toIso8601String());
    await metaBox.delete('pending_$jobId');
  }

  /// Try to sync a single job immediately
  Future<void> _trySyncJob(Job job) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      // Check if this is a new job or update
      final existing = await _cloudService.getJob(job.id);
      if (existing == null) {
        await _cloudService.createJob(job);
      } else {
        await _cloudService.updateJob(job);
      }
      
      // Clear sync marker
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_${job.id}');
    } catch (_) {
      // Sync failed - will retry later
    }
  }

  /// Full sync with cloud
  Future<void> syncWithCloud() async {
    if (!_isLoggedIn) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    final metaBox = await _getSyncMetaBox();
    final localBox = await _getBox();

    // 1. Process pending deletions
    final deleteKeys = metaBox.keys.where((k) => k.toString().startsWith('delete_'));
    for (final key in deleteKeys) {
      final jobId = key.toString().replaceFirst('delete_', '');
      try {
        await _cloudService.deleteJob(jobId);
        await metaBox.delete(key);
      } catch (_) {}
    }

    // 2. Push pending local changes to cloud
    final pendingKeys = metaBox.keys.where((k) => k.toString().startsWith('pending_'));
    for (final key in pendingKeys) {
      final jobId = key.toString().replaceFirst('pending_', '');
      final localJson = localBox.get(jobId);
      if (localJson != null) {
        try {
          final job = Job.fromJson(jsonDecode(localJson));
          final existing = await _cloudService.getJob(jobId);
          if (existing == null) {
            await _cloudService.createJob(job);
          } else {
            await _cloudService.updateJob(job);
          }
          await metaBox.delete(key);
        } catch (_) {}
      }
    }

    // 3. Pull cloud changes
    final lastSyncStr = metaBox.get('lastSync');
    final lastSync = lastSyncStr != null 
        ? DateTime.parse(lastSyncStr) 
        : DateTime.fromMillisecondsSinceEpoch(0);

    final cloudJobs = await _cloudService.getJobsUpdatedSince(lastSync);
    
    for (final cloudJob in cloudJobs) {
      final localJson = localBox.get(cloudJob.id);
      if (localJson != null) {
        // Conflict resolution: cloud wins if updated more recently
        final localJob = Job.fromJson(jsonDecode(localJson));
        if (cloudJob.updatedAt.isAfter(localJob.updatedAt)) {
          await localBox.put(cloudJob.id, jsonEncode(cloudJob.toJson()));
        }
      } else {
        // New from cloud
        await localBox.put(cloudJob.id, jsonEncode(cloudJob.toJson()));
      }
    }

    // 4. Update last sync time
    await metaBox.put('lastSync', DateTime.now().toIso8601String());
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final metaBox = await _getSyncMetaBox();
    return metaBox.keys
        .where((k) => k.toString().startsWith('pending_') || k.toString().startsWith('delete_'))
        .length;
  }
}
