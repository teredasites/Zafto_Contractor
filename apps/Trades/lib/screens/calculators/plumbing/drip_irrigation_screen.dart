import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drip Irrigation Calculator - Design System v2.6
///
/// Sizes drip irrigation systems for gardens and landscapes.
/// Calculates emitter requirements, run times, and supply sizing.
///
/// References: Irrigation Association, Manufacturer Guidelines
class DripIrrigationScreen extends ConsumerStatefulWidget {
  const DripIrrigationScreen({super.key});
  @override
  ConsumerState<DripIrrigationScreen> createState() => _DripIrrigationScreenState();
}

class _DripIrrigationScreenState extends ConsumerState<DripIrrigationScreen> {
  // Number of plants/emitters
  int _emitterCount = 20;

  // Emitter flow rate (GPH)
  double _emitterGph = 1.0;

  // Available pressure (PSI)
  double _pressure = 40;

  // Available flow (GPM)
  double _availableGpm = 5;

  // Soil type
  String _soilType = 'loam';

  static const Map<String, ({String desc, double wateringFactor})> _soilTypes = {
    'sand': (desc: 'Sandy', wateringFactor: 1.3),
    'loam': (desc: 'Loam', wateringFactor: 1.0),
    'clay': (desc: 'Clay', wateringFactor: 0.7),
  };

  // Total GPH
  double get _totalGph => _emitterCount * _emitterGph;

  // Total GPM required
  double get _totalGpm => _totalGph / 60;

  // System adequate
  bool get _isAdequate => _totalGpm <= _availableGpm;

  // Supply line size
  String get _supplySize {
    if (_totalGpm <= 2) return '½\"';
    if (_totalGpm <= 5) return '¾\"';
    return '1\"';
  }

  // Maximum emitters per zone (based on available flow)
  int get _maxEmittersPerZone => ((_availableGpm * 60) / _emitterGph).floor();

  // Zones needed
  int get _zonesNeeded => (_emitterCount / _maxEmittersPerZone).ceil().clamp(1, 10);

  // Run time for 1 gallon per plant (minutes)
  int get _runTimeMinutes {
    final factor = _soilTypes[_soilType]?.wateringFactor ?? 1.0;
    return ((60 / _emitterGph) * factor).round();
  }

  // Pressure regulator needed
  bool get _needsRegulator => _pressure > 25;

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
          'Drip Irrigation',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildEmitterCard(colors),
          const SizedBox(height: 16),
          _buildSupplyCard(colors),
          const SizedBox(height: 16),
          _buildSoilCard(colors),
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
            '$_zonesNeeded',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _zonesNeeded == 1 ? 'Zone Required' : 'Zones Required',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!_isAdequate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Multiple zones needed for available flow',
                style: TextStyle(color: colors.accentWarning, fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total Flow', '${_totalGph.toStringAsFixed(1)} GPH'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Per Zone', '${_maxEmittersPerZone} emitters max'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Line', _supplySize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Run Time (1 gal/plant)', '$_runTimeMinutes min'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pressure Regulator', _needsRegulator ? 'Required' : 'Optional'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmitterCard(ZaftoColors colors) {
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
            'EMITTERS',
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
              Text('Number of Emitters', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_emitterCount',
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
              value: _emitterCount.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _emitterCount = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flow Rate per Emitter', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_emitterGph.toStringAsFixed(1)} GPH',
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
              value: _emitterGph,
              min: 0.5,
              max: 4,
              divisions: 7,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _emitterGph = v);
              },
            ),
          ),
          Text(
            'Common: 0.5, 1, 2 GPH emitters',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyCard(ZaftoColors colors) {
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
            'WATER SUPPLY',
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
              Text('Available Flow', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_availableGpm.toStringAsFixed(1)} GPM',
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
              value: _availableGpm,
              min: 1,
              max: 15,
              divisions: 28,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _availableGpm = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pressure.toStringAsFixed(0)} PSI',
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
              value: _pressure,
              min: 15,
              max: 80,
              divisions: 65,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pressure = v);
              },
            ),
          ),
          Text(
            'Drip systems operate best at 15-25 PSI',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilCard(ZaftoColors colors) {
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
            'SOIL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _soilTypes.entries.map((entry) {
              final isSelected = _soilType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _soilType = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
              Icon(LucideIcons.droplets, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Drip System Tips',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Use pressure regulator (25 PSI)\n'
            '• Install filter before emitters\n'
            '• Flush system before closing\n'
            '• Check emitters monthly\n'
            '• Backflow preventer required\n'
            '• Winterize in freezing climates',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
