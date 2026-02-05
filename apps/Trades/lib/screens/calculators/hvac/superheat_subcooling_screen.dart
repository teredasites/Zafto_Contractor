import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Superheat/Subcooling Calculator - Design System v2.6
///
/// Calculates superheat and subcooling for system diagnosis.
/// Essential for proper refrigerant charging.
///
/// References: EPA 608, Manufacturer Specifications
class SuperheatSubcoolingScreen extends ConsumerStatefulWidget {
  const SuperheatSubcoolingScreen({super.key});
  @override
  ConsumerState<SuperheatSubcoolingScreen> createState() => _SuperheatSubcoolingScreenState();
}

class _SuperheatSubcoolingScreenState extends ConsumerState<SuperheatSubcoolingScreen> {
  // Measurement type
  String _measurementType = 'superheat';

  // Suction pressure (PSIG) - for superheat
  double _suctionPressure = 118;

  // Suction line temp (°F) - for superheat
  double _suctionTemp = 55;

  // Liquid pressure (PSIG) - for subcooling
  double _liquidPressure = 280;

  // Liquid line temp (°F) - for subcooling
  double _liquidTemp = 95;

  // Refrigerant type
  String _refrigerantType = 'r410a';

  // Refrigerant PT data (simplified - saturation temps at common pressures)
  static const Map<String, Map<int, double>> _ptCharts = {
    'r410a': {
      90: 32, 100: 37, 110: 42, 118: 45, 130: 50, 140: 54, 150: 58,
      200: 72, 250: 86, 280: 95, 300: 100, 350: 112, 400: 123,
    },
    'r22': {
      40: 15, 50: 22, 60: 28, 70: 34, 80: 40, 90: 45, 100: 50,
      150: 67, 200: 82, 250: 96, 300: 109, 350: 120,
    },
    'r32': {
      100: 30, 120: 38, 140: 45, 160: 52, 180: 58, 200: 64,
      250: 78, 300: 90, 350: 101, 400: 111,
    },
    'r454b': {
      90: 28, 100: 33, 110: 38, 120: 42, 130: 47, 140: 51, 150: 55,
      200: 70, 250: 83, 300: 95, 350: 106,
    },
  };

  // Get saturation temp from pressure
  double _getSatTemp(double pressure) {
    final chart = _ptCharts[_refrigerantType] ?? _ptCharts['r410a']!;
    final pressures = chart.keys.toList()..sort();

    // Find bracketing pressures and interpolate
    for (int i = 0; i < pressures.length - 1; i++) {
      if (pressure >= pressures[i] && pressure <= pressures[i + 1]) {
        final p1 = pressures[i];
        final p2 = pressures[i + 1];
        final t1 = chart[p1]!;
        final t2 = chart[p2]!;
        final ratio = (pressure - p1) / (p2 - p1);
        return t1 + (t2 - t1) * ratio;
      }
    }

    // Extrapolate if outside range
    if (pressure < pressures.first) return chart[pressures.first]! - 5;
    return chart[pressures.last]! + 5;
  }

  // Superheat calculation
  double get _superheat {
    final satTemp = _getSatTemp(_suctionPressure);
    return _suctionTemp - satTemp;
  }

  // Subcooling calculation
  double get _subcooling {
    final satTemp = _getSatTemp(_liquidPressure);
    return satTemp - _liquidTemp;
  }

  // Target ranges
  String get _superheatTarget => '10-15°F';
  String get _subcoolingTarget => '8-12°F';

  // Diagnosis
  String get _diagnosis {
    if (_measurementType == 'superheat') {
      if (_superheat < 5) return 'Low - Possible flooding';
      if (_superheat < 10) return 'Slightly low - May need charge adjustment';
      if (_superheat <= 15) return 'Normal range';
      if (_superheat <= 25) return 'Slightly high - May be undercharged';
      return 'High - Likely undercharged or restricted';
    } else {
      if (_subcooling < 5) return 'Low - Likely undercharged';
      if (_subcooling < 8) return 'Slightly low';
      if (_subcooling <= 12) return 'Normal range';
      if (_subcooling <= 18) return 'Slightly high - May be overcharged';
      return 'High - Likely overcharged or restricted';
    }
  }

  bool get _inRange {
    if (_measurementType == 'superheat') {
      return _superheat >= 10 && _superheat <= 15;
    }
    return _subcooling >= 8 && _subcooling <= 12;
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
          'Superheat / Subcooling',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildMeasurementTypeCard(colors),
          const SizedBox(height: 16),
          _buildRefrigerantCard(colors),
          const SizedBox(height: 16),
          if (_measurementType == 'superheat')
            _buildSuperheatCard(colors)
          else
            _buildSubcoolingCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final value = _measurementType == 'superheat' ? _superheat : _subcooling;
    final label = _measurementType == 'superheat' ? 'Superheat' : 'Subcooling';
    final target = _measurementType == 'superheat' ? _superheatTarget : _subcoolingTarget;

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
            '${value.toStringAsFixed(1)}°F',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _inRange
                  ? colors.accentPrimary.withValues(alpha: 0.1)
                  : colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _diagnosis,
              style: TextStyle(
                color: _inRange ? colors.accentPrimary : colors.accentWarning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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
                _buildResultRow(colors, 'Target Range', target),
                const SizedBox(height: 10),
                if (_measurementType == 'superheat') ...[
                  _buildResultRow(colors, 'Suction Pressure', '${_suctionPressure.toStringAsFixed(0)} PSIG'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Saturation Temp', '${_getSatTemp(_suctionPressure).toStringAsFixed(1)}°F'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Suction Line Temp', '${_suctionTemp.toStringAsFixed(1)}°F'),
                ] else ...[
                  _buildResultRow(colors, 'Liquid Pressure', '${_liquidPressure.toStringAsFixed(0)} PSIG'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Saturation Temp', '${_getSatTemp(_liquidPressure).toStringAsFixed(1)}°F'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Liquid Line Temp', '${_liquidTemp.toStringAsFixed(1)}°F'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTypeCard(ZaftoColors colors) {
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
            'MEASUREMENT TYPE',
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
                    setState(() => _measurementType = 'superheat');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _measurementType == 'superheat' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Superheat',
                        style: TextStyle(
                          color: _measurementType == 'superheat'
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
                    setState(() => _measurementType = 'subcooling');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _measurementType == 'subcooling' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Subcooling',
                        style: TextStyle(
                          color: _measurementType == 'subcooling'
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

  Widget _buildRefrigerantCard(ZaftoColors colors) {
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
            'REFRIGERANT',
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
            children: ['r410a', 'r22', 'r32', 'r454b'].map((ref) {
              final isSelected = _refrigerantType == ref;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _refrigerantType = ref);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref.toUpperCase().replaceFirst('R', 'R-'),
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSuperheatCard(ZaftoColors colors) {
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
            'SUPERHEAT MEASUREMENTS',
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
              Text('Suction Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_suctionPressure.toStringAsFixed(0)} PSIG',
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
              value: _suctionPressure,
              min: 50,
              max: 200,
              divisions: 150,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _suctionPressure = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suction Line Temp', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_suctionTemp.toStringAsFixed(1)}°F',
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
              value: _suctionTemp,
              min: 30,
              max: 80,
              divisions: 100,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _suctionTemp = v);
              },
            ),
          ),
          Text(
            'Measure at service valve',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcoolingCard(ZaftoColors colors) {
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
            'SUBCOOLING MEASUREMENTS',
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
              Text('Liquid Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_liquidPressure.toStringAsFixed(0)} PSIG',
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
              value: _liquidPressure,
              min: 150,
              max: 450,
              divisions: 300,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _liquidPressure = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Liquid Line Temp', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_liquidTemp.toStringAsFixed(1)}°F',
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
              value: _liquidTemp,
              min: 60,
              max: 130,
              divisions: 140,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _liquidTemp = v);
              },
            ),
          ),
          Text(
            'Measure at condensing unit',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.thermometer, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Charging Guidelines',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Superheat: Fixed orifice systems\n'
            '• Subcooling: TXV systems\n'
            '• Verify outdoor temp conditions\n'
            '• Allow system to stabilize\n'
            '• Use manufacturer specs\n'
            '• EPA 608 certification required',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
