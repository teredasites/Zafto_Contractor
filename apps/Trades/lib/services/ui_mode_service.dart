/// ZAFTO UI Mode Service
/// Session 23 - Simple vs Pro Mode Management
/// S151 - Firebase removed, migrated to Supabase
///
/// Controls UI complexity:
/// - Simple Mode: Core flow (Bid -> Job -> Invoice)
/// - Pro Mode: Full CRM (Leads, Tasks, Automations, etc.)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

/// Company provider for UI mode (uses Supabase)
final _uiModeCompanyProvider = StreamProvider<Company?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.companyId == null) {
    return Stream.value(null);
  }

  final supabase = Supabase.instance.client;
  return supabase
      .from('companies')
      .stream(primaryKey: ['id'])
      .eq('id', authState.companyId!)
      .map((rows) => rows.isNotEmpty ? Company.fromMap({...rows.first, 'id': rows.first['id']}) : null);
});

/// Current UI mode for the company
final uiModeProvider = Provider<UiMode>((ref) {
  final companyAsync = ref.watch(_uiModeCompanyProvider);
  final company = companyAsync.valueOrNull;
  return company?.uiMode ?? UiMode.simple;
});

/// Whether Pro Mode is enabled
final isProModeProvider = Provider<bool>((ref) {
  return ref.watch(uiModeProvider) == UiMode.pro;
});

/// Check if a specific pro feature is enabled
final proFeatureProvider = Provider.family<bool, String>((ref, feature) {
  final companyAsync = ref.watch(_uiModeCompanyProvider);
  final company = companyAsync.valueOrNull;
  if (company == null) return false;
  return company.hasProFeature(feature);
});

/// UI Mode notifier for toggling
final uiModeNotifierProvider = StateNotifierProvider<UiModeNotifier, UiMode>((ref) {
  final companyAsync = ref.watch(_uiModeCompanyProvider);
  final company = companyAsync.valueOrNull;
  final authState = ref.watch(authStateProvider);
  return UiModeNotifier(company, authState.companyId);
});

// ============================================================
// NOTIFIER
// ============================================================

class UiModeNotifier extends StateNotifier<UiMode> {
  final Company? _company;
  final String? _companyId;

  UiModeNotifier(this._company, this._companyId)
      : super(_company?.uiMode ?? UiMode.simple);

  /// Toggle between Simple and Pro mode
  Future<void> toggleMode() async {
    final newMode = state == UiMode.simple ? UiMode.pro : UiMode.simple;
    state = newMode;
    await _updateSupabase({'ui_mode': newMode.name});
  }

  /// Set mode explicitly
  Future<void> setMode(UiMode mode) async {
    if (state == mode) return;
    state = mode;
    await _updateSupabase({'ui_mode': mode.name});
  }

  /// Enable/disable specific pro features
  Future<void> setProFeatures(List<String> features) async {
    await _updateSupabase({'enabled_pro_features': features});
  }

  Future<void> _updateSupabase(Map<String, dynamic> data) async {
    if (_companyId == null) return;
    await Supabase.instance.client
        .from('companies')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _companyId!);
  }
}

// ============================================================
// FEATURE DEFINITIONS
// ============================================================

/// Pro mode features with descriptions
class ProFeature {
  final String id;
  final String name;
  final String description;
  final String icon;

  const ProFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<ProFeature> proFeatures = [
  ProFeature(
    id: 'leads',
    name: 'Lead Pipeline',
    description: 'Track leads from first contact to won job',
    icon: 'user_plus',
  ),
  ProFeature(
    id: 'tasks',
    name: 'Tasks & Follow-ups',
    description: 'Never forget a follow-up with task reminders',
    icon: 'check_square',
  ),
  ProFeature(
    id: 'communications',
    name: 'Communication Hub',
    description: 'Log calls, emails, and texts in one place',
    icon: 'message_square',
  ),
  ProFeature(
    id: 'timeClock',
    name: 'Time Clock Admin',
    description: 'View and approve employee timesheets',
    icon: 'clock',
  ),
  ProFeature(
    id: 'serviceAgreements',
    name: 'Service Agreements',
    description: 'Recurring maintenance contracts',
    icon: 'file_text',
  ),
  ProFeature(
    id: 'equipment',
    name: 'Equipment Tracking',
    description: 'Track customer equipment and service history',
    icon: 'tool',
  ),
  ProFeature(
    id: 'multiProperty',
    name: 'Multi-Property',
    description: 'Manage multiple properties per customer',
    icon: 'building',
  ),
  ProFeature(
    id: 'automations',
    name: 'Automations',
    description: 'Auto-send follow-ups and reminders',
    icon: 'zap',
  ),
  ProFeature(
    id: 'advancedReports',
    name: 'Advanced Reports',
    description: 'Detailed business analytics and insights',
    icon: 'bar_chart',
  ),
];
