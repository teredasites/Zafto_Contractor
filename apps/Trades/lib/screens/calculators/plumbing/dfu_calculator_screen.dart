import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drainage Fixture Unit (DFU) Calculator - Design System v2.6
///
/// Calculates total DFU load and determines minimum pipe sizes per IPC 2024.
/// Covers: horizontal branches, building drains, stacks.
///
/// References: IPC Table 710.1(2), IPC Table 710.1(1), IPC 710.1
class DfuCalculatorScreen extends ConsumerStatefulWidget {
  const DfuCalculatorScreen({super.key});
  @override
  ConsumerState<DfuCalculatorScreen> createState() => _DfuCalculatorScreenState();
}

class _DfuCalculatorScreenState extends ConsumerState<DfuCalculatorScreen> {
  // Fixture counts - residential
  int _waterClosetTank = 0;
  int _waterClosetFlush = 0;
  int _lavatory = 0;
  int _bathtub = 0;
  int _shower = 0;
  int _kitchenSink = 0;
  int _dishwasher = 0;
  int _clothesWasher = 0;
  int _laundryTub = 0;
  int _floorDrain = 0;

  // Fixture counts - commercial/specialty
  int _urinalFlush = 0;
  int _urinalTank = 0;
  int _utilitySink = 0;
  int _barSink = 0;
  int _bidet = 0;
  int _drinkingFountain = 0;
  int _hoseBibb = 0;
  int _mopSink = 0;

  // Display mode
  bool _showCommercial = false;

  // Drain slope selection
  String _drainSlope = '1/4"'; // 1/8" or 1/4" per foot

  // DFU values per IPC 2024 Table 709.1
  static const Map<String, double> _dfuValues = {
    'waterClosetTank': 3.0,      // Tank type (residential)
    'waterClosetFlush': 4.0,    // Flushometer (commercial)
    'lavatory': 1.0,
    'bathtub': 2.0,             // With or without shower
    'shower': 2.0,              // Stall
    'kitchenSink': 2.0,         // Domestic with or without disposal
    'dishwasher': 2.0,          // Domestic
    'clothesWasher': 2.0,       // 2" standpipe
    'laundryTub': 2.0,
    'floorDrain': 2.0,          // 2" drain
    'urinalFlush': 4.0,         // Flushometer
    'urinalTank': 2.0,          // Tank type
    'utilitySink': 2.0,
    'barSink': 1.0,
    'bidet': 1.0,
    'drinkingFountain': 0.5,
    'hoseBibb': 0.5,            // Each
    'mopSink': 3.0,             // Service sink
  };

  // Minimum trap sizes (inches) per fixture
  static const Map<String, String> _trapSizes = {
    'waterClosetTank': '3" (integral)',
    'waterClosetFlush': '3" (integral)',
    'lavatory': '1-1/4"',
    'bathtub': '1-1/2"',
    'shower': '2"',
    'kitchenSink': '1-1/2"',
    'dishwasher': '1-1/2" (via sink)',
    'clothesWasher': '2"',
    'laundryTub': '1-1/2"',
    'floorDrain': '2"',
    'urinalFlush': '2" (integral)',
    'urinalTank': '2" (integral)',
    'utilitySink': '1-1/2"',
    'barSink': '1-1/4"',
    'bidet': '1-1/4"',
    'drinkingFountain': '1-1/4"',
    'hoseBibb': 'N/A',
    'mopSink': '3"',
  };

  // Horizontal branch sizing (IPC Table 710.1(2))
  // Max DFU for given pipe size - using List of records for proper lookup
  static final List<({double size, int maxDfu})> _horizontalBranchDfu = [
    (size: 1.5, maxDfu: 3),    // 1-1/2"
    (size: 2.0, maxDfu: 6),    // 2"
    (size: 2.5, maxDfu: 12),   // 2-1/2"
    (size: 3.0, maxDfu: 20),   // 3"
    (size: 4.0, maxDfu: 160),  // 4"
    (size: 5.0, maxDfu: 360),  // 5"
    (size: 6.0, maxDfu: 620),  // 6"
    (size: 8.0, maxDfu: 1400), // 8"
  ];

  // Building drain sizing (IPC Table 710.1(1))
  static final List<({double size, int eighth, int quarter})> _buildingDrainDfu = [
    (size: 2.0, eighth: 0, quarter: 21),
    (size: 2.5, eighth: 0, quarter: 24),
    (size: 3.0, eighth: 36, quarter: 42),
    (size: 4.0, eighth: 180, quarter: 216),
    (size: 5.0, eighth: 390, quarter: 480),
    (size: 6.0, eighth: 700, quarter: 840),
    (size: 8.0, eighth: 1600, quarter: 1920),
    (size: 10.0, eighth: 2900, quarter: 3500),
    (size: 12.0, eighth: 4600, quarter: 5600),
  ];

  // Stack sizing (IPC Table 710.1(2))
  static final List<({double size, int maxDfu})> _stackTotalDfu = [
    (size: 1.5, maxDfu: 4),
    (size: 2.0, maxDfu: 10),
    (size: 2.5, maxDfu: 20),
    (size: 3.0, maxDfu: 48),
    (size: 4.0, maxDfu: 240),
    (size: 5.0, maxDfu: 540),
    (size: 6.0, maxDfu: 960),
    (size: 8.0, maxDfu: 2200),
    (size: 10.0, maxDfu: 3800),
    (size: 12.0, maxDfu: 6000),
  ];

  double get _totalDfu {
    double total = 0;
    total += _waterClosetTank * _dfuValues['waterClosetTank']!;
    total += _waterClosetFlush * _dfuValues['waterClosetFlush']!;
    total += _lavatory * _dfuValues['lavatory']!;
    total += _bathtub * _dfuValues['bathtub']!;
    total += _shower * _dfuValues['shower']!;
    total += _kitchenSink * _dfuValues['kitchenSink']!;
    total += _dishwasher * _dfuValues['dishwasher']!;
    total += _clothesWasher * _dfuValues['clothesWasher']!;
    total += _laundryTub * _dfuValues['laundryTub']!;
    total += _floorDrain * _dfuValues['floorDrain']!;
    total += _urinalFlush * _dfuValues['urinalFlush']!;
    total += _urinalTank * _dfuValues['urinalTank']!;
    total += _utilitySink * _dfuValues['utilitySink']!;
    total += _barSink * _dfuValues['barSink']!;
    total += _bidet * _dfuValues['bidet']!;
    total += _drinkingFountain * _dfuValues['drinkingFountain']!;
    total += _hoseBibb * _dfuValues['hoseBibb']!;
    total += _mopSink * _dfuValues['mopSink']!;
    return total;
  }

  int get _fixtureCount {
    return _waterClosetTank + _waterClosetFlush + _lavatory + _bathtub +
           _shower + _kitchenSink + _dishwasher + _clothesWasher +
           _laundryTub + _floorDrain + _urinalFlush + _urinalTank +
           _utilitySink + _barSink + _bidet + _drinkingFountain +
           _hoseBibb + _mopSink;
  }

  String get _minHorizontalBranch {
    final dfu = _totalDfu;
    if (dfu <= 0) return '--';
    for (final entry in _horizontalBranchDfu) {
      if (dfu <= entry.maxDfu) {
        return _formatPipeSize(entry.size);
      }
    }
    return '8"+';
  }

  String get _minBuildingDrain {
    final dfu = _totalDfu;
    if (dfu <= 0) return '--';
    for (final entry in _buildingDrainDfu) {
      final maxDfu = _drainSlope == '1/8"' ? entry.eighth : entry.quarter;
      if (dfu <= maxDfu && maxDfu > 0) {
        return _formatPipeSize(entry.size);
      }
    }
    return '12"+';
  }

  String get _minStack {
    final dfu = _totalDfu;
    if (dfu <= 0) return '--';
    for (final entry in _stackTotalDfu) {
      if (dfu <= entry.maxDfu) {
        return _formatPipeSize(entry.size);
      }
    }
    return '12"+';
  }

  String _formatPipeSize(double size) {
    if (size == 1.5) return '1-1/2"';
    if (size == 2.5) return '2-1/2"';
    return '${size.toInt()}"';
  }

  bool get _hasWaterCloset => _waterClosetTank > 0 || _waterClosetFlush > 0;

  String get _minBuildingDrainNote {
    if (_hasWaterCloset && _totalDfu <= 20) {
      return 'Note: 3" min required when connected to water closet';
    }
    return '';
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
          'DFU Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCommercial ? LucideIcons.building2 : LucideIcons.home,
              color: colors.accentPrimary,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showCommercial = !_showCommercial);
            },
            tooltip: _showCommercial ? 'Show Residential' : 'Show Commercial',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildSlopeSelector(colors),
          const SizedBox(height: 16),
          _buildResidentialFixtures(colors),
          if (_showCommercial) ...[
            const SizedBox(height: 16),
            _buildCommercialFixtures(colors),
          ],
          const SizedBox(height: 16),
          _buildPipeSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: _fixtureCount > 0
          ? FloatingActionButton.extended(
              onPressed: _resetAll,
              backgroundColor: colors.bgElevated,
              icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary, size: 18),
              label: Text('Reset', style: TextStyle(color: colors.textSecondary)),
            )
          : null,
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
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
            _totalDfu.toStringAsFixed(_totalDfu == _totalDfu.truncate() ? 0 : 1),
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Drainage Fixture Units',
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
                _buildResultRow(colors, 'Fixtures', '$_fixtureCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Horizontal Branch', _minHorizontalBranch, highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Building Drain ($_drainSlope/ft)', _minBuildingDrain, highlight: true),
                if (_minBuildingDrainNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _minBuildingDrainNote,
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ],
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Min Stack Size', _minStack),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeSelector(ZaftoColors colors) {
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
            'BUILDING DRAIN SLOPE',
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
              Expanded(child: _buildSlopeChip(colors, '1/8"', '1/8" per foot (min for 3"+)')),
              const SizedBox(width: 12),
              Expanded(child: _buildSlopeChip(colors, '1/4"', '1/4" per foot (standard)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeChip(ZaftoColors colors, String slope, String desc) {
    final isSelected = _drainSlope == slope;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _drainSlope = slope);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              slope,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentialFixtures(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.home, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'RESIDENTIAL FIXTURES',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFixtureRow(colors, 'Water Closet (Tank)', 3.0, _waterClosetTank, (v) => setState(() => _waterClosetTank = v), '3" trap'),
          _buildFixtureRow(colors, 'Lavatory', 1.0, _lavatory, (v) => setState(() => _lavatory = v), '1-1/4" trap'),
          _buildFixtureRow(colors, 'Bathtub', 2.0, _bathtub, (v) => setState(() => _bathtub = v), '1-1/2" trap'),
          _buildFixtureRow(colors, 'Shower', 2.0, _shower, (v) => setState(() => _shower = v), '2" trap'),
          _buildFixtureRow(colors, 'Kitchen Sink', 2.0, _kitchenSink, (v) => setState(() => _kitchenSink = v), '1-1/2" trap'),
          _buildFixtureRow(colors, 'Dishwasher', 2.0, _dishwasher, (v) => setState(() => _dishwasher = v), 'via sink'),
          _buildFixtureRow(colors, 'Clothes Washer', 2.0, _clothesWasher, (v) => setState(() => _clothesWasher = v), '2" standpipe'),
          _buildFixtureRow(colors, 'Laundry Tub', 2.0, _laundryTub, (v) => setState(() => _laundryTub = v), '1-1/2" trap'),
          _buildFixtureRow(colors, 'Floor Drain', 2.0, _floorDrain, (v) => setState(() => _floorDrain = v), '2" trap'),
        ],
      ),
    );
  }

  Widget _buildCommercialFixtures(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building2, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'COMMERCIAL / SPECIALTY',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFixtureRow(colors, 'Water Closet (Flushometer)', 4.0, _waterClosetFlush, (v) => setState(() => _waterClosetFlush = v), '3" trap'),
          _buildFixtureRow(colors, 'Urinal (Flushometer)', 4.0, _urinalFlush, (v) => setState(() => _urinalFlush = v), '2" trap'),
          _buildFixtureRow(colors, 'Urinal (Tank)', 2.0, _urinalTank, (v) => setState(() => _urinalTank = v), '2" trap'),
          _buildFixtureRow(colors, 'Mop/Service Sink', 3.0, _mopSink, (v) => setState(() => _mopSink = v), '3" trap'),
          _buildFixtureRow(colors, 'Utility Sink', 2.0, _utilitySink, (v) => setState(() => _utilitySink = v), '1-1/2" trap'),
          _buildFixtureRow(colors, 'Bar Sink', 1.0, _barSink, (v) => setState(() => _barSink = v), '1-1/4" trap'),
          _buildFixtureRow(colors, 'Bidet', 1.0, _bidet, (v) => setState(() => _bidet = v), '1-1/4" trap'),
          _buildFixtureRow(colors, 'Drinking Fountain', 0.5, _drinkingFountain, (v) => setState(() => _drinkingFountain = v), '1-1/4" trap'),
          _buildFixtureRow(colors, 'Hose Bibb', 0.5, _hoseBibb, (v) => setState(() => _hoseBibb = v), '--'),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String name, double dfu, int count, void Function(int) onChanged, String trapNote) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${dfu.toStringAsFixed(dfu == dfu.truncate() ? 0 : 1)} DFU  •  $trapNote',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: count > 0
                      ? () {
                          HapticFeedback.selectionClick();
                          onChanged(count - 1);
                        }
                      : null,
                  icon: Icon(
                    LucideIcons.minus,
                    color: count > 0 ? colors.textSecondary : colors.textQuaternary,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: count > 0 ? colors.accentPrimary : colors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onChanged(count + 1);
                  },
                  icon: Icon(LucideIcons.plus, color: colors.accentPrimary, size: 18),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizingTable(ZaftoColors colors) {
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
            'IPC TABLE 710.1(2) - HORIZONTAL BRANCHES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum DFU per pipe size',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _horizontalBranchDfu.map((entry) {
              // Highlight the first pipe size that can handle current DFU
              final isHighlighted = _totalDfu > 0 && _totalDfu <= entry.maxDfu &&
                  (_horizontalBranchDfu.where((e) => e.size < entry.size && _totalDfu <= e.maxDfu).isEmpty);
              return Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(6),
                  border: isHighlighted ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _formatPipeSize(entry.size),
                      style: TextStyle(
                        color: isHighlighted ? colors.accentPrimary : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.maxDfu} DFU',
                      style: TextStyle(
                        color: isHighlighted ? colors.accentPrimary : colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
                'IPC 2024 Chapter 7',
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
            '• Table 709.1 - Fixture unit values\n'
            '• Table 710.1(1) - Building drains/sewers\n'
            '• Table 710.1(2) - Horizontal branches/stacks\n'
            '• 710.1 - Min 1/4" slope <3", 1/8" for 3"+\n'
            '• 704.1 - Fixture trap required for each fixture\n'
            '• UPC uses similar values (check local adoption)',
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

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _waterClosetTank = 0;
      _waterClosetFlush = 0;
      _lavatory = 0;
      _bathtub = 0;
      _shower = 0;
      _kitchenSink = 0;
      _dishwasher = 0;
      _clothesWasher = 0;
      _laundryTub = 0;
      _floorDrain = 0;
      _urinalFlush = 0;
      _urinalTank = 0;
      _utilitySink = 0;
      _barSink = 0;
      _bidet = 0;
      _drinkingFountain = 0;
      _hoseBibb = 0;
      _mopSink = 0;
    });
  }
}
