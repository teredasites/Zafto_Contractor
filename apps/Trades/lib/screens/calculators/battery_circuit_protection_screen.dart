import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Battery Circuit Protection Calculator - Design System v2.6
/// NEC 706 BESS overcurrent protection sizing
class BatteryCircuitProtectionScreen extends ConsumerStatefulWidget {
  const BatteryCircuitProtectionScreen({super.key});
  @override
  ConsumerState<BatteryCircuitProtectionScreen> createState() => _BatteryCircuitProtectionScreenState();
}

class _BatteryCircuitProtectionScreenState extends ConsumerState<BatteryCircuitProtectionScreen> {
  double _batteryKwh = 20;
  int _batteryVoltage = 48;
  double _maxDischargeRate = 1.0; // C-rate
  double _maxChargeRate = 0.5; // C-rate
  String _batteryType = 'lithium';

  double? _maxDischargeCurrent;
  double? _maxChargeCurrent;
  int? _ocpdRating;
  String? _wireSize;
  String? _disconnectRating;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate battery Ah
    final batteryAh = (_batteryKwh * 1000) / _batteryVoltage;

    // Max currents based on C-rate
    final maxDischarge = batteryAh * _maxDischargeRate;
    final maxCharge = batteryAh * _maxChargeRate;

    // Higher of charge/discharge for OCPD sizing
    final maxCurrent = maxDischarge > maxCharge ? maxDischarge : maxCharge;

    // NEC 706.21 - OCPD rating (125% of max current)
    final ocpdCurrent = maxCurrent * 1.25;

    // Round up to standard breaker sizes
    int ocpdRating;
    if (ocpdCurrent <= 15) {
      ocpdRating = 15;
    } else if (ocpdCurrent <= 20) {
      ocpdRating = 20;
    } else if (ocpdCurrent <= 30) {
      ocpdRating = 30;
    } else if (ocpdCurrent <= 40) {
      ocpdRating = 40;
    } else if (ocpdCurrent <= 50) {
      ocpdRating = 50;
    } else if (ocpdCurrent <= 60) {
      ocpdRating = 60;
    } else if (ocpdCurrent <= 70) {
      ocpdRating = 70;
    } else if (ocpdCurrent <= 80) {
      ocpdRating = 80;
    } else if (ocpdCurrent <= 100) {
      ocpdRating = 100;
    } else if (ocpdCurrent <= 125) {
      ocpdRating = 125;
    } else if (ocpdCurrent <= 150) {
      ocpdRating = 150;
    } else if (ocpdCurrent <= 175) {
      ocpdRating = 175;
    } else if (ocpdCurrent <= 200) {
      ocpdRating = 200;
    } else if (ocpdCurrent <= 225) {
      ocpdRating = 225;
    } else if (ocpdCurrent <= 250) {
      ocpdRating = 250;
    } else if (ocpdCurrent <= 300) {
      ocpdRating = 300;
    } else if (ocpdCurrent <= 400) {
      ocpdRating = 400;
    } else {
      ocpdRating = ((ocpdCurrent / 100).ceil() * 100).toInt();
    }

    // Wire sizing based on OCPD (simplified - 75°C copper)
    String wireSize;
    if (ocpdRating <= 15) {
      wireSize = '14 AWG';
    } else if (ocpdRating <= 20) {
      wireSize = '12 AWG';
    } else if (ocpdRating <= 30) {
      wireSize = '10 AWG';
    } else if (ocpdRating <= 40) {
      wireSize = '8 AWG';
    } else if (ocpdRating <= 55) {
      wireSize = '6 AWG';
    } else if (ocpdRating <= 70) {
      wireSize = '4 AWG';
    } else if (ocpdRating <= 85) {
      wireSize = '3 AWG';
    } else if (ocpdRating <= 100) {
      wireSize = '2 AWG';
    } else if (ocpdRating <= 115) {
      wireSize = '1 AWG';
    } else if (ocpdRating <= 130) {
      wireSize = '1/0 AWG';
    } else if (ocpdRating <= 150) {
      wireSize = '2/0 AWG';
    } else if (ocpdRating <= 175) {
      wireSize = '3/0 AWG';
    } else if (ocpdRating <= 200) {
      wireSize = '4/0 AWG';
    } else if (ocpdRating <= 230) {
      wireSize = '250 kcmil';
    } else if (ocpdRating <= 255) {
      wireSize = '300 kcmil';
    } else if (ocpdRating <= 285) {
      wireSize = '350 kcmil';
    } else if (ocpdRating <= 310) {
      wireSize = '400 kcmil';
    } else {
      wireSize = '500+ kcmil';
    }

    // Disconnect rating (NEC 706.7)
    final disconnectRating = '${((maxCurrent * 1.25 / 50).ceil() * 50).toInt()}A';

    String recommendation;
    if (_batteryType == 'lithium') {
      recommendation = 'Lithium requires DC-rated OCPD with sufficient AIC rating. Use Class T or RK1 fuses for high fault current.';
    } else {
      recommendation = 'Lead-acid may require different settings for equalization charging. Verify with manufacturer.';
    }

    if (_batteryVoltage > 60) {
      recommendation += ' Voltage exceeds 60V - full NEC 706 compliance required.';
    }

    setState(() {
      _maxDischargeCurrent = maxDischarge;
      _maxChargeCurrent = maxCharge;
      _ocpdRating = ocpdRating;
      _wireSize = wireSize;
      _disconnectRating = disconnectRating;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _batteryKwh = 20;
      _batteryVoltage = 48;
      _maxDischargeRate = 1.0;
      _maxChargeRate = 0.5;
      _batteryType = 'lithium';
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
        title: Text('Battery Protection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BATTERY SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Battery Capacity', value: _batteryKwh, min: 5, max: 100, unit: ' kWh', onChanged: (v) { setState(() => _batteryKwh = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Battery Voltage', options: const ['24V', '48V', '400V', '800V'], selectedIndex: [24, 48, 400, 800].indexOf(_batteryVoltage), onChanged: (i) { setState(() => _batteryVoltage = [24, 48, 400, 800][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Battery Type', options: const ['Lithium', 'Lead-Acid'], selectedIndex: _batteryType == 'lithium' ? 0 : 1, onChanged: (i) { setState(() => _batteryType = i == 0 ? 'lithium' : 'leadacid'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'C-RATE LIMITS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Discharge Rate', value: _maxDischargeRate, min: 0.5, max: 3, unit: 'C', decimals: 1, onChanged: (v) { setState(() => _maxDischargeRate = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Charge Rate', value: _maxChargeRate, min: 0.2, max: 2, unit: 'C', decimals: 1, onChanged: (v) { setState(() => _maxChargeRate = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PROTECTION SIZING'),
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
        Icon(LucideIcons.shield, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size OCPD per NEC 706. OCPD rated 125% of max current. Use DC-rated devices for battery circuits.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${decimals > 0 ? value.toStringAsFixed(decimals) : value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_ocpdRating == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$_ocpdRating A', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('OCPD Rating', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Max Discharge', '${_maxDischargeCurrent?.toStringAsFixed(0)}A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max Charge', '${_maxChargeCurrent?.toStringAsFixed(0)}A')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Wire Size', _wireSize ?? '')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Disconnect', _disconnectRating ?? '')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
