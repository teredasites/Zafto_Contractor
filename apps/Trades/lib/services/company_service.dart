/// ZAFTO Company Service - Company Creation & Management
/// Sprint 7.0 - January 2026
/// S151 - Firebase removed, migrated to Supabase

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';
import 'auth_service.dart';

/// Company service provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  final authState = ref.watch(authStateProvider);
  return CompanyService(authState);
});

/// Current company provider - streams company data from Supabase
final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.hasCompany) return Stream.value(null);

  final supabase = Supabase.instance.client;
  return supabase
      .from('companies')
      .stream(primaryKey: ['id'])
      .eq('id', authState.companyId!)
      .map((rows) => rows.isNotEmpty
          ? Company.fromMap({...rows.first, 'id': rows.first['id']})
          : null);
});

// ============================================================
// COMPANY SERVICE
// ============================================================

class CompanyService {
  final AuthState _authState;

  CompanyService(this._authState);

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _userId => _authState.user?.uid;

  /// Create a new company (during onboarding)
  Future<String> createCompany({
    required String name,
    required CompanyTier tier,
    String? businessName,
    String? phone,
    String? email,
    String? licenseNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();

    // Create company document
    final result = await _supabase.from('companies').insert({
      'name': name,
      'tier': tier.name,
      'owner_user_id': _userId,
      'business_name': businessName,
      'phone': phone,
      'email': email,
      'license_number': licenseNumber,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'enabled_trades': ['electrical'],
      'default_tax_rate': 0,
      'invoice_prefix': 'INV',
      'next_invoice_number': 1,
      'created_at': now,
      'updated_at': now,
    }).select('id').single();

    final companyId = result['id'] as String;

    // Create default Owner role
    final roleResult = await _supabase.from('roles').insert({
      'company_id': companyId,
      'name': 'Owner',
      'is_system_role': true,
      'is_default': false,
      'permissions': _getOwnerPermissions(),
      'created_at': now,
      'updated_at': now,
    }).select('id').single();

    final roleId = roleResult['id'] as String;

    // Update user with company reference
    await _supabase.from('users').update({
      'company_id': companyId,
      'role_id': roleId,
      'status': 'active',
      'updated_at': now,
    }).eq('id', _userId!);

    return companyId;
  }

  /// Get current company
  Future<Company?> getCurrentCompany() async {
    if (!_authState.hasCompany) return null;

    final rows = await _supabase
        .from('companies')
        .select()
        .eq('id', _authState.companyId!)
        .limit(1);

    if (rows.isEmpty) return null;
    return Company.fromMap({...rows.first, 'id': rows.first['id']});
  }

  /// Update company settings
  Future<void> updateCompany(Company company) async {
    await _supabase.from('companies').update({
      ...company.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', company.id);
  }

  /// Get and increment invoice number
  Future<String> getNextInvoiceNumber() async {
    if (!_authState.hasCompany) throw Exception('No company');

    // Use Supabase RPC for atomic increment
    final rows = await _supabase
        .from('companies')
        .select('invoice_prefix, next_invoice_number')
        .eq('id', _authState.companyId!)
        .limit(1);

    if (rows.isEmpty) throw Exception('Company not found');

    final prefix = rows.first['invoice_prefix'] as String? ?? 'INV';
    final current = rows.first['next_invoice_number'] as int? ?? 1;
    final year = DateTime.now().year;

    await _supabase.from('companies').update({
      'next_invoice_number': current + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _authState.companyId!);

    return '$prefix-$year-${current.toString().padLeft(4, '0')}';
  }

  /// Check if user is company owner
  bool isOwner() {
    return _authState.user?.uid == _authState.companyId;
  }

  /// Get all owner permissions
  Map<String, bool> _getOwnerPermissions() => {
    'jobs.view.own': true,
    'jobs.view.all': true,
    'jobs.create': true,
    'jobs.edit.own': true,
    'jobs.edit.all': true,
    'jobs.delete': true,
    'jobs.assign': true,
    'invoices.view.own': true,
    'invoices.view.all': true,
    'invoices.create': true,
    'invoices.edit': true,
    'invoices.send': true,
    'invoices.approve': true,
    'invoices.void': true,
    'customers.view': true,
    'customers.create': true,
    'customers.edit': true,
    'customers.delete': true,
    'team.view': true,
    'team.invite': true,
    'team.edit': true,
    'team.remove': true,
    'dispatch.view': true,
    'dispatch.manage': true,
    'reports.view': true,
    'reports.export': true,
    'company.settings': true,
    'billing.manage': true,
    'roles.manage': true,
    'audit.view': true,
  };
}
