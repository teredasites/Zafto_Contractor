/// ZAFTO Save to Job Widget - Universal Calculator Save
///
/// Provides a one-size-fits-all solution for saving any calculator
/// result to a job.
///
/// Usage in any calculator:
/// ```dart
/// ZaftoSaveToJobButton(
///   calculatorId: 'voltage_drop',
///   calculatorName: 'Voltage Drop',
///   inputs: {'voltage': 120, 'current': 15},
///   outputs: {'drop': '2.84%', 'volts': '3.41V'},
/// )
/// ```
///
/// Or use with ZaftoResultCard:
/// ```dart
/// ZaftoResultCard(
///   label: 'VOLTAGE DROP',
///   value: '2.84%',
///   onAddToJob: () => ZaftoSaveToJob.show(
///     context,
///     ref,
///     calculatorId: 'voltage_drop',
///     calculatorName: 'Voltage Drop',
///     inputs: inputs,
///     outputs: outputs,
///   ),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';

// ============================================================
// QUICK CALCULATION RECORD - Stored with Jobs
// ============================================================

/// Generic calculation record that works with any calculator
class QuickCalculationRecord {
  final String id;
  final String calculatorId;
  final String calculatorName;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final DateTime savedAt;
  final String? notes;

  QuickCalculationRecord({
    required this.id,
    required this.calculatorId,
    required this.calculatorName,
    required this.inputs,
    required this.outputs,
    required this.savedAt,
    this.notes,
  });

  factory QuickCalculationRecord.create({
    required String calculatorId,
    required String calculatorName,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
    String? notes,
  }) {
    return QuickCalculationRecord(
      id: 'calc_${DateTime.now().millisecondsSinceEpoch}',
      calculatorId: calculatorId,
      calculatorName: calculatorName,
      inputs: inputs,
      outputs: outputs,
      savedAt: DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'calculatorId': calculatorId,
        'calculatorName': calculatorName,
        'inputs': inputs,
        'outputs': outputs,
        'savedAt': savedAt.toIso8601String(),
        'notes': notes,
      };

  factory QuickCalculationRecord.fromJson(Map<String, dynamic> json) {
    return QuickCalculationRecord(
      id: json['id'] as String,
      calculatorId: json['calculatorId'] as String,
      calculatorName: json['calculatorName'] as String,
      inputs: Map<String, dynamic>.from(json['inputs'] ?? {}),
      outputs: Map<String, dynamic>.from(json['outputs'] ?? {}),
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Get primary output for display
  String get primaryOutput {
    if (outputs.isEmpty) return '-';
    final first = outputs.entries.first;
    return '${first.key}: ${first.value}';
  }
}

// ============================================================
// SAVE TO JOB BUTTON WIDGET
// ============================================================

/// Standalone button to save calculation to a job
class ZaftoSaveToJobButton extends ConsumerWidget {
  final String calculatorId;
  final String calculatorName;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final bool compact;

  const ZaftoSaveToJobButton({
    super.key,
    required this.calculatorId,
    required this.calculatorName,
    required this.inputs,
    required this.outputs,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    if (compact) {
      return IconButton(
        icon: Icon(LucideIcons.briefcase, color: colors.textSecondary, size: 20),
        onPressed: () => ZaftoSaveToJob.show(
          context,
          ref,
          calculatorId: calculatorId,
          calculatorName: calculatorName,
          inputs: inputs,
          outputs: outputs,
        ),
        tooltip: 'Save to Job',
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ZaftoSaveToJob.show(
          context,
          ref,
          calculatorId: calculatorId,
          calculatorName: calculatorName,
          inputs: inputs,
          outputs: outputs,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.accentPrimary.withValues(alpha: 0.1),
          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.briefcase, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'Save to Job',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SAVE TO JOB DIALOG/SHEET
// ============================================================

/// Static helper class for showing save to job UI
class ZaftoSaveToJob {
  ZaftoSaveToJob._();

  static const String _boxName = 'job_calculations';

  /// Show the save to job bottom sheet
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref, {
    required String calculatorId,
    required String calculatorName,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveToJobSheet(
        calculatorId: calculatorId,
        calculatorName: calculatorName,
        inputs: inputs,
        outputs: outputs,
      ),
    );
    return result ?? false;
  }

  /// Quick save to active job (if one exists)
  static Future<bool> quickSave(
    WidgetRef ref, {
    required String calculatorId,
    required String calculatorName,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
    required String jobId,
  }) async {
    try {
      final service = ref.read(jobServiceProvider);
      final job = await service.getJob(jobId);
      if (job == null) return false;

      final record = QuickCalculationRecord.create(
        calculatorId: calculatorId,
        calculatorName: calculatorName,
        inputs: inputs,
        outputs: outputs,
      );

      // Save calculation record to Hive box (keyed by job ID)
      await _saveCalculationRecord(record, jobId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save calculation record to Hive box
  static Future<void> _saveCalculationRecord(
    QuickCalculationRecord record,
    String jobId,
  ) async {
    Box<String> box;
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<String>(_boxName);
    } else {
      box = Hive.box<String>(_boxName);
    }

    // Store with job prefix for easy lookup
    await box.put('${jobId}_${record.id}', jsonEncode(record.toJson()));
  }

  /// Get calculations for a job
  static Future<List<QuickCalculationRecord>> getCalculationsForJob(
    String jobId,
  ) async {
    Box<String> box;
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<String>(_boxName);
    } else {
      box = Hive.box<String>(_boxName);
    }

    final records = <QuickCalculationRecord>[];
    for (final key in box.keys) {
      if (key.toString().startsWith('${jobId}_')) {
        final json = box.get(key);
        if (json != null) {
          try {
            records.add(QuickCalculationRecord.fromJson(jsonDecode(json)));
          } catch (_) {}
        }
      }
    }

    records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return records;
  }

  /// Delete a calculation record
  static Future<void> deleteCalculation(String jobId, String calculationId) async {
    Box<String> box;
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<String>(_boxName);
    } else {
      box = Hive.box<String>(_boxName);
    }

    await box.delete('${jobId}_$calculationId');
  }

  /// Delete all calculations for a job
  static Future<void> deleteAllCalculationsForJob(String jobId) async {
    Box<String> box;
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<String>(_boxName);
    } else {
      box = Hive.box<String>(_boxName);
    }

    final keysToDelete = box.keys
        .where((key) => key.toString().startsWith('${jobId}_'))
        .toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }
}

// ============================================================
// BOTTOM SHEET IMPLEMENTATION
// ============================================================

class _SaveToJobSheet extends ConsumerStatefulWidget {
  final String calculatorId;
  final String calculatorName;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;

  const _SaveToJobSheet({
    required this.calculatorId,
    required this.calculatorName,
    required this.inputs,
    required this.outputs,
  });

  @override
  ConsumerState<_SaveToJobSheet> createState() => _SaveToJobSheetState();
}

class _SaveToJobSheetState extends ConsumerState<_SaveToJobSheet> {
  String? _selectedJobId;
  bool _saving = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedJobId == null) return;

    setState(() => _saving = true);

    try {
      final service = ref.read(jobServiceProvider);
      final job = await service.getJob(_selectedJobId!);
      if (job == null) throw Exception('Job not found');

      final record = QuickCalculationRecord.create(
        calculatorId: widget.calculatorId,
        calculatorName: widget.calculatorName,
        inputs: widget.inputs,
        outputs: widget.outputs,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Save calculation record to Hive box (keyed by job ID)
      await ZaftoSaveToJob._saveCalculationRecord(record, _selectedJobId!);

      // Refresh jobs
      ref.read(jobsProvider.notifier).loadJobs();

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${job.displayTitle}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save calculation'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(LucideIcons.briefcase, color: colors.accentPrimary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save to Job',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.calculatorName,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: colors.borderSubtle, height: 1),
          // Output preview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESULTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.outputs.entries.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(fontSize: 13, color: colors.textSecondary),
                          ),
                          Text(
                            '${e.value}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (widget.outputs.length > 3)
                  Text(
                    '+${widget.outputs.length - 3} more',
                    style: TextStyle(fontSize: 11, color: colors.textTertiary),
                  ),
              ],
            ),
          ),
          // Notes field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notesController,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add notes (optional)',
                hintStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Job list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT JOB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading jobs', style: TextStyle(color: colors.textSecondary)),
              ),
              data: (jobs) {
                final activeJobs = jobs.where((j) =>
                  j.status != JobStatus.completed &&
                  j.status != JobStatus.invoiced &&
                  j.status != JobStatus.cancelled
                ).toList();

                if (activeJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.inbox, size: 48, color: colors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No active jobs',
                          style: TextStyle(fontSize: 15, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a job first to save calculations',
                          style: TextStyle(fontSize: 13, color: colors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeJobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final job = activeJobs[index];
                    final isSelected = _selectedJobId == job.id;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedJobId = job.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentPrimary.withValues(alpha: 0.1)
                              : colors.bgBase,
                          border: Border.all(
                            color: isSelected
                                ? colors.accentPrimary
                                : colors.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.accentPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.briefcase,
                                size: 20,
                                color: colors.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.displayTitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${job.customerName.isNotEmpty ? job.customerName : 'No customer'} - ${job.statusLabel}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                LucideIcons.checkCircle,
                                size: 20,
                                color: colors.accentPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedJobId == null || _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: colors.bgElevated,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Calculation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
