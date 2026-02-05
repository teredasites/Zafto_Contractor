import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Refrigerant Charge Calculator - Design System v2.6
///
/// Calculates additional refrigerant charge for line set lengths.
/// Covers common refrigerants and line sizes.
///
/// References: Manufacturer specifications, EPA 608
class RefrigerantChargeScreen extends ConsumerStatefulWidget {
  const RefrigerantChargeScreen({super.key});
  @override
  ConsumerState<RefrigerantChargeScreen> createState() => _RefrigerantChargeScreenState();
}

class _RefrigerantChargeScreenState extends ConsumerState<RefrigerantChargeScreen> {
  // Refrigerant type
  String _refrigerantType = 'r410a';

  // Line set length (feet)
  double _lineLength = 50;

  // Factory charge line length (feet)
  double _factoryLength = 25;

  // Liquid line size (inches)
  String _liquidLineSize = '0.375';

  static const Map<String, ({String desc, String gwp, bool phaseOut})> _refrigerantTypes = {
    'r410a': (desc: 'R-410A', gwp: '2088', phaseOut: true),
    'r32': (desc: 'R-32', gwp: '675', phaseOut: false),
    'r454b': (desc: 'R-454B', gwp: '466', phaseOut: false),
    'r22': (desc: 'R-22 (Legacy)', gwp: '1810', phaseOut: true),
    'r134a': (desc: 'R-134a', gwp: '1430', phaseOut: true),
  };

  // Charge per foot (oz/ft) based on liquid line size
  static const Map<String, double> _chargeRates = {
    '0.25': 0.2,    // 1/4" liquid line
    '0.3125': 0.3,  // 5/16" liquid line
    '0.375': 0.6,   // 3/8" liquid line
    '0.5': 1.0,     // 1/2" liquid line
    '0.625': 1.5,   // 5/8" liquid line
  };

  static const Map<String, String> _lineSizeLabels = {
    '0.25': '¼\"',
    '0.3125': '5/16\"',
    '0.375': '⅜\"',
    '0.5': '½\"',
    '0.625': '⅝\"',
  };

  // Additional line length beyond factory
  double get _additionalLength => (_lineLength - _factoryLength).clamp(0, double.infinity);

  // Charge rate
  double get _chargeRate => _chargeRates[_liquidLineSize] ?? 0.6;

  // Additional charge needed (oz)
  double get _additionalCharge => _additionalLength * _chargeRate;

  // Convert to pounds
  double get _chargePounds => _additionalCharge / 16;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final refrigerant = _refrigerantTypes[_refrigerantType];

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
          'Refrigerant Charge',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildRefrigerantCard(colors),
          const SizedBox(height: 16),
          _buildLineLengthCard(colors),
          const SizedBox(height: 16),
          _buildLineSizeCard(colors),
          if (refrigerant?.phaseOut ?? false) ...[
            const SizedBox(height: 16),
            _buildPhaseOutWarning(colors),
          ],
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
            '${_additionalCharge.toStringAsFixed(1)} oz',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Additional Charge',
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
                _buildResultRow(colors, 'Refrigerant', _refrigerantTypes[_refrigerantType]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Liquid Line', _lineSizeLabels[_liquidLineSize] ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Length', '${_lineLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Factory Charge', '${_factoryLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Additional', '${_additionalLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Charge Rate', '${_chargeRate.toStringAsFixed(1)} oz/ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total (lbs)', '${_chargePounds.toStringAsFixed(2)} lbs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefrigerantCard(ZaftoColors colors) {
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
            'REFRIGERANT TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._refrigerantTypes.entries.map((entry) {
            final isSelected = _refrigerantType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _refrigerantType = entry.key);
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
                        'GWP: ${entry.value.gwp}',
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

  Widget _buildLineLengthCard(ZaftoColors colors) {
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
            'LINE SET LENGTH',
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
              Text('Total Line Length', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_lineLength.toStringAsFixed(0)} ft',
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
              value: _lineLength,
              min: 10,
              max: 150,
              divisions: 28,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _lineLength = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Factory Charge Length', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_factoryLength.toStringAsFixed(0)} ft',
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
              value: _factoryLength,
              min: 15,
              max: 50,
              divisions: 7,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _factoryLength = v);
              },
            ),
          ),
          Text(
            'Check equipment data plate for factory charge length',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLineSizeCard(ZaftoColors colors) {
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
            'LIQUID LINE SIZE',
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
            children: _lineSizeLabels.entries.map((entry) {
              final isSelected = _liquidLineSize == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _liquidLineSize = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPhaseOutWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phase-Out Refrigerant',
                  style: TextStyle(color: colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'This refrigerant is being phased out due to high GWP. Consider low-GWP alternatives for new installations.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
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
              Icon(LucideIcons.gauge, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'EPA Section 608',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• EPA 608 certification required\n'
            '• Verify manufacturer charge tables\n'
            '• Weigh-in method preferred\n'
            '• Check subcooling/superheat\n'
            '• Document all refrigerant use\n'
            '• Recover before service',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
