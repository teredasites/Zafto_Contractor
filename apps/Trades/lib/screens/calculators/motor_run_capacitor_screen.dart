import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Run Capacitor Calculator - Design System v2.6
/// Capacitor sizing and testing for HVAC motors
class MotorRunCapacitorScreen extends ConsumerStatefulWidget {
  const MotorRunCapacitorScreen({super.key});
  @override
  ConsumerState<MotorRunCapacitorScreen> createState() => _MotorRunCapacitorScreenState();
}

class _MotorRunCapacitorScreenState extends ConsumerState<MotorRunCapacitorScreen> {
  double _ratedMfd = 45;
  double _measuredMfd = 40;
  double _voltageRating = 370;
  double _systemVoltage = 240;
  String _capacitorType = 'run';
  String _application = 'compressor';

  double? _deviation;
  bool? _withinSpec;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate deviation from rated
    final deviation = ((_measuredMfd - _ratedMfd) / _ratedMfd) * 100;

    // Tolerance: Run caps typically ±6%, start caps ±20%
    final tolerance = _capacitorType == 'run' ? 6.0 : 20.0;
    final withinSpec = deviation.abs() <= tolerance;

    String status;
    if (deviation.abs() <= tolerance) {
      status = 'GOOD';
    } else if (deviation < -tolerance) {
      status = 'WEAK - Replace';
    } else {
      status = 'OVER - Check Wiring';
    }

    String recommendation;
    if (!withinSpec && deviation < 0) {
      recommendation = 'Capacitor has lost ${deviation.abs().toStringAsFixed(0)}% of capacity. Weak capacitor causes hard starting, overheating, and motor damage.';
    } else if (!withinSpec && deviation > 0) {
      recommendation = 'Reading higher than rated. Check meter calibration or wiring. Wrong capacitor installed?';
    } else {
      recommendation = 'Capacitor within specification (±${tolerance.toStringAsFixed(0)}% tolerance).';
    }

    // Voltage rating check
    if (_voltageRating < _systemVoltage * 1.1) {
      recommendation += ' WARNING: Voltage rating too low. Use ${(_systemVoltage * 1.5).toStringAsFixed(0)}V or higher rated cap.';
    }

    if (_capacitorType == 'run') {
      recommendation += ' Run cap: Stays in circuit continuously. Oil-filled, rated for 370V or 440V typical.';
    } else {
      recommendation += ' Start cap: In circuit only during startup. Electrolytic, 110-330V typical. Should drop out quickly.';
    }

    if (_application == 'compressor') {
      recommendation += ' Compressor: Match OEM specs. Incorrect MFD causes amp draw issues.';
    } else if (_application == 'condenser_fan') {
      recommendation += ' Condenser fan: Common failure point. Replace with exact or higher voltage rating.';
    } else {
      recommendation += ' Blower motor: PSC motors very sensitive to capacitor. Match exactly.';
    }

    setState(() {
      _deviation = deviation;
      _withinSpec = withinSpec;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _ratedMfd = 45;
      _measuredMfd = 40;
      _voltageRating = 370;
      _systemVoltage = 240;
      _capacitorType = 'run';
      _application = 'compressor';
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
        title: Text('Run Capacitor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CAPACITOR TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RATINGS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Rated MFD', _ratedMfd, 5, 100, ' µF', (v) { setState(() => _ratedMfd = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Measured', _measuredMfd, 0, 100, ' µF', (v) { setState(() => _measuredMfd = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Cap Voltage', _voltageRating, 110, 480, ' V', (v) { setState(() => _voltageRating = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'System V', _systemVoltage, 110, 480, ' V', (v) { setState(() => _systemVoltage = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TEST RESULTS'),
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
        Icon(LucideIcons.battery, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Run capacitors: ±6% tolerance. Start capacitors: ±20%. Discharge before testing. Use capacitor meter.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = [('run', 'Run Capacitor'), ('start', 'Start Capacitor')];
    return Row(
      children: types.map((t) {
        final selected = _capacitorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _capacitorType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
    final apps = [('compressor', 'Compressor'), ('condenser_fan', 'Cond. Fan'), ('blower', 'Blower')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 6 : 0),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_deviation == null) return const SizedBox.shrink();

    final isGood = _withinSpec ?? false;
    final isWeak = (_deviation ?? 0) < -6;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_deviation?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Deviation from Rated', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isGood ? Colors.green : (isWeak ? Colors.red : Colors.orange), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Rated', '${_ratedMfd.toStringAsFixed(0)} µF')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Measured', '${_measuredMfd.toStringAsFixed(0)} µF')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Tolerance', _capacitorType == 'run' ? '±6%' : '±20%')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isWeak ? Colors.red.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? Colors.green : (isWeak ? Colors.red : Colors.orange), size: 16),
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
