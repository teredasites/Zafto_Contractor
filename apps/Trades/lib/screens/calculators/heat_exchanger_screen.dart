import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Heat Exchanger Calculator - Design System v2.6
/// LMTD and effectiveness calculations
class HeatExchangerScreen extends ConsumerStatefulWidget {
  const HeatExchangerScreen({super.key});
  @override
  ConsumerState<HeatExchangerScreen> createState() => _HeatExchangerScreenState();
}

class _HeatExchangerScreenState extends ConsumerState<HeatExchangerScreen> {
  double _hotInlet = 180;
  double _hotOutlet = 140;
  double _coldInlet = 60;
  double _coldOutlet = 100;
  String _flowArrangement = 'counter';
  double _hotFlowRate = 10; // GPM
  String _hotFluid = 'water';

  double? _lmtd;
  double? _heatTransferred;
  double? _effectiveness;
  double? _ntu;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Temperature differences
    final dt1 = _hotInlet - _coldOutlet;
    final dt2 = _hotOutlet - _coldInlet;

    // Log Mean Temperature Difference
    double lmtd;
    if ((dt1 - dt2).abs() < 0.1) {
      lmtd = dt1; // Avoid divide by zero
    } else {
      lmtd = (dt1 - dt2) / _ln(dt1 / dt2);
    }

    // Correction factor for flow arrangement
    double correctionFactor;
    switch (_flowArrangement) {
      case 'counter':
        correctionFactor = 1.0; // Counter flow is reference
        break;
      case 'parallel':
        correctionFactor = 0.85; // Parallel flow less efficient
        break;
      case 'crossflow':
        correctionFactor = 0.95;
        break;
      case 'shell_tube':
        correctionFactor = 0.90;
        break;
      default:
        correctionFactor = 1.0;
    }

    final correctedLmtd = lmtd * correctionFactor;

    // Heat transferred (BTU/h)
    // Q = m * Cp * DT for hot side
    double specificHeat = _hotFluid == 'water' ? 1.0 : 0.58; // Water vs oil
    double density = _hotFluid == 'water' ? 8.33 : 7.0;

    final massFlowRate = _hotFlowRate * density * 60; // lb/h
    final heatTransferred = massFlowRate * specificHeat * (_hotInlet - _hotOutlet);

    // Effectiveness
    final maxTempDiff = _hotInlet - _coldInlet;
    final actualHotDrop = _hotInlet - _hotOutlet;
    final actualColdRise = _coldOutlet - _coldInlet;
    final effectiveness = (actualHotDrop > actualColdRise ? actualHotDrop : actualColdRise) / maxTempDiff * 100;

    // NTU (Number of Transfer Units) - simplified
    final ntu = effectiveness / (100 - effectiveness + 0.01);

    String recommendation;
    if (effectiveness > 90) {
      recommendation = 'Very high effectiveness (${effectiveness.toStringAsFixed(0)}%). Heat exchanger well-sized or oversized.';
    } else if (effectiveness > 70) {
      recommendation = 'Good effectiveness. Standard operation.';
    } else if (effectiveness > 50) {
      recommendation = 'Moderate effectiveness. Check for fouling or undersizing.';
    } else {
      recommendation = 'Low effectiveness. Possible fouling, low flow rate, or undersized exchanger.';
    }

    if (_flowArrangement == 'parallel') {
      recommendation += ' Parallel flow limited to 50% max effectiveness. Consider counter-flow arrangement.';
    }

    if (_hotOutlet < _coldInlet + 10) {
      recommendation += ' Approach temperature very tight. Verify flows and consider larger exchanger.';
    }

    recommendation += ' LMTD method: Q = U × A × LMTD. Size area based on required duty.';

    setState(() {
      _lmtd = correctedLmtd;
      _heatTransferred = heatTransferred;
      _effectiveness = effectiveness;
      _ntu = ntu;
      _recommendation = recommendation;
    });
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    double result = 0;
    double term = (x - 1) / (x + 1);
    double power = term;
    for (int i = 1; i < 20; i += 2) {
      result += power / i;
      power *= term * term;
    }
    return 2 * result;
  }

  void _reset() {
    setState(() {
      _hotInlet = 180;
      _hotOutlet = 140;
      _coldInlet = 60;
      _coldOutlet = 100;
      _flowArrangement = 'counter';
      _hotFlowRate = 10;
      _hotFluid = 'water';
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
        title: Text('Heat Exchanger', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ARRANGEMENT'),
              const SizedBox(height: 12),
              _buildFlowArrangementSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HOT SIDE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Inlet', _hotInlet, 100, 250, '°F', (v) { setState(() => _hotInlet = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Outlet', _hotOutlet, 80, 200, '°F', (v) { setState(() => _hotOutlet = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Hot Flow Rate', value: _hotFlowRate, min: 1, max: 50, unit: ' GPM', onChanged: (v) { setState(() => _hotFlowRate = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COLD SIDE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Inlet', _coldInlet, 40, 120, '°F', (v) { setState(() => _coldInlet = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Outlet', _coldOutlet, 60, 160, '°F', (v) { setState(() => _coldOutlet = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PERFORMANCE'),
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
        Icon(LucideIcons.arrowLeftRight, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('LMTD method for heat exchanger sizing. Counter-flow most efficient. Effectiveness = actual/max possible heat transfer.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFlowArrangementSelector(ZaftoColors colors) {
    final arrangements = [
      ('counter', 'Counter'),
      ('parallel', 'Parallel'),
      ('crossflow', 'Cross'),
      ('shell_tube', 'Shell/Tube'),
    ];
    return Row(
      children: arrangements.map((a) {
        final selected = _flowArrangement == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _flowArrangement = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != arrangements.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
    if (_lmtd == null) return const SizedBox.shrink();

    final isEfficient = (_effectiveness ?? 0) > 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_effectiveness?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Effectiveness', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: isEfficient ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('LMTD: ${_lmtd?.toStringAsFixed(1)}°F', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Heat Rate', '${(_heatTransferred! / 1000).toStringAsFixed(1)}k BTU/h')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'NTU', '${_ntu?.toStringAsFixed(2)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Hot ΔT', '${(_hotInlet - _hotOutlet).toStringAsFixed(0)}°F')),
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
