// ZAFTO Schedule Baseline Screen
// GC6: Baseline list, capture, comparison, variance report, EVM metrics.
// Max 5 baselines per project. Active baseline highlighted.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/schedule_baseline.dart';
import '../../models/schedule_baseline_task.dart';
import '../../providers/schedule_baselines_provider.dart';

class ScheduleBaselineScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const ScheduleBaselineScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ScheduleBaselineScreen> createState() => _ScheduleBaselineScreenState();
}

class _ScheduleBaselineScreenState extends ConsumerState<ScheduleBaselineScreen> {
  bool _capturing = false;
  String? _expandedBaselineId;
  List<ScheduleBaselineTask>? _expandedTasks;
  Map<String, dynamic>? _varianceData;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final baselinesAsync = ref.watch(scheduleBaselinesProvider(widget.projectId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baselines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            Text(widget.projectName, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          ],
        ),
      ),
      body: baselinesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _buildErrorState(colors, e),
        data: (baselines) {
          if (baselines.isEmpty) return _buildEmptyState(colors);
          return _buildBaselineList(colors, baselines);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _capturing ? null : () => _captureBaseline(context),
        backgroundColor: _capturing ? colors.fillDefault : colors.accentPrimary,
        icon: _capturing
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary))
            : Icon(LucideIcons.camera, color: colors.isDark ? Colors.black : Colors.white),
        label: Text(
          _capturing ? 'Capturing...' : 'Capture Baseline',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _capturing ? colors.textSecondary : (colors.isDark ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBaselineList(ZaftoColors colors, List<ScheduleBaseline> baselines) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleBaselinesProvider(widget.projectId)),
      color: colors.accentPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: baselines.length,
        itemBuilder: (context, index) => _buildBaselineCard(colors, baselines[index], baselines.length),
      ),
    );
  }

  Widget _buildBaselineCard(ZaftoColors colors, ScheduleBaseline baseline, int totalCount) {
    final isExpanded = _expandedBaselineId == baseline.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseline.isActive ? colors.accentPrimary.withValues(alpha: 0.5) : colors.borderSubtle,
          width: baseline.isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleExpand(baseline.id),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: baseline.isActive
                              ? colors.accentPrimary.withValues(alpha: 0.1)
                              : colors.fillDefault,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.bookmark,
                          size: 20,
                          color: baseline.isActive ? colors.accentPrimary : colors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    baseline.name,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (baseline.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.accentPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.accentPrimary)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BL #${baseline.baselineNumber}  |  ${_formatDate(baseline.capturedAt)}',
                              style: TextStyle(fontSize: 12, color: colors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 18,
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _buildStat(colors, 'Tasks', baseline.totalTasks.toString()),
                      _buildStat(colors, 'Milestones', baseline.totalMilestones.toString()),
                      _buildStat(colors, 'Cost', '\$${_formatCost(baseline.totalCost)}'),
                      if (baseline.plannedStart != null && baseline.plannedFinish != null)
                        _buildStat(
                          colors,
                          'Duration',
                          '${baseline.plannedFinish!.difference(baseline.plannedStart!).inDays}d',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (isExpanded) ...[
            Divider(height: 1, color: colors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (baseline.description != null && baseline.description!.isNotEmpty) ...[
                    Text(baseline.description!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                    const SizedBox(height: 12),
                  ],
                  // Dates
                  if (baseline.plannedStart != null || baseline.plannedFinish != null)
                    _buildDetailRow(colors, 'Schedule',
                        '${baseline.plannedStart != null ? _formatDate(baseline.plannedStart!) : '—'} to ${baseline.plannedFinish != null ? _formatDate(baseline.plannedFinish!) : '—'}'),
                  if (baseline.dataDate != null)
                    _buildDetailRow(colors, 'Data Date', _formatDate(baseline.dataDate!)),
                  const SizedBox(height: 12),

                  // Task snapshot
                  if (_expandedTasks != null) ...[
                    Text('Task Snapshot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 8),
                    ..._buildTaskSnapshot(colors, _expandedTasks!),
                    const SizedBox(height: 12),
                  ],

                  // Variance report
                  if (_varianceData != null) ...[
                    Text('Variance Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 8),
                    _buildVarianceSummary(colors, _varianceData!),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _loadVariance(baseline),
                          icon: Icon(LucideIcons.barChart2, size: 16, color: colors.accentPrimary),
                          label: Text('Variance', style: TextStyle(fontSize: 12, color: colors.accentPrimary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: totalCount <= 1 ? null : () => _deleteBaseline(baseline),
                          icon: Icon(LucideIcons.trash2, size: 16, color: colors.accentError),
                          label: Text('Delete', style: TextStyle(fontSize: 12, color: colors.accentError)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(ZaftoColors colors, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary))),
        ],
      ),
    );
  }

  List<Widget> _buildTaskSnapshot(ZaftoColors colors, List<ScheduleBaselineTask> tasks) {
    final criticalCount = tasks.where((t) => t.isCritical == true).length;
    final milestones = tasks.where((t) => t.taskType == 'milestone').length;
    final totalCost = tasks.fold(0.0, (sum, t) => sum + (t.budgetedCost ?? 0));
    final avgProgress = tasks.isEmpty ? 0.0 : tasks.fold(0.0, (sum, t) => sum + (t.percentComplete ?? 0)) / tasks.length;

    return [
      _buildSnapshotRow(colors, LucideIcons.listTodo, '${tasks.length} tasks', '$criticalCount critical'),
      _buildSnapshotRow(colors, LucideIcons.flag, '$milestones milestones', '\$${_formatCost(totalCost)} budget'),
      _buildSnapshotRow(colors, LucideIcons.activity, '${avgProgress.toStringAsFixed(1)}% avg complete', ''),
    ];
  }

  Widget _buildSnapshotRow(ZaftoColors colors, IconData icon, String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textTertiary),
          const SizedBox(width: 8),
          Text(left, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          const Spacer(),
          Text(right, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildVarianceSummary(ZaftoColors colors, Map<String, dynamic> data) {
    final tasks = data['tasks'] as List<Map<String, dynamic>>? ?? [];
    if (tasks.isEmpty) {
      return Text('No matching tasks for comparison.', style: TextStyle(fontSize: 12, color: colors.textTertiary));
    }

    final ahead = tasks.where((t) => t['status'] == 'ahead').length;
    final behind = tasks.where((t) => t['status'] == 'behind').length;
    final onTime = tasks.where((t) => t['status'] == 'on_time').length;

    return Column(
      children: [
        Row(
          children: [
            _buildVarianceChip(colors, '$ahead ahead', colors.accentSuccess),
            const SizedBox(width: 8),
            _buildVarianceChip(colors, '$onTime on time', colors.accentInfo),
            const SizedBox(width: 8),
            _buildVarianceChip(colors, '$behind behind', colors.accentError),
          ],
        ),
        if (behind > 0) ...[
          const SizedBox(height: 8),
          ...tasks.where((t) => t['status'] == 'behind').take(5).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 12, color: colors.accentWarning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t['task_name'] as String? ?? 'Unknown',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+${t['finish_variance_days']}d',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.accentError),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildVarianceChip(ZaftoColors colors, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.bookmark, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No baselines yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Capture a baseline to snapshot your current schedule',
              style: TextStyle(fontSize: 14, color: colors.textTertiary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Max 5 baselines per project', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(ZaftoColors colors, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 40, color: colors.accentError),
          const SizedBox(height: 12),
          Text('Failed to load baselines', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(scheduleBaselinesProvider(widget.projectId)),
            child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════

  void _toggleExpand(String baselineId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedBaselineId == baselineId) {
        _expandedBaselineId = null;
        _expandedTasks = null;
        _varianceData = null;
      } else {
        _expandedBaselineId = baselineId;
        _expandedTasks = null;
        _varianceData = null;
        _loadBaselineTasks(baselineId);
      }
    });
  }

  Future<void> _loadBaselineTasks(String baselineId) async {
    try {
      final repo = ref.read(scheduleBaselineRepoProvider);
      final tasks = await repo.getBaselineTasks(baselineId);
      if (mounted && _expandedBaselineId == baselineId) {
        setState(() => _expandedTasks = tasks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  Future<void> _loadVariance(ScheduleBaseline baseline) async {
    try {
      final repo = ref.read(scheduleBaselineRepoProvider);
      final baselineTasks = await repo.getBaselineTasks(baseline.id);

      // Fetch current tasks
      final supabase = Supabase.instance.client;
      final currentResponse = await supabase
          .from('schedule_tasks')
          .select('id, name, early_start, early_finish, planned_start, planned_finish')
          .eq('project_id', widget.projectId)
          .isFilter('deleted_at', null);

      final currentTasks = currentResponse as List;
      final currentMap = <String, Map<String, dynamic>>{};
      for (final ct in currentTasks) {
        final row = ct as Map<String, dynamic>;
        currentMap[row['id'] as String] = row;
      }

      final varianceRows = <Map<String, dynamic>>[];
      for (final bt in baselineTasks) {
        final ct = currentMap[bt.taskId];
        if (ct == null) continue;

        final bStart = bt.plannedStart;
        final bFinish = bt.plannedFinish;
        final cStartStr = ct['early_start'] ?? ct['planned_start'];
        final cFinishStr = ct['early_finish'] ?? ct['planned_finish'];
        final cStart = cStartStr != null ? DateTime.tryParse(cStartStr.toString()) : null;
        final cFinish = cFinishStr != null ? DateTime.tryParse(cFinishStr.toString()) : null;

        final startVar = bStart != null && cStart != null ? cStart.difference(bStart).inDays : 0;
        final finishVar = bFinish != null && cFinish != null ? cFinish.difference(bFinish).inDays : 0;

        String status = 'on_time';
        if (finishVar > 0) {
          status = 'behind';
        } else if (finishVar < 0) {
          status = 'ahead';
        }

        varianceRows.add({
          'task_id': bt.taskId,
          'task_name': bt.name ?? ct['name'] ?? 'Unnamed',
          'start_variance_days': startVar,
          'finish_variance_days': finishVar,
          'status': status,
        });
      }

      if (mounted) {
        setState(() => _varianceData = {'tasks': varianceRows});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to compute variance: $e')),
        );
      }
    }
  }

  Future<void> _captureBaseline(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final colors = ref.read(zaftoColorsProvider);
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: colors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capture Baseline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Snapshot all current task data (max 5 per project)', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Baseline Name',
                hintText: 'e.g., Original Schedule',
                labelStyle: TextStyle(color: colors.textTertiary),
                hintStyle: TextStyle(color: colors.textTertiary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.accentPrimary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.accentPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(ctx, {'name': name, 'notes': notesController.text.trim()});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Capture', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _capturing = true);
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      final response = await supabase.functions.invoke(
        'schedule-baseline-capture',
        body: {
          'project_id': widget.projectId,
          'name': result['name'],
          'notes': result['notes'],
        },
      );

      final data = response.data as Map<String, dynamic>?;

      ref.invalidate(scheduleBaselinesProvider(widget.projectId));

      if (mounted && data != null) {
        final evm = data['evm'] as Map<String, dynamic>?;
        final tasksCount = data['tasks_captured'] as int? ?? 0;
        final spi = (evm?['spi'] as num?)?.toDouble() ?? 0;
        final cpi = (evm?['cpi'] as num?)?.toDouble() ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baseline captured: $tasksCount tasks  |  SPI: ${spi.toStringAsFixed(2)}  |  CPI: ${cpi.toStringAsFixed(2)}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _deleteBaseline(ScheduleBaseline baseline) async {
    final colors = ref.read(zaftoColorsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Baseline?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'This will permanently delete "${baseline.name}" and its task snapshot. This cannot be undone.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(scheduleBaselineRepoProvider);
      await repo.deleteBaseline(baseline.id);
      ref.invalidate(scheduleBaselinesProvider(widget.projectId));

      if (mounted) {
        setState(() {
          if (_expandedBaselineId == baseline.id) {
            _expandedBaselineId = null;
            _expandedTasks = null;
            _varianceData = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Baseline "${baseline.name}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FORMATTERS
  // ══════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatCost(double cost) {
    if (cost >= 1000000) return '${(cost / 1000000).toStringAsFixed(1)}M';
    if (cost >= 1000) return '${(cost / 1000).toStringAsFixed(1)}K';
    return cost.toStringAsFixed(0);
  }
}
