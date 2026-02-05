import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Cooling Tower Sizing Calculator - Design System v2.6
/// Evaporative cooling tower capacity and water treatment
class CoolingTowerScreen extends ConsumerStatefulWidget {
  const CoolingTowerScreen({super.key});
  @override
  ConsumerState<CoolingTowerScreen> createState() => _CoolingTowerScreenState();
}

class _CoolingTowerScreenState extends ConsumerState<CoolingTowerScreen> {
  double _heatRejection = 150; // tons
  double _hotWaterTemp = 95;
  double _coldWaterTemp = 85;
  double _wetBulbTemp = 78;
  String _towerType = 'crossflow';
  double _cyclesConcentration = 5;

  double? _approachTemp;
  double? _rangeTemp;
  double? _gpmFlow;
  double? _evaporationGpm;
  double? _blowdownGpm;
  double? _makeupGpm;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Range = Hot water - Cold water
    final rangeTemp = _hotWaterTemp - _coldWaterTemp;

    // Approach = Cold water - Wet bulb
    final approachTemp = _coldWaterTemp - _wetBulbTemp;

    // Flow rate: GPM = (Tons × 24) / Range
    // For 10°F range: 2.4 GPM per ton
    final gpmFlow = (_heatRejection * 24) / rangeTemp;

    // Evaporation rate: ~1% of flow per 10°F range
    // More precisely: Evap = Flow × Range × 0.001
    final evaporationGpm = gpmFlow * rangeTemp * 0.001;

    // Blowdown: Evap / (Cycles - 1)
    final blowdownGpm = evaporationGpm / (_cyclesConcentration - 1);

    // Makeup water = Evaporation + Blowdown + Drift (~0.005% of flow)
    final driftGpm = gpmFlow * 0.00005;
    final makeupGpm = evaporationGpm + blowdownGpm + driftGpm;

    String recommendation;
    if (approachTemp < 5) {
      recommendation = 'Very low approach - may require oversized tower or multiple cells.';
    } else if (approachTemp < 7) {
      recommendation = 'Low approach (${approachTemp.toStringAsFixed(0)}°F) - premium tower selection needed.';
    } else {
      recommendation = 'Approach of ${approachTemp.toStringAsFixed(0)}°F is achievable with standard tower.';
    }

    if (_towerType == 'crossflow') {
      recommendation += ' Crossflow: Lower pump head, easier maintenance access.';
    } else {
      recommendation += ' Counterflow: More compact footprint, higher efficiency.';
    }

    if (_cyclesConcentration < 4) {
      recommendation += ' Low cycles increase water usage - verify water treatment program.';
    } else if (_cyclesConcentration > 6) {
      recommendation += ' High cycles reduce water use but require careful chemistry control.';
    }

    recommendation += ' Makeup: ${makeupGpm.toStringAsFixed(1)} GPM. Ensure adequate supply and treatment.';

    setState(() {
      _approachTemp = approachTemp;
      _rangeTemp = rangeTemp;
      _gpmFlow = gpmFlow;
      _evaporationGpm = evaporationGpm;
      _blowdownGpm = blowdownGpm;
      _makeupGpm = makeupGpm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _heatRejection = 150;
      _hotWaterTemp = 95;
      _coldWaterTemp = 85;
      _wetBulbTemp = 78;
      _towerType = 'crossflow';
      _cyclesConcentration = 5;
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
        title: Text('Cooling Tower', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'HEAT REJECTION'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Rejection', value: _heatRejection, min: 20, max: 500, unit: ' tons', onChanged: (v) { setState(() => _heatRejection = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WATER TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Hot Water', _hotWaterTemp, 85, 105, '°F', (v) { setState(() => _hotWaterTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Cold Water', _coldWaterTemp, 75, 95, '°F', (v) { setState(() => _coldWaterTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design Wet Bulb', value: _wetBulbTemp, min: 65, max: 82, unit: '°F', onChanged: (v) { setState(() => _wetBulbTemp = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TOWER TYPE'),
              const SizedBox(height: 12),
              _buildTowerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Cycles of Concentration', value: _cyclesConcentration, min: 2, max: 10, unit: 'x', onChanged: (v) { setState(() => _cyclesConcentration = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TOWER SIZING'),
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
        Icon(LucideIcons.cloudRain, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Cooling tower: Approach = cold water - wet bulb. Range = hot - cold. Typical: 7°F approach, 10°F range.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildTowerTypeSelector(ZaftoColors colors) {
    final types = [('crossflow', 'Crossflow'), ('counterflow', 'Counterflow')];
    return Row(
      children: types.map((t) {
        final selected = _towerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _towerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
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
    if (_gpmFlow == null) return const SizedBox.shrink();

    final isGoodApproach = _approachTemp! >= 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('APPROACH', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${_approachTemp?.toStringAsFixed(0)}°F', style: TextStyle(color: isGoodApproach ? Colors.green : colors.accentWarning, fontSize: 24, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('RANGE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${_rangeTemp?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('Flow Rate: ${_gpmFlow?.toStringAsFixed(0)} GPM', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Evaporation', '${_evaporationGpm?.toStringAsFixed(1)} GPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Blowdown', '${_blowdownGpm?.toStringAsFixed(1)} GPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Makeup', '${_makeupGpm?.toStringAsFixed(1)} GPM')),
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
