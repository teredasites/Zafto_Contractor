import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Pump Head Calculator - Design System v2.6
/// Total dynamic head for hydronic pump selection
class PumpHeadScreen extends ConsumerStatefulWidget {
  const PumpHeadScreen({super.key});
  @override
  ConsumerState<PumpHeadScreen> createState() => _PumpHeadScreenState();
}

class _PumpHeadScreenState extends ConsumerState<PumpHeadScreen> {
  double _gpm = 20;
  double _pipeLength = 200;
  double _fittingEquivalent = 50;
  double _staticLift = 0;
  String _pipeSize = '1';
  String _pipeMaterial = 'copper';

  double? _frictionHead;
  double? _staticHead;
  double? _totalHead;
  double? _velocityFps;
  String? _pumpSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Pipe internal diameters (inches)
    final pipeDiameters = {
      '3/4': 0.785,
      '1': 1.025,
      '1-1/4': 1.380,
      '1-1/2': 1.610,
      '2': 2.067,
      '2-1/2': 2.469,
      '3': 3.068,
    };

    final id = pipeDiameters[_pipeSize] ?? 1.025;

    // Velocity = GPM × 0.408 / Area
    final area = math.pi * math.pow(id / 2, 2);
    final velocity = (_gpm * 0.408) / area;

    // Hazen-Williams C values
    final cValues = {
      'copper': 130.0,
      'pex': 140.0,
      'steel': 120.0,
      'cpvc': 150.0,
    };
    final c = cValues[_pipeMaterial] ?? 130.0;

    // Total equivalent length
    final totalLength = _pipeLength + _fittingEquivalent;

    // Friction loss (Hazen-Williams): hf = 10.67 × L × Q^1.852 / (C^1.852 × D^4.87)
    // Simplified for ft of head per 100 ft
    final frictionPer100 = (0.2083 * math.pow(_gpm, 1.852)) /
                           (math.pow(c, 1.852) * math.pow(id, 4.87)) * 100;
    final frictionHead = frictionPer100 * (totalLength / 100);

    // Static head (closed loop = 0, open system = lift)
    final staticHead = _staticLift;

    // Total dynamic head
    final totalHead = frictionHead + staticHead;

    // Pump sizing recommendation
    String pumpSize;
    if (totalHead < 10 && _gpm < 15) {
      pumpSize = '1/25 HP Circulator';
    } else if (totalHead < 15 && _gpm < 25) {
      pumpSize = '1/12 HP Circulator';
    } else if (totalHead < 20 && _gpm < 35) {
      pumpSize = '1/6 HP Circulator';
    } else if (totalHead < 30 && _gpm < 50) {
      pumpSize = '1/4 HP Circulator';
    } else {
      pumpSize = '1/2+ HP Pump';
    }

    String recommendation;
    if (velocity > 4) {
      recommendation = 'Velocity exceeds 4 FPS - may cause noise and erosion. Consider larger pipe.';
    } else if (velocity < 1.5) {
      recommendation = 'Low velocity - good for quiet operation but ensure air removal at high points.';
    } else {
      recommendation = 'Velocity in optimal range (1.5-4 FPS). Good balance of quiet operation and efficiency.';
    }

    if (totalHead > 25) {
      recommendation += ' High head - verify pump curve covers this operating point with margin.';
    }

    setState(() {
      _frictionHead = frictionHead;
      _staticHead = staticHead;
      _totalHead = totalHead;
      _velocityFps = velocity;
      _pumpSize = pumpSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _gpm = 20;
      _pipeLength = 200;
      _fittingEquivalent = 50;
      _staticLift = 0;
      _pipeSize = '1';
      _pipeMaterial = 'copper';
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pump Head', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLOW & PIPING'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Flow Rate', value: _gpm, min: 5, max: 100, unit: ' GPM', onChanged: (v) { setState(() => _gpm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildPipeSizeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Pipe Material', options: const ['Copper', 'PEX', 'Steel', 'CPVC'], selectedIndex: ['copper', 'pex', 'steel', 'cpvc'].indexOf(_pipeMaterial), onChanged: (i) { setState(() => _pipeMaterial = ['copper', 'pex', 'steel', 'cpvc'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM LENGTH'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Pipe Length', value: _pipeLength, min: 50, max: 500, unit: ' ft', onChanged: (v) { setState(() => _pipeLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Fitting Equivalent', value: _fittingEquivalent, min: 0, max: 200, unit: ' ft', onChanged: (v) { setState(() => _fittingEquivalent = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Static Lift', value: _staticLift, min: 0, max: 50, unit: ' ft', onChanged: (v) { setState(() => _staticLift = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PUMP SELECTION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TDH = friction + static. Closed loops have no static head. Select pump where curve crosses operating point.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeSizeSelector(ZaftoColors colors) {
    final sizes = ['3/4', '1', '1-1/4', '1-1/2', '2', '2-1/2', '3'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipe Size', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((s) {
            final selected = _pipeSize == s;
            return GestureDetector(
              onTap: () { setState(() => _pipeSize = s); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Text('$s"', style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_totalHead == null) return const SizedBox.shrink();

    Color velocityColor;
    if (_velocityFps! < 1.5) {
      velocityColor = Colors.orange;
    } else if (_velocityFps! > 4) {
      velocityColor = Colors.red;
    } else {
      velocityColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_totalHead?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Feet of Head (TDH)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_pumpSize ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Friction Head', '${_frictionHead?.toStringAsFixed(1)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Static Head', '${_staticHead?.toStringAsFixed(1)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItemColored(colors, 'Velocity', '${_velocityFps?.toStringAsFixed(1)} FPS', velocityColor)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }

  Widget _buildResultItemColored(ZaftoColors colors, String label, String value, Color valueColor) {
    return Column(children: [
      Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
