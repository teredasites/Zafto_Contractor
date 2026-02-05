import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Standalone ESS Calculator - Design System v2.6
/// Battery backup sizing without solar (kWh for backup)
class StandaloneEssScreen extends ConsumerStatefulWidget {
  const StandaloneEssScreen({super.key});
  @override
  ConsumerState<StandaloneEssScreen> createState() => _StandaloneEssScreenState();
}

class _StandaloneEssScreenState extends ConsumerState<StandaloneEssScreen> {
  double _criticalLoadKw = 5;
  double _backupHours = 8;
  double _depthOfDischarge = 80;
  double _systemEfficiency = 90;
  String _batteryType = 'lithium';

  double? _usableKwh;
  double? _totalKwh;
  double? _peakPowerKw;
  String? _batteryCount;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Energy needed
    final energyNeeded = _criticalLoadKw * _backupHours;

    // Account for efficiency and DoD
    final dodFactor = _depthOfDischarge / 100;
    final efficiencyFactor = _systemEfficiency / 100;
    final totalKwh = energyNeeded / (dodFactor * efficiencyFactor);

    // Usable capacity
    final usableKwh = totalKwh * dodFactor;

    // Peak power (assume 1.5x continuous for surge)
    final peakPower = _criticalLoadKw * 1.5;

    // Estimate battery count (common 5kWh/10kWh modules)
    int batteryModules;
    String batteryCount;
    if (_batteryType == 'lithium') {
      batteryModules = (totalKwh / 10).ceil();
      batteryCount = '$batteryModules × 10kWh modules (or ${(totalKwh / 5).ceil()} × 5kWh)';
    } else {
      batteryModules = (totalKwh / 5).ceil();
      batteryCount = '$batteryModules × 5kWh lead-acid banks';
    }

    String recommendation;
    if (totalKwh < 10) {
      recommendation = 'Single residential battery unit sufficient (Powerwall, Enphase, etc.)';
    } else if (totalKwh < 30) {
      recommendation = 'Multiple stacked battery modules recommended.';
    } else {
      recommendation = 'Commercial ESS or multiple residential systems needed.';
    }

    setState(() {
      _usableKwh = usableKwh;
      _totalKwh = totalKwh;
      _peakPowerKw = peakPower;
      _batteryCount = batteryCount;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _criticalLoadKw = 5;
      _backupHours = 8;
      _depthOfDischarge = 80;
      _systemEfficiency = 90;
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
        title: Text('Standalone ESS', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD & BACKUP TIME'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Critical Load', value: _criticalLoadKw, min: 1, max: 25, unit: ' kW', decimals: 1, onChanged: (v) { setState(() => _criticalLoadKw = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Backup Duration', value: _backupHours, min: 2, max: 48, unit: ' hours', onChanged: (v) { setState(() => _backupHours = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BATTERY PARAMETERS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Battery Type', options: const ['Lithium', 'Lead-Acid'], selectedIndex: _batteryType == 'lithium' ? 0 : 1, onChanged: (i) { setState(() => _batteryType = i == 0 ? 'lithium' : 'leadacid'); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Depth of Discharge', value: _depthOfDischarge, min: 50, max: 100, unit: '%', onChanged: (v) { setState(() => _depthOfDischarge = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Efficiency', value: _systemEfficiency, min: 80, max: 98, unit: '%', onChanged: (v) { setState(() => _systemEfficiency = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BATTERY SIZING'),
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
        Icon(LucideIcons.batteryFull, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size battery backup without solar. Lithium: 80-100% DoD. Lead-acid: 50% DoD max.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600))),
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
    if (_totalKwh == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_totalKwh!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('kWh Total Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Usable', '${_usableKwh?.toStringAsFixed(1)} kWh')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Peak Power', '${_peakPowerKw?.toStringAsFixed(1)} kW')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(_batteryCount ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
