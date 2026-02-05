import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Sump Pump Sizing Calculator - Design System v2.6
///
/// Calculates required sump pump GPM and HP based on pit size,
/// head height, and water inflow rate.
///
/// References: Industry standards, Manufacturer guidelines
class SumpPumpScreen extends ConsumerStatefulWidget {
  const SumpPumpScreen({super.key});
  @override
  ConsumerState<SumpPumpScreen> createState() => _SumpPumpScreenState();
}

class _SumpPumpScreenState extends ConsumerState<SumpPumpScreen> {
  // Pit dimensions
  double _pitDiameter = 18; // inches
  double _pitDepth = 24; // inches

  // Pump off level (inches from bottom)
  double _pumpOffLevel = 4;

  // Pump on level (inches from bottom)
  double _pumpOnLevel = 14;

  // Vertical lift (feet to discharge point)
  double _verticalLift = 8;

  // Horizontal run (feet)
  double _horizontalRun = 20;

  // Discharge pipe diameter
  String _dischargePipe = '1.5'; // inches

  // Number of elbows
  int _elbows = 2;

  // Check valve installed
  bool _hasCheckValve = true;

  // Water inflow rate (if known)
  double _inflowRate = 0; // GPM, 0 = calculate from cycle time

  // Desired cycle time (minutes between cycles)
  double _cycleTime = 3;

  // Pump type
  String _pumpType = 'submersible'; // 'submersible' or 'pedestal'

  // Friction loss per 100 ft for various pipe sizes (at ~30 GPM)
  static const Map<String, double> _frictionLoss = {
    '1.25': 15.0,
    '1.5': 6.0,
    '2': 2.0,
  };

  // Equivalent length of fittings (feet)
  static const Map<String, double> _fittingEquivalent = {
    'elbow90': 4.0,
    'elbow45': 2.0,
    'checkValve': 10.0,
  };

  // Pit volume in gallons
  double get _pitVolume {
    final radiusInches = _pitDiameter / 2;
    final volumeCubicInches = math.pi * radiusInches * radiusInches * _pitDepth;
    return volumeCubicInches / 231; // 231 cubic inches per gallon
  }

  // Usable volume (between on and off levels)
  double get _usableVolume {
    final radiusInches = _pitDiameter / 2;
    final usableDepth = _pumpOnLevel - _pumpOffLevel;
    final volumeCubicInches = math.pi * radiusInches * radiusInches * usableDepth;
    return volumeCubicInches / 231;
  }

  // Total dynamic head (TDH) in feet
  double get _totalDynamicHead {
    // Static head (vertical lift)
    double tdh = _verticalLift;

    // Friction head from horizontal run
    final frictionPer100 = _frictionLoss[_dischargePipe] ?? 6.0;
    tdh += (_horizontalRun / 100) * frictionPer100;

    // Friction from elbows
    tdh += _elbows * _fittingEquivalent['elbow90']!;

    // Friction from check valve
    if (_hasCheckValve) {
      tdh += _fittingEquivalent['checkValve']!;
    }

    return tdh;
  }

  // Required GPM based on inflow and cycle time
  double get _requiredGpm {
    if (_inflowRate > 0) {
      return _inflowRate;
    }

    // Calculate from desired cycle time
    // Pump must empty usable volume faster than it fills
    // Assume pump runs for 20-30% of cycle time
    final pumpRunTime = _cycleTime * 0.25; // minutes pump runs
    final fillTime = _cycleTime * 0.75; // minutes pit fills

    // If pit fills in fillTime minutes, inflow = usableVolume / fillTime
    final estimatedInflow = _usableVolume / fillTime;

    // Pump must discharge usableVolume in pumpRunTime
    return _usableVolume / pumpRunTime;
  }

  // Recommended pump HP
  String get _recommendedHp {
    final gpm = _requiredGpm;
    final tdh = _totalDynamicHead;

    // Simplified HP estimation
    // HP = (GPM × TDH) / (3960 × efficiency)
    // Assume 50% efficiency for small pumps
    final hp = (gpm * tdh) / (3960 * 0.5);

    if (hp <= 0.25) return '1/4 HP';
    if (hp <= 0.33) return '1/3 HP';
    if (hp <= 0.5) return '1/2 HP';
    if (hp <= 0.75) return '3/4 HP';
    if (hp <= 1.0) return '1 HP';
    return '1.5 HP+';
  }

  // Recommended pump GPM at TDH
  double get _recommendedGpmAtHead {
    // Add 25% safety margin to required GPM
    return _requiredGpm * 1.25;
  }

  // Battery backup recommendation
  String get _batteryBackupSize {
    final gpm = _requiredGpm;
    if (gpm < 20) return '35 Ah';
    if (gpm < 40) return '50 Ah';
    if (gpm < 60) return '75 Ah';
    return '100+ Ah';
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
          'Sump Pump Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildPitDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildPumpLevelsCard(colors),
          const SizedBox(height: 16),
          _buildDischargeCard(colors),
          const SizedBox(height: 16),
          _buildCycleTimeCard(colors),
          const SizedBox(height: 16),
          _buildPumpCurveNote(colors),
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
            _recommendedHp,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Pump Size',
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
                _buildResultRow(colors, 'Required GPM', '${_requiredGpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min GPM @ TDH', '${_recommendedGpmAtHead.toStringAsFixed(1)} GPM', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Dynamic Head', '${_totalDynamicHead.toStringAsFixed(1)} ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Pit Volume', '${_pitVolume.toStringAsFixed(1)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Usable Volume', '${_usableVolume.toStringAsFixed(1)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Vertical Lift', '${_verticalLift.toStringAsFixed(0)} ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Battery Backup', _batteryBackupSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitDimensionsCard(ZaftoColors colors) {
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
            'PIT DIMENSIONS',
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
                    Text('Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildQuickSelect(colors, _pitDiameter, [14, 18, 22, 24], '"', (v) => setState(() => _pitDiameter = v)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Depth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildQuickSelect(colors, _pitDepth, [18, 22, 24, 30], '"', (v) => setState(() => _pitDepth = v)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelect(ZaftoColors colors, double value, List<int> options, String unit, void Function(double) onSelect) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final isSelected = value == opt.toDouble();
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.toDouble());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$opt$unit',
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPumpLevelsCard(ZaftoColors colors) {
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
            'PUMP LEVELS (FROM BOTTOM)',
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
                    Text('Pump OFF', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_pumpOffLevel.toInt()}"', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentSuccess,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentSuccess,
                      ),
                      child: Slider(
                        value: _pumpOffLevel,
                        min: 2,
                        max: 12,
                        divisions: 10,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _pumpOffLevel = v;
                            if (_pumpOnLevel <= v) _pumpOnLevel = v + 2;
                          });
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
                    Text('Pump ON', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_pumpOnLevel.toInt()}"', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _pumpOnLevel,
                        min: _pumpOffLevel + 2,
                        max: _pitDepth - 2,
                        divisions: ((_pitDepth - 2) - (_pumpOffLevel + 2)).toInt().clamp(1, 20),
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _pumpOnLevel = v);
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

  Widget _buildDischargeCard(ZaftoColors colors) {
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
            'DISCHARGE',
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
                    Text('Vertical Lift', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_verticalLift.toInt()} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _verticalLift,
                        min: 4,
                        max: 25,
                        divisions: 21,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _verticalLift = v);
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
                    Text('Horizontal Run', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_horizontalRun.toInt()} ft', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.bgBase,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        value: _horizontalRun,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _horizontalRun = v);
                        },
                      ),
                    ),
                  ],
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
                    Text('Discharge Pipe', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['1.25', '1.5', '2'].map((size) {
                        final isSelected = _dischargePipe == size;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _dischargePipe = size);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.accentPrimary : colors.bgBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$size"',
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
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elbows (90\u00B0)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildCounter(colors, _elbows, 0, 6, (v) => setState(() => _elbows = v)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _hasCheckValve = !_hasCheckValve);
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hasCheckValve ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                    border: _hasCheckValve ? null : Border.all(color: colors.borderSubtle),
                  ),
                  child: _hasCheckValve
                      ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Text('Check Valve', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                Text(' (+10 ft equiv.)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(ZaftoColors colors, int value, int min, int max, void Function(int) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value - 1);
                  }
                : null,
            icon: Icon(LucideIcons.minus, color: value > min ? colors.textSecondary : colors.textQuaternary, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text('$value', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: value < max
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + 1);
                  }
                : null,
            icon: Icon(LucideIcons.plus, color: value < max ? colors.accentPrimary : colors.textQuaternary, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleTimeCard(ZaftoColors colors) {
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
            'CYCLE TIME',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text('Desired Minutes Between Cycles', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${_cycleTime.toStringAsFixed(1)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _cycleTime,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _cycleTime = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text('Longer cycle = larger pump needed. 2-4 min typical.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPumpCurveNote(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: colors.accentInfo, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Check manufacturer pump curve. Pump must deliver ${_recommendedGpmAtHead.toStringAsFixed(0)} GPM at ${_totalDynamicHead.toStringAsFixed(0)} ft head.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
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
                'Sump Pump Guidelines',
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
            '• Size pump for GPM at total dynamic head (TDH)\n'
            '• Check valve required on discharge\n'
            '• Battery backup recommended\n'
            '• Pit minimum 18" dia x 22" deep typical\n'
            '• Alarm recommended for high water\n'
            '• 2-4 cycles per hour is normal',
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
