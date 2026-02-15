import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';

// ============================================================
// Inspector History Screen — Completed Inspections
//
// Shows all completed inspections with filtering by result
// (pass/fail/conditional). Search, real data from provider.
// ============================================================

class InspectorHistoryScreen extends ConsumerStatefulWidget {
  const InspectorHistoryScreen({super.key});

  @override
  ConsumerState<InspectorHistoryScreen> createState() => _InspectorHistoryScreenState();
}

class _InspectorHistoryScreenState extends ConsumerState<InspectorHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 12),
            _buildSearchBar(colors),
            const SizedBox(height: 12),
            _buildFilterChips(colors),
            const SizedBox(height: 12),
            Expanded(
              child: inspectionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
                error: (e, _) => _buildErrorState(colors),
                data: (inspections) {
                  final completed = inspections
                      .where((i) => i.status == InspectionStatus.completed)
                      .toList();
                  final filtered = _applyFilters(completed);
                  if (filtered.isEmpty) return _buildEmptyState(colors);
                  return RefreshIndicator(
                    onRefresh: () => ref.read(inspectionsProvider.notifier).refresh(),
                    color: colors.accentPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildHistoryCard(colors, filtered[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PmInspection> _applyFilters(List<PmInspection> inspections) {
    var result = inspections;

    // Filter by result
    switch (_selectedFilter) {
      case 'Pass':
        result = result.where((i) => (i.score ?? 0) >= 70).toList();
        break;
      case 'Fail':
        result = result.where((i) => (i.score ?? 0) < 70 && (i.score ?? 0) > 0).toList();
        break;
      case 'Conditional':
        result = result.where((i) =>
            i.overallCondition == ItemCondition.fair ||
            i.overallCondition == ItemCondition.poor).toList();
        break;
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((i) =>
          _typeLabel(i.inspectionType).toLowerCase().contains(query) ||
          (i.notes ?? '').toLowerCase().contains(query)).toList();
    }

    // Sort newest first
    result.sort((a, b) =>
        (b.completedDate ?? b.createdAt).compareTo(a.completedDate ?? a.createdAt));
    return result;
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'History',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search inspections...',
            hintStyle: TextStyle(fontSize: 14, color: colors.textQuaternary),
            prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textQuaternary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    final filters = [
      ('All', null as Color?),
      ('Pass', colors.accentSuccess),
      ('Fail', colors.accentError),
      ('Conditional', colors.accentWarning),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, color) = filters[index];
          final isSelected = _selectedFilter == label;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedFilter = label);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (color ?? colors.accentPrimary)
                    : colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(ZaftoColors colors, PmInspection inspection) {
    final passed = (inspection.score ?? 0) >= 70;
    final resultColor = passed ? colors.accentSuccess : colors.accentError;
    final resultLabel = passed ? 'PASS' : 'FAIL';
    final date = inspection.completedDate ?? inspection.createdAt;
    final dateStr = '${date.month}/${date.day}/${date.year}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to inspection detail/report
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resultColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  '${inspection.score ?? 0}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(inspection.inspectionType),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                      if (inspection.overallCondition != null) ...[
                        Text(' · ', style: TextStyle(fontSize: 12, color: colors.textQuaternary)),
                        Text(
                          _conditionLabel(inspection.overallCondition!),
                          style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  if (inspection.photos.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.image, size: 12, color: colors.textQuaternary),
                        const SizedBox(width: 4),
                        Text(
                          '${inspection.photos.length} photo${inspection.photos.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Result badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                resultLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No completed inspections'
                : 'No ${_selectedFilter.toLowerCase()} inspections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed inspections will appear here',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
          const SizedBox(height: 16),
          Text(
            'Failed to load history',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ref.read(inspectionsProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(InspectionType type) {
    switch (type) {
      case InspectionType.moveIn:
        return 'Move-In';
      case InspectionType.moveOut:
        return 'Move-Out';
      case InspectionType.routine:
        return 'Routine';
      case InspectionType.annual:
        return 'Annual';
      case InspectionType.maintenance:
        return 'Maintenance';
      case InspectionType.safety:
        return 'Safety';
    }
  }

  String _conditionLabel(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
      case ItemCondition.damaged:
        return 'Damaged';
      case ItemCondition.missing:
        return 'Missing';
    }
  }
}
