import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Total Dynamic Head (TDH) Calculator - Design System v2.6
///
/// Calculates total head required for pump selection.
/// Combines static head, friction head, and pressure head.
///
/// References: Hydraulic Institute standards, pump manufacturer data
class TotalDynamicHeadScreen extends ConsumerStatefulWidget {
  const TotalDynamicHeadScreen({super.key});
  @override
  ConsumerState<TotalDynamicHeadScreen> createState() => _TotalDynamicHeadScreenState();
}

class _TotalDynamicHeadScreenState extends ConsumerState<TotalDynamicHeadScreen> {
  // Static head components
  double _suctionLift = 5.0; // feet below pump
  double _dischargeLift = 20.0; // feet above pump

  // Friction head
  double _frictionHead = 8.0; // feet (calculated or entered)

  // Pressure requirements
  double _dischargePressurepsi = 20.0; // psi at discharge point

  // Flow rate (for reference)
  double _flowRate = 25.0; // GPM

  // Pipe details for friction calculation
  double _pipeLength = 100.0;
  double _pipeDiameter = 1.5;
  int _fittingsCount = 10;

  // Mode: simple or detailed
  String _mode = 'simple';

  // Friction factor by pipe size (feet per 100 ft at moderate velocity)
  static final Map<double, double> _frictionFactors = {
    0.75: 6.0,
    1.0: 3.5,
    1.25: 2.0,
    1.5: 1.2,
    2.0: 0.6,
    2.5: 0.35,
    3.0: 0.2,
  };

  // Static suction head (negative if lift required)
  double get _staticSuctionHead {
    return -_suctionLift; // Negative because it's a lift
  }

  // Static discharge head
  double get _staticDischargeHead {
    return _dischargeLift;
  }

  // Total static head
  double get _totalStaticHead {
    return _suctionLift + _dischargeLift;
  }

  // Calculated friction head (detailed mode)
  double get _calculatedFrictionHead {
    final factor = _frictionFactors[_pipeDiameter] ?? 2.0;
    final fittingsEquivalent = _fittingsCount * (_pipeDiameter * 2);
    final totalLength = _pipeLength + fittingsEquivalent;
    return (totalLength / 100) * factor;
  }

  // Friction head to use
  double get _frictionHeadValue {
    return _mode == 'detailed' ? _calculatedFrictionHead : _frictionHead;
  }

  // Pressure head (convert psi to feet: 2.31 ft per psi)
  double get _pressureHead {
    return _dischargePressurepsi * 2.31;
  }

  // Total Dynamic Head
  double get _TDH {
    return _totalStaticHead + _frictionHeadValue + _pressureHead;
  }

  // Estimated pump HP (rough)
  double get _estimatedHP {
    // HP = (GPM × TDH) / (3960 × Efficiency)
    // Assume 50% efficiency for small pumps
    return (_flowRate * _TDH) / (3960 * 0.5);
  }

  String get _pumpRecommendation {
    final hp = _estimatedHP;
    if (hp <= 0.25) return '1/4 HP';
    if (hp <= 0.33) return '1/3 HP';
    if (hp <= 0.5) return '1/2 HP';
    if (hp <= 0.75) return '3/4 HP';
    if (hp <= 1.0) return '1 HP';
    if (hp <= 1.5) return '1-1/2 HP';
    if (hp <= 2.0) return '2 HP';
    return '${hp.ceil()} HP';
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
          'Total Dynamic Head',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildModeSelector(colors),
          const SizedBox(height: 16),
          _buildStaticHeadCard(colors),
          const SizedBox(height: 16),
          _mode == 'simple' ? _buildSimpleFrictionCard(colors) : _buildDetailedFrictionCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildBreakdown(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _TDH.toStringAsFixed(1),
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' ft',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total Dynamic Head',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Min Pump Size: $_pumpRecommendation',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 16,
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
                _buildResultRow(colors, 'Static Head', '${_totalStaticHead.toStringAsFixed(1)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Friction Head', '${_frictionHeadValue.toStringAsFixed(1)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pressure Head', '${_pressureHead.toStringAsFixed(1)} ft'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Flow Rate', '${_flowRate.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Est. HP', _estimatedHP.toStringAsFixed(2), highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ZaftoColors colors) {
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
            'FRICTION CALCULATION',
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
                    setState(() => _mode = 'simple');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _mode == 'simple' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Enter Known',
                      style: TextStyle(
                        color: _mode == 'simple' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = 'detailed');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _mode == 'detailed' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Calculate',
                      style: TextStyle(
                        color: _mode == 'detailed' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildStaticHeadCard(ZaftoColors colors) {
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
            'STATIC HEAD',
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
                    Text('Suction Lift', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_suctionLift.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _suctionLift,
                    min: 0,
                    max: 25,
                    divisions: 25,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _suctionLift = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Distance from water source to pump (max ~25 ft)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discharge Lift', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_dischargeLift.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _dischargeLift,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _dischargeLift = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Distance from pump to highest discharge point',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFrictionCard(ZaftoColors colors) {
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
            'FRICTION HEAD (KNOWN)',
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
                '${_frictionHead.toStringAsFixed(0)} ft',
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
                    value: _frictionHead,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _frictionHead = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'From pipe loss calculator or manufacturer data',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFrictionCard(ZaftoColors colors) {
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
            'FRICTION CALCULATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text('PIPE SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frictionFactors.keys.map((size) {
              final isSelected = _pipeDiameter == size;
              String label;
              if (size == 0.75) {
                label = '3/4"';
              } else if (size == 1.25) {
                label = '1-1/4"';
              } else if (size == 1.5) {
                label = '1-1/2"';
              } else if (size == 2.5) {
                label = '2-1/2"';
              } else {
                label = '${size.toInt()}"';
              }
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeDiameter = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pipe Length', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_pipeLength.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    value: _pipeLength,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _pipeLength = v);
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
                    Text('Fittings', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('$_fittingsCount', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    value: _fittingsCount.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _fittingsCount = v.toInt());
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calculated Friction', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text(
                  '${_calculatedFrictionHead.toStringAsFixed(1)} ft',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
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
            'PRESSURE REQUIREMENT',
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
                '${_dischargePressurepsi.toStringAsFixed(0)} psi',
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
                    value: _dischargePressurepsi,
                    min: 0,
                    max: 80,
                    divisions: 16,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _dischargePressurepsi = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Required pressure at discharge point (= ${_pressureHead.toStringAsFixed(1)} ft head)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
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
            'FLOW RATE',
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
                '${_flowRate.toStringAsFixed(0)} GPM',
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
                    min: 5,
                    max: 200,
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
          Text(
            'Required flow rate for pump sizing',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(ZaftoColors colors) {
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
            'TDH BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Suction Lift', '${_suctionLift.toStringAsFixed(1)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Discharge Lift', '${_dischargeLift.toStringAsFixed(1)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Static Head', '${_totalStaticHead.toStringAsFixed(1)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Friction Head', '${_frictionHeadValue.toStringAsFixed(1)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Pressure Head', '${_pressureHead.toStringAsFixed(1)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Dynamic Head', '${_TDH.toStringAsFixed(1)} ft', highlight: true),
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
                'Hydraulic Institute',
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
            '• TDH = Static + Friction + Pressure head\n'
            '• 1 psi = 2.31 feet of head\n'
            '• Max suction lift ~25 ft at sea level\n'
            '• HP = (GPM \u00d7 TDH) / (3960 \u00d7 eff)\n'
            '• Select pump with curve above TDH at GPM\n'
            '• Add 10-20% safety factor',
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
