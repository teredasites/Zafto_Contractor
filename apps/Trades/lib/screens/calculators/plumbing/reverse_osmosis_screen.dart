import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Reverse Osmosis System Calculator - Design System v2.6
///
/// Sizes RO systems for residential and light commercial.
/// Calculates membrane capacity and waste water ratios.
///
/// References: NSF/ANSI 58, WQA Guidelines
class ReverseOsmosisScreen extends ConsumerStatefulWidget {
  const ReverseOsmosisScreen({super.key});
  @override
  ConsumerState<ReverseOsmosisScreen> createState() => _ReverseOsmosisScreenState();
}

class _ReverseOsmosisScreenState extends ConsumerState<ReverseOsmosisScreen> {
  // Daily usage (gallons)
  double _dailyUsage = 10;

  // Feed water TDS (ppm)
  double _feedTds = 300;

  // Water temperature (°F)
  double _temperature = 77;

  // Feed pressure (PSI)
  double _feedPressure = 60;

  // System type
  String _systemType = 'undersink';

  static const Map<String, ({String desc, double gpd, int stages})> _systemTypes = {
    'undersink': (desc: 'Under-Sink', gpd: 50, stages: 4),
    'undersink_plus': (desc: 'Under-Sink Plus', gpd: 75, stages: 5),
    'countertop': (desc: 'Countertop', gpd: 35, stages: 3),
    'whole_house': (desc: 'Whole House', gpd: 500, stages: 5),
  };

  // Temperature correction factor
  double get _tempFactor {
    if (_temperature >= 77) return 1.0;
    if (_temperature >= 70) return 0.9;
    if (_temperature >= 60) return 0.75;
    if (_temperature >= 50) return 0.6;
    return 0.5;
  }

  // Pressure correction factor
  double get _pressureFactor {
    if (_feedPressure >= 60) return 1.0;
    if (_feedPressure >= 50) return 0.85;
    if (_feedPressure >= 40) return 0.7;
    return 0.5;
  }

  // Effective GPD with corrections
  double get _effectiveGpd {
    final baseGpd = _systemTypes[_systemType]?.gpd ?? 50;
    return baseGpd * _tempFactor * _pressureFactor;
  }

  // TDS rejection (typically 95-98%)
  double get _tdsRejection => 0.96;
  int get _productTds => (_feedTds * (1 - _tdsRejection)).round();

  // Waste ratio (typically 3:1 to 4:1)
  String get _wasteRatio {
    if (_feedTds > 500) return '4:1';
    if (_feedTds > 300) return '3:1';
    return '2:1';
  }

  // Tank size recommendation
  String get _tankSize {
    if (_dailyUsage <= 5) return '2 gallon';
    if (_dailyUsage <= 10) return '3.2 gallon';
    if (_dailyUsage <= 20) return '4 gallon';
    return '14 gallon';
  }

  // Membrane size
  String get _membraneSize {
    final gpd = _systemTypes[_systemType]?.gpd ?? 50;
    return '$gpd GPD';
  }

  // System adequate check
  bool get _isAdequate => _effectiveGpd >= _dailyUsage;

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
          'RO System Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeCard(colors),
          const SizedBox(height: 16),
          _buildUsageCard(colors),
          const SizedBox(height: 16),
          _buildWaterQualityCard(colors),
          const SizedBox(height: 16),
          _buildConditionsCard(colors),
          const SizedBox(height: 16),
          _buildMaintenanceCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = _isAdequate ? colors.accentSuccess : colors.accentError;
    final statusText = _isAdequate ? 'Adequate' : 'Undersized';

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
            _membraneSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Membrane Capacity',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAdequate ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$statusText (${_effectiveGpd.toStringAsFixed(0)} GPD effective)',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
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
                _buildResultRow(colors, 'Tank Size', _tankSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Stages', '${_systemTypes[_systemType]?.stages ?? 4}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Product TDS', '$_productTds ppm'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Waste Ratio', _wasteRatio),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _systemType = entry.key);
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.gpd} GPD',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
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

  Widget _buildUsageCard(ZaftoColors colors) {
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
            'DAILY USAGE',
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
              Text('RO Water Needed', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_dailyUsage.toStringAsFixed(0)} gallons/day',
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
              value: _dailyUsage,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _dailyUsage = v);
              },
            ),
          ),
          Text(
            'Drinking + cooking typically 2-5 GPD per person',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterQualityCard(ZaftoColors colors) {
    String tdsQuality;
    if (_feedTds < 200) {
      tdsQuality = 'Low';
    } else if (_feedTds < 400) {
      tdsQuality = 'Moderate';
    } else if (_feedTds < 700) {
      tdsQuality = 'High';
    } else {
      tdsQuality = 'Very High';
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
            'FEED WATER TDS',
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
              Text('Total Dissolved Solids', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_feedTds.toStringAsFixed(0)} ppm ($tdsQuality)',
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
              value: _feedTds,
              min: 50,
              max: 1000,
              divisions: 95,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _feedTds = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsCard(ZaftoColors colors) {
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
            'OPERATING CONDITIONS',
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
              Text('Water Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_temperature.toStringAsFixed(0)}°F (${_tempFactor.toStringAsFixed(2)}x)',
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
              value: _temperature,
              min: 40,
              max: 90,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _temperature = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Feed Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_feedPressure.toStringAsFixed(0)} PSI (${_pressureFactor.toStringAsFixed(2)}x)',
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
              value: _feedPressure,
              min: 30,
              max: 80,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _feedPressure = v);
              },
            ),
          ),
          Text(
            'Booster pump needed below 40 PSI',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(ZaftoColors colors) {
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
              Icon(LucideIcons.wrench, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Filter Replacement Schedule',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMaintenanceRow(colors, 'Sediment Pre-Filter', '6-12 months'),
          _buildMaintenanceRow(colors, 'Carbon Pre-Filter', '6-12 months'),
          _buildMaintenanceRow(colors, 'RO Membrane', '2-3 years'),
          _buildMaintenanceRow(colors, 'Carbon Post-Filter', '12 months'),
          _buildMaintenanceRow(colors, 'Remineralization', '12 months'),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRow(ZaftoColors colors, String item, String interval) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Text(interval, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
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
                'NSF/ANSI 58',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• TDS reduction ≥ 75% required\n'
            '• Air gap or check valve on drain\n'
            '• Dedicated faucet required\n'
            '• Drain connection per local code\n'
            '• Storage tank pressure 7-8 PSI\n'
            '• Consider remineralization post-RO',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
