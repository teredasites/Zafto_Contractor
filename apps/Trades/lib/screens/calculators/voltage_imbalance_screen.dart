import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Voltage Imbalance Calculator - Design System v2.6
/// 3-phase voltage imbalance percentage per NEMA MG-1
class VoltageImbalanceScreen extends ConsumerStatefulWidget {
  const VoltageImbalanceScreen({super.key});
  @override
  ConsumerState<VoltageImbalanceScreen> createState() => _VoltageImbalanceScreenState();
}

class _VoltageImbalanceScreenState extends ConsumerState<VoltageImbalanceScreen> {
  double _vab = 480;
  double _vbc = 480;
  double _vca = 480;

  double? _average;
  double? _maxDeviation;
  double? _imbalancePercent;
  double? _motorDerating;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final avg = (_vab + _vbc + _vca) / 3;
    final devAb = (_vab - avg).abs();
    final devBc = (_vbc - avg).abs();
    final devCa = (_vca - avg).abs();
    final maxDev = [devAb, devBc, devCa].reduce((a, b) => a > b ? a : b);
    final imbalance = (maxDev / avg) * 100;

    // Motor derating per NEMA MG-1
    double derating;
    if (imbalance <= 1) {
      derating = 100;
    } else if (imbalance <= 2) {
      derating = 95;
    } else if (imbalance <= 3) {
      derating = 88;
    } else if (imbalance <= 4) {
      derating = 82;
    } else if (imbalance <= 5) {
      derating = 75;
    } else {
      derating = 65;
    }

    String status;
    String recommendation;
    if (imbalance <= 1) {
      status = 'EXCELLENT';
      recommendation = 'Voltage balance within ideal range.';
    } else if (imbalance <= 2) {
      status = 'ACCEPTABLE';
      recommendation = 'Minor imbalance. Monitor periodically.';
    } else if (imbalance <= 3) {
      status = 'MARGINAL';
      recommendation = 'Consider load balancing. Derate motors.';
    } else {
      status = 'EXCESSIVE';
      recommendation = 'Investigate cause immediately. Motors at risk.';
    }

    setState(() {
      _average = avg;
      _maxDeviation = maxDev;
      _imbalancePercent = imbalance;
      _motorDerating = derating;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _vab = 480;
      _vbc = 480;
      _vca = 480;
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
        title: Text('Voltage Imbalance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LINE-TO-LINE VOLTAGES'),
              const SizedBox(height: 12),
              _buildVoltageInput(colors, 'V(A-B)', _vab, (v) { setState(() => _vab = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildVoltageInput(colors, 'V(B-C)', _vbc, (v) { setState(() => _vbc = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildVoltageInput(colors, 'V(C-A)', _vca, (v) { setState(() => _vca = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ANALYSIS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildDeratingCard(colors),
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
        Expanded(child: Text('NEMA MG-1: Max 1% preferred, 2% acceptable. >2% requires motor derating.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildVoltageInput(ZaftoColors colors, String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
            child: Slider(value: value, min: 400, max: 520, onChanged: onChanged),
          ),
        ),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(1)}V', textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_imbalancePercent == null) return const SizedBox.shrink();
    final isGood = _imbalancePercent! <= 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? colors.accentPositive : colors.accentWarning, size: 24),
            const SizedBox(width: 8),
            Text(_status!, style: TextStyle(color: isGood ? colors.accentPositive : colors.accentWarning, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          Text('${_imbalancePercent!.toStringAsFixed(2)}%', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Voltage Imbalance', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Average', '${_average?.toStringAsFixed(1)}V')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max Deviation', '${_maxDeviation?.toStringAsFixed(1)}V')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDeratingCard(ZaftoColors colors) {
    if (_motorDerating == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Row(
        children: [
          Icon(LucideIcons.settings2, color: colors.accentPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motor Derating Factor', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('${_motorDerating!.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text('per NEMA MG-1', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
