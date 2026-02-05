import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Insulation Calculator - Design System v2.6
///
/// Calculates insulation thickness and R-value needs.
/// Helps meet energy code requirements.
///
/// References: IECC 2024, ASHRAE 90.1
class PipeInsulationScreen extends ConsumerStatefulWidget {
  const PipeInsulationScreen({super.key});
  @override
  ConsumerState<PipeInsulationScreen> createState() => _PipeInsulationScreenState();
}

class _PipeInsulationScreenState extends ConsumerState<PipeInsulationScreen> {
  // Pipe diameter
  String _pipeDiameter = '3/4';

  // Pipe type
  String _pipeType = 'hot'; // 'hot' or 'cold'

  // Fluid temperature
  double _fluidTemp = 140;

  // Ambient temperature
  double _ambientTemp = 70;

  // Insulation type
  String _insulationType = 'fiberglass';

  // Location
  String _location = 'conditioned';

  // Pipe sizes
  static const List<String> _pipeSizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2', '2-1/2', '3', '4'];

  // Insulation types with k-values
  static const Map<String, ({double kValue, String name})> _insulationTypes = {
    'fiberglass': (kValue: 0.25, name: 'Fiberglass'),
    'foam': (kValue: 0.28, name: 'Foam Rubber'),
    'mineral': (kValue: 0.24, name: 'Mineral Wool'),
    'polyiso': (kValue: 0.18, name: 'Polyisocyanurate'),
  };

  // IECC minimum insulation by pipe size (hot water)
  static const Map<String, double> _minInsulationHot = {
    '1/2': 0.5,
    '3/4': 0.5,
    '1': 1.0,
    '1-1/4': 1.0,
    '1-1/2': 1.0,
    '2': 1.5,
    '2-1/2': 1.5,
    '3': 1.5,
    '4': 1.5,
  };

  double get _tempDifference => (_fluidTemp - _ambientTemp).abs();

  double get _minimumThickness {
    if (_pipeType == 'cold') {
      // Cold pipes need less insulation but must prevent condensation
      return 0.5;
    }
    return _minInsulationHot[_pipeDiameter] ?? 1.0;
  }

  String get _recommendedThickness {
    final minThick = _minimumThickness;
    if (_location == 'unconditioned') {
      return '${(minThick * 1.5).toStringAsFixed(1)}"';
    }
    return '$minThick"';
  }

  double get _rValue {
    final thickness = _minimumThickness;
    final kValue = _insulationTypes[_insulationType]?.kValue ?? 0.25;
    return thickness / kValue;
  }

  double get _heatLossPerFoot {
    // Simplified heat loss: Q = 2πkL(T1-T2)/ln(r2/r1)
    // Approximation for typical conditions
    final pipeDia = _parsePipeDiameter(_pipeDiameter);
    final insulationThick = _minimumThickness;
    final kValue = _insulationTypes[_insulationType]?.kValue ?? 0.25;

    if (insulationThick <= 0) return _tempDifference * 0.5; // Uninsulated

    return (_tempDifference * kValue * 3.14 * 2) /
           ((_logApprox((pipeDia + 2 * insulationThick) / pipeDia)));
  }

  double _parsePipeDiameter(String size) {
    switch (size) {
      case '1/2': return 0.5;
      case '3/4': return 0.75;
      case '1-1/4': return 1.25;
      case '1-1/2': return 1.5;
      case '2-1/2': return 2.5;
      default: return double.tryParse(size) ?? 1.0;
    }
  }

  double _logApprox(double x) {
    if (x <= 0) return 0;
    // Natural log approximation
    double result = 0;
    double term = (x - 1) / (x + 1);
    double power = term;
    for (int i = 1; i <= 10; i += 2) {
      result += power / i;
      power *= term * term;
    }
    return 2 * result;
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
          'Pipe Insulation',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPipeTypeCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildInsulationTypeCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
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
          Text(
            _recommendedThickness,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Insulation Thickness',
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
                _buildResultRow(colors, 'Pipe Size', '$_pipeDiameter"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Type', _pipeType == 'hot' ? 'Hot Water' : 'Cold Water'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Temp Diff', '${_tempDifference.toStringAsFixed(0)}°F'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'R-Value', 'R-${_rValue.toStringAsFixed(1)}', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Heat Loss', '${_heatLossPerFoot.toStringAsFixed(1)} BTU/hr/ft'),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _pipeType = 'hot';
                      _fluidTemp = 140;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _pipeType == 'hot' ? Colors.red : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.flame, color: _pipeType == 'hot' ? Colors.white : Colors.red, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Hot Water',
                          style: TextStyle(
                            color: _pipeType == 'hot' ? Colors.white : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
                    setState(() {
                      _pipeType = 'cold';
                      _fluidTemp = 55;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _pipeType == 'cold' ? Colors.blue : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.snowflake, color: _pipeType == 'cold' ? Colors.white : Colors.blue, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Cold Water',
                          style: TextStyle(
                            color: _pipeType == 'cold' ? Colors.white : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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

  Widget _buildTemperatureCard(ZaftoColors colors) {
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
            'TEMPERATURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildTempRow(colors, 'Fluid Temp', _fluidTemp, (v) => setState(() => _fluidTemp = v),
              min: _pipeType == 'hot' ? 100 : 40, max: _pipeType == 'hot' ? 180 : 70,
              color: _pipeType == 'hot' ? Colors.red : Colors.blue),
          const SizedBox(height: 12),
          _buildTempRow(colors, 'Ambient', _ambientTemp, (v) => setState(() => _ambientTemp = v),
              min: 40, max: 100, color: colors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildTempRow(ZaftoColors colors, String label, double value, Function(double) onChanged,
      {required double min, required double max, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text('${value.toStringAsFixed(0)}°F', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: colors.bgBase,
            thumbColor: color,
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInsulationTypeCard(ZaftoColors colors) {
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
            'INSULATION TYPE',
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
            children: _insulationTypes.entries.map((entry) {
              final isSelected = _insulationType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _insulationType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.name,
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

  Widget _buildLocationCard(ZaftoColors colors) {
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
            'PIPE LOCATION',
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
                    setState(() => _location = 'conditioned');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _location == 'conditioned' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Conditioned',
                        style: TextStyle(
                          color: _location == 'conditioned'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                    setState(() => _location = 'unconditioned');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _location == 'unconditioned' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Unconditioned',
                        style: TextStyle(
                          color: _location == 'unconditioned'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                'IECC 2024 / ASHRAE 90.1',
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
            '• IECC Table C403.11.3 for minimums\n'
            '• Hot water pipes must be insulated\n'
            '• Cold pipes to prevent condensation\n'
            '• Thickness based on temp difference\n'
            '• Increase for unconditioned spaces\n'
            '• Vapor barrier on cold pipes',
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
