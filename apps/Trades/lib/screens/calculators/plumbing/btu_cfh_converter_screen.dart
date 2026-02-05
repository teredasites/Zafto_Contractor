import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// BTU to CFH Converter - Design System v2.6
///
/// Converts between BTU/hr, CFH, therms, and other gas units.
/// Essential for gas pipe sizing calculations.
///
/// References: IFGC 2024, NFPA 54
class BtuCfhConverterScreen extends ConsumerStatefulWidget {
  const BtuCfhConverterScreen({super.key});
  @override
  ConsumerState<BtuCfhConverterScreen> createState() => _BtuCfhConverterScreenState();
}

class _BtuCfhConverterScreenState extends ConsumerState<BtuCfhConverterScreen> {
  // Input value
  double _inputValue = 100000;

  // Input unit
  String _inputUnit = 'btu';

  // Gas type
  String _gasType = 'natural';

  // Units available
  static const List<({String value, String label, String desc})> _units = [
    (value: 'btu', label: 'BTU/hr', desc: 'British Thermal Units per hour'),
    (value: 'cfh', label: 'CFH', desc: 'Cubic Feet per Hour'),
    (value: 'therms', label: 'Therms/hr', desc: '100,000 BTU'),
    (value: 'mbtu', label: 'MBH', desc: '1,000 BTU/hr'),
    (value: 'kw', label: 'kW', desc: 'Kilowatts'),
  ];

  // Gas energy content
  static const Map<String, int> _btuPerCf = {
    'natural': 1000,
    'propane': 2500,
  };

  // Conversion factors to BTU/hr
  double _toBtu(double value, String unit) {
    switch (unit) {
      case 'btu':
        return value;
      case 'cfh':
        return value * (_btuPerCf[_gasType] ?? 1000);
      case 'therms':
        return value * 100000;
      case 'mbtu':
        return value * 1000;
      case 'kw':
        return value * 3412.14;
      default:
        return value;
    }
  }

  // Conversion from BTU/hr
  double _fromBtu(double btu, String unit) {
    switch (unit) {
      case 'btu':
        return btu;
      case 'cfh':
        return btu / (_btuPerCf[_gasType] ?? 1000);
      case 'therms':
        return btu / 100000;
      case 'mbtu':
        return btu / 1000;
      case 'kw':
        return btu / 3412.14;
      default:
        return btu;
    }
  }

  double get _btuValue => _toBtu(_inputValue, _inputUnit);

  Map<String, double> get _conversions {
    final btu = _btuValue;
    return {
      'btu': btu,
      'cfh': _fromBtu(btu, 'cfh'),
      'therms': _fromBtu(btu, 'therms'),
      'mbtu': _fromBtu(btu, 'mbtu'),
      'kw': _fromBtu(btu, 'kw'),
    };
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}k';
    } else if (value < 0.01) {
      return value.toStringAsExponential(2);
    } else if (value < 1) {
      return value.toStringAsFixed(4);
    } else {
      return value.toStringAsFixed(2);
    }
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
          'BTU / CFH Converter',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(colors),
          const SizedBox(height: 16),
          _buildGasTypeCard(colors),
          const SizedBox(height: 16),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildQuickReference(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
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
            children: [
              Expanded(
                child: Text(
                  _formatValue(_inputValue),
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _units.firstWhere((u) => u.value == _inputUnit).label,
                  style: TextStyle(
                    color: colors.isDark ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
            ),
            child: Slider(
              value: _inputValue.clamp(1, 1000000).toDouble(),
              min: 1,
              max: 1000000,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _units.map((unit) {
              final isSelected = _inputUnit == unit.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _inputUnit = unit.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unit.label,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
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

  Widget _buildGasTypeCard(ZaftoColors colors) {
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
            'GAS TYPE (FOR CFH CONVERSION)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gasType = 'natural');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _gasType == 'natural' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Natural Gas',
                          style: TextStyle(
                            color: _gasType == 'natural'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '1,000 BTU/CF',
                          style: TextStyle(
                            color: _gasType == 'natural'
                                ? (colors.isDark ? Colors.black54 : Colors.white70)
                                : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gasType = 'propane');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _gasType == 'propane' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Propane (LP)',
                          style: TextStyle(
                            color: _gasType == 'propane'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '2,500 BTU/CF',
                          style: TextStyle(
                            color: _gasType == 'propane'
                                ? (colors.isDark ? Colors.black54 : Colors.white70)
                                : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final conversions = _conversions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONVERSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._units.map((unit) {
            final value = conversions[unit.value] ?? 0;
            final isInput = unit.value == _inputUnit;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isInput
                    ? colors.accentPrimary.withValues(alpha: 0.1)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: isInput ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.label,
                          style: TextStyle(
                            color: isInput ? colors.accentPrimary : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          unit.desc,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 10,
                          ),
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
                        fontSize: 16,
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

  Widget _buildQuickReference(ZaftoColors colors) {
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
            'QUICK REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildRefRow(colors, '1 Therm', '100,000 BTU'),
          _buildRefRow(colors, '1 MBH', '1,000 BTU/hr'),
          _buildRefRow(colors, '1 kW', '3,412 BTU/hr'),
          _buildRefRow(colors, '1 HP (boiler)', '33,475 BTU/hr'),
          _buildRefRow(colors, '1 CF Natural Gas', '~1,000 BTU'),
          _buildRefRow(colors, '1 CF Propane', '~2,500 BTU'),
          _buildRefRow(colors, '1 gal Propane', '~91,500 BTU'),
        ],
      ),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            '=',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              right,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Gas Conversion Reference',
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
            '• BTU = British Thermal Unit\n'
            '• CFH = Cubic Feet per Hour\n'
            '• Appliance nameplate shows BTU input\n'
            '• CFH needed for gas pipe sizing\n'
            '• Local gas content may vary\n'
            '• Verify with utility company',
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
