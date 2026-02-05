import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pressure Conversion Calculator - Design System v2.6
///
/// Converts between pressure units used in plumbing.
/// PSI, kPa, bar, inches of water column, feet of head.
///
/// References: Standard Conversion Factors
class PressureConversionScreen extends ConsumerStatefulWidget {
  const PressureConversionScreen({super.key});
  @override
  ConsumerState<PressureConversionScreen> createState() => _PressureConversionScreenState();
}

class _PressureConversionScreenState extends ConsumerState<PressureConversionScreen> {
  double _inputValue = 50;
  String _inputUnit = 'psi';

  static const Map<String, ({String name, String symbol, double toPsi})> _units = {
    'psi': (name: 'Pounds per Square Inch', symbol: 'PSI', toPsi: 1.0),
    'kpa': (name: 'Kilopascals', symbol: 'kPa', toPsi: 0.145038),
    'bar': (name: 'Bar', symbol: 'bar', toPsi: 14.5038),
    'atm': (name: 'Atmospheres', symbol: 'atm', toPsi: 14.696),
    'fth2o': (name: 'Feet of Water', symbol: 'ft H₂O', toPsi: 0.433),
    'inh2o': (name: 'Inches of Water Column', symbol: 'in WC', toPsi: 0.0361),
    'inhg': (name: 'Inches of Mercury', symbol: 'in Hg', toPsi: 0.4912),
    'mmhg': (name: 'Millimeters of Mercury', symbol: 'mmHg', toPsi: 0.01934),
  };

  double get _psiValue => _inputValue * (_units[_inputUnit]?.toPsi ?? 1.0);

  Map<String, double> get _allConversions {
    return Map.fromEntries(
      _units.entries.map((e) => MapEntry(e.key, _psiValue / e.value.toPsi))
    );
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
          'Pressure Conversion',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(colors),
          const SizedBox(height: 16),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildQuickReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INPUT VALUE',
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
              Text('Value', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_inputValue.toStringAsFixed(_inputValue == _inputValue.roundToDouble() ? 0 : 2)} ${_units[_inputUnit]?.symbol}',
                style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700),
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
              value: _inputValue.clamp(0.1, 500),
              min: 0.1,
              max: 500,
              divisions: 499,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _inputValue = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'INPUT UNIT',
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
            children: _units.entries.map((entry) {
              final isSelected = _inputUnit == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _inputUnit = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.symbol,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final conversions = _allConversions;

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
            'CONVERTED VALUES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._units.entries.map((entry) {
            final value = conversions[entry.key] ?? 0;
            final isInput = entry.key == _inputUnit;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.name,
                          style: TextStyle(
                            color: isInput ? colors.accentPrimary : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: isInput ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        Text(
                          entry.value.symbol,
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatValue(value),
                      style: TextStyle(
                        color: isInput ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 10000) {
      return value.toStringAsExponential(2);
    } else if (value >= 100) {
      return value.toStringAsFixed(1);
    } else if (value >= 1) {
      return value.toStringAsFixed(2);
    } else if (value >= 0.01) {
      return value.toStringAsFixed(4);
    } else {
      return value.toStringAsExponential(2);
    }
  }

  Widget _buildQuickReference(ZaftoColors colors) {
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
              Icon(LucideIcons.bookmark, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Quick Reference',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRefRow(colors, '1 PSI', '2.31 ft H₂O = 6.89 kPa'),
          _buildRefRow(colors, '1 bar', '14.5 PSI = 100 kPa'),
          _buildRefRow(colors, '1 atm', '14.7 PSI = 33.9 ft H₂O'),
          _buildRefRow(colors, '27.7 in WC', '1 PSI (gas pressure)'),
          const SizedBox(height: 8),
          Text(
            'Tip: 1 PSI ≈ 2.31 feet of head (water)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(left, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('=', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(right, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
