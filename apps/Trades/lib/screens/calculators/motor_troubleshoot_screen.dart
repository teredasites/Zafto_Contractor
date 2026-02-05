import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Troubleshooting Calculator - Design System v2.6
/// Motor amp draw analysis and diagnosis
class MotorTroubleshootScreen extends ConsumerStatefulWidget {
  const MotorTroubleshootScreen({super.key});
  @override
  ConsumerState<MotorTroubleshootScreen> createState() => _MotorTroubleshootScreenState();
}

class _MotorTroubleshootScreenState extends ConsumerState<MotorTroubleshootScreen> {
  double _nameplateFla = 10; // Full Load Amps
  double _measuredAmps = 9.5;
  double _voltageL1L2 = 230;
  double _voltageL2L3 = 235;
  double _voltageL3L1 = 228;
  String _motorType = 'three_phase';
  String _application = 'fan';

  double? _percentFla;
  double? _voltageImbalance;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Percent of FLA
    final percentFla = (_measuredAmps / _nameplateFla) * 100;

    // Voltage imbalance calculation (3-phase)
    double voltageImbalance = 0;
    if (_motorType == 'three_phase') {
      final avgVoltage = (_voltageL1L2 + _voltageL2L3 + _voltageL3L1) / 3;
      final maxDev = [
        (_voltageL1L2 - avgVoltage).abs(),
        (_voltageL2L3 - avgVoltage).abs(),
        (_voltageL3L1 - avgVoltage).abs(),
      ].reduce(math.max);
      voltageImbalance = (maxDev / avgVoltage) * 100;
    }

    // Status determination
    String status;
    if (percentFla > 115) {
      status = 'OVERLOADED';
    } else if (percentFla > 100) {
      status = 'HIGH LOAD';
    } else if (percentFla < 50) {
      status = 'LIGHT LOAD';
    } else {
      status = 'NORMAL';
    }

    // Additional voltage check
    if (voltageImbalance > 2) {
      status = 'VOLTAGE IMBALANCE';
    }

    String recommendation;
    recommendation = 'Running ${percentFla.toStringAsFixed(0)}% of nameplate FLA (${_nameplateFla.toStringAsFixed(1)}A). ';

    if (percentFla > 115) {
      recommendation += 'OVERLOAD: Motor exceeds service factor. Check for mechanical binding, belt tension, or undersized motor.';
    } else if (percentFla > 100) {
      recommendation += 'High load approaching FLA. Monitor temperature. Verify load is appropriate.';
    } else if (percentFla < 50) {
      recommendation += 'Light load: Motor may be oversized. Consider VFD for part-load efficiency.';
    } else {
      recommendation += 'Load is within normal range.';
    }

    if (_motorType == 'three_phase' && voltageImbalance > 2) {
      recommendation += ' VOLTAGE IMBALANCE: ${voltageImbalance.toStringAsFixed(1)}% exceeds 2% max. ';
      recommendation += 'Current imbalance will be 6-10× voltage imbalance. Check connections, transformer, utility.';
    } else if (_motorType == 'three_phase') {
      recommendation += ' Voltage imbalance ${voltageImbalance.toStringAsFixed(1)}% OK (<2%).';
    }

    switch (_application) {
      case 'fan':
        recommendation += ' Fan: Amps vary with speed cubed. High amps may indicate high static or belt slip.';
        break;
      case 'pump':
        recommendation += ' Pump: Check impeller clearance and strainer. Dead-heading causes overload.';
        break;
      case 'compressor':
        recommendation += ' Compressor: High amps may indicate high head pressure, low suction, or liquid flood-back.';
        break;
      case 'conveyor':
        recommendation += ' Conveyor: Check for binding, overloading, or bearing failure.';
        break;
    }

    recommendation += ' Service factor motors can run 115% of FLA briefly. Windings heat 7-10% per 1% voltage imbalance.';

    setState(() {
      _percentFla = percentFla;
      _voltageImbalance = voltageImbalance;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _nameplateFla = 10;
      _measuredAmps = 9.5;
      _voltageL1L2 = 230;
      _voltageL2L3 = 235;
      _voltageL3L1 = 228;
      _motorType = 'three_phase';
      _application = 'fan';
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
        title: Text('Motor Troubleshoot', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MOTOR TYPE'),
              const SizedBox(height: 12),
              _buildMotorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AMP READINGS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Nameplate FLA', _nameplateFla, 1, 100, ' A', (v) { setState(() => _nameplateFla = v); _calculate(); }, decimals: 1)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Measured', _measuredAmps, 0.5, 100, ' A', (v) { setState(() => _measuredAmps = v); _calculate(); }, decimals: 1)),
              ]),
              if (_motorType == 'three_phase') ...[
                const SizedBox(height: 24),
                _buildSectionHeader(colors, 'PHASE VOLTAGES'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildCompactSlider(colors, 'L1-L2', _voltageL1L2, 180, 260, ' V', (v) { setState(() => _voltageL1L2 = v); _calculate(); })),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCompactSlider(colors, 'L2-L3', _voltageL2L3, 180, 260, ' V', (v) { setState(() => _voltageL2L3 = v); _calculate(); })),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCompactSlider(colors, 'L3-L1', _voltageL3L1, 180, 260, ' V', (v) { setState(() => _voltageL3L1 = v); _calculate(); })),
                ]),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MOTOR STATUS'),
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
        Icon(LucideIcons.cog, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Normal operation 70-100% FLA. Voltage imbalance >2% causes 6-10× current imbalance. Check all phases.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMotorTypeSelector(ZaftoColors colors) {
    final types = [('three_phase', '3-Phase'), ('single_phase', '1-Phase')];
    return Row(
      children: types.map((t) {
        final selected = _motorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _motorType = t.$1); _calculate(); },
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

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('fan', 'Fan'), ('pump', 'Pump'), ('compressor', 'Compressor'), ('conveyor', 'Conveyor')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
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
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_percentFla == null) return const SizedBox.shrink();

    Color statusColor;
    switch (_status) {
      case 'NORMAL':
        statusColor = Colors.green;
        break;
      case 'OVERLOADED':
      case 'VOLTAGE IMBALANCE':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_percentFla?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('of Full Load Amps', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Measured', '${_measuredAmps.toStringAsFixed(1)} A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Nameplate', '${_nameplateFla.toStringAsFixed(1)} A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'V Imbalance', '${_voltageImbalance?.toStringAsFixed(1)}%')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
