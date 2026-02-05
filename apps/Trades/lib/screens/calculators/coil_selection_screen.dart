import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Coil Selection Calculator - Design System v2.6
/// Heating and cooling coil sizing for AHUs and fan coils
class CoilSelectionScreen extends ConsumerStatefulWidget {
  const CoilSelectionScreen({super.key});
  @override
  ConsumerState<CoilSelectionScreen> createState() => _CoilSelectionScreenState();
}

class _CoilSelectionScreenState extends ConsumerState<CoilSelectionScreen> {
  String _coilType = 'cooling';
  double _capacity = 60000; // BTU/h
  double _airCfm = 2000;
  double _enteringAirDb = 80;
  double _enteringAirWb = 67;
  double _leavingAirDb = 55;
  double _enteringWaterTemp = 45;
  double _leavingWaterTemp = 55;
  int _rows = 4;

  double? _faceVelocity;
  double? _faceArea;
  double? _waterGpm;
  double? _airPressureDrop;
  double? _waterPressureDrop;
  double? _sensibleHeat;
  double? _latentHeat;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Face velocity (target 450-550 fpm for cooling, up to 700 for heating)
    final maxVelocity = _coilType == 'cooling' ? 500.0 : 650.0;
    final faceArea = _airCfm / maxVelocity;
    final faceVelocity = _airCfm / faceArea;

    // Water flow rate
    // GPM = BTU / (500 × ΔT)
    final waterDeltaT = (_leavingWaterTemp - _enteringWaterTemp).abs();
    final waterGpm = _capacity / (500 * waterDeltaT);

    // Estimate pressure drops
    // Air side: ~0.1" WC per row at 500 fpm
    final airPressureDrop = _rows * 0.08 * math.pow(faceVelocity / 500, 2);

    // Water side: ~2-5 ft head per row
    final waterPressureDrop = _rows * 2.5;

    // Sensible and latent heat (for cooling coils)
    double sensibleHeat;
    double latentHeat;

    if (_coilType == 'cooling') {
      // Estimate sensible/latent split
      // Q_sensible = 1.08 × CFM × ΔT_db
      final airDeltaDb = _enteringAirDb - _leavingAirDb;
      sensibleHeat = 1.08 * _airCfm * airDeltaDb;
      latentHeat = _capacity - sensibleHeat;
      if (latentHeat < 0) latentHeat = 0;
    } else {
      sensibleHeat = _capacity;
      latentHeat = 0;
    }

    // Coil dimensions estimate
    // Standard fin spacing: 10-14 FPI for cooling
    final finsPerInch = _coilType == 'cooling' ? 12 : 10;

    String recommendation;
    if (_coilType == 'cooling') {
      recommendation = 'Cooling coil: ${_rows}-row, ${finsPerInch} FPI typical. ';
      if (faceVelocity > 550) {
        recommendation += 'High face velocity may cause moisture carryover. ';
      }
      if (latentHeat > sensibleHeat * 0.5) {
        recommendation += 'Significant latent load - ensure adequate drain pan. ';
      }
    } else {
      recommendation = 'Heating coil: ${_rows}-row adequate for most applications. ';
      if (_enteringWaterTemp > 160) {
        recommendation += 'High water temp - use steam coil if >180°F. ';
      }
    }

    if (waterGpm < 1) {
      recommendation += 'Low GPM - verify control valve for low-flow operation. ';
    }

    recommendation += 'Coil face: ${faceArea.toStringAsFixed(1)} sq ft. Water: ${waterGpm.toStringAsFixed(1)} GPM.';

    setState(() {
      _faceVelocity = faceVelocity;
      _faceArea = faceArea;
      _waterGpm = waterGpm;
      _airPressureDrop = airPressureDrop;
      _waterPressureDrop = waterPressureDrop;
      _sensibleHeat = sensibleHeat;
      _latentHeat = latentHeat;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coilType = 'cooling';
      _capacity = 60000;
      _airCfm = 2000;
      _enteringAirDb = 80;
      _enteringAirWb = 67;
      _leavingAirDb = 55;
      _enteringWaterTemp = 45;
      _leavingWaterTemp = 55;
      _rows = 4;
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
        title: Text('Coil Selection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COIL TYPE'),
              const SizedBox(height: 12),
              _buildCoilTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CAPACITY'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Capacity', value: _capacity, min: 10000, max: 200000, unit: ' BTU', displayK: true, onChanged: (v) { setState(() => _capacity = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Airflow', value: _airCfm, min: 400, max: 10000, unit: ' CFM', onChanged: (v) { setState(() => _airCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Coil Rows', value: _rows.toDouble(), min: 2, max: 8, unit: '', onChanged: (v) { setState(() => _rows = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Entering DB', _enteringAirDb, 65, 95, '°F', (v) { setState(() => _enteringAirDb = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Leaving DB', _leavingAirDb, 50, 70, '°F', (v) { setState(() => _leavingAirDb = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WATER CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Entering', _enteringWaterTemp, 35, 180, '°F', (v) { setState(() => _enteringWaterTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Leaving', _leavingWaterTemp, 45, 200, '°F', (v) { setState(() => _leavingWaterTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COIL SIZING'),
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
        Expanded(child: Text('Coil selection: Target 450-550 fpm face velocity for cooling. 4-6 rows typical for DX/chilled water.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCoilTypeSelector(ZaftoColors colors) {
    final types = [
      ('cooling', 'Cooling Coil', 'CHW/DX'),
      ('heating', 'Heating Coil', 'Hot Water'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _coilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _coilType = t.$1;
                if (t.$1 == 'heating') {
                  _enteringWaterTemp = 140;
                  _leavingWaterTemp = 120;
                } else {
                  _enteringWaterTemp = 45;
                  _leavingWaterTemp = 55;
                }
              });
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool displayK = false, required ValueChanged<double> onChanged}) {
    final displayValue = displayK ? '${(value / 1000).toStringAsFixed(0)}k$unit' : '${value.toStringAsFixed(0)}$unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_faceArea == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_faceArea?.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('Coil Face Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('AIR SIDE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${_faceVelocity?.toStringAsFixed(0)} fpm', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('${_airPressureDrop?.toStringAsFixed(2)}" WC', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('WATER SIDE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${_waterGpm?.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('${_waterPressureDrop?.toStringAsFixed(1)} ft head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
          ]),
          if (_coilType == 'cooling') ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildResultItem(colors, 'Sensible', '${(_sensibleHeat! / 1000).toStringAsFixed(1)}k BTU')),
              Container(width: 1, height: 40, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'Latent', '${(_latentHeat! / 1000).toStringAsFixed(1)}k BTU')),
              Container(width: 1, height: 40, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'SHR', '${(_sensibleHeat! / _capacity).toStringAsFixed(2)}')),
            ]),
          ],
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
