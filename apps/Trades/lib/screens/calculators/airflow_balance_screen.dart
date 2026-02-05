import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Airflow Balance Calculator - Design System v2.6
/// Test and balance airflow verification
class AirflowBalanceScreen extends ConsumerStatefulWidget {
  const AirflowBalanceScreen({super.key});
  @override
  ConsumerState<AirflowBalanceScreen> createState() => _AirflowBalanceScreenState();
}

class _AirflowBalanceScreenState extends ConsumerState<AirflowBalanceScreen> {
  double _designCfm = 1000;
  double _measuredCfm = 920;
  double _supplyTemp = 55;
  double _returnTemp = 75;
  String _measureMethod = 'pitot';
  String _toleranceStd = 'ashrae';

  double? _percentDesign;
  double? _deviation;
  double? _sensibleLoad;
  bool? _inTolerance;
  String? _recommendation;

  // Tolerance standards
  final Map<String, double> _tolerances = {
    'ashrae': 10,    // ASHRAE ±10%
    'smacna': 10,    // SMACNA ±10%
    'nebb': 10,      // NEBB ±10%
    'tight': 5,      // Tight tolerance ±5%
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Percent of design
    final percentDesign = (_measuredCfm / _designCfm) * 100;
    final deviation = percentDesign - 100;

    // Check tolerance
    final tolerance = _tolerances[_toleranceStd] ?? 10;
    final inTolerance = deviation.abs() <= tolerance;

    // Sensible cooling/heating capacity
    final deltaT = _returnTemp - _supplyTemp;
    final sensibleLoad = 1.08 * _measuredCfm * deltaT;

    String recommendation;
    recommendation = 'Measured: ${_measuredCfm.toStringAsFixed(0)} CFM (${percentDesign.toStringAsFixed(1)}% of design). ';

    if (inTolerance) {
      recommendation += 'PASS: Within ±${tolerance.toStringAsFixed(0)}% tolerance. ';
    } else {
      recommendation += 'FAIL: Outside ±${tolerance.toStringAsFixed(0)}% tolerance. Deviation: ${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%. ';
    }

    if (deviation < -10) {
      recommendation += 'Low airflow: Check for restrictions, dirty filters, closed dampers, or fan issues. ';
    } else if (deviation > 10) {
      recommendation += 'High airflow: Check for bypass, removed restrictions, or damper settings. ';
    }

    switch (_measureMethod) {
      case 'pitot':
        recommendation += 'Pitot traverse: Most accurate. Minimum 20 points for rectangular, 10 for round.';
        break;
      case 'hood':
        recommendation += 'Flow hood: Quick for diffusers. Calibrate regularly. May under-read at high velocity.';
        break;
      case 'velocity':
        recommendation += 'Velocity grid: Average multiple points. Duct should be straight 7.5 diameters upstream.';
        break;
      case 'pressure':
        recommendation += 'Fan curve method: Use fan curves with measured static. Verify fan speed matches.';
        break;
    }

    recommendation += ' Sensible capacity: ${(sensibleLoad / 12000).toStringAsFixed(2)} tons at ${deltaT.toStringAsFixed(0)}°F ΔT.';

    if (deltaT < 15) {
      recommendation += ' Low ΔT may indicate high airflow, low coil load, or control issues.';
    } else if (deltaT > 25) {
      recommendation += ' High ΔT may indicate low airflow or high coil loading.';
    }

    setState(() {
      _percentDesign = percentDesign;
      _deviation = deviation;
      _sensibleLoad = sensibleLoad;
      _inTolerance = inTolerance;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _designCfm = 1000;
      _measuredCfm = 920;
      _supplyTemp = 55;
      _returnTemp = 75;
      _measureMethod = 'pitot';
      _toleranceStd = 'ashrae';
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
        title: Text('Airflow Balance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MEASUREMENT METHOD'),
              const SizedBox(height: 12),
              _buildMethodSelector(colors),
              const SizedBox(height: 12),
              _buildToleranceSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Design', _designCfm, 100, 10000, ' CFM', (v) { setState(() => _designCfm = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Measured', _measuredCfm, 100, 10000, ' CFM', (v) { setState(() => _measuredCfm = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply', _supplyTemp, 45, 65, '°F', (v) { setState(() => _supplyTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Return', _returnTemp, 70, 85, '°F', (v) { setState(() => _returnTemp = v); _calculate(); })),
              ]),
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
        Icon(LucideIcons.scale, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TAB standard: ±10% of design. Verify with pitot traverse or calibrated flow hood. Document all readings.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = [('pitot', 'Pitot'), ('hood', 'Flow Hood'), ('velocity', 'Vel Grid'), ('pressure', 'Fan Curve')];
    return Row(
      children: methods.map((m) {
        final selected = _measureMethod == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _measureMethod = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != methods.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToleranceSelector(ZaftoColors colors) {
    final stds = [('ashrae', 'ASHRAE ±10%'), ('smacna', 'SMACNA'), ('tight', 'Tight ±5%')];
    return Row(
      children: stds.map((s) {
        final selected = _toleranceStd == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _toleranceStd = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != stds.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
    if (_percentDesign == null) return const SizedBox.shrink();

    final passed = _inTolerance ?? false;
    final statusColor = passed ? Colors.green : Colors.red;
    final status = passed ? 'PASS' : 'FAIL';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_percentDesign?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('of Design Airflow', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status (${_deviation! >= 0 ? '+' : ''}${_deviation?.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Design', '${_designCfm.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Measured', '${_measuredCfm.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Sensible', '${((_sensibleLoad ?? 0) / 1000).toStringAsFixed(1)} MBH')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(passed ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
