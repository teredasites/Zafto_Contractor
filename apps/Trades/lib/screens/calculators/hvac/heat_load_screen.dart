import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Heat Load Calculator - Design System v2.6
///
/// Calculates heating load for residential and light commercial buildings.
/// Uses simplified Manual J methodology.
///
/// References: ACCA Manual J, ASHRAE
class HeatLoadScreen extends ConsumerStatefulWidget {
  const HeatLoadScreen({super.key});
  @override
  ConsumerState<HeatLoadScreen> createState() => _HeatLoadScreenState();
}

class _HeatLoadScreenState extends ConsumerState<HeatLoadScreen> {
  // Square footage
  double _sqft = 2000;

  // Ceiling height (feet)
  double _ceilingHeight = 8;

  // Climate zone
  String _climateZone = 'zone_4';

  // Insulation level
  String _insulationLevel = 'average';

  // Window percentage
  double _windowPercent = 15;

  static const Map<String, ({String desc, double heatingFactor})> _climateZones = {
    'zone_1': (desc: 'Zone 1 (Hot)', heatingFactor: 20),
    'zone_2': (desc: 'Zone 2 (Hot-Humid)', heatingFactor: 25),
    'zone_3': (desc: 'Zone 3 (Warm)', heatingFactor: 30),
    'zone_4': (desc: 'Zone 4 (Mixed)', heatingFactor: 40),
    'zone_5': (desc: 'Zone 5 (Cool)', heatingFactor: 50),
    'zone_6': (desc: 'Zone 6 (Cold)', heatingFactor: 55),
    'zone_7': (desc: 'Zone 7 (Very Cold)', heatingFactor: 60),
  };

  static const Map<String, ({String desc, double factor})> _insulationLevels = {
    'poor': (desc: 'Poor (Older home)', factor: 1.3),
    'average': (desc: 'Average (Code min)', factor: 1.0),
    'good': (desc: 'Good (Above code)', factor: 0.85),
    'excellent': (desc: 'Excellent (High-perf)', factor: 0.7),
  };

  // Total volume
  double get _volume => _sqft * _ceilingHeight;

  // Base heat load (BTU/hr)
  double get _baseLoad {
    final zone = _climateZones[_climateZone];
    return _sqft * (zone?.heatingFactor ?? 40);
  }

  // Adjusted heat load
  double get _adjustedLoad {
    final insulation = _insulationLevels[_insulationLevel];
    final insulationFactor = insulation?.factor ?? 1.0;

    // Window adjustment (more windows = more heat loss)
    final windowFactor = 1 + ((_windowPercent - 15) * 0.02);

    // Ceiling height adjustment
    final heightFactor = _ceilingHeight / 8;

    return _baseLoad * insulationFactor * windowFactor * heightFactor;
  }

  // Furnace size recommendation (BTU input)
  int get _furnaceSize {
    // Add 20% safety factor, round to common sizes
    final needed = _adjustedLoad * 1.2;
    final sizes = [40000, 60000, 80000, 100000, 120000, 140000];
    return sizes.firstWhere((s) => s >= needed, orElse: () => 140000);
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
          'Heat Load Calculator',
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
          _buildWindowCard(colors),
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
            '${(_adjustedLoad / 1000).toStringAsFixed(1)}K',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'BTU/hr Heat Load',
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
                _buildResultRow(colors, 'Square Footage', '${_sqft.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Volume', '${_volume.toStringAsFixed(0)} cu ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU/sq ft', '${_btuPerSqft.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Furnace Size', '${_furnaceSize ~/ 1000}K BTU input'),
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
            'BUILDING SIZE',
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ceiling Height', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_ceilingHeight.toStringAsFixed(0)} ft',
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
              value: _ceilingHeight,
              min: 7,
              max: 14,
              divisions: 14,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ceilingHeight = v);
              },
            ),
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
                        '${entry.value.heatingFactor.toStringAsFixed(0)} BTU/sf',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _insulationLevels.entries.map((entry) {
              final isSelected = _insulationLevel == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _insulationLevel = entry.key);
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

  Widget _buildWindowCard(ZaftoColors colors) {
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
            'WINDOW AREA',
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
              Text('% of Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_windowPercent.toStringAsFixed(0)}%',
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
              value: _windowPercent,
              min: 5,
              max: 40,
              divisions: 35,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _windowPercent = v);
              },
            ),
          ),
          Text(
            'Typical: 15% of floor area',
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
                'ACCA Manual J',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Full Manual J for permit\n'
            '• Consider duct losses (10-30%)\n'
            '• Verify design temperature\n'
            '• Account for all heat sources\n'
            '• Right-size equipment\n'
            '• Avoid oversizing',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
