import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Heat Tape Calculator - Design System v2.6
///
/// Calculates heat tape wattage for pipe freeze protection.
/// Determines watts per foot and total power needed.
///
/// References: UL 515, Manufacturer specs
class HeatTapeScreen extends ConsumerStatefulWidget {
  const HeatTapeScreen({super.key});
  @override
  ConsumerState<HeatTapeScreen> createState() => _HeatTapeScreenState();
}

class _HeatTapeScreenState extends ConsumerState<HeatTapeScreen> {
  // Pipe diameter
  String _pipeDiameter = '3/4';

  // Pipe material
  String _pipeMaterial = 'copper';

  // Pipe length
  double _pipeLength = 25;

  // Minimum expected temperature
  double _minTemp = 0;

  // Desired pipe temperature
  double _desiredTemp = 40;

  // Insulation thickness
  double _insulation = 0.5;

  // Exposure
  String _exposure = 'sheltered';

  static const List<String> _pipeSizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2', '3', '4'];

  // Watts per foot based on temp difference and insulation
  // Simplified table based on typical heat tape requirements
  double get _wattsPerFoot {
    final tempDiff = _desiredTemp - _minTemp;
    final pipeDia = _parsePipeDiameter(_pipeDiameter);

    // Base watts per foot (at 1" pipe, 40°F diff, 1/2" insulation)
    double baseWatts = 3.0;

    // Adjust for temperature difference
    baseWatts *= (tempDiff / 40);

    // Adjust for pipe diameter
    baseWatts *= (pipeDia / 1.0);

    // Adjust for insulation
    if (_insulation < 0.5) baseWatts *= 1.5;
    if (_insulation >= 1.0) baseWatts *= 0.7;
    if (_insulation >= 1.5) baseWatts *= 0.5;

    // Adjust for exposure
    if (_exposure == 'exposed') baseWatts *= 1.3;
    if (_exposure == 'buried') baseWatts *= 0.8;

    return baseWatts.clamp(1.0, 15.0);
  }

  double get _totalWatts => _wattsPerFoot * _pipeLength;

  double get _amps120 => _totalWatts / 120;
  double get _amps240 => _totalWatts / 240;

  double _parsePipeDiameter(String size) {
    switch (size) {
      case '1/2': return 0.5;
      case '3/4': return 0.75;
      case '1-1/4': return 1.25;
      case '1-1/2': return 1.5;
      default: return double.tryParse(size) ?? 1.0;
    }
  }

  String get _recommendedType {
    final wpf = _wattsPerFoot;
    if (wpf <= 3) return 'Self-regulating 3W/ft';
    if (wpf <= 5) return 'Self-regulating 5W/ft';
    if (wpf <= 8) return 'Self-regulating 8W/ft';
    if (wpf <= 10) return 'Self-regulating 10W/ft';
    return 'Constant wattage (high output)';
  }

  double get _estimatedCostPerHour {
    // Assume $0.12/kWh
    return (_totalWatts / 1000) * 0.12;
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
          'Heat Tape Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildPipeLengthCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildInsulationCard(colors),
          const SizedBox(height: 16),
          _buildExposureCard(colors),
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
            '${_wattsPerFoot.toStringAsFixed(1)} W/ft',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Required Heat Output',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _recommendedType,
              style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
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
                _buildResultRow(colors, 'Pipe Length', '${_pipeLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Watts', '${_totalWatts.toStringAsFixed(0)} W', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Amps @ 120V', '${_amps120.toStringAsFixed(2)} A'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Amps @ 240V', '${_amps240.toStringAsFixed(2)} A'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Est. Cost/hr', '\$${_estimatedCostPerHour.toStringAsFixed(3)}'),
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

  Widget _buildPipeLengthCard(ZaftoColors colors) {
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
            'PIPE LENGTH (FEET)',
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
                '${_pipeLength.toStringAsFixed(0)} ft',
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
                    value: _pipeLength,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _pipeLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total length of pipe to protect',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
            'TEMPERATURES (°F)',
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
              Text('Min Ambient: ${_minTemp.toStringAsFixed(0)}°F', style: TextStyle(color: Colors.blue, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    value: _minTemp,
                    min: -40,
                    max: 32,
                    divisions: 18,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _minTemp = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Desired Pipe: ${_desiredTemp.toStringAsFixed(0)}°F', style: TextStyle(color: Colors.orange, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: Colors.orange,
                  ),
                  child: Slider(
                    value: _desiredTemp,
                    min: 35,
                    max: 60,
                    divisions: 5,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _desiredTemp = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsulationCard(ZaftoColors colors) {
    final thicknesses = [0.0, 0.5, 1.0, 1.5, 2.0];

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
            'INSULATION THICKNESS',
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
            children: thicknesses.map((thick) {
              final isSelected = _insulation == thick;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _insulation = thick);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    thick == 0 ? 'None' : '$thick"',
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
            'More insulation = less heat tape needed',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildExposureCard(ZaftoColors colors) {
    final exposures = [
      (value: 'sheltered', label: 'Sheltered'),
      (value: 'exposed', label: 'Wind Exposed'),
      (value: 'buried', label: 'Buried'),
    ];

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
            'EXPOSURE',
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
            children: exposures.map((exp) {
              final isSelected = _exposure == exp.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _exposure = exp.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exp.label,
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
              Icon(LucideIcons.info, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Heat Tape Guidelines',
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
            '• Self-regulating preferred (safer)\n'
            '• UL 515 listed products required\n'
            '• Thermostat control recommended\n'
            '• Insulate over heat tape\n'
            '• GFCI protection required\n'
            '• Never overlap heat tape',
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
