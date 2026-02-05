import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Snow Melt System Calculator - Design System v2.6
/// Hydronic snow melt sizing for driveways and walkways
class SnowMeltScreen extends ConsumerStatefulWidget {
  const SnowMeltScreen({super.key});
  @override
  ConsumerState<SnowMeltScreen> createState() => _SnowMeltScreenState();
}

class _SnowMeltScreenState extends ConsumerState<SnowMeltScreen> {
  double _area = 500; // sq ft
  double _designSnowfall = 1.0; // inches per hour
  double _designTemp = 20; // outdoor design temp
  String _surfaceType = 'concrete';
  String _application = 'residential';
  String _classification = 'class_2';

  double? _heatOutput;
  double? _totalLoad;
  double? _tubeLength;
  double? _glycolGpm;
  String? _recommendation;

  // Heat output requirements BTU/hr/sqft by ASHRAE classification
  final Map<String, double> _classificationOutput = {
    'class_1': 75,   // Residential, tolerate some accumulation
    'class_2': 125,  // Commercial, keep surfaces clear
    'class_3': 200,  // Critical areas, no accumulation
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Base heat output by classification
    double baseOutput = _classificationOutput[_classification] ?? 125;

    // Adjust for design conditions
    // Higher snowfall rate = more heat
    baseOutput *= _designSnowfall;

    // Adjust for ambient temperature
    // Colder = more heat loss
    if (_designTemp < 0) {
      baseOutput *= 1.3;
    } else if (_designTemp < 15) {
      baseOutput *= 1.15;
    }

    // Surface type adjustment
    switch (_surfaceType) {
      case 'concrete':
        // Base case
        break;
      case 'asphalt':
        baseOutput *= 1.1; // Slightly higher
        break;
      case 'pavers':
        baseOutput *= 1.15; // More insulating
        break;
    }

    final totalLoad = baseOutput * _area;

    // Tube spacing typically 9-12" for snow melt
    // Using 12" for calculation
    final tubeLength = _area; // 1 ft spacing = area in linear ft

    // Flow rate: typical 0.2-0.3 GPM per 1000 BTU/hr
    final glycolGpm = totalLoad * 0.25 / 1000;

    String recommendation;
    recommendation = 'Snow melt: ${baseOutput.toStringAsFixed(0)} BTU/hr/ft² × ${_area.toStringAsFixed(0)} ft² = ${(totalLoad / 1000).toStringAsFixed(1)} MBH total. ';

    switch (_classification) {
      case 'class_1':
        recommendation += 'Class I (residential): Some accumulation OK. Idling recommended.';
        break;
      case 'class_2':
        recommendation += 'Class II (commercial): Surfaces kept clear. Standard commercial choice.';
        break;
      case 'class_3':
        recommendation += 'Class III (critical): No accumulation tolerated. Hospitals, emergency access.';
        break;
    }

    switch (_surfaceType) {
      case 'concrete':
        recommendation += ' Concrete: Good thermal mass. Embed tubes at 2" depth min.';
        break;
      case 'asphalt':
        recommendation += ' Asphalt: Install tubes in sand bed below. Max surface temp 140°F.';
        break;
      case 'pavers':
        recommendation += ' Pavers: Use sand set with tubes below. Consider insulation underneath.';
        break;
    }

    recommendation += ' Supply temp: 100-140°F typical. Use 50% glycol minimum for freeze protection.';

    if (_designTemp < 10) {
      recommendation += ' Cold climate: Consider idling system above 32°F ambient.';
    }

    switch (_application) {
      case 'residential':
        recommendation += ' Residential: Manual or snow sensor activation. Zone larger areas.';
        break;
      case 'commercial':
        recommendation += ' Commercial: Snow/ice sensor with ambient cutoff. Continuous idling option.';
        break;
    }

    recommendation += ' Boiler sizing: ${(totalLoad * 1.25 / 1000).toStringAsFixed(0)} MBH (25% safety factor).';

    setState(() {
      _heatOutput = baseOutput;
      _totalLoad = totalLoad;
      _tubeLength = tubeLength;
      _glycolGpm = glycolGpm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _area = 500;
      _designSnowfall = 1.0;
      _designTemp = 20;
      _surfaceType = 'concrete';
      _application = 'residential';
      _classification = 'class_2';
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
        title: Text('Snow Melt', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM TYPE'),
              const SizedBox(height: 12),
              _buildClassificationSelector(colors),
              const SizedBox(height: 12),
              _buildSurfaceTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AREA & CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Area', _area, 100, 5000, ' ft²', (v) { setState(() => _area = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Snowfall', _designSnowfall, 0.5, 2.5, '"/hr', (v) { setState(() => _designSnowfall = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN TEMPERATURE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Design Temp', value: _designTemp, min: -20, max: 35, unit: '°F', onChanged: (v) { setState(() => _designTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SYSTEM REQUIREMENTS'),
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
        Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('ASHRAE snow melt: Class I 75, Class II 125, Class III 200 BTU/hr/ft². Hydronic with glycol. 9-12" tube spacing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildClassificationSelector(ZaftoColors colors) {
    final classes = [('class_1', 'Class I'), ('class_2', 'Class II'), ('class_3', 'Class III')];
    return Row(
      children: classes.map((c) {
        final selected = _classification == c.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _classification = c.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: c != classes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurfaceTypeSelector(ZaftoColors colors) {
    final surfaces = [('concrete', 'Concrete'), ('asphalt', 'Asphalt'), ('pavers', 'Pavers')];
    return Row(
      children: surfaces.map((s) {
        final selected = _surfaceType == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _surfaceType = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != surfaces.last ? 8 : 0),
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
    if (_totalLoad == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${((_totalLoad ?? 0) / 1000).toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('MBH Total Heat Load', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_heatOutput?.toStringAsFixed(0)} BTU/hr/ft²', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Tube Length', '${_tubeLength?.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Glycol Flow', '${_glycolGpm?.toStringAsFixed(1)} GPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Area', '${_area.toStringAsFixed(0)} ft²')),
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
