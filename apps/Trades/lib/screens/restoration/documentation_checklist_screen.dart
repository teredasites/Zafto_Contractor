// ZAFTO Documentation Checklist Screen
// TPA-compliant documentation overlay: required items by phase, completion tracking,
// photo phase tagging (before/during/after/equipment/moisture/source/exterior/contents/pre_existing)
// Phase T5d — Sprint T5: Documentation Validation

import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Phase display config
const _phaseConfig = <String, ({String label, IconData icon})>{
  'initial_inspection': (label: 'Initial Inspection', icon: LucideIcons.camera),
  'during_work': (label: 'During Work', icon: LucideIcons.clipboardList),
  'daily_monitoring': (label: 'Daily Monitoring', icon: LucideIcons.activity),
  'completion': (label: 'Completion', icon: LucideIcons.fileCheck),
  'closeout': (label: 'Closeout', icon: LucideIcons.penTool),
};

class _ChecklistItem {
  final String id;
  final String phase;
  final String itemName;
  final String? description;
  final bool isRequired;
  final String evidenceType;
  final int minCount;

  const _ChecklistItem({
    required this.id,
    required this.phase,
    required this.itemName,
    this.description,
    this.isRequired = true,
    this.evidenceType = 'photo',
    this.minCount = 1,
  });

  factory _ChecklistItem.fromJson(Map<String, dynamic> json) => _ChecklistItem(
        id: json['id'] as String,
        phase: json['phase'] as String,
        itemName: json['item_name'] as String,
        description: json['description'] as String?,
        isRequired: json['is_required'] as bool? ?? true,
        evidenceType: json['evidence_type'] as String? ?? 'photo',
        minCount: json['min_count'] as int? ?? 1,
      );
}

class _ProgressItem {
  final String id;
  final String checklistItemId;
  final bool isComplete;
  final int evidenceCount;

  const _ProgressItem({
    required this.id,
    required this.checklistItemId,
    this.isComplete = false,
    this.evidenceCount = 0,
  });

  factory _ProgressItem.fromJson(Map<String, dynamic> json) => _ProgressItem(
        id: json['id'] as String,
        checklistItemId: json['checklist_item_id'] as String,
        isComplete: json['is_complete'] as bool? ?? false,
        evidenceCount: json['evidence_count'] as int? ?? 0,
      );
}

class DocumentationChecklistScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;
  final String jobType;

  const DocumentationChecklistScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
    this.jobType = 'water_mitigation',
  });

  @override
  ConsumerState<DocumentationChecklistScreen> createState() =>
      _DocumentationChecklistScreenState();
}

class _DocumentationChecklistScreenState
    extends ConsumerState<DocumentationChecklistScreen> {
  List<_ChecklistItem> _items = [];
  List<_ProgressItem> _progress = [];
  bool _loading = true;
  String? _error;
  final Set<String> _expandedPhases = {'initial_inspection'};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final supabase = Supabase.instance.client;

      // Get template
      final templates = await supabase
          .from('doc_checklist_templates')
          .select('id')
          .eq('job_type', widget.jobType)
          .eq('is_active', true)
          .order('is_system_default', ascending: true)
          .limit(1);

      if ((templates as List).isEmpty) {
        setState(() {
          _items = [];
          _progress = [];
          _loading = false;
        });
        return;
      }

      final templateId = templates[0]['id'] as String;

      final results = await Future.wait([
        supabase
            .from('doc_checklist_items')
            .select()
            .eq('template_id', templateId)
            .order('sort_order'),
        supabase
            .from('job_doc_progress')
            .select()
            .eq('job_id', widget.jobId),
      ]);

      setState(() {
        _items = (results[0] as List)
            .map((r) => _ChecklistItem.fromJson(r as Map<String, dynamic>))
            .toList();
        _progress = (results[1] as List)
            .map((r) => _ProgressItem.fromJson(r as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleItem(String itemId) async {
    final existing = _progress.where((p) => p.checklistItemId == itemId).firstOrNull;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      if (existing != null && existing.isComplete) {
        await supabase.from('job_doc_progress').update({
          'is_complete': false,
          'completed_at': null,
        }).eq('id', existing.id);
      } else if (existing != null) {
        await supabase.from('job_doc_progress').update({
          'is_complete': true,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'completed_by_user_id': user.id,
        }).eq('id', existing.id);
      } else {
        await supabase.from('job_doc_progress').insert({
          'company_id': companyId,
          'job_id': widget.jobId,
          'tpa_assignment_id': widget.tpaAssignmentId,
          'checklist_item_id': itemId,
          'is_complete': true,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'completed_by_user_id': user.id,
          'evidence_count': 0,
        });
      }
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  int get _totalRequired => _items.where((i) => i.isRequired).length;
  int get _completedRequired {
    final progressMap = {for (final p in _progress) p.checklistItemId: p};
    return _items.where((i) {
      if (!i.isRequired) return false;
      final p = progressMap[i.id];
      return p != null && p.isComplete && p.evidenceCount >= i.minCount;
    }).length;
  }

  int get _compliancePercent =>
      _totalRequired > 0 ? ((_completedRequired / _totalRequired) * 100).round() : 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation Checklist'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load checklist', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shield, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No checklist template', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('No documentation checklist is configured for this job type.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final progressMap = {for (final p in _progress) p.checklistItemId: p};
    final percent = _compliancePercent;
    final barColor = percent >= 100 ? Colors.green : percent >= 70 ? Colors.amber : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compliance header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compliance', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '$percent%',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: barColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_completedRequired of $_totalRequired required items complete',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Phase sections
        for (final phase in _phaseConfig.keys) ...[
          _buildPhaseSection(phase, progressMap),
        ],
      ],
    );
  }

  Widget _buildPhaseSection(String phase, Map<String, _ProgressItem> progressMap) {
    final phaseItems = _items.where((i) => i.phase == phase).toList();
    if (phaseItems.isEmpty) return const SizedBox.shrink();

    final config = _phaseConfig[phase]!;
    final isExpanded = _expandedPhases.contains(phase);
    final required = phaseItems.where((i) => i.isRequired).length;
    final reqComplete = phaseItems.where((i) {
      if (!i.isRequired) return false;
      final p = progressMap[i.id];
      return p != null && p.isComplete;
    }).length;
    final allDone = reqComplete == required;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPhases.remove(phase);
                } else {
                  _expandedPhases.add(phase);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    config.icon,
                    size: 18,
                    color: allDone ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('$reqComplete/$required required', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (allDone) Icon(LucideIcons.checkCircle2, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...phaseItems.map((item) {
              final prog = progressMap[item.id];
              final isComplete = prog?.isComplete == true;
              return ListTile(
                dense: true,
                leading: GestureDetector(
                  onTap: () => _toggleItem(item.id),
                  child: Icon(
                    isComplete ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 20,
                    color: isComplete ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                    color: isComplete ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description != null)
                      Text(item.description!, style: const TextStyle(fontSize: 11)),
                    Row(
                      children: [
                        if (item.isRequired)
                          Container(
                            margin: const EdgeInsets.only(right: 4, top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Required', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.evidenceType} x${item.minCount}',
                            style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: item.description != null,
              );
            }),
          ],
        ],
      ),
    );
  }
}
