// ZAFTO Daily Log Service — Supabase Backend
// Providers, notifier, and auth-enriched service for daily job logs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/daily_log.dart';
import '../repositories/daily_log_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository();
});

final dailyLogServiceProvider = Provider<DailyLogService>((ref) {
  final repo = ref.watch(dailyLogRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return DailyLogService(repo, authState);
});

// Logs for a job — auto-dispose when screen closes.
final jobDailyLogsProvider = StateNotifierProvider.autoDispose
    .family<JobDailyLogsNotifier, AsyncValue<List<DailyLog>>, String>(
  (ref, jobId) {
    final service = ref.watch(dailyLogServiceProvider);
    return JobDailyLogsNotifier(service, jobId);
  },
);

// Today's log for a job.
final todaysLogProvider = FutureProvider.autoDispose
    .family<DailyLog?, String>((ref, jobId) async {
  final service = ref.watch(dailyLogServiceProvider);
  return service.getTodaysLog(jobId);
});

// --- Job Daily Logs Notifier ---

class JobDailyLogsNotifier
    extends StateNotifier<AsyncValue<List<DailyLog>>> {
  final DailyLogService _service;
  final String _jobId;

  JobDailyLogsNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _service.getLogsByJob(_jobId);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  int get logCount => state.valueOrNull?.length ?? 0;
}

// --- Service ---

class DailyLogService {
  final DailyLogRepository _repo;
  final AuthState _authState;

  DailyLogService(this._repo, this._authState);

  // Create a daily log, enriching with auth context.
  Future<DailyLog> createLog({
    required String jobId,
    required DateTime logDate,
    required String summary,
    String? weather,
    int? temperatureF,
    String? workPerformed,
    String? issues,
    String? delays,
    String? visitors,
    int crewCount = 1,
    double? hoursWorked,
    String? safetyNotes,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to create a log.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final log = DailyLog(
      companyId: companyId,
      jobId: jobId,
      authorUserId: userId,
      logDate: logDate,
      weather: weather,
      temperatureF: temperatureF,
      summary: summary,
      workPerformed: workPerformed,
      issues: issues,
      delays: delays,
      visitors: visitors,
      crewCount: crewCount,
      hoursWorked: hoursWorked,
      safetyNotes: safetyNotes,
    );

    return _repo.createLog(log);
  }

  Future<List<DailyLog>> getLogsByJob(String jobId) {
    return _repo.getLogsByJob(jobId);
  }

  Future<DailyLog?> getTodaysLog(String jobId) {
    return _repo.getTodaysLog(jobId);
  }

  Future<DailyLog> updateLog(String id, Map<String, dynamic> updates) {
    return _repo.updateLog(id, updates);
  }

  Future<DailyLog> saveLog(DailyLog log) {
    return _repo.upsertLog(log);
  }
}
