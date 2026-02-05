import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Expansion Tank Sizing Calculator - Design System v2.6
///
/// Calculates thermal expansion tank size for water heaters per IPC 2024.
/// Required when backflow prevention devices are installed.
///
/// References: IPC 607.3, Manufacturer sizing formulas
class ExpansionTankScreen extends ConsumerStatefulWidget {
  const ExpansionTankScreen({super.key});
  @override
  ConsumerState<ExpansionTankScreen> createState() => _ExpansionTankScreenState();
}

class _ExpansionTankScreenState extends ConsumerState<ExpansionTankScreen> {
  // Water heater capacity (gallons)
  double _tankCapacity = 50;

  // Supply pressure (PSI)
  double _supplyPressure = 60;

  // PRV setting (PSI) - if installed
  double _prvSetting = 75;

  // Incoming water temperature (Fahrenheit)
  double _inletTemp = 50;

  // Water heater setpoint (Fahrenheit)
  double _setpointTemp = 120;

  // Has PRV installed?
  bool _hasPrv = true;

  // Common water heater sizes
  static const List<int> _commonTankSizes = [30, 40, 50, 66, 75, 80, 100, 120];

  // Common pressure settings
  static const List<int> _commonPressures = [40, 50, 60, 70, 80];

  // Standard expansion tank sizes (gallons)
  static const List<double> _standardTankSizes = [2.0, 2.1, 4.5, 10.0, 14.0, 20.0, 32.0, 44.0];

  // Expansion factor based on temperature rise
  // Approximate values for water expansion
  double get _expansionFactor {
    final tempRise = _setpointTemp - _inletTemp;
    // Water expands approximately 0.023% per degree F above 40F
    // More accurate: use ASHRAE data tables
    if (tempRise <= 0) return 0;

    // Simplified expansion coefficient
    // At 40F: density = 62.42 lb/ft3
    // At 120F: density = 61.71 lb/ft3
    // At 140F: density = 61.38 lb/ft3
    final expansionPercent = tempRise * 0.00023; // ~0.023% per degree F
    return expansionPercent;
  }

  // Volume of expanded water (gallons)
  double get _expansionVolume {
    return _tankCapacity * _expansionFactor;
  }

  // Acceptance factor based on pressures
  double get _acceptanceFactor {
    // Formula: (Pmax - Pinlet) / (Pmax + 14.7)
    // Pmax = PRV setting or maximum operating pressure
    // Pinlet = Supply pressure
    final pmax = _hasPrv ? _prvSetting : _supplyPressure + 10; // +10 for safety margin
    final pinlet = _supplyPressure;

    if (pmax <= pinlet) return 0.1; // Minimum factor

    return (pmax - pinlet) / (pmax + 14.7);
  }

  // Calculated expansion tank size (gallons)
  double get _calculatedTankSize {
    if (_acceptanceFactor <= 0) return 0;
    return _expansionVolume / _acceptanceFactor;
  }

  // Recommended tank size (next standard size up)
  double get _recommendedTankSize {
    final calc = _calculatedTankSize;
    for (final size in _standardTankSizes) {
      if (size >= calc) return size;
    }
    return _standardTankSizes.last;
  }

  // System volume for hydronic (optional future expansion)
  double get _systemVolume => _tankCapacity;

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
          'Expansion Tank Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildWaterHeaterCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
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
            '${_recommendedTankSize.toStringAsFixed(1)} gal',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Expansion Tank',
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
                _buildResultRow(colors, 'Water Heater', '${_tankCapacity.toInt()} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Expansion Volume', '${_expansionVolume.toStringAsFixed(2)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Expansion Factor', '${(_expansionFactor * 100).toStringAsFixed(2)}%'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Acceptance Factor', _acceptanceFactor.toStringAsFixed(3)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Calculated Size', '${_calculatedTankSize.toStringAsFixed(2)} gal', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Temperature Rise', '${(_setpointTemp - _inletTemp).toInt()}\u00B0F'),
              ],
            ),
          ),
          if (!_hasPrv) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Expansion tank required when backflow preventer is installed',
                      style: TextStyle(color: colors.accentWarning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterHeaterCard(ZaftoColors colors) {
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
            'WATER HEATER CAPACITY',
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
            children: _commonTankSizes.map((size) {
              final isSelected = _tankCapacity == size.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tankCapacity = size.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size gal',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_tankCapacity.toInt()} gal',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _tankCapacity,
                    min: 20,
                    max: 120,
                    divisions: 20,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _tankCapacity = v);
                    },
                  ),
                ),
              ),
            ],
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supply Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_supplyPressure.toInt()} PSI',
                          style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _supplyPressure,
                        min: 30,
                        max: 80,
                        divisions: 10,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _supplyPressure = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _hasPrv = !_hasPrv);
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hasPrv ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                    border: _hasPrv ? null : Border.all(color: colors.borderSubtle),
                  ),
                  child: _hasPrv
                      ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'PRV / Pressure Regulator Installed',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_hasPrv) ...[
            const SizedBox(height: 12),
            Text('PRV Setting', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_prvSetting.toInt()} PSI',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: colors.accentPrimary,
                      inactiveTrackColor: colors.bgBase,
                      thumbColor: colors.accentPrimary,
                    ),
                    child: Slider(
                      value: _prvSetting,
                      min: 50,
                      max: 100,
                      divisions: 10,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _prvSetting = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(ZaftoColors colors) {
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
            'TEMPERATURE',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inlet Water', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '${_inletTemp.toInt()}\u00B0F',
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _inletTemp,
                        min: 35,
                        max: 75,
                        divisions: 8,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _inletTemp = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setpoint', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '${_setpointTemp.toInt()}\u00B0F',
                      style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _setpointTemp,
                        min: 100,
                        max: 160,
                        divisions: 12,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _setpointTemp = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
    // Quick reference table
    final quickRef = [
      (heater: 30, tank: 2.0),
      (heater: 40, tank: 2.0),
      (heater: 50, tank: 2.1),
      (heater: 66, tank: 4.5),
      (heater: 80, tank: 4.5),
      (heater: 100, tank: 10.0),
      (heater: 120, tank: 14.0),
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
            'QUICK SIZING REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Typical sizes at 50 PSI supply, 75 PSI max',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...quickRef.map((item) {
            final isSelected = _tankCapacity == item.heater.toDouble();
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${item.heater} gal heater',
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '${item.tank} gal tank',
                    style: TextStyle(
                      color: isSelected ? colors.accentPrimary : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 607',
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
            '• 607.3 - Expansion tank required with backflow preventer\n'
            '• 607.3.1 - Thermal expansion tank sizing\n'
            '• Pre-charge tank to match supply pressure\n'
            '• Install on cold water side\n'
            '• Size based on water heater capacity\n'
            '• Consider inlet temp in cold climates',
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
