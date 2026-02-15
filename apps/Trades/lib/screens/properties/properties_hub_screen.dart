import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'property_detail_screen.dart';

class PropertiesHubScreen extends ConsumerStatefulWidget {
  const PropertiesHubScreen({super.key});

  @override
  ConsumerState<PropertiesHubScreen> createState() =>
      _PropertiesHubScreenState();
}

class _PropertiesHubScreenState extends ConsumerState<PropertiesHubScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final propertiesAsync = ref.watch(propertiesProvider);
    final stats = ref.watch(propertyStatsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Properties',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: propertiesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        data: (properties) => _buildContent(colors, properties, stats),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accentPrimary,
        onPressed: () {
          HapticFeedback.selectionClick();
          _showCreatePropertyDialog(ref.read(zaftoColorsProvider));
        },
        child: Icon(LucideIcons.plus, color: colors.textOnAccent),
      ),
    );
  }

  void _showCreatePropertyDialog(ZaftoColors colors) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Property',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Property Name',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await ref.read(propertiesProvider.notifier).add(
                          Property(
                            name: name,
                            addressLine1: addressController.text.trim(),
                            city: '',
                            state: '',
                            zip: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create property: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Property',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ZaftoColors colors,
    List<Property> properties,
    PropertyStats stats,
  ) {
    final filtered = properties.where((p) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.fullAddress.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Stats bar
        Container(
          color: colors.bgElevated,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                colors: colors,
                label: 'Properties',
                value: '${stats.totalProperties}',
              ),
              _StatChip(
                colors: colors,
                label: 'Units',
                value: '${stats.totalUnits}',
              ),
              _StatChip(
                colors: colors,
                label: 'Occupancy',
                value: '${stats.occupancyRate}%',
              ),
              _StatChip(
                colors: colors,
                label: 'Vacant',
                value: '${stats.vacantUnits}',
              ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search properties...',
              hintStyle: TextStyle(color: colors.textTertiary),
              prefixIcon:
                  Icon(LucideIcons.search, color: colors.textTertiary),
              filled: true,
              fillColor: colors.bgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Property list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No properties found',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _PropertyCard(
                    colors: colors,
                    property: filtered[index],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailScreen(
                            propertyId: filtered[index].id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;

  const _StatChip({
    required this.colors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: colors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final ZaftoColors colors;
  final Property property;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.colors,
    required this.property,
    required this.onTap,
  });

  String _formatPropertyType(PropertyType type) {
    switch (type) {
      case PropertyType.singleFamily:
        return 'Single Family';
      case PropertyType.multiFamily:
        return 'Multi Family';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.duplex:
        return 'Duplex';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.mixedUse:
        return 'Mixed Use';
      case PropertyType.other:
        return 'Other';
    }
  }

  Color _statusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.active:
        return colors.accentSuccess;
      case PropertyStatus.inactive:
        return colors.accentWarning;
      case PropertyStatus.sold:
        return colors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    property.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatPropertyType(property.propertyType),
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              property.fullAddress,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.doorOpen,
                    size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${property.totalUnits} unit${property.totalUnits == 1 ? '' : 's'}',
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(property.status)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    property.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(property.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
