import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Storm Drain Sizing Calculator - Design System v2.6
///
/// Sizes storm drains for roof drains and area drains.
/// Based on rainfall rate and drainage area.
///
/// References: IPC 2024 Chapter 11
class StormDrainScreen extends ConsumerStatefulWidget {
  const StormDrainScreen({super.key});
  @override
  ConsumerState<StormDrainScreen> createState() => _StormDrainScreenState();
}

class _StormDrainScreenState extends ConsumerState<StormDrainScreen> {
  // Drainage area (square feet)
  double _drainageArea = 2500;

  // Rainfall rate (inches per hour)
  double _rainfallRate = 4;

  // Drain type
  String _drainType = 'roof_drain';

  // Slope (horizontal drains)
  String _slope = 'quarter';

  static const Map<String, ({String desc, double factor})> _drainTypes = {
    'roof_drain': (desc: 'Roof Drain', factor: 1.0),
    'area_drain': (desc: 'Area Drain', factor: 1.0),
    'scupper': (desc: 'Scupper', factor: 0.85),
    'gutter': (desc: 'Gutter', factor: 0.9),
  };

  static const Map<String, ({String desc, double factor})> _slopes = {
    'eighth': (desc: '⅛" per ft', factor: 0.7),
    'quarter': (desc: '¼" per ft', factor: 1.0),
    'half': (desc: '½" per ft', factor: 1.4),
  };

  // IPC Table 1106.2 - Pipe sizes based on sq ft at 1" rainfall
  static final Map<String, List<int>> _pipeSizing = {
    '2': [544, 768, 987],
    '3': [1610, 2276, 2924],
    '4': [3460, 4892, 6284],
    '5': [6280, 8882, 11408],
    '6': [10200, 14424, 18528],
    '8': [22000, 31104, 39960],
  };

  double get _effectiveArea => _drainageArea * _rainfallRate;
  double get _slopeFactor => _slopes[_slope]?.factor ?? 1.0;
  double get _adjustedArea => _effectiveArea / _slopeFactor;

  String get _verticalPipeSize {
    // For vertical leaders, use first column
    if (_effectiveArea <= 544) return '2"';
    if (_effectiveArea <= 1610) return '3"';
    if (_effectiveArea <= 3460) return '4"';
    if (_effectiveArea <= 6280) return '5"';
    if (_effectiveArea <= 10200) return '6"';
    return '8"';
  }

  String get _horizontalPipeSize {
    // Column based on slope
    int col = _slope == 'eighth' ? 0 : (_slope == 'quarter' ? 1 : 2);

    for (var entry in _pipeSizing.entries) {
      if (_adjustedArea <= entry.value[col]) {
        return '${entry.key}"';
      }
    }
    return '8"+';
  }

  double get _flowRateGpm => (_drainageArea * _rainfallRate * 0.0104);

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
          'Storm Drain Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildDrainTypeCard(colors),
          const SizedBox(height: 16),
          _buildAreaCard(colors),
          const SizedBox(height: 16),
          _buildSlopeCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _verticalPipeSize,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '/',
                style: TextStyle(color: colors.textTertiary, fontSize: 32),
              ),
              const SizedBox(width: 16),
              Text(
                _horizontalPipeSize,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          Text(
            'Vertical / Horizontal',
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
                _buildResultRow(colors, 'Drainage Area', '${_drainageArea.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Rainfall Rate', '${_rainfallRate.toStringAsFixed(1)} in/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Effective Area', '${_effectiveArea.toStringAsFixed(0)} sq ft × in/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow Rate', '${_flowRateGpm.toStringAsFixed(1)} GPM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainTypeCard(ZaftoColors colors) {
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
            'DRAIN TYPE',
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
            children: _drainTypes.entries.map((entry) {
              final isSelected = _drainType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _drainType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
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

  Widget _buildAreaCard(ZaftoColors colors) {
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
            'DRAINAGE PARAMETERS',
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
              Text('Drainage Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_drainageArea.toStringAsFixed(0)} sq ft',
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
              value: _drainageArea,
              min: 500,
              max: 25000,
              divisions: 49,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _drainageArea = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rainfall Rate', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_rainfallRate.toStringAsFixed(1)} in/hr',
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
              value: _rainfallRate,
              min: 1,
              max: 10,
              divisions: 18,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _rainfallRate = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use 100-year, 1-hour rainfall rate for your area',
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
            'HORIZONTAL PIPE SLOPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._slopes.entries.map((entry) {
            final isSelected = _slope == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _slope = entry.key);
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'PIPE SIZING (at 1" rainfall)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader(colors, 'Size'),
                  _buildTableHeader(colors, 'Vert.'),
                  _buildTableHeader(colors, '¼"/ft'),
                  _buildTableHeader(colors, '½"/ft'),
                ],
              ),
              ..._pipeSizing.entries.map((entry) {
                return TableRow(
                  children: [
                    _buildTableCell(colors, '${entry.key}"'),
                    _buildTableCell(colors, '${entry.value[0]}'),
                    _buildTableCell(colors, '${entry.value[1]}'),
                    _buildTableCell(colors, '${entry.value[2]}'),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Values in sq ft at 1"/hr rainfall. Divide by actual rate.',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(color: colors.textPrimary, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.cloudRain, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Chapter 11',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Table 1106.2: Vertical leader sizing\n'
            '• Table 1106.3: Horizontal sizing\n'
            '• Secondary overflow required\n'
            '• Check local rainfall data\n'
            '• Combined systems per Table 1106.6\n'
            '• Include vertical wall area at 50%',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
