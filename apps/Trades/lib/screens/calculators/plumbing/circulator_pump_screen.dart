import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Circulator Pump Sizing - Design System v2.6
///
/// Sizes circulator pumps for hydronic heating/cooling and
/// domestic hot water recirculation systems.
///
/// References: ASHRAE, pump manufacturer guidelines
class CirculatorPumpScreen extends ConsumerStatefulWidget {
  const CirculatorPumpScreen({super.key});
  @override
  ConsumerState<CirculatorPumpScreen> createState() => _CirculatorPumpScreenState();
}

class _CirculatorPumpScreenState extends ConsumerState<CirculatorPumpScreen> {
  // Application type
  String _application = 'recirc';

  // System load (BTU/hr) - for hydronic
  double _systemLoad = 50000;

  // Temperature drop (degrees F)
  double _tempDrop = 20;

  // Total developed length (feet)
  double _totalLength = 150;

  // Pipe size (inches)
  double _pipeSize = 0.75;

  // Number of elbows/fittings
  int _elbows = 8;
  int _tees = 2;
  int _valves = 3;

  // Applications
  static const Map<String, ({String name, String desc, bool usesBTU})> _applications = {
    'recirc': (name: 'Hot Water Recirc', desc: 'DHW recirculation loop', usesBTU: false),
    'baseboard': (name: 'Baseboard Heat', desc: 'Hot water baseboard', usesBTU: true),
    'radiant': (name: 'Radiant Floor', desc: 'In-floor hydronic', usesBTU: true),
    'fanCoil': (name: 'Fan Coil', desc: 'Hydronic fan coil units', usesBTU: true),
    'snowMelt': (name: 'Snow Melt', desc: 'Driveway/walkway', usesBTU: true),
    'pool': (name: 'Pool/Spa', desc: 'Solar or heat pump loop', usesBTU: true),
  };

  // Pipe friction loss (ft head per 100 ft at 4 fps)
  static final Map<double, double> _frictionFactor = {
    0.5: 12.0,
    0.75: 5.5,
    1.0: 3.0,
    1.25: 1.6,
    1.5: 1.0,
    2.0: 0.5,
  };

  // Calculate flow rate (GPM)
  double get _flowRateGPM {
    final app = _applications[_application];
    if (app?.usesBTU == true) {
      // Hydronic: GPM = BTU/hr / (500 × ΔT)
      // 500 = 60 min/hr × 8.33 lb/gal × 1 BTU/lb-°F
      if (_tempDrop <= 0) return 0;
      return _systemLoad / (500 * _tempDrop);
    } else {
      // DHW recirc: typically 1-3 GPM for residential
      // Based on pipe size and recommended velocity
      return _pipeSize * 3; // Rough estimate
    }
  }

  // Equivalent length from fittings
  double get _fittingsEquivalentLength {
    // Approximate equivalent lengths
    final elbowLen = _elbows * (_pipeSize * 3);
    final teeLen = _tees * (_pipeSize * 5);
    final valveLen = _valves * (_pipeSize * 2);
    return elbowLen + teeLen + valveLen;
  }

  double get _totalEquivalentLength {
    return _totalLength + _fittingsEquivalentLength;
  }

  // Head loss (feet of water)
  double get _headLoss {
    final friction = _frictionFactor[_pipeSize] ?? 5.0;
    return (_totalEquivalentLength / 100) * friction;
  }

  // Pump power (rough HP estimate)
  double get _estimatedHP {
    // HP = (GPM × Head) / (3960 × Efficiency)
    // Assume 50% efficiency for small circulators
    return (_flowRateGPM * _headLoss) / (3960 * 0.5);
  }

  String get _recommendedPump {
    final gpm = _flowRateGPM;
    final head = _headLoss;

    if (gpm < 3 && head < 5) return '1/40 HP Circulator';
    if (gpm < 5 && head < 8) return '1/25 HP Circulator';
    if (gpm < 8 && head < 12) return '1/12 HP Circulator';
    if (gpm < 15 && head < 20) return '1/6 HP Circulator';
    if (gpm < 25 && head < 30) return '1/4 HP Circulator';
    return '1/2 HP+ Circulator';
  }

  String get _pumpConnection {
    if (_pipeSize <= 0.75) return '1/2" or 3/4" Sweat';
    if (_pipeSize <= 1.0) return '3/4" or 1" Sweat';
    if (_pipeSize <= 1.5) return '1" or 1-1/4" Flanged';
    return '1-1/2" or 2" Flanged';
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
          'Circulator Pump',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          if (_applications[_application]?.usesBTU == true) ...[
            _buildHydronicCard(colors),
            const SizedBox(height: 16),
          ],
          _buildPipingCard(colors),
          const SizedBox(height: 16),
          _buildFittingsCard(colors),
          const SizedBox(height: 16),
          _buildCalculationBreakdown(colors),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _recommendedPump,
              style: TextStyle(
                color: colors.isDark ? Colors.black : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
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
                _buildResultRow(colors, 'Flow Rate', '${_flowRateGPM.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Head Required', '${_headLoss.toStringAsFixed(1)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Connection', _pumpConnection),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Application', _applications[_application]?.name ?? '', highlight: true),
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
                Icon(LucideIcons.info, color: colors.accentWarning, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verify pump curve covers operating point',
                    style: TextStyle(color: colors.accentWarning, fontSize: 10),
                  ),
                ),
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
          ..._applications.entries.map((entry) {
            final isSelected = _application == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _application = entry.key);
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
                          Text(
                            entry.value.name,
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value.desc,
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

  Widget _buildHydronicCard(ZaftoColors colors) {
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
            'HYDRONIC LOAD',
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
                    Text('System Load', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${(_systemLoad / 1000).toStringAsFixed(0)}k BTU/hr', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _systemLoad,
                    min: 10000,
                    max: 200000,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _systemLoad = v);
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
                    Text('Temp Drop (\u0394T)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_tempDrop.toStringAsFixed(0)}\u00B0F', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _tempDrop,
                    min: 10,
                    max: 40,
                    divisions: 30,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _tempDrop = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Typical: 20\u00B0F baseboard, 10\u00B0F radiant',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
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
          Text('PIPE SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frictionFactor.keys.map((size) {
              final isSelected = _pipeSize == size;
              String label;
              if (size == 0.5) {
                label = '1/2"';
              } else if (size == 0.75) {
                label = '3/4"';
              } else if (size == 1.25) {
                label = '1-1/4"';
              } else if (size == 1.5) {
                label = '1-1/2"';
              } else {
                label = '${size.toInt()}"';
              }
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Developed Length', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_totalLength.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    value: _totalLength,
                    min: 25,
                    max: 500,
                    divisions: 19,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _totalLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total pipe length in loop (supply + return)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFittingsCard(ZaftoColors colors) {
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
            'FITTINGS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildFittingRow(colors, 'Elbows', _elbows, (v) => setState(() => _elbows = v)),
          _buildFittingRow(colors, 'Tees', _tees, (v) => setState(() => _tees = v)),
          _buildFittingRow(colors, 'Valves', _valves, (v) => setState(() => _valves = v)),
          const SizedBox(height: 8),
          Text(
            'Adds ${_fittingsEquivalentLength.toStringAsFixed(1)} ft equivalent length',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFittingRow(ZaftoColors colors, String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          _buildCounterButton(colors, LucideIcons.minus, () {
            if (value > 0) onChanged(value - 1);
          }),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _buildCounterButton(colors, LucideIcons.plus, () {
            onChanged(value + 1);
          }),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildCalculationBreakdown(ZaftoColors colors) {
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
            'CALCULATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_applications[_application]?.usesBTU == true) ...[
            _buildResultRow(colors, 'Formula', 'GPM = BTU/(500×\u0394T)'),
            const SizedBox(height: 6),
            _buildResultRow(colors, 'Load', '${(_systemLoad / 1000).toStringAsFixed(0)}k BTU/hr'),
            const SizedBox(height: 6),
            _buildResultRow(colors, 'Temp Drop', '${_tempDrop.toStringAsFixed(0)}\u00B0F'),
            Divider(color: colors.borderSubtle, height: 16),
          ],
          _buildResultRow(colors, 'Pipe Length', '${_totalLength.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, '+ Fittings Equiv.', '${_fittingsEquivalentLength.toStringAsFixed(1)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Total Equiv. Length', '${_totalEquivalentLength.toStringAsFixed(1)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Flow Rate', '${_flowRateGPM.toStringAsFixed(1)} GPM', highlight: true),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Head Loss', '${_headLoss.toStringAsFixed(1)} ft', highlight: true),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 12,
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
                'ASHRAE / Industry Standards',
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
            '• GPM = BTU/hr / (500 \u00d7 \u0394T)\n'
            '• Head = friction loss + elevation\n'
            '• Size for operating point on curve\n'
            '• DHW recirc: 2-4 fps velocity\n'
            '• Hydronic: 3-5 fps velocity\n'
            '• Consider variable speed pumps',
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
