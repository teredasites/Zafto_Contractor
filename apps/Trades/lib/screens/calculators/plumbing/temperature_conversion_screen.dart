import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Temperature Conversion Calculator - Design System v2.6
///
/// Converts between temperature units with plumbing-specific references.
/// Includes common setpoint temperatures for plumbing systems.
///
/// References: Standard Conversion Formulas
class TemperatureConversionScreen extends ConsumerStatefulWidget {
  const TemperatureConversionScreen({super.key});
  @override
  ConsumerState<TemperatureConversionScreen> createState() => _TemperatureConversionScreenState();
}

class _TemperatureConversionScreenState extends ConsumerState<TemperatureConversionScreen> {
  double _inputValue = 120;
  String _inputUnit = 'f';

  // Convert to Fahrenheit as base
  double get _fahrenheit {
    switch (_inputUnit) {
      case 'f': return _inputValue;
      case 'c': return (_inputValue * 9/5) + 32;
      case 'k': return ((_inputValue - 273.15) * 9/5) + 32;
      case 'r': return _inputValue - 459.67;
      default: return _inputValue;
    }
  }

  double get _celsius => (_fahrenheit - 32) * 5/9;
  double get _kelvin => _celsius + 273.15;
  double get _rankine => _fahrenheit + 459.67;

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
          'Temperature Conversion',
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
          _buildPlumbingTemps(colors),
          const SizedBox(height: 16),
          _buildQuickReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    final unitSymbols = {'f': '°F', 'c': '°C', 'k': 'K', 'r': '°R'};

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
            'INPUT TEMPERATURE',
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
                '${_inputValue.toStringAsFixed(1)}${unitSymbols[_inputUnit]}',
                style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700),
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
              value: _inputValue.clamp(-100, 500),
              min: -100,
              max: 500,
              divisions: 600,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _inputValue = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildUnitButton(colors, 'f', '°F'),
              const SizedBox(width: 8),
              _buildUnitButton(colors, 'c', '°C'),
              const SizedBox(width: 8),
              _buildUnitButton(colors, 'k', 'K'),
              const SizedBox(width: 8),
              _buildUnitButton(colors, 'r', '°R'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(ZaftoColors colors, String unit, String label) {
    final isSelected = _inputUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _inputUnit = unit);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.bgBase,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
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
          const SizedBox(height: 16),
          _buildTempRow(colors, 'Fahrenheit', '${_fahrenheit.toStringAsFixed(2)}°F', _inputUnit == 'f'),
          const SizedBox(height: 12),
          _buildTempRow(colors, 'Celsius', '${_celsius.toStringAsFixed(2)}°C', _inputUnit == 'c'),
          const SizedBox(height: 12),
          _buildTempRow(colors, 'Kelvin', '${_kelvin.toStringAsFixed(2)} K', _inputUnit == 'k'),
          const SizedBox(height: 12),
          _buildTempRow(colors, 'Rankine', '${_rankine.toStringAsFixed(2)}°R', _inputUnit == 'r'),
        ],
      ),
    );
  }

  Widget _buildTempRow(ZaftoColors colors, String label, String value, bool isInput) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isInput ? colors.accentPrimary : colors.textSecondary,
            fontSize: 14,
            fontWeight: isInput ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isInput ? colors.accentPrimary : colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlumbingTemps(ZaftoColors colors) {
    final temps = [
      ('Hot Water Setpoint', '120°F', '49°C'),
      ('Scalding Warning', '130°F+', '54°C+'),
      ('Sanitizing (Dishwasher)', '140°F', '60°C'),
      ('Legionella Kill', '158°F', '70°C'),
      ('Freeze Protection', '35°F', '2°C'),
      ('Pipe Freezing Risk', '32°F', '0°C'),
      ('Glycol Addition', '<20°F', '<-7°C'),
    ];

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
            'PLUMBING REFERENCE TEMPERATURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...temps.map((temp) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(temp.$1, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
                Expanded(
                  child: Text(temp.$2, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text(temp.$3, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
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
              Icon(LucideIcons.calculator, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Conversion Formulas',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '°F = (°C × 9/5) + 32\n'
            '°C = (°F - 32) × 5/9\n'
            'K = °C + 273.15\n'
            '°R = °F + 459.67',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.6, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
