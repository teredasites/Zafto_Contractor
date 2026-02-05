import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Coffee/Beverage Service Calculator - Design System v2.6
///
/// Calculates plumbing requirements for commercial coffee and beverage equipment.
/// Covers water supply, drainage, and filtration needs.
///
/// References: IPC 2024, NSF Standards
class CoffeeServiceScreen extends ConsumerStatefulWidget {
  const CoffeeServiceScreen({super.key});
  @override
  ConsumerState<CoffeeServiceScreen> createState() => _CoffeeServiceScreenState();
}

class _CoffeeServiceScreenState extends ConsumerState<CoffeeServiceScreen> {
  // Equipment type
  String _equipmentType = 'brewer';

  // Number of units
  int _unitCount = 1;

  // Filtration required
  bool _filtrationRequired = true;

  static const Map<String, ({String desc, double gpm, int supplySize, int drainSize, int dfu, bool backflow})> _equipmentTypes = {
    'brewer': (desc: 'Coffee Brewer', gpm: 0.5, supplySize: 38, drainSize: 1, dfu: 1, backflow: true),
    'espresso': (desc: 'Espresso Machine', gpm: 1.0, supplySize: 50, drainSize: 1, dfu: 1, backflow: true),
    'iced_tea': (desc: 'Iced Tea Brewer', gpm: 0.5, supplySize: 38, drainSize: 1, dfu: 1, backflow: true),
    'hot_water': (desc: 'Hot Water Dispenser', gpm: 0.75, supplySize: 50, drainSize: 1, dfu: 1, backflow: true),
    'soda': (desc: 'Soda/Carbonation', gpm: 0.5, supplySize: 38, drainSize: 2, dfu: 2, backflow: true),
    'ice_bin': (desc: 'Ice Bin with Drain', gpm: 0.0, supplySize: 0, drainSize: 1, dfu: 1, backflow: false),
  };

  // Get equipment specs
  double get _totalGpm {
    final equipment = _equipmentTypes[_equipmentType];
    return (equipment?.gpm ?? 0.5) * _unitCount;
  }

  int get _supplySize => _equipmentTypes[_equipmentType]?.supplySize ?? 38;
  int get _drainSize => _equipmentTypes[_equipmentType]?.drainSize ?? 1;
  int get _totalDfu => (_equipmentTypes[_equipmentType]?.dfu ?? 1) * _unitCount;
  bool get _needsBackflow => _equipmentTypes[_equipmentType]?.backflow ?? true;

  // Supply pipe size string
  String get _supplyPipe {
    if (_supplySize == 0) return 'N/A';
    if (_supplySize <= 38) return '⅜\"';
    if (_supplySize <= 50) return '½\"';
    return '¾\"';
  }

  // Filter recommendations
  String get _filterType {
    if (!_filtrationRequired) return 'None specified';
    if (_equipmentType == 'espresso') return '5 micron + carbon';
    if (_equipmentType == 'soda') return 'Carbon + scale inhibitor';
    return '5 micron sediment + carbon';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Coffee/Beverage Service',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildUnitCountCard(colors),
          const SizedBox(height: 16),
          _buildFiltrationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final equipment = _equipmentTypes[_equipmentType];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            _supplyPipe,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Supply Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Equipment', equipment?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Units', '$_unitCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Flow', '${_totalGpm.toStringAsFixed(2)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Size', '$_drainSize\" indirect'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total DFU', '$_totalDfu'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Backflow Device', _needsBackflow ? 'Required' : 'N/A'),
                if (_filtrationRequired) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Filter Type', _filterType),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EQUIPMENT TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._equipmentTypes.entries.map((entry) {
            final isSelected = _equipmentType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _equipmentType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (entry.value.gpm > 0)
                        Text(
                          '${entry.value.gpm} GPM',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnitCountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUMBER OF UNITS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Unit Count', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_unitCount',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _unitCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _unitCount = v.round());
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5].map((count) {
              final isSelected = _unitCount == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _unitCount = count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _filtrationRequired ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _filtrationRequired ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filtrationRequired = !_filtrationRequired);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _filtrationRequired ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _filtrationRequired ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _filtrationRequired
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water Filtration',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Recommended for equipment protection',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.coffee, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 / NSF',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Indirect drain connection\n'
            '• Air gap required for drain\n'
            '• Backflow preventer on supply\n'
            '• Filter before equipment\n'
            '• Accessible shut-off valve\n'
            '• NSF listed equipment',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
