import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Thermal Expansion Calculator - Design System v2.6
///
/// Calculates thermal expansion in hot water systems.
/// Sizes expansion tanks for closed systems with check valves.
///
/// References: IPC 2024 Section 607.3
class ThermalExpansionScreen extends ConsumerStatefulWidget {
  const ThermalExpansionScreen({super.key});
  @override
  ConsumerState<ThermalExpansionScreen> createState() => _ThermalExpansionScreenState();
}

class _ThermalExpansionScreenState extends ConsumerState<ThermalExpansionScreen> {
  // Water heater size (gallons)
  double _heaterSize = 50;

  // Inlet temperature (°F)
  double _inletTemp = 50;

  // Set temperature (°F)
  double _setTemp = 120;

  // System pressure (PSI)
  double _systemPressure = 50;

  // Water expansion coefficient (approximate)
  // Water expands about 2% when heated from 50°F to 120°F
  double get _expansionPercent {
    final tempRise = _setTemp - _inletTemp;
    // Roughly 0.023% per degree F rise
    return (tempRise * 0.00023) * 100;
  }

  // Expanded water volume (gallons)
  double get _expansionVolume => _heaterSize * (_expansionPercent / 100);

  // Required tank acceptance (gallons)
  // Tank must accept expansion plus safety margin
  double get _requiredAcceptance => _expansionVolume * 1.25;

  // Recommended tank size
  String get _tankSize {
    final acceptance = _requiredAcceptance;
    if (acceptance <= 0.5) return '2 gallon';
    if (acceptance <= 1.0) return '2 gallon';
    if (acceptance <= 1.5) return '4.5 gallon';
    if (acceptance <= 2.5) return '4.5 gallon';
    if (acceptance <= 4.0) return '10 gallon';
    return '10+ gallon';
  }

  // Pre-charge pressure (should be set to system pressure)
  int get _preChargePsi => _systemPressure.round();

  // Pressure relief concern
  bool get _reliefConcern => _systemPressure + (_expansionPercent * 2) > 80;

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
          'Thermal Expansion',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildHeaterCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
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
            _tankSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Expansion Tank',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_reliefConcern) ...[
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
                    'High pressure - verify T&P valve',
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
                _buildResultRow(colors, 'Expansion', '${_expansionPercent.toStringAsFixed(2)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Expanded Volume', '${_expansionVolume.toStringAsFixed(2)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Required Acceptance', '${_requiredAcceptance.toStringAsFixed(2)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pre-Charge Pressure', '$_preChargePsi PSI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaterCard(ZaftoColors colors) {
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
            'WATER HEATER SIZE',
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
              Text('Tank Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_heaterSize.toStringAsFixed(0)} gallons',
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
              value: _heaterSize,
              min: 20,
              max: 120,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _heaterSize = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 40, 50, 75, 80].map((size) {
              final isSelected = (_heaterSize - size).abs() < 3;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _heaterSize = size.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$size gal',
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

  Widget _buildTemperatureCard(ZaftoColors colors) {
    final tempRise = _setTemp - _inletTemp;

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
            'TEMPERATURES',
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
              Text('Inlet Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_inletTemp.toStringAsFixed(0)}°F',
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
              value: _inletTemp,
              min: 35,
              max: 80,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _inletTemp = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Set Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_setTemp.toStringAsFixed(0)}°F',
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
              value: _setTemp,
              min: 100,
              max: 160,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _setTemp = v);
              },
            ),
          ),
          Text(
            'Temperature rise: ${tempRise.toStringAsFixed(0)}°F',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
            'SYSTEM PRESSURE',
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
                '${_systemPressure.toStringAsFixed(0)} PSI',
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
              value: _systemPressure,
              min: 30,
              max: 80,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _systemPressure = v);
              },
            ),
          ),
          Text(
            'Set tank pre-charge equal to supply pressure',
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
              Icon(LucideIcons.thermometer, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 607.3',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Required with check valve/PRV\n'
            '• Install on cold supply side\n'
            '• Pre-charge = system pressure\n'
            '• T&P valve still required\n'
            '• Support tank properly\n'
            '• Check annually',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
