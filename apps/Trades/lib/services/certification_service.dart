// ZAFTO Certification Service — Supabase Backend
// Providers and service for employee license/certification tracking.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/certification.dart';
import '../repositories/certification_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final certificationRepositoryProvider =
    Provider<CertificationRepository>((ref) {
  return CertificationRepository();
});

final certificationServiceProvider = Provider<CertificationService>((ref) {
  final repo = ref.watch(certificationRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return CertificationService(repo, authState);
});

// All certifications for the company.
final companyCertificationsProvider =
    FutureProvider.autoDispose<List<Certification>>((ref) async {
  final repo = ref.watch(certificationRepositoryProvider);
  return repo.getCertifications();
});

// Certifications for a specific user.
final userCertificationsProvider = FutureProvider.autoDispose
    .family<List<Certification>, String>((ref, userId) async {
  final repo = ref.watch(certificationRepositoryProvider);
  return repo.getCertificationsByUser(userId);
});

// Certifications expiring within N days.
final expiringCertificationsProvider = FutureProvider.autoDispose
    .family<List<Certification>, int>((ref, days) async {
  final repo = ref.watch(certificationRepositoryProvider);
  return repo.getExpiring(days: days);
});

// Configurable certification types from DB.
// Fetches system defaults (company_id IS NULL) + company-specific types.
final certificationTypesProvider =
    FutureProvider.autoDispose<List<CertificationTypeConfig>>((ref) async {
  final response = await supabase
      .from('certification_types')
      .select('*')
      .eq('is_active', true)
      .order('sort_order');

  final items = response as List;
  return items
      .map((row) =>
          CertificationTypeConfig.fromJson(row as Map<String, dynamic>))
      .toList();
});

// --- Service ---

class CertificationService {
  final CertificationRepository _repo;
  final AuthState _authState;

  CertificationService(this._repo, this._authState);

  Future<Certification> createCertification({
    required String userId,
    required String certificationTypeValue,
    required String certificationName,
    String? issuingAuthority,
    String? certificationNumber,
    DateTime? issuedDate,
    DateTime? expirationDate,
    bool renewalRequired = true,
    int renewalReminderDays = 30,
    String? documentUrl,
    String? notes,
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage certifications.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final cert = Certification(
      companyId: companyId,
      userId: userId,
      certificationTypeValue: certificationTypeValue,
      certificationName: certificationName,
      issuingAuthority: issuingAuthority,
      certificationNumber: certificationNumber,
      issuedDate: issuedDate,
      expirationDate: expirationDate,
      renewalRequired: renewalRequired,
      renewalReminderDays: renewalReminderDays,
      documentUrl: documentUrl,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createCertification(cert);
  }

  Future<List<Certification>> getCertifications() =>
      _repo.getCertifications();

  Future<List<Certification>> getCertificationsByUser(String userId) =>
      _repo.getCertificationsByUser(userId);

  Future<List<Certification>> getExpiring({int days = 30}) =>
      _repo.getExpiring(days: days);

  Future<Certification?> getCertification(String id) =>
      _repo.getCertification(id);

  Future<Certification> updateCertification(
          String id, Certification cert) =>
      _repo.updateCertification(id, cert);

  Future<void> deleteCertification(String id) =>
      _repo.deleteCertification(id);
}
