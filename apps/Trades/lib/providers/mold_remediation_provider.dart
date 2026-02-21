// ZAFTO Mold Remediation Providers
// Created: DEPTH35 — Riverpod providers for assessments, moisture readings,
// remediation plans, equipment, lab samples, clearance tests, state licensing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/mold_remediation_repository.dart';
import '../models/mold_remediation.dart';

// ══════════════════════════════════════════════════════════════
// REPOSITORY
// ══════════════════════════════════════════════════════════════

final moldRepoProvider = Provider<MoldRemediationRepository>((ref) {
  return MoldRemediationRepository();
});

// ══════════════════════════════════════════════════════════════
// STATE LICENSING (system reference)
// ══════════════════════════════════════════════════════════════

final moldStateLicensingProvider =
    FutureProvider<List<MoldStateLicensing>>((ref) {
  return ref.watch(moldRepoProvider).getStateLicensing();
});

final moldStateLicensingByCodeProvider =
    FutureProvider.family<MoldStateLicensing?, String>((ref, stateCode) {
  return ref.watch(moldRepoProvider).getStateLicensingByCode(stateCode);
});

final moldStatesRequiringLicenseProvider =
    FutureProvider<List<MoldStateLicensing>>((ref) {
  return ref.watch(moldRepoProvider).getStatesRequiringLicense();
});

// ══════════════════════════════════════════════════════════════
// ASSESSMENTS
// ══════════════════════════════════════════════════════════════

final moldAssessmentsProvider =
    FutureProvider.autoDispose.family<List<MoldAssessment>, String>(
  (ref, companyId) {
    return ref.watch(moldRepoProvider).getAssessments(companyId);
  },
);

final moldAssessmentsByPropertyProvider = FutureProvider.autoDispose
    .family<List<MoldAssessment>, ({String companyId, String propertyId})>(
  (ref, params) {
    return ref
        .watch(moldRepoProvider)
        .getAssessmentsByProperty(params.companyId, params.propertyId);
  },
);

final moldAssessmentsByJobProvider = FutureProvider.autoDispose
    .family<List<MoldAssessment>, ({String companyId, String jobId})>(
  (ref, params) {
    return ref
        .watch(moldRepoProvider)
        .getAssessmentsByJob(params.companyId, params.jobId);
  },
);

final moldAssessmentProvider =
    FutureProvider.autoDispose.family<MoldAssessment, String>(
  (ref, id) {
    return ref.watch(moldRepoProvider).getAssessment(id);
  },
);

// ══════════════════════════════════════════════════════════════
// MOISTURE READINGS
// ══════════════════════════════════════════════════════════════

final moldMoistureReadingsProvider =
    FutureProvider.autoDispose.family<List<MoldMoistureReading>, String>(
  (ref, assessmentId) {
    return ref.watch(moldRepoProvider).getMoistureReadings(assessmentId);
  },
);

final moldMoistureReadingsByRoomProvider = FutureProvider.autoDispose
    .family<List<MoldMoistureReading>, ({String assessmentId, String roomName})>(
  (ref, params) {
    return ref
        .watch(moldRepoProvider)
        .getMoistureReadingsByRoom(params.assessmentId, params.roomName);
  },
);

// ══════════════════════════════════════════════════════════════
// REMEDIATION PLANS
// ══════════════════════════════════════════════════════════════

final moldRemediationPlansProvider =
    FutureProvider.autoDispose.family<List<MoldRemediationPlan>, String>(
  (ref, companyId) {
    return ref.watch(moldRepoProvider).getRemediationPlans(companyId);
  },
);

final moldRemediationPlansByAssessmentProvider =
    FutureProvider.autoDispose.family<List<MoldRemediationPlan>, String>(
  (ref, assessmentId) {
    return ref
        .watch(moldRepoProvider)
        .getRemediationPlansByAssessment(assessmentId);
  },
);

final moldRemediationPlanProvider =
    FutureProvider.autoDispose.family<MoldRemediationPlan, String>(
  (ref, id) {
    return ref.watch(moldRepoProvider).getRemediationPlan(id);
  },
);

// ══════════════════════════════════════════════════════════════
// EQUIPMENT DEPLOYMENTS
// ══════════════════════════════════════════════════════════════

final moldEquipmentByRemediationProvider =
    FutureProvider.autoDispose.family<List<MoldEquipmentDeployment>, String>(
  (ref, remediationId) {
    return ref
        .watch(moldRepoProvider)
        .getEquipmentByRemediation(remediationId);
  },
);

final moldActiveDeploymentsProvider =
    FutureProvider.autoDispose.family<List<MoldEquipmentDeployment>, String>(
  (ref, companyId) {
    return ref.watch(moldRepoProvider).getActiveDeployments(companyId);
  },
);

// ══════════════════════════════════════════════════════════════
// LAB SAMPLES
// ══════════════════════════════════════════════════════════════

final moldLabSamplesByAssessmentProvider =
    FutureProvider.autoDispose.family<List<MoldLabSample>, String>(
  (ref, assessmentId) {
    return ref.watch(moldRepoProvider).getLabSamplesByAssessment(assessmentId);
  },
);

final moldLabSamplesProvider =
    FutureProvider.autoDispose.family<List<MoldLabSample>, String>(
  (ref, companyId) {
    return ref.watch(moldRepoProvider).getLabSamples(companyId);
  },
);

final moldLabSampleProvider =
    FutureProvider.autoDispose.family<MoldLabSample, String>(
  (ref, id) {
    return ref.watch(moldRepoProvider).getLabSample(id);
  },
);

// ══════════════════════════════════════════════════════════════
// CLEARANCE TESTS
// ══════════════════════════════════════════════════════════════

final moldClearanceByRemediationProvider =
    FutureProvider.autoDispose.family<List<MoldClearanceTest>, String>(
  (ref, remediationId) {
    return ref
        .watch(moldRepoProvider)
        .getClearanceTestsByRemediation(remediationId);
  },
);

final moldClearanceByAssessmentProvider =
    FutureProvider.autoDispose.family<List<MoldClearanceTest>, String>(
  (ref, assessmentId) {
    return ref
        .watch(moldRepoProvider)
        .getClearanceTestsByAssessment(assessmentId);
  },
);

final moldClearanceTestProvider =
    FutureProvider.autoDispose.family<MoldClearanceTest, String>(
  (ref, id) {
    return ref.watch(moldRepoProvider).getClearanceTest(id);
  },
);
