import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Walk-In Cooler/Freezer Calculator - Design System v2.6
/// Refrigeration load calculation for walk-ins
class WalkInCoolerScreen extends ConsumerStatefulWidget {
  const WalkInCoolerScreen({super.key});
  @override
  ConsumerState<WalkInCoolerScreen> createState() => _WalkInCoolerScreenState();
}

class _WalkInCoolerScreenState extends ConsumerState<WalkInCoolerScreen> {
  double _length = 10;
  double _width = 8;
  double _height = 8;
  String _boxType = 'cooler';
  double _ambientTemp = 90;
  double _insulation = 4;
  int _doorOpenings = 20;
  double _productLoad = 500;
  double _lightingWatts = 100;
  int _peopleCount = 1;

  double? _wallLoad;
  double? _infiltrationLoad;
  double? _productLoadBtu;
  double? _miscLoad;
  double? _totalLoad;
  double? _evaporatorTons;
  double? _compressorHp;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Box temperature based on type
    final boxTemp = _boxType == 'cooler' ? 35.0 : (_boxType == 'freezer' ? 0.0 : -10.0);
    final deltaT = _ambientTemp - boxTemp;

    // Surface area
    final floorArea = _length * _width;
    final wallArea = 2 * (_length * _height) + 2 * (_width * _height);
    final ceilingArea = floorArea;
    final totalSurface = wallArea + ceilingArea; // Floor often not insulated same

    // Wall transmission load
    // U-factor for insulated panels: ~0.044 for 4" foam
    final uFactor = 0.176 / _insulation; // Approximate
    final wallLoad = totalSurface * uFactor * deltaT * 24; // BTU/day

    // Floor load (reduced since usually on slab)
    final floorLoad = floorArea * 0.08 * deltaT * 24;

    final transmissionLoad = wallLoad + floorLoad;

    // Infiltration load (door openings)
    // Approximate CFM per opening × delta T × 1.08
    final infiltrationCfm = _doorOpenings * 30; // 30 CFM equivalent per opening
    final infiltrationLoad = infiltrationCfm * 1.08 * deltaT * 60; // Per day estimate

    // Product load (cooling incoming product)
    // Assume product enters at ambient, needs to reach box temp
    // Specific heat ~0.9 BTU/lb/°F average
    final productLoadBtu = _productLoad * 0.9 * deltaT;

    // Miscellaneous loads
    final lightingLoad = _lightingWatts * 3.41 * 12; // 12 hours runtime
    final peopleLoad = _peopleCount * 600 * 4; // 600 BTU/hr, 4 hours
    final miscLoad = lightingLoad + peopleLoad;

    // Total daily load
    final totalDaily = transmissionLoad + infiltrationLoad + productLoadBtu + miscLoad;

    // Convert to hourly load (24 hr operation, but compressor runs ~16-18 hrs)
    final totalHourly = totalDaily / 16; // 16 hr runtime

    // Evaporator sizing (typically 10-15% oversized)
    final evapBtu = totalHourly * 1.15;
    final evapTons = evapBtu / 12000;

    // Compressor HP (roughly 1 HP per 8000-12000 BTU depending on temp)
    final btuPerHp = _boxType == 'cooler' ? 12000 : (_boxType == 'freezer' ? 8000 : 6000);
    final compressorHp = evapBtu / btuPerHp;

    String recommendation;
    if (_boxType == 'cooler') {
      recommendation = 'Walk-in cooler: R-404A or R-448A typical. Medium temp evap coil. Maintain 35-38°F product temp.';
    } else if (_boxType == 'freezer') {
      recommendation = 'Walk-in freezer: Low temp system required. Electric defrost on evap. Maintain 0 to -10°F.';
    } else {
      recommendation = 'Low temp freezer: Very low temp system. Multiple compressors or scroll may be needed.';
    }

    if (_insulation < 4 && _boxType != 'cooler') {
      recommendation += ' Insulation may be inadequate for this temperature. Consider 5-6" panels.';
    }

    if (_doorOpenings > 30) {
      recommendation += ' High door traffic. Consider strip curtains or rapid-roll door.';
    }

    setState(() {
      _wallLoad = transmissionLoad;
      _infiltrationLoad = infiltrationLoad;
      _productLoadBtu = productLoadBtu;
      _miscLoad = miscLoad;
      _totalLoad = totalHourly;
      _evaporatorTons = evapTons;
      _compressorHp = compressorHp;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _length = 10;
      _width = 8;
      _height = 8;
      _boxType = 'cooler';
      _ambientTemp = 90;
      _insulation = 4;
      _doorOpenings = 20;
      _productLoad = 500;
      _lightingWatts = 100;
      _peopleCount = 1;
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
        title: Text('Walk-In Cooler', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BOX DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'L', _length, 4, 30, ' ft', (v) { setState(() => _length = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'W', _width, 4, 20, ' ft', (v) { setState(() => _width = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'H', _height, 7, 12, ' ft', (v) { setState(() => _height = v); _calculate(); })),
              ]),
              const SizedBox(height: 16),
              _buildBoxTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ambient Temp', value: _ambientTemp, min: 60, max: 110, unit: '\u00B0F', onChanged: (v) { setState(() => _ambientTemp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Insulation Thickness', value: _insulation, min: 2, max: 6, unit: '"', onChanged: (v) { setState(() => _insulation = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Door Openings/Day', value: _doorOpenings.toDouble(), min: 5, max: 100, unit: '', onChanged: (v) { setState(() => _doorOpenings = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INTERNAL LOADS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Product Load', value: _productLoad, min: 0, max: 2000, unit: ' lbs/day', onChanged: (v) { setState(() => _productLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Lighting', value: _lightingWatts, min: 0, max: 500, unit: ' W', onChanged: (v) { setState(() => _lightingWatts = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'REFRIGERATION SIZING'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildLoadBreakdown(colors),
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
        Icon(LucideIcons.warehouse, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Walk-in load = transmission + infiltration + product + misc. Size evaporator 15% over calculated load.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBoxTypeSelector(ZaftoColors colors) {
    final types = [
      ('cooler', 'Cooler', '35°F'),
      ('freezer', 'Freezer', '0°F'),
      ('lowtemp', 'Low Temp', '-10°F'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _boxType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _boxType = t.$1); _calculate(); },
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
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
    if (_totalLoad == null) return const SizedBox.shrink();

    final boxTemp = _boxType == 'cooler' ? 35 : (_boxType == 'freezer' ? 0 : -10);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${(_totalLoad! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('BTU/hr', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
            Container(width: 1, height: 60, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${_evaporatorTons?.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('Tons', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('${_compressorHp?.toStringAsFixed(1)} HP Compressor', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Box Temp', '$boxTemp°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Volume', '${(_length * _width * _height).toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Surface', '${(2 * (_length * _height) + 2 * (_width * _height) + 2 * (_length * _width)).toStringAsFixed(0)} sq ft')),
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

  Widget _buildLoadBreakdown(ZaftoColors colors) {
    if (_wallLoad == null) return const SizedBox.shrink();

    final loads = [
      ('Transmission (walls/ceiling)', _wallLoad! / 16),
      ('Infiltration (door openings)', _infiltrationLoad! / 16),
      ('Product cooling', _productLoadBtu! / 16),
      ('Misc (lights, people)', _miscLoad! / 16),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOAD BREAKDOWN (BTU/HR)', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...loads.map((l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(l.$1, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
              Text('${(l.$2 / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          )),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_totalLoad! / 1000).toStringAsFixed(1)}k BTU/hr', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
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
