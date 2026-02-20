import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/inspection.dart';
import '../../repositories/inspection_repository.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// No inspection provider exists — load data manually via Supabase query.
// Using a simple FutureProvider to fetch inspections.
import 'package:supabase_flutter/supabase_flutter.dart';

final _inspectionsProvider =
    FutureProvider.autoDispose<List<PmInspection>>((ref) async {
  final response = await Supabase.instance.client
      .from('pm_inspections')
      .select()
      .order('created_at', ascending: false);
  return (response as List)
      .map((row) => PmInspection.fromJson(row as Map<String, dynamic>))
      .toList();
});

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key});

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  InspectionStatus? _statusFilter;

  String _formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final inspectionsAsync = ref.watch(_inspectionsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Inspections',
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
              ref.invalidate(_inspectionsProvider);
            },
            icon: Icon(LucideIcons.refreshCw, size: 20, color: colors.textSecondary),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _showNewInspectionDialog(colors);
            },
            icon: Icon(LucideIcons.plus, color: colors.textPrimary),
          ),
        ],
      ),
      body: inspectionsAsync.when(
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
                'Failed to load inspections',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_inspectionsProvider),
                child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
        data: (inspections) => _buildContent(colors, inspections),
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<PmInspection> inspections) {
    final filtered = _statusFilter == null
        ? inspections
        : inspections.where((i) => i.status == _statusFilter).toList();

    return Column(
      children: [
        // Status filters
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                colors: colors,
                label: 'All',
                isSelected: _statusFilter == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = null);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Scheduled',
                isSelected: _statusFilter == InspectionStatus.scheduled,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = InspectionStatus.scheduled);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'In Progress',
                isSelected: _statusFilter == InspectionStatus.inProgress,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = InspectionStatus.inProgress);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Completed',
                isSelected: _statusFilter == InspectionStatus.completed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = InspectionStatus.completed);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clipboardCheck, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'No inspections yet',
                        style: TextStyle(color: colors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to create one',
                        style: TextStyle(color: colors.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _InspectionCard(
                    colors: colors,
                    inspection: filtered[index],
                    formatDate: _formatDate,
                  ),
                ),
        ),
      ],
    );
  }

  void _showNewInspectionDialog(ZaftoColors colors) {
    InspectionType selectedType = InspectionType.moveIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Inspection',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              // Type selector
              DropdownButtonFormField<InspectionType>(
                initialValue: selectedType,
                dropdownColor: colors.bgElevated,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Inspection Type',
                  labelStyle: TextStyle(color: colors.textTertiary),
                  filled: true,
                  fillColor: colors.bgBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                items: InspectionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_inspectionTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedType = v);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.textOnAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                    try {
                      final repo = InspectionRepository();
                      final user = Supabase.instance.client.auth.currentUser;
                      final companyId = user?.appMetadata['company_id'] as String? ?? '';
                      await repo.createInspection(PmInspection(
                        companyId: companyId,
                        propertyId: '',
                        inspectionType: selectedType,
                        scheduledDate: DateTime.now(),
                        status: InspectionStatus.scheduled,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                      ref.invalidate(_inspectionsProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inspection created')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create inspection: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Create Inspection',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _inspectionTypeLabel(InspectionType type) {
  return switch (type) {
    InspectionType.moveIn => 'Move-In',
    InspectionType.moveOut => 'Move-Out',
    InspectionType.routine => 'Routine',
    InspectionType.annual => 'Annual',
    InspectionType.maintenance => 'Maintenance',
    InspectionType.safety => 'Safety',
    InspectionType.roughIn => 'Rough-In',
    InspectionType.framing => 'Framing',
    InspectionType.foundation => 'Foundation',
    InspectionType.finalInspection => 'Final',
    InspectionType.permit => 'Permit',
    InspectionType.codeCompliance => 'Code Compliance',
    InspectionType.qcHoldPoint => 'QC Hold Point',
    InspectionType.reInspection => 'Re-Inspection',
    InspectionType.swppp => 'SWPPP',
    InspectionType.environmental => 'Environmental',
    InspectionType.ada => 'ADA',
    InspectionType.insuranceDamage => 'Insurance Damage',
    InspectionType.tpi => 'TPI',
    InspectionType.preConstruction => 'Pre-Construction',
    InspectionType.roofing => 'Roofing',
    InspectionType.fireLifeSafety => 'Fire/Life Safety',
    InspectionType.electrical => 'Electrical',
    InspectionType.plumbing => 'Plumbing',
    InspectionType.hvac => 'HVAC',
    InspectionType.quickChecklist => 'Quick Checklist',
  };
}

Color _inspectionStatusColor(ZaftoColors colors, InspectionStatus status) {
  return switch (status) {
    InspectionStatus.scheduled => colors.warning,
    InspectionStatus.inProgress => colors.accentPrimary,
    InspectionStatus.completed => colors.success,
    InspectionStatus.cancelled => colors.textTertiary,
  };
}

String _inspectionStatusLabel(InspectionStatus status) {
  return switch (status) {
    InspectionStatus.scheduled => 'SCHEDULED',
    InspectionStatus.inProgress => 'IN PROGRESS',
    InspectionStatus.completed => 'COMPLETED',
    InspectionStatus.cancelled => 'CANCELLED',
  };
}

Color _conditionColor(ZaftoColors colors, ItemCondition? condition) {
  if (condition == null) return colors.textTertiary;
  return switch (condition) {
    ItemCondition.excellent => colors.success,
    ItemCondition.good => colors.success,
    ItemCondition.fair => colors.warning,
    ItemCondition.poor => colors.error,
    ItemCondition.damaged => colors.error,
    ItemCondition.missing => colors.textTertiary,
  };
}

String _conditionLabel(ItemCondition? condition) {
  if (condition == null) return 'N/A';
  return switch (condition) {
    ItemCondition.excellent => 'EXCELLENT',
    ItemCondition.good => 'GOOD',
    ItemCondition.fair => 'FAIR',
    ItemCondition.poor => 'POOR',
    ItemCondition.damaged => 'DAMAGED',
    ItemCondition.missing => 'MISSING',
  };
}

class _FilterChip extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.colors,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: 0.12)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.accentPrimary : colors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final ZaftoColors colors;
  final PmInspection inspection;
  final String Function(DateTime) formatDate;

  const _InspectionCard({
    required this.colors,
    required this.inspection,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final sColor = _inspectionStatusColor(colors, inspection.status);
    final cColor = _conditionColor(colors, inspection.overallCondition);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _inspectionTypeLabel(inspection.inspectionType),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _inspectionStatusLabel(inspection.status),
                  style: TextStyle(
                    color: sColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info row
          Row(
            children: [
              if (inspection.scheduledDate != null) ...[
                Icon(LucideIcons.calendar, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  formatDate(inspection.scheduledDate!),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 16),
              ],
              if (inspection.overallCondition != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _conditionLabel(inspection.overallCondition),
                    style: TextStyle(
                      color: cColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (inspection.score != null) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.star, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${inspection.score}/100',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
          if (inspection.completedDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 13, color: colors.success),
                const SizedBox(width: 4),
                Text(
                  'Completed ${formatDate(inspection.completedDate!)}',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
          if (inspection.notes != null && inspection.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              inspection.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
          if (inspection.photos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.camera, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${inspection.photos.length} photo${inspection.photos.length == 1 ? '' : 's'}',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
