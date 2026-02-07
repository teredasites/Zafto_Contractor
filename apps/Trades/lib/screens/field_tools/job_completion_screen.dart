import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../core/supabase_client.dart';

// Job Completion — Validates all requirements before marking job complete.
// Auto-checks: punch list, photos, signature, time entries, materials, daily log, change orders.
// Insurance claims get 4 extra checks: moisture, equipment, drying, TPI.
class JobCompletionScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const JobCompletionScreen({super.key, this.jobId});

  @override
  ConsumerState<JobCompletionScreen> createState() =>
      _JobCompletionScreenState();
}

class _CompletionCheck {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  bool isChecked;
  bool isLoading;
  String? detail;

  _CompletionCheck({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  })  : isChecked = false,
        isLoading = true,
        detail = null;
}

class _JobCompletionScreenState extends ConsumerState<JobCompletionScreen> {
  late List<_CompletionCheck> _checks;
  bool _isCompleting = false;
  bool _jobAlreadyComplete = false;
  bool _isInsuranceClaim = false;
  String? _claimId;

  @override
  void initState() {
    super.initState();
    _checks = [
      _CompletionCheck(
        id: 'punch_list',
        title: 'Punch List Complete',
        subtitle: 'All punch list items completed or skipped',
        icon: LucideIcons.checkSquare,
      ),
      _CompletionCheck(
        id: 'photos',
        title: 'Final Photos Taken',
        subtitle: 'At least one photo documented for the job',
        icon: LucideIcons.camera,
      ),
      _CompletionCheck(
        id: 'signature',
        title: 'Client Signature Captured',
        subtitle: 'Client has signed off on completed work',
        icon: LucideIcons.penTool,
      ),
      _CompletionCheck(
        id: 'time_entries',
        title: 'Time Entries Complete',
        subtitle: 'No active clock entries running',
        icon: LucideIcons.clock,
      ),
      _CompletionCheck(
        id: 'materials',
        title: 'Materials Logged',
        subtitle: 'Materials used on job have been recorded',
        icon: LucideIcons.package,
      ),
      _CompletionCheck(
        id: 'daily_log',
        title: 'Daily Log Submitted',
        subtitle: 'Today\'s daily log has been submitted',
        icon: LucideIcons.clipboardList,
      ),
      _CompletionCheck(
        id: 'change_orders',
        title: 'Change Orders Resolved',
        subtitle: 'All change orders approved, rejected, or voided',
        icon: LucideIcons.fileDiff,
      ),
    ];
    if (widget.jobId != null) {
      _detectJobTypeAndRunChecks();
    } else {
      for (final c in _checks) {
        c.isLoading = false;
      }
    }
  }

  Future<void> _detectJobTypeAndRunChecks() async {
    try {
      final jobResponse = await supabase
          .from('jobs')
          .select('job_type')
          .eq('id', widget.jobId!)
          .single();

      if (jobResponse['job_type'] == 'insurance_claim') {
        _isInsuranceClaim = true;

        // Look up the claim for this job
        final claimResponse = await supabase
            .from('insurance_claims')
            .select('id')
            .eq('job_id', widget.jobId!)
            .limit(1);
        final claimRows = claimResponse as List;
        if (claimRows.isNotEmpty) {
          _claimId = claimRows[0]['id'] as String;
        }

        // Add insurance-specific checks
        _checks.addAll([
          _CompletionCheck(
            id: 'moisture_target',
            title: 'Moisture Readings at Target',
            subtitle: 'All moisture readings show dry conditions',
            icon: LucideIcons.droplets,
          ),
          _CompletionCheck(
            id: 'equipment_removed',
            title: 'All Equipment Removed',
            subtitle: 'Restoration equipment returned or removed',
            icon: LucideIcons.wrench,
          ),
          _CompletionCheck(
            id: 'drying_complete',
            title: 'Drying Completion Logged',
            subtitle: 'Drying log has a completion entry',
            icon: LucideIcons.thermometer,
          ),
          _CompletionCheck(
            id: 'tpi_passed',
            title: 'TPI Final Inspection Passed',
            subtitle: 'Third-party inspector approved the work',
            icon: LucideIcons.clipboardCheck,
          ),
        ]);

        if (mounted) setState(() {});
      }
    } catch (_) {
      // Non-insurance job or error — proceed with standard checks
    }

    _runAllChecks();
  }

  Future<void> _runAllChecks() async {
    final futures = <Future>[
      _checkPunchList(),
      _checkPhotos(),
      _checkSignature(),
      _checkTimeEntries(),
      _checkMaterials(),
      _checkDailyLog(),
      _checkChangeOrders(),
      _checkJobStatus(),
    ];

    if (_isInsuranceClaim) {
      futures.addAll([
        _checkMoistureTarget(),
        _checkEquipmentRemoved(),
        _checkDryingComplete(),
        _checkTpiPassed(),
      ]);
    }

    await Future.wait(futures);
  }

  Future<void> _checkPunchList() async {
    final check = _checks.firstWhere((c) => c.id == 'punch_list');
    try {
      final response = await supabase
          .from('punch_list_items')
          .select('id, status')
          .eq('job_id', widget.jobId!);

      final items = response as List;
      if (items.isEmpty) {
        check.isChecked = true;
        check.detail = 'No punch list items';
      } else {
        final open = items.where((r) =>
            r['status'] == 'open' || r['status'] == 'in_progress').length;
        final total = items.length;
        check.isChecked = open == 0;
        check.detail = '${total - open}/$total completed';
      }
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkPhotos() async {
    final check = _checks.firstWhere((c) => c.id == 'photos');
    try {
      final response = await supabase
          .from('photos')
          .select('id')
          .eq('job_id', widget.jobId!)
          .limit(1);

      final items = response as List;
      check.isChecked = items.isNotEmpty;
      check.detail = items.isNotEmpty ? 'Photos on file' : 'No photos found';
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkSignature() async {
    final check = _checks.firstWhere((c) => c.id == 'signature');
    try {
      final response = await supabase
          .from('signatures')
          .select('id')
          .eq('job_id', widget.jobId!)
          .limit(1);

      final items = response as List;
      check.isChecked = items.isNotEmpty;
      check.detail = items.isNotEmpty ? 'Signature captured' : 'No signature';
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkTimeEntries() async {
    final check = _checks.firstWhere((c) => c.id == 'time_entries');
    try {
      final response = await supabase
          .from('time_entries')
          .select('id')
          .eq('job_id', widget.jobId!)
          .isFilter('clock_out', null)
          .limit(1);

      final items = response as List;
      check.isChecked = items.isEmpty;
      check.detail = items.isEmpty ? 'No active clocks' : 'Clock still running';
    } catch (_) {
      check.isChecked = true;
      check.detail = 'No time tracking data';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkMaterials() async {
    final check = _checks.firstWhere((c) => c.id == 'materials');
    try {
      final response = await supabase
          .from('job_materials')
          .select('id')
          .eq('job_id', widget.jobId!)
          .isFilter('deleted_at', null)
          .limit(1);

      final items = response as List;
      check.isChecked = items.isNotEmpty;
      check.detail = items.isNotEmpty ? 'Materials logged' : 'No materials logged';
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkDailyLog() async {
    final check = _checks.firstWhere((c) => c.id == 'daily_log');
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('daily_logs')
          .select('id')
          .eq('job_id', widget.jobId!)
          .eq('log_date', dateStr)
          .limit(1);

      final items = response as List;
      check.isChecked = items.isNotEmpty;
      check.detail = items.isNotEmpty ? 'Today\'s log submitted' : 'No log for today';
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkChangeOrders() async {
    final check = _checks.firstWhere((c) => c.id == 'change_orders');
    try {
      final response = await supabase
          .from('change_orders')
          .select('id, status')
          .eq('job_id', widget.jobId!);

      final items = response as List;
      if (items.isEmpty) {
        check.isChecked = true;
        check.detail = 'No change orders';
      } else {
        final unresolved = items.where((r) =>
            r['status'] == 'draft' || r['status'] == 'pending_approval').length;
        check.isChecked = unresolved == 0;
        check.detail = unresolved == 0
            ? 'All ${items.length} resolved'
            : '$unresolved unresolved';
      }
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  // ==================== INSURANCE-SPECIFIC CHECKS ====================

  Future<void> _checkMoistureTarget() async {
    final check = _checks.firstWhere((c) => c.id == 'moisture_target');
    try {
      final response = await supabase
          .from('moisture_readings')
          .select('id, is_dry')
          .eq('job_id', widget.jobId!);

      final items = response as List;
      if (items.isEmpty) {
        check.isChecked = false;
        check.detail = 'No moisture readings recorded';
      } else {
        final notDry = items.where((r) => r['is_dry'] != true).length;
        check.isChecked = notDry == 0;
        check.detail = notDry == 0
            ? 'All ${items.length} readings at target'
            : '$notDry of ${items.length} still wet';
      }
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkEquipmentRemoved() async {
    final check = _checks.firstWhere((c) => c.id == 'equipment_removed');
    try {
      final response = await supabase
          .from('restoration_equipment')
          .select('id, status')
          .eq('job_id', widget.jobId!);

      final items = response as List;
      if (items.isEmpty) {
        check.isChecked = true;
        check.detail = 'No equipment deployed';
      } else {
        final stillDeployed = items.where((r) =>
            r['status'] == 'deployed' || r['status'] == 'maintenance').length;
        check.isChecked = stillDeployed == 0;
        check.detail = stillDeployed == 0
            ? 'All ${items.length} pieces removed'
            : '$stillDeployed still on site';
      }
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkDryingComplete() async {
    final check = _checks.firstWhere((c) => c.id == 'drying_complete');
    try {
      final response = await supabase
          .from('drying_logs')
          .select('id')
          .eq('job_id', widget.jobId!)
          .eq('log_type', 'completion')
          .limit(1);

      final items = response as List;
      check.isChecked = items.isNotEmpty;
      check.detail = items.isNotEmpty
          ? 'Drying completion logged'
          : 'No completion entry in drying log';
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkTpiPassed() async {
    final check = _checks.firstWhere((c) => c.id == 'tpi_passed');
    if (_claimId == null) {
      check.isChecked = false;
      check.detail = 'No linked insurance claim';
      check.isLoading = false;
      if (mounted) setState(() {});
      return;
    }
    try {
      final response = await supabase
          .from('tpi_scheduling')
          .select('id, inspection_type, status, result')
          .eq('claim_id', _claimId!)
          .eq('inspection_type', 'final_inspection');

      final items = response as List;
      if (items.isEmpty) {
        check.isChecked = false;
        check.detail = 'No final inspection scheduled';
      } else {
        final passed = items.any(
            (r) => r['status'] == 'completed' && r['result'] == 'passed');
        check.isChecked = passed;
        check.detail = passed
            ? 'Final inspection passed'
            : 'Final inspection not yet passed';
      }
    } catch (_) {
      check.detail = 'Could not verify';
    }
    check.isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _checkJobStatus() async {
    try {
      final response = await supabase
          .from('jobs')
          .select('status')
          .eq('id', widget.jobId!)
          .single();

      if (response['status'] == 'completed') {
        _jobAlreadyComplete = true;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  bool get _allChecked =>
      _checks.every((c) => c.isChecked) &&
      _checks.every((c) => !c.isLoading);

  bool get _anyLoading => _checks.any((c) => c.isLoading);

  int get _checkedCount => _checks.where((c) => c.isChecked).length;

  double get _progress =>
      _checks.isEmpty ? 0 : _checkedCount / _checks.length;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _isInsuranceClaim ? 'Insurance Completion' : 'Job Completion',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (widget.jobId != null)
            IconButton(
              icon: Icon(LucideIcons.refreshCw, color: colors.textSecondary),
              onPressed: () {
                for (final c in _checks) {
                  c.isLoading = true;
                  c.isChecked = false;
                  c.detail = null;
                }
                _jobAlreadyComplete = false;
                setState(() {});
                _runAllChecks();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.jobId == null)
            _buildNoJobBanner(colors)
          else ...[
            if (_jobAlreadyComplete) _buildAlreadyCompleteBanner(colors),
            _buildProgressHeader(colors),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _checks.length,
              itemBuilder: (context, index) =>
                  _buildCheckItem(colors, _checks[index]),
            ),
          ),
          if (widget.jobId != null && !_jobAlreadyComplete)
            _buildCompleteButton(colors),
        ],
      ),
    );
  }

  Widget _buildNoJobBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Open from a job to run completion checklist',
                style: TextStyle(fontSize: 13, color: colors.accentWarning)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyCompleteBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
          const SizedBox(width: 12),
          Text('This job is already marked as completed',
              style: TextStyle(
                  fontSize: 13,
                  color: colors.accentSuccess,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _anyLoading
                    ? 'Checking requirements...'
                    : _allChecked
                        ? 'All requirements met'
                        : '$_checkedCount of ${_checks.length} requirements met',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary),
              ),
              if (!_anyLoading)
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _allChecked
                          ? colors.accentSuccess
                          : colors.accentPrimary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _anyLoading
                ? LinearProgressIndicator(
                    minHeight: 8,
                    backgroundColor: colors.fillDefault,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        colors.accentPrimary),
                  )
                : LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: colors.fillDefault,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _allChecked
                          ? colors.accentSuccess
                          : colors.accentPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, _CompletionCheck check) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: check.isChecked
              ? colors.accentSuccess.withOpacity(0.3)
              : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          SizedBox(
            width: 28,
            height: 28,
            child: check.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colors.textTertiary),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: check.isChecked
                          ? colors.accentSuccess
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: check.isChecked
                            ? colors.accentSuccess
                            : colors.borderSubtle,
                        width: 2,
                      ),
                    ),
                    child: check.isChecked
                        ? const Icon(LucideIcons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
          ),
          const SizedBox(width: 12),
          Icon(check.icon, size: 20,
              color: check.isChecked
                  ? colors.accentSuccess
                  : colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: check.isChecked
                            ? colors.textSecondary
                            : colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  check.detail ?? check.subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: check.isChecked
                          ? colors.accentSuccess
                          : colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(ZaftoColors colors) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isCompleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.checkCircle, size: 20),
            label: Text(
              _isCompleting ? 'Completing...' : 'Complete Job',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _allChecked ? colors.accentSuccess : colors.fillDefault,
              foregroundColor: _allChecked ? Colors.white : colors.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _allChecked && !_isCompleting
                ? () => _completeJob(colors)
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _completeJob(ZaftoColors colors) async {
    final dialogContent = _isInsuranceClaim
        ? 'The job will be completed and the insurance claim status will advance to "Work Complete".'
        : 'The job status will be set to completed. This can be undone from the job details screen.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete this job?'),
        content: Text(dialogContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Complete',
                  style: TextStyle(color: colors.accentSuccess))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCompleting = true);
    HapticFeedback.heavyImpact();

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await supabase.from('jobs').update({
        'status': 'completed',
        'completed_at': now,
      }).eq('id', widget.jobId!);

      // Advance insurance claim to work_complete
      if (_isInsuranceClaim && _claimId != null) {
        await supabase.from('insurance_claims').update({
          'claim_status': 'work_complete',
          'work_completed_at': now,
        }).eq('id', _claimId!);
      }

      if (mounted) {
        setState(() {
          _isCompleting = false;
          _jobAlreadyComplete = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isInsuranceClaim
                ? 'Job completed — claim advanced to Work Complete'
                : 'Job marked as completed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete job'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
