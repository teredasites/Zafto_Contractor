// ZAFTO Property Scan Provider
// Created: Phase P — Sprint P7
//
// Riverpod providers for property scan state management.
// Uses FutureProvider.family for data fetching, StateNotifier for mutations.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property_scan.dart';
import '../repositories/property_scan_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final propertyScanRepoProvider = Provider<PropertyScanRepository>((ref) {
  return PropertyScanRepository();
});

// ════════════════════════════════════════════════════════════════
// SCAN LIST PROVIDER
// ════════════════════════════════════════════════════════════════

final propertyScanListProvider =
    FutureProvider.autoDispose<List<PropertyScan>>((ref) async {
  final repo = ref.read(propertyScanRepoProvider);
  return repo.getScans();
});

// ════════════════════════════════════════════════════════════════
// SINGLE SCAN PROVIDER (.family by scan ID)
// ════════════════════════════════════════════════════════════════

final propertyScanProvider =
    FutureProvider.autoDispose.family<PropertyScan?, String>((ref, scanId) async {
  final repo = ref.read(propertyScanRepoProvider);
  return repo.getScan(scanId);
});

// ════════════════════════════════════════════════════════════════
// SCAN BY JOB ID
// ════════════════════════════════════════════════════════════════

final propertyScanByJobProvider =
    FutureProvider.autoDispose.family<PropertyScan?, String>((ref, jobId) async {
  final repo = ref.read(propertyScanRepoProvider);
  return repo.getScanByJobId(jobId);
});

// ════════════════════════════════════════════════════════════════
// FULL SCAN DATA (scan + roof + walls + trades + lead score)
// ════════════════════════════════════════════════════════════════

class ScanFullData {
  final PropertyScan scan;
  final RoofMeasurement? roof;
  final List<RoofFacet> facets;
  final WallMeasurement? wall;
  final List<TradeBidData> tradeBids;
  final PropertyLeadScore? leadScore;
  final List<ScanHistoryEntry> history;

  const ScanFullData({
    required this.scan,
    this.roof,
    this.facets = const [],
    this.wall,
    this.tradeBids = const [],
    this.leadScore,
    this.history = const [],
  });
}

final scanFullDataProvider =
    FutureProvider.autoDispose.family<ScanFullData?, String>((ref, scanId) async {
  final repo = ref.read(propertyScanRepoProvider);

  final scan = await repo.getScan(scanId);
  if (scan == null) return null;

  // Fetch all related data in parallel
  final results = await Future.wait([
    repo.getRoofMeasurement(scanId),
    repo.getWallMeasurement(scanId),
    repo.getTradeBids(scanId),
    repo.getLeadScore(scanId),
    repo.getScanHistory(scanId),
  ]);

  final roof = results[0] as RoofMeasurement?;
  List<RoofFacet> facets = [];
  if (roof != null) {
    facets = await repo.getRoofFacets(roof.id);
  }

  return ScanFullData(
    scan: scan,
    roof: roof,
    facets: facets,
    wall: results[1] as WallMeasurement?,
    tradeBids: results[2] as List<TradeBidData>,
    leadScore: results[3] as PropertyLeadScore?,
    history: results[4] as List<ScanHistoryEntry>,
  );
});
