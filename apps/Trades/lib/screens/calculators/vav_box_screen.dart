import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// VAV Box Sizing Calculator - Design System v2.6
/// Variable Air Volume terminal unit sizing
class VavBoxScreen extends ConsumerStatefulWidget {
  const VavBoxScreen({super.key});
  @override
  ConsumerState<VavBoxScreen> createState() => _VavBoxScreenState();
}

class _VavBoxScreenState extends ConsumerState<VavBoxScreen> {
  double _coolingCfm = 800;
  double _heatingCfm = 400;
  double _coolingLoad = 24000; // BTU/h
  double _heatingLoad = 15000;
  String _boxType = 'cooling_only';
  String _reheatType = 'none';
  double _inletVelocity = 1500;

  String? _inletSize;
  double? _minCfm;
  double? _maxCfm;
  double? _turndownRatio;
  double? _reheatCapacity;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Inlet size based on velocity
    // Area = CFM / Velocity (fpm)
    final area = _coolingCfm / _inletVelocity; // sq ft
    final diameterInches = math.sqrt(area * 4 / math.pi) * 12;

    // Standard inlet sizes
    final sizes = [6.0, 8.0, 10.0, 12.0, 14.0, 16.0];
    String inletSize = '16"';
    for (final size in sizes) {
      if (size >= diameterInches) {
        inletSize = '${size.toStringAsFixed(0)}"';
        break;
      }
    }

    // Min/max CFM
    double minCfm;
    double maxCfm = _coolingCfm;

    if (_boxType == 'cooling_only') {
      minCfm = _coolingCfm * 0.3; // 30% minimum typical
    } else {
      minCfm = _heatingCfm > 0 ? _heatingCfm : _coolingCfm * 0.3;
    }

    final turndownRatio = maxCfm / minCfm;

    // Reheat capacity
    double reheatCapacity = 0;
    if (_reheatType == 'hot_water') {
      // Sensible: Q = 1.08 × CFM × ΔT
      // Assume 20°F rise at minimum flow
      reheatCapacity = 1.08 * minCfm * 20;
    } else if (_reheatType == 'electric') {
      reheatCapacity = _heatingLoad.toDouble();
    }

    String recommendation;
    if (turndownRatio > 4) {
      recommendation = 'High turndown (${turndownRatio.toStringAsFixed(1)}:1) - verify box can modulate to minimum without hunting.';
    } else {
      recommendation = 'Turndown ratio ${turndownRatio.toStringAsFixed(1)}:1 is reasonable for most applications.';
    }

    if (_boxType == 'cooling_only') {
      recommendation += ' Cooling-only: No reheat - zone must drift toward setpoint at minimum flow.';
    } else if (_reheatType == 'hot_water') {
      recommendation += ' Hot water reheat: Size coil for ${(reheatCapacity / 1000).toStringAsFixed(1)}k BTU. Provide 2-way control valve.';
    } else if (_reheatType == 'electric') {
      recommendation += ' Electric reheat: ${(reheatCapacity / 3412).toStringAsFixed(1)} kW heater. Check electrical capacity.';
    }

    if (_inletVelocity > 2000) {
      recommendation += ' High inlet velocity may cause noise - consider larger inlet.';
    }

    if (minCfm < _coolingCfm * 0.2) {
      recommendation += ' Very low minimum may cause poor air distribution.';
    }

    setState(() {
      _inletSize = inletSize;
      _minCfm = minCfm;
      _maxCfm = maxCfm;
      _turndownRatio = turndownRatio;
      _reheatCapacity = reheatCapacity;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingCfm = 800;
      _heatingCfm = 400;
      _coolingLoad = 24000;
      _heatingLoad = 15000;
      _boxType = 'cooling_only';
      _reheatType = 'none';
      _inletVelocity = 1500;
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
        title: Text('VAV Box Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Cooling CFM', value: _coolingCfm, min: 100, max: 3000, unit: ' CFM', onChanged: (v) { setState(() => _coolingCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heating CFM (min)', value: _heatingCfm, min: 50, max: 1500, unit: ' CFM', onChanged: (v) { setState(() => _heatingCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Inlet Velocity', value: _inletVelocity, min: 800, max: 2500, unit: ' fpm', onChanged: (v) { setState(() => _inletVelocity = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BOX TYPE'),
              const SizedBox(height: 12),
              _buildBoxTypeSelector(colors),
              if (_boxType != 'cooling_only') ...[
                const SizedBox(height: 12),
                _buildReheatTypeSelector(colors),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BOX SELECTION'),
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
        Icon(LucideIcons.box, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('VAV sizing: Inlet velocity 1200-2000 fpm. Turndown 3:1 to 5:1 typical. Size reheat for heating at min flow.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBoxTypeSelector(ZaftoColors colors) {
    final types = [
      ('cooling_only', 'Cooling Only'),
      ('reheat', 'With Reheat'),
      ('fan_powered', 'Fan Powered'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _boxType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() { _boxType = t.$1; if (t.$1 == 'cooling_only') _reheatType = 'none'; }); _calculate(); },
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

  Widget _buildReheatTypeSelector(ZaftoColors colors) {
    final types = [('hot_water', 'Hot Water'), ('electric', 'Electric')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reheat Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _reheatType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _reheatType = t.$1); _calculate(); },
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
    if (_inletSize == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_inletSize!, style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Inlet Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('Turndown ${_turndownRatio?.toStringAsFixed(1)}:1', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Min CFM', '${_minCfm?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max CFM', '${_maxCfm?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Reheat', _reheatCapacity! > 0 ? '${(_reheatCapacity! / 1000).toStringAsFixed(1)}k BTU' : 'None')),
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
