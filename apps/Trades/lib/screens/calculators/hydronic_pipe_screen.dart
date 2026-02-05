import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Hydronic Pipe Sizing Calculator - Design System v2.6
/// GPM to pipe size for hot water heating systems
class HydronicPipeScreen extends ConsumerStatefulWidget {
  const HydronicPipeScreen({super.key});
  @override
  ConsumerState<HydronicPipeScreen> createState() => _HydronicPipeScreenState();
}

class _HydronicPipeScreenState extends ConsumerState<HydronicPipeScreen> {
  double _loadBtu = 50000;
  double _deltaT = 20;
  String _pipeType = 'copper';
  double _maxVelocity = 4;

  double? _gpmRequired;
  String? _pipeSize;
  double? _velocity;
  double? _headLoss;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // GPM = BTU / (500 × ΔT)
    final gpm = _loadBtu / (500 * _deltaT);

    // Pipe sizing tables (simplified)
    // Based on flow rate and max velocity
    String pipeSize;
    double velocity;
    double headLossPer100;

    // Internal diameters (inches): 1/2"=0.545, 3/4"=0.785, 1"=1.025, 1-1/4"=1.380, 1-1/2"=1.610, 2"=2.067
    final pipeSizes = [
      ('1/2"', 0.545),
      ('3/4"', 0.785),
      ('1"', 1.025),
      ('1-1/4"', 1.380),
      ('1-1/2"', 1.610),
      ('2"', 2.067),
      ('2-1/2"', 2.469),
      ('3"', 3.068),
    ];

    // Find smallest pipe that keeps velocity under max
    pipeSize = pipeSizes.last.$1;
    double id = pipeSizes.last.$2;

    for (final pipe in pipeSizes) {
      final area = math.pi * math.pow(pipe.$2 / 2, 2); // sq in
      final vel = (gpm * 0.408) / area; // 0.408 converts GPM/sq in to FPS
      if (vel <= _maxVelocity) {
        pipeSize = pipe.$1;
        id = pipe.$2;
        velocity = vel;
        break;
      }
    }

    // Recalculate actual velocity
    final area = math.pi * math.pow(id / 2, 2);
    velocity = (gpm * 0.408) / area;

    // Head loss (Hazen-Williams, C=130 for copper)
    // Simplified: head loss ≈ (0.2083 × Q^1.852) / (C^1.852 × D^4.87) × 100
    final c = _pipeType == 'copper' ? 130.0 : (_pipeType == 'pex' ? 140.0 : 150.0);
    headLossPer100 = (0.2083 * math.pow(gpm, 1.852)) / (math.pow(c, 1.852) * math.pow(id, 4.87)) * 100;

    String recommendation;
    if (velocity > 4) {
      recommendation = 'Velocity exceeds 4 FPS. May cause noise and erosion. Consider larger pipe.';
    } else if (velocity < 1.5) {
      recommendation = 'Low velocity may allow air to settle. Consider smaller pipe or ensure air removal.';
    } else {
      recommendation = 'Good velocity range (1.5-4 FPS) for quiet operation and efficient heat transfer.';
    }

    if (_pipeType == 'pex') {
      recommendation += ' PEX: Use oxygen-barrier type for closed hydronic systems.';
    }

    setState(() {
      _gpmRequired = gpm;
      _pipeSize = pipeSize;
      _velocity = velocity;
      _headLoss = headLossPer100;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _loadBtu = 50000;
      _deltaT = 20;
      _pipeType = 'copper';
      _maxVelocity = 4;
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
        title: Text('Hydronic Pipe', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Load', value: _loadBtu, min: 10000, max: 200000, unit: ' BTU/hr', onChanged: (v) { setState(() => _loadBtu = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design ΔT', value: _deltaT, min: 10, max: 40, unit: '\u00B0F', onChanged: (v) { setState(() => _deltaT = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPE TYPE'),
              const SizedBox(height: 12),
              _buildPipeTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Velocity', value: _maxVelocity, min: 2, max: 8, unit: ' FPS', decimals: 1, onChanged: (v) { setState(() => _maxVelocity = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PIPE SIZING'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildFlowChart(colors),
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
        Icon(LucideIcons.pipette, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('GPM = BTU ÷ (500 × ΔT). Size for 1.5-4 FPS velocity. Lower ΔT = more GPM = larger pipe.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeTypeSelector(ZaftoColors colors) {
    final types = [
      ('copper', 'Copper', 'Type L/M'),
      ('pex', 'PEX', 'Oxygen barrier'),
      ('cpvc', 'CPVC', 'Schedule 80'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _pipeType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU/hr' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : (decimals > 0 ? '${value.toStringAsFixed(decimals)}$unit' : '${value.toStringAsFixed(0)}$unit');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_pipeSize == null) return const SizedBox.shrink();

    Color velocityColor;
    if (_velocity! < 1.5) {
      velocityColor = Colors.orange;
    } else if (_velocity! > 4) {
      velocityColor = Colors.red;
    } else {
      velocityColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_pipeSize!, style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('${_pipeType.toUpperCase()} Pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Flow Rate', '${_gpmRequired?.toStringAsFixed(1)} GPM')),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItemColored(colors, 'Velocity', '${_velocity?.toStringAsFixed(1)} FPS', velocityColor)),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Head Loss', '${_headLoss?.toStringAsFixed(2)} ft/100')),
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

  Widget _buildFlowChart(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COPPER PIPE CAPACITIES @ 4 FPS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildCapacityRow(colors, '1/2"', '1.6 GPM', '~16k BTU'),
          _buildCapacityRow(colors, '3/4"', '3.5 GPM', '~35k BTU'),
          _buildCapacityRow(colors, '1"', '6.0 GPM', '~60k BTU'),
          _buildCapacityRow(colors, '1-1/4"', '11 GPM', '~110k BTU'),
          _buildCapacityRow(colors, '1-1/2"', '15 GPM', '~150k BTU'),
          _buildCapacityRow(colors, '2"', '25 GPM', '~250k BTU'),
        ],
      ),
    );
  }

  Widget _buildCapacityRow(ZaftoColors colors, String size, String gpm, String btu) {
    final isSelected = _pipeSize == size;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        SizedBox(width: 50, child: Text(size, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
        Expanded(child: Text(gpm, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        Text(btu, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
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
