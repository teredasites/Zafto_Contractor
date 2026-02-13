// ZAFTO Scan Verification Screen
// Created: Phase P — Sprint P7
//
// On-site verification workflow — checklist of measurements from Recon.
// Each measurement: label, Recon value, [Confirm] / [Adjust] buttons.
// Adjusted values update DB + recalculate confidence.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/property_scan_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class ScanVerificationScreen extends ConsumerStatefulWidget {
  final String scanId;

  const ScanVerificationScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanVerificationScreen> createState() => _ScanVerificationScreenState();
}

class _ScanVerificationScreenState extends ConsumerState<ScanVerificationScreen> {
  final Map<String, String> _adjustments = {};
  final Set<String> _confirmed = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final asyncData = ref.watch(scanFullDataProvider(widget.scanId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(
          'Verify Measurements',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_confirmed.isNotEmpty || _adjustments.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _saveAll,
              child: _saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600),
                    ),
            ),
        ],
      ),
      body: asyncData.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => Center(
          child: Text(e.toString(), style: TextStyle(color: colors.accentError)),
        ),
        data: (data) {
          if (data == null) {
            return Center(
              child: Text('Scan not found', style: TextStyle(color: colors.textSecondary)),
            );
          }

          final items = _buildVerificationItems(data);
          final confirmedCount = _confirmed.length;
          final adjustedCount = _adjustments.length;
          final totalCount = items.length;
          final progress = totalCount > 0 ? (confirmedCount + adjustedCount) / totalCount : 0.0;

          return Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${confirmedCount + adjustedCount} of $totalCount verified',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$confirmedCount confirmed',
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$adjustedCount adjusted',
                                style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colors.bgElevated,
                        valueColor: AlwaysStoppedAnimation(colors.accentPrimary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Verification items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _VerificationItem(
                      item: item,
                      isConfirmed: _confirmed.contains(item.field),
                      adjustedValue: _adjustments[item.field],
                      colors: colors,
                      onConfirm: () {
                        setState(() {
                          _confirmed.add(item.field);
                          _adjustments.remove(item.field);
                        });
                      },
                      onAdjust: (value) {
                        setState(() {
                          _adjustments[item.field] = value;
                          _confirmed.remove(item.field);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_VerificationData> _buildVerificationItems(ScanFullData data) {
    final items = <_VerificationData>[];

    // Roof measurements
    final roof = data.roof;
    if (roof != null) {
      items.addAll([
        _VerificationData(
          field: 'roof_total_area_sqft',
          label: 'Roof Area',
          value: '${roof.totalAreaSqft.toStringAsFixed(0)} sq ft',
          rawValue: roof.totalAreaSqft.toString(),
          category: 'Roof',
        ),
        _VerificationData(
          field: 'roof_total_area_squares',
          label: 'Roof Squares',
          value: '${roof.totalAreaSquares.toStringAsFixed(1)} SQ',
          rawValue: roof.totalAreaSquares.toString(),
          category: 'Roof',
        ),
        if (roof.pitchPrimary != null)
          _VerificationData(
            field: 'roof_pitch_primary',
            label: 'Primary Pitch',
            value: roof.pitchPrimary!,
            rawValue: roof.pitchPrimary!,
            category: 'Roof',
          ),
        _VerificationData(
          field: 'roof_facet_count',
          label: 'Facet Count',
          value: '${roof.facetCount}',
          rawValue: roof.facetCount.toString(),
          category: 'Roof',
        ),
        if (roof.ridgeLengthFt > 0)
          _VerificationData(
            field: 'roof_ridge_length_ft',
            label: 'Ridge Length',
            value: '${roof.ridgeLengthFt.toStringAsFixed(0)} ft',
            rawValue: roof.ridgeLengthFt.toString(),
            category: 'Roof',
          ),
        if (roof.eaveLengthFt > 0)
          _VerificationData(
            field: 'roof_eave_length_ft',
            label: 'Eave Length',
            value: '${roof.eaveLengthFt.toStringAsFixed(0)} ft',
            rawValue: roof.eaveLengthFt.toString(),
            category: 'Roof',
          ),
      ]);
    }

    // Wall measurements
    final wall = data.wall;
    if (wall != null) {
      items.addAll([
        _VerificationData(
          field: 'wall_total_wall_area_sqft',
          label: 'Total Wall Area',
          value: '${wall.totalWallAreaSqft.toStringAsFixed(0)} sq ft',
          rawValue: wall.totalWallAreaSqft.toString(),
          category: 'Walls',
        ),
        _VerificationData(
          field: 'wall_total_siding_area_sqft',
          label: 'Siding Area',
          value: '${wall.totalSidingAreaSqft.toStringAsFixed(0)} sq ft',
          rawValue: wall.totalSidingAreaSqft.toString(),
          category: 'Walls',
        ),
        _VerificationData(
          field: 'wall_stories',
          label: 'Stories',
          value: '${wall.stories}',
          rawValue: wall.stories.toString(),
          category: 'Walls',
        ),
      ]);
    }

    return items;
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);

    try {
      final repo = ref.read(propertyScanRepoProvider);
      final data = ref.read(scanFullDataProvider(widget.scanId)).valueOrNull;
      if (data == null) return;

      final items = _buildVerificationItems(data);

      // Save confirmations
      for (final field in _confirmed) {
        final item = items.cast<_VerificationData?>().firstWhere(
              (i) => i?.field == field,
              orElse: () => null,
            );
        if (item != null) {
          await repo.verifyMeasurement(
            scanId: widget.scanId,
            field: field,
            oldValue: item.rawValue,
            newValue: item.rawValue,
            isAdjustment: false,
          );
        }
      }

      // Save adjustments
      for (final entry in _adjustments.entries) {
        final item = items.cast<_VerificationData?>().firstWhere(
              (i) => i?.field == entry.key,
              orElse: () => null,
            );
        if (item != null) {
          await repo.verifyMeasurement(
            scanId: widget.scanId,
            field: entry.key,
            oldValue: item.rawValue,
            newValue: entry.value,
            isAdjustment: true,
          );
        }
      }

      // Invalidate to refetch
      ref.invalidate(scanFullDataProvider(widget.scanId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ════════════════════════════════════════════════════════════════
// VERIFICATION DATA
// ════════════════════════════════════════════════════════════════

class _VerificationData {
  final String field;
  final String label;
  final String value;
  final String rawValue;
  final String category;

  const _VerificationData({
    required this.field,
    required this.label,
    required this.value,
    required this.rawValue,
    required this.category,
  });
}

// ════════════════════════════════════════════════════════════════
// VERIFICATION ITEM WIDGET
// ════════════════════════════════════════════════════════════════

class _VerificationItem extends StatefulWidget {
  final _VerificationData item;
  final bool isConfirmed;
  final String? adjustedValue;
  final ZaftoColors colors;
  final VoidCallback onConfirm;
  final ValueChanged<String> onAdjust;

  const _VerificationItem({
    required this.item,
    required this.isConfirmed,
    this.adjustedValue,
    required this.colors,
    required this.onConfirm,
    required this.onAdjust,
  });

  @override
  State<_VerificationItem> createState() => _VerificationItemState();
}

class _VerificationItemState extends State<_VerificationItem> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isAdjusted = widget.adjustedValue != null;
    final statusColor = widget.isConfirmed
        ? Colors.green
        : isAdjusted
            ? Colors.orange
            : colors.borderSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: widget.isConfirmed || isAdjusted ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.item.category,
                  style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              // Status icon
              if (widget.isConfirmed)
                Icon(LucideIcons.checkCircle, size: 18, color: Colors.green)
              else if (isAdjusted)
                Icon(LucideIcons.pencil, size: 18, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          // Value
          Text(
            isAdjusted ? '${widget.item.value}  →  ${widget.adjustedValue}' : widget.item.value,
            style: TextStyle(
              color: isAdjusted ? Colors.orange : colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Editing mode
          if (_editing) ...[
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'New value',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) {
                if (v.isNotEmpty) {
                  widget.onAdjust(v);
                }
                setState(() => _editing = false);
              },
            ),
            const SizedBox(height: 8),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.check,
                  label: 'Confirm',
                  color: Colors.green,
                  isActive: widget.isConfirmed,
                  onTap: widget.onConfirm,
                  bgColor: colors.bgBase,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.pencil,
                  label: 'Adjust',
                  color: Colors.orange,
                  isActive: isAdjusted,
                  onTap: () {
                    _controller.text = widget.item.rawValue;
                    setState(() => _editing = !_editing);
                  },
                  bgColor: colors.bgBase,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final Color bgColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? color.withValues(alpha: 0.15) : bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? color : color.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : color.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
