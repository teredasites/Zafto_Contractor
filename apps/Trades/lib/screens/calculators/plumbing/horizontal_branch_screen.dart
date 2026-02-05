import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Horizontal Branch Sizing Calculator - Design System v2.6
///
/// Calculates horizontal branch drain sizing for fixture groups.
/// Includes common bathroom and kitchen configurations.
///
/// References: IPC 2024 Section 710, Table 710.1(2)
class HorizontalBranchScreen extends ConsumerStatefulWidget {
  const HorizontalBranchScreen({super.key});
  @override
  ConsumerState<HorizontalBranchScreen> createState() => _HorizontalBranchScreenState();
}

class _HorizontalBranchScreenState extends ConsumerState<HorizontalBranchScreen> {
  // Fixture counts
  int _toilets = 1;
  int _lavatories = 1;
  int _bathtubs = 0;
  int _showers = 1;
  int _kitchenSinks = 0;
  int _dishwashers = 0;
  int _washingMachines = 0;
  int _floorDrains = 0;

  // Configuration presets
  String _preset = 'custom';

  // Slope
  String _slope = '1/4';

  // DFU values per IPC Table 709.1
  static const Map<String, double> _dfuValues = {
    'toilet': 3.0, // Water closet (1.6 gpf)
    'lavatory': 1.0,
    'bathtub': 2.0,
    'shower': 2.0,
    'kitchenSink': 2.0,
    'dishwasher': 2.0,
    'washingMachine': 2.0,
    'floorDrain': 2.0,
  };

  // Presets for common configurations
  static const List<({String value, String label, Map<String, int> fixtures})> _presets = [
    (value: 'custom', label: 'Custom', fixtures: {}),
    (value: 'halfBath', label: 'Half Bath', fixtures: {'toilet': 1, 'lavatory': 1}),
    (value: 'fullBath', label: 'Full Bath', fixtures: {'toilet': 1, 'lavatory': 1, 'bathtub': 1}),
    (value: 'masterBath', label: 'Master Bath', fixtures: {'toilet': 1, 'lavatory': 2, 'shower': 1, 'bathtub': 1}),
    (value: 'kitchen', label: 'Kitchen', fixtures: {'kitchenSink': 1, 'dishwasher': 1}),
    (value: 'laundry', label: 'Laundry', fixtures: {'washingMachine': 1, 'floorDrain': 1}),
  ];

  // Capacity tables per IPC Table 710.1(2)
  static const Map<String, Map<String, int>> _branchCapacity = {
    '1/8': {
      '1-1/2': 1,
      '2': 8,
      '2-1/2': 14,
      '3': 35,
      '4': 216,
    },
    '1/4': {
      '1-1/2': 1,
      '2': 8,
      '2-1/2': 14,
      '3': 42,
      '4': 250,
    },
  };

  double get _totalDfu {
    return (_toilets * _dfuValues['toilet']!) +
           (_lavatories * _dfuValues['lavatory']!) +
           (_bathtubs * _dfuValues['bathtub']!) +
           (_showers * _dfuValues['shower']!) +
           (_kitchenSinks * _dfuValues['kitchenSink']!) +
           (_dishwashers * _dfuValues['dishwasher']!) +
           (_washingMachines * _dfuValues['washingMachine']!) +
           (_floorDrains * _dfuValues['floorDrain']!);
  }

  bool get _hasToilet => _toilets > 0;

  String _calculatePipeSize() {
    final dfu = _totalDfu.round();
    final capacity = _branchCapacity[_slope] ?? _branchCapacity['1/4']!;

    // Min 3" if serving toilet
    final minSize = _hasToilet ? '3' : '1-1/2';

    for (final entry in capacity.entries) {
      if (_compareSize(entry.key, minSize) >= 0 && entry.value >= dfu) {
        return '${entry.key}"';
      }
    }

    return '> 4"';
  }

  int _compareSize(String a, String b) {
    final sizeOrder = ['1-1/2', '2', '2-1/2', '3', '4'];
    return sizeOrder.indexOf(a).compareTo(sizeOrder.indexOf(b));
  }

  void _applyPreset(String presetValue) {
    final preset = _presets.firstWhere((p) => p.value == presetValue);
    if (preset.value == 'custom') return;

    setState(() {
      _preset = presetValue;
      _toilets = preset.fixtures['toilet'] ?? 0;
      _lavatories = preset.fixtures['lavatory'] ?? 0;
      _bathtubs = preset.fixtures['bathtub'] ?? 0;
      _showers = preset.fixtures['shower'] ?? 0;
      _kitchenSinks = preset.fixtures['kitchenSink'] ?? 0;
      _dishwashers = preset.fixtures['dishwasher'] ?? 0;
      _washingMachines = preset.fixtures['washingMachine'] ?? 0;
      _floorDrains = preset.fixtures['floorDrain'] ?? 0;
    });
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
          'Horizontal Branch Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, recommendedSize),
          const SizedBox(height: 16),
          _buildPresetCard(colors),
          const SizedBox(height: 16),
          _buildSlopeCard(colors),
          const SizedBox(height: 16),
          _buildFixtureCard(colors),
          const SizedBox(height: 16),
          _buildDfuBreakdown(colors),
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
            'Minimum Branch Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_hasToilet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Min 3" required (toilet)',
                    style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total DFU', _totalDfu.toStringAsFixed(1)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Slope', '$_slope"/ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Fixtures', '${_getFixtureCount()}'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Branch Size', recommendedSize, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getFixtureCount() {
    return _toilets + _lavatories + _bathtubs + _showers +
           _kitchenSinks + _dishwashers + _washingMachines + _floorDrains;
  }

  Widget _buildPresetCard(ZaftoColors colors) {
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
            'QUICK PRESETS',
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
            children: _presets.where((p) => p.value != 'custom').map((preset) {
              final isSelected = _preset == preset.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _applyPreset(preset.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    preset.label,
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _slope == '1/8' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '1/8"/ft',
                        style: TextStyle(
                          color: _slope == '1/8'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _slope == '1/4' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '1/4"/ft',
                        style: TextStyle(
                          color: _slope == '1/4'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildFixtureCard(ZaftoColors colors) {
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
            'FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildFixtureRow(colors, 'Toilets', _toilets, (v) => setState(() { _toilets = v; _preset = 'custom'; }), dfu: 3),
          _buildFixtureRow(colors, 'Lavatories', _lavatories, (v) => setState(() { _lavatories = v; _preset = 'custom'; }), dfu: 1),
          _buildFixtureRow(colors, 'Bathtubs', _bathtubs, (v) => setState(() { _bathtubs = v; _preset = 'custom'; }), dfu: 2),
          _buildFixtureRow(colors, 'Showers', _showers, (v) => setState(() { _showers = v; _preset = 'custom'; }), dfu: 2),
          _buildFixtureRow(colors, 'Kitchen Sinks', _kitchenSinks, (v) => setState(() { _kitchenSinks = v; _preset = 'custom'; }), dfu: 2),
          _buildFixtureRow(colors, 'Dishwashers', _dishwashers, (v) => setState(() { _dishwashers = v; _preset = 'custom'; }), dfu: 2),
          _buildFixtureRow(colors, 'Washing Machines', _washingMachines, (v) => setState(() { _washingMachines = v; _preset = 'custom'; }), dfu: 2),
          _buildFixtureRow(colors, 'Floor Drains', _floorDrains, (v) => setState(() { _floorDrains = v; _preset = 'custom'; }), dfu: 2),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int count, Function(int) onChanged, {required int dfu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  '$dfu DFU each',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count > 0) onChanged(count - 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.minus, color: colors.textSecondary, size: 18),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$count',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count < 10) onChanged(count + 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDfuBreakdown(ZaftoColors colors) {
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
            'DFU BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_toilets > 0) _buildDfuRow(colors, 'Toilets', _toilets, 3),
          if (_lavatories > 0) _buildDfuRow(colors, 'Lavatories', _lavatories, 1),
          if (_bathtubs > 0) _buildDfuRow(colors, 'Bathtubs', _bathtubs, 2),
          if (_showers > 0) _buildDfuRow(colors, 'Showers', _showers, 2),
          if (_kitchenSinks > 0) _buildDfuRow(colors, 'Kitchen Sinks', _kitchenSinks, 2),
          if (_dishwashers > 0) _buildDfuRow(colors, 'Dishwashers', _dishwashers, 2),
          if (_washingMachines > 0) _buildDfuRow(colors, 'Washing Machines', _washingMachines, 2),
          if (_floorDrains > 0) _buildDfuRow(colors, 'Floor Drains', _floorDrains, 2),
          Divider(color: colors.borderSubtle, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total DFU', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${_totalDfu.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDfuRow(ZaftoColors colors, String label, int count, int dfu) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label ($count × $dfu)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text('${count * dfu}', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
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
            '• Table 710.1(2) for horizontal branches\n'
            '• Min 3" for any branch serving WC\n'
            '• 1/4"/ft for pipes under 3"\n'
            '• 1/8" or 1/4"/ft for 3"+ pipe\n'
            '• Max 6 WCs per 3" horizontal branch\n'
            '• Consider combination waste/vent',
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
