import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Chiller COP Calculator - Design System v2.6
/// Chiller efficiency and performance analysis
class ChillerCopScreen extends ConsumerStatefulWidget {
  const ChillerCopScreen({super.key});
  @override
  ConsumerState<ChillerCopScreen> createState() => _ChillerCopScreenState();
}

class _ChillerCopScreenState extends ConsumerState<ChillerCopScreen> {
  double _tonnage = 200;
  double _kwInput = 180;
  double _chwSupply = 44;
  double _chwReturn = 54;
  double _flowRate = 480; // GPM
  String _chillerType = 'centrifugal';
  String _refrigerant = 'r134a';

  double? _cop;
  double? _kwPerTon;
  double? _actualTons;
  double? _efficiency;
  String? _status;
  String? _recommendation;

  // Reference kW/ton by chiller type (full load)
  final Map<String, double> _referenceKwTon = {
    'centrifugal': 0.55,
    'screw': 0.65,
    'scroll': 0.75,
    'reciprocating': 0.85,
    'absorption': 1.20,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate actual tons from flow and delta T
    // Tons = GPM × ΔT × 500 / 12000
    final deltaT = _chwReturn - _chwSupply;
    final actualTons = (_flowRate * deltaT * 500) / 12000;

    // kW/ton
    final kwPerTon = _kwInput / actualTons;

    // COP = Cooling output (kW) / Power input (kW)
    // 1 ton = 3.517 kW
    final coolingKw = actualTons * 3.517;
    final cop = coolingKw / _kwInput;

    // Compare to reference efficiency
    final refKwTon = _referenceKwTon[_chillerType] ?? 0.65;
    final efficiency = (refKwTon / kwPerTon) * 100;

    String status;
    if (kwPerTon <= refKwTon * 0.9) {
      status = 'EXCELLENT';
    } else if (kwPerTon <= refKwTon * 1.1) {
      status = 'GOOD';
    } else if (kwPerTon <= refKwTon * 1.3) {
      status = 'FAIR';
    } else {
      status = 'POOR';
    }

    String recommendation;
    recommendation = 'Operating at ${kwPerTon.toStringAsFixed(3)} kW/ton (COP ${cop.toStringAsFixed(2)}). ';

    if (kwPerTon > refKwTon * 1.2) {
      recommendation += 'Efficiency below expected. Check condenser water temp, tube fouling, and refrigerant charge.';
    } else if (kwPerTon > refKwTon) {
      recommendation += 'Efficiency slightly below reference. Monitor trends.';
    } else {
      recommendation += 'Excellent efficiency for ${_chillerType.replaceAll('_', ' ')} chiller.';
    }

    switch (_chillerType) {
      case 'centrifugal':
        recommendation += ' Centrifugal: Best efficiency at design load. Part-load with VFD or hot gas bypass.';
        break;
      case 'screw':
        recommendation += ' Screw: Good part-load efficiency. Slide valve or VFD capacity control.';
        break;
      case 'scroll':
        recommendation += ' Scroll: Simple, reliable. Stage loading for part-load.';
        break;
      case 'absorption':
        recommendation += ' Absorption: Uses heat input. COP typically 0.7-1.2. Check solution concentration.';
        break;
    }

    if (deltaT < 8) {
      recommendation += ' Low delta T: Check for bypass or excessive flow.';
    } else if (deltaT > 14) {
      recommendation += ' High delta T: Check flow rate. May indicate low flow condition.';
    }

    if (_chwSupply < 40) {
      recommendation += ' Very low supply temp increases energy use.';
    }

    setState(() {
      _cop = cop;
      _kwPerTon = kwPerTon;
      _actualTons = actualTons;
      _efficiency = efficiency.clamp(0, 150);
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _tonnage = 200;
      _kwInput = 180;
      _chwSupply = 44;
      _chwReturn = 54;
      _flowRate = 480;
      _chillerType = 'centrifugal';
      _refrigerant = 'r134a';
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
        title: Text('Chiller COP', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CHILLER TYPE'),
              const SizedBox(height: 12),
              _buildChillerTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'POWER INPUT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'kW Input', _kwInput, 50, 500, ' kW', (v) { setState(() => _kwInput = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Rated Tons', _tonnage, 50, 500, ' ton', (v) { setState(() => _tonnage = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CHILLED WATER'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply', _chwSupply, 38, 50, '°F', (v) { setState(() => _chwSupply = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Return', _chwReturn, 48, 60, '°F', (v) { setState(() => _chwReturn = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Flow', _flowRate, 100, 1500, ' GPM', (v) { setState(() => _flowRate = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CHILLER EFFICIENCY'),
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
        Expanded(child: Text('COP = Cooling Output / Power Input. Higher COP = better efficiency. Target <0.6 kW/ton for centrifugal.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildChillerTypeSelector(ZaftoColors colors) {
    final types = [('centrifugal', 'Centrifugal'), ('screw', 'Screw'), ('scroll', 'Scroll'), ('absorption', 'Absorption')];
    return Row(
      children: types.map((t) {
        final selected = _chillerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _chillerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
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
    if (_cop == null) return const SizedBox.shrink();

    final statusColor = _status == 'EXCELLENT' ? Colors.green
        : _status == 'GOOD' ? Colors.blue
        : _status == 'FAIR' ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${_cop?.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('COP', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
            Container(width: 1, height: 60, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${_kwPerTon?.toStringAsFixed(3)}', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('kW/ton', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_status ?? ''} - ${_efficiency?.toStringAsFixed(0)}% of Reference', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Actual Tons', '${_actualTons?.toStringAsFixed(1)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${(_chwReturn - _chwSupply).toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Ref kW/ton', '${_referenceKwTon[_chillerType]?.toStringAsFixed(2)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_status == 'EXCELLENT' || _status == 'GOOD' ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
