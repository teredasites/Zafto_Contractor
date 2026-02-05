import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// DWV Pipe Sizing Calculator - Design System v2.6
///
/// Sizes drain, waste, and vent pipes by fixture units.
/// Uses DFU tables per IPC/UPC standards.
///
/// References: IPC 2024 Table 710.1(2), UPC Table 702.1
class DwvPipeSizingScreen extends ConsumerStatefulWidget {
  const DwvPipeSizingScreen({super.key});
  @override
  ConsumerState<DwvPipeSizingScreen> createState() => _DwvPipeSizingScreenState();
}

class _DwvPipeSizingScreenState extends ConsumerState<DwvPipeSizingScreen> {
  // Total DFU load
  double _dfu = 20;

  // Pipe type
  String _pipeType = 'horizontal'; // 'horizontal', 'vertical', 'building'

  // Slope (for horizontal only)
  String _slope = '1/4'; // '1/8' or '1/4' inches per foot

  // DFU capacity tables per IPC Table 710.1(2)
  static const Map<String, Map<String, int>> _horizontalCapacity = {
    '1/8': {
      '1-1/2': 1,
      '2': 8,
      '2-1/2': 14,
      '3': 35,
      '4': 216,
      '5': 428,
      '6': 720,
      '8': 1920,
      '10': 3500,
      '12': 5600,
    },
    '1/4': {
      '1-1/2': 1,
      '2': 8,
      '2-1/2': 14,
      '3': 42,
      '4': 250,
      '5': 500,
      '6': 840,
      '8': 2240,
      '10': 4200,
      '12': 6720,
    },
  };

  // Vertical stack capacity per IPC Table 710.1(1)
  static const Map<String, int> _verticalCapacity = {
    '1-1/2': 2,
    '2': 6,
    '2-1/2': 12,
    '3': 32,
    '4': 256,
    '5': 480,
    '6': 840,
    '8': 2640,
    '10': 5040,
    '12': 8400,
  };

  // Building drain capacity (same as 1/8" slope typically)
  static const Map<String, int> _buildingDrainCapacity = {
    '2': 8,
    '2-1/2': 14,
    '3': 35,
    '4': 216,
    '5': 428,
    '6': 720,
    '8': 1920,
    '10': 3500,
    '12': 5600,
  };

  static const List<({String value, String label})> _pipeTypes = [
    (value: 'horizontal', label: 'Horizontal Branch'),
    (value: 'vertical', label: 'Vertical Stack'),
    (value: 'building', label: 'Building Drain'),
  ];

  String _calculatePipeSize() {
    final dfu = _dfu.round();
    Map<String, int> capacity;

    if (_pipeType == 'horizontal') {
      capacity = _horizontalCapacity[_slope] ?? _horizontalCapacity['1/4']!;
    } else if (_pipeType == 'vertical') {
      capacity = _verticalCapacity;
    } else {
      capacity = _buildingDrainCapacity;
    }

    for (final entry in capacity.entries) {
      if (entry.value >= dfu) {
        return '${entry.key}"';
      }
    }

    return '> 12"';
  }

  int _getCapacity(String size) {
    if (_pipeType == 'horizontal') {
      return (_horizontalCapacity[_slope] ?? _horizontalCapacity['1/4']!)[size] ?? 0;
    } else if (_pipeType == 'vertical') {
      return _verticalCapacity[size] ?? 0;
    } else {
      return _buildingDrainCapacity[size] ?? 0;
    }
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
          'DWV Pipe Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, recommendedSize),
          const SizedBox(height: 16),
          _buildPipeTypeCard(colors),
          const SizedBox(height: 16),
          if (_pipeType == 'horizontal') ...[
            _buildSlopeCard(colors),
            const SizedBox(height: 16),
          ],
          _buildDfuCard(colors),
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
            'Minimum Pipe Size',
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
                _buildResultRow(colors, 'Pipe Type', _pipeTypes.firstWhere((t) => t.value == _pipeType).label),
                if (_pipeType == 'horizontal') ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Slope', '$_slope"/ft'),
                ],
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(
                  colors,
                  'Capacity',
                  '${_getCapacity(recommendedSize.replaceAll('"', ''))} DFU',
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeTypeCard(ZaftoColors colors) {
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
            'PIPE TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_pipeTypes.length, (i) {
            final type = _pipeTypes[i];
            final isSelected = _pipeType == type.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeType = type.value);
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
                        type.value == 'horizontal' ? LucideIcons.arrowRight
                            : type.value == 'vertical' ? LucideIcons.arrowDown
                            : LucideIcons.home,
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.label,
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
            'DRAIN SLOPE',
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _slope = '1/8');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _slope == '1/8' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1/8"/ft',
                          style: TextStyle(
                            color: _slope == '1/8'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '3"+ pipe only',
                          style: TextStyle(
                            color: _slope == '1/8'
                                ? (colors.isDark ? Colors.black54 : Colors.white70)
                                : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _slope = '1/4');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _slope == '1/4' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1/4"/ft',
                          style: TextStyle(
                            color: _slope == '1/4'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'All pipe sizes',
                          style: TextStyle(
                            color: _slope == '1/4'
                                ? (colors.isDark ? Colors.black54 : Colors.white70)
                                : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
            'DRAINAGE FIXTURE UNITS (DFU)',
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
                    min: 1,
                    max: 500,
                    divisions: 499,
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
            'Total fixture units draining to this pipe',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityTable(ZaftoColors colors) {
    Map<String, int> capacity;
    String tableTitle;

    if (_pipeType == 'horizontal') {
      capacity = _horizontalCapacity[_slope] ?? _horizontalCapacity['1/4']!;
      tableTitle = 'HORIZONTAL BRANCH CAPACITY ($_slope"/FT)';
    } else if (_pipeType == 'vertical') {
      capacity = _verticalCapacity;
      tableTitle = 'VERTICAL STACK CAPACITY';
    } else {
      capacity = _buildingDrainCapacity;
      tableTitle = 'BUILDING DRAIN CAPACITY';
    }

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
            tableTitle,
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
                'IPC 2024 Table 710.1',
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
            '• Min drain: 1-1/2" (except WC)\n'
            '• Min building drain: 3" (with WC)\n'
            '• 1/8"/ft min for 3"+ pipe\n'
            '• 1/4"/ft min for <3" pipe\n'
            '• Size up for long runs\n'
            '• UPC has similar requirements',
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
