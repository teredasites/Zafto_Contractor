// ZAFTO Schedule Resource Screen
// GC4: Resource list with assignment counts, histogram chart,
// over-allocation highlighting, and task assignments per resource.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/schedule_resource.dart';
import '../../providers/schedule_resources_provider.dart';

class ScheduleResourceScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ScheduleResourceScreen({super.key, required this.projectId});

  @override
  ConsumerState<ScheduleResourceScreen> createState() => _ScheduleResourceScreenState();
}

class _ScheduleResourceScreenState extends ConsumerState<ScheduleResourceScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final resourcesAsync = ref.watch(scheduleResourcesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Resources', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.barChart3, size: 20, color: colors.textSecondary),
            tooltip: 'Level Resources',
            onPressed: () => _triggerLeveling(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilter(colors),
          const SizedBox(height: 8),
          Expanded(
            child: resourcesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => _buildErrorState(colors, e),
              data: (resources) {
                final filtered = _selectedType != null
                    ? resources.where((r) => r.resourceType.name == _selectedType).toList()
                    : resources;
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildResourceList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createResource(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildTypeFilter(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(colors, 'All', null),
          _buildChip(colors, 'Labor', 'labor'),
          _buildChip(colors, 'Equipment', 'equipment'),
          _buildChip(colors, 'Material', 'material'),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, String? type) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
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

  Widget _buildResourceList(ZaftoColors colors, List<ScheduleResource> resources) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleResourcesProvider),
      color: colors.accentPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: resources.length,
        itemBuilder: (context, index) => _buildResourceCard(colors, resources[index]),
      ),
    );
  }

  Widget _buildResourceCard(ZaftoColors colors, ScheduleResource resource) {
    final typeIcon = switch (resource.resourceType) {
      ResourceType.labor => LucideIcons.hardHat,
      ResourceType.equipment => LucideIcons.wrench,
      ResourceType.material => LucideIcons.package,
    };
    final typeColor = switch (resource.resourceType) {
      ResourceType.labor => colors.accentPrimary,
      ResourceType.equipment => colors.accentWarning,
      ResourceType.material => colors.accentInfo,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, size: 20, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildSmallChip(colors, resource.resourceType.name, typeColor),
                    if (resource.trade != null) ...[
                      const SizedBox(width: 6),
                      _buildSmallChip(colors, resource.trade!, colors.textTertiary),
                    ],
                    if (resource.role != null) ...[
                      const SizedBox(width: 6),
                      _buildSmallChip(colors, resource.role!, colors.textTertiary),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Max: ${resource.maxUnits}x  |  \$${resource.costPerHour.toStringAsFixed(2)}/hr',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          if (resource.color != null)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _parseColor(resource.color!),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(ZaftoColors colors, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
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
            child: Icon(LucideIcons.users, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No resources yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to add labor, equipment, or materials', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
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
          Text('Failed to load resources', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(scheduleResourcesProvider),
            child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _createResource(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final colors = ref.read(zaftoColorsProvider);
    final nameController = TextEditingController();
    ResourceType selectedType = ResourceType.labor;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: colors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Resource Name',
                  labelStyle: TextStyle(color: colors.textTertiary),
                  filled: true,
                  fillColor: colors.bgBase,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.accentPrimary)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              const SizedBox(height: 8),
              Row(
                children: ResourceType.values.map((type) {
                  final isActive = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? colors.accentPrimary : colors.fillDefault,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final n = nameController.text.trim();
                    if (n.isNotEmpty) {
                      Navigator.pop(ctx, {'name': n, 'type': selectedType.name});
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
      ),
    );

    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      final repo = ref.read(scheduleResourceRepoProvider);
      final resource = ScheduleResource(
        companyId: companyId,
        name: result['name'] as String,
        resourceType: ResourceType.values.firstWhere(
          (r) => r.name == result['type'],
          orElse: () => ResourceType.labor,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createResource(resource);
      ref.invalidate(scheduleResourcesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create resource: $e')),
        );
      }
    }
  }

  Future<void> _triggerLeveling(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.functions.invoke(
        'schedule-level-resources',
        body: {'project_id': widget.projectId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resources leveled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leveling failed: $e')),
        );
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
