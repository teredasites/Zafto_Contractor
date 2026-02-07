// ZAFTO PM Maintenance Service — Property Management
// Created: Property Management Feature
//
// THE MOAT: When a property owner sees a maintenance request,
// they can "Handle It" themselves — creating a job from the
// request, linking everything, and starting time tracking.
// This is the key differentiator for contractor-owned properties.
//
// Providers: pmMaintenanceRepositoryProvider, pmMaintenanceServiceProvider,
//   maintenanceRequestsProvider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../models/maintenance_request.dart';
import '../models/job.dart';
import '../repositories/pm_maintenance_repository.dart';
import '../repositories/job_repository.dart';
import 'auth_service.dart';
import 'job_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final pmMaintenanceRepositoryProvider =
    Provider<PmMaintenanceRepository>((ref) {
  return PmMaintenanceRepository();
});

final pmMaintenanceServiceProvider = Provider<PmMaintenanceService>((ref) {
  final repo = ref.watch(pmMaintenanceRepositoryProvider);
  final jobRepo = ref.watch(jobRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return PmMaintenanceService(repo, jobRepo, authState);
});

final maintenanceRequestsProvider = StateNotifierProvider<
    MaintenanceRequestsNotifier,
    AsyncValue<List<MaintenanceRequest>>>((ref) {
  final service = ref.watch(pmMaintenanceServiceProvider);
  return MaintenanceRequestsNotifier(service);
});

// ============================================================
// PM MAINTENANCE SERVICE (business logic)
// ============================================================

class PmMaintenanceService {
  final PmMaintenanceRepository _repo;
  final JobRepository _jobRepo;
  final AuthState _authState;

  PmMaintenanceService(this._repo, this._jobRepo, this._authState);

  // Standard CRUD
  Future<List<MaintenanceRequest>> getRequests({String? propertyId}) =>
      _repo.getRequests(propertyId: propertyId);

  Future<MaintenanceRequest?> getRequest(String id) => _repo.getRequest(id);

  Future<MaintenanceRequest> createRequest(MaintenanceRequest request) {
    final enriched = request.copyWith(
      companyId: _authState.companyId ?? '',
    );
    return _repo.createRequest(enriched);
  }

  Future<MaintenanceRequest> updateRequest(
          String id, MaintenanceRequest request) =>
      _repo.updateRequest(id, request);

  Future<void> updateRequestStatus(
          String id, MaintenanceStatus status) =>
      _repo.updateRequestStatus(id, status);

  Future<void> deleteRequest(String id) =>
      _repo.updateRequestStatus(id, MaintenanceStatus.cancelled);

  // Work order actions
  Future<List<WorkOrderAction>> getActions(String requestId) =>
      _repo.getActions(requestId);

  // ============================================================
  // THE MOAT: "I'll Handle It"
  // ============================================================
  //
  // Creates a job from a maintenance request, links property +
  // unit, auto-assigns to current user. The contractor who owns
  // the property handles the repair themselves — no vendor needed.
  //
  Future<Job> handleItMyself(String requestId) async {
    final request = await _repo.getRequest(requestId);
    if (request == null) {
      throw const DatabaseError(
        'Request not found',
        userMessage: 'Maintenance request not found.',
      );
    }

    // Create a job from the request
    final job = Job(
      id: '',
      companyId: _authState.companyId ?? '',
      title: 'Maintenance: ${request.title}',
      description: request.description,
      status: JobStatus.inProgress,
      jobType: JobType.standard,
      propertyId: request.propertyId,
      unitId: request.unitId,
      maintenanceRequestId: request.id,
      assignedUserIds: [_authState.user?.uid ?? ''],
      createdByUserId: _authState.user?.uid ?? '',
      estimatedAmount: request.estimatedCost ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final created = await _jobRepo.createJob(job);

    // Update request: link job, set status to in_progress
    await _repo.updateRequestStatus(requestId, MaintenanceStatus.inProgress);

    // Link job to maintenance request
    await _repo.linkJobToRequest(requestId, created.id);

    // Add work order action
    await _repo.addAction(WorkOrderAction(
      id: '',
      maintenanceRequestId: requestId,
      actionType: WorkOrderActionType.started,
      performedBy: _authState.user?.uid ?? '',
      details: 'Owner handling: Job ${created.id} created',
      createdAt: DateTime.now(),
    ));

    return created;
  }

  // ============================================================
  // VENDOR ASSIGNMENT
  // ============================================================

  // Assign a maintenance request to an external vendor
  Future<void> assignToVendor(String requestId, String vendorId) async {
    await _repo.assignRequest(requestId, vendorId);
    await _repo.addAction(WorkOrderAction(
      id: '',
      maintenanceRequestId: requestId,
      actionType: WorkOrderActionType.assigned,
      performedBy: _authState.user?.uid ?? '',
      details: 'Assigned to vendor $vendorId',
      createdAt: DateTime.now(),
    ));
  }

  // ============================================================
  // REQUEST COMPLETION
  // ============================================================

  // Mark a maintenance request as completed
  Future<void> completeRequest(String requestId, {String? notes}) async {
    await _repo.updateRequestStatus(requestId, MaintenanceStatus.completed);
    await _repo.addAction(WorkOrderAction(
      id: '',
      maintenanceRequestId: requestId,
      actionType: WorkOrderActionType.completed,
      performedBy: _authState.user?.uid ?? '',
      details: notes ?? 'Request completed',
      createdAt: DateTime.now(),
    ));
  }

  // ============================================================
  // JOB COMPLETION → MAINTENANCE REQUEST UPDATE
  // ============================================================

  // Wire: job completion → update linked maintenance request
  Future<void> completeMaintenanceJob(String jobId) async {
    // Find maintenance request linked to this job
    final requests = await _repo.getRequestsForJob(jobId);
    if (requests.isEmpty) return;

    for (final req in requests) {
      await _repo.updateRequestStatus(req.id, MaintenanceStatus.completed);
      await _repo.addAction(WorkOrderAction(
        id: '',
        maintenanceRequestId: req.id,
        actionType: WorkOrderActionType.completed,
        performedBy: _authState.user?.uid ?? '',
        details: 'Job $jobId completed — maintenance request auto-closed',
        createdAt: DateTime.now(),
      ));
    }
  }
}

// ============================================================
// MAINTENANCE REQUESTS NOTIFIER
// ============================================================

class MaintenanceRequestsNotifier
    extends StateNotifier<AsyncValue<List<MaintenanceRequest>>> {
  final PmMaintenanceService _service;

  MaintenanceRequestsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _service.getRequests();
      state = AsyncValue.data(requests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(MaintenanceRequest request) async {
    try {
      await _service.createRequest(request);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(String id, MaintenanceRequest request) async {
    try {
      await _service.updateRequest(id, request);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, MaintenanceStatus status) async {
    try {
      await _service.updateRequestStatus(id, status);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> handleIt(String requestId) async {
    try {
      await _service.handleItMyself(requestId);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> assignVendor(String requestId, String vendorId) async {
    try {
      await _service.assignToVendor(requestId, vendorId);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.deleteRequest(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
