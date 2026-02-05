import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Mixing Valve (TMV) Sizing Calculator - Design System v2.6
///
/// Sizes thermostatic mixing valves for safe water delivery.
/// Calculates flow rates and outlet temperatures.
///
/// References: ASSE 1017, IPC 2024 Section 424
class MixingValveScreen extends ConsumerStatefulWidget {
  const MixingValveScreen({super.key});
  @override
  ConsumerState<MixingValveScreen> createState() => _MixingValveScreenState();
}

class _MixingValveScreenState extends ConsumerState<MixingValveScreen> {
  // Hot water temperature
  double _hotTemp = 140;

  // Cold water temperature
  double _coldTemp = 55;

  // Desired mixed temperature
  double _mixedTemp = 110;

  // Required flow rate (GPM)
  double _flowRate = 3.0;

  // Application type
  String _application = 'shower';

  // Application settings
  static const Map<String, ({double temp, double gpm, String desc})> _applications = {
    'shower': (temp: 110, gpm: 2.5, desc: 'Shower/Tub'),
    'lavatory': (temp: 105, gpm: 1.5, desc: 'Lavatory'),
    'bidet': (temp: 100, gpm: 1.0, desc: 'Bidet'),
    'healthcare': (temp: 105, gpm: 2.0, desc: 'Healthcare facility'),
    'commercial': (temp: 110, gpm: 3.0, desc: 'Commercial'),
    'emergency': (temp: 85, gpm: 3.0, desc: 'Emergency eyewash'),
  };

  // Calculate hot water percentage needed
  double get _hotPercent {
    if (_hotTemp <= _coldTemp) return 0;
    return ((_mixedTemp - _coldTemp) / (_hotTemp - _coldTemp)) * 100;
  }

  // Calculate cold water percentage
  double get _coldPercent => 100 - _hotPercent;

  // Flow rates
  double get _hotFlow => _flowRate * (_hotPercent / 100);
  double get _coldFlow => _flowRate * (_coldPercent / 100);

  // Standard TMV sizes
  List<({String size, double minGpm, double maxGpm})> get _valveSizes {
    return [
      (size: '1/2"', minGpm: 0.5, maxGpm: 4.0),
      (size: '3/4"', minGpm: 1.0, maxGpm: 10.0),
      (size: '1"', minGpm: 3.0, maxGpm: 20.0),
      (size: '1-1/4"', minGpm: 5.0, maxGpm: 35.0),
      (size: '1-1/2"', minGpm: 10.0, maxGpm: 50.0),
      (size: '2"', minGpm: 15.0, maxGpm: 85.0),
    ];
  }

  String get _recommendedSize {
    for (final valve in _valveSizes) {
      if (_flowRate >= valve.minGpm && _flowRate <= valve.maxGpm) {
        return valve.size;
      }
    }
    return '> 2"';
  }

  void _applyApplication(String app) {
    final settings = _applications[app];
    if (settings != null) {
      setState(() {
        _application = app;
        _mixedTemp = settings.temp;
        _flowRate = settings.gpm;
      });
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
          'Mixing Valve (TMV)',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildMixingDiagram(colors),
          const SizedBox(height: 16),
          _buildValveSizeTable(colors),
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
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'TMV Size',
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
                _buildResultRow(colors, 'Hot Supply', '${_hotTemp.toStringAsFixed(0)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Cold Supply', '${_coldTemp.toStringAsFixed(0)}°F'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Mixed Output', '${_mixedTemp.toStringAsFixed(0)}°F', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Flow', '${_flowRate.toStringAsFixed(1)} GPM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _applications.entries.map((entry) {
              final isSelected = _application == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _applyApplication(entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
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
            'TEMPERATURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildTempSlider(colors, 'Hot Supply', _hotTemp, (v) => setState(() => _hotTemp = v),
              min: 110, max: 160, color: Colors.red),
          const SizedBox(height: 16),
          _buildTempSlider(colors, 'Cold Supply', _coldTemp, (v) => setState(() => _coldTemp = v),
              min: 40, max: 70, color: Colors.blue),
          const SizedBox(height: 16),
          _buildTempSlider(colors, 'Desired Mix', _mixedTemp, (v) => setState(() => _mixedTemp = v),
              min: 80, max: 120, color: colors.accentPrimary),
        ],
      ),
    );
  }

  Widget _buildTempSlider(ZaftoColors colors, String label, double value, Function(double) onChanged,
      {required double min, required double max, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}°F',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: colors.bgBase,
            thumbColor: color,
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlowCard(ZaftoColors colors) {
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
            'REQUIRED FLOW RATE (GPM)',
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
                '${_flowRate.toStringAsFixed(1)} GPM',
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
                    value: _flowRate,
                    min: 0.5,
                    max: 20,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
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

  Widget _buildMixingDiagram(ZaftoColors colors) {
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
            'MIXING RATIO',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(LucideIcons.flame, color: Colors.red, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'HOT',
                      style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_hotPercent.toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_hotFlow.toStringAsFixed(2)} GPM',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.plus, color: colors.textTertiary, size: 24),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(LucideIcons.snowflake, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'COLD',
                      style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_coldPercent.toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_coldFlow.toStringAsFixed(2)} GPM',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.equal, color: colors.textTertiary, size: 24),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MIXED',
                      style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_mixedTemp.toStringAsFixed(0)}°F',
                      style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_flowRate.toStringAsFixed(2)} GPM',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
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

  Widget _buildValveSizeTable(ZaftoColors colors) {
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
            'TMV SIZE CHART',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._valveSizes.map((valve) {
            final isRecommended = valve.size == _recommendedSize;
            final inRange = _flowRate >= valve.minGpm && _flowRate <= valve.maxGpm;

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
                    width: 50,
                    child: Text(
                      valve.size,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${valve.minGpm} - ${valve.maxGpm} GPM',
                      style: TextStyle(
                        color: inRange ? colors.textSecondary : colors.textTertiary,
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
                'IPC 2024 Section 424 / ASSE 1017',
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
            '• Max 120°F at showers per IPC 424.5\n'
            '• ASSE 1017 certified TMV required\n'
            '• Scald protection for vulnerable users\n'
            '• Store hot water at 140°F (Legionella)\n'
            '• Deliver at safe 110-120°F\n'
            '• Point-of-use or master mixing valve',
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
