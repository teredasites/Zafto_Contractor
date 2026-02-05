import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Ejector Pump Sizing Calculator - Design System v2.6
///
/// Sizes sewage ejector pumps for basement bathrooms and below-grade fixtures.
/// Calculates GPM, head, and HP requirements.
///
/// References: IPC 712, Pump manufacturer guidelines
class EjectorPumpScreen extends ConsumerStatefulWidget {
  const EjectorPumpScreen({super.key});
  @override
  ConsumerState<EjectorPumpScreen> createState() => _EjectorPumpScreenState();
}

class _EjectorPumpScreenState extends ConsumerState<EjectorPumpScreen> {
  // Fixture count
  int _toilets = 1;
  int _showers = 0;
  int _lavatories = 1;
  int _washingMachines = 0;
  int _floorDrains = 0;
  int _utilSinks = 0;

  // Vertical lift (feet)
  double _verticalLift = 10.0;

  // Horizontal run (feet)
  double _horizontalRun = 20.0;

  // Discharge pipe size
  String _pipeSize = '2'; // inches

  // Basin size
  String _basinSize = '24x24'; // diameter x depth

  // Application type
  String _applicationType = 'residential';

  // DFU values per IPC Table 709.1
  static const Map<String, double> _dfuValues = {
    'toilet': 4.0,
    'shower': 2.0,
    'lavatory': 1.0,
    'washingMachine': 2.0,
    'floorDrain': 2.0,
    'utilSink': 2.0,
  };

  // Friction loss per 100 ft (approximation for sewage)
  static const Map<String, double> _frictionLoss = {
    '1.5': 8.0,
    '2': 4.5,
    '2.5': 2.8,
    '3': 1.8,
  };

  // Basin sizes with capacities
  static const Map<String, ({int gallons, String note})> _basinSizes = {
    '18x24': (gallons: 18, note: 'Minimum for 1 fixture'),
    '24x24': (gallons: 30, note: 'Standard residential'),
    '24x30': (gallons: 38, note: '2-3 fixtures'),
    '30x30': (gallons: 45, note: 'Multiple fixtures'),
    '36x30': (gallons: 55, note: 'Heavy use'),
  };

  double get _totalDFU {
    return (_toilets * _dfuValues['toilet']!) +
        (_showers * _dfuValues['shower']!) +
        (_lavatories * _dfuValues['lavatory']!) +
        (_washingMachines * _dfuValues['washingMachine']!) +
        (_floorDrains * _dfuValues['floorDrain']!) +
        (_utilSinks * _dfuValues['utilSink']!);
  }

  // GPM requirement based on DFU
  double get _requiredGPM {
    // Approximate conversion: residential typically 1.5-2 GPM per DFU for peak
    // Toilets drive the major flow requirement
    if (_toilets >= 1) {
      return 30 + (_totalDFU - 4) * 2; // Base 30 GPM for toilet, add for others
    }
    return _totalDFU * 5; // Non-toilet fixtures
  }

  // Total dynamic head calculation
  double get _frictionHead {
    final frictionPer100 = _frictionLoss[_pipeSize] ?? 4.5;
    // Add fittings equivalent length (2 elbows = ~10 ft, check valve = ~15 ft)
    final equivalentLength = _horizontalRun + 25; // 25 ft for fittings
    return equivalentLength * frictionPer100 / 100;
  }

  double get _totalHead {
    return _verticalLift + _frictionHead;
  }

  // Recommended HP based on head and GPM
  double get _recommendedHP {
    // Rule of thumb: HP = (GPM * Head) / 3960 / 0.5 (50% efficiency)
    // Plus safety factor
    final calcHP = (_requiredGPM * _totalHead) / 3960 / 0.5;
    if (calcHP <= 0.33) return 0.33;
    if (calcHP <= 0.5) return 0.5;
    if (calcHP <= 0.75) return 0.75;
    if (calcHP <= 1.0) return 1.0;
    if (calcHP <= 1.5) return 1.5;
    return 2.0;
  }

  String get _recommendedPumpSize {
    if (_totalDFU <= 6) return '4/10 HP Sewage Ejector';
    if (_totalDFU <= 12) return '1/2 HP Sewage Ejector';
    if (_totalDFU <= 20) return '3/4 HP Sewage Ejector';
    return '1 HP+ Sewage Ejector';
  }

  String get _minPipeSize {
    if (_toilets > 0) return '2"'; // Code requirement for solids-handling
    if (_totalDFU > 10) return '2"';
    return '1-1/2"';
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
          'Ejector Pump Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildPipingCard(colors),
          const SizedBox(height: 16),
          _buildBasinCard(colors),
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
          Text(
            '${_recommendedHP.toString()} HP',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _recommendedPumpSize,
            style: TextStyle(color: colors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
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
                _buildResultRow(colors, 'Total DFU', _totalDFU.toStringAsFixed(0)),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Required Flow', '${_requiredGPM.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total Head', '${_totalHead.toStringAsFixed(1)} ft'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Min Discharge', _minPipeSize, highlight: true),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Vent Required', '2" min'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Must have alarm for high water level',
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
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
            'FIXTURES SERVED',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildFixtureRow(colors, 'Toilets', _toilets, 4, (v) => setState(() => _toilets = v)),
          _buildFixtureRow(colors, 'Showers/Tubs', _showers, 2, (v) => setState(() => _showers = v)),
          _buildFixtureRow(colors, 'Lavatories', _lavatories, 1, (v) => setState(() => _lavatories = v)),
          _buildFixtureRow(colors, 'Washing Machines', _washingMachines, 2, (v) => setState(() => _washingMachines = v)),
          _buildFixtureRow(colors, 'Floor Drains', _floorDrains, 2, (v) => setState(() => _floorDrains = v)),
          _buildFixtureRow(colors, 'Utility Sinks', _utilSinks, 2, (v) => setState(() => _utilSinks = v)),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int value, int dfu, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                Text('$dfu DFU each', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
          Row(
            children: [
              _buildCounterButton(colors, LucideIcons.minus, () {
                if (value > 0) onChanged(value - 1);
              }),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _buildCounterButton(colors, LucideIcons.plus, () {
                onChanged(value + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 16),
      ),
    );
  }

  Widget _buildPipingCard(ZaftoColors colors) {
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
                    Text('Vertical Lift', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_verticalLift.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _verticalLift,
                    min: 5,
                    max: 40,
                    divisions: 35,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _verticalLift = v);
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
                    Text('Horizontal Run', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_horizontalRun.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'DISCHARGE PIPE SIZE',
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
            children: ['1.5', '2', '2.5', '3'].map((size) {
              final isSelected = _pipeSize == size;
              final isTooSmall = _toilets > 0 && size == '1.5';
              return GestureDetector(
                onTap: isTooSmall ? null : () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : (isTooSmall ? colors.bgBase.withValues(alpha: 0.5) : colors.bgBase),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size"',
                    style: TextStyle(
                      color: isSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : (isTooSmall ? colors.textTertiary : colors.textPrimary),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_toilets > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Min 2" required for solids-handling',
              style: TextStyle(color: colors.accentWarning, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasinCard(ZaftoColors colors) {
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
            'BASIN SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._basinSizes.entries.map((entry) {
            final isSelected = _basinSize == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _basinSize = entry.key);
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
                        '${entry.key}" (${entry.value.gallons} gal)',
                        style: TextStyle(
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      entry.value.note,
                      style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
            'HEAD CALCULATION BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Static Head (Vertical)', '${_verticalLift.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Friction Loss', '${_frictionHead.toStringAsFixed(1)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Dynamic Head', '${_totalHead.toStringAsFixed(1)} ft', highlight: true),
          const SizedBox(height: 12),
          Text(
            'Friction loss includes ~25 ft equivalent for fittings',
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
                'IPC 2024 Section 712',
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
            '• 712.1 - Sewage pumps/ejectors required below sewer\n'
            '• 712.3.3 - Capacity based on fixture units\n'
            '• 712.3.4 - Min 2" solids-handling discharge\n'
            '• 712.4 - Basin sized for pump cycle\n'
            '• 712.5 - Alarm required for high water\n'
            '• 712.2 - Vent required (min 2")',
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
