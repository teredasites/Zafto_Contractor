// ZAFTO Restoration Service — Supabase Backend
// Providers and services for supplements, moisture, drying logs, equipment, TPI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/claim_supplement.dart';
import '../models/moisture_reading.dart';
import '../models/drying_log.dart';
import '../models/restoration_equipment.dart';
import '../models/tpi_inspection.dart';
import '../repositories/claim_supplement_repository.dart';
import '../repositories/moisture_reading_repository.dart';
import '../repositories/drying_log_repository.dart';
import '../repositories/restoration_equipment_repository.dart';
import '../repositories/tpi_inspection_repository.dart';
import 'auth_service.dart';

// --- Repository Providers ---

final claimSupplementRepositoryProvider =
    Provider<ClaimSupplementRepository>((ref) {
  return ClaimSupplementRepository();
});

final moistureReadingRepositoryProvider =
    Provider<MoistureReadingRepository>((ref) {
  return MoistureReadingRepository();
});

final dryingLogRepositoryProvider = Provider<DryingLogRepository>((ref) {
  return DryingLogRepository();
});

final restorationEquipmentRepositoryProvider =
    Provider<RestorationEquipmentRepository>((ref) {
  return RestorationEquipmentRepository();
});

final tpiInspectionRepositoryProvider =
    Provider<TpiInspectionRepository>((ref) {
  return TpiInspectionRepository();
});

// --- Service Provider ---

final restorationServiceProvider = Provider<RestorationService>((ref) {
  final authState = ref.watch(authStateProvider);
  return RestorationService(
    supplementRepo: ref.watch(claimSupplementRepositoryProvider),
    moistureRepo: ref.watch(moistureReadingRepositoryProvider),
    dryingRepo: ref.watch(dryingLogRepositoryProvider),
    equipmentRepo: ref.watch(restorationEquipmentRepositoryProvider),
    tpiRepo: ref.watch(tpiInspectionRepositoryProvider),
    authState: authState,
  );
});

// --- Data Providers (auto-dispose, family by job/claim ID) ---

// Supplements by claim
final claimSupplementsProvider = FutureProvider.autoDispose
    .family<List<ClaimSupplement>, String>((ref, claimId) async {
  final repo = ref.watch(claimSupplementRepositoryProvider);
  return repo.getSupplementsByClaim(claimId);
});

// Moisture readings by job
final jobMoistureReadingsProvider = FutureProvider.autoDispose
    .family<List<MoistureReading>, String>((ref, jobId) async {
  final repo = ref.watch(moistureReadingRepositoryProvider);
  return repo.getReadingsByJob(jobId);
});

// Moisture areas for a job
final jobMoistureAreasProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, jobId) async {
  final repo = ref.watch(moistureReadingRepositoryProvider);
  return repo.getAreas(jobId);
});

// Drying logs by job
final jobDryingLogsProvider = FutureProvider.autoDispose
    .family<List<DryingLog>, String>((ref, jobId) async {
  final repo = ref.watch(dryingLogRepositoryProvider);
  return repo.getLogsByJob(jobId);
});

// Equipment by job
final jobEquipmentProvider = FutureProvider.autoDispose
    .family<List<RestorationEquipment>, String>((ref, jobId) async {
  final repo = ref.watch(restorationEquipmentRepositoryProvider);
  return repo.getEquipmentByJob(jobId);
});

// Deployed equipment only
final deployedEquipmentProvider = FutureProvider.autoDispose
    .family<List<RestorationEquipment>, String>((ref, jobId) async {
  final repo = ref.watch(restorationEquipmentRepositoryProvider);
  return repo.getDeployedEquipment(jobId);
});

// TPI inspections by claim
final claimTpiInspectionsProvider = FutureProvider.autoDispose
    .family<List<TpiInspection>, String>((ref, claimId) async {
  final repo = ref.watch(tpiInspectionRepositoryProvider);
  return repo.getInspectionsByClaim(claimId);
});

// --- Service ---

class RestorationService {
  final ClaimSupplementRepository supplementRepo;
  final MoistureReadingRepository moistureRepo;
  final DryingLogRepository dryingRepo;
  final RestorationEquipmentRepository equipmentRepo;
  final TpiInspectionRepository tpiRepo;
  final AuthState authState;

  RestorationService({
    required this.supplementRepo,
    required this.moistureRepo,
    required this.dryingRepo,
    required this.equipmentRepo,
    required this.tpiRepo,
    required this.authState,
  });

  String get _companyId {
    final id = authState.companyId;
    if (id == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return id;
  }

  String? get _userId => authState.user?.uid;

  // --- Supplements ---

  Future<ClaimSupplement> createSupplement({
    required String claimId,
    required String title,
    String? description,
    SupplementReason reason = SupplementReason.hiddenDamage,
    double amount = 0,
    List<Map<String, dynamic>> lineItems = const [],
  }) async {
    final nextNumber = await supplementRepo.getNextSupplementNumber(claimId);
    final supplement = ClaimSupplement(
      companyId: _companyId,
      claimId: claimId,
      supplementNumber: nextNumber,
      title: title,
      description: description,
      reason: reason,
      amount: amount,
      lineItems: lineItems,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return supplementRepo.createSupplement(supplement);
  }

  // --- Moisture ---

  Future<MoistureReading> recordMoistureReading({
    required String jobId,
    String? claimId,
    required String areaName,
    String? floorLevel,
    MaterialType materialType = MaterialType.drywall,
    required double readingValue,
    ReadingUnit readingUnit = ReadingUnit.percent,
    double? targetValue,
    String? meterType,
    String? meterModel,
    double? ambientTempF,
    double? ambientHumidity,
  }) async {
    final effectiveTarget = targetValue ?? materialType.defaultTarget;
    final reading = MoistureReading(
      companyId: _companyId,
      jobId: jobId,
      claimId: claimId,
      areaName: areaName,
      floorLevel: floorLevel,
      materialType: materialType,
      readingValue: readingValue,
      readingUnit: readingUnit,
      targetValue: effectiveTarget,
      meterType: meterType,
      meterModel: meterModel,
      ambientTempF: ambientTempF,
      ambientHumidity: ambientHumidity,
      isDry: readingValue <= effectiveTarget,
      recordedByUserId: _userId,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return moistureRepo.createReading(reading);
  }

  // --- Drying Logs ---

  Future<DryingLog> createDryingLog({
    required String jobId,
    String? claimId,
    DryingLogType logType = DryingLogType.daily,
    required String summary,
    String? details,
    int equipmentCount = 0,
    int dehumidifiersRunning = 0,
    int airMoversRunning = 0,
    int airScrubbersRunning = 0,
    double? outdoorTempF,
    double? outdoorHumidity,
    double? indoorTempF,
    double? indoorHumidity,
    List<Map<String, dynamic>> photos = const [],
  }) async {
    final log = DryingLog(
      companyId: _companyId,
      jobId: jobId,
      claimId: claimId,
      logType: logType,
      summary: summary,
      details: details,
      equipmentCount: equipmentCount,
      dehumidifiersRunning: dehumidifiersRunning,
      airMoversRunning: airMoversRunning,
      airScrubbersRunning: airScrubbersRunning,
      outdoorTempF: outdoorTempF,
      outdoorHumidity: outdoorHumidity,
      indoorTempF: indoorTempF,
      indoorHumidity: indoorHumidity,
      photos: photos,
      recordedByUserId: _userId,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return dryingRepo.createLog(log);
  }

  // --- Equipment ---

  Future<RestorationEquipment> deployEquipment({
    required String jobId,
    String? claimId,
    required EquipmentType equipmentType,
    String? make,
    String? model,
    String? serialNumber,
    String? assetTag,
    required String areaDeployed,
    required double dailyRate,
    String? notes,
  }) async {
    final equipment = RestorationEquipment(
      companyId: _companyId,
      jobId: jobId,
      claimId: claimId,
      equipmentType: equipmentType,
      make: make,
      model: model,
      serialNumber: serialNumber,
      assetTag: assetTag,
      areaDeployed: areaDeployed,
      deployedAt: DateTime.now(),
      dailyRate: dailyRate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return equipmentRepo.deployEquipment(equipment);
  }

  Future<void> removeEquipment(String id) {
    return equipmentRepo.removeEquipment(id);
  }

  // --- TPI ---

  Future<TpiInspection> scheduleInspection({
    required String claimId,
    required String jobId,
    String? inspectorName,
    String? inspectorCompany,
    String? inspectorPhone,
    String? inspectorEmail,
    TpiInspectionType inspectionType = TpiInspectionType.progress,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    final inspection = TpiInspection(
      companyId: _companyId,
      claimId: claimId,
      jobId: jobId,
      inspectorName: inspectorName,
      inspectorCompany: inspectorCompany,
      inspectorPhone: inspectorPhone,
      inspectorEmail: inspectorEmail,
      inspectionType: inspectionType,
      scheduledDate: scheduledDate,
      status: scheduledDate != null ? TpiStatus.scheduled : TpiStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return tpiRepo.createInspection(inspection);
  }
}
