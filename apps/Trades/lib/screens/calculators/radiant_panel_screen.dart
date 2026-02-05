import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Radiant Panel Calculator - Design System v2.6
/// Radiant ceiling/wall panel sizing and water temp
class RadiantPanelScreen extends ConsumerStatefulWidget {
  const RadiantPanelScreen({super.key});
  @override
  ConsumerState<RadiantPanelScreen> createState() => _RadiantPanelScreenState();
}

class _RadiantPanelScreenState extends ConsumerState<RadiantPanelScreen> {
  double _roomArea = 500; // sq ft
  double _ceilingHeight = 10;
  double _heatLoad = 30; // BTU/h per sq ft
  double _meanWaterTemp = 120;
  double _roomTemp = 68;
  String _panelType = 'ceiling';
  String _panelMaterial = 'steel';

  double? _totalLoad;
  double? _panelCapacity;
  double? _panelAreaNeeded;
  double? _coveragePercent;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total heating load
    final totalLoad = _roomArea * _heatLoad;

    // Panel output depends on MWT - Room Temp
    final tempDifference = _meanWaterTemp - _roomTemp;

    // Base panel capacity (BTU/h per sq ft)
    // Varies by panel type and material
    double baseFactor;
    double materialFactor;

    switch (_panelType) {
      case 'ceiling':
        baseFactor = 2.0;
        break;
      case 'wall':
        baseFactor = 1.8;
        break;
      case 'floor':
        baseFactor = 1.5; // Lower output per sq ft for radiant floor
        break;
      default:
        baseFactor = 2.0;
    }

    switch (_panelMaterial) {
      case 'steel':
        materialFactor = 1.0;
        break;
      case 'aluminum':
        materialFactor = 1.1;
        break;
      case 'copper':
        materialFactor = 1.15;
        break;
      default:
        materialFactor = 1.0;
    }

    // Panel capacity = baseFactor * materialFactor * (MWT - RoomTemp)^1.1
    // Approximation based on ASHRAE data
    final panelCapacity = baseFactor * materialFactor * _power(tempDifference, 1.1);

    // Panel area needed
    final panelAreaNeeded = totalLoad / panelCapacity;

    // Coverage percentage
    double availableSurface;
    if (_panelType == 'ceiling') {
      availableSurface = _roomArea;
    } else if (_panelType == 'wall') {
      // Estimate wall area minus windows/doors
      availableSurface = _roomArea * 0.7 * 4 / (_ceilingHeight / 10);
    } else {
      availableSurface = _roomArea;
    }

    final coveragePercent = (panelAreaNeeded / availableSurface) * 100;

    String recommendation;
    if (coveragePercent > 90) {
      recommendation = 'Panel area exceeds available surface (${coveragePercent.toStringAsFixed(0)}%). Increase water temp or add supplemental heat.';
    } else if (coveragePercent > 70) {
      recommendation = 'High panel coverage (${coveragePercent.toStringAsFixed(0)}%). Verify layout allows for lights and diffusers.';
    } else if (coveragePercent > 40) {
      recommendation = 'Good panel coverage. Standard layouts work well. Zone panels near perimeter.';
    } else {
      recommendation = 'Low coverage required. Consider lower water temp to improve comfort and efficiency.';
    }

    if (_panelType == 'ceiling') {
      recommendation += ' Ceiling panels: 9-11 ft mounting height optimal. Above 12 ft, increase panel area 15%.';
    } else if (_panelType == 'floor') {
      recommendation += ' Radiant floor: Max surface temp 85°F occupied, 90°F perimeter. Response time slower than panels.';
    }

    if (_meanWaterTemp > 140) {
      recommendation += ' High water temp may cause discomfort. Consider condensing boiler with lower temps.';
    } else if (_meanWaterTemp < 100) {
      recommendation += ' Low temp operation ideal for heat pump source.';
    }

    setState(() {
      _totalLoad = totalLoad;
      _panelCapacity = panelCapacity;
      _panelAreaNeeded = panelAreaNeeded;
      _coveragePercent = coveragePercent;
      _recommendation = recommendation;
    });
  }

  double _power(double base, double exponent) {
    if (base <= 0) return 0;
    return base * (1 + (exponent - 1) * (base - 1) / base / 10);
  }

  void _reset() {
    setState(() {
      _roomArea = 500;
      _ceilingHeight = 10;
      _heatLoad = 30;
      _meanWaterTemp = 120;
      _roomTemp = 68;
      _panelType = 'ceiling';
      _panelMaterial = 'steel';
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
        title: Text('Radiant Panels', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL TYPE'),
              const SizedBox(height: 12),
              _buildPanelTypeSelector(colors),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Area', _roomArea, 100, 2000, ' sq ft', (v) { setState(() => _roomArea = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Ceiling Ht', _ceilingHeight, 8, 20, ' ft', (v) { setState(() => _ceilingHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Load', value: _heatLoad, min: 15, max: 60, unit: ' BTU/sq ft', onChanged: (v) { setState(() => _heatLoad = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Mean Water', _meanWaterTemp, 90, 180, '°F', (v) { setState(() => _meanWaterTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Room Temp', _roomTemp, 60, 75, '°F', (v) { setState(() => _roomTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PANEL SIZING'),
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
        Icon(LucideIcons.sun, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Radiant panels provide comfort at lower air temps. Ceiling panels: 40-70% coverage typical. Lower water temp = better efficiency.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPanelTypeSelector(ZaftoColors colors) {
    final types = [('ceiling', 'Ceiling'), ('wall', 'Wall'), ('floor', 'Floor')];
    return Row(
      children: types.map((t) {
        final selected = _panelType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _panelType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = [('steel', 'Steel'), ('aluminum', 'Aluminum'), ('copper', 'Copper')];
    return Row(
      children: materials.map((m) {
        final selected = _panelMaterial == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _panelMaterial = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != materials.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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
    if (_panelAreaNeeded == null) return const SizedBox.shrink();

    final coverageOk = (_coveragePercent ?? 0) <= 80;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_panelAreaNeeded?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('sq ft of Panel Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: coverageOk ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_coveragePercent?.toStringAsFixed(0)}% Coverage', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Load', '${(_totalLoad! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Panel Cap.', '${_panelCapacity?.toStringAsFixed(0)} BTU/sf')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${(_meanWaterTemp - _roomTemp).toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(coverageOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: coverageOk ? Colors.green : Colors.orange, size: 16),
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
