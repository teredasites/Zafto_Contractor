import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Radiant Floor Heating Calculator - Design System v2.6
/// Tube spacing and output for hydronic radiant systems
class RadiantFloorScreen extends ConsumerStatefulWidget {
  const RadiantFloorScreen({super.key});
  @override
  ConsumerState<RadiantFloorScreen> createState() => _RadiantFloorScreenState();
}

class _RadiantFloorScreenState extends ConsumerState<RadiantFloorScreen> {
  double _roomSquareFeet = 500;
  double _heatLossPerSqFt = 25;
  String _floorCovering = 'tile';
  double _supplyWaterTemp = 120;
  String _tubeSpacing = '9';
  String _tubeSize = 'half';

  double? _totalHeatLoss;
  double? _btusPerSqFt;
  double? _totalTubeLength;
  double? _loopCount;
  double? _flowGpm;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total heat loss
    final totalHeatLoss = _roomSquareFeet * _heatLossPerSqFt;

    // Floor covering R-value affects output
    double coveringRValue;
    switch (_floorCovering) {
      case 'tile': coveringRValue = 0.05; break;
      case 'hardwood': coveringRValue = 0.68; break;
      case 'carpet_thin': coveringRValue = 1.0; break;
      case 'carpet_thick': coveringRValue = 2.0; break;
      case 'concrete': coveringRValue = 0.0; break;
      default: coveringRValue = 0.5;
    }

    // Mean radiant panel temp (simplified)
    final roomTemp = 70.0;
    final meanFluidTemp = _supplyWaterTemp - 15; // Delta T across panel
    final panelSurfaceTemp = meanFluidTemp - (coveringRValue * 10); // Rough estimate

    // BTU output per sq ft based on panel surface temp
    // Higher temp differential = more output
    final tempDiff = panelSurfaceTemp - roomTemp;
    // Approximate: 2 BTU/sq ft per °F temperature difference
    var btusPerSqFt = tempDiff * 2.0;

    // Adjust for tube spacing
    double spacingFactor;
    switch (_tubeSpacing) {
      case '6': spacingFactor = 1.2; break;
      case '9': spacingFactor = 1.0; break;
      case '12': spacingFactor = 0.85; break;
      default: spacingFactor = 1.0;
    }
    btusPerSqFt *= spacingFactor;

    // Verify we can meet load
    final canMeetLoad = btusPerSqFt >= _heatLossPerSqFt;

    // Calculate tube length
    // Feet of tube per sq ft = 12 / spacing(inches)
    final tubePerSqFt = 12 / double.parse(_tubeSpacing);
    final totalTubeLength = _roomSquareFeet * tubePerSqFt;

    // Loop sizing (max loop length depends on tube size)
    double maxLoopLength;
    if (_tubeSize == 'half') {
      maxLoopLength = 300; // 1/2" PEX
    } else if (_tubeSize == 'fiveeighths') {
      maxLoopLength = 400; // 5/8" PEX
    } else {
      maxLoopLength = 500; // 3/4" PEX
    }

    final loopCount = (totalTubeLength / maxLoopLength).ceil();

    // Flow rate (typically 0.5 GPM per 10,000 BTU)
    final flowGpm = totalHeatLoss / 10000 * 0.5;

    String recommendation;
    if (!canMeetLoad) {
      recommendation = 'Panel output may not meet heat loss. Consider tighter spacing, higher supply temp, or supplemental heat.';
    } else if (coveringRValue > 1.5) {
      recommendation = 'High R-value floor covering significantly reduces output. Max floor surface temp ~85°F for comfort.';
    } else {
      recommendation = 'Design appears adequate. Supply water temp should maintain floor surface at 80-85°F max.';
    }

    if (_supplyWaterTemp > 140) {
      recommendation += ' High supply temp - verify floor material tolerances.';
    }

    recommendation += ' Typical: ${_tubeSpacing}" O.C. spacing, ${loopCount} loops with manifold.';

    setState(() {
      _totalHeatLoss = totalHeatLoss;
      _btusPerSqFt = btusPerSqFt;
      _totalTubeLength = totalTubeLength;
      _loopCount = loopCount.toDouble();
      _flowGpm = flowGpm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomSquareFeet = 500;
      _heatLossPerSqFt = 25;
      _floorCovering = 'tile';
      _supplyWaterTemp = 120;
      _tubeSpacing = '9';
      _tubeSize = 'half';
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
        title: Text('Radiant Floor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Area', value: _roomSquareFeet, min: 100, max: 2000, unit: ' sq ft', onChanged: (v) { setState(() => _roomSquareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Loss', value: _heatLossPerSqFt, min: 10, max: 50, unit: ' BTU/sq ft', onChanged: (v) { setState(() => _heatLossPerSqFt = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLOOR COVERING'),
              const SizedBox(height: 12),
              _buildFloorCoveringSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM DESIGN'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Supply Water Temp', value: _supplyWaterTemp, min: 90, max: 160, unit: '\u00B0F', onChanged: (v) { setState(() => _supplyWaterTemp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildTubeSpacingSelector(colors),
              const SizedBox(height: 12),
              _buildTubeSizeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DESIGN SUMMARY'),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Radiant floor output depends on tube spacing, supply temp, and floor covering. Max surface temp ~85°F for comfort.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFloorCoveringSelector(ZaftoColors colors) {
    final coverings = [
      ('tile', 'Tile/Stone', 'R-0.05'),
      ('hardwood', 'Hardwood', 'R-0.68'),
      ('carpet_thin', 'Thin Carpet', 'R-1.0'),
      ('carpet_thick', 'Thick Carpet', 'R-2.0'),
      ('concrete', 'Exposed Concrete', 'R-0'),
    ];
    return Column(
      children: coverings.map((c) {
        final selected = _floorCovering == c.$1;
        return GestureDetector(
          onTap: () { setState(() => _floorCovering = c.$1); _calculate(); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(children: [
              Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Text(c.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 12)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTubeSpacingSelector(ZaftoColors colors) {
    final spacings = ['6', '9', '12'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tube Spacing', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: spacings.map((s) {
            final selected = _tubeSpacing == s;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _tubeSpacing = s); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: s != spacings.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text('$s" O.C.', style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTubeSizeSelector(ZaftoColors colors) {
    final sizes = [('half', '1/2"'), ('fiveeighths', '5/8"'), ('threequarters', '3/4"')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tube Size (PEX)', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((s) {
            final selected = _tubeSize == s.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _tubeSize = s.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: s != sizes.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
    if (_totalTubeLength == null) return const SizedBox.shrink();

    final meetsLoad = _btusPerSqFt! >= _heatLossPerSqFt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: meetsLoad ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(meetsLoad ? 'DESIGN ADEQUATE' : 'REVIEW DESIGN', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Load', '${(_totalHeatLoss! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItemColored(colors, 'Panel Output', '${_btusPerSqFt?.toStringAsFixed(0)} BTU/sf', meetsLoad ? Colors.green : Colors.orange)),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Req\'d Output', '${_heatLossPerSqFt.toStringAsFixed(0)} BTU/sf')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Tube Length', '${_totalTubeLength?.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Loops', '${_loopCount?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Flow Rate', '${_flowGpm?.toStringAsFixed(1)} GPM')),
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
