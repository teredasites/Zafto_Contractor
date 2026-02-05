import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Inverter/Charger Calculator - Design System v2.6
/// Hybrid inverter sizing for off-grid and backup systems
class InverterChargerScreen extends ConsumerStatefulWidget {
  const InverterChargerScreen({super.key});
  @override
  ConsumerState<InverterChargerScreen> createState() => _InverterChargerScreenState();
}

class _InverterChargerScreenState extends ConsumerState<InverterChargerScreen> {
  double _continuousLoadKw = 5;
  double _surgeLoadKw = 10;
  double _batteryKwh = 20;
  int _batteryVoltage = 48;
  String _outputType = 'split';

  double? _minContinuousKw;
  double? _minSurgeKw;
  int? _chargerAmps;
  String? _recommendedSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Minimum continuous with 25% margin
    final minContinuous = _continuousLoadKw * 1.25;

    // Surge rating needed
    final minSurge = _surgeLoadKw;

    // Charger sizing (C/10 to C/5 charge rate)
    final chargeRateLow = (_batteryKwh * 1000) / (_batteryVoltage * 10);
    final chargeRateHigh = (_batteryKwh * 1000) / (_batteryVoltage * 5);
    final chargerAmps = ((chargeRateLow + chargeRateHigh) / 2).round();

    // Round up to standard sizes
    double recommendedKw;
    if (minContinuous <= 3) {
      recommendedKw = 3;
    } else if (minContinuous <= 5) {
      recommendedKw = 5;
    } else if (minContinuous <= 8) {
      recommendedKw = 8;
    } else if (minContinuous <= 10) {
      recommendedKw = 10;
    } else if (minContinuous <= 12) {
      recommendedKw = 12;
    } else {
      recommendedKw = (minContinuous / 5).ceil() * 5;
    }

    String recommendation;
    if (_outputType == 'split') {
      recommendation = 'Split-phase 120/240V output. Ensure neutral-ground bond is correct for off-grid.';
    } else {
      recommendation = 'Single-phase 120V or 230V. Common for small systems or grid-tie.';
    }

    if (_surgeLoadKw > _continuousLoadKw * 3) {
      recommendation += ' High surge ratio - verify motor starting loads.';
    }

    setState(() {
      _minContinuousKw = minContinuous;
      _minSurgeKw = minSurge;
      _chargerAmps = chargerAmps;
      _recommendedSize = '${recommendedKw.toStringAsFixed(0)}kW / ${(recommendedKw * 2).toStringAsFixed(0)}kW surge';
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _continuousLoadKw = 5;
      _surgeLoadKw = 10;
      _batteryKwh = 20;
      _batteryVoltage = 48;
      _outputType = 'split';
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
        title: Text('Inverter/Charger', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Continuous Load', value: _continuousLoadKw, min: 1, max: 20, unit: ' kW', decimals: 1, onChanged: (v) { setState(() => _continuousLoadKw = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Surge/Starting Load', value: _surgeLoadKw, min: 2, max: 50, unit: ' kW', decimals: 1, onChanged: (v) { setState(() => _surgeLoadKw = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BATTERY SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Battery Capacity', value: _batteryKwh, min: 5, max: 100, unit: ' kWh', onChanged: (v) { setState(() => _batteryKwh = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Battery Voltage', options: const ['24V', '48V'], selectedIndex: _batteryVoltage == 24 ? 0 : 1, onChanged: (i) { setState(() => _batteryVoltage = i == 0 ? 24 : 48); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OUTPUT TYPE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'AC Output', options: const ['Split-Phase 120/240V', 'Single-Phase'], selectedIndex: _outputType == 'split' ? 0 : 1, onChanged: (i) { setState(() => _outputType = i == 0 ? 'split' : 'single'); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'INVERTER SIZING'),
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
        Icon(LucideIcons.refreshCw, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size for continuous + 25% margin. Surge rating typically 2× continuous. Charger sized for C/5 to C/10.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
    if (_recommendedSize == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedSize!, style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          Text('Recommended Inverter', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Min Continuous', '${_minContinuousKw?.toStringAsFixed(1)}kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Surge Needed', '${_minSurgeKw?.toStringAsFixed(1)}kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Charger', '${_chargerAmps}A')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
