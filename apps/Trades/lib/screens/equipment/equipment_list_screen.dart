// ZAFTO Equipment List Screen
// Created: Sprint FIELD2 (Session 131)
//
// Browse all company tools/equipment with search, filter by category/status.
// Tap to view details. FAB for admins to add new equipment.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/equipment_item.dart';
import '../../providers/equipment_provider.dart';
import '../../widgets/error_widgets.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _searchQuery = '';
  EquipmentCategory? _categoryFilter;
  String _statusFilter = 'all'; // all, available, checked_out

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(equipmentItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'available', child: Text('Available')),
              const PopupMenuItem(value: 'checked_out', child: Text('Checked Out')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tools...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('All', _categoryFilter == null, () => setState(() => _categoryFilter = null)),
                ...EquipmentCategory.values.map((cat) =>
                    _filterChip(cat.label, _categoryFilter == cat, () => setState(() => _categoryFilter = cat))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: itemsAsync.when(
              loading: () => const ZaftoLoadingState(message: 'Loading equipment...'),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load equipment',
                onRetry: () => ref.invalidate(equipmentItemsProvider),
              ),
              data: (items) {
                var filtered = items.where((item) {
                  if (_searchQuery.isNotEmpty) {
                    final match = item.name.toLowerCase().contains(_searchQuery) ||
                        (item.serialNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (item.barcode?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (item.manufacturer?.toLowerCase().contains(_searchQuery) ?? false);
                    if (!match) return false;
                  }
                  if (_categoryFilter != null && item.category != _categoryFilter) return false;
                  if (_statusFilter == 'available' && item.isCheckedOut) return false;
                  if (_statusFilter == 'checked_out' && !item.isCheckedOut) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return ZaftoEmptyState(
                    icon: Icons.build_outlined,
                    title: _searchQuery.isNotEmpty ? 'No tools found' : 'No equipment yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different search'
                        : 'Add your first tool to start tracking',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(equipmentItemsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _EquipmentTile(item: item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final EquipmentItem item;
  const _EquipmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor(item.category).withValues(alpha: 0.15),
          child: Icon(_categoryIcon(item.category), color: _categoryColor(item.category), size: 20),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(item.category.label, style: theme.textTheme.bodySmall),
            if (item.serialNumber != null) ...[
              const Text(' \u2022 ', style: TextStyle(color: Colors.grey)),
              Flexible(
                child: Text(
                  'S/N: ${item.serialNumber}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _conditionBadge(item.condition),
            const SizedBox(width: 8),
            if (item.isCheckedOut)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EquipmentDetailScreen(itemId: item.id)),
        ),
      ),
    );
  }

  Widget _conditionBadge(EquipmentCondition condition) {
    final color = switch (condition) {
      EquipmentCondition.newCondition || EquipmentCondition.good => Colors.green,
      EquipmentCondition.fair => Colors.amber,
      EquipmentCondition.poor || EquipmentCondition.damaged => Colors.red,
      EquipmentCondition.retired => Colors.grey,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  IconData _categoryIcon(EquipmentCategory cat) => switch (cat) {
        EquipmentCategory.handTool => Icons.handyman,
        EquipmentCategory.powerTool => Icons.power,
        EquipmentCategory.testingEquipment => Icons.speed,
        EquipmentCategory.safetyEquipment => Icons.health_and_safety,
        EquipmentCategory.vehicleMounted => Icons.local_shipping,
        EquipmentCategory.specialty => Icons.precision_manufacturing,
      };

  Color _categoryColor(EquipmentCategory cat) => switch (cat) {
        EquipmentCategory.handTool => Colors.blue,
        EquipmentCategory.powerTool => Colors.orange,
        EquipmentCategory.testingEquipment => Colors.purple,
        EquipmentCategory.safetyEquipment => Colors.red,
        EquipmentCategory.vehicleMounted => Colors.teal,
        EquipmentCategory.specialty => Colors.indigo,
      };
}
