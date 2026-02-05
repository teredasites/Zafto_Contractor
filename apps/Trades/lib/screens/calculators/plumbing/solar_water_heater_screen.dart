import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Solar Water Heater Sizing Calculator - Design System v2.6
///
/// Sizes solar water heating systems for residential applications.
/// Determines collector area and storage tank requirements.
///
/// References: SRCC, ASHRAE 93
class SolarWaterHeaterScreen extends ConsumerStatefulWidget {
  const SolarWaterHeaterScreen({super.key});
  @override
  ConsumerState<SolarWaterHeaterScreen> createState() => _SolarWaterHeaterScreenState();
}

class _SolarWaterHeaterScreenState extends ConsumerState<SolarWaterHeaterScreen> {
  // Number of occupants
  int _occupants = 4;

  // Daily hot water usage per person (gallons)
  double _gallonsPerPerson = 20;

  // System type
  String _systemType = 'indirect';

  // Climate zone
  String _climateZone = 'moderate';

  // Roof orientation
  String _roofOrientation = 'south';

  static const Map<String, ({String desc, double solarFraction})> _systemTypes = {
    'direct': (desc: 'Direct (Active Open Loop)', solarFraction: 0.85),
    'indirect': (desc: 'Indirect (Active Closed Loop)', solarFraction: 0.75),
    'passive_its': (desc: 'Passive ICS (Batch)', solarFraction: 0.60),
    'thermosiphon': (desc: 'Thermosiphon', solarFraction: 0.70),
    'drainback': (desc: 'Drainback', solarFraction: 0.70),
  };

  static const Map<String, ({String desc, double sunHours, double factor})> _climateZones = {
    'hot': (desc: 'Hot/Sunny (AZ, FL)', sunHours: 6.0, factor: 1.0),
    'warm': (desc: 'Warm (CA, TX)', sunHours: 5.0, factor: 1.1),
    'moderate': (desc: 'Moderate (TN, NC)', sunHours: 4.5, factor: 1.2),
    'cool': (desc: 'Cool (NY, OH)', sunHours: 4.0, factor: 1.4),
    'cold': (desc: 'Cold (MN, MT)', sunHours: 3.5, factor: 1.6),
  };

  static const Map<String, ({String desc, double efficiency})> _orientations = {
    'south': (desc: 'True South (optimal)', efficiency: 1.0),
    'se_sw': (desc: 'SE or SW (±45°)', efficiency: 0.90),
    'east_west': (desc: 'East or West (±90°)', efficiency: 0.75),
  };

  double get _dailyDemand => _occupants * _gallonsPerPerson;
  double get _solarFraction => _systemTypes[_systemType]?.solarFraction ?? 0.75;
  double get _climateFactor => _climateZones[_climateZone]?.factor ?? 1.2;
  double get _orientationEfficiency => _orientations[_roofOrientation]?.efficiency ?? 1.0;
  double get _sunHours => _climateZones[_climateZone]?.sunHours ?? 4.5;

  // Tank size = 1.5-2x daily demand for solar systems
  int get _tankSize => ((_dailyDemand * 1.75) / 10).ceil() * 10; // Round to nearest 10

  // Collector area (sq ft) = Daily demand × 2.0 / (sunHours × efficiency × orientation)
  double get _collectorArea => (_dailyDemand * 2.0 * _climateFactor) / (_sunHours * _orientationEfficiency);

  // Number of 4x8 collectors (32 sq ft each)
  int get _collectorCount => (_collectorArea / 32).ceil();

  // Annual energy savings (therms for gas, kWh for electric)
  double get _annualSavingsGas => (_dailyDemand * 365 * 8.33 * 70 * _solarFraction) / 100000;
  double get _annualSavingsElectric => (_dailyDemand * 365 * 8.33 * 70 * _solarFraction) / 3412;

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
          'Solar Water Heater',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeCard(colors),
          const SizedBox(height: 16),
          _buildClimateCard(colors),
          const SizedBox(height: 16),
          _buildOrientationCard(colors),
          const SizedBox(height: 16),
          _buildSavingsCard(colors),
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
            '${_collectorArea.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Sq Ft Collector Area',
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
                _buildResultRow(colors, 'Daily Demand', '${_dailyDemand.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tank Size', '$_tankSize gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Collectors (4×8)', '$_collectorCount panels'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Solar Fraction', '${(_solarFraction * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Peak Sun Hours', '${_sunHours.toStringAsFixed(1)} hrs/day'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(ZaftoColors colors) {
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
            'HOUSEHOLD',
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
              Text('Number of Occupants', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_occupants',
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
              value: _occupants.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupants = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gallons per Person/Day', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_gallonsPerPerson.toStringAsFixed(0)}',
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
              value: _gallonsPerPerson,
              min: 10,
              max: 30,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _gallonsPerPerson = v);
              },
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
                        '${(entry.value.solarFraction * 100).toStringAsFixed(0)}%',
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

  Widget _buildClimateCard(ZaftoColors colors) {
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
            'CLIMATE ZONE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._climateZones.entries.map((entry) {
            final isSelected = _climateZone == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _climateZone = entry.key);
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
                        '${entry.value.sunHours} hrs',
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

  Widget _buildOrientationCard(ZaftoColors colors) {
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
            'ROOF ORIENTATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._orientations.entries.map((entry) {
            final isSelected = _roofOrientation == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _roofOrientation = entry.key);
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
                        '${(entry.value.efficiency * 100).toStringAsFixed(0)}%',
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

  Widget _buildSavingsCard(ZaftoColors colors) {
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
            'ESTIMATED ANNUAL SAVINGS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Gas Water Heater', '${_annualSavingsGas.toStringAsFixed(0)} therms'),
          _buildDimRow(colors, 'Electric Water Heater', '${_annualSavingsElectric.toStringAsFixed(0)} kWh'),
          const SizedBox(height: 8),
          Text(
            'Based on 70°F temperature rise, ${(_solarFraction * 100).toStringAsFixed(0)}% solar fraction',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
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
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
              Icon(LucideIcons.sun, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'System Notes',
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
            '• Indirect best for freezing climates\n'
            '• Direct only for non-freezing areas\n'
            '• Collector tilt = latitude for year-round\n'
            '• Backup heater always required\n'
            '• SRCC certified collectors required\n'
            '• Check local incentives/rebates',
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
