import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Flow Rate (GPM) Calculator - Design System v2.6
///
/// Calculates water flow rate based on pipe diameter and velocity.
/// Helps size pipes for required flow or verify capacity.
///
/// References: IPC Appendix E, Hydraulics principles
class FlowRateScreen extends ConsumerStatefulWidget {
  const FlowRateScreen({super.key});
  @override
  ConsumerState<FlowRateScreen> createState() => _FlowRateScreenState();
}

class _FlowRateScreenState extends ConsumerState<FlowRateScreen> {
  // Calculation mode
  String _mode = 'flow'; // 'flow' (calc GPM) or 'velocity' (calc velocity) or 'size' (calc pipe size)

  // Pipe diameter (inches)
  double _pipeDiameter = 0.75;

  // Velocity (fps)
  double _velocity = 5.0;

  // Flow rate (GPM) - for reverse calculation
  double _flowRate = 10.0;

  // Common pipe sizes
  static const List<double> _pipeSizes = [
    0.375, 0.5, 0.625, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0
  ];

  // Recommended velocities by application
  static const Map<String, ({double min, double max, String note})> _velocityGuidelines = {
    'Residential Supply': (min: 4.0, max: 8.0, note: 'Typical home water lines'),
    'Commercial Supply': (min: 4.0, max: 10.0, note: 'Office, retail'),
    'Hot Water Recirc': (min: 2.0, max: 4.0, note: 'Prevents erosion'),
    'Fire Protection': (min: 10.0, max: 20.0, note: 'NFPA requirements'),
    'Chilled Water': (min: 4.0, max: 8.0, note: 'HVAC systems'),
    'Suction Line': (min: 2.0, max: 4.0, note: 'Pump inlet'),
    'Discharge Line': (min: 4.0, max: 10.0, note: 'Pump outlet'),
  };

  // Cross-sectional area in sq inches
  double get _crossSectionArea {
    return 3.14159 * (_pipeDiameter / 2) * (_pipeDiameter / 2);
  }

  // Flow rate calculation: Q = A * V (converted to GPM)
  // Q (GPM) = Area (sq in) * Velocity (fps) * 60 / 231
  // 231 cubic inches = 1 gallon
  double get _calculatedFlowRate {
    return _crossSectionArea * _velocity * 60 / 231;
  }

  // Velocity from flow rate: V = Q * 231 / (A * 60)
  double get _calculatedVelocity {
    if (_crossSectionArea <= 0) return 0;
    return _flowRate * 231 / (_crossSectionArea * 60);
  }

  // Pipe size needed for given flow at given velocity
  double get _calculatedPipeSize {
    // Area = Q * 231 / (V * 60)
    // D = 2 * sqrt(A / pi)
    if (_velocity <= 0) return 0;
    final area = _flowRate * 231 / (_velocity * 60);
    return 2 * _sqrt(area / 3.14159);
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  String get _recommendedPipeSize {
    final needed = _calculatedPipeSize;
    for (final size in _pipeSizes) {
      if (size >= needed) {
        return _formatPipeSize(size);
      }
    }
    return '6" or larger';
  }

  String _formatPipeSize(double size) {
    if (size == 0.375) return '3/8"';
    if (size == 0.5) return '1/2"';
    if (size == 0.625) return '5/8"';
    if (size == 0.75) return '3/4"';
    if (size == 1.25) return '1-1/4"';
    if (size == 1.5) return '1-1/2"';
    if (size == 2.5) return '2-1/2"';
    return '${size.toInt()}"';
  }

  String get _velocityAssessment {
    if (_mode == 'flow') {
      if (_velocity < 2) return 'LOW - May cause sediment buildup';
      if (_velocity > 10) return 'HIGH - Risk of water hammer, noise';
      if (_velocity > 8) return 'MODERATE - Acceptable but noisy';
      return 'OPTIMAL - Good for most applications';
    } else {
      final v = _calculatedVelocity;
      if (v < 2) return 'LOW - May cause sediment buildup';
      if (v > 10) return 'HIGH - Risk of water hammer, noise';
      if (v > 8) return 'MODERATE - Acceptable but noisy';
      return 'OPTIMAL - Good for most applications';
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
          'Flow Rate Calculator',
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
          if (_mode != 'size') _buildPipeSizeCard(colors),
          if (_mode != 'size') const SizedBox(height: 16),
          if (_mode == 'flow' || _mode == 'size') _buildVelocityCard(colors),
          if (_mode == 'flow' || _mode == 'size') const SizedBox(height: 16),
          if (_mode == 'velocity' || _mode == 'size') _buildFlowRateCard(colors),
          if (_mode == 'velocity' || _mode == 'size') const SizedBox(height: 16),
          _buildVelocityGuide(colors),
          const SizedBox(height: 16),
          _buildFlowTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
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
            'CALCULATE',
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
            children: [
              _buildModeChip(colors, 'flow', 'Flow Rate (GPM)'),
              _buildModeChip(colors, 'velocity', 'Velocity (FPS)'),
              _buildModeChip(colors, 'size', 'Pipe Size'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(ZaftoColors colors, String value, String label) {
    final isSelected = _mode == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _mode = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String resultValue;
    String resultLabel;
    String resultUnit;

    switch (_mode) {
      case 'flow':
        resultValue = _calculatedFlowRate.toStringAsFixed(1);
        resultLabel = 'Flow Rate';
        resultUnit = 'GPM';
        break;
      case 'velocity':
        resultValue = _calculatedVelocity.toStringAsFixed(1);
        resultLabel = 'Velocity';
        resultUnit = 'FPS';
        break;
      case 'size':
        resultValue = _calculatedPipeSize.toStringAsFixed(2);
        resultLabel = 'Minimum Pipe ID';
        resultUnit = 'inches';
        break;
      default:
        resultValue = '0';
        resultLabel = '';
        resultUnit = '';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resultValue,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' $resultUnit',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            resultLabel,
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_mode == 'size') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Use $_recommendedPipeSize pipe',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (_mode == 'flow') ...[
                  _buildResultRow(colors, 'Pipe Diameter', _formatPipeSize(_pipeDiameter)),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Velocity', '${_velocity.toStringAsFixed(1)} fps'),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Cross Section', '${_crossSectionArea.toStringAsFixed(3)} sq in'),
                ] else if (_mode == 'velocity') ...[
                  _buildResultRow(colors, 'Pipe Diameter', _formatPipeSize(_pipeDiameter)),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Flow Rate', '${_flowRate.toStringAsFixed(1)} GPM'),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Cross Section', '${_crossSectionArea.toStringAsFixed(3)} sq in'),
                ] else ...[
                  _buildResultRow(colors, 'Required Flow', '${_flowRate.toStringAsFixed(1)} GPM'),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Design Velocity', '${_velocity.toStringAsFixed(1)} fps'),
                ],
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Assessment', _velocityAssessment, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizeCard(ZaftoColors colors) {
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
            children: _pipeSizes.map((size) {
              final isSelected = _pipeDiameter == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeDiameter = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatPipeSize(size),
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

  Widget _buildVelocityCard(ZaftoColors colors) {
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
            'VELOCITY (FPS)',
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
                '${_velocity.toStringAsFixed(1)} fps',
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
                    value: _velocity,
                    min: 1,
                    max: 20,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _velocity = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Typical: 4-8 fps residential, 4-10 fps commercial',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRateCard(ZaftoColors colors) {
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
            'FLOW RATE (GPM)',
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
                '${_flowRate.toStringAsFixed(1)} GPM',
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
                    value: _flowRate,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Required flow in gallons per minute',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityGuide(ZaftoColors colors) {
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
            'VELOCITY GUIDELINES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._velocityGuidelines.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.key,
                      style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${entry.value.min.toInt()}-${entry.value.max.toInt()} fps',
                      style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildFlowTable(ZaftoColors colors) {
    // Flow rates at 5 fps for common pipe sizes
    final flowData = <double, double>{};
    for (final size in _pipeSizes) {
      final area = 3.14159 * (size / 2) * (size / 2);
      flowData[size] = area * 5 * 60 / 231;
    }

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
            'FLOW CAPACITY @ 5 FPS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...flowData.entries.map((entry) {
            final isSelected = _pipeDiameter == entry.key;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatPipeSize(entry.key),
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)} GPM',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
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
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? colors.accentPrimary : colors.textPrimary,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
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
                'IPC 2024 Appendix E',
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
            '• Formula: Q = A \u00d7 V \u00d7 60/231\n'
            '• Q = flow rate (GPM)\n'
            '• A = cross section area (sq in)\n'
            '• V = velocity (feet/second)\n'
            '• Max velocity: 8 fps residential\n'
            '• Min velocity: 2 fps (sediment)',
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
