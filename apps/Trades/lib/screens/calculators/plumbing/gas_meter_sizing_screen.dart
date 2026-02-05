import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Gas Meter Sizing Calculator - Design System v2.6
///
/// Sizes gas meters based on total BTU demand.
/// Converts BTU to CFH and recommends meter capacity.
///
/// References: NFPA 54, IFGC 2024
class GasMeterSizingScreen extends ConsumerStatefulWidget {
  const GasMeterSizingScreen({super.key});
  @override
  ConsumerState<GasMeterSizingScreen> createState() => _GasMeterSizingScreenState();
}

class _GasMeterSizingScreenState extends ConsumerState<GasMeterSizingScreen> {
  // Gas type
  String _gasType = 'natural'; // 'natural' or 'propane'

  // Connected appliances (BTU/hr)
  int _furnace = 80000;
  int _waterHeater = 40000;
  int _range = 65000;
  int _dryer = 22000;
  int _fireplace = 0;
  int _other = 0;

  // Custom input mode
  bool _useCustomTotal = false;
  double _customTotal = 200000;

  // BTU content per cubic foot
  static const Map<String, int> _btuPerCf = {
    'natural': 1000, // Natural gas ~1000 BTU/cf
    'propane': 2500, // Propane ~2500 BTU/cf
  };

  // Standard meter sizes (CFH capacity)
  static const List<({String size, int cfh, String desc})> _meterSizes = [
    (size: '175', cfh: 175, desc: 'Small residential'),
    (size: '250', cfh: 250, desc: 'Standard residential'),
    (size: '400', cfh: 400, desc: 'Large residential'),
    (size: '630', cfh: 630, desc: 'Small commercial'),
    (size: '1000', cfh: 1000, desc: 'Medium commercial'),
    (size: '1600', cfh: 1600, desc: 'Large commercial'),
    (size: '2500', cfh: 2500, desc: 'Industrial'),
  ];

  double get _totalBtu {
    if (_useCustomTotal) return _customTotal;
    return (_furnace + _waterHeater + _range + _dryer + _fireplace + _other).toDouble();
  }

  double get _totalCfh {
    final btuPerCf = _btuPerCf[_gasType] ?? 1000;
    return _totalBtu / btuPerCf;
  }

  String get _recommendedMeter {
    final cfh = _totalCfh;
    for (final meter in _meterSizes) {
      if (meter.cfh >= cfh * 1.1) { // 10% safety margin
        return meter.size;
      }
    }
    return '> 2500';
  }

  int get _recommendedCfh {
    final size = _recommendedMeter;
    return _meterSizes.firstWhere(
      (m) => m.size == size,
      orElse: () => _meterSizes.last,
    ).cfh;
  }

  double get _utilizationPercent {
    return (_totalCfh / _recommendedCfh) * 100;
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
          'Gas Meter Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildGasTypeCard(colors),
          const SizedBox(height: 16),
          _buildInputModeCard(colors),
          const SizedBox(height: 16),
          if (_useCustomTotal)
            _buildCustomTotalCard(colors)
          else
            _buildAppliancesCard(colors),
          const SizedBox(height: 16),
          _buildMeterTable(colors),
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
            '$_recommendedMeter CFH',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Meter Size',
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
                _buildResultRow(colors, 'Total BTU/hr', '${_totalBtu.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Gas Type', _gasType == 'natural' ? 'Natural Gas' : 'Propane'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU per CF', '${_btuPerCf[_gasType]}'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Required CFH', _totalCfh.toStringAsFixed(1), highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Utilization', '${_utilizationPercent.toStringAsFixed(0)}%'),
              ],
            ),
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
            'GAS TYPE',
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
                          '~1000 BTU/CF',
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
                          '~2500 BTU/CF',
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

  Widget _buildInputModeCard(ZaftoColors colors) {
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
            'INPUT METHOD',
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
                    setState(() => _useCustomTotal = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_useCustomTotal ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'By Appliance',
                        style: TextStyle(
                          color: !_useCustomTotal
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _useCustomTotal = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _useCustomTotal ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Custom Total',
                        style: TextStyle(
                          color: _useCustomTotal
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildAppliancesCard(ZaftoColors colors) {
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
            'CONNECTED APPLIANCES (BTU/HR)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildApplianceSlider(colors, 'Furnace', _furnace, (v) => setState(() => _furnace = v), max: 200000),
          _buildApplianceSlider(colors, 'Water Heater', _waterHeater, (v) => setState(() => _waterHeater = v), max: 100000),
          _buildApplianceSlider(colors, 'Range/Cooktop', _range, (v) => setState(() => _range = v), max: 100000),
          _buildApplianceSlider(colors, 'Dryer', _dryer, (v) => setState(() => _dryer = v), max: 35000),
          _buildApplianceSlider(colors, 'Fireplace', _fireplace, (v) => setState(() => _fireplace = v), max: 100000),
          _buildApplianceSlider(colors, 'Other', _other, (v) => setState(() => _other = v), max: 200000),
        ],
      ),
    );
  }

  Widget _buildApplianceSlider(ZaftoColors colors, String label, int value, Function(int) onChanged, {required int max}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
              Text(
                '${(value / 1000).toStringAsFixed(0)}k BTU',
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
              value: value.toDouble(),
              min: 0,
              max: max.toDouble(),
              divisions: 40,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTotalCard(ZaftoColors colors) {
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
            'TOTAL BTU/HR',
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
              Text(
                '${(_customTotal / 1000).toStringAsFixed(0)}k',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
                    value: _customTotal,
                    min: 10000,
                    max: 2000000,
                    divisions: 199,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _customTotal = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Combined BTU rating of all gas appliances',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterTable(ZaftoColors colors) {
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
            'STANDARD METER SIZES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._meterSizes.map((meter) {
            final isRecommended = meter.size == _recommendedMeter;
            final meetsLoad = meter.cfh >= _totalCfh;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${meter.size} CFH',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meter.desc,
                      style: TextStyle(
                        color: meetsLoad ? colors.textSecondary : colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
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
                'IFGC 2024 / NFPA 54',
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
            '• CFH = BTU ÷ BTU per cubic foot\n'
            '• Natural gas: ~1000 BTU/CF\n'
            '• Propane: ~2500 BTU/CF\n'
            '• Meter sized for total connected load\n'
            '• Contact utility for exact sizing\n'
            '• Diversity factor may apply',
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
