import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Lighting Control Calculator - Design System v2.6
/// Dimmer and switch load calculations
class LightingControlScreen extends ConsumerStatefulWidget {
  const LightingControlScreen({super.key});
  @override
  ConsumerState<LightingControlScreen> createState() => _LightingControlScreenState();
}

class _LightingControlScreenState extends ConsumerState<LightingControlScreen> {
  String _loadType = 'led';
  double _totalWatts = 500;
  int _voltage = 120;
  String _controlType = 'dimmer';

  double? _loadAmps;
  double? _deratedAmps;
  String? _switchRating;
  String? _dimmerRating;
  String? _neutralRequired;
  String? _minWireSize;

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
        title: Text('Lighting Control', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD TYPE'),
              const SizedBox(height: 12),
              _buildLoadTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total Watts', value: _totalWatts, min: 50, max: 2000, unit: ' W', onChanged: (v) { setState(() => _totalWatts = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['120V', '277V'], selectedIndex: _voltage == 120 ? 0 : 1, onChanged: (i) { setState(() => _voltage = i == 0 ? 120 : 277); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONTROL TYPE'),
              const SizedBox(height: 12),
              _buildControlTypeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CONTROL REQUIREMENTS'),
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
        Expanded(child: Text('NEC 404 - Switch and dimmer load ratings', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildLoadTypeSelector(ZaftoColors colors) {
    final types = [
      ('LED', 'led', 'Most common, requires compatible dimmer'),
      ('CFL', 'cfl', 'Dimmable CFL only'),
      ('Incandescent', 'incandescent', 'Standard resistive load'),
      ('MLV', 'mlv', 'Magnetic low voltage'),
      ('ELV', 'elv', 'Electronic low voltage'),
    ];
    return Column(children: types.map((t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _loadType = t.$2); _calculate(); },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _loadType == t.$2 ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: _loadType == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
          child: Row(children: [
            Icon(_loadType == t.$2 ? LucideIcons.checkCircle : LucideIcons.circle, color: _loadType == t.$2 ? colors.accentPrimary : colors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.$1, style: TextStyle(color: _loadType == t.$2 ? colors.accentPrimary : colors.textPrimary, fontWeight: FontWeight.w600)),
              Text(t.$3, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ])),
          ]),
        ),
      ),
    )).toList());
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

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: List.generate(options.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(i); },
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selectedIndex == i ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: selectedIndex == i ? colors.accentPrimary : colors.borderSubtle)),
              alignment: Alignment.center,
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildControlTypeSelector(ZaftoColors colors) {
    final types = [('Switch', 'switch'), ('Dimmer', 'dimmer'), ('Smart Switch', 'smart')];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: types.map((t) => Expanded(
        child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _controlType = t.$2); _calculate(); },
          child: Container(
            margin: EdgeInsets.only(right: t.$2 != 'smart' ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _controlType == t.$2 ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: _controlType == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
            alignment: Alignment.center,
            child: Text(t.$1, style: TextStyle(color: _controlType == t.$2 ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      )).toList()),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text(_controlType == 'dimmer' ? _dimmerRating ?? '600W' : _switchRating ?? '15A', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('minimum ${_controlType == 'dimmer' ? 'dimmer' : 'switch'} rating', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Load', '${_totalWatts.toStringAsFixed(0)} W'),
        _buildCalcRow(colors, 'Load current', '${_loadAmps?.toStringAsFixed(2) ?? '0'} A'),
        _buildCalcRow(colors, 'Derated (80%)', '${_deratedAmps?.toStringAsFixed(2) ?? '0'} A'),
        _buildCalcRow(colors, 'Min wire size', _minWireSize ?? '#14 AWG'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _neutralRequired == 'Yes' ? colors.warning.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(_neutralRequired == 'Yes' ? LucideIcons.alertTriangle : LucideIcons.info, color: _neutralRequired == 'Yes' ? colors.warning : colors.accentPrimary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Neutral at switch: ${_neutralRequired ?? 'Check'}', style: TextStyle(color: _neutralRequired == 'Yes' ? colors.warning : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 12),
        if (_loadType == 'led' || _loadType == 'cfl') Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use dimmer rated for ${_loadType.toUpperCase()} loads. Check compatibility with specific fixtures.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ),
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
    final amps = _totalWatts / _voltage;
    final derated = amps / 0.80; // 80% continuous load rule

    // Switch rating
    String switchRating;
    if (derated <= 15) switchRating = '15A';
    else if (derated <= 20) switchRating = '20A';
    else if (derated <= 30) switchRating = '30A';
    else switchRating = '${(derated / 5).ceil() * 5}A';

    // Dimmer rating - varies by load type
    String dimmerRating;
    double effectiveWatts = _totalWatts;

    // LED/CFL loads may have higher inrush, derate accordingly
    if (_loadType == 'led' || _loadType == 'cfl') {
      effectiveWatts *= 1.25; // 25% derating for electronic loads
    } else if (_loadType == 'mlv') {
      effectiveWatts *= 1.25; // MLV needs magnetic dimmer
    }

    if (effectiveWatts <= 150) dimmerRating = '150W';
    else if (effectiveWatts <= 300) dimmerRating = '300W';
    else if (effectiveWatts <= 600) dimmerRating = '600W';
    else if (effectiveWatts <= 1000) dimmerRating = '1000W';
    else if (effectiveWatts <= 1500) dimmerRating = '1500W';
    else dimmerRating = '${((effectiveWatts / 500).ceil()) * 500}W';

    // Neutral required per NEC 404.2(C) for smart switches/dimmers
    String neutral = (_controlType == 'smart' || _controlType == 'dimmer') ? 'Yes' : 'No';

    // Wire size
    String wire = derated <= 15 ? '#14 AWG' : derated <= 20 ? '#12 AWG' : '#10 AWG';

    setState(() {
      _loadAmps = amps;
      _deratedAmps = derated;
      _switchRating = switchRating;
      _dimmerRating = dimmerRating;
      _neutralRequired = neutral;
      _minWireSize = wire;
    });
  }

  void _reset() {
    setState(() {
      _loadType = 'led';
      _totalWatts = 500;
      _voltage = 120;
      _controlType = 'dimmer';
    });
    _calculate();
  }
}
