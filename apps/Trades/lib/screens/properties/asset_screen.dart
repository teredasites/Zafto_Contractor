import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property_asset.dart';
import '../../repositories/asset_repository.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// No asset provider exists — load data manually via Supabase query.
import 'package:supabase_flutter/supabase_flutter.dart';

final _propertyAssetsProvider =
    FutureProvider.autoDispose<List<PropertyAsset>>((ref) async {
  final response = await Supabase.instance.client
      .from('property_assets')
      .select()
      .eq('status', 'active')
      .order('created_at', ascending: false);
  return (response as List)
      .map((row) => PropertyAsset.fromJson(row as Map<String, dynamic>))
      .toList();
});

class AssetScreen extends ConsumerStatefulWidget {
  const AssetScreen({super.key});

  @override
  ConsumerState<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<AssetScreen> {
  final Set<String> _expandedIds = {};

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final assetsAsync = ref.watch(_propertyAssetsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Asset Health',
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
              ref.invalidate(_propertyAssetsProvider);
            },
            icon: Icon(LucideIcons.refreshCw, size: 20, color: colors.textSecondary),
          ),
        ],
      ),
      body: assetsAsync.when(
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
                'Failed to load assets',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_propertyAssetsProvider),
                child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
        data: (assets) => _buildContent(colors, assets),
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<PropertyAsset> assets) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.hardDrive, size: 48, color: colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No assets tracked',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Add assets from property details',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final isExpanded = _expandedIds.contains(asset.id);

        return _AssetCard(
          colors: colors,
          asset: asset,
          isExpanded: isExpanded,
          formatDate: _formatDate,
          onToggle: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_expandedIds.contains(asset.id)) {
                _expandedIds.remove(asset.id);
              } else {
                _expandedIds.add(asset.id);
              }
            });
          },
          onAddService: () => _showAddServiceSheet(colors, asset),
        );
      },
    );
  }

  void _showAddServiceSheet(ZaftoColors colors, PropertyAsset asset) {
    HapticFeedback.selectionClick();
    final descriptionController = TextEditingController();
    final costController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
              'Add Service Record',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${asset.brand ?? 'Unknown'} ${asset.model ?? ''}'.trim(),
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: colors.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Cost (optional)',
                labelStyle: TextStyle(color: colors.textTertiary),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: colors.textPrimary),
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
                    final repo = AssetRepository();
                    await repo.addServiceRecord(AssetServiceRecord(
                      assetId: asset.id,
                      serviceType: ServiceType.routine,
                      serviceDate: DateTime.now(),
                      description: descriptionController.text.trim(),
                      cost: double.tryParse(costController.text.trim()),
                      createdAt: DateTime.now(),
                    ));
                    ref.invalidate(_propertyAssetsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service record saved')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save record: $e')),
                      );
                    }
                  }
                },
                child: const Text(
                  'Save Record',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _assetTypeIcon(AssetType type) {
  return switch (type) {
    AssetType.hvac => LucideIcons.thermometer,
    AssetType.waterHeater => LucideIcons.flame,
    AssetType.appliance => LucideIcons.refrigerator,
    AssetType.roof => LucideIcons.home,
    AssetType.plumbing => LucideIcons.droplets,
    AssetType.electrical => LucideIcons.zap,
    AssetType.flooring => LucideIcons.layers,
    AssetType.window => LucideIcons.squareStack,
    AssetType.door => LucideIcons.doorOpen,
    AssetType.exterior => LucideIcons.building2,
    AssetType.landscaping => LucideIcons.trees,
    AssetType.security => LucideIcons.shield,
    AssetType.other => LucideIcons.hardDrive,
  };
}

String _assetTypeLabel(AssetType type) {
  return switch (type) {
    AssetType.hvac => 'HVAC',
    AssetType.waterHeater => 'Water Heater',
    AssetType.appliance => 'Appliance',
    AssetType.roof => 'Roof',
    AssetType.plumbing => 'Plumbing',
    AssetType.electrical => 'Electrical',
    AssetType.flooring => 'Flooring',
    AssetType.window => 'Window',
    AssetType.door => 'Door',
    AssetType.exterior => 'Exterior',
    AssetType.landscaping => 'Landscaping',
    AssetType.security => 'Security',
    AssetType.other => 'Other',
  };
}

Color _conditionColor(ZaftoColors colors, AssetCondition condition) {
  return switch (condition) {
    AssetCondition.excellent => colors.success,
    AssetCondition.good => colors.success,
    AssetCondition.fair => colors.warning,
    AssetCondition.poor => colors.error,
    AssetCondition.needsReplacement => colors.error,
  };
}

String _conditionLabel(AssetCondition condition) {
  return switch (condition) {
    AssetCondition.excellent => 'EXCELLENT',
    AssetCondition.good => 'GOOD',
    AssetCondition.fair => 'FAIR',
    AssetCondition.poor => 'POOR',
    AssetCondition.needsReplacement => 'REPLACE',
  };
}

class _AssetCard extends StatelessWidget {
  final ZaftoColors colors;
  final PropertyAsset asset;
  final bool isExpanded;
  final String Function(DateTime?) formatDate;
  final VoidCallback onToggle;
  final VoidCallback onAddService;

  const _AssetCard({
    required this.colors,
    required this.asset,
    required this.isExpanded,
    required this.formatDate,
    required this.onToggle,
    required this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    final cColor = _conditionColor(colors, asset.condition);
    final displayName =
        '${asset.brand ?? ''} ${asset.model ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Card header
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _assetTypeIcon(asset.assetType),
                    size: 20,
                    color: colors.accentPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty
                              ? displayName
                              : _assetTypeLabel(asset.assetType),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Condition badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _conditionLabel(asset.condition),
                                style: TextStyle(
                                  color: cColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (asset.warrantyActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.accentPrimary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'WARRANTY',
                                  style: TextStyle(
                                    color: colors.accentPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (asset.needsService) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SERVICE DUE',
                                  style: TextStyle(
                                    color: colors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          // Expanded detail info
          if (isExpanded) ...[
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    colors: colors,
                    label: 'Type',
                    value: _assetTypeLabel(asset.assetType),
                  ),
                  if (asset.serialNumber != null)
                    _DetailRow(
                      colors: colors,
                      label: 'Serial #',
                      value: asset.serialNumber!,
                    ),
                  _DetailRow(
                    colors: colors,
                    label: 'Install Date',
                    value: formatDate(asset.installDate),
                  ),
                  _DetailRow(
                    colors: colors,
                    label: 'Last Service',
                    value: formatDate(asset.lastServiceDate),
                  ),
                  _DetailRow(
                    colors: colors,
                    label: 'Next Service',
                    value: formatDate(asset.nextServiceDate),
                  ),
                  if (asset.warrantyActive)
                    _DetailRow(
                      colors: colors,
                      label: 'Warranty Until',
                      value: formatDate(asset.warrantyExpires),
                    ),
                  if (asset.replacementCost != null)
                    _DetailRow(
                      colors: colors,
                      label: 'Replacement Cost',
                      value: '\$${asset.replacementCost!.toStringAsFixed(2)}',
                    ),
                  if (asset.expectedLifespanYears != null)
                    _DetailRow(
                      colors: colors,
                      label: 'Expected Lifespan',
                      value: '${asset.expectedLifespanYears} years',
                    ),
                  if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      asset.notes!,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Add service button
                  GestureDetector(
                    onTap: onAddService,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: colors.accentPrimary
                                .withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plus,
                              size: 14, color: colors.accentPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Add Service Record',
                            style: TextStyle(
                              color: colors.accentPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;

  const _DetailRow({
    required this.colors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
