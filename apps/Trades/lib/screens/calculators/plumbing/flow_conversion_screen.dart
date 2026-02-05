import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Flow Rate Conversion Calculator - Design System v2.6
///
/// Converts between common flow rate units used in plumbing.
/// GPM, GPH, CFM, L/min, m³/hr
///
/// References: Standard Conversion Factors
class FlowConversionScreen extends ConsumerStatefulWidget {
  const FlowConversionScreen({super.key});
  @override
  ConsumerState<FlowConversionScreen> createState() => _FlowConversionScreenState();
}

class _FlowConversionScreenState extends ConsumerState<FlowConversionScreen> {
  double _inputValue = 10;
  String _inputUnit = 'gpm';

  static const Map<String, ({String name, String symbol, double toGpm})> _units = {
    'gpm': (name: 'Gallons per Minute', symbol: 'GPM', toGpm: 1.0),
    'gph': (name: 'Gallons per Hour', symbol: 'GPH', toGpm: 1/60),
    'lpm': (name: 'Liters per Minute', symbol: 'L/min', toGpm: 0.264172),
    'lph': (name: 'Liters per Hour', symbol: 'L/hr', toGpm: 0.264172/60),
    'm3h': (name: 'Cubic Meters per Hour', symbol: 'm³/hr', toGpm: 4.40287),
    'cfm': (name: 'Cubic Feet per Minute', symbol: 'CFM', toGpm: 7.48052),
    'cfs': (name: 'Cubic Feet per Second', symbol: 'CFS', toGpm: 448.831),
    'gpd': (name: 'Gallons per Day', symbol: 'GPD', toGpm: 1/1440),
  };

  // Convert input to GPM first, then to all other units
  double get _gpmValue => _inputValue * (_units[_inputUnit]?.toGpm ?? 1.0);

  Map<String, double> get _allConversions {
    return Map.fromEntries(
      _units.entries.map((e) => MapEntry(e.key, _gpmValue / e.value.toGpm))
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
          'Flow Rate Conversion',
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
              value: _inputValue.clamp(0.1, 1000),
              min: 0.1,
              max: 1000,
              divisions: 999,
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
          _buildRefRow(colors, '1 GPM', '60 GPH = 3.785 L/min'),
          _buildRefRow(colors, '1 CFM', '7.48 GPM (water)'),
          _buildRefRow(colors, '1 CFS', '448.8 GPM'),
          _buildRefRow(colors, '1 m³/hr', '4.4 GPM'),
          _buildRefRow(colors, '1 GPD', '0.000694 GPM'),
          const SizedBox(height: 8),
          Text(
            'Note: CFM to GPM assumes water at standard conditions',
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
          Text(right, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
