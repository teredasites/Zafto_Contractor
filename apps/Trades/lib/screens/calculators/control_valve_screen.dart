import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Control Valve Sizing Calculator - Design System v2.6
/// Cv calculation and valve authority analysis
class ControlValveScreen extends ConsumerStatefulWidget {
  const ControlValveScreen({super.key});
  @override
  ConsumerState<ControlValveScreen> createState() => _ControlValveScreenState();
}

class _ControlValveScreenState extends ConsumerState<ControlValveScreen> {
  double _flowRate = 50; // GPM
  double _valveDp = 5; // psi
  double _systemDp = 20; // psi (total system drop)
  double _specificGravity = 1.0;
  String _valveType = 'globe';
  String _characteristic = 'equal_pct';

  double? _cvRequired;
  double? _authority;
  double? _recommendedCv;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Cv formula: Cv = GPM × sqrt(SG / ΔP)
    final cvRequired = _flowRate * math.sqrt(_specificGravity / _valveDp);

    // Valve authority = Valve ΔP / System ΔP
    final authority = _valveDp / _systemDp;

    // Recommended Cv (select next standard size up)
    final standardCvs = <double>[0.5, 1, 2, 3, 5, 8, 12, 20, 30, 50, 80, 120, 200, 300, 500];
    double recommendedCv = standardCvs.last;
    for (final cv in standardCvs) {
      if (cv >= cvRequired) {
        recommendedCv = cv;
        break;
      }
    }

    String recommendation;
    recommendation = 'Required Cv: ${cvRequired.toStringAsFixed(1)}. Select Cv ${recommendedCv.toStringAsFixed(0)} valve. ';

    // Authority check
    if (authority >= 0.5) {
      recommendation += 'Good authority (${(authority * 100).toStringAsFixed(0)}%). Valve will control well.';
    } else if (authority >= 0.25) {
      recommendation += 'Marginal authority (${(authority * 100).toStringAsFixed(0)}%). Control may be inconsistent at low flow.';
    } else {
      recommendation += 'POOR authority (${(authority * 100).toStringAsFixed(0)}%). Valve undersized relative to system. Increase valve ΔP or reduce piping losses.';
    }

    switch (_valveType) {
      case 'globe':
        recommendation += ' Globe valve: Best for modulating. Linear or equal %. Industry standard.';
        break;
      case 'ball':
        recommendation += ' Ball valve: Good for on/off or quick-acting. Characterized balls available for modulating.';
        break;
      case 'butterfly':
        recommendation += ' Butterfly: Large flows, lower cost. Less precise control.';
        break;
    }

    switch (_characteristic) {
      case 'equal_pct':
        recommendation += ' Equal %: Best for coils and heat exchangers. Linearizes system response.';
        break;
      case 'linear':
        recommendation += ' Linear: Use when coil has linear characteristic or for bypass.';
        break;
      case 'quick_open':
        recommendation += ' Quick-opening: For on/off applications. Not for modulating.';
        break;
    }

    // Oversizing warning
    if (recommendedCv > cvRequired * 2) {
      recommendation += ' WARNING: Large size margin. Control may be difficult at low loads.';
    }

    recommendation += ' Size for 3-5 psi drop across valve at design flow.';

    setState(() {
      _cvRequired = cvRequired;
      _authority = authority;
      _recommendedCv = recommendedCv;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _flowRate = 50;
      _valveDp = 5;
      _systemDp = 20;
      _specificGravity = 1.0;
      _valveType = 'globe';
      _characteristic = 'equal_pct';
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
        title: Text('Control Valve', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VALVE TYPE'),
              const SizedBox(height: 12),
              _buildValveTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCharacteristicSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLOW & PRESSURE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Flow Rate', _flowRate, 1, 500, ' GPM', (v) { setState(() => _flowRate = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Sp. Gravity', _specificGravity, 0.8, 1.2, '', (v) { setState(() => _specificGravity = v); _calculate(); }, decimals: 2)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PRESSURE DROP'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Valve ΔP', _valveDp, 1, 20, ' psi', (v) { setState(() => _valveDp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'System ΔP', _systemDp, 5, 50, ' psi', (v) { setState(() => _systemDp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'VALVE SIZING'),
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
        Expanded(child: Text('Cv = GPM × √(SG/ΔP). Valve authority should be 0.3-0.5 minimum for good control. Equal % characteristic for coils.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildValveTypeSelector(ZaftoColors colors) {
    final types = [('globe', 'Globe'), ('ball', 'Ball'), ('butterfly', 'Butterfly')];
    return Row(
      children: types.map((t) {
        final selected = _valveType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _valveType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCharacteristicSelector(ZaftoColors colors) {
    final chars = [('equal_pct', 'Equal %'), ('linear', 'Linear'), ('quick_open', 'Quick Open')];
    return Row(
      children: chars.map((c) {
        final selected = _characteristic == c.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _characteristic = c.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: c != chars.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_cvRequired == null) return const SizedBox.shrink();

    final isGood = (_authority ?? 0) >= 0.3;
    final statusColor = isGood ? Colors.green : ((_authority ?? 0) >= 0.2 ? Colors.orange : Colors.red);
    final status = isGood ? 'GOOD AUTHORITY' : ((_authority ?? 0) >= 0.2 ? 'MARGINAL' : 'POOR AUTHORITY');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('Cv ${_recommendedCv?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Recommended Valve Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status (${((_authority ?? 0) * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Required Cv', '${_cvRequired?.toStringAsFixed(1)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Valve ΔP', '${_valveDp.toStringAsFixed(0)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'System ΔP', '${_systemDp.toStringAsFixed(0)} psi')),
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
