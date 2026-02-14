// ZAFTO Schedule Task Detail Sheet
// GC4: Bottom sheet for task editing — name, duration, dates, constraints,
// progress slider, predecessors, resource assignments, notes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/schedule_task.dart';
import '../../providers/schedule_tasks_provider.dart';

class ScheduleTaskDetailSheet extends ConsumerStatefulWidget {
  final ScheduleTask task;
  final String projectId;
  final VoidCallback onSaved;

  const ScheduleTaskDetailSheet({
    super.key,
    required this.task,
    required this.projectId,
    required this.onSaved,
  });

  @override
  ConsumerState<ScheduleTaskDetailSheet> createState() => _ScheduleTaskDetailSheetState();
}

class _ScheduleTaskDetailSheetState extends ConsumerState<ScheduleTaskDetailSheet> {
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  late double _percentComplete;
  late ConstraintType _constraintType;
  String? _constraintDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _durationController = TextEditingController(text: '${widget.task.originalDuration ?? 0}');
    _notesController = TextEditingController(text: widget.task.notes ?? '');
    _percentComplete = widget.task.percentComplete;
    _constraintType = widget.task.constraintType;
    _constraintDate = widget.task.constraintDate?.toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textQuaternary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Task Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                ),
                if (_saving)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary))
                else
                  TextButton(
                    onPressed: _save,
                    child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: colors.accentPrimary)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(colors, 'Task Name', _nameController),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(colors, 'Duration (days)', _durationController, isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateField(colors, 'Planned Start', widget.task.plannedStart?.toIso8601String().substring(0, 10))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Type badge
                  if (widget.task.taskType != ScheduleTaskType.task)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildInfoChip(colors, widget.task.taskType.name.toUpperCase(),
                        widget.task.taskType == ScheduleTaskType.milestone ? colors.accentWarning : colors.textSecondary),
                    ),
                  // Progress slider
                  _buildSectionHeader(colors, 'Progress'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _percentComplete,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: _percentComplete >= 100 ? colors.accentSuccess : colors.accentPrimary,
                          inactiveColor: colors.fillDefault,
                          onChanged: (v) => setState(() => _percentComplete = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${_percentComplete.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Constraint
                  _buildSectionHeader(colors, 'Constraint'),
                  _buildConstraintPicker(colors),
                  const SizedBox(height: 16),
                  // CPM Info (read-only)
                  if (widget.task.earlyStart != null || widget.task.lateStart != null) ...[
                    _buildSectionHeader(colors, 'CPM Dates (calculated)'),
                    _buildCpmInfo(colors),
                    const SizedBox(height: 16),
                  ],
                  // Notes
                  _buildSectionHeader(colors, 'Notes'),
                  _buildTextField(colors, 'Notes', _notesController, maxLines: 3),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
    );
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
        filled: true,
        fillColor: colors.bgBase,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.accentPrimary)),
      ),
    );
  }

  Widget _buildDateField(ZaftoColors colors, String label, String? value) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value != null ? (DateTime.tryParse(value) ?? DateTime.now()) : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (date != null) {
          // Date is read-only display for now; planned_start updated via save
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value?.substring(0, 10) ?? 'Not set',
                style: TextStyle(fontSize: 14, color: value != null ? colors.textPrimary : colors.textQuaternary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstraintPicker(ZaftoColors colors) {
    return DropdownButtonFormField<ConstraintType>(
      value: _constraintType,
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.bgBase,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
      ),
      dropdownColor: colors.bgElevated,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      items: ConstraintType.values.map((ct) => DropdownMenuItem(
        value: ct,
        child: Text(_constraintLabel(ct)),
      )).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _constraintType = v);
      },
    );
  }

  Widget _buildCpmInfo(ZaftoColors colors) {
    final t = widget.task;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildCpmRow(colors, 'Early Start', t.earlyStart?.toIso8601String().substring(0, 10)),
          _buildCpmRow(colors, 'Early Finish', t.earlyFinish?.toIso8601String().substring(0, 10)),
          _buildCpmRow(colors, 'Late Start', t.lateStart?.toIso8601String().substring(0, 10)),
          _buildCpmRow(colors, 'Late Finish', t.lateFinish?.toIso8601String().substring(0, 10)),
          _buildCpmRow(colors, 'Total Float', '${t.totalFloat?.toStringAsFixed(0) ?? '-'} days'),
          _buildCpmRow(colors, 'Free Float', '${t.freeFloat?.toStringAsFixed(0) ?? '-'} days'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Critical', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              _buildInfoChip(colors, t.isCritical ? 'YES' : 'NO',
                t.isCritical ? colors.accentError : colors.accentSuccess),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCpmRow(ZaftoColors colors, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          Text(value?.substring(0, value.length >= 10 ? 10 : value.length) ?? '-',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ZaftoColors colors, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _constraintLabel(ConstraintType ct) => switch (ct) {
    ConstraintType.asap => 'As Soon As Possible',
    ConstraintType.alap => 'As Late As Possible',
    ConstraintType.snet => 'Start No Earlier Than',
    ConstraintType.snlt => 'Start No Later Than',
    ConstraintType.fnet => 'Finish No Earlier Than',
    ConstraintType.fnlt => 'Finish No Later Than',
    ConstraintType.mso => 'Must Start On',
    ConstraintType.mfo => 'Must Finish On',
  };

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(scheduleTaskRepoProvider);
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'original_duration': int.tryParse(_durationController.text) ?? widget.task.originalDuration,
        'percent_complete': _percentComplete,
        'constraint_type': _constraintType.name,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      if (_constraintDate != null) {
        updates['constraint_date'] = _constraintDate;
      }

      await repo.updateTask(widget.task.id, updates);

      // Trigger CPM recalc if duration or constraint changed
      if ((_durationController.text != '${widget.task.originalDuration}') ||
          _constraintType != widget.task.constraintType ||
          _percentComplete != widget.task.percentComplete) {
        try {
          final supabase = Supabase.instance.client;
          await supabase.functions.invoke(
            'schedule-calculate-cpm',
            body: {'project_id': widget.projectId},
          );
        } catch (_) {
          // CPM recalc failure is non-blocking
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
