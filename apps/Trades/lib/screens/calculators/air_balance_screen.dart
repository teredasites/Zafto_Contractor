import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Air Balance (TAB) Calculator - Design System v2.6
/// Testing, adjusting, balancing for HVAC systems
class AirBalanceScreen extends ConsumerStatefulWidget {
  const AirBalanceScreen({super.key});
  @override
  ConsumerState<AirBalanceScreen> createState() => _AirBalanceScreenState();
}

class _AirBalanceScreenState extends ConsumerState<AirBalanceScreen> {
  double _designCfm = 1000;
  double _measuredCfm = 850;
  double _supplyAirTemp = 55;
  double _returnAirTemp = 75;
  double _outsideAirCfm = 200;
  String _measurementMethod = 'pitot';
  int _diffuserCount = 4;

  double? _percentDesign;
  double? _cfmDeviation;
  double? _outsideAirPercent;
  double? _sensibleBtu;
  String? _balanceStatus;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Percent of design airflow
    final percentDesign = (_measuredCfm / _designCfm) * 100;
    final cfmDeviation = _measuredCfm - _designCfm;

    // Outside air percentage
    final outsideAirPercent = (_outsideAirCfm / _measuredCfm) * 100;

    // Sensible cooling capacity
    // Q = 1.08 × CFM × ΔT
    final deltaT = _returnAirTemp - _supplyAirTemp;
    final sensibleBtu = 1.08 * _measuredCfm * deltaT;

    // Balance status
    String balanceStatus;
    if (percentDesign >= 95 && percentDesign <= 105) {
      balanceStatus = 'Within Tolerance (±5%)';
    } else if (percentDesign >= 90 && percentDesign <= 110) {
      balanceStatus = 'Acceptable (±10%)';
    } else if (percentDesign < 90) {
      balanceStatus = 'Under-Performing';
    } else {
      balanceStatus = 'Over-Performing';
    }

    String recommendation;
    if (percentDesign < 90) {
      recommendation = 'Low airflow: Check for dirty filters, closed dampers, duct restrictions, or fan issues.';
    } else if (percentDesign > 110) {
      recommendation = 'High airflow: Check damper settings, may need to partially close to balance system.';
    } else {
      recommendation = 'Airflow within acceptable range. Document readings and damper positions.';
    }

    if (outsideAirPercent < 15) {
      recommendation += ' Low OA% - verify outdoor damper operation and minimum ventilation.';
    }

    if (_measurementMethod == 'pitot') {
      recommendation += ' Pitot traverse: Use log-Tchebycheff or equal area method for accuracy.';
    } else if (_measurementMethod == 'hood') {
      recommendation += ' Capture hood: Center over diffuser, ensure complete seal.';
    }

    // CFM per diffuser
    final cfmPerDiffuser = _measuredCfm / _diffuserCount;
    recommendation += ' CFM/diffuser: ${cfmPerDiffuser.toStringAsFixed(0)} - adjust neck dampers to balance.';

    setState(() {
      _percentDesign = percentDesign;
      _cfmDeviation = cfmDeviation;
      _outsideAirPercent = outsideAirPercent;
      _sensibleBtu = sensibleBtu;
      _balanceStatus = balanceStatus;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _designCfm = 1000;
      _measuredCfm = 850;
      _supplyAirTemp = 55;
      _returnAirTemp = 75;
      _outsideAirCfm = 200;
      _measurementMethod = 'pitot';
      _diffuserCount = 4;
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
        title: Text('Air Balance (TAB)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSliderRow(colors, label: 'Design CFM', value: _designCfm, min: 100, max: 5000, unit: ' CFM', onChanged: (v) { setState(() => _designCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Measured CFM', value: _measuredCfm, min: 50, max: 5000, unit: ' CFM', onChanged: (v) { setState(() => _measuredCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outside Air CFM', value: _outsideAirCfm, min: 0, max: 1000, unit: ' CFM', onChanged: (v) { setState(() => _outsideAirCfm = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply Air', _supplyAirTemp, 45, 65, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Return Air', _returnAirTemp, 65, 85, '°F', (v) { setState(() => _returnAirTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MEASUREMENT'),
              const SizedBox(height: 12),
              _buildMethodSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Diffuser Count', value: _diffuserCount.toDouble(), min: 1, max: 20, unit: '', onChanged: (v) { setState(() => _diffuserCount = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BALANCE RESULTS'),
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
        Expanded(child: Text('TAB: Compare measured to design CFM. Target ±5% of design. Balance diffusers for even distribution.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = [
      ('pitot', 'Pitot Traverse'),
      ('hood', 'Capture Hood'),
      ('vane', 'Rotating Vane'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Measurement Method', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: methods.map((m) {
            final selected = _measurementMethod == m.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _measurementMethod = m.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: m != methods.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
    if (_percentDesign == null) return const SizedBox.shrink();

    final isGood = _percentDesign! >= 90 && _percentDesign! <= 110;
    final isIdeal = _percentDesign! >= 95 && _percentDesign! <= 105;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_percentDesign?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('of Design Airflow', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: isIdeal ? Colors.green : (isGood ? Colors.orange : Colors.red), borderRadius: BorderRadius.circular(20)),
            child: Text(_balanceStatus ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Deviation', '${_cfmDeviation! >= 0 ? '+' : ''}${_cfmDeviation?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'OA %', '${_outsideAirPercent?.toStringAsFixed(1)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Sensible', '${(_sensibleBtu! / 1000).toStringAsFixed(1)}k BTU')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.clipboardCheck, color: colors.textSecondary, size: 16),
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
