// ZAFTO Clearance Testing Screen
// Third-party clearance coordination, spore counts, pass/fail determination
// Sprint REST2 — Mold remediation dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/mold_assessment.dart';

class ClearanceTestingScreen extends ConsumerStatefulWidget {
  final String moldAssessmentId;

  const ClearanceTestingScreen({
    super.key,
    required this.moldAssessmentId,
  });

  @override
  ConsumerState<ClearanceTestingScreen> createState() =>
      _ClearanceTestingScreenState();
}

class _ClearanceTestingScreenState
    extends ConsumerState<ClearanceTestingScreen> {
  MoldAssessment? _assessment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }

  Future<void> _loadAssessment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('mold_assessments')
          .select()
          .eq('id', widget.moldAssessmentId)
          .single();

      _assessment = MoldAssessment.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateClearanceField(Map<String, dynamic> updates) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('mold_assessments')
          .update(updates)
          .eq('id', widget.moldAssessmentId);

      await _loadAssessment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setClearanceStatus(MoldClearanceStatus status) async {
    final updates = <String, dynamic>{
      'clearance_status': status.dbValue,
    };

    if (status == MoldClearanceStatus.passed ||
        status == MoldClearanceStatus.failed) {
      updates['clearance_date'] = DateTime.now().toUtc().toIso8601String();
    }

    // Also update assessment status
    if (status == MoldClearanceStatus.passed) {
      updates['assessment_status'] = 'cleared';
    } else if (status == MoldClearanceStatus.failed) {
      updates['assessment_status'] = 'failed_clearance';
    }

    await _updateClearanceField(updates);
  }

  Future<void> _editClearanceInspector() async {
    final inspectorCtrl =
        TextEditingController(text: _assessment?.clearanceInspector ?? '');
    final companyCtrl =
        TextEditingController(text: _assessment?.clearanceCompany ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return AlertDialog(
          title: const Text('Clearance Inspector'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: inspectorCtrl,
                decoration: const InputDecoration(
                    labelText: 'Inspector Name', isDense: true),
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: companyCtrl,
                decoration: const InputDecoration(
                    labelText: 'IH / Inspection Company', isDense: true),
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, {
                  'inspector': inspectorCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _updateClearanceField({
      'clearance_inspector': result['inspector'],
      'clearance_company': result['company'],
    });
  }

  Future<void> _editSporeCount({required bool isPre}) async {
    final controller = TextEditingController(
      text: isPre
          ? _assessment?.sporeCountBefore?.toStringAsFixed(0) ?? ''
          : _assessment?.sporeCountAfter?.toStringAsFixed(0) ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return AlertDialog(
          title: Text(isPre
              ? 'Pre-Remediation Spore Count'
              : 'Post-Remediation Spore Count'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Spore Count (spores/m³)',
                  hintText: 'e.g., 12500',
                  isDense: true,
                ),
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                isPre
                    ? 'Enter the highest indoor spore count from pre-remediation air sampling.'
                    : 'Enter the highest indoor spore count from post-remediation air sampling.',
                style: TextStyle(fontSize: 11, color: colors.textTertiary),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.pop(ctx, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _updateClearanceField({
      isPre ? 'spore_count_before' : 'spore_count_after': result,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Clearance Testing')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: TextStyle(color: colors.textSecondary)),
                      TextButton(
                          onPressed: _loadAssessment,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _assessment == null
                  ? Center(
                      child: Text('Assessment not found',
                          style: TextStyle(color: colors.textSecondary)))
                  : _buildContent(colors),
    );
  }

  Widget _buildContent(ZaftoColors colors) {
    final a = _assessment!;
    final needsClearance = a.needsClearance;
    final reduction = a.sporeReduction;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Clearance requirement
        if (!needsClearance)
          _infoCard(colors, LucideIcons.info,
              'Clearance testing is NOT required for ${a.iicrcLevel.label}. '
              'However, post-remediation verification is always recommended.',
              cardColor: Colors.blue),

        if (needsClearance)
          _infoCard(colors, LucideIcons.alertTriangle,
              'Clearance testing is REQUIRED for ${a.iicrcLevel.label}. '
              'A third-party inspector (not the remediator) must verify the work.',
              cardColor: Colors.amber),

        // Current status
        const SizedBox(height: 16),
        _sectionHeader(colors, 'CLEARANCE STATUS'),
        const SizedBox(height: 8),
        _buildStatusCard(colors, a),

        // Inspector info
        const SizedBox(height: 20),
        _sectionHeader(colors, 'CLEARANCE INSPECTOR'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _editClearanceInspector,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.user, size: 18, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.clearanceInspector?.isNotEmpty == true
                            ? a.clearanceInspector!
                            : 'Tap to add inspector',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: a.clearanceInspector?.isNotEmpty == true
                              ? colors.textPrimary
                              : colors.textTertiary,
                        ),
                      ),
                      if (a.clearanceCompany?.isNotEmpty == true)
                        Text(a.clearanceCompany!,
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 16, color: colors.textTertiary),
              ],
            ),
          ),
        ),

        // Spore counts
        const SizedBox(height: 20),
        _sectionHeader(colors, 'SPORE COUNTS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSporeCard(
                colors,
                'Pre-Remediation',
                a.sporeCountBefore,
                onTap: () => _editSporeCount(isPre: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSporeCard(
                colors,
                'Post-Remediation',
                a.sporeCountAfter,
                onTap: () => _editSporeCount(isPre: false),
              ),
            ),
          ],
        ),

        // Reduction percentage
        if (a.sporeCountBefore != null && a.sporeCountAfter != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: reduction >= 80
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: reduction >= 80 ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  reduction >= 80
                      ? LucideIcons.trendingDown
                      : LucideIcons.alertTriangle,
                  size: 20,
                  color: reduction >= 80 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  '${reduction.toStringAsFixed(1)}% spore reduction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: reduction >= 80 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Clearance criteria
        const SizedBox(height: 20),
        _sectionHeader(colors, 'CLEARANCE CRITERIA'),
        const SizedBox(height: 8),
        _criteriaItem(colors, 'No visible mold growth on remediated surfaces'),
        _criteriaItem(colors, 'Moisture levels within normal range (<16% wood, <1% drywall)'),
        _criteriaItem(colors, 'Indoor spore counts at or below outdoor baseline'),
        _criteriaItem(colors, 'No musty/moldy odor detected'),
        _criteriaItem(colors, 'Containment intact and properly maintained'),
        _criteriaItem(colors, 'All affected materials properly removed and disposed'),
        _criteriaItem(colors, 'Work area clean — no debris or dust'),

        // Pass / Fail buttons
        const SizedBox(height: 24),
        _sectionHeader(colors, 'DETERMINATION'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: a.clearanceStatus == MoldClearanceStatus.passed
                      ? null
                      : () => _setClearanceStatus(MoldClearanceStatus.passed),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('PASS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor:
                        Colors.green.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: a.clearanceStatus == MoldClearanceStatus.failed
                      ? null
                      : () => _setClearanceStatus(MoldClearanceStatus.failed),
                  icon: const Icon(Icons.cancel),
                  label: const Text('FAIL'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (a.clearanceStatus == MoldClearanceStatus.failed) ...[
          const SizedBox(height: 12),
          _infoCard(colors, LucideIcons.alertTriangle,
              'Clearance FAILED. Re-remediation is required. '
              'Review protocol steps, repeat cleaning, and schedule new clearance testing.',
              cardColor: Colors.red),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatusCard(ZaftoColors colors, MoldAssessment a) {
    Color statusColor;
    IconData statusIcon;
    switch (a.clearanceStatus) {
      case MoldClearanceStatus.passed:
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle;
      case MoldClearanceStatus.failed:
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
      case MoldClearanceStatus.awaitingResults:
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
      case MoldClearanceStatus.sampling:
        statusColor = Colors.blue;
        statusIcon = LucideIcons.testTubes;
      case MoldClearanceStatus.notRequired:
        statusColor = Colors.grey;
        statusIcon = LucideIcons.minusCircle;
      default:
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 24, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.clearanceStatus.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: statusColor)),
                if (a.clearanceDate != null)
                  Text(
                    'Date: ${a.clearanceDate!.month}/${a.clearanceDate!.day}/${a.clearanceDate!.year}',
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          // Status workflow buttons
          if (a.clearanceStatus == MoldClearanceStatus.pending)
            TextButton(
              onPressed: () =>
                  _setClearanceStatus(MoldClearanceStatus.sampling),
              child: const Text('Start Sampling'),
            ),
          if (a.clearanceStatus == MoldClearanceStatus.sampling)
            TextButton(
              onPressed: () =>
                  _setClearanceStatus(MoldClearanceStatus.awaitingResults),
              child: const Text('Awaiting Results'),
            ),
        ],
      ),
    );
  }

  Widget _buildSporeCard(
    ZaftoColors colors,
    String label,
    double? value, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary)),
            const SizedBox(height: 6),
            Text(
              value != null ? '${value.toStringAsFixed(0)} sp/m³' : 'Tap to enter',
              style: TextStyle(
                fontSize: value != null ? 18 : 13,
                fontWeight: value != null ? FontWeight.w700 : FontWeight.w400,
                color:
                    value != null ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criteriaItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.checkSquare,
                size: 14, color: colors.textTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ZaftoColors colors, IconData icon, String text,
      {Color cardColor = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cardColor),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: colors.textTertiary));
  }
}
