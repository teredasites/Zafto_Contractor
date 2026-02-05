import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// TXV Sizing Calculator - Design System v2.6
/// Thermostatic expansion valve selection and diagnosis
class TxvSizingScreen extends ConsumerStatefulWidget {
  const TxvSizingScreen({super.key});
  @override
  ConsumerState<TxvSizingScreen> createState() => _TxvSizingScreenState();
}

class _TxvSizingScreenState extends ConsumerState<TxvSizingScreen> {
  double _systemCapacity = 60000; // BTU/hr
  double _evapTemp = 40; // degrees F
  double _condTemp = 105; // degrees F
  double _liquidSubcooling = 10; // degrees F
  String _refrigerant = 'r410a';
  String _txvType = 'external_eq';

  double? _txvTonnage;
  double? _pressureDrop;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // TXV sizing typically 100-120% of system capacity
    final txvTonnage = (_systemCapacity / 12000) * 1.1; // 10% oversizing

    // Pressure drop across TXV (rough estimate based on conditions)
    final pressureDifferential = _condTemp - _evapTemp;
    double pressureDrop;

    switch (_refrigerant) {
      case 'r410a':
        pressureDrop = pressureDifferential * 3.5; // psig approximate
        break;
      case 'r22':
        pressureDrop = pressureDifferential * 2.0;
        break;
      case 'r134a':
        pressureDrop = pressureDifferential * 1.5;
        break;
      case 'r404a':
        pressureDrop = pressureDifferential * 2.5;
        break;
      default:
        pressureDrop = pressureDifferential * 2.5;
    }

    String recommendation;
    recommendation = 'System: ${(_systemCapacity / 12000).toStringAsFixed(1)} tons. TXV: ${txvTonnage.toStringAsFixed(1)} ton rating. ';
    recommendation += 'ΔP across valve: ~${pressureDrop.toStringAsFixed(0)} psi. ';

    // Subcooling check
    if (_liquidSubcooling < 5) {
      recommendation += 'LOW subcooling: TXV may flash before entering. Add charge or check condenser. ';
    } else if (_liquidSubcooling > 20) {
      recommendation += 'HIGH subcooling: System may be overcharged or restriction present. ';
    } else {
      recommendation += 'Subcooling ${_liquidSubcooling.toStringAsFixed(0)}°F OK. ';
    }

    switch (_txvType) {
      case 'external_eq':
        recommendation += 'External equalized: Required for distributors or long suction lines. Eq line after evap. ';
        break;
      case 'internal_eq':
        recommendation += 'Internal equalized: OK for single circuit, low pressure drop evaporators. ';
        break;
      case 'electronic':
        recommendation += 'Electronic EXV: Precise control, requires controller. Better part-load efficiency. ';
        break;
    }

    // Refrigerant notes
    switch (_refrigerant) {
      case 'r410a':
        recommendation += 'R-410A: Higher pressures, ensure TXV rated for 410A.';
        break;
      case 'r22':
        recommendation += 'R-22: Phase out. Consider replacement system.';
        break;
      case 'r134a':
        recommendation += 'R-134a: Automotive/chiller refrigerant.';
        break;
      case 'r404a':
        recommendation += 'R-404A: Commercial refrigeration. High GWP.';
        break;
    }

    recommendation += ' Superheat setting typically 8-12°F. Check bulb contact and insulation.';

    setState(() {
      _txvTonnage = txvTonnage;
      _pressureDrop = pressureDrop;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemCapacity = 60000;
      _evapTemp = 40;
      _condTemp = 105;
      _liquidSubcooling = 10;
      _refrigerant = 'r410a';
      _txvType = 'external_eq';
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
        title: Text('TXV Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'REFRIGERANT'),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 12),
              _buildTxvTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Capacity', _systemCapacity, 12000, 300000, ' BTU/hr', (v) { setState(() => _systemCapacity = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Subcooling', _liquidSubcooling, 0, 30, '°F', (v) { setState(() => _liquidSubcooling = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Evap Temp', _evapTemp, 0, 55, '°F', (v) { setState(() => _evapTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Cond Temp', _condTemp, 80, 130, '°F', (v) { setState(() => _condTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TXV SELECTION'),
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
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TXV meters refrigerant to maintain superheat. Size 100-120% of capacity. Need adequate subcooling.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134a'), ('r404a', 'R-404A')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerant == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerant = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTxvTypeSelector(ZaftoColors colors) {
    final types = [('external_eq', 'External EQ'), ('internal_eq', 'Internal EQ'), ('electronic', 'Electronic')];
    return Row(
      children: types.map((t) {
        final selected = _txvType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _txvType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
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
    if (_txvTonnage == null) return const SizedBox.shrink();

    final subcoolingOk = _liquidSubcooling >= 5 && _liquidSubcooling <= 20;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_txvTonnage?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Ton TXV Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: subcoolingOk ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(subcoolingOk ? 'SUBCOOLING OK' : 'CHECK SUBCOOLING', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'System', '${(_systemCapacity / 12000).toStringAsFixed(1)} tons')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'ΔP', '${_pressureDrop?.toStringAsFixed(0)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Subcool', '${_liquidSubcooling.toStringAsFixed(0)}°F')),
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
