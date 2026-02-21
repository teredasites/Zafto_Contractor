// ZAFTO Labor Unit Provider
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Riverpod providers for labor units and crew performance tracking.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_unit.dart';
import '../repositories/labor_unit_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final laborUnitRepoProvider = Provider<LaborUnitRepository>((ref) {
  return LaborUnitRepository();
});

// ════════════════════════════════════════════════════════════════
// ALL LABOR UNITS (optionally by trade)
// ════════════════════════════════════════════════════════════════

final laborUnitsProvider = FutureProvider.autoDispose
    .family<List<LaborUnit>, String?>((ref, trade) async {
  final repo = ref.read(laborUnitRepoProvider);
  return repo.getUnits(trade: trade);
});

// ════════════════════════════════════════════════════════════════
// SINGLE LABOR UNIT
// ════════════════════════════════════════════════════════════════

final laborUnitProvider = FutureProvider.autoDispose
    .family<LaborUnit, String>((ref, unitId) async {
  final repo = ref.read(laborUnitRepoProvider);
  return repo.getUnit(unitId);
});

// ════════════════════════════════════════════════════════════════
// CREW PERFORMANCE HISTORY
// ════════════════════════════════════════════════════════════════

final crewPerformanceProvider = FutureProvider.autoDispose
    .family<List<CrewPerformanceEntry>, String?>((ref, trade) async {
  final repo = ref.read(laborUnitRepoProvider);
  return repo.getPerformance(trade: trade);
});

// ════════════════════════════════════════════════════════════════
// CREW PERFORMANCE MULTIPLIER
// ════════════════════════════════════════════════════════════════

final crewMultiplierProvider = FutureProvider.autoDispose
    .family<double, ({String companyId, String trade})>((ref, params) async {
  final repo = ref.read(laborUnitRepoProvider);
  return repo.getPerformanceMultiplier(params.companyId, params.trade);
});
