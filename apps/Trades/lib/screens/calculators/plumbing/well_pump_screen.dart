import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Well Pump Sizing - Design System v2.6
///
/// Sizes submersible and jet pumps for residential wells.
/// Calculates GPM, head, and HP requirements.
///
/// References: NGWA, pump manufacturer guidelines
class WellPumpScreen extends ConsumerStatefulWidget {
  const WellPumpScreen({super.key});
  @override
  ConsumerState<WellPumpScreen> createState() => _WellPumpScreenState();
}

class _WellPumpScreenState extends ConsumerState<WellPumpScreen> {
  // Well depth (feet)
  double _wellDepth = 150.0;

  // Static water level (feet below surface)
  double _staticLevel = 50.0;

  // Drawdown (how much water level drops when pumping)
  double _drawdown = 20.0;

  // Horizontal distance to pressure tank
  double _horizontalDistance = 50.0;

  // Vertical rise from well to house
  double _verticalRise = 10.0;

  // Required pressure (psi)
  double _requiredPressure = 50.0;

  // Peak demand (GPM)
  double _peakDemand = 10.0;

  // Pump type
  String _pumpType = 'submersible';

  // Pump types with characteristics
  static const Map<String, ({String name, String desc, int maxDepth, String use})> _pumpTypes = {
    'submersible': (name: 'Submersible', desc: 'In-well motor', maxDepth: 400, use: 'Deep wells'),
    'jetDeep': (name: 'Deep Well Jet', desc: 'Above-ground motor', maxDepth: 150, use: 'Moderate depth'),
    'jetShallow': (name: 'Shallow Well Jet', desc: 'Above-ground', maxDepth: 25, use: 'Shallow wells'),
    'convertible': (name: 'Convertible Jet', desc: 'Dual-mode', maxDepth: 90, use: 'Variable depth'),
  };

  // Pumping level (static + drawdown)
  double get _pumpingLevel {
    return _staticLevel + _drawdown;
  }

  // Total vertical lift
  double get _totalVerticalLift {
    return _pumpingLevel + _verticalRise;
  }

  // Friction loss estimate (based on pipe length and flow)
  double get _frictionLoss {
    // Approximate: 5 ft per 100 ft of pipe at typical flows
    final totalPipe = _wellDepth + _horizontalDistance;
    return (totalPipe / 100) * 5;
  }

  // Pressure head (convert psi to feet)
  double get _pressureHead {
    return _requiredPressure * 2.31;
  }

  // Total dynamic head
  double get _totalDynamicHead {
    return _totalVerticalLift + _frictionLoss + _pressureHead;
  }

  // Recommended HP
  double get _recommendedHP {
    // HP = (GPM × TDH) / (3960 × Efficiency)
    // Assume 55% efficiency for well pumps
    final hp = (_peakDemand * _totalDynamicHead) / (3960 * 0.55);

    // Round up to standard sizes
    if (hp <= 0.33) return 0.33;
    if (hp <= 0.5) return 0.5;
    if (hp <= 0.75) return 0.75;
    if (hp <= 1.0) return 1.0;
    if (hp <= 1.5) return 1.5;
    if (hp <= 2.0) return 2.0;
    if (hp <= 3.0) return 3.0;
    if (hp <= 5.0) return 5.0;
    return (hp).ceil().toDouble();
  }

  // Wire size recommendation (for submersible)
  String get _wireSize {
    final hp = _recommendedHP;
    final distance = _wellDepth + 50; // Wire run

    if (hp <= 0.5 && distance < 200) return '12 AWG';
    if (hp <= 0.75 && distance < 200) return '10 AWG';
    if (hp <= 1.0 && distance < 200) return '10 AWG';
    if (hp <= 1.5 && distance < 200) return '8 AWG';
    if (hp <= 2.0) return '8 AWG';
    return '6 AWG';
  }

  // Pressure tank size recommendation
  String get _tankSize {
    final gpm = _peakDemand;
    if (gpm <= 5) return '20 gallon';
    if (gpm <= 10) return '32 gallon';
    if (gpm <= 15) return '44 gallon';
    if (gpm <= 20) return '62 gallon';
    return '86 gallon';
  }

  // Recommended pump type based on depth
  String get _recommendedPumpType {
    if (_pumpingLevel <= 25) return 'jetShallow';
    if (_pumpingLevel <= 90) return 'convertible';
    if (_pumpingLevel <= 150) return 'jetDeep';
    return 'submersible';
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
          'Well Pump Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildWellCard(colors),
          const SizedBox(height: 16),
          _buildDistanceCard(colors),
          const SizedBox(height: 16),
          _buildDemandCard(colors),
          const SizedBox(height: 16),
          _buildPumpTypeCard(colors),
          const SizedBox(height: 16),
          _buildHeadBreakdown(colors),
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
                _recommendedHP.toString(),
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
                  ' HP',
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
            'Recommended Pump Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
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
                _buildResultRow(colors, 'Total Dynamic Head', '${_totalDynamicHead.toStringAsFixed(0)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Peak Demand', '${_peakDemand.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pumping Level', '${_pumpingLevel.toStringAsFixed(0)} ft'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Wire Size', _wireSize, highlight: true),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pressure Tank', _tankSize),
              ],
            ),
          ),
          if (_pumpType != _recommendedPumpType) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_pumpTypes[_recommendedPumpType]?.name} recommended for this depth',
                      style: TextStyle(color: colors.accentWarning, fontSize: 10),
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

  Widget _buildWellCard(ZaftoColors colors) {
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
            'WELL DATA',
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
                    Text('Well Depth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_wellDepth.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _wellDepth,
                    min: 25,
                    max: 400,
                    divisions: 75,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _wellDepth = v);
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
                    Text('Static Level', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_staticLevel.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _staticLevel,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _staticLevel = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Water level when not pumping',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drawdown', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_drawdown.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _drawdown,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _drawdown = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'How much level drops while pumping',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(ZaftoColors colors) {
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
            'PIPING',
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
                    Text('Horizontal Run', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_horizontalDistance.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _horizontalDistance,
                    min: 0,
                    max: 300,
                    divisions: 30,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _horizontalDistance = v);
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
                    Text('Vertical Rise', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_verticalRise.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _verticalRise,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _verticalRise = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Elevation from well to highest fixture',
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
            'SYSTEM REQUIREMENTS',
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
                    Text('Peak Demand', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_peakDemand.toStringAsFixed(0)} GPM', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _peakDemand,
                    min: 3,
                    max: 30,
                    divisions: 27,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _peakDemand = v);
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
                    Text('System Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_requiredPressure.toStringAsFixed(0)} psi', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _requiredPressure,
                    min: 30,
                    max: 70,
                    divisions: 8,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _requiredPressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Typical: 40/60 or 50/70 psi cut-in/cut-out',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpTypeCard(ZaftoColors colors) {
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
            'PUMP TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._pumpTypes.entries.map((entry) {
            final isSelected = _pumpType == entry.key;
            final isRecommended = entry.key == _recommendedPumpType;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _pumpType = entry.key);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.value.name,
                                style: TextStyle(
                                  color: isSelected ? colors.accentPrimary : colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isRecommended) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.accentSuccess.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Best',
                                    style: TextStyle(color: colors.accentSuccess, fontSize: 8, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Max ${entry.value.maxDepth} ft - ${entry.value.use}',
                            style: TextStyle(color: colors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
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

  Widget _buildHeadBreakdown(ZaftoColors colors) {
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
            'HEAD CALCULATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pumping Level', '${_pumpingLevel.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Vertical Rise', '${_verticalRise.toStringAsFixed(0)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Lift', '${_totalVerticalLift.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Friction Loss', '${_frictionLoss.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Pressure Head', '${_pressureHead.toStringAsFixed(0)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Dynamic Head', '${_totalDynamicHead.toStringAsFixed(0)} ft', highlight: true),
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
                'NGWA / Pump Standards',
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
            '• TDH = Lift + Friction + Pressure head\n'
            '• Submersible: most efficient > 25 ft\n'
            '• Size pump 10-20% above well yield\n'
            '• Pressure tank prevents short-cycling\n'
            '• Check wire size for voltage drop\n'
            '• Verify well recovery rate',
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
