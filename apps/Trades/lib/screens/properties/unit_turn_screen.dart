import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/unit_turn.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// No unit turns provider exists — load data manually via Supabase query.
import 'package:supabase_flutter/supabase_flutter.dart';

final _unitTurnsProvider =
    FutureProvider.autoDispose<List<UnitTurn>>((ref) async {
  final response = await Supabase.instance.client
      .from('unit_turns')
      .select('*, unit_turn_tasks(*)')
      .order('created_at', ascending: false);
  return (response as List).map((row) {
    final map = row as Map<String, dynamic>;
    // Nested tasks come back as 'unit_turn_tasks', remap to 'tasks' for model
    if (map.containsKey('unit_turn_tasks')) {
      map['tasks'] = map.remove('unit_turn_tasks');
    }
    return UnitTurn.fromJson(map);
  }).toList();
});

class UnitTurnScreen extends ConsumerStatefulWidget {
  const UnitTurnScreen({super.key});

  @override
  ConsumerState<UnitTurnScreen> createState() => _UnitTurnScreenState();
}

class _UnitTurnScreenState extends ConsumerState<UnitTurnScreen> {
  final Set<String> _expandedIds = {};

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final turnsAsync = ref.watch(_unitTurnsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Unit Turns',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.invalidate(_unitTurnsProvider);
            },
            icon: Icon(LucideIcons.refreshCw, size: 20, color: colors.textSecondary),
          ),
        ],
      ),
      body: turnsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
              const SizedBox(height: 12),
              Text(
                'Failed to load unit turns',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_unitTurnsProvider),
                child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
        data: (turns) => _buildContent(colors, turns),
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<UnitTurn> turns) {
    if (turns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.refreshCw, size: 48, color: colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No active unit turns',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Unit turns appear when tenants move out',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: turns.length,
      itemBuilder: (context, index) {
        final turn = turns[index];
        final isExpanded = _expandedIds.contains(turn.id);
        final completedCount = turn.tasks.where((t) =>
            t.status == TurnTaskStatus.completed ||
            t.status == TurnTaskStatus.skipped).length;
        final totalTasks = turn.tasks.length;
        final progress = totalTasks > 0 ? completedCount / totalTasks : 0.0;

        final sColor = _turnStatusColor(colors, turn.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              // Card header
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(turn.id);
                    } else {
                      _expandedIds.add(turn.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.refreshCw, size: 18, color: colors.accentPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit ${turn.unitId}',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (turn.moveOutDate != null)
                                  Text(
                                    'Move-out: ${_formatDate(turn.moveOutDate)}',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _turnStatusLabel(turn.status),
                              style: TextStyle(
                                color: sColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 16,
                            color: colors.textTertiary,
                          ),
                        ],
                      ),
                      if (totalTasks > 0) ...[
                        const SizedBox(height: 10),
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: colors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$completedCount / $totalTasks',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Target / cost info
                      if (turn.targetReadyDate != null || turn.totalCost != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (turn.targetReadyDate != null) ...[
                              Icon(LucideIcons.target, size: 13, color: colors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                'Target: ${_formatDate(turn.targetReadyDate)}',
                                style: TextStyle(color: colors.textTertiary, fontSize: 12),
                              ),
                            ],
                            if (turn.targetReadyDate != null && turn.totalCost != null)
                              const SizedBox(width: 16),
                            if (turn.totalCost != null) ...[
                              Icon(LucideIcons.dollarSign, size: 13, color: colors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                '\$${turn.totalCost!.toStringAsFixed(2)}',
                                style: TextStyle(color: colors.textTertiary, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Expanded task list
              if (isExpanded && turn.tasks.isNotEmpty) ...[
                Divider(height: 1, color: colors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: turn.tasks.map((task) {
                      final isComplete = task.status == TurnTaskStatus.completed;
                      final isSkipped = task.status == TurnTaskStatus.skipped;
                      final isInProgress = task.status == TurnTaskStatus.inProgress;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            // Checkbox
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _toggleTask(turn.id, task.id, task.status);
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isComplete
                                      ? colors.success
                                      : isSkipped
                                          ? colors.textTertiary
                                          : isInProgress
                                              ? colors.accentPrimary.withValues(alpha: 0.2)
                                              : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isComplete
                                        ? colors.success
                                        : isSkipped
                                            ? colors.textTertiary
                                            : isInProgress
                                                ? colors.accentPrimary
                                                : colors.border,
                                    width: 2,
                                  ),
                                ),
                                child: isComplete
                                    ? Icon(LucideIcons.check, size: 14, color: colors.textOnAccent)
                                    : isSkipped
                                        ? Icon(LucideIcons.minus, size: 14, color: colors.textOnAccent)
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Task info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _turnTaskTypeLabel(task.taskType),
                                    style: TextStyle(
                                      color: isComplete || isSkipped
                                          ? colors.textTertiary
                                          : colors.textPrimary,
                                      fontSize: 14,
                                      decoration: isComplete || isSkipped
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (task.description != null && task.description!.isNotEmpty)
                                    Text(
                                      task.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Cost
                            if (task.estimatedCost != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '\$${task.estimatedCost!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: colors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // Skip button
                            if (!isComplete && !isSkipped)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _skipTask(turn.id, task.id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: colors.textTertiary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            // Create Job button
                            if (!isComplete && !isSkipped)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _createJobFromTask(turn, task);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.accentPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.wrench, size: 12, color: colors.accentPrimary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Job',
                                        style: TextStyle(
                                          color: colors.accentPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              // Expanded but no tasks
              if (isExpanded && turn.tasks.isEmpty) ...[
                Divider(height: 1, color: colors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No tasks added yet',
                    style: TextStyle(color: colors.textTertiary, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _toggleTask(String turnId, String taskId, TurnTaskStatus currentStatus) {
    if (currentStatus == TurnTaskStatus.completed) {
      // TODO: Mark as pending via Supabase update
    } else {
      // TODO: Mark as completed via Supabase update
    }
  }

  void _skipTask(String turnId, String taskId) {
    // TODO: Mark task as skipped via Supabase update
  }

  void _createJobFromTask(UnitTurn turn, UnitTurnTask task) {
    // TODO: Create maintenance job from this turn task
    // Pre-fill: property, unit, task description
  }
}

Color _turnStatusColor(ZaftoColors colors, TurnStatus status) {
  return switch (status) {
    TurnStatus.pending => colors.warning,
    TurnStatus.inProgress => colors.accentPrimary,
    TurnStatus.ready => colors.success,
    TurnStatus.listed => colors.accentInfo,
    TurnStatus.leased => colors.success,
  };
}

String _turnStatusLabel(TurnStatus status) {
  return switch (status) {
    TurnStatus.pending => 'PENDING',
    TurnStatus.inProgress => 'IN PROGRESS',
    TurnStatus.ready => 'READY',
    TurnStatus.listed => 'LISTED',
    TurnStatus.leased => 'LEASED',
  };
}

String _turnTaskTypeLabel(TurnTaskType type) {
  return switch (type) {
    TurnTaskType.cleaning => 'Cleaning',
    TurnTaskType.painting => 'Painting',
    TurnTaskType.flooring => 'Flooring',
    TurnTaskType.appliance => 'Appliance',
    TurnTaskType.plumbing => 'Plumbing',
    TurnTaskType.electrical => 'Electrical',
    TurnTaskType.hvac => 'HVAC',
    TurnTaskType.general => 'General',
    TurnTaskType.inspection => 'Inspection',
    TurnTaskType.keys => 'Keys',
  };
}
