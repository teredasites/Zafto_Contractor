// ZAFTO Property Management Maintenance Repository
// Created: Property Management feature
//
// Supabase CRUD for maintenance_requests and work_order_actions tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/maintenance_request.dart';

class PmMaintenanceRepository {
  static const _requestsTable = 'maintenance_requests';
  static const _actionsTable = 'work_order_actions';

  // ============================================================
  // MAINTENANCE REQUESTS — READ
  // ============================================================

  Future<List<MaintenanceRequest>> getRequests({
    String? propertyId,
    MaintenanceStatus? status,
  }) async {
    try {
      var query = supabase.from(_requestsTable).select();
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((row) => MaintenanceRequest.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch maintenance requests: $e',
        userMessage: 'Could not load maintenance requests. Please try again.',
        cause: e,
      );
    }
  }

  Future<MaintenanceRequest?> getRequest(String id) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return MaintenanceRequest.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch maintenance request: $e',
        userMessage: 'Could not load maintenance request. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // MAINTENANCE REQUESTS — WRITE
  // ============================================================

  Future<MaintenanceRequest> createRequest(MaintenanceRequest r) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .insert(r.toInsertJson())
          .select()
          .single();
      return MaintenanceRequest.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create maintenance request: $e',
        userMessage: 'Could not create request. Please try again.',
        cause: e,
      );
    }
  }

  Future<MaintenanceRequest> updateRequest(
    String id,
    MaintenanceRequest r,
  ) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .update(r.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return MaintenanceRequest.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update maintenance request: $e',
        userMessage: 'Could not update request. Please try again.',
        cause: e,
      );
    }
  }

  Future<MaintenanceRequest> updateRequestStatus(
    String id,
    MaintenanceStatus status,
  ) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .update({'status': status.name})
          .eq('id', id)
          .select()
          .single();
      return MaintenanceRequest.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update request status: $e',
        userMessage: 'Could not update request status. Please try again.',
        cause: e,
      );
    }
  }

  Future<MaintenanceRequest> assignRequest(
    String id,
    String userId,
  ) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .update({
            'assigned_to': userId,
            'status': 'scheduled',
          })
          .eq('id', id)
          .select()
          .single();
      return MaintenanceRequest.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to assign maintenance request: $e',
        userMessage: 'Could not assign request. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // MAINTENANCE REQUESTS — QUERY BY JOB
  // ============================================================

  Future<List<MaintenanceRequest>> getRequestsForJob(String jobId) async {
    try {
      final response = await supabase
          .from(_requestsTable)
          .select()
          .eq('job_id', jobId);
      return (response as List)
          .map((row) => MaintenanceRequest.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch maintenance requests for job: $e',
        userMessage:
            'Could not load maintenance requests for this job. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> linkJobToRequest(String requestId, String jobId) async {
    try {
      await supabase
          .from(_requestsTable)
          .update({'job_id': jobId})
          .eq('id', requestId);
    } catch (e) {
      throw DatabaseError(
        'Failed to link job to maintenance request: $e',
        userMessage: 'Could not link job to request. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // WORK ORDER ACTIONS — READ
  // ============================================================

  Future<List<WorkOrderAction>> getActions(String requestId) async {
    try {
      final response = await supabase
          .from(_actionsTable)
          .select()
          .eq('maintenance_request_id', requestId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((row) => WorkOrderAction.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch work order actions: $e',
        userMessage: 'Could not load work order actions. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // WORK ORDER ACTIONS — WRITE
  // ============================================================

  Future<WorkOrderAction> addAction(WorkOrderAction a) async {
    try {
      final response = await supabase
          .from(_actionsTable)
          .insert(a.toInsertJson())
          .select()
          .single();
      return WorkOrderAction.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add work order action: $e',
        userMessage: 'Could not add action. Please try again.',
        cause: e,
      );
    }
  }
}
