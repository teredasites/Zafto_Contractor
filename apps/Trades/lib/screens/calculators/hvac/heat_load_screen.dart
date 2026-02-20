import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Heat Load Calculator - Design System v2.6
///
/// Calculates heating load for residential and light commercial buildings.
/// Uses simplified Manual J methodology with infiltration, duct losses,
/// and wall exposure factors.
///
/// References: ACCA Manual J, ASHRAE Fundamentals Ch. 17
class HeatLoadScreen extends ConsumerStatefulWidget {
  const HeatLoadScreen({super.key});
  @override
  ConsumerState<HeatLoadScreen> createState() => _HeatLoadScreenState();
}

class _HeatLoadScreenState extends ConsumerState<HeatLoadScreen> {
  double _sqft = 2000;
  double _ceilingHeight = 8;
  String _climateZone = 'zone_4';
  String _insulationLevel = 'average';
  double _windowPercent = 15;
  String _buildingTightness = 'average';
  String _ductLocation = 'unconditioned';
  int _exteriorWalls = 3;

  // Climate zones with design temperature differentials
  // ΔT = indoor 70°F minus 99% winter design outdoor temp per ASHRAE
  static const Map<String, ({String desc, double heatingFactor, double designDeltaT})> _climateZones = {
    'zone_1': (desc: 'Zone 1 (Hot)', heatingFactor: 20, designDeltaT: 28),
    'zone_2': (desc: 'Zone 2 (Hot-Humid)', heatingFactor: 25, designDeltaT: 34),
    'zone_3': (desc: 'Zone 3 (Warm)', heatingFactor: 30, designDeltaT: 41),
    'zone_4': (desc: 'Zone 4 (Mixed)', heatingFactor: 40, designDeltaT: 55),
    'zone_5': (desc: 'Zone 5 (Cool)', heatingFactor: 50, designDeltaT: 69),
    'zone_6': (desc: 'Zone 6 (Cold)', heatingFactor: 55, designDeltaT: 76),
    'zone_7': (desc: 'Zone 7 (Very Cold)', heatingFactor: 60, designDeltaT: 83),
  };

  static const Map<String, ({String desc, double factor})> _insulationLevels = {
    'poor': (desc: 'Poor (Older home)', factor: 1.3),
    'average': (desc: 'Average (Code min)', factor: 1.0),
    'good': (desc: 'Good (Above code)', factor: 0.85),
    'excellent': (desc: 'Excellent (High-perf)', factor: 0.7),
  };

  // Air changes per hour by building tightness
  // ASHRAE 62.2: typical residential 0.35 ACH minimum
  static const Map<String, ({String desc, double ach})> _tightnessLevels = {
    'tight': (desc: 'Tight (New/Sealed)', ach: 0.2),
    'average': (desc: 'Average', ach: 0.5),
    'leaky': (desc: 'Leaky (Older)', ach: 1.0),
    'very_leaky': (desc: 'Very Leaky (Pre-1970)', ach: 1.5),
  };

  // Duct loss factors per ACCA Manual D
  static const Map<String, ({String desc, double factor})> _ductLocations = {
    'conditioned': (desc: 'In Conditioned Space', factor: 0.0),
    'insulated': (desc: 'Insulated Unconditioned', factor: 0.10),
    'unconditioned': (desc: 'Uninsulated Attic/Crawl', factor: 0.25),
    'none': (desc: 'No Ducts (Mini-split)', factor: 0.0),
  };

  double get _volume => _sqft * _ceilingHeight;

  // Envelope heat loss: base BTU/sf × insulation × windows × height × wall exposure
  double get _envelopeLoad {
    final zone = _climateZones[_climateZone];
    final insulation = _insulationLevels[_insulationLevel];
    final heatingFactor = zone?.heatingFactor ?? 40;
    final insulationFactor = insulation?.factor ?? 1.0;
    final windowFactor = 1 + ((_windowPercent - 15) * 0.02);
    final heightFactor = _ceilingHeight / 8;
    final wallFactor = switch (_exteriorWalls) {
      1 => 0.85,
      2 => 0.90,
      3 => 1.0,
      4 => 1.15,
      _ => 1.0,
    };
    return _sqft * heatingFactor * insulationFactor * windowFactor * heightFactor * wallFactor;
  }

  // Infiltration heat loss: q = 0.018 × ACH × V × ΔT
  // 0.018 BTU/(ft³·°F·hr) = air density × specific heat / 60
  // Per ASHRAE Fundamentals Ch. 16 infiltration methodology
  double get _infiltrationLoad {
    final tightness = _tightnessLevels[_buildingTightness];
    final zone = _climateZones[_climateZone];
    final ach = tightness?.ach ?? 0.5;
    final deltaT = zone?.designDeltaT ?? 55;
    return 0.018 * ach * _volume * deltaT;
  }

  // Duct losses as percentage of subtotal
  double get _ductLoss {
    final duct = _ductLocations[_ductLocation];
    final factor = duct?.factor ?? 0.25;
    return (_envelopeLoad + _infiltrationLoad) * factor;
  }

  double get _totalLoad => _envelopeLoad + _infiltrationLoad + _ductLoss;

  // Furnace size: total + 20% safety factor, rounded to standard sizes
  int get _furnaceSize {
    final needed = _totalLoad * 1.2;
    final sizes = [40000, 60000, 80000, 100000, 120000, 140000];
    return sizes.firstWhere((s) => s >= needed, orElse: () => 140000);
  }

  double get _btuPerSqft => _totalLoad / _sqft;

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
          _buildTightnessCard(colors),
          const SizedBox(height: 16),
          _buildDuctCard(colors),
          const SizedBox(height: 16),
          _buildExteriorWallsCard(colors),
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
            '${(_totalLoad / 1000).toStringAsFixed(1)}K',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'BTU/hr Total Heat Load',
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
                _buildResultRow(colors, 'Envelope Loss', '${(_envelopeLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Infiltration Loss', '${(_infiltrationLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Duct Loss', '${(_ductLoss / 1000).toStringAsFixed(1)}K BTU/hr'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'Total Load', '${(_totalLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU/sq ft', '${_btuPerSqft.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Volume', '${_volume.toStringAsFixed(0)} cu ft'),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value.heatingFactor.toStringAsFixed(0)} BTU/sf',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'ΔT ${entry.value.designDeltaT.toStringAsFixed(0)}°F',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  Widget _buildTightnessCard(ZaftoColors colors) {
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
            'BUILDING TIGHTNESS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Air changes per hour (ACH) — affects infiltration heat loss',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          ..._tightnessLevels.entries.map((entry) {
            final isSelected = _buildingTightness == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _buildingTightness = entry.key);
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
                        '${entry.value.ach} ACH',
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

  Widget _buildDuctCard(ZaftoColors colors) {
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
            'DUCT LOCATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ducts in unconditioned space lose heat — per ACCA Manual D',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          ..._ductLocations.entries.map((entry) {
            final isSelected = _ductLocation == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _ductLocation = entry.key);
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
                        entry.value.factor > 0 ? '+${(entry.value.factor * 100).toStringAsFixed(0)}%' : '0%',
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

  Widget _buildExteriorWallsCard(ZaftoColors colors) {
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
            'EXTERIOR WALLS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'More exposed walls = more heat loss surface area',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: [1, 2, 3, 4].map((count) {
              final isSelected = _exteriorWalls == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _exteriorWalls = count);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            count == 1 ? 'wall' : 'walls',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
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
                'ACCA Manual J / ASHRAE',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Full Manual J required for permit\n'
            '• Includes envelope + infiltration + duct losses\n'
            '• Infiltration: q = 0.018 × ACH × V × ΔT\n'
            '• Verify 99% design outdoor temp for your city\n'
            '• Blower door test for actual ACH\n'
            '• Right-size equipment — avoid oversizing',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
