// ZAFTO Form Template Service — Supabase Backend
// Providers and service for configurable compliance form templates.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/form_template.dart';
import '../repositories/form_template_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final formTemplateRepositoryProvider =
    Provider<FormTemplateRepository>((ref) {
  return FormTemplateRepository();
});

final formTemplateServiceProvider = Provider<FormTemplateService>((ref) {
  final repo = ref.watch(formTemplateRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return FormTemplateService(repo, authState);
});

// All active templates visible to the company (own + system).
final activeFormTemplatesProvider =
    FutureProvider.autoDispose<List<FormTemplate>>((ref) async {
  final repo = ref.watch(formTemplateRepositoryProvider);
  return repo.getTemplates();
});

// Templates filtered by company's enabled trades.
// Pass the trades list from Company.enabledTrades.
final tradeFormTemplatesProvider = FutureProvider.autoDispose
    .family<List<FormTemplate>, List<String>>((ref, trades) async {
  final repo = ref.watch(formTemplateRepositoryProvider);
  if (trades.isEmpty) return repo.getTemplates();
  return repo.getTemplatesForTrades(trades);
});

// System templates only (for settings/admin view).
final systemFormTemplatesProvider =
    FutureProvider.autoDispose<List<FormTemplate>>((ref) async {
  final repo = ref.watch(formTemplateRepositoryProvider);
  return repo.getSystemTemplates();
});

// --- Service ---

class FormTemplateService {
  final FormTemplateRepository _repo;
  final AuthState _authState;

  FormTemplateService(this._repo, this._authState);

  Future<FormTemplate> createTemplate({
    String? trade,
    required String name,
    String? description,
    FormCategory category = FormCategory.compliance,
    String? regulationReference,
    required List<FormFieldDefinition> fields,
    int sortOrder = 0,
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage form templates.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final template = FormTemplate(
      companyId: companyId,
      trade: trade,
      name: name,
      description: description,
      category: category,
      regulationReference: regulationReference,
      fields: fields,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createTemplate(template);
  }

  // Clone a system template for company customization.
  Future<FormTemplate> cloneTemplate(FormTemplate source) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to clone templates.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final cloned = source.copyWith(
      id: '',
      companyId: companyId,
      isSystem: false,
      name: '${source.name} (Custom)',
    );

    return _repo.createTemplate(cloned);
  }

  Future<List<FormTemplate>> getTemplates() => _repo.getTemplates();

  Future<List<FormTemplate>> getTemplatesByTrade(String trade) =>
      _repo.getTemplatesByTrade(trade);

  Future<List<FormTemplate>> getTemplatesForTrades(List<String> trades) =>
      _repo.getTemplatesForTrades(trades);

  Future<FormTemplate?> getTemplate(String id) => _repo.getTemplate(id);

  Future<FormTemplate> updateTemplate(String id, FormTemplate template) =>
      _repo.updateTemplate(id, template);

  Future<void> deleteTemplate(String id) => _repo.deleteTemplate(id);
}
