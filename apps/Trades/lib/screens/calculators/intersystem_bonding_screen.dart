import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Intersystem Bonding Calculator - Design System v2.6
/// NEC 250.94 - Communications systems bonding
class IntersystemBondingScreen extends ConsumerStatefulWidget {
  const IntersystemBondingScreen({super.key});
  @override
  ConsumerState<IntersystemBondingScreen> createState() => _IntersystemBondingScreenState();
}

class _IntersystemBondingScreenState extends ConsumerState<IntersystemBondingScreen> {
  bool _hasCatv = true;
  bool _hasTelephone = true;
  bool _hasSatellite = false;
  bool _hasAntenna = false;
  bool _hasLowVoltage = false;
  int _serviceAmps = 200;

  String? _bondingConductorSize;
  int? _terminalsRequired;
  String? _ibtLocation;
  List<String> _systems = [];

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
        title: Text('Intersystem Bonding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COMMUNICATION SYSTEMS'),
              const SizedBox(height: 12),
              _buildSystemToggle(colors, 'CATV / Cable', _hasCatv, (v) { setState(() => _hasCatv = v); _calculate(); }),
              const SizedBox(height: 8),
              _buildSystemToggle(colors, 'Telephone / Data', _hasTelephone, (v) { setState(() => _hasTelephone = v); _calculate(); }),
              const SizedBox(height: 8),
              _buildSystemToggle(colors, 'Satellite Dish', _hasSatellite, (v) { setState(() => _hasSatellite = v); _calculate(); }),
              const SizedBox(height: 8),
              _buildSystemToggle(colors, 'TV Antenna', _hasAntenna, (v) { setState(() => _hasAntenna = v); _calculate(); }),
              const SizedBox(height: 8),
              _buildSystemToggle(colors, 'Other Low-Voltage', _hasLowVoltage, (v) { setState(() => _hasLowVoltage = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SERVICE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Service Size', value: _serviceAmps.toDouble(), min: 100, max: 400, unit: ' A', onChanged: (v) { setState(() => _serviceAmps = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'INTERSYSTEM BONDING'),
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
        Expanded(child: Text('NEC 250.94 - Required at service for all communication systems', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSystemToggle(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Row(children: [
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textTertiary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: value ? colors.textPrimary : colors.textSecondary, fontWeight: value ? FontWeight.w600 : FontWeight.normal))),
        ]),
      ),
    );
  }

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
          child: Slider(value: value, min: min, max: max, divisions: ((max - min) / 50).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildSpecCard(colors, _bondingConductorSize ?? '#6', 'Conductor'),
          _buildSpecCard(colors, '${_terminalsRequired ?? 3}', 'Terminals'),
        ]),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('INTERSYSTEM BONDING TERMINATION (IBT)', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(_ibtLocation ?? 'At service entrance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Systems requiring bonding:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            ..._systems.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(LucideIcons.check, color: colors.accentPrimary, size: 14),
                const SizedBox(width: 8),
                Text(s, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Bonding conductor', _bondingConductorSize ?? '#6 AWG Cu'),
        _buildCalcRow(colors, 'IBT terminals', '${_terminalsRequired ?? 3} minimum'),
        _buildCalcRow(colors, 'Max conductor length', '20 ft to IBT'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('NEC 250.94 Requirements', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('• Accessible location\n• External or internal at meter\n• Min #14 Cu for each system\n• IBT sized per 250.94(A)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 28)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
    // Count systems
    final systems = <String>[];
    if (_hasCatv) systems.add('CATV / Cable');
    if (_hasTelephone) systems.add('Telephone / Data');
    if (_hasSatellite) systems.add('Satellite Dish');
    if (_hasAntenna) systems.add('TV Antenna');
    if (_hasLowVoltage) systems.add('Other Low-Voltage');

    // Minimum 3 terminals required per 250.94
    final terminals = systems.length < 3 ? 3 : systems.length + 1;

    // Bonding conductor size per 250.94
    // Connected to GEC, GE, or enclosure ground
    // Minimum #6 AWG Cu for most residential
    String conductor;
    if (_serviceAmps <= 100) {
      conductor = '#6 AWG Cu';
    } else if (_serviceAmps <= 200) {
      conductor = '#6 AWG Cu';
    } else if (_serviceAmps <= 400) {
      conductor = '#4 AWG Cu';
    } else {
      conductor = '#2 AWG Cu';
    }

    // IBT location
    String location;
    if (_serviceAmps <= 200) {
      location = 'At meter base or service disconnect';
    } else {
      location = 'At service entrance equipment';
    }

    setState(() {
      _bondingConductorSize = conductor;
      _terminalsRequired = terminals;
      _ibtLocation = location;
      _systems = systems;
    });
  }

  void _reset() {
    setState(() {
      _hasCatv = true;
      _hasTelephone = true;
      _hasSatellite = false;
      _hasAntenna = false;
      _hasLowVoltage = false;
      _serviceAmps = 200;
    });
    _calculate();
  }
}
