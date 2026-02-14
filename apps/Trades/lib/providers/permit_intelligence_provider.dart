// ZAFTO Permit Intelligence Provider — Riverpod providers for permits
// Connects permit_intelligence_repository to Flutter UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/permit_intelligence_repository.dart';
import '../models/permit_jurisdiction.dart';
import '../models/permit_requirement.dart';
import '../models/job_permit.dart';
import '../models/permit_inspection.dart';

final permitRepoProvider = Provider((ref) => PermitIntelligenceRepository());

// ── Jurisdictions ──────────────────────────────────────

final jurisdictionsProvider = FutureProvider.family<List<PermitJurisdiction>, String?>(
  (ref, stateCode) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getJurisdictions(stateCode: stateCode);
  },
);

final jurisdictionByCityProvider = FutureProvider.family<PermitJurisdiction?, ({String city, String stateCode})>(
  (ref, params) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getJurisdictionByCity(params.city, params.stateCode);
  },
);

// ── Requirements ───────────────────────────────────────

final permitRequirementsProvider = FutureProvider.family<List<PermitRequirement>, ({String jurisdictionId, String? tradeType})>(
  (ref, params) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getRequirements(params.jurisdictionId, tradeType: params.tradeType);
  },
);

// ── Job Permits ────────────────────────────────────────

final jobPermitsProvider = FutureProvider.family<List<JobPermit>, String>(
  (ref, jobId) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getJobPermits(jobId);
  },
);

final activePermitsProvider = FutureProvider<List<JobPermit>>(
  (ref) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getAllActivePermits();
  },
);

// ── Inspections ────────────────────────────────────────

final permitInspectionsProvider = FutureProvider.family<List<PermitInspection>, String>(
  (ref, jobPermitId) async {
    final repo = ref.watch(permitRepoProvider);
    return repo.getInspections(jobPermitId);
  },
);
