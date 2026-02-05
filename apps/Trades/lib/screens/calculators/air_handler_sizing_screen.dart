import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Air Handler Sizing Calculator - Design System v2.6
/// AHU selection based on load and airflow
class AirHandlerSizingScreen extends ConsumerStatefulWidget {
  const AirHandlerSizingScreen({super.key});
  @override
  ConsumerState<AirHandlerSizingScreen> createState() => _AirHandlerSizingScreenState();
}

class _AirHandlerSizingScreenState extends ConsumerState<AirHandlerSizingScreen> {
  double _coolingLoad = 120000; // BTU/hr
  double _heatingLoad = 80000; // BTU/hr
  double _supplyAirTemp = 55; // degrees F
  double _returnAirTemp = 75; // degrees F
  double _outsideAirPercent = 20; // percent
  String _ahuType = 'packaged';
  String _fanType = 'forward_curved';

  double? _requiredCfm;
  double? _coilTonnage;
  double? _staticPressure;
  double? _fanHp;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // CFM = BTU/hr ÷ (1.08 × ΔT)
    final deltaT = _returnAirTemp - _supplyAirTemp;
    final requiredCfm = _coolingLoad / (1.08 * deltaT);

    // Coil tonnage
    final coilTonnage = _coolingLoad / 12000;

    // Static pressure estimate based on system type
    double staticPressure;
    switch (_ahuType) {
      case 'packaged':
        staticPressure = 0.5 + (_outsideAirPercent * 0.01);
        break;
      case 'modular':
        staticPressure = 1.0 + (_outsideAirPercent * 0.015);
        break;
      case 'custom':
        staticPressure = 1.5 + (_outsideAirPercent * 0.02);
        break;
      default:
        staticPressure = 1.0;
    }

    // Fan HP estimate
    // BHP = (CFM × SP) ÷ (6356 × efficiency)
    double fanEfficiency;
    switch (_fanType) {
      case 'forward_curved':
        fanEfficiency = 0.60;
        break;
      case 'backward_curved':
        fanEfficiency = 0.75;
        break;
      case 'airfoil':
        fanEfficiency = 0.80;
        break;
      case 'plug_fan':
        fanEfficiency = 0.70;
        break;
      default:
        fanEfficiency = 0.65;
    }
    final fanBhp = (requiredCfm * staticPressure) / (6356 * fanEfficiency);
    final fanHp = (fanBhp * 1.15).ceilToDouble(); // Add service factor and round up

    String recommendation;
    recommendation = 'Required: ${requiredCfm.toStringAsFixed(0)} CFM for ${_coolingLoad.toStringAsFixed(0)} BTU/hr. ';
    recommendation += 'Coil: ${coilTonnage.toStringAsFixed(1)} ton capacity. ';
    recommendation += 'ESP: ${staticPressure.toStringAsFixed(2)}" WC. Fan: ${fanHp.toStringAsFixed(0)} HP. ';

    // CFM per ton check
    final cfmPerTon = requiredCfm / coilTonnage;
    if (cfmPerTon < 350) {
      recommendation += 'LOW CFM/ton (${cfmPerTon.toStringAsFixed(0)}) - may need larger coil or lower SA temp. ';
    } else if (cfmPerTon > 500) {
      recommendation += 'HIGH CFM/ton (${cfmPerTon.toStringAsFixed(0)}) - good latent capacity. ';
    } else {
      recommendation += 'CFM/ton: ${cfmPerTon.toStringAsFixed(0)} (400 typical). ';
    }

    switch (_ahuType) {
      case 'packaged':
        recommendation += 'Packaged AHU: Self-contained, rooftop or indoor. Simpler install.';
        break;
      case 'modular':
        recommendation += 'Modular AHU: Sectional assembly. Flexible configuration.';
        break;
      case 'custom':
        recommendation += 'Custom AHU: Built to spec. Highest efficiency potential.';
        break;
    }

    switch (_fanType) {
      case 'forward_curved':
        recommendation += ' FC fans: Compact, quiet, but less efficient.';
        break;
      case 'backward_curved':
        recommendation += ' BC fans: More efficient, non-overloading.';
        break;
      case 'airfoil':
        recommendation += ' Airfoil: Highest efficiency, best for large systems.';
        break;
      case 'plug_fan':
        recommendation += ' Plug fans: Direct drive, compact. Good with VFD.';
        break;
    }

    setState(() {
      _requiredCfm = requiredCfm;
      _coilTonnage = coilTonnage;
      _staticPressure = staticPressure;
      _fanHp = fanHp;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingLoad = 120000;
      _heatingLoad = 80000;
      _supplyAirTemp = 55;
      _returnAirTemp = 75;
      _outsideAirPercent = 20;
      _ahuType = 'packaged';
      _fanType = 'forward_curved';
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
        title: Text('Air Handler Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'AHU TYPE'),
              const SizedBox(height: 12),
              _buildAhuTypeSelector(colors),
              const SizedBox(height: 12),
              _buildFanTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOADS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Cooling', _coolingLoad, 24000, 600000, ' BTU/hr', (v) { setState(() => _coolingLoad = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Heating', _heatingLoad, 0, 400000, ' BTU/hr', (v) { setState(() => _heatingLoad = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply', _supplyAirTemp, 50, 65, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Return', _returnAirTemp, 70, 80, '°F', (v) { setState(() => _returnAirTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildCompactSlider(colors, 'Outside Air', _outsideAirPercent, 0, 100, '%', (v) { setState(() => _outsideAirPercent = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AHU SIZING'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('AHU sized for CFM = BTU ÷ (1.08 × ΔT). Target 400 CFM/ton. Consider static pressure for fan sizing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildAhuTypeSelector(ZaftoColors colors) {
    final types = [('packaged', 'Packaged'), ('modular', 'Modular'), ('custom', 'Custom')];
    return Row(
      children: types.map((t) {
        final selected = _ahuType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _ahuType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildFanTypeSelector(ZaftoColors colors) {
    final types = [('forward_curved', 'FC'), ('backward_curved', 'BC'), ('airfoil', 'Airfoil'), ('plug_fan', 'Plug')];
    return Row(
      children: types.map((t) {
        final selected = _fanType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _fanType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_requiredCfm == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_requiredCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: [
                Text('${_coilTonnage?.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                Text('Tons', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
              Column(children: [
                Text('${_staticPressure?.toStringAsFixed(2)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                Text('ESP', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
              Column(children: [
                Text('${_fanHp?.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                Text('HP', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Cooling', '${(_coolingLoad / 12000).toStringAsFixed(1)} tons')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'ΔT', '${(_returnAirTemp - _supplyAirTemp).toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CFM/Ton', '${(_requiredCfm! / _coilTonnage!).toStringAsFixed(0)}')),
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
