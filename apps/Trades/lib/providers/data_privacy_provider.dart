// ZAFTO Data Privacy Providers
// Created: DEPTH33 — Consent management, data export/deletion,
// privacy policy versions.
//
// Riverpod providers for user consent, data export requests,
// data deletion requests, and privacy policy versions.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/data_privacy.dart';
import '../repositories/data_privacy_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final dataPrivacyRepoProvider =
    Provider<DataPrivacyRepository>((ref) {
  return DataPrivacyRepository();
});

// ════════════════════════════════════════════════════════════════
// USER CONSENT
// ════════════════════════════════════════════════════════════════

/// All consent records for current user
final userConsentsProvider =
    FutureProvider.autoDispose<List<UserConsent>>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getConsents();
});

/// Latest consent status per type (map of ConsentType → bool)
final consentStatusProvider =
    FutureProvider.autoDispose<Map<ConsentType, bool>>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getConsentStatus();
});

/// Single consent by type
final consentByTypeProvider = FutureProvider.autoDispose
    .family<UserConsent?, ConsentType>((ref, type) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getConsentByType(type);
});

// ════════════════════════════════════════════════════════════════
// DATA EXPORT REQUESTS
// ════════════════════════════════════════════════════════════════

/// All export requests for current user
final dataExportRequestsProvider =
    FutureProvider.autoDispose<List<DataExportRequest>>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getExportRequests();
});

// ════════════════════════════════════════════════════════════════
// DATA DELETION REQUESTS
// ════════════════════════════════════════════════════════════════

/// All deletion requests for current user
final dataDeletionRequestsProvider =
    FutureProvider.autoDispose<List<DataDeletionRequest>>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getDeletionRequests();
});

// ════════════════════════════════════════════════════════════════
// PRIVACY POLICY VERSIONS
// ════════════════════════════════════════════════════════════════

/// All policy versions
final privacyPolicyVersionsProvider =
    FutureProvider.autoDispose<List<PrivacyPolicyVersion>>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getPolicyVersions();
});

/// Current active policy
final currentPrivacyPolicyProvider =
    FutureProvider.autoDispose<PrivacyPolicyVersion?>((ref) async {
  final repo = ref.read(dataPrivacyRepoProvider);
  return repo.getCurrentPolicy();
});
