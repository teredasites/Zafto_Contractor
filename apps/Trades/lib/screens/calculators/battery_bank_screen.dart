import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Battery Bank Calculator - Design System v2.6
/// Series/parallel battery configuration for off-grid systems
class BatteryBankScreen extends ConsumerStatefulWidget {
  const BatteryBankScreen({super.key});
  @override
  ConsumerState<BatteryBankScreen> createState() => _BatteryBankScreenState();
}

class _BatteryBankScreenState extends ConsumerState<BatteryBankScreen> {
  int _systemVoltage = 48;
  double _requiredAh = 200;
  double _batteryVoltage = 12;
  double _batteryAh = 100;

  int? _seriesCount;
  int? _parallelCount;
  int? _totalBatteries;
  double? _totalKwh;
  String? _wiringDescription;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Series for voltage
    final seriesCount = (_systemVoltage / _batteryVoltage).ceil();

    // Parallel for capacity
    final parallelCount = (_requiredAh / _batteryAh).ceil();

    // Total batteries
    final totalBatteries = seriesCount * parallelCount;

    // Total kWh
    final totalKwh = (_systemVoltage * _requiredAh) / 1000;

    // Wiring description
    final wiringDesc = '$seriesCount in series × $parallelCount parallel strings';

    String recommendation;
    if (seriesCount > 4) {
      recommendation = 'Consider higher voltage batteries to reduce series connections.';
    } else if (parallelCount > 4) {
      recommendation = 'Consider higher Ah batteries to reduce parallel strings. Max 4 parallel recommended.';
    } else {
      recommendation = 'Configuration within recommended limits. Ensure equal cable lengths.';
    }

    setState(() {
      _seriesCount = seriesCount;
      _parallelCount = parallelCount;
      _totalBatteries = totalBatteries;
      _totalKwh = totalKwh;
      _wiringDescription = wiringDesc;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemVoltage = 48;
      _requiredAh = 200;
      _batteryVoltage = 12;
      _batteryAh = 100;
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
        title: Text('Battery Bank', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'System Voltage', options: const ['12V', '24V', '48V'], selectedIndex: [12, 24, 48].indexOf(_systemVoltage), onChanged: (i) { setState(() => _systemVoltage = [12, 24, 48][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Required Capacity', value: _requiredAh, min: 50, max: 1000, unit: ' Ah', onChanged: (v) { setState(() => _requiredAh = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BATTERY SPECIFICATIONS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Battery Voltage', options: const ['6V', '12V'], selectedIndex: _batteryVoltage == 6 ? 0 : 1, onChanged: (i) { setState(() => _batteryVoltage = i == 0 ? 6 : 12); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Battery Capacity', value: _batteryAh, min: 50, max: 300, unit: ' Ah', onChanged: (v) { setState(() => _batteryAh = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BANK CONFIGURATION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildDiagramCard(colors),
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
        Expanded(child: Text('Series increases voltage. Parallel increases capacity. Max 4 parallel strings recommended.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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
            child: Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_totalBatteries == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$_totalBatteries', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Total Batteries', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(_wiringDescription ?? '', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Series', '$_seriesCount')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Parallel', '$_parallelCount')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total kWh', '${_totalKwh?.toStringAsFixed(1)}')),
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

  Widget _buildDiagramCard(ZaftoColors colors) {
    if (_seriesCount == null || _parallelCount == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRING SCHEMATIC', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_parallelCount!, (p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_seriesCount!, (s) => Container(
                    width: 30,
                    height: 16,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.accentPrimary),
                    ),
                  )),
                ),
              )),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('${_batteryVoltage.round()}V × $_seriesCount = ${_systemVoltage}V per string', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
