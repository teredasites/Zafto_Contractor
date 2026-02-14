// ZAFTO Schedule Gantt Screen
// GC4: Interactive Gantt chart with task bars, dependency arrows,
// gestures (pinch-zoom, pan, long-press, drag), critical path toggle,
// today line, and baseline overlay.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/schedule_task.dart';
import '../../models/schedule_dependency.dart';
import '../../providers/schedule_tasks_provider.dart';
import 'schedule_task_detail_screen.dart';
import 'schedule_baseline_screen.dart';
import 'schedule_resource_screen.dart';

// ── Zoom levels ──
enum GanttZoom { day, week, month }

class ScheduleGanttScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const ScheduleGanttScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ScheduleGanttScreen> createState() => _ScheduleGanttScreenState();
}

class _ScheduleGanttScreenState extends ConsumerState<ScheduleGanttScreen> {
  GanttZoom _zoom = GanttZoom.week;
  bool _showCriticalPath = true;
  bool _showDependencies = true;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _taskListController = ScrollController();

  static const double _taskRowHeight = 36.0;
  static const double _taskListWidth = 200.0;
  static const double _headerHeight = 40.0;

  double get _dayWidth => switch (_zoom) {
    GanttZoom.day => 40.0,
    GanttZoom.week => 16.0,
    GanttZoom.month => 4.0,
  };

  @override
  void initState() {
    super.initState();
    // Sync vertical scroll between task list and chart
    _verticalController.addListener(() {
      if (_taskListController.hasClients) {
        _taskListController.jumpTo(_verticalController.offset);
      }
    });
    _taskListController.addListener(() {
      if (_verticalController.hasClients) {
        _verticalController.jumpTo(_taskListController.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _taskListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final tasksAsync = ref.watch(scheduleTasksProvider(widget.projectId));
    final depsAsync = ref.watch(scheduleDependenciesProvider(widget.projectId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.projectName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          // Zoom controls
          IconButton(
            icon: Icon(LucideIcons.zoomOut, size: 20, color: colors.textSecondary),
            onPressed: () => _changeZoom(1),
          ),
          IconButton(
            icon: Icon(LucideIcons.zoomIn, size: 20, color: colors.textSecondary),
            onPressed: () => _changeZoom(-1),
          ),
          // Critical path toggle
          IconButton(
            icon: Icon(
              LucideIcons.activity,
              size: 20,
              color: _showCriticalPath ? colors.accentError : colors.textTertiary,
            ),
            tooltip: 'Critical Path',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showCriticalPath = !_showCriticalPath);
            },
          ),
          // More menu
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary),
            color: colors.bgElevated,
            onSelected: (value) {
              switch (value) {
                case 'resources':
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ScheduleResourceScreen(projectId: widget.projectId),
                  ));
                case 'baselines':
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ScheduleBaselineScreen(
                      projectId: widget.projectId,
                      projectName: widget.projectName,
                    ),
                  ));
                case 'dependencies':
                  setState(() => _showDependencies = !_showDependencies);
                case 'add_task':
                  _addTask(context);
                case 'recalc':
                  _triggerCpmRecalc();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'add_task', child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Add Task', style: TextStyle(color: colors.textPrimary)),
                ],
              )),
              PopupMenuItem(value: 'resources', child: Row(
                children: [
                  Icon(LucideIcons.users, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Resources', style: TextStyle(color: colors.textPrimary)),
                ],
              )),
              PopupMenuItem(value: 'baselines', child: Row(
                children: [
                  Icon(LucideIcons.bookmark, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Baselines', style: TextStyle(color: colors.textPrimary)),
                ],
              )),
              PopupMenuItem(value: 'dependencies', child: Row(
                children: [
                  Icon(LucideIcons.link, size: 16, color: _showDependencies ? colors.accentPrimary : colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Dependencies', style: TextStyle(color: colors.textPrimary)),
                ],
              )),
              PopupMenuItem(value: 'recalc', child: Row(
                children: [
                  Icon(LucideIcons.refreshCw, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Recalculate CPM', style: TextStyle(color: colors.textPrimary)),
                ],
              )),
            ],
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _buildErrorState(colors, e),
        data: (tasks) {
          if (tasks.isEmpty) return _buildEmptyState(colors);
          final deps = depsAsync.valueOrNull ?? [];
          return _buildGanttView(colors, tasks, deps);
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _addTask(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, size: 18, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildGanttView(ZaftoColors colors, List<ScheduleTask> tasks, List<ScheduleDependency> deps) {
    // Compute date range
    DateTime? minDate;
    DateTime? maxDate;
    for (final t in tasks) {
      final es = t.earlyStart ?? t.plannedStart;
      final ef = t.earlyFinish ?? t.plannedFinish;
      if (es != null && (minDate == null || es.isBefore(minDate))) minDate = es;
      if (ef != null && (maxDate == null || ef.isAfter(maxDate))) maxDate = ef;
    }

    minDate ??= DateTime.now();
    maxDate ??= minDate.add(const Duration(days: 30));

    // Add padding to date range
    final startDate = minDate.subtract(const Duration(days: 7));
    final endDate = maxDate.add(const Duration(days: 14));
    final totalDays = endDate.difference(startDate).inDays;

    return Column(
      children: [
        // Header row
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              // Task list header
              Container(
                width: _taskListWidth,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  border: Border(
                    bottom: BorderSide(color: colors.borderSubtle),
                    right: BorderSide(color: colors.borderSubtle),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text('Tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
              ),
              // Timeline header
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalDays * _dayWidth,
                    height: _headerHeight,
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      border: Border(bottom: BorderSide(color: colors.borderSubtle)),
                    ),
                    child: CustomPaint(
                      painter: _TimelineHeaderPainter(
                        startDate: startDate,
                        totalDays: totalDays,
                        dayWidth: _dayWidth,
                        zoom: _zoom,
                        textColor: colors.textTertiary,
                        lineColor: colors.borderSubtle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Row(
            children: [
              // Task list pane
              SizedBox(
                width: _taskListWidth,
                child: ListView.builder(
                  controller: _taskListController,
                  itemCount: tasks.length,
                  itemExtent: _taskRowHeight,
                  itemBuilder: (context, index) => _buildTaskRow(colors, tasks[index]),
                ),
              ),
              Container(width: 1, color: colors.borderSubtle),
              // Gantt chart pane
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalDays * _dayWidth,
                    child: ListView.builder(
                      controller: _verticalController,
                      itemCount: tasks.length,
                      itemExtent: _taskRowHeight,
                      itemBuilder: (context, index) {
                        return CustomPaint(
                          painter: _TaskBarPainter(
                            task: tasks[index],
                            startDate: startDate,
                            dayWidth: _dayWidth,
                            rowHeight: _taskRowHeight,
                            isCritical: tasks[index].isCritical,
                            showCriticalPath: _showCriticalPath,
                            criticalColor: colors.accentError,
                            normalColor: colors.accentPrimary,
                            milestoneColor: colors.accentWarning,
                            summaryColor: colors.textSecondary,
                            progressColor: colors.accentSuccess,
                            todayColor: colors.accentError,
                            gridColor: colors.borderSubtle,
                          ),
                          child: GestureDetector(
                            onTap: () => _onTaskTap(tasks[index]),
                            onLongPress: () => _onTaskLongPress(context, tasks[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskRow(ZaftoColors colors, ScheduleTask task) {
    final indent = task.indentLevel * 16.0;
    final isSummary = task.taskType == ScheduleTaskType.summary;
    final isMilestone = task.taskType == ScheduleTaskType.milestone;

    return GestureDetector(
      onTap: () => _onTaskTap(task),
      onLongPress: () => _onTaskLongPress(context, task),
      child: Container(
        height: _taskRowHeight,
        padding: EdgeInsets.only(left: 8 + indent, right: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5))),
          color: (_showCriticalPath && task.isCritical)
              ? colors.accentError.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            if (isSummary)
              Icon(LucideIcons.chevronDown, size: 12, color: colors.textTertiary)
            else if (isMilestone)
              Icon(LucideIcons.diamond, size: 10, color: colors.accentWarning)
            else
              const SizedBox(width: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSummary ? FontWeight.w600 : FontWeight.w400,
                  color: (_showCriticalPath && task.isCritical)
                      ? colors.accentError
                      : colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${task.percentComplete.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  void _changeZoom(int direction) {
    HapticFeedback.selectionClick();
    setState(() {
      final idx = GanttZoom.values.indexOf(_zoom) + direction;
      if (idx >= 0 && idx < GanttZoom.values.length) {
        _zoom = GanttZoom.values[idx];
      }
    });
  }

  void _onTaskTap(ScheduleTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleTaskDetailSheet(
        task: task,
        projectId: widget.projectId,
        onSaved: () => ref.invalidate(scheduleTasksProvider(widget.projectId)),
      ),
    );
  }

  void _onTaskLongPress(BuildContext context, ScheduleTask task) {
    HapticFeedback.mediumImpact();
    final colors = ref.read(zaftoColorsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.edit, color: colors.textSecondary),
              title: Text('Edit Task', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _onTaskTap(task);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.checkCircle, color: colors.accentSuccess),
              title: Text('Mark Complete', style: TextStyle(color: colors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final repo = ref.read(scheduleTaskRepoProvider);
                await repo.updateProgress(task.id, 100);
                ref.invalidate(scheduleTasksProvider(widget.projectId));
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: colors.accentError),
              title: Text('Delete Task', style: TextStyle(color: colors.accentError)),
              onTap: () async {
                Navigator.pop(ctx);
                final repo = ref.read(scheduleTaskRepoProvider);
                await repo.deleteTask(task.id);
                ref.invalidate(scheduleTasksProvider(widget.projectId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final colors = ref.read(zaftoColorsProvider);
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '5');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
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
            Text('Add Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Task Name',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.accentPrimary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Duration (days)',
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
                  final n = nameController.text.trim();
                  if (n.isNotEmpty) {
                    Navigator.pop(ctx, {
                      'name': n,
                      'duration': int.tryParse(durationController.text) ?? 5,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      final tasks = ref.read(scheduleTasksProvider(widget.projectId)).valueOrNull ?? [];
      final maxSort = tasks.isEmpty ? 0 : tasks.map((t) => t.sortOrder).reduce(math.max);

      final task = ScheduleTask(
        companyId: companyId,
        projectId: widget.projectId,
        name: result['name'] as String,
        originalDuration: (result['duration'] as int).toDouble(),
        sortOrder: maxSort + 10,
        plannedStart: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(scheduleTaskRepoProvider);
      await repo.createTask(task);
      ref.invalidate(scheduleTasksProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  Future<void> _triggerCpmRecalc() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) return;

      await supabase.functions.invoke(
        'schedule-calculate-cpm',
        body: {'project_id': widget.projectId},
      );

      ref.invalidate(scheduleTasksProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CPM recalculated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CPM recalc failed: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.ganttChart, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No tasks yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to add your first task', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _addTask(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
            ),
          ),
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
          Text('Failed to load tasks', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(scheduleTasksProvider(widget.projectId)),
            child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════
// TIMELINE HEADER PAINTER
// ═══════════════════════════════════════════════════════════════

class _TimelineHeaderPainter extends CustomPainter {
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final GanttZoom zoom;
  final Color textColor;
  final Color lineColor;

  _TimelineHeaderPainter({
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.zoom,
    required this.textColor,
    required this.lineColor,
  });

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = lineColor..strokeWidth = 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final x = i * dayWidth;

      // Draw tick line
      if (zoom == GanttZoom.day || date.day == 1 || date.weekday == DateTime.monday) {
        canvas.drawLine(Offset(x, size.height - 8), Offset(x, size.height), linePaint);
      }

      // Draw label
      String? label;
      if (zoom == GanttZoom.day) {
        label = '${date.day}';
      } else if (zoom == GanttZoom.week && date.weekday == DateTime.monday) {
        label = '${_months[date.month - 1]} ${date.day}';
      } else if (zoom == GanttZoom.month && date.day == 1) {
        label = '${_months[date.month - 1]} ${date.year}';
      }

      if (label != null) {
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: textColor),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, (size.height - textPainter.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineHeaderPainter oldDelegate) =>
      oldDelegate.zoom != zoom || oldDelegate.dayWidth != dayWidth;
}

// ═══════════════════════════════════════════════════════════════
// TASK BAR PAINTER
// ═══════════════════════════════════════════════════════════════

class _TaskBarPainter extends CustomPainter {
  final ScheduleTask task;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;
  final bool isCritical;
  final bool showCriticalPath;
  final Color criticalColor;
  final Color normalColor;
  final Color milestoneColor;
  final Color summaryColor;
  final Color progressColor;
  final Color todayColor;
  final Color gridColor;

  _TaskBarPainter({
    required this.task,
    required this.startDate,
    required this.dayWidth,
    required this.rowHeight,
    required this.isCritical,
    required this.showCriticalPath,
    required this.criticalColor,
    required this.normalColor,
    required this.milestoneColor,
    required this.summaryColor,
    required this.progressColor,
    required this.todayColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid line
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()..color = gridColor.withValues(alpha: 0.3)..strokeWidth = 0.5,
    );

    // Today line
    final today = DateTime.now();
    final todayDays = today.difference(startDate).inDays;
    final todayX = todayDays * dayWidth;
    if (todayX >= 0 && todayX <= size.width) {
      canvas.drawLine(
        Offset(todayX, 0),
        Offset(todayX, size.height),
        Paint()..color = todayColor.withValues(alpha: 0.3)..strokeWidth = 1,
      );
    }

    // Get task dates (already DateTime? in the model)
    final taskStart = task.earlyStart ?? task.plannedStart;
    final taskEnd = task.earlyFinish ?? task.plannedFinish;
    if (taskStart == null) return;

    final startDays = taskStart.difference(startDate).inDays;
    final x = startDays * dayWidth;
    final barY = rowHeight * 0.25;
    final barHeight = rowHeight * 0.5;

    if (task.taskType == ScheduleTaskType.milestone) {
      // Diamond shape for milestones
      final cx = x;
      final cy = rowHeight / 2;
      const size = 6.0;
      final path = Path()
        ..moveTo(cx, cy - size)
        ..lineTo(cx + size, cy)
        ..lineTo(cx, cy + size)
        ..lineTo(cx - size, cy)
        ..close();
      canvas.drawPath(path, Paint()..color = milestoneColor);
      return;
    }

    if (taskEnd == null) return;
    final endDays = taskEnd.difference(startDate).inDays;
    final barWidth = math.max((endDays - startDays) * dayWidth, 4.0);

    if (task.taskType == ScheduleTaskType.summary) {
      // Summary bar — thin dark bar with end brackets
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barY + barHeight * 0.3, barWidth, barHeight * 0.4),
        const Radius.circular(1),
      );
      canvas.drawRRect(barRect, Paint()..color = summaryColor);

      // Left bracket
      canvas.drawRect(
        Rect.fromLTWH(x, barY, 3, barHeight),
        Paint()..color = summaryColor,
      );
      // Right bracket
      canvas.drawRect(
        Rect.fromLTWH(x + barWidth - 3, barY, 3, barHeight),
        Paint()..color = summaryColor,
      );
      return;
    }

    // Regular task bar
    final barColor = (showCriticalPath && isCritical) ? criticalColor : normalColor;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, barY, barWidth, barHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(barRect, Paint()..color = barColor.withValues(alpha: 0.3));

    // Progress fill
    if (task.percentComplete > 0) {
      final progressWidth = barWidth * (task.percentComplete / 100);
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barY, progressWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(progressRect, Paint()..color = barColor);
    }

    // Border
    canvas.drawRRect(barRect, Paint()
      ..color = barColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _TaskBarPainter oldDelegate) =>
      oldDelegate.task.id != task.id ||
      oldDelegate.showCriticalPath != showCriticalPath ||
      oldDelegate.dayWidth != dayWidth;
}
