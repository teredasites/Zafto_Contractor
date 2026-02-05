import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Emergency Lighting Calculator - Design System v2.6
/// NEC 700.12, IBC 1008 - Egress lighting requirements
class EmergencyLightingScreen extends ConsumerStatefulWidget {
  const EmergencyLightingScreen({super.key});
  @override
  ConsumerState<EmergencyLightingScreen> createState() => _EmergencyLightingScreenState();
}

class _EmergencyLightingScreenState extends ConsumerState<EmergencyLightingScreen> {
  double _corridorLength = 100;
  double _corridorWidth = 6;
  int _floors = 1;
  int _stairwells = 2;
  bool _hasExitDischarge = true;

  double? _corridorArea;
  int? _corridorUnits;
  int? _stairwellUnits;
  int? _exitSignsNeeded;
  int? _totalUnits;
  double? _batteryCapacity;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Emergency Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EGRESS PATH'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Corridor Length', value: _corridorLength, min: 20, max: 500, unit: ' ft', onChanged: (v) { setState(() => _corridorLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Corridor Width', value: _corridorWidth, min: 4, max: 12, unit: ' ft', onChanged: (v) { setState(() => _corridorWidth = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Floors', value: _floors.toDouble(), min: 1, max: 10, unit: '', onChanged: (v) { setState(() => _floors = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Stairwells', value: _stairwells.toDouble(), min: 1, max: 6, unit: '', onChanged: (v) { setState(() => _stairwells = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Exit Discharge Illumination', value: _hasExitDischarge, onChanged: (v) { setState(() => _hasExitDischarge = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EMERGENCY LIGHTING PLAN'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Min 1 fc at floor, 90 min duration per NEC 700.12', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        Switch(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_totalUnits ?? 0}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('emergency light units', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildSpecCard(colors, '${_corridorUnits ?? 0}', 'Corridor'),
          _buildSpecCard(colors, '${_stairwellUnits ?? 0}', 'Stairwell'),
          _buildSpecCard(colors, '${_exitSignsNeeded ?? 0}', 'Exit Signs'),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Corridor area', '${_corridorArea?.toStringAsFixed(0) ?? '0'} sq ft'),
        _buildCalcRow(colors, 'Corridor units', '${_corridorUnits ?? 0} (1 per 50 ft)'),
        _buildCalcRow(colors, 'Stairwell units', '${_stairwellUnits ?? 0} (1 per landing)'),
        _buildCalcRow(colors, 'Exit signs', '${_exitSignsNeeded ?? 0}'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Total units', '${_totalUnits ?? 0}', highlight: true),
        _buildCalcRow(colors, 'Battery capacity', '${_batteryCapacity?.toStringAsFixed(0) ?? '0'} Wh min', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REQUIREMENTS', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildReqItem(colors, 'Min 1 footcandle at floor level'),
            _buildReqItem(colors, '90-minute battery backup'),
            _buildReqItem(colors, 'Automatic activation on power loss'),
            _buildReqItem(colors, 'Monthly 30-sec test, annual 90-min test'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildReqItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(LucideIcons.check, color: colors.accentPrimary, size: 12),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Corridor area per floor
    final corridorArea = _corridorLength * _corridorWidth * _floors;

    // Emergency lights: typically every 50 ft in corridors
    final corridorUnits = ((_corridorLength / 50).ceil()) * _floors;

    // Stairwell: 1 per landing (typically floors + 1 per stairwell)
    final stairwellUnits = (_floors + 1) * _stairwells;

    // Exit signs: at each exit door, direction changes, stairwell entries
    // Roughly 2 per floor minimum + 1 per stairwell
    var exitSigns = (2 * _floors) + _stairwells;
    if (_hasExitDischarge) exitSigns += _stairwells; // Add for exterior

    final total = corridorUnits + stairwellUnits;

    // Battery capacity: assume 5W per unit, 90 minutes
    final batteryWh = total * 5 * 1.5; // 5W × 1.5 hours

    setState(() {
      _corridorArea = corridorArea;
      _corridorUnits = corridorUnits;
      _stairwellUnits = stairwellUnits;
      _exitSignsNeeded = exitSigns;
      _totalUnits = total;
      _batteryCapacity = batteryWh;
    });
  }

  void _reset() {
    setState(() {
      _corridorLength = 100;
      _corridorWidth = 6;
      _floors = 1;
      _stairwells = 2;
      _hasExitDischarge = true;
    });
    _calculate();
  }
}
