// ZAFTO Property Scan Repository
// Created: Phase P — Sprint P7
//
// CRUD for property scans + related data (roof, walls, trades, lead scores).
// Calls recon Edge Functions for scan execution.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property_scan.dart';

class PropertyScanRepository {
  SupabaseClient get _client => supabase;

  // ════════════════════════════════════════════════════════════════
  // PROPERTY SCANS
  // ════════════════════════════════════════════════════════════════

  /// Get all scans for the current company
  Future<List<PropertyScan>> getScans({int limit = 50}) async {
    try {
      final res = await _client
          .from('property_scans')
          .select('*')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List).map((r) => PropertyScan.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load property scans', cause: e);
    }
  }

  /// Get a single scan by ID
  Future<PropertyScan?> getScan(String scanId) async {
    try {
      final res = await _client
          .from('property_scans')
          .select('*')
          .eq('id', scanId)
          .maybeSingle();

      return res != null ? PropertyScan.fromJson(res) : null;
    } catch (e) {
      throw DatabaseError('Failed to load scan', cause: e);
    }
  }

  /// Get scan by job ID (most recent)
  Future<PropertyScan?> getScanByJobId(String jobId) async {
    try {
      final res = await _client
          .from('property_scans')
          .select('*')
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return res != null ? PropertyScan.fromJson(res) : null;
    } catch (e) {
      throw DatabaseError('Failed to load scan for job', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ROOF MEASUREMENTS
  // ════════════════════════════════════════════════════════════════

  /// Get roof measurement for a scan
  Future<RoofMeasurement?> getRoofMeasurement(String scanId) async {
    try {
      final res = await _client
          .from('roof_measurements')
          .select('*')
          .eq('scan_id', scanId)
          .limit(1)
          .maybeSingle();

      return res != null ? RoofMeasurement.fromJson(res) : null;
    } catch (e) {
      throw DatabaseError('Failed to load roof measurement', cause: e);
    }
  }

  /// Get facets for a roof measurement
  Future<List<RoofFacet>> getRoofFacets(String roofMeasurementId) async {
    try {
      final res = await _client
          .from('roof_facets')
          .select('*')
          .eq('roof_measurement_id', roofMeasurementId)
          .order('facet_number');

      return (res as List).map((r) => RoofFacet.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load roof facets', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // WALL MEASUREMENTS
  // ════════════════════════════════════════════════════════════════

  /// Get wall measurement for a scan
  Future<WallMeasurement?> getWallMeasurement(String scanId) async {
    try {
      final res = await _client
          .from('wall_measurements')
          .select('*')
          .eq('scan_id', scanId)
          .limit(1)
          .maybeSingle();

      return res != null ? WallMeasurement.fromJson(res) : null;
    } catch (e) {
      throw DatabaseError('Failed to load wall measurement', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TRADE BID DATA
  // ════════════════════════════════════════════════════════════════

  /// Get all trade bids for a scan
  Future<List<TradeBidData>> getTradeBids(String scanId) async {
    try {
      final res = await _client
          .from('trade_bid_data')
          .select('*')
          .eq('scan_id', scanId)
          .order('trade');

      return (res as List).map((r) => TradeBidData.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load trade bids', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // LEAD SCORES
  // ════════════════════════════════════════════════════════════════

  /// Get lead score for a scan
  Future<PropertyLeadScore?> getLeadScore(String scanId) async {
    try {
      final res = await _client
          .from('property_lead_scores')
          .select('*')
          .eq('property_scan_id', scanId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return res != null ? PropertyLeadScore.fromJson(res) : null;
    } catch (e) {
      throw DatabaseError('Failed to load lead score', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SCAN HISTORY
  // ════════════════════════════════════════════════════════════════

  /// Get history for a scan
  Future<List<ScanHistoryEntry>> getScanHistory(String scanId) async {
    try {
      final res = await _client
          .from('scan_history')
          .select('*')
          .eq('scan_id', scanId)
          .order('performed_at', ascending: false)
          .limit(50);

      return (res as List).map((r) => ScanHistoryEntry.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load scan history', cause: e);
    }
  }

  /// Log a history entry
  Future<void> logHistory({
    required String scanId,
    required String action,
    String? fieldChanged,
    String? oldValue,
    String? newValue,
    String device = 'mobile',
    String? notes,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      await _client.from('scan_history').insert({
        'company_id': companyId,
        'scan_id': scanId,
        'action': action,
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'performed_by': user.id,
        'device': device,
        'notes': notes,
      });
    } catch (_) {
      // History logging is non-critical — don't throw
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ON-SITE VERIFICATION
  // ════════════════════════════════════════════════════════════════

  /// Verify or adjust a measurement field on-site
  Future<void> verifyMeasurement({
    required String scanId,
    required String field,
    required String oldValue,
    required String newValue,
    bool isAdjustment = false,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw AuthError('Not authenticated');

      // Log history
      await logHistory(
        scanId: scanId,
        action: isAdjustment ? 'adjusted' : 'verified',
        fieldChanged: field,
        oldValue: oldValue,
        newValue: newValue,
        device: 'mobile',
      );

      // Update verification status on scan
      await _client.from('property_scans').update({
        'verification_status': isAdjustment ? 'adjusted' : 'verified',
        'verified_by': user.id,
        'verified_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', scanId);

      // If adjusting, update the actual measurement field
      if (isAdjustment && oldValue != newValue) {
        // Determine which table to update based on field prefix
        if (field.startsWith('roof_')) {
          final dbField = field.replaceFirst('roof_', '');
          await _client
              .from('roof_measurements')
              .update({dbField: newValue})
              .eq('scan_id', scanId);
        } else if (field.startsWith('wall_')) {
          final dbField = field.replaceFirst('wall_', '');
          await _client
              .from('wall_measurements')
              .update({dbField: newValue})
              .eq('scan_id', scanId);
        }

        // Boost confidence score on verification (+10)
        final scan = await getScan(scanId);
        if (scan != null) {
          final newConf = (scan.confidenceScore + 10).clamp(0, 100);
          await _client.from('property_scans').update({
            'confidence_score': newConf,
          }).eq('id', scanId);
        }
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to verify measurement', cause: e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TRIGGER SCAN (Edge Function)
  // ════════════════════════════════════════════════════════════════

  /// Trigger a new property scan via Edge Function
  Future<String?> triggerScan({
    required String address,
    String? jobId,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw AuthError('Not authenticated');

      final url = Uri.parse('${envConfig.supabaseUrl}/functions/v1/recon-property-lookup');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'address': address,
          if (jobId != null) 'job_id': jobId,
        }),
      );

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        throw DatabaseError(body['error'] as String? ?? 'Scan failed');
      }

      final body = jsonDecode(res.body);
      return body['scan_id'] as String?;
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to trigger scan', cause: e);
    }
  }

  /// Trigger lead score computation via Edge Function
  Future<void> triggerLeadScore(String scanId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return;

      final url = Uri.parse('${envConfig.supabaseUrl}/functions/v1/recon-lead-score');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'property_scan_id': scanId}),
      );
    } catch (_) {
      // Non-critical
    }
  }
}
