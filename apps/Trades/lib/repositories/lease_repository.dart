// ZAFTO Lease Repository
// Created: Property Management feature
//
// Supabase CRUD for leases and lease_documents tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property.dart';

// Lease document metadata (stored in lease_documents table)
class LeaseDocument {
  final String id;
  final String leaseId;
  final String fileName;
  final String? storagePath;
  final String? url;
  final String? documentType;
  final DateTime createdAt;

  const LeaseDocument({
    required this.id,
    required this.leaseId,
    required this.fileName,
    this.storagePath,
    this.url,
    this.documentType,
    required this.createdAt,
  });

  factory LeaseDocument.fromJson(Map<String, dynamic> json) => LeaseDocument(
    id: json['id'] as String,
    leaseId: json['lease_id'] as String,
    fileName: json['file_name'] as String? ?? 'Untitled',
    storagePath: json['storage_path'] as String?,
    url: json['url'] as String?,
    documentType: json['document_type'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class LeaseRepository {
  static const _table = 'leases';
  static const _docsTable = 'lease_documents';

  // ============================================================
  // LEASES — READ
  // ============================================================

  Future<List<Lease>> getLeases({
    String? propertyId,
    String? tenantId,
    LeaseStatus? status,
  }) async {
    try {
      var query = supabase.from(_table).select();
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((row) => Lease.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch leases: $e',
        userMessage: 'Could not load leases. Please try again.',
        cause: e,
      );
    }
  }

  Future<Lease?> getLease(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Lease.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch lease: $e',
        userMessage: 'Could not load lease. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<Lease>> getExpiringLeases(int withinDays) async {
    try {
      final now = DateTime.now().toUtc();
      final cutoff = now.add(Duration(days: withinDays));
      final response = await supabase
          .from(_table)
          .select()
          .eq('status', 'active')
          .gte('end_date', now.toIso8601String())
          .lte('end_date', cutoff.toIso8601String())
          .order('end_date', ascending: true);
      return (response as List)
          .map((row) => Lease.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch expiring leases: $e',
        userMessage: 'Could not load expiring leases. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // LEASES — WRITE
  // ============================================================

  Future<Lease> createLease(Lease l) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(l.toInsertJson())
          .select()
          .single();
      return Lease.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create lease: $e',
        userMessage: 'Could not create lease. Please try again.',
        cause: e,
      );
    }
  }

  Future<Lease> updateLease(String id, Lease l) async {
    try {
      final response = await supabase
          .from(_table)
          .update(l.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Lease.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update lease: $e',
        userMessage: 'Could not update lease. Please try again.',
        cause: e,
      );
    }
  }

  Future<Lease> terminateLease(
    String id,
    String reason,
  ) async {
    try {
      final response = await supabase
          .from(_table)
          .update({
            'status': 'terminated',
            'termination_date': DateTime.now().toUtc().toIso8601String(),
            'termination_reason': reason,
          })
          .eq('id', id)
          .select()
          .single();
      return Lease.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to terminate lease: $e',
        userMessage: 'Could not terminate lease. Please try again.',
        cause: e,
      );
    }
  }

  Future<Lease> renewLease(
    String id,
    DateTime newEndDate, {
    double? newRent,
  }) async {
    try {
      final updates = <String, dynamic>{
        'end_date': newEndDate.toUtc().toIso8601String(),
        'status': 'active',
      };
      if (newRent != null) {
        updates['rent_amount'] = newRent;
      }
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Lease.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to renew lease: $e',
        userMessage: 'Could not renew lease. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // LEASE DOCUMENTS — READ
  // ============================================================

  Future<List<LeaseDocument>> getLeaseDocuments(String leaseId) async {
    try {
      final response = await supabase
          .from(_docsTable)
          .select()
          .eq('lease_id', leaseId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => LeaseDocument.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch lease documents: $e',
        userMessage: 'Could not load lease documents. Please try again.',
        cause: e,
      );
    }
  }
}
