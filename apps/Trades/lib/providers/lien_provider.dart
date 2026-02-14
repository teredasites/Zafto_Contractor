// ZAFTO Lien Provider — Riverpod providers for lien protection
// Connects lien_repository to Flutter UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lien_repository.dart';
import '../models/lien_rule.dart';
import '../models/lien_tracking.dart';

final lienRepoProvider = Provider((ref) => LienRepository());

final lienRulesProvider = FutureProvider<List<LienRule>>(
  (ref) async {
    final repo = ref.watch(lienRepoProvider);
    return repo.getAllRules();
  },
);

final lienRuleByStateProvider = FutureProvider.family<LienRule?, String>(
  (ref, stateCode) async {
    final repo = ref.watch(lienRepoProvider);
    return repo.getRuleByState(stateCode);
  },
);

final activeLiensProvider = FutureProvider<List<LienTracking>>(
  (ref) async {
    final repo = ref.watch(lienRepoProvider);
    return repo.getActiveLiens();
  },
);

final lienByJobProvider = FutureProvider.family<LienTracking?, String>(
  (ref, jobId) async {
    final repo = ref.watch(lienRepoProvider);
    return repo.getLienByJob(jobId);
  },
);
