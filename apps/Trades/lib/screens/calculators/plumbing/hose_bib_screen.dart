import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Hose Bib / Sillcock Calculator - Design System v2.6
///
/// Calculates hose bib requirements, flow rates, and frost protection.
/// Covers residential and commercial exterior faucets.
///
/// References: IPC 2024, Manufacturer Guidelines
class HoseBibScreen extends ConsumerStatefulWidget {
  const HoseBibScreen({super.key});
  @override
  ConsumerState<HoseBibScreen> createState() => _HoseBibScreenState();
}

class _HoseBibScreenState extends ConsumerState<HoseBibScreen> {
  // Supply pressure (PSI)
  double _pressure = 50;

  // Hose length (feet)
  double _hoseLength = 50;

  // Hose diameter
  String _hoseDiameter = '5/8';

  // Type of sillcock
  String _sillcockType = 'frost_free';

  // Climate zone
  String _climate = 'moderate';

  static const Map<String, ({String desc, double flowAt50psi})> _hoseDiameters = {
    '1/2': (desc: '½\" Garden Hose', flowAt50psi: 9),
    '5/8': (desc: '⅝\" Garden Hose', flowAt50psi: 17),
    '3/4': (desc: '¾\" Garden Hose', flowAt50psi: 23),
  };

  static const Map<String, ({String desc, int minLength, bool frostProtection})> _sillcockTypes = {
    'standard': (desc: 'Standard Hose Bib', minLength: 0, frostProtection: false),
    'frost_free': (desc: 'Frost-Free Sillcock', minLength: 6, frostProtection: true),
    'frost_free_12': (desc: 'Frost-Free 12\"', minLength: 12, frostProtection: true),
    'frost_free_14': (desc: 'Frost-Free 14\"', minLength: 14, frostProtection: true),
    'wall_hydrant': (desc: 'Wall Hydrant', minLength: 0, frostProtection: true),
  };

  static const Map<String, ({String desc, int minWallLength})> _climates = {
    'warm': (desc: 'Warm (No Freeze)', minWallLength: 0),
    'moderate': (desc: 'Moderate (Light Freeze)', minWallLength: 6),
    'cold': (desc: 'Cold (Hard Freeze)', minWallLength: 10),
    'severe': (desc: 'Severe (Deep Frost)', minWallLength: 14),
  };

  // Flow rate at end of hose (GPM)
  double get _flowRate {
    final baseFlow = _hoseDiameters[_hoseDiameter]?.flowAt50psi ?? 17;
    // Adjust for pressure (flow varies with sqrt of pressure ratio)
    final pressureRatio = _pressure / 50;
    final adjustedFlow = baseFlow * (pressureRatio > 0 ? pressureRatio.sqrt() : 0);
    // Reduce for hose length (friction loss)
    final lengthFactor = 1 - (_hoseLength / 500); // ~10% loss per 50 feet
    return (adjustedFlow * lengthFactor).clamp(0, 30);
  }

  // Pressure at end of hose
  double get _endPressure {
    // Simplified: ~2 PSI loss per 50 feet for 5/8" hose at moderate flow
    final loss = (_hoseLength / 50) * 2;
    return (_pressure - loss).clamp(0, _pressure);
  }

  // Recommended sillcock length
  String get _recommendedLength {
    final minLength = _climates[_climate]?.minWallLength ?? 6;
    if (minLength <= 0) return 'Standard OK';
    if (minLength <= 6) return '6\" minimum';
    if (minLength <= 10) return '10\" minimum';
    return '14\" minimum';
  }

  // Frost protection status
  bool get _hasFrostProtection => _sillcockTypes[_sillcockType]?.frostProtection ?? false;

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
          'Hose Bib Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildHoseCard(colors),
          const SizedBox(height: 16),
          _buildSillcockCard(colors),
          const SizedBox(height: 16),
          _buildClimateCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final needsFrostProtection = (_climates[_climate]?.minWallLength ?? 0) > 0;
    final hasFrost = _hasFrostProtection;

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
            '${_flowRate.toStringAsFixed(1)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'GPM at Hose End',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (needsFrostProtection && !hasFrost) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Frost protection recommended',
                    style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600),
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
                _buildResultRow(colors, 'Supply Pressure', '${_pressure.toStringAsFixed(0)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'End Pressure', '${_endPressure.toStringAsFixed(0)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hose Size', _hoseDiameters[_hoseDiameter]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Recommended', _recommendedLength),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureCard(ZaftoColors colors) {
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
            'SUPPLY PRESSURE',
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
              Text('Static Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
              min: 20,
              max: 80,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pressure = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoseCard(ZaftoColors colors) {
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
            'HOSE SPECIFICATIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _hoseDiameters.entries.map((entry) {
              final isSelected = _hoseDiameter == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hoseDiameter = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.key + '\"',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hose Length', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_hoseLength.toStringAsFixed(0)} ft',
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
              value: _hoseLength,
              min: 25,
              max: 200,
              divisions: 35,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _hoseLength = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSillcockCard(ZaftoColors colors) {
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
            'SILLCOCK TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._sillcockTypes.entries.map((entry) {
            final isSelected = _sillcockType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sillcockType = entry.key);
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
                      if (entry.value.frostProtection)
                        Icon(
                          LucideIcons.snowflake,
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          size: 14,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _climates.entries.map((entry) {
              final isSelected = _climate == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _climate = entry.key);
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
              Icon(LucideIcons.droplet, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC Requirements',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Vacuum breaker required (HVB)\n'
            '• ½\" minimum supply\n'
            '• Frost-free in freezing climates\n'
            '• Slope downward to exterior\n'
            '• Accessible shutoff valve\n'
            '• Consider key-operated for security',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double sqrt() => this <= 0 ? 0 : this.toDouble().pow(0.5);
  double pow(double exp) {
    if (this <= 0) return 0;
    double result = 1;
    double base = this;
    int n = (exp * 1000).round();
    for (int i = 0; i < 500; i++) {
      result = (result + base / result) / 2;
    }
    return result;
  }
}
