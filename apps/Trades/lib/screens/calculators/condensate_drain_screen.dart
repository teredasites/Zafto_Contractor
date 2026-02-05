import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Condensate Drain Calculator - Design System v2.6
/// Condensate drain line sizing and trap seal depth
class CondensateDrainScreen extends ConsumerStatefulWidget {
  const CondensateDrainScreen({super.key});
  @override
  ConsumerState<CondensateDrainScreen> createState() => _CondensateDrainScreenState();
}

class _CondensateDrainScreenState extends ConsumerState<CondensateDrainScreen> {
  double _coolingTons = 5;
  double _staticPressure = 1.0; // inches WC (negative)
  double _drainLength = 20; // feet
  String _drainType = 'gravity';
  String _equipmentType = 'ahu';

  double? _condensateRate;
  double? _pipeSize;
  double? _trapDepth;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Condensate rate: approximately 0.5-1.5 gal/hr per ton depending on conditions
    // Using 1.0 gal/hr/ton as typical for comfort cooling
    double condensateMultiplier;
    switch (_equipmentType) {
      case 'ahu':
        condensateMultiplier = 1.0;
        break;
      case 'fcu':
        condensateMultiplier = 0.8;
        break;
      case 'ptac':
        condensateMultiplier = 0.6;
        break;
      case 'dx_coil':
        condensateMultiplier = 1.2;
        break;
      default:
        condensateMultiplier = 1.0;
    }

    final condensateRate = _coolingTons * condensateMultiplier;

    // Minimum pipe size based on condensate rate
    // 3/4" handles up to 2 gph, 1" up to 4 gph, etc.
    double pipeSize;
    if (condensateRate <= 2) {
      pipeSize = 0.75;
    } else if (condensateRate <= 4) {
      pipeSize = 1.0;
    } else if (condensateRate <= 8) {
      pipeSize = 1.25;
    } else if (condensateRate <= 15) {
      pipeSize = 1.5;
    } else {
      pipeSize = 2.0;
    }

    // Adjust for drain length
    if (_drainLength > 50) {
      pipeSize = math.max(pipeSize, 1.0);
    }

    // Trap seal depth = static pressure + 1" safety
    // P-trap must be deeper than unit negative pressure to prevent air infiltration
    final trapDepth = _staticPressure + 1.0;

    String recommendation;
    recommendation = 'Condensate: ${condensateRate.toStringAsFixed(1)} gal/hr. ';

    if (_drainType == 'gravity') {
      recommendation += 'Gravity drain: ${pipeSize.toStringAsFixed(2)}" minimum. Slope 1/8" to 1/4" per foot.';
    } else {
      recommendation += 'Condensate pump required. Size pump for ${(condensateRate * 1.5).toStringAsFixed(1)} gph capacity.';
    }

    recommendation += ' P-trap: ${trapDepth.toStringAsFixed(1)}" deep minimum to seal against ${_staticPressure.toStringAsFixed(1)}" WC negative pressure.';

    if (_staticPressure > 3) {
      recommendation += ' WARNING: High negative pressure. Consider deep seal trap or fabricated trap.';
    }

    switch (_equipmentType) {
      case 'ahu':
        recommendation += ' AHU: Trap on each drain pan. Clean-out access required.';
        break;
      case 'fcu':
        recommendation += ' FCU: Integral trap or external P-trap. Maintain prime in seasonal units.';
        break;
      case 'ptac':
        recommendation += ' PTAC: Slinger ring or condensate pump. Check drain clearance.';
        break;
      case 'dx_coil':
        recommendation += ' DX coil: Secondary drain pan recommended. Overflow switch for protection.';
        break;
    }

    if (_drainType == 'gravity') {
      recommendation += ' Vent drain line downstream of trap if long run or multiple connections.';
    }

    setState(() {
      _condensateRate = condensateRate;
      _pipeSize = pipeSize;
      _trapDepth = trapDepth;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingTons = 5;
      _staticPressure = 1.0;
      _drainLength = 20;
      _drainType = 'gravity';
      _equipmentType = 'ahu';
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
        title: Text('Condensate Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EQUIPMENT TYPE'),
              const SizedBox(height: 12),
              _buildEquipmentSelector(colors),
              const SizedBox(height: 12),
              _buildDrainTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM PARAMETERS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Cooling', _coolingTons, 1, 50, ' tons', (v) { setState(() => _coolingTons = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Static', _staticPressure, 0.5, 6, '" WC', (v) { setState(() => _staticPressure = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DRAIN RUN'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Drain Length', value: _drainLength, min: 5, max: 100, unit: ' ft', onChanged: (v) { setState(() => _drainLength = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DRAIN SIZING'),
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
        Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Condensate ~1 gal/hr per ton. P-trap depth must exceed unit negative pressure to maintain seal. Slope drain 1/8"-1/4" per foot.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildEquipmentSelector(ZaftoColors colors) {
    final types = [('ahu', 'AHU'), ('fcu', 'FCU'), ('ptac', 'PTAC'), ('dx_coil', 'DX Coil')];
    return Row(
      children: types.map((t) {
        final selected = _equipmentType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _equipmentType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrainTypeSelector(ZaftoColors colors) {
    final types = [('gravity', 'Gravity Drain'), ('pump', 'Condensate Pump')];
    return Row(
      children: types.map((t) {
        final selected = _drainType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _drainType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_pipeSize == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_pipeSize?.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Minimum Drain Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('${_trapDepth?.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('Minimum Trap Depth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Condensate', '${_condensateRate?.toStringAsFixed(1)} gph')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cooling', '${_coolingTons.toStringAsFixed(0)} tons')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Static', '${_staticPressure.toStringAsFixed(1)}" WC')),
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
}
