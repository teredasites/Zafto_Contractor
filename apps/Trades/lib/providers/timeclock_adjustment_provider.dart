import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeclock_adjustment.dart';
import '../repositories/timeclock_adjustment_repository.dart';

/// Repository singleton
final timeclockAdjustmentRepoProvider =
    Provider<TimeclockAdjustmentRepository>((ref) {
  return TimeclockAdjustmentRepository(Supabase.instance.client);
});

/// Adjustments for a specific time entry
final timeclockAdjustmentsByEntryProvider =
    FutureProvider.autoDispose.family<List<TimeclockAdjustment>, String>(
        (ref, timeEntryId) async {
  final repo = ref.watch(timeclockAdjustmentRepoProvider);
  return repo.getByTimeEntry(timeEntryId);
});

/// Adjustments for an employee in a company
final timeclockAdjustmentsByEmployeeProvider = FutureProvider.autoDispose
    .family<List<TimeclockAdjustment>, ({String companyId, String employeeId})>(
        (ref, params) async {
  final repo = ref.watch(timeclockAdjustmentRepoProvider);
  return repo.getByEmployee(params.companyId, params.employeeId);
});

/// Adjustments made by a specific manager
final timeclockAdjustmentsByAdjusterProvider = FutureProvider.autoDispose
    .family<List<TimeclockAdjustment>, ({String companyId, String adjusterId})>(
        (ref, params) async {
  final repo = ref.watch(timeclockAdjustmentRepoProvider);
  return repo.getByAdjuster(params.companyId, params.adjusterId);
});
