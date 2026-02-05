import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Tankless Water Heater Sizing Calculator - Design System v2.6
///
/// Sizes tankless water heaters based on flow rate and temperature rise.
/// Covers gas and electric units for residential applications.
///
/// References: Manufacturer specifications, ASHRAE
class TanklessSizingScreen extends ConsumerStatefulWidget {
  const TanklessSizingScreen({super.key});
  @override
  ConsumerState<TanklessSizingScreen> createState() => _TanklessSizingScreenState();
}

class _TanklessSizingScreenState extends ConsumerState<TanklessSizingScreen> {
  // Fuel type
  String _fuelType = 'gas';

  // Inlet water temperature (groundwater temp)
  double _inletTemp = 50;

  // Desired output temperature
  double _outletTemp = 120;

  // Fixtures to run simultaneously
  Map<String, int> _fixtures = {
    'shower': 1,
    'bathroom_faucet': 1,
    'kitchen_sink': 0,
    'dishwasher': 0,
    'washing_machine': 0,
  };

  static const Map<String, ({double gpm, String desc})> _fixtureFlows = {
    'shower': (gpm: 2.0, desc: 'Shower'),
    'bathroom_faucet': (gpm: 1.0, desc: 'Bathroom Faucet'),
    'kitchen_sink': (gpm: 1.5, desc: 'Kitchen Sink'),
    'dishwasher': (gpm: 1.5, desc: 'Dishwasher'),
    'washing_machine': (gpm: 2.0, desc: 'Washing Machine'),
  };

  static const Map<String, ({int maxBtu, double maxGpm, String desc})> _unitSizes = {
    'small': (maxBtu: 120000, maxGpm: 5.0, desc: 'Small (1-2 fixtures)'),
    'medium': (maxBtu: 160000, maxGpm: 7.0, desc: 'Medium (2-3 fixtures)'),
    'large': (maxBtu: 199000, maxGpm: 9.0, desc: 'Large (3-4 fixtures)'),
    'commercial': (maxBtu: 250000, maxGpm: 11.0, desc: 'Commercial (4+ fixtures)'),
  };

  double get _temperatureRise => _outletTemp - _inletTemp;

  double get _totalGpm {
    double total = 0;
    _fixtures.forEach((key, count) {
      total += (_fixtureFlows[key]?.gpm ?? 0) * count;
    });
    return total;
  }

  // BTU = GPM × 500 × Temperature Rise
  double get _requiredBtu => _totalGpm * 500 * _temperatureRise;

  // For electric: kW = GPM × 500 × Temp Rise / 3412
  double get _requiredKw => _requiredBtu / 3412;

  String get _recommendedSize {
    if (_requiredBtu <= 120000) return 'small';
    if (_requiredBtu <= 160000) return 'medium';
    if (_requiredBtu <= 199000) return 'large';
    return 'commercial';
  }

  double get _achievableGpm {
    // Calculate actual GPM at given temp rise
    final maxBtu = _unitSizes[_recommendedSize]?.maxBtu ?? 199000;
    return maxBtu / (500 * _temperatureRise);
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
          'Tankless Water Heater',
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
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
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
    final canMeetDemand = _achievableGpm >= _totalGpm;
    final statusColor = canMeetDemand ? colors.accentSuccess : colors.accentWarning;

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
            _fuelType == 'gas' ? '${(_requiredBtu / 1000).toStringAsFixed(0)}K' : '${_requiredKw.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _fuelType == 'gas' ? 'BTU Required' : 'kW Required',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canMeetDemand ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  canMeetDemand ? 'Demand Met' : 'Consider Larger Unit',
                  style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
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
                _buildResultRow(colors, 'Required Flow', '${_totalGpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Temp Rise', '${_temperatureRise.toStringAsFixed(0)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Recommended Size', _unitSizes[_recommendedSize]?.desc ?? 'Large'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Achievable GPM', '${_achievableGpm.toStringAsFixed(1)} GPM @ ${_temperatureRise.toStringAsFixed(0)}°F rise'),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _fuelType = 'gas');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _fuelType == 'gas' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.flame,
                          color: _fuelType == 'gas' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gas',
                          style: TextStyle(
                            color: _fuelType == 'gas' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'BTU rating',
                          style: TextStyle(
                            color: _fuelType == 'gas' ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                            fontSize: 10,
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
                    setState(() => _fuelType = 'electric');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _fuelType == 'electric' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.zap,
                          color: _fuelType == 'electric' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Electric',
                          style: TextStyle(
                            color: _fuelType == 'electric' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'kW rating',
                          style: TextStyle(
                            color: _fuelType == 'electric' ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                            fontSize: 10,
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
          _buildTempSlider(colors, 'Inlet (Groundwater)', _inletTemp, (v) => setState(() => _inletTemp = v), 35, 75),
          const SizedBox(height: 16),
          _buildTempSlider(colors, 'Outlet (Desired)', _outletTemp, (v) => setState(() => _outletTemp = v), 100, 140),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Temperature Rise: ',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                Text(
                  '${_temperatureRise.toStringAsFixed(0)}°F',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempSlider(ZaftoColors colors, String label, double value, Function(double) onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}°F',
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
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
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
            'SIMULTANEOUS FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fixtureFlows.entries.map((entry) {
            final count = _fixtures[entry.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.desc,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        ),
                        Text(
                          '${entry.value.gpm} GPM each',
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (count > 0) {
                            setState(() => _fixtures[entry.key] = count - 1);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: count > 0 ? colors.bgBase : colors.bgBase.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.minus, color: count > 0 ? colors.textPrimary : colors.textTertiary, size: 16),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (count < 5) {
                            setState(() => _fixtures[entry.key] = count + 1);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.accentPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
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
            'UNIT SIZE REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._unitSizes.entries.map((entry) {
            final isRecommended = entry.key == _recommendedSize;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✓',
                        style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 10),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      entry.value.desc,
                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${entry.value.maxBtu ~/ 1000}K BTU / ${entry.value.maxGpm} GPM',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
              Icon(LucideIcons.info, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Sizing Formula',
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
            '• BTU = GPM × 500 × Temp Rise\n'
            '• kW = BTU ÷ 3412\n'
            '• Groundwater temp varies by region\n'
            '• Cold climates = higher temp rise\n'
            '• Gas units: 80-99% efficiency\n'
            '• Electric units: 99%+ efficiency',
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
