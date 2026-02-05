import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Service Line Sizing - Design System v2.6
///
/// Sizes water service line from street main to building.
/// Accounts for pressure, distance, elevation, and demand.
///
/// References: IPC 2024 Appendix E, AWWA standards
class WaterServiceSizingScreen extends ConsumerStatefulWidget {
  const WaterServiceSizingScreen({super.key});
  @override
  ConsumerState<WaterServiceSizingScreen> createState() => _WaterServiceSizingScreenState();
}

class _WaterServiceSizingScreenState extends ConsumerState<WaterServiceSizingScreen> {
  // Street main pressure (psi)
  double _streetPressure = 60.0;

  // Required pressure at fixture (psi)
  double _minFixturePressure = 15.0;

  // Total fixture units (WSFU)
  double _totalWSFU = 40.0;

  // Service line length (feet)
  double _serviceLength = 100.0;

  // Elevation change (feet) - positive = uphill
  double _elevationChange = 10.0;

  // Meter type
  String _meterType = 'standard';

  // Building type
  String _buildingType = 'residential';

  // Meter pressure losses (psi)
  static const Map<String, ({double loss, String size})> _meterLoss = {
    'standard': (loss: 8.0, size: '5/8" x 3/4"'),
    'compound': (loss: 12.0, size: 'Compound'),
    'turbine': (loss: 5.0, size: 'Turbine'),
  };

  // Pipe sizes with max WSFU at given pressure loss
  static const List<({String size, double id, int wsfu30, int wsfu40, int wsfu50})> _pipeSizing = [
    (size: '3/4"', id: 0.785, wsfu30: 8, wsfu40: 14, wsfu50: 20),
    (size: '1"', id: 1.025, wsfu30: 18, wsfu40: 32, wsfu50: 48),
    (size: '1-1/4"', id: 1.265, wsfu30: 36, wsfu40: 63, wsfu50: 95),
    (size: '1-1/2"', id: 1.505, wsfu30: 60, wsfu40: 105, wsfu50: 158),
    (size: '2"', id: 1.985, wsfu30: 130, wsfu40: 225, wsfu50: 340),
  ];

  // Elevation pressure loss: 0.433 psi per foot of elevation
  double get _elevationLoss {
    return _elevationChange * 0.433;
  }

  // Meter pressure loss
  double get _meterPressureLoss {
    return _meterLoss[_meterType]?.loss ?? 8.0;
  }

  // Available pressure for friction loss
  double get _availablePressure {
    return _streetPressure - _minFixturePressure - _elevationLoss - _meterPressureLoss;
  }

  // Allowable pressure loss per 100 feet
  double get _allowableLossPer100ft {
    if (_serviceLength <= 0) return 0;
    return _availablePressure / (_serviceLength / 100);
  }

  // Recommended pipe size based on WSFU and available pressure
  String get _recommendedSize {
    final wsfu = _totalWSFU.toInt();
    final pressureCategory = _allowableLossPer100ft;

    for (final pipe in _pipeSizing) {
      int maxWSFU;
      if (pressureCategory >= 50) {
        maxWSFU = pipe.wsfu50;
      } else if (pressureCategory >= 40) {
        maxWSFU = pipe.wsfu40;
      } else {
        maxWSFU = pipe.wsfu30;
      }

      if (wsfu <= maxWSFU) {
        return pipe.size;
      }
    }
    return '2" or larger';
  }

  // Flow rate at design WSFU (GPM)
  double get _designFlowGPM {
    // Hunter's curve approximation for WSFU to GPM
    if (_totalWSFU <= 6) return _totalWSFU * 1.5;
    if (_totalWSFU <= 20) return 15 + (_totalWSFU - 10) * 0.8;
    if (_totalWSFU <= 50) return 23 + (_totalWSFU - 20) * 0.5;
    if (_totalWSFU <= 100) return 38 + (_totalWSFU - 50) * 0.35;
    return 55 + (_totalWSFU - 100) * 0.25;
  }

  String get _pressureAssessment {
    if (_availablePressure < 10) return 'INSUFFICIENT - Need larger pipe or booster';
    if (_availablePressure < 20) return 'MARGINAL - Consider larger pipe';
    if (_availablePressure > 60) return 'HIGH - May need PRV inside';
    return 'ADEQUATE - Good design range';
  }

  Color _pressureColor(ZaftoColors colors) {
    if (_availablePressure < 10) return colors.accentError;
    if (_availablePressure < 20) return colors.accentWarning;
    return colors.accentSuccess;
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
          'Water Service Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildDemandCard(colors),
          const SizedBox(height: 16),
          _buildServiceCard(colors),
          const SizedBox(height: 16),
          _buildMeterCard(colors),
          const SizedBox(height: 16),
          _buildPressureBreakdown(colors),
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
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Service Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _pressureColor(colors).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _pressureAssessment,
              style: TextStyle(
                color: _pressureColor(colors),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Design Flow', '${_designFlowGPM.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total WSFU', _totalWSFU.toStringAsFixed(0)),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Available Pressure', '${_availablePressure.toStringAsFixed(1)} psi'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Loss Budget/100ft', '${_allowableLossPer100ft.toStringAsFixed(1)} psi', highlight: true),
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
            'STREET MAIN PRESSURE',
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
                '${_streetPressure.toStringAsFixed(0)} psi',
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
                    value: _streetPressure,
                    min: 30,
                    max: 100,
                    divisions: 70,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _streetPressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Get from water utility or pressure test',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Text(
            'MINIMUM FIXTURE PRESSURE',
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
            children: [8, 10, 15, 20, 25].map((psi) {
              final isSelected = _minFixturePressure == psi.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _minFixturePressure = psi.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$psi psi',
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
          const SizedBox(height: 8),
          Text(
            'IPC requires 8 psi min; 15-20 psi typical design',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandCard(ZaftoColors colors) {
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
            'WATER SUPPLY FIXTURE UNITS (WSFU)',
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
                '${_totalWSFU.toStringAsFixed(0)} WSFU',
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
                    value: _totalWSFU,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _totalWSFU = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Use WSFU calculator for exact count',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Reference:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('1 Bath: 8-12 WSFU | 2 Bath: 15-20 WSFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                Text('3 Bath: 22-30 WSFU | 4+ Bath: 35-50 WSFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ZaftoColors colors) {
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
            'SERVICE LINE',
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
                    Text('Length', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_serviceLength.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _serviceLength,
                    min: 20,
                    max: 300,
                    divisions: 28,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _serviceLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elevation Change', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_elevationChange >= 0 ? "+" : ""}${_elevationChange.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _elevationChange,
                    min: -20,
                    max: 50,
                    divisions: 70,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _elevationChange = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Positive = building higher than main',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard(ZaftoColors colors) {
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
            'METER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._meterLoss.entries.map((entry) {
            final isSelected = _meterType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _meterType = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${entry.key[0].toUpperCase()}${entry.key.substring(1)} (${entry.value.size})',
                        style: TextStyle(
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '~${entry.value.loss.toStringAsFixed(0)} psi loss',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPressureBreakdown(ZaftoColors colors) {
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
            'PRESSURE BUDGET',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Street Pressure', '${_streetPressure.toStringAsFixed(0)} psi'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '- Fixture Min', '-${_minFixturePressure.toStringAsFixed(0)} psi'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '- Elevation Loss', '-${_elevationLoss.toStringAsFixed(1)} psi'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '- Meter Loss', '-${_meterPressureLoss.toStringAsFixed(0)} psi'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Available for Friction', '${_availablePressure.toStringAsFixed(1)} psi', highlight: true),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'SIZING TABLE (MAX WSFU)',
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
              const SizedBox(width: 50),
              Expanded(child: Text('30 psi', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('40 psi', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('50 psi', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 6),
          ..._pipeSizing.map((pipe) {
            final isRecommended = pipe.size == _recommendedSize;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      pipe.size,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Text('${pipe.wsfu30}', style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text('${pipe.wsfu40}', style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text('${pipe.wsfu50}', style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Values at psi loss per 100 ft available for friction',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
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
                'IPC 2024 Appendix E',
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
            '• E103 - Water service sizing procedure\n'
            '• E201 - Pressure loss table\n'
            '• Min 8 psi at highest fixture\n'
            '• Elevation: 0.433 psi/ft\n'
            '• Always size larger if marginal\n'
            '• Verify utility main pressure',
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
