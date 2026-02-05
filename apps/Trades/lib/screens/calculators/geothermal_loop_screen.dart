import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Geothermal Loop Sizing Calculator - Design System v2.6
/// Ground loop length for GSHP systems
class GeothermalLoopScreen extends ConsumerStatefulWidget {
  const GeothermalLoopScreen({super.key});
  @override
  ConsumerState<GeothermalLoopScreen> createState() => _GeothermalLoopScreenState();
}

class _GeothermalLoopScreenState extends ConsumerState<GeothermalLoopScreen> {
  double _systemTons = 3;
  String _loopType = 'vertical';
  String _soilType = 'clay';
  double _designEwt = 30;
  String _dominantMode = 'heating';
  bool _hasDesuperheater = false;

  double? _boreDepth;
  double? _totalLength;
  int? _numberOfBores;
  double? _flowGpm;
  String? _loopDesign;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Loop sizing based on soil conductivity and load
    // Soil thermal conductivity (BTU/hr-ft-°F)
    double soilConductivity;
    switch (_soilType) {
      case 'sand_dry': soilConductivity = 0.4; break;
      case 'sand_wet': soilConductivity = 1.3; break;
      case 'clay': soilConductivity = 1.0; break;
      case 'rock': soilConductivity = 1.8; break;
      case 'saturated': soilConductivity = 1.5; break;
      default: soilConductivity = 1.0;
    }

    // Load in BTU/hr (12,000 BTU/ton)
    final loadBtu = _systemTons * 12000;

    // Heat transfer rate depends on soil and mode
    // Heating: extract heat from ground
    // Cooling: reject heat to ground
    double heatTransferRate; // BTU/hr per foot of bore
    if (_dominantMode == 'heating') {
      heatTransferRate = 20 + (soilConductivity * 10); // 30-50 BTU/hr-ft typical
    } else {
      heatTransferRate = 25 + (soilConductivity * 10); // Slightly higher for cooling
    }

    double totalLength;
    double boreDepth;
    int numberOfBores;
    String loopDesign;

    if (_loopType == 'vertical') {
      // Vertical closed loop
      totalLength = loadBtu / heatTransferRate;
      boreDepth = 200; // Standard bore depth
      numberOfBores = (totalLength / (boreDepth * 2)).ceil(); // Each bore has down + up
      if (numberOfBores < 1) numberOfBores = 1;

      // Adjust bore depth for actual configuration
      boreDepth = totalLength / (numberOfBores * 2);
      if (boreDepth > 400) {
        boreDepth = 300;
        numberOfBores = (totalLength / (boreDepth * 2)).ceil();
      }

      loopDesign = '$numberOfBores bores × ${boreDepth.toStringAsFixed(0)} ft deep';
    } else if (_loopType == 'horizontal') {
      // Horizontal closed loop
      // Less efficient, need 400-600 ft per ton
      totalLength = _systemTons * 500; // Middle ground estimate
      boreDepth = 6; // Burial depth in feet
      numberOfBores = (_systemTons).ceil(); // Approximate trenches

      loopDesign = '${numberOfBores} trenches × ${(totalLength / numberOfBores).toStringAsFixed(0)} ft';
    } else {
      // Pond/lake loop
      totalLength = _systemTons * 300; // Less length needed in water
      boreDepth = 8; // Depth in water
      numberOfBores = (_systemTons * 2).ceil(); // Coils

      loopDesign = '${numberOfBores} coils, ${totalLength.toStringAsFixed(0)} ft total';
    }

    // Flow rate (typically 3 GPM per ton)
    final flowGpm = _systemTons * 3;

    String recommendation;
    if (_loopType == 'vertical') {
      recommendation = 'Vertical loop: Most efficient use of land. Typical bore spacing 15-20 ft. HDPE pipe, thermally fused.';
    } else if (_loopType == 'horizontal') {
      recommendation = 'Horizontal loop: Requires more land area. Burial 4-6 ft deep, below frost line. Slinky coils reduce trench length.';
    } else {
      recommendation = 'Pond loop: Water source must be adequate volume and depth. Anchor coils to prevent floating.';
    }

    if (_designEwt < 25) {
      recommendation += ' Very low EWT may require antifreeze (propylene glycol).';
    }

    if (soilConductivity < 0.6) {
      recommendation += ' Poor soil conductivity - consider thermal conductivity test before final design.';
    }

    if (_hasDesuperheater) {
      recommendation += ' Desuperheater will provide domestic hot water assist.';
    }

    setState(() {
      _boreDepth = boreDepth;
      _totalLength = totalLength;
      _numberOfBores = numberOfBores;
      _flowGpm = flowGpm;
      _loopDesign = loopDesign;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemTons = 3;
      _loopType = 'vertical';
      _soilType = 'clay';
      _designEwt = 30;
      _dominantMode = 'heating';
      _hasDesuperheater = false;
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
        title: Text('Geothermal Loop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Capacity', value: _systemTons, min: 1, max: 10, unit: ' tons', decimals: 1, onChanged: (v) { setState(() => _systemTons = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Dominant Mode', options: const ['Heating', 'Cooling'], selectedIndex: _dominantMode == 'heating' ? 0 : 1, onChanged: (i) { setState(() => _dominantMode = i == 0 ? 'heating' : 'cooling'); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Desuperheater (DHW assist)', _hasDesuperheater, (v) { setState(() => _hasDesuperheater = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOOP TYPE'),
              const SizedBox(height: 12),
              _buildLoopTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'GROUND CONDITIONS'),
              const SizedBox(height: 12),
              _buildSoilTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design Entering Water Temp', value: _designEwt, min: 20, max: 50, unit: '\u00B0F', onChanged: (v) { setState(() => _designEwt = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LOOP SIZING'),
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
        Icon(LucideIcons.globe, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Ground loop sizing depends on soil conductivity and heating/cooling dominance. Always verify with thermal conductivity test.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLoopTypeSelector(ZaftoColors colors) {
    final types = [
      ('vertical', 'Vertical', 'Bores 150-400 ft'),
      ('horizontal', 'Horizontal', 'Trenches 4-6 ft'),
      ('pond', 'Pond/Lake', 'Submerged coils'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _loopType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _loopType = t.$1); _calculate(); },
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

  Widget _buildSoilTypeSelector(ZaftoColors colors) {
    final soils = [
      ('sand_dry', 'Dry Sand', 'Poor'),
      ('sand_wet', 'Wet Sand', 'Good'),
      ('clay', 'Clay', 'Average'),
      ('rock', 'Rock', 'Excellent'),
      ('saturated', 'Saturated', 'Good'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Soil Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: soils.map((s) {
            final selected = _soilType == s.$1;
            return GestureDetector(
              onTap: () { setState(() => _soilType = s.$1); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Column(children: [
                  Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(s.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_totalLength == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_totalLength?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Total Loop Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_loopDesign ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, _loopType == 'vertical' ? 'Bore Depth' : 'Burial', '${_boreDepth?.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, _loopType == 'pond' ? 'Coils' : 'Bores/Trenches', '$_numberOfBores')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Flow Rate', '${_flowGpm?.toStringAsFixed(0)} GPM')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PIPE SPEC', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('1" or 1-1/4" HDPE DR-11, thermally fused joints', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
