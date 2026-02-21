// ZAFTO Property Intelligence Repository
// Created: DEPTH28 — Property Recon Mega-Expansion
//
// Reads property profiles, weather intelligence, permits, and trade auto-scopes.
// Calls recon-property-intelligence and recon-auto-scope Edge Functions.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property_intelligence.dart';

// ════════════════════════════════════════════════════════════════
// INTERFACE
// ════════════════════════════════════════════════════════════════

abstract class PropertyIntelligenceRepositoryInterface {
  Future<PropertyProfile?> getProfile(String scanId);
  Future<WeatherIntelligence?> getWeather(String scanId);
  Future<List<PermitRecord>> getPermits(String scanId);
  Future<List<TradeAutoScope>> getScopes(String scanId);
  Future<void> triggerIntelligence(String scanId);
  Future<void> triggerAutoScope(String scanId, List<String> trades);
}

// ════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ════════════════════════════════════════════════════════════════

class PropertyIntelligenceRepository implements PropertyIntelligenceRepositoryInterface {
  SupabaseClient get _client => supabase;

  @override
  Future<PropertyProfile?> getProfile(String scanId) async {
    try {
      final res = await _client
          .from('property_profiles')
          .select()
          .eq('scan_id', scanId)
          .maybeSingle();

      return res != null ? PropertyProfile.fromJson(res) : null;
    } catch (e) {
      throw AppError('Failed to load property profile: $e');
    }
  }

  @override
  Future<WeatherIntelligence?> getWeather(String scanId) async {
    try {
      final res = await _client
          .from('weather_intelligence')
          .select()
          .eq('scan_id', scanId)
          .maybeSingle();

      return res != null ? WeatherIntelligence.fromJson(res) : null;
    } catch (e) {
      throw AppError('Failed to load weather intelligence: $e');
    }
  }

  @override
  Future<List<PermitRecord>> getPermits(String scanId) async {
    try {
      final res = await _client
          .from('permit_history')
          .select()
          .eq('scan_id', scanId)
          .order('filed_date', ascending: false);

      return (res as List).map((row) => PermitRecord.fromJson(row)).toList();
    } catch (e) {
      throw AppError('Failed to load permit history: $e');
    }
  }

  @override
  Future<List<TradeAutoScope>> getScopes(String scanId) async {
    try {
      final res = await _client
          .from('trade_auto_scopes')
          .select()
          .eq('scan_id', scanId)
          .order('trade');

      return (res as List).map((row) => TradeAutoScope.fromJson(row)).toList();
    } catch (e) {
      throw AppError('Failed to load auto-scopes: $e');
    }
  }

  @override
  Future<void> triggerIntelligence(String scanId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw AppError('Not authenticated');

      final url = '${_client.rest.url.replaceAll('/rest/v1', '')}/functions/v1/recon-property-intelligence';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'scan_id': scanId}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw AppError(data['error'] ?? 'Intelligence gathering failed');
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError('Intelligence gathering failed: $e');
    }
  }

  @override
  Future<void> triggerAutoScope(String scanId, List<String> trades) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw AppError('Not authenticated');

      final url = '${_client.rest.url.replaceAll('/rest/v1', '')}/functions/v1/recon-auto-scope';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'scan_id': scanId, 'trades': trades}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw AppError(data['error'] ?? 'Auto-scope generation failed');
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError('Auto-scope generation failed: $e');
    }
  }
}
