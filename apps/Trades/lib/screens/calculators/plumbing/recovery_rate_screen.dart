import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Recovery Rate Calculator - Design System v2.6
///
/// Calculates water heater recovery rate (GPH) needs.
/// Determines if heater can keep up with demand.
///
/// References: ASHRAE, Manufacturer specs
class RecoveryRateScreen extends ConsumerStatefulWidget {
  const RecoveryRateScreen({super.key});
  @override
  ConsumerState<RecoveryRateScreen> createState() => _RecoveryRateScreenState();
}

class _RecoveryRateScreenState extends ConsumerState<RecoveryRateScreen> {
  // Peak demand (gallons)
  double _peakDemand = 60;

  // Recovery period (minutes)
  double _recoveryPeriod = 60;

  // Tank size (gallons)
  double _tankSize = 50;

  // Inlet temperature
  double _inletTemp = 55;

  // Desired outlet temperature
  double _outletTemp = 120;

  // Fuel type
  String _fuelType = 'gas';

  // Efficiency ratings by fuel type
  static const Map<String, ({double efficiency, int btuPerGallon, String desc})> _fuelData = {
    'gas': (efficiency: 0.80, btuPerGallon: 8340, desc: 'Natural Gas (80% eff)'),
    'propane': (efficiency: 0.80, btuPerGallon: 8340, desc: 'Propane (80% eff)'),
    'electric': (efficiency: 0.95, btuPerGallon: 3413, desc: 'Electric (95% eff)'),
    'heatPump': (efficiency: 2.5, btuPerGallon: 3413, desc: 'Heat Pump (250% COP)'),
  };

  double get _temperatureRise => _outletTemp - _inletTemp;

  // BTU required to heat water: weight × temp rise × specific heat
  // 8.33 lbs/gallon × temp rise × 1 BTU/lb/°F = 8.33 × temp rise
  double get _btuPerGallon => 8.33 * _temperatureRise;

  // Recovery rate needed (GPH)
  double get _requiredGph {
    // Need to recover (peak demand - tank usable) in recovery period
    final usableTank = _tankSize * 0.7; // 70% usable
    final toRecover = (_peakDemand - usableTank).clamp(0, double.infinity);
    return toRecover / (_recoveryPeriod / 60);
  }

  // BTU input required
  double get _requiredBtu {
    final fuel = _fuelData[_fuelType]!;
    return (_requiredGph * _btuPerGallon) / fuel.efficiency;
  }

  // Actual recovery rate for common heaters
  List<({String size, double gph, int btu})> get _standardHeaters {
    final fuel = _fuelData[_fuelType]!;
    if (_fuelType == 'gas' || _fuelType == 'propane') {
      return [
        (size: '40 gal', gph: 40000 * fuel.efficiency / _btuPerGallon, btu: 40000),
        (size: '50 gal', gph: 40000 * fuel.efficiency / _btuPerGallon, btu: 40000),
        (size: '50 gal HE', gph: 50000 * fuel.efficiency / _btuPerGallon, btu: 50000),
        (size: '75 gal', gph: 75000 * fuel.efficiency / _btuPerGallon, btu: 75000),
      ];
    } else {
      return [
        (size: '40 gal', gph: 4500 * fuel.efficiency / _btuPerGallon, btu: 4500),
        (size: '50 gal', gph: 4500 * fuel.efficiency / _btuPerGallon, btu: 4500),
        (size: '50 gal HE', gph: 5500 * fuel.efficiency / _btuPerGallon, btu: 5500),
        (size: '80 gal', gph: 5500 * fuel.efficiency / _btuPerGallon, btu: 5500),
      ];
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
          'Recovery Rate Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFuelTypeCard(colors),
          const SizedBox(height: 16),
          _buildDemandCard(colors),
          const SizedBox(height: 16),
          _buildTankCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildHeaterComparison(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final meetsNeed = _standardHeaters.any((h) => h.gph >= _requiredGph);

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
            '${_requiredGph.toStringAsFixed(1)} GPH',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recovery Rate Needed',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: meetsNeed
                  ? colors.accentSuccess.withValues(alpha: 0.1)
                  : colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meetsNeed ? 'Standard heater adequate' : 'May need larger heater',
              style: TextStyle(
                color: meetsNeed ? colors.accentSuccess : colors.accentWarning,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
                _buildResultRow(colors, 'Peak Demand', '${_peakDemand.toStringAsFixed(0)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tank Size', '${_tankSize.toStringAsFixed(0)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Temp Rise', '${_temperatureRise.toStringAsFixed(0)}°F'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'BTU/gallon', _btuPerGallon.toStringAsFixed(0)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU Required', '${(_requiredBtu / 1000).toStringAsFixed(1)}k', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeCard(ZaftoColors colors) {
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
            'FUEL TYPE',
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
            children: _fuelData.entries.map((entry) {
              final isSelected = _fuelType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _fuelType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc.split(' (')[0],
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

  Widget _buildDemandCard(ZaftoColors colors) {
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
            'PEAK DEMAND',
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
                '${_peakDemand.toStringAsFixed(0)} gal',
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
                    value: _peakDemand,
                    min: 20,
                    max: 200,
                    divisions: 36,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _peakDemand = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Recovery: ${_recoveryPeriod.toStringAsFixed(0)} min',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary.withValues(alpha: 0.5),
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _recoveryPeriod,
                    min: 30,
                    max: 120,
                    divisions: 6,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _recoveryPeriod = v);
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

  Widget _buildTankCard(ZaftoColors colors) {
    final tanks = [30.0, 40.0, 50.0, 65.0, 75.0, 80.0];

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
            'TANK SIZE',
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
            children: tanks.map((tank) {
              final isSelected = _tankSize == tank;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tankSize = tank);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tank.toStringAsFixed(0)} gal',
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
          Row(
            children: [
              Text('Inlet: ${_inletTemp.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    value: _inletTemp,
                    min: 40,
                    max: 70,
                    divisions: 6,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _inletTemp = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('Outlet: ${_outletTemp.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: Colors.red,
                  ),
                  child: Slider(
                    value: _outletTemp,
                    min: 100,
                    max: 140,
                    divisions: 8,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _outletTemp = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Temperature rise: ${_temperatureRise.toStringAsFixed(0)}°F',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaterComparison(ZaftoColors colors) {
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
            'STANDARD HEATER RECOVERY RATES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._standardHeaters.map((heater) {
            final meetsNeed = heater.gph >= _requiredGph;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: meetsNeed
                    ? colors.accentSuccess.withValues(alpha: 0.1)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: meetsNeed ? Border.all(color: colors.accentSuccess) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      heater.size,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(heater.btu / 1000).toStringAsFixed(0)}k BTU',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${heater.gph.toStringAsFixed(1)} GPH',
                      style: TextStyle(
                        color: meetsNeed ? colors.accentSuccess : colors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (meetsNeed)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
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
              Icon(LucideIcons.info, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Recovery Rate Info',
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
            '• GPH = Gallons Per Hour recovery\n'
            '• BTU/gallon = 8.33 × temp rise\n'
            '• Gas recovers faster than electric\n'
            '• Heat pump most efficient but slower\n'
            '• Tankless has unlimited recovery\n'
            '• Consider first hour rating instead',
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
