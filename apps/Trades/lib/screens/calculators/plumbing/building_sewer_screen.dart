import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Building Sewer Sizing Calculator - Design System v2.6
///
/// Sizes the building sewer (lateral) from building to main.
/// Considers DFU load, slope, and pipe material.
///
/// References: IPC 2024 Section 710, Table 710.1(2)
class BuildingSewerScreen extends ConsumerStatefulWidget {
  const BuildingSewerScreen({super.key});
  @override
  ConsumerState<BuildingSewerScreen> createState() => _BuildingSewerScreenState();
}

class _BuildingSewerScreenState extends ConsumerState<BuildingSewerScreen> {
  // Total DFU load
  double _dfu = 50;

  // Slope
  String _slope = '1/8';

  // Pipe material
  String _material = 'pvc';

  // Run length (for info only)
  double _runLength = 50;

  // Capacity tables per IPC Table 710.1(2)
  static const Map<String, Map<String, int>> _sewerCapacity = {
    '1/16': {
      '4': 180,
      '5': 390,
      '6': 700,
      '8': 1600,
      '10': 2900,
      '12': 4600,
    },
    '1/8': {
      '4': 216,
      '5': 428,
      '6': 720,
      '8': 1920,
      '10': 3500,
      '12': 5600,
    },
    '1/4': {
      '4': 250,
      '5': 500,
      '6': 840,
      '8': 2240,
      '10': 4200,
      '12': 6720,
    },
  };

  static const List<({String value, String label})> _slopes = [
    (value: '1/16', label: '1/16"/ft (min for 4"+)'),
    (value: '1/8', label: '1/8"/ft (standard)'),
    (value: '1/4', label: '1/4"/ft (preferred)'),
  ];

  static const List<({String value, String label})> _materials = [
    (value: 'pvc', label: 'PVC (SDR 35)'),
    (value: 'abs', label: 'ABS'),
    (value: 'castIron', label: 'Cast Iron'),
    (value: 'clay', label: 'Vitrified Clay'),
  ];

  String _calculatePipeSize() {
    final dfu = _dfu.round();
    final capacity = _sewerCapacity[_slope] ?? _sewerCapacity['1/8']!;

    for (final entry in capacity.entries) {
      if (entry.value >= dfu) {
        return '${entry.key}"';
      }
    }

    return '> 12"';
  }

  int _getCapacity(String size) {
    return (_sewerCapacity[_slope] ?? _sewerCapacity['1/8']!)[size] ?? 0;
  }

  double _getTotalDrop() {
    final slopeValue = _slope == '1/16' ? 0.0625 : _slope == '1/8' ? 0.125 : 0.25;
    return _runLength * slopeValue;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final recommendedSize = _calculatePipeSize();

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
          'Building Sewer Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, recommendedSize),
          const SizedBox(height: 16),
          _buildDfuCard(colors),
          const SizedBox(height: 16),
          _buildSlopeCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          const SizedBox(height: 16),
          _buildCapacityTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, String recommendedSize) {
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
            recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Sewer Size',
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
                _buildResultRow(colors, 'DFU Load', _dfu.toStringAsFixed(0)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Slope', _slopes.firstWhere((s) => s.value == _slope).label.split(' ')[0]),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Material', _materials.firstWhere((m) => m.value == _material).label),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Run Length', '${_runLength.toStringAsFixed(0)} ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Total Drop', '${_getTotalDrop().toStringAsFixed(1)}"', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Capacity', '${_getCapacity(recommendedSize.replaceAll('"', ''))} DFU'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDfuCard(ZaftoColors colors) {
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
            'TOTAL DFU LOAD',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_dfu.toStringAsFixed(0)} DFU',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _dfu,
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _dfu = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total fixture units for entire building',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeCard(ZaftoColors colors) {
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
            'SEWER SLOPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_slopes.length, (i) {
            final slope = _slopes[i];
            final isSelected = _slope == slope.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _slope = slope.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        slope.label,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  Widget _buildMaterialCard(ZaftoColors colors) {
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
            'PIPE MATERIAL',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _materials.map((mat) {
              final isSelected = _material == mat.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _material = mat.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mat.label,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildRunLengthCard(ZaftoColors colors) {
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
            'RUN LENGTH',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_runLength.toStringAsFixed(0)} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _runLength,
                    min: 10,
                    max: 200,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _runLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Distance from building to city main/septic',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityTable(ZaftoColors colors) {
    final capacity = _sewerCapacity[_slope] ?? _sewerCapacity['1/8']!;
    final recommendedSize = _calculatePipeSize().replaceAll('"', '');

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
            'SEWER CAPACITY ($_slope"/FT)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...capacity.entries.map((entry) {
            final isRecommended = entry.key == recommendedSize;
            final meetsLoad = entry.value >= _dfu;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${entry.key}"',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value} DFU',
                      style: TextStyle(
                        color: meetsLoad ? colors.textSecondary : colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 710',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Min sewer size: 4" (typically)\n'
            '• Min slope 1/16"/ft for 4"+ pipe\n'
            '• 1/8"/ft standard recommendation\n'
            '• Cleanouts every 100 ft max\n'
            '• Bedding required per spec\n'
            '• Check local depth requirements',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
