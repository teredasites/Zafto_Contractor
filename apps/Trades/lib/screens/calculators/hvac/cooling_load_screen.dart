import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cooling Load Calculator - Design System v2.6
///
/// Calculates cooling load for residential and light commercial buildings.
/// Uses simplified Manual J methodology.
///
/// References: ACCA Manual J, ASHRAE
class CoolingLoadScreen extends ConsumerStatefulWidget {
  const CoolingLoadScreen({super.key});
  @override
  ConsumerState<CoolingLoadScreen> createState() => _CoolingLoadScreenState();
}

class _CoolingLoadScreenState extends ConsumerState<CoolingLoadScreen> {
  // Square footage
  double _sqft = 2000;

  // Climate zone
  String _climateZone = 'zone_4';

  // Insulation level
  String _insulationLevel = 'average';

  // Sun exposure
  String _sunExposure = 'average';

  // Occupants
  int _occupants = 4;

  static const Map<String, ({String desc, double coolingFactor})> _climateZones = {
    'zone_1': (desc: 'Zone 1 (Hot)', coolingFactor: 35),
    'zone_2': (desc: 'Zone 2 (Hot-Humid)', coolingFactor: 32),
    'zone_3': (desc: 'Zone 3 (Warm)', coolingFactor: 28),
    'zone_4': (desc: 'Zone 4 (Mixed)', coolingFactor: 24),
    'zone_5': (desc: 'Zone 5 (Cool)', coolingFactor: 20),
    'zone_6': (desc: 'Zone 6 (Cold)', coolingFactor: 18),
    'zone_7': (desc: 'Zone 7 (Very Cold)', coolingFactor: 15),
  };

  static const Map<String, ({String desc, double factor})> _insulationLevels = {
    'poor': (desc: 'Poor', factor: 1.25),
    'average': (desc: 'Average', factor: 1.0),
    'good': (desc: 'Good', factor: 0.85),
    'excellent': (desc: 'Excellent', factor: 0.7),
  };

  static const Map<String, ({String desc, double factor})> _sunExposures = {
    'shaded': (desc: 'Well Shaded', factor: 0.85),
    'average': (desc: 'Average', factor: 1.0),
    'sunny': (desc: 'Sunny/West Facing', factor: 1.15),
    'extreme': (desc: 'Extreme Sun', factor: 1.3),
  };

  // Base cooling load (BTU/hr)
  double get _baseLoad {
    final zone = _climateZones[_climateZone];
    return _sqft * (zone?.coolingFactor ?? 24);
  }

  // Occupant heat gain (400 BTU/hr sensible per person typical)
  double get _occupantLoad => _occupants * 400;

  // Adjusted cooling load
  double get _adjustedLoad {
    final insulation = _insulationLevels[_insulationLevel];
    final sun = _sunExposures[_sunExposure];

    return (_baseLoad * (insulation?.factor ?? 1.0) * (sun?.factor ?? 1.0)) + _occupantLoad;
  }

  // AC tonnage (12,000 BTU/ton)
  double get _tonnage => _adjustedLoad / 12000;

  // Recommended AC size
  String get _acSize {
    final tons = _tonnage;
    if (tons <= 1.75) return '1.5 ton';
    if (tons <= 2.25) return '2 ton';
    if (tons <= 2.75) return '2.5 ton';
    if (tons <= 3.25) return '3 ton';
    if (tons <= 3.75) return '3.5 ton';
    if (tons <= 4.25) return '4 ton';
    if (tons <= 5.25) return '5 ton';
    return '${tons.ceil()} ton';
  }

  // BTU per square foot
  double get _btuPerSqft => _adjustedLoad / _sqft;

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
          'Cooling Load Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSquareFootageCard(colors),
          const SizedBox(height: 16),
          _buildClimateCard(colors),
          const SizedBox(height: 16),
          _buildInsulationCard(colors),
          const SizedBox(height: 16),
          _buildSunCard(colors),
          const SizedBox(height: 16),
          _buildOccupantsCard(colors),
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
            _acSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Air Conditioner Size',
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
                _buildResultRow(colors, 'Cooling Load', '${(_adjustedLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tonnage', '${_tonnage.toStringAsFixed(2)} tons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU/sq ft', '${_btuPerSqft.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Occupant Load', '${_occupantLoad.toStringAsFixed(0)} BTU/hr'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareFootageCard(ZaftoColors colors) {
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
            'CONDITIONED AREA',
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
              Text('Square Footage', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_sqft.toStringAsFixed(0)} sq ft',
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
              value: _sqft,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _sqft = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1000, 1500, 2000, 2500, 3000].map((sf) {
              final isSelected = (_sqft - sf).abs() < 100;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sqft = sf.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$sf',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _climateZones.entries.map((entry) {
              final isSelected = _climateZone == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _climateZone = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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

  Widget _buildInsulationCard(ZaftoColors colors) {
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
            'INSULATION LEVEL',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _insulationLevels.entries.map((entry) {
              final isSelected = _insulationLevel == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _insulationLevel = entry.key);
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
                            fontSize: 11,
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

  Widget _buildSunCard(ZaftoColors colors) {
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
            'SUN EXPOSURE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _sunExposures.entries.map((entry) {
              final isSelected = _sunExposure == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sunExposure = entry.key);
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
                            fontSize: 10,
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

  Widget _buildOccupantsCard(ZaftoColors colors) {
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
            'OCCUPANTS',
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
              Text('Number of People', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
              max: 12,
              divisions: 11,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupants = v.round());
              },
            ),
          ),
          Text(
            'Each person adds ~400 BTU/hr',
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
              Icon(LucideIcons.snowflake, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ACCA Manual J',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Full Manual J for permit\n'
            '• Sensible + latent loads\n'
            '• Avoid oversizing (short cycling)\n'
            '• Consider dehumidification\n'
            '• Account for duct losses\n'
            '• Design outdoor temp from Manual J',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
