import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Hot Water Recirculation System - Design System v2.6
///
/// Designs DHW recirculation systems for instant hot water.
/// Sizes pump, pipe, and calculates energy impact.
///
/// References: ASHRAE, DOE water heater standards
class RecirculationSystemScreen extends ConsumerStatefulWidget {
  const RecirculationSystemScreen({super.key});
  @override
  ConsumerState<RecirculationSystemScreen> createState() => _RecirculationSystemScreenState();
}

class _RecirculationSystemScreenState extends ConsumerState<RecirculationSystemScreen> {
  // Total loop length (supply + return)
  double _loopLength = 150.0;

  // Pipe size (inches)
  String _pipeSize = '1/2';

  // System type
  String _systemType = 'dedicated';

  // Control method
  String _controlMethod = 'timer';

  // Number of fixtures served
  int _fixtures = 6;

  // Water heater BTU/hr
  double _waterHeaterBTU = 40000;

  // System types
  static const Map<String, ({String name, String desc, double efficiency})> _systemTypes = {
    'dedicated': (name: 'Dedicated Return', desc: 'Separate return line', efficiency: 1.0),
    'crossover': (name: 'Crossover Bridge', desc: 'Uses cold line as return', efficiency: 0.9),
    'pointOfUse': (name: 'Point-of-Use Pump', desc: 'Under-sink demand', efficiency: 0.95),
  };

  // Control methods
  static const Map<String, ({String name, String desc, double runHours})> _controlMethods = {
    'continuous': (name: 'Continuous', desc: 'Always running', runHours: 24),
    'timer': (name: 'Timer', desc: 'Scheduled hours', runHours: 8),
    'thermostat': (name: 'Thermostat', desc: 'Temp-activated', runHours: 6),
    'demand': (name: 'Demand/Button', desc: 'User-activated', runHours: 2),
    'motion': (name: 'Motion Sensor', desc: 'Presence-based', runHours: 4),
  };

  // Pipe heat loss (BTU/hr per linear foot)
  static const Map<String, ({double uninsulated, double insulated})> _heatLoss = {
    '1/2': (uninsulated: 25, insulated: 8),
    '3/4': (uninsulated: 35, insulated: 12),
    '1': (uninsulated: 45, insulated: 15),
    '1-1/4': (uninsulated: 55, insulated: 18),
  };

  // Flow rate needed (GPM) - typically 0.5-3 GPM
  double get _flowRate {
    // Based on pipe size and velocity ~2 fps
    switch (_pipeSize) {
      case '1/2': return 1.0;
      case '3/4': return 1.8;
      case '1': return 3.0;
      case '1-1/4': return 4.5;
      default: return 1.5;
    }
  }

  // Heat loss per hour (BTU/hr)
  double get _heatLossPerHour {
    final loss = _heatLoss[_pipeSize];
    if (loss == null) return 0;
    // Assume insulated for calculation
    return _loopLength * loss.insulated;
  }

  // Daily energy use (BTU)
  double get _dailyEnergyUse {
    final runHours = _controlMethods[_controlMethod]?.runHours ?? 8;
    return _heatLossPerHour * runHours;
  }

  // Annual energy cost estimate
  double get _annualEnergyCost {
    // Natural gas: ~$1.00 per therm (100,000 BTU)
    // Electric: ~$0.12 per kWh (3,412 BTU)
    // Assume gas water heater
    final annualBTU = _dailyEnergyUse * 365;
    final therms = annualBTU / 100000;
    return therms * 1.00; // $1 per therm average
  }

  // Recommended pump
  String get _recommendedPump {
    if (_flowRate <= 1.5) return '1/40 HP Circulator';
    if (_flowRate <= 3.0) return '1/25 HP Circulator';
    return '1/12 HP Circulator';
  }

  // Water savings estimate (gallons/year)
  double get _waterSavings {
    // Average household wastes 2 gal per use waiting for hot water
    // Average 10 uses per day
    return 2 * 10 * 365.0; // ~7,300 gallons/year
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
          'Recirculation System',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeCard(colors),
          const SizedBox(height: 16),
          _buildLoopCard(colors),
          const SizedBox(height: 16),
          _buildControlCard(colors),
          const SizedBox(height: 16),
          _buildEnergyAnalysis(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _recommendedPump,
              style: TextStyle(
                color: colors.isDark ? Colors.black : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
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
                _buildResultRow(colors, 'Flow Rate', '${_flowRate.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Loop Length', '${_loopLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Heat Loss', '${_heatLossPerHour.toStringAsFixed(0)} BTU/hr'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Est. Annual Cost', '\$${_annualEnergyCost.toStringAsFixed(0)}', highlight: true),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Water Saved', '${(_waterSavings / 1000).toStringAsFixed(1)}k gal/yr'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTypeCard(ZaftoColors colors) {
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
            'SYSTEM TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._systemTypes.entries.map((entry) {
            final isSelected = _systemType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _systemType = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.name,
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value.desc,
                            style: TextStyle(color: colors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoopCard(ZaftoColors colors) {
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
            'LOOP DESIGN',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Loop Length', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_loopLength.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _loopLength,
                    min: 50,
                    max: 400,
                    divisions: 35,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _loopLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total pipe length (supply + return)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Text(
            'PIPE SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['1/2', '3/4', '1', '1-1/4'].map((size) {
              final isSelected = _pipeSize == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size"',
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

  Widget _buildControlCard(ZaftoColors colors) {
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
            'CONTROL METHOD',
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
            children: _controlMethods.entries.map((entry) {
              final isSelected = _controlMethod == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _controlMethod = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.value.name,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '~${entry.value.runHours.toInt()}h/day',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Demand/button control is most energy efficient',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyAnalysis(ZaftoColors colors) {
    final runHours = _controlMethods[_controlMethod]?.runHours ?? 8;

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
            'ENERGY ANALYSIS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Heat Loss Rate', '${_heatLossPerHour.toStringAsFixed(0)} BTU/hr'),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Run Hours/Day', '${runHours.toStringAsFixed(0)} hours'),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Daily Energy', '${(_dailyEnergyUse / 1000).toStringAsFixed(1)}k BTU'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Annual Energy', '${(_dailyEnergyUse * 365 / 1000000).toStringAsFixed(1)}M BTU'),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Est. Annual Cost', '\$${_annualEnergyCost.toStringAsFixed(0)}', highlight: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.droplets, color: colors.accentSuccess, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saves ~${(_waterSavings / 1000).toStringAsFixed(0)}k gallons/year in wasted water',
                    style: TextStyle(color: colors.accentSuccess, fontSize: 11),
                  ),
                ),
              ],
            ),
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
                'IPC 607 / Energy Codes',
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
            '• IPC 607.2 - Hot water temp maintenance\n'
            '• Insulate all hot water piping (R-3 min)\n'
            '• Size pump for 2-4 fps velocity\n'
            '• Use demand control for efficiency\n'
            '• Check valve at pump discharge\n'
            '• Expansion tank may be required',
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
