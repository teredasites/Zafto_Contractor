import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Hydronic Flow Calculator - Design System v2.6
/// GPM and head loss for hydronic heating/cooling systems
class HydronicFlowScreen extends ConsumerStatefulWidget {
  const HydronicFlowScreen({super.key});
  @override
  ConsumerState<HydronicFlowScreen> createState() => _HydronicFlowScreenState();
}

class _HydronicFlowScreenState extends ConsumerState<HydronicFlowScreen> {
  double _loadBtu = 100000;
  double _deltaT = 20;
  String _fluid = 'water';
  double _glycolPercent = 30;
  double _pipeSize = 1.0; // inches
  double _pipeLength = 100; // feet

  double? _gpm;
  double? _velocity;
  double? _headLoss;
  double? _reynoldsNumber;
  String? _flowRegime;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Specific heat and density adjustments for glycol
    double specificHeat; // BTU/lb-°F
    double density; // lb/gal

    if (_fluid == 'water') {
      specificHeat = 1.0;
      density = 8.33;
    } else {
      // Propylene glycol corrections
      specificHeat = 1.0 - (_glycolPercent * 0.006); // Decreases with glycol
      density = 8.33 + (_glycolPercent * 0.02); // Increases with glycol
    }

    // GPM = BTU/h / (500 * ΔT) for water
    // Adjusted: GPM = BTU/h / (density * 60 * specificHeat * ΔT)
    final gpm = _loadBtu / (density * 60 * specificHeat * _deltaT);

    // Pipe internal diameter (Schedule 40)
    final pipeIds = {
      0.5: 0.622,
      0.75: 0.824,
      1.0: 1.049,
      1.25: 1.380,
      1.5: 1.610,
      2.0: 2.067,
      2.5: 2.469,
      3.0: 3.068,
    };
    final idInches = pipeIds[_pipeSize] ?? _pipeSize * 0.9;
    final idFeet = idInches / 12;

    // Cross-sectional area
    final areaSqFt = math.pi * math.pow(idFeet / 2, 2);

    // Velocity (ft/s) = GPM / (area * 7.48)
    final velocity = (gpm / 7.48) / areaSqFt / 60;

    // Reynolds number
    final kinematicViscosity = _fluid == 'water' ? 1.08e-5 : 1.08e-5 * (1 + _glycolPercent * 0.03);
    final reynolds = (velocity * idFeet) / kinematicViscosity;

    String flowRegime;
    if (reynolds < 2300) {
      flowRegime = 'Laminar';
    } else if (reynolds < 4000) {
      flowRegime = 'Transitional';
    } else {
      flowRegime = 'Turbulent';
    }

    // Friction factor (Swamee-Jain for turbulent)
    final roughness = 0.00015 / idFeet; // Copper pipe
    double frictionFactor;
    if (reynolds < 2300) {
      frictionFactor = 64 / reynolds;
    } else {
      frictionFactor = 0.25 / math.pow(math.log(roughness / 3.7 + 5.74 / math.pow(reynolds, 0.9)) / math.ln10, 2);
    }

    // Head loss (ft) = f * L/D * v²/2g
    final headLoss = frictionFactor * (_pipeLength / idFeet) * math.pow(velocity, 2) / (2 * 32.2);

    String recommendation;
    if (velocity > 8) {
      recommendation = 'HIGH VELOCITY (${velocity.toStringAsFixed(1)} fps). May cause noise and erosion. Increase pipe size.';
    } else if (velocity > 6) {
      recommendation = 'Velocity on high end. Consider next size up for quiet operation.';
    } else if (velocity < 2) {
      recommendation = 'Low velocity may allow air accumulation and poor heat transfer. Consider smaller pipe or increased flow.';
    } else {
      recommendation = 'Velocity in optimal range (2-6 fps) for quiet operation and heat transfer.';
    }

    if (_fluid == 'glycol') {
      recommendation += ' Glycol reduces capacity ${(_glycolPercent * 0.6).toStringAsFixed(0)}%. Increase flow or delta T to compensate.';
    }

    recommendation += ' Total head loss: ${headLoss.toStringAsFixed(1)} ft. Size pump accordingly.';

    setState(() {
      _gpm = gpm;
      _velocity = velocity;
      _headLoss = headLoss;
      _reynoldsNumber = reynolds;
      _flowRegime = flowRegime;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _loadBtu = 100000;
      _deltaT = 20;
      _fluid = 'water';
      _glycolPercent = 30;
      _pipeSize = 1.0;
      _pipeLength = 100;
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
        title: Text('Hydronic Flow', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Load', value: _loadBtu / 1000, min: 10, max: 500, unit: 'k BTU/h', onChanged: (v) { setState(() => _loadBtu = v * 1000); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design Delta T', value: _deltaT, min: 10, max: 40, unit: '°F', onChanged: (v) { setState(() => _deltaT = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLUID'),
              const SizedBox(height: 12),
              _buildFluidSelector(colors),
              if (_fluid == 'glycol') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Glycol Concentration', value: _glycolPercent, min: 10, max: 50, unit: '%', onChanged: (v) { setState(() => _glycolPercent = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPING'),
              const SizedBox(height: 12),
              _buildPipeSizeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Pipe Run Length', value: _pipeLength, min: 25, max: 500, unit: ' ft', onChanged: (v) { setState(() => _pipeLength = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FLOW ANALYSIS'),
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
        Icon(LucideIcons.waves, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('GPM = BTU/h ÷ (500 × ΔT) for water. Target 2-6 fps velocity. Glycol reduces capacity.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFluidSelector(ZaftoColors colors) {
    final fluids = [('water', 'Water'), ('glycol', 'Glycol Mix')];
    return Row(
      children: fluids.map((f) {
        final selected = _fluid == f.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _fluid = f.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: f != fluids.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(f.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPipeSizeSelector(ZaftoColors colors) {
    final sizes = [
      (0.75, '3/4"'),
      (1.0, '1"'),
      (1.25, '1-1/4"'),
      (1.5, '1-1/2"'),
      (2.0, '2"'),
    ];
    return Row(
      children: sizes.map((s) {
        final selected = _pipeSize == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeSize = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != sizes.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_gpm == null) return const SizedBox.shrink();

    final velocityOk = (_velocity ?? 0) >= 2 && (_velocity ?? 0) <= 6;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_gpm?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('GPM Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: velocityOk ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_velocity?.toStringAsFixed(1)} fps - $_flowRegime', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Head Loss', '${_headLoss?.toStringAsFixed(1)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${_deltaT.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Reynolds', '${(_reynoldsNumber! / 1000).toStringAsFixed(1)}k')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(velocityOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: velocityOk ? Colors.green : Colors.orange, size: 16),
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
}
