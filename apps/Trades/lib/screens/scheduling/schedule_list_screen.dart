// ZAFTO Schedule List Screen
// GC4: Lists all schedule projects with status cards, search, FAB to create.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/schedule_project.dart';
import '../../providers/schedule_project_provider.dart';
import 'schedule_gantt_screen.dart';

class ScheduleListScreen extends ConsumerStatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  ConsumerState<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends ConsumerState<ScheduleListScreen> {
  ScheduleProjectStatus? _filterStatus;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final projectsAsync = ref.watch(scheduleProjectsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? _buildSearchField(colors)
            : Text('Schedules', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search, color: colors.textSecondary),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Portfolio summary card (only shows when projects exist)
          projectsAsync.whenOrNull(
            data: (projects) => projects.length >= 2 ? _buildPortfolioSummary(colors, projects) : null,
          ) ?? const SizedBox.shrink(),
          _buildFilterChips(colors),
          const SizedBox(height: 8),
          Expanded(
            child: projectsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => _buildErrorState(colors, e),
              data: (projects) {
                final filtered = _applyFilters(projects);
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildProjectsList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createProject(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildSearchField(ZaftoColors colors) {
    return TextField(
      autofocus: true,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search schedules...',
        hintStyle: TextStyle(color: colors.textQuaternary),
        border: InputBorder.none,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(colors, 'All', null),
          _buildChip(colors, 'Active', ScheduleProjectStatus.active),
          _buildChip(colors, 'Draft', ScheduleProjectStatus.draft),
          _buildChip(colors, 'On Hold', ScheduleProjectStatus.onHold),
          _buildChip(colors, 'Complete', ScheduleProjectStatus.complete),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, ScheduleProjectStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterStatus = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<ScheduleProject> _applyFilters(List<ScheduleProject> projects) {
    var result = projects;
    if (_filterStatus != null) {
      result = result.where((p) => p.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  Widget _buildPortfolioSummary(ZaftoColors colors, List<ScheduleProject> projects) {
    // Compute health from project status + percent completion
    final activeProjects = projects.where((p) => p.status == ScheduleProjectStatus.active).toList();
    if (activeProjects.isEmpty) return const SizedBox.shrink();

    final complete = activeProjects.where((p) => p.overallPercentComplete >= 100).length;
    final behindCount = activeProjects.where((p) =>
        p.plannedFinish != null && p.plannedFinish!.isBefore(DateTime.now()) && p.overallPercentComplete < 100
    ).length;
    final onTrack = activeProjects.length - behindCount - complete;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.layoutDashboard, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Overview',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${activeProjects.length} active',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatPill(colors, '$onTrack', 'On Track', colors.accentSuccess),
                const SizedBox(width: 8),
                _buildStatPill(colors, '$behindCount', 'Behind', colors.accentError),
                const SizedBox(width: 8),
                _buildStatPill(colors, '$complete', 'Done', colors.accentInfo),
              ],
            ),
            // Aggregate progress bar
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: activeProjects.isEmpty
                    ? 0
                    : activeProjects.fold<double>(0, (s, p) => s + p.overallPercentComplete) / (activeProjects.length * 100),
                backgroundColor: colors.fillDefault,
                valueColor: AlwaysStoppedAnimation(colors.accentPrimary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Avg. progress: ${activeProjects.isEmpty ? 0 : (activeProjects.fold<double>(0, (s, p) => s + p.overallPercentComplete) / activeProjects.length).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, color: colors.textQuaternary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(ZaftoColors colors, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList(ZaftoColors colors, List<ScheduleProject> projects) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleProjectsProvider),
      color: colors.accentPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) => _buildProjectCard(colors, projects[index]),
      ),
    );
  }

  Widget _buildProjectCard(ZaftoColors colors, ScheduleProject project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ScheduleGanttScreen(projectId: project.id, projectName: project.name),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(colors, project.status),
                const Spacer(),
                if (project.overallPercentComplete > 0)
                  Text(
                    '${project.overallPercentComplete.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accentPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(project.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            if (project.description != null && project.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                project.description!,
                style: TextStyle(fontSize: 13, color: colors.textTertiary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (project.plannedStart != null) ...[
                  Icon(LucideIcons.calendarRange, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(project.plannedStart!, project.plannedFinish),
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
            if (project.overallPercentComplete > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.overallPercentComplete / 100,
                  backgroundColor: colors.fillDefault,
                  valueColor: AlwaysStoppedAnimation(
                    project.isComplete ? colors.accentSuccess : colors.accentPrimary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, ScheduleProjectStatus status) {
    final (color, bgColor, label) = switch (status) {
      ScheduleProjectStatus.draft => (colors.textTertiary, colors.fillDefault, 'Draft'),
      ScheduleProjectStatus.active => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), 'Active'),
      ScheduleProjectStatus.onHold => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15), 'On Hold'),
      ScheduleProjectStatus.complete => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), 'Complete'),
      ScheduleProjectStatus.archived => (colors.textTertiary, colors.fillDefault, 'Archived'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
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
            child: Icon(LucideIcons.ganttChart, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No schedules yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to create your first schedule', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
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
          Text('Failed to load schedules', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(scheduleProjectsProvider),
            child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final s = '${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}';
    if (end == null) return s;
    final e = '${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}';
    return '$s → $e';
  }

  Future<void> _createProject(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final colors = ref.read(zaftoColorsProvider);
    final nameController = TextEditingController();

    final name = await showModalBottomSheet<String>(
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
            Text('New Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Create a project schedule', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Schedule name',
                hintStyle: TextStyle(color: colors.textQuaternary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.accentPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final n = nameController.text.trim();
                  if (n.isNotEmpty) Navigator.pop(ctx, n);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      final repo = ref.read(scheduleProjectRepoProvider);
      final project = await repo.createProject(
        companyId: companyId,
        name: name,
        plannedStart: DateTime.now(),
      );

      ref.invalidate(scheduleProjectsProvider);

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ScheduleGanttScreen(projectId: project.id, projectName: project.name),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create schedule: $e')),
        );
      }
    }
  }
}
