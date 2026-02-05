import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Compressor Amp Draw Calculator - Design System v2.6
/// Diagnose compressor health via amperage analysis
class CompressorAmpDrawScreen extends ConsumerStatefulWidget {
  const CompressorAmpDrawScreen({super.key});
  @override
  ConsumerState<CompressorAmpDrawScreen> createState() => _CompressorAmpDrawScreenState();
}

class _CompressorAmpDrawScreenState extends ConsumerState<CompressorAmpDrawScreen> {
  double _ratedRla = 18;
  double _measuredAmps = 16;
  double _ratedLra = 95;
  double _supplyVoltage = 240;
  double _ratedVoltage = 230;
  String _compressorType = 'scroll';
  String _phase = 'single';

  double? _percentRla;
  double? _voltageDeviation;
  double? _expectedAmps;
  String? _healthStatus;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Voltage deviation affects amp draw
    final voltageDeviation = ((_supplyVoltage - _ratedVoltage) / _ratedVoltage) * 100;

    // Expected amps adjusted for voltage (amps increase with lower voltage)
    // Approximate: 3% amp change per 10% voltage change
    final voltageEffect = -voltageDeviation * 0.3;
    final expectedAmps = _ratedRla * (1 + voltageEffect / 100);

    // Percent of RLA
    final percentRla = (_measuredAmps / _ratedRla) * 100;

    // Health status
    String healthStatus;
    if (_measuredAmps > _ratedRla * 1.1) {
      healthStatus = 'HIGH - Overloaded';
    } else if (_measuredAmps > _ratedRla) {
      healthStatus = 'CAUTION - Near RLA';
    } else if (percentRla >= 70 && percentRla <= 100) {
      healthStatus = 'NORMAL';
    } else if (percentRla >= 50 && percentRla < 70) {
      healthStatus = 'LOW - Light Load';
    } else if (percentRla < 50) {
      healthStatus = 'VERY LOW - Check System';
    } else {
      healthStatus = 'NORMAL';
    }

    String recommendation;
    if (_measuredAmps > _ratedRla * 1.1) {
      recommendation = 'Amp draw exceeds RLA. Check: dirty condenser, high head pressure, refrigerant overcharge, restricted airflow.';
    } else if (_measuredAmps > _ratedRla) {
      recommendation = 'Operating near max capacity. Monitor temperatures. Check condenser and airflow.';
    } else if (percentRla < 50) {
      recommendation = 'Very low amp draw. Possible: low charge, liquid line restriction, faulty metering device, low load conditions.';
    } else {
      recommendation = 'Amp draw within normal range. Document for baseline comparison.';
    }

    if (voltageDeviation.abs() > 10) {
      recommendation += ' Voltage deviation ${voltageDeviation.toStringAsFixed(1)}% - check electrical supply.';
    }

    if (_compressorType == 'scroll') {
      recommendation += ' Scroll compressors may run higher amps at startup until temperature stabilizes.';
    } else if (_compressorType == 'reciprocating') {
      recommendation += ' Reciprocating compressors: check oil level and valve condition if amps are abnormal.';
    }

    setState(() {
      _percentRla = percentRla;
      _voltageDeviation = voltageDeviation;
      _expectedAmps = expectedAmps;
      _healthStatus = healthStatus;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _ratedRla = 18;
      _measuredAmps = 16;
      _ratedLra = 95;
      _supplyVoltage = 240;
      _ratedVoltage = 230;
      _compressorType = 'scroll';
      _phase = 'single';
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
        title: Text('Compressor Amps', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COMPRESSOR'),
              const SizedBox(height: 12),
              _buildCompressorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildPhaseSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'NAMEPLATE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Rated RLA', _ratedRla, 5, 50, ' A', (v) { setState(() => _ratedRla = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Rated LRA', _ratedLra, 20, 200, ' A', (v) { setState(() => _ratedLra = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Rated Voltage', value: _ratedVoltage, min: 200, max: 480, unit: ' V', onChanged: (v) { setState(() => _ratedVoltage = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MEASURED'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Amps', _measuredAmps, 1, 50, ' A', (v) { setState(() => _measuredAmps = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Voltage', _supplyVoltage, 180, 500, ' V', (v) { setState(() => _supplyVoltage = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DIAGNOSIS'),
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
        Icon(LucideIcons.zap, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Compare measured amps to nameplate RLA. Normal is 70-100% RLA under load. Check after 10+ min runtime.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCompressorTypeSelector(ZaftoColors colors) {
    final types = [('scroll', 'Scroll'), ('reciprocating', 'Recip'), ('rotary', 'Rotary')];
    return Row(
      children: types.map((t) {
        final selected = _compressorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _compressorType = t.$1); _calculate(); },
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

  Widget _buildPhaseSelector(ZaftoColors colors) {
    final phases = [('single', 'Single Phase'), ('three', '3-Phase')];
    return Row(
      children: phases.map((p) {
        final selected = _phase == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _phase = p.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: p != phases.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(p.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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
          child: Text('${value.toStringAsFixed(1)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
    if (_percentRla == null) return const SizedBox.shrink();

    final isNormal = _percentRla! >= 50 && _percentRla! <= 100;
    final isHigh = _measuredAmps > _ratedRla;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_percentRla?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('of Rated Load Amps', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isHigh ? Colors.red : (isNormal ? Colors.green : Colors.orange), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_healthStatus ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Measured', '${_measuredAmps.toStringAsFixed(1)} A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'RLA', '${_ratedRla.toStringAsFixed(1)} A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Voltage', '${_voltageDeviation?.toStringAsFixed(1)}%')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isHigh ? Colors.red.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isHigh ? LucideIcons.alertTriangle : LucideIcons.checkCircle, color: isHigh ? Colors.red : colors.textSecondary, size: 16),
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
