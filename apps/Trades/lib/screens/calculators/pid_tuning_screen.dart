import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// PID Tuning Calculator - Design System v2.6
/// BAS control loop tuning parameters
class PidTuningScreen extends ConsumerStatefulWidget {
  const PidTuningScreen({super.key});
  @override
  ConsumerState<PidTuningScreen> createState() => _PidTuningScreenState();
}

class _PidTuningScreenState extends ConsumerState<PidTuningScreen> {
  double _processGain = 1.0; // Kp - process gain
  double _deadTime = 30; // seconds
  double _timeConstant = 120; // seconds
  String _tuningMethod = 'ziegler';
  String _loopType = 'temperature';

  double? _kc; // Controller gain
  double? _ti; // Integral time
  double? _td; // Derivative time
  double? _responseRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Various tuning methods
    double kc, ti, td;
    final tau = _timeConstant;
    final theta = _deadTime;
    final kp = _processGain;

    switch (_tuningMethod) {
      case 'ziegler':
        // Ziegler-Nichols (aggressive)
        kc = 1.2 * tau / (kp * theta);
        ti = 2 * theta;
        td = 0.5 * theta;
        break;
      case 'cohen':
        // Cohen-Coon (less aggressive)
        kc = (1.35 / kp) * (tau / theta + 0.185);
        ti = 2.5 * theta * (tau + 0.185 * theta) / (tau + 0.611 * theta);
        td = 0.37 * theta * tau / (tau + 0.185 * theta);
        break;
      case 'imc':
        // Internal Model Control (conservative)
        final lambda = math.max(0.25 * tau, 1.5 * theta); // Closed-loop time constant
        kc = tau / (kp * (lambda + theta));
        ti = tau;
        td = 0;
        break;
      case 'lambda':
        // Lambda tuning (very conservative)
        final lambdaFactor = 3 * theta; // Conservative
        kc = tau / (kp * lambdaFactor);
        ti = tau;
        td = 0;
        break;
      default:
        kc = 1.0;
        ti = 60;
        td = 0;
    }

    // Response ratio (controllability)
    final responseRatio = theta / tau;

    String recommendation;
    recommendation = 'Dead time: ${theta.toStringAsFixed(0)}s, Time constant: ${tau.toStringAsFixed(0)}s. ';

    if (responseRatio > 1) {
      recommendation += 'WARNING: Dead time dominant (θ/τ > 1). Difficult to control. Use conservative tuning.';
    } else if (responseRatio > 0.5) {
      recommendation += 'Moderate dead time. Use moderate tuning. Consider feedforward.';
    } else {
      recommendation += 'Low dead time ratio (${responseRatio.toStringAsFixed(2)}). Good controllability.';
    }

    switch (_tuningMethod) {
      case 'ziegler':
        recommendation += ' Ziegler-Nichols: Aggressive, may overshoot. Good starting point.';
        break;
      case 'cohen':
        recommendation += ' Cohen-Coon: Balanced response. Less overshoot than Z-N.';
        break;
      case 'imc':
        recommendation += ' IMC: Conservative, no overshoot. Best for processes where overshoot is harmful.';
        break;
      case 'lambda':
        recommendation += ' Lambda: Very conservative. Specify desired closed-loop time constant.';
        break;
    }

    switch (_loopType) {
      case 'temperature':
        recommendation += ' Temperature: Slow process. Start conservative, P+I typically sufficient.';
        break;
      case 'pressure':
        recommendation += ' Pressure: Fast response. May need derivative. Watch for noise.';
        break;
      case 'flow':
        recommendation += ' Flow: Fast, noisy. Usually P+I only. Filter input signal.';
        break;
      case 'level':
        recommendation += ' Level: Often P-only for surge tanks. Tight control needs P+I.';
        break;
    }

    if (td > 0) {
      recommendation += ' Derivative (Td=${td.toStringAsFixed(0)}s): Helps with lag. Filter derivative to reduce noise.';
    }

    setState(() {
      _kc = kc;
      _ti = ti;
      _td = td;
      _responseRatio = responseRatio;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _processGain = 1.0;
      _deadTime = 30;
      _timeConstant = 120;
      _tuningMethod = 'ziegler';
      _loopType = 'temperature';
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
        title: Text('PID Tuning', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TUNING METHOD'),
              const SizedBox(height: 12),
              _buildMethodSelector(colors),
              const SizedBox(height: 12),
              _buildLoopTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PROCESS MODEL'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Gain (Kp)', _processGain, 0.1, 5.0, '', (v) { setState(() => _processGain = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Dead Time', _deadTime, 5, 180, ' s', (v) { setState(() => _deadTime = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TIME CONSTANT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Time Constant (τ)', value: _timeConstant, min: 30, max: 600, unit: ' s', onChanged: (v) { setState(() => _timeConstant = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PID PARAMETERS'),
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
        Icon(LucideIcons.settings2, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('PID: Kc=gain, Ti=integral time, Td=derivative time. Start conservative, increase gain until slight oscillation.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = [('ziegler', 'Ziegler-Nichols'), ('cohen', 'Cohen-Coon'), ('imc', 'IMC'), ('lambda', 'Lambda')];
    return Row(
      children: methods.map((m) {
        final selected = _tuningMethod == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _tuningMethod = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != methods.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoopTypeSelector(ZaftoColors colors) {
    final types = [('temperature', 'Temp'), ('pressure', 'Pressure'), ('flow', 'Flow'), ('level', 'Level')];
    return Row(
      children: types.map((t) {
        final selected = _loopType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _loopType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
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
    if (_kc == null) return const SizedBox.shrink();

    final controllable = (_responseRatio ?? 1) < 1;
    final statusColor = controllable ? Colors.green : Colors.orange;
    final status = controllable ? 'CONTROLLABLE' : 'DIFFICULT CONTROL';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPidValue(colors, 'Kc', '${_kc?.toStringAsFixed(2)}'),
              _buildPidValue(colors, 'Ti', '${_ti?.toStringAsFixed(0)}s'),
              _buildPidValue(colors, 'Td', '${_td?.toStringAsFixed(0)}s'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status (θ/τ = ${_responseRatio?.toStringAsFixed(2)})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Dead Time', '${_deadTime.toStringAsFixed(0)} s')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Time Const', '${_timeConstant.toStringAsFixed(0)} s')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Process Gain', '${_processGain.toStringAsFixed(2)}')),
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

  Widget _buildPidValue(ZaftoColors colors, String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ),
      ],
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
