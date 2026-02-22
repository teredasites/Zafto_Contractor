import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signing_workflow.dart';
import '../repositories/signing_workflow_repository.dart';

/// Repository singleton
final signingWorkflowRepoProvider =
    Provider<SigningWorkflowRepository>((ref) {
  return SigningWorkflowRepository(Supabase.instance.client);
});

/// All workflows for a company (optionally filtered by status)
final signingWorkflowsProvider = FutureProvider.autoDispose
    .family<List<SigningWorkflow>, ({String companyId, String? status})>(
        (ref, params) async {
  final repo = ref.watch(signingWorkflowRepoProvider);
  return repo.getByCompany(params.companyId, status: params.status);
});

/// Single workflow by ID
final signingWorkflowByIdProvider =
    FutureProvider.autoDispose.family<SigningWorkflow?, String>(
        (ref, id) async {
  final repo = ref.watch(signingWorkflowRepoProvider);
  return repo.getById(id);
});

/// Workflows for a specific render
final signingWorkflowsByRenderProvider =
    FutureProvider.autoDispose.family<List<SigningWorkflow>, String>(
        (ref, renderId) async {
  final repo = ref.watch(signingWorkflowRepoProvider);
  return repo.getByRender(renderId);
});

/// Audit events for a signature request or render
final signatureAuditEventsProvider = FutureProvider.autoDispose
    .family<List<SignatureAuditEvent>,
        ({String? signatureRequestId, String? renderId})>(
        (ref, params) async {
  final repo = ref.watch(signingWorkflowRepoProvider);
  return repo.getAuditEvents(
    signatureRequestId: params.signatureRequestId,
    renderId: params.renderId,
  );
});
