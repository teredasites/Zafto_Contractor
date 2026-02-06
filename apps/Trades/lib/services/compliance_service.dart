// ZAFTO Compliance Service — Supabase Backend
// Providers, notifier, and service for compliance/safety records.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/compliance_record.dart';
import '../repositories/compliance_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final complianceRepositoryProvider = Provider<ComplianceRepository>((ref) {
  return ComplianceRepository();
});

final complianceServiceProvider = Provider<ComplianceService>((ref) {
  final repo = ref.watch(complianceRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ComplianceService(repo, authState);
});

// Records for a specific job — auto-dispose when screen closes.
final jobComplianceProvider = StateNotifierProvider.autoDispose
    .family<JobComplianceNotifier, AsyncValue<List<ComplianceRecord>>, String>(
  (ref, jobId) {
    final service = ref.watch(complianceServiceProvider);
    return JobComplianceNotifier(service, jobId);
  },
);

// Records filtered by type (company-wide).
final complianceByTypeProvider = FutureProvider.autoDispose
    .family<List<ComplianceRecord>, ComplianceRecordType>(
  (ref, type) async {
    final repo = ref.watch(complianceRepositoryProvider);
    return repo.getRecordsByType(type);
  },
);

// Recent records across all jobs.
final recentComplianceProvider =
    FutureProvider.autoDispose<List<ComplianceRecord>>(
  (ref) async {
    final repo = ref.watch(complianceRepositoryProvider);
    return repo.getRecentRecords(limit: 50);
  },
);

// --- Job Compliance Notifier ---

class JobComplianceNotifier
    extends StateNotifier<AsyncValue<List<ComplianceRecord>>> {
  final ComplianceService _service;
  final String _jobId;

  JobComplianceNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _service.getRecordsByJob(_jobId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<ComplianceRecord> filterByType(ComplianceRecordType type) {
    return state.valueOrNull
            ?.where((r) => r.recordType == type)
            .toList() ??
        [];
  }
}

// --- Service ---

class ComplianceService {
  final ComplianceRepository _repo;
  final AuthState _authState;

  ComplianceService(this._repo, this._authState);

  // Create a compliance record, enriching with auth context.
  Future<ComplianceRecord> createRecord({
    required ComplianceRecordType type,
    String? jobId,
    required Map<String, dynamic> data,
    List<String> crewMembers = const [],
    String? severity,
    double? latitude,
    double? longitude,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to save records.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final record = ComplianceRecord(
      companyId: companyId,
      jobId: jobId,
      createdByUserId: userId,
      recordType: type,
      data: data,
      crewMembers: crewMembers,
      severity: severity,
      locationLatitude: latitude,
      locationLongitude: longitude,
      startedAt: startedAt,
      endedAt: endedAt,
      createdAt: DateTime.now(),
    );

    return _repo.createRecord(record);
  }

  Future<List<ComplianceRecord>> getRecordsByJob(String jobId) {
    return _repo.getRecordsByJob(jobId);
  }

  Future<List<ComplianceRecord>> getRecordsByType(
      ComplianceRecordType type) {
    return _repo.getRecordsByType(type);
  }

  Future<List<ComplianceRecord>> getRecordsByJobAndType(
      String jobId, ComplianceRecordType type) {
    return _repo.getRecordsByJobAndType(jobId, type);
  }

  Future<List<ComplianceRecord>> getRecentRecords({int limit = 50}) {
    return _repo.getRecentRecords(limit: limit);
  }
}
