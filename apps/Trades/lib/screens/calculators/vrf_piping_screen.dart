import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// VRF Piping Calculator - Design System v2.6
/// Variable refrigerant flow piping design
class VrfPipingScreen extends ConsumerStatefulWidget {
  const VrfPipingScreen({super.key});
  @override
  ConsumerState<VrfPipingScreen> createState() => _VrfPipingScreenState();
}

class _VrfPipingScreenState extends ConsumerState<VrfPipingScreen> {
  double _totalCapacity = 120000; // BTU/h
  double _pipeLength = 150; // ft
  double _elevationChange = 30; // ft
  String _pipeSection = 'main';
  String _refrigerantType = 'r410a';
  int _indoorUnits = 8;

  double? _liquidLineSize;
  double? _gasLineSize;
  double? _oilReturn;
  double? _capacityDerating;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // VRF piping based on capacity and length
    // Simplified sizing based on manufacturer guidelines

    double liquidSize;
    double gasSize;

    // Main line sizing based on total capacity
    if (_pipeSection == 'main') {
      if (_totalCapacity <= 48000) {
        liquidSize = 0.375;
        gasSize = 0.75;
      } else if (_totalCapacity <= 96000) {
        liquidSize = 0.5;
        gasSize = 1.0;
      } else if (_totalCapacity <= 150000) {
        liquidSize = 0.5;
        gasSize = 1.125;
      } else if (_totalCapacity <= 250000) {
        liquidSize = 0.625;
        gasSize = 1.375;
      } else {
        liquidSize = 0.75;
        gasSize = 1.625;
      }
    } else {
      // Branch line to individual units
      final perUnitCapacity = _totalCapacity / _indoorUnits;
      if (perUnitCapacity <= 12000) {
        liquidSize = 0.25;
        gasSize = 0.5;
      } else if (perUnitCapacity <= 24000) {
        liquidSize = 0.375;
        gasSize = 0.625;
      } else {
        liquidSize = 0.5;
        gasSize = 0.75;
      }
    }

    // Capacity derating for pipe length
    double lengthDerating = 0;
    if (_pipeLength > 100) {
      lengthDerating = (_pipeLength - 100) * 0.05; // 0.05% per ft over 100
    }

    // Elevation derating
    double elevationDerating = 0;
    if (_elevationChange > 20) {
      elevationDerating = (_elevationChange - 20) * 0.2; // 0.2% per ft over 20
    }

    final capacityDerating = lengthDerating + elevationDerating;

    // Oil return velocity check
    // Minimum velocity required for oil return in risers
    final oilReturn = _elevationChange > 0 ? (_elevationChange > 40 ? 85 : 100) : 100;

    String recommendation;
    if (_pipeSection == 'main') {
      recommendation = 'Main line: ${liquidSize}" liquid, ${gasSize}" suction. Use Y-branches for equal distribution.';
    } else {
      recommendation = 'Branch line: ${liquidSize}" liquid, ${gasSize}" suction per indoor unit.';
    }

    if (_pipeLength > 200) {
      recommendation += ' LONG RUN: Over 200 ft - verify with manufacturer. May need larger pipe or additional oil traps.';
    }

    if (_elevationChange > 40) {
      recommendation += ' HIGH RISE: Install oil trap every 40 ft of vertical rise. Minimum $oilReturn fpm velocity.';
    }

    if (capacityDerating > 10) {
      recommendation += ' Capacity reduced by ${capacityDerating.toStringAsFixed(1)}% due to piping length/elevation.';
    }

    recommendation += ' Braze all joints. Nitrogen flow during brazing. Evacuate to 500 microns.';

    setState(() {
      _liquidLineSize = liquidSize;
      _gasLineSize = gasSize;
      _oilReturn = oilReturn.toDouble();
      _capacityDerating = capacityDerating;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _totalCapacity = 120000;
      _pipeLength = 150;
      _elevationChange = 30;
      _pipeSection = 'main';
      _refrigerantType = 'r410a';
      _indoorUnits = 8;
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
        title: Text('VRF Piping', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PIPE SECTION'),
              const SizedBox(height: 12),
              _buildPipeSectionSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total Capacity', value: _totalCapacity / 1000, min: 24, max: 400, unit: 'k BTU/h', onChanged: (v) { setState(() => _totalCapacity = v * 1000); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Indoor Units', value: _indoorUnits.toDouble(), min: 2, max: 24, unit: ' units', onChanged: (v) { setState(() => _indoorUnits = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPING RUN'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Length', _pipeLength, 25, 500, ' ft', (v) { setState(() => _pipeLength = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Elevation', _elevationChange, 0, 100, ' ft', (v) { setState(() => _elevationChange = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PIPE SIZING'),
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
        Icon(LucideIcons.gitBranch, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('VRF piping varies by manufacturer. Always verify with specific equipment manuals. Use ACR copper or approved tubing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeSectionSelector(ZaftoColors colors) {
    final sections = [('main', 'Main Line'), ('branch', 'Branch Line')];
    return Row(
      children: sections.map((s) {
        final selected = _pipeSection == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeSection = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != sections.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
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
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
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
    if (_liquidLineSize == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${_liquidLineSize?.toStringAsFixed(3)}"', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('Liquid Line', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
            Container(width: 1, height: 60, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${_gasLineSize?.toStringAsFixed(3)}"', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('Suction Line', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ]),
          if ((_capacityDerating ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('Capacity Derating: ${_capacityDerating?.toStringAsFixed(1)}%', style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Per Unit', '${(_totalCapacity / _indoorUnits / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Min Vel', '${_oilReturn?.toStringAsFixed(0)} fpm')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Units', '$_indoorUnits')),
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
