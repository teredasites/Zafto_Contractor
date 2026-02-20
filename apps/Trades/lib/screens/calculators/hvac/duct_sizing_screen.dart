import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Duct Sizing Calculator - Design System v2.6
///
/// Sizes supply and return ducts based on CFM requirements.
/// Calculates round and rectangular equivalents.
///
/// References: ACCA Manual D, SMACNA
class DuctSizingScreen extends ConsumerStatefulWidget {
  const DuctSizingScreen({super.key});
  @override
  ConsumerState<DuctSizingScreen> createState() => _DuctSizingScreenState();
}

class _DuctSizingScreenState extends ConsumerState<DuctSizingScreen> {
  // CFM (cubic feet per minute)
  double _cfm = 400;

  // Friction rate (inches w.c. per 100 ft)
  double _frictionRate = 0.08;

  // Duct type
  String _ductType = 'supply';

  // Maximum velocity
  String _velocityClass = 'residential';

  static const Map<String, ({String desc, int maxVelocity})> _velocityClasses = {
    'residential': (desc: 'Residential', maxVelocity: 900),
    'commercial': (desc: 'Commercial', maxVelocity: 1200),
    'industrial': (desc: 'Industrial', maxVelocity: 1800),
  };

  static const Map<String, ({String desc, double factor})> _ductTypes = {
    'supply': (desc: 'Supply Duct', factor: 1.0),
    'return': (desc: 'Return Duct', factor: 1.2),
    'exhaust': (desc: 'Exhaust Duct', factor: 1.0),
    'outside_air': (desc: 'Outside Air', factor: 1.0),
  };

  // Round duct diameter (inches)
  double get _roundDiameter {
    // ASHRAE-derived friction chart regression for round galvanized steel duct
    // Standard air (70°F, sea level), absolute roughness ε = 0.0003 ft
    // Relationship: Δpf = 0.09527 × CFM^1.9 / D^5.02
    // Solved for D: D_inches = (0.09527 × CFM^1.9 / FR)^(1/5.02)
    // Validated against ASHRAE duct friction chart data points:
    //   200 CFM @ 0.08 → 7.7" (chart: ~8")
    //   400 CFM @ 0.08 → 10.0" (chart: ~10")
    //   600 CFM @ 0.08 → 11.6" (chart: ~12")
    //  1000 CFM @ 0.08 → 14.0" (chart: ~14")
    final factor = _ductTypes[_ductType]?.factor ?? 1.0;
    final adjustedCfm = _cfm * factor;

    final d = math.pow(
      0.09527 * math.pow(adjustedCfm, 1.9) / _frictionRate,
      1.0 / 5.02,
    ).toDouble();
    return (d * 10).roundToDouble() / 10;
  }

  // Actual velocity (FPM)
  double get _velocity {
    final area = 3.14159 * (_roundDiameter / 24) * (_roundDiameter / 24); // sq ft
    return _cfm / area;
  }

  // Rectangular equivalents (common sizes)
  Map<String, String> get _rectangularSizes {
    final d = _roundDiameter;
    // Equivalent area = π × (D/2)² = W × H
    final area = 3.14159 * (d / 2) * (d / 2);

    final sizes = <String, String>{};

    // Find common rectangular sizes with same area ±10%
    final commonWidths = [6, 8, 10, 12, 14, 16, 18, 20, 24, 30];
    for (final w in commonWidths) {
      final h = (area / w).round();
      if (h >= 4 && h <= 24) {
        sizes['${w}\" × ${h}\"'] = '${(w * h / area * 100).toStringAsFixed(0)}%';
      }
    }

    return sizes;
  }

  // Standard round duct size
  int get _standardRound {
    final sizes = [4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24];
    return sizes.firstWhere((s) => s >= _roundDiameter, orElse: () => 24);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final maxVel = _velocityClasses[_velocityClass]?.maxVelocity ?? 900;
    final velocityOk = _velocity <= maxVel;

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
          'Duct Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, velocityOk),
          const SizedBox(height: 16),
          _buildCfmCard(colors),
          const SizedBox(height: 16),
          _buildDuctTypeCard(colors),
          const SizedBox(height: 16),
          _buildVelocityCard(colors),
          const SizedBox(height: 16),
          _buildFrictionCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, bool velocityOk) {
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
            '$_standardRound\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Round Duct Diameter',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!velocityOk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Velocity exceeds limit - upsize duct',
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ],
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
                _buildResultRow(colors, 'Airflow', '${_cfm.toStringAsFixed(0)} CFM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Calculated Dia.', '${_roundDiameter.toStringAsFixed(1)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Velocity', '${_velocity.toStringAsFixed(0)} FPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Friction Rate', '${_frictionRate.toStringAsFixed(2)}\" w.c./100ft'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECTANGULAR EQUIVALENTS',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ..._rectangularSizes.entries.take(4).map((entry) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _buildResultRow(colors, entry.key, entry.value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCfmCard(ZaftoColors colors) {
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
            'AIRFLOW (CFM)',
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
              Text('CFM Required', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_cfm.toStringAsFixed(0)} CFM',
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
              value: _cfm,
              min: 50,
              max: 2000,
              divisions: 39,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _cfm = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [100, 200, 400, 600, 800, 1000].map((cfm) {
              final isSelected = (_cfm - cfm).abs() < 25;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cfm = cfm.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$cfm',
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

  Widget _buildDuctTypeCard(ZaftoColors colors) {
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
            'DUCT TYPE',
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
            children: _ductTypes.entries.map((entry) {
              final isSelected = _ductType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _ductType = entry.key);
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

  Widget _buildVelocityCard(ZaftoColors colors) {
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
            'APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._velocityClasses.entries.map((entry) {
            final isSelected = _velocityClass == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _velocityClass = entry.key);
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
                        '≤${entry.value.maxVelocity} FPM',
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

  Widget _buildFrictionCard(ZaftoColors colors) {
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
            'FRICTION RATE',
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
              Text('in. w.c. per 100 ft', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                _frictionRate.toStringAsFixed(2),
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
              value: _frictionRate,
              min: 0.04,
              max: 0.15,
              divisions: 22,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _frictionRate = v);
              },
            ),
          ),
          Text(
            'Typical residential: 0.08\" w.c./100ft',
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
              Icon(LucideIcons.wind, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ACCA Manual D',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Size for available static\n'
            '• Account for fittings\n'
            '• Verify velocity limits\n'
            '• Balance all branches\n'
            '• Return ≥ supply area\n'
            '• Support per SMACNA',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
