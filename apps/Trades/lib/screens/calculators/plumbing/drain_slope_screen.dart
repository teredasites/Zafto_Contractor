import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drain Slope Calculator - Design System v2.6
///
/// Calculates required drop for horizontal drain runs per IPC 2024.
/// Helps plumbers verify slope and calculate total drop.
///
/// References: IPC 704.1, IPC Table 704.1
class DrainSlopeScreen extends ConsumerStatefulWidget {
  const DrainSlopeScreen({super.key});
  @override
  ConsumerState<DrainSlopeScreen> createState() => _DrainSlopeScreenState();
}

class _DrainSlopeScreenState extends ConsumerState<DrainSlopeScreen> {
  // Pipe diameter
  String _pipeDiameter = '2'; // inches

  // Run length
  double _runLength = 10; // feet

  // Calculation mode
  String _mode = 'drop'; // 'drop' or 'verify'

  // For verification mode
  double _actualDrop = 2.5; // inches

  // Pipe diameters and required slopes per IPC Table 704.1
  static const Map<String, ({String slope, double inchesPerFoot, String note})> _slopeRequirements = {
    '1-1/4': (slope: '1/4"', inchesPerFoot: 0.25, note: 'Rarely used for drains'),
    '1-1/2': (slope: '1/4"', inchesPerFoot: 0.25, note: 'Lavatory, small fixtures'),
    '2': (slope: '1/4"', inchesPerFoot: 0.25, note: 'Standard branch'),
    '2-1/2': (slope: '1/4"', inchesPerFoot: 0.25, note: 'Transition size'),
    '3': (slope: '1/8"', inchesPerFoot: 0.125, note: '1/8" or 1/4" per IPC'),
    '4': (slope: '1/8"', inchesPerFoot: 0.125, note: 'Building drain'),
    '5': (slope: '1/8"', inchesPerFoot: 0.125, note: 'Commercial'),
    '6': (slope: '1/8"', inchesPerFoot: 0.125, note: 'Building sewer'),
    '8': (slope: '1/8"', inchesPerFoot: 0.125, note: 'Main sewer'),
  };

  // Slope options for user selection (for 3"+ pipe)
  static const List<({String label, double value})> _slopeOptions = [
    (label: '1/8" per foot', value: 0.125),
    (label: '1/4" per foot', value: 0.25),
    (label: '1/2" per foot', value: 0.5),
    (label: '1" per foot', value: 1.0),
  ];

  // Selected slope (for 3"+ pipe where user can choose)
  double _selectedSlope = 0.125;

  double get _requiredSlope {
    final req = _slopeRequirements[_pipeDiameter];
    if (req == null) return 0.25;
    // For 3" and larger, use selected slope
    if (double.tryParse(_pipeDiameter) != null && double.parse(_pipeDiameter) >= 3) {
      return _selectedSlope;
    }
    return req.inchesPerFoot;
  }

  double get _minimumSlope {
    final req = _slopeRequirements[_pipeDiameter];
    return req?.inchesPerFoot ?? 0.25;
  }

  double get _totalDropInches {
    return _runLength * _requiredSlope;
  }

  double get _totalDropFeet {
    return _totalDropInches / 12;
  }

  String get _slopePercentage {
    return '${(_requiredSlope / 12 * 100).toStringAsFixed(2)}%';
  }

  double get _slopeDegrees {
    // arctan(rise/run) in degrees
    return ((_requiredSlope / 12) * 57.2958); // 180/pi
  }

  // Verification mode calculations
  double get _actualSlopePerFoot {
    if (_runLength <= 0) return 0;
    return _actualDrop / _runLength;
  }

  bool get _slopeMeetsCode {
    return _actualSlopePerFoot >= _minimumSlope;
  }

  String get _verificationStatus {
    if (_actualSlopePerFoot < _minimumSlope * 0.9) {
      return 'TOO FLAT - Increase slope';
    } else if (_actualSlopePerFoot < _minimumSlope) {
      return 'MARGINAL - Slightly below minimum';
    } else if (_actualSlopePerFoot > 0.5) {
      return 'STEEP - Risk of liquid separation';
    } else {
      return 'OK - Meets code requirements';
    }
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
          'Drain Slope Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeSelector(colors),
          const SizedBox(height: 16),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildPipeDiameterCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          if (_mode == 'drop' && _canSelectSlope) ...[
            const SizedBox(height: 16),
            _buildSlopeSelector(colors),
          ],
          if (_mode == 'verify') ...[
            const SizedBox(height: 16),
            _buildActualDropCard(colors),
          ],
          const SizedBox(height: 16),
          _buildSlopeTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool get _canSelectSlope {
    final diameter = double.tryParse(_pipeDiameter) ?? 0;
    return diameter >= 3;
  }

  Widget _buildModeSelector(ZaftoColors colors) {
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
            'CALCULATION MODE',
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
              Expanded(child: _buildModeChip(colors, 'drop', 'Calculate Drop', 'How much drop for this run?')),
              const SizedBox(width: 12),
              Expanded(child: _buildModeChip(colors, 'verify', 'Verify Slope', 'Is my slope correct?')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _mode == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _mode = value);
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
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 14,
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

  Widget _buildResultsCard(ZaftoColors colors) {
    if (_mode == 'verify') {
      return _buildVerifyResultsCard(colors);
    }

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
            _formatDropInches(_totalDropInches),
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Drop Required',
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
                _buildResultRow(colors, 'Pipe Diameter', '$_pipeDiameter"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Run Length', '${_runLength.toStringAsFixed(1)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Slope', '${_slopeRequirements[_pipeDiameter]?.slope ?? "1/4\""}/ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Drop (Feet)', '${_totalDropFeet.toStringAsFixed(3)} ft', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Slope %', _slopePercentage),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Slope Degrees', '${_slopeDegrees.toStringAsFixed(2)}\u00B0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyResultsCard(ZaftoColors colors) {
    final meetsCode = _slopeMeetsCode;
    final statusColor = meetsCode ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            meetsCode ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
            color: statusColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _verificationStatus,
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
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
                _buildResultRow(colors, 'Actual Slope', '${_actualSlopePerFoot.toStringAsFixed(3)}"/ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Required Min', '${_minimumSlope.toString()}"/ft', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Difference', '${(_actualSlopePerFoot - _minimumSlope).toStringAsFixed(3)}"/ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Your Drop', '${_actualDrop.toStringAsFixed(2)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Drop Needed', '${(_runLength * _minimumSlope).toStringAsFixed(2)}"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDropInches(double inches) {
    if (inches < 1) {
      return '${(inches * 16).round()}/16"';
    } else if (inches < 12) {
      final whole = inches.floor();
      final fraction = inches - whole;
      if (fraction < 0.0625) return '$whole"';
      return '$whole ${(fraction * 16).round()}/16"';
    } else {
      return '${(inches / 12).toStringAsFixed(2)} ft';
    }
  }

  Widget _buildPipeDiameterCard(ZaftoColors colors) {
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
            'PIPE DIAMETER',
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
            children: _slopeRequirements.keys.map((size) {
              final isSelected = _pipeDiameter == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeDiameter = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size"',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
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
                '${_runLength.toStringAsFixed(1)} ft',
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
                    min: 1,
                    max: 100,
                    divisions: 99,
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
            'Horizontal distance of drain run',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
            'SLOPE (3"+ PIPE)',
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
            children: _slopeOptions.map((option) {
              final isSelected = _selectedSlope == option.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSlope = option.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.label,
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
          const SizedBox(height: 8),
          Text(
            'IPC allows 1/8" minimum for 3"+ pipe',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActualDropCard(ZaftoColors colors) {
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
            'ACTUAL DROP (MEASURED)',
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
                '${_actualDrop.toStringAsFixed(2)}"',
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
                    value: _actualDrop,
                    min: 0,
                    max: 24,
                    divisions: 96,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _actualDrop = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total drop from start to end of run',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeTable(ZaftoColors colors) {
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
            'IPC TABLE 704.1 - SLOPE REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._slopeRequirements.entries.map((entry) {
            final isSelected = _pipeDiameter == entry.key;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${entry.key}"',
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${entry.value.slope}/ft',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.note,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
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
                'IPC 2024 Section 704',
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
            '• 704.1 - Min slope: 1/4"/ft for pipes < 3"\n'
            '• 704.1 - Min slope: 1/8"/ft for pipes 3"+\n'
            '• Steeper slope (1/4") recommended for solids\n'
            '• Avoid excessive slope (>1/2"/ft)\n'
            '• UPC has similar requirements\n'
            '• Verify with local AHJ',
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
