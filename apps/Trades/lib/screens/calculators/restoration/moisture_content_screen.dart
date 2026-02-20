import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Moisture Content Target Calculator
///
/// Calculates equilibrium moisture content (EMC) for wood and building
/// materials based on temperature and relative humidity. Used to determine
/// drying goals and verify when materials have reached acceptable levels.
///
/// EMC Formula: Hailwood-Horrobin equation (USDA Forest Products Lab)
/// References: USDA FPL-GTR-190, IICRC S500-2021
class MoistureContentScreen extends ConsumerStatefulWidget {
  const MoistureContentScreen({super.key});
  @override
  ConsumerState<MoistureContentScreen> createState() => _MoistureContentScreenState();
}

class _MoistureContentScreenState extends ConsumerState<MoistureContentScreen> {
  double _temperatureF = 72;
  double _relativeHumidity = 50;
  String _materialType = 'softwood';
  double _currentMC = 20;

  static const Map<String, ({String desc, double dryTarget, double wetThreshold, String detail})> _materials = {
    'softwood': (
      desc: 'Softwood (Pine, Fir, Spruce)',
      dryTarget: 12.0,
      wetThreshold: 19.0,
      detail: 'Framing lumber, subfloor, sheathing',
    ),
    'hardwood': (
      desc: 'Hardwood (Oak, Maple, Cherry)',
      dryTarget: 8.0,
      wetThreshold: 16.0,
      detail: 'Hardwood flooring, trim, cabinets',
    ),
    'plywood': (
      desc: 'Plywood / OSB',
      dryTarget: 10.0,
      wetThreshold: 18.0,
      detail: 'Subfloor, wall sheathing, roof deck',
    ),
    'drywall': (
      desc: 'Drywall (Gypsum)',
      dryTarget: 0.5,
      wetThreshold: 1.0,
      detail: 'Wall/ceiling board — replace if sustained wet',
    ),
    'concrete': (
      desc: 'Concrete / Masonry',
      dryTarget: 3.0,
      wetThreshold: 5.0,
      detail: 'Slab, foundation, CMU block walls',
    ),
    'insulation': (
      desc: 'Insulation (Fiberglass)',
      dryTarget: 0.0,
      wetThreshold: 1.0,
      detail: 'Replace if saturated — cannot be effectively dried',
    ),
  };

  // Hailwood-Horrobin EMC equation (USDA FPL-GTR-190)
  // This is the industry standard for wood EMC calculation
  double get _emcPercent {
    final t = (_temperatureF - 32) * 5 / 9; // °C
    final h = _relativeHumidity / 100; // decimal

    // Coefficients per Hailwood-Horrobin
    final w = 330 + 0.452 * t + 0.00415 * t * t;
    final k = 0.791 + 0.000463 * t - 0.000000844 * t * t;
    final k1 = 6.34 + 0.000775 * t - 0.0000935 * t * t;
    final k2 = 1.09 + 0.0284 * t - 0.0000904 * t * t;

    final kh = k * h;

    // Avoid division by zero
    if (kh >= 1.0) return 30.0; // fiber saturation point
    if (h <= 0) return 0.0;

    final emc = (1800 / w) *
        ((k1 * kh / (1 + k1 * kh)) +
            (k2 * kh + 2 * k1 * k2 * kh * kh) /
                (1 + k1 * kh + k1 * k2 * kh * kh));

    return math.max(0, math.min(30, emc));
  }

  // Material-specific dry target
  double get _dryTarget => _materials[_materialType]?.dryTarget ?? 12.0;

  // Material-specific wet threshold
  double get _wetThreshold => _materials[_materialType]?.wetThreshold ?? 19.0;

  // Is current MC acceptable?
  String get _mcStatus {
    if (_currentMC <= _dryTarget) return 'DRY';
    if (_currentMC <= _wetThreshold) return 'ACCEPTABLE';
    return 'WET';
  }

  // Wet-to-dry ratio
  double get _wdr {
    if (_dryTarget <= 0) return _currentMC > 0 ? double.infinity : 1.0;
    return _currentMC / _dryTarget;
  }

  // How much moisture needs to be removed (relative)
  double get _moistureToRemove {
    if (_currentMC <= _dryTarget) return 0;
    return _currentMC - _dryTarget;
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
          'Moisture Content Target',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildConditionsCard(colors),
          const SizedBox(height: 16),
          _buildCurrentMCCard(colors),
          const SizedBox(height: 16),
          _buildMCGuide(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = switch (_mcStatus) {
      'DRY' => Colors.green,
      'ACCEPTABLE' => Colors.orange,
      'WET' => Colors.red,
      _ => colors.accentPrimary,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '${_emcPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'EMC Target',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: colors.borderSubtle),
              Column(
                children: [
                  Text(
                    '${_currentMC.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Current MC',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _mcStatus,
              style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w700),
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
                _buildResultRow(colors, 'Dry Target', '${_dryTarget.toStringAsFixed(1)}% MC'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Wet Threshold', '${_wetThreshold.toStringAsFixed(1)}% MC'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'EMC at Conditions', '${_emcPercent.toStringAsFixed(1)}% MC'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'WDR (Wet/Dry Ratio)', _wdr.isFinite ? _wdr.toStringAsFixed(2) : 'N/A'),
                const SizedBox(height: 10),
                _buildResultRow(
                  colors,
                  'Moisture to Remove',
                  _moistureToRemove > 0 ? '${_moistureToRemove.toStringAsFixed(1)}% MC' : 'None — at target',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ZaftoColors colors) {
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
            'MATERIAL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._materials.entries.map((entry) {
            final isSelected = _materialType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _materialType = entry.key);
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.desc,
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.value.detail,
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.value.dryTarget}%',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
            'AMBIENT CONDITIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Used to calculate Equilibrium Moisture Content (EMC)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_temperatureF.toStringAsFixed(0)}°F',
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
              value: _temperatureF,
              min: 40,
              max: 120,
              divisions: 80,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _temperatureF = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relative Humidity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_relativeHumidity.toStringAsFixed(0)}%',
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
              value: _relativeHumidity,
              min: 5,
              max: 100,
              divisions: 95,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _relativeHumidity = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMCCard(ZaftoColors colors) {
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
            'CURRENT MOISTURE READING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the pin or pinless meter reading from the affected material',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Moisture Content', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_currentMC.toStringAsFixed(1)}%',
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
              value: _currentMC,
              min: 0,
              max: 40,
              divisions: 80,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _currentMC = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCGuide(ZaftoColors colors) {
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
            'MOISTURE CONTENT TARGETS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildMCRow(colors, 'Softwood lumber', '6-12%', '> 19%'),
          const SizedBox(height: 6),
          _buildMCRow(colors, 'Hardwood flooring', '6-8%', '> 16%'),
          const SizedBox(height: 6),
          _buildMCRow(colors, 'Plywood/OSB', '8-10%', '> 18%'),
          const SizedBox(height: 6),
          _buildMCRow(colors, 'Drywall', '< 0.5%', '> 1%'),
          const SizedBox(height: 6),
          _buildMCRow(colors, 'Concrete', '< 3%', '> 5%'),
          const SizedBox(height: 12),
          Text(
            'Wood fiber saturation point: ~28-30% MC. Above this, free water is present.',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMCRow(ZaftoColors colors, String material, String dry, String wet) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(material, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            dry,
            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            wet,
            style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
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
              Icon(LucideIcons.bookOpen, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'USDA FPL / IICRC S500',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• EMC: Hailwood-Horrobin equation (USDA FPL-GTR-190)\n'
            '• WDR > 1.0 = material still above dry target\n'
            '• Pin meter: correction for species and temperature\n'
            '• Compare affected vs unaffected (same material)\n'
            '• Drywall > 1% MC: consider replacement\n'
            '• Wood > 19% MC: risk of mold growth (IICRC S520)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
