import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Fire Alarm Circuit Calculator - Design System v2.6
/// NFPA 72 and NEC 760 wire sizing requirements
class FireAlarmCircuitScreen extends ConsumerStatefulWidget {
  const FireAlarmCircuitScreen({super.key});
  @override
  ConsumerState<FireAlarmCircuitScreen> createState() => _FireAlarmCircuitScreenState();
}

class _FireAlarmCircuitScreenState extends ConsumerState<FireAlarmCircuitScreen> {
  String _circuitType = 'slc';
  double _runLength = 500;
  int _deviceCount = 20;
  int _voltage = 24;
  double _currentPerDevice = 0.015;

  double? _totalCurrent;
  double? _voltageDrop;
  double? _voltageDropPercent;
  String? _minWireSize;
  String? _maxLength;
  bool? _isCompliant;

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
        title: Text('Fire Alarm Circuit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CIRCUIT TYPE'),
              const SizedBox(height: 12),
              _buildCircuitTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CIRCUIT PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Run Length (total)', value: _runLength, min: 100, max: 5000, unit: ' ft', onChanged: (v) { setState(() => _runLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Devices', value: _deviceCount.toDouble(), min: 1, max: 127, unit: '', onChanged: (v) { setState(() => _deviceCount = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'System Voltage', options: const ['12V', '24V'], selectedIndex: _voltage == 12 ? 0 : 1, onChanged: (i) { setState(() => _voltage = i == 0 ? 12 : 24); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'WIRE SIZING'),
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
        Expanded(child: Text('NFPA 72 / NEC 760 - Max 10% voltage drop', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildCircuitTypeSelector(ZaftoColors colors) {
    final types = [
      ('SLC (Signaling)', 'slc', 'Addressable device loop'),
      ('NAC (Notification)', 'nac', 'Horn/strobe circuit'),
      ('IDC (Initiating)', 'idc', 'Conventional zone'),
    ];
    return Column(children: types.map((t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _circuitType = t.$2;
            // Adjust current per device based on type
            if (t.$2 == 'slc') _currentPerDevice = 0.015;
            else if (t.$2 == 'nac') _currentPerDevice = 0.10;
            else _currentPerDevice = 0.005;
          });
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _circuitType == t.$2 ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: _circuitType == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
          child: Row(children: [
            Icon(_circuitType == t.$2 ? LucideIcons.checkCircle : LucideIcons.circle, color: _circuitType == t.$2 ? colors.accentPrimary : colors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.$1, style: TextStyle(color: _circuitType == t.$2 ? colors.accentPrimary : colors.textPrimary, fontWeight: FontWeight.w600)),
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
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round() ~/ 10, onChanged: onChanged),
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

  Widget _buildResultCard(ZaftoColors colors) {
    final compliant = _isCompliant ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: compliant ? colors.accentPrimary.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(compliant ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: compliant ? colors.accentPrimary : colors.error, size: 24),
          const SizedBox(width: 8),
          Text(compliant ? 'COMPLIANT' : 'EXCEEDS 10%', style: TextStyle(color: compliant ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        Text(_minWireSize ?? '#18', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('AWG minimum', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Circuit type', _circuitType.toUpperCase()),
        _buildCalcRow(colors, 'Device count', '$_deviceCount'),
        _buildCalcRow(colors, 'Total current', '${_totalCurrent?.toStringAsFixed(3) ?? '0'} A'),
        _buildCalcRow(colors, 'Run length', '${_runLength.toStringAsFixed(0)} ft'),
        _buildCalcRow(colors, 'Voltage drop', '${_voltageDrop?.toStringAsFixed(2) ?? '0'} V'),
        _buildCalcRow(colors, 'Drop percentage', '${_voltageDropPercent?.toStringAsFixed(1) ?? '0'}%'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Max length @ ${_minWireSize ?? '#18'}', _maxLength ?? '0 ft', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REQUIREMENTS', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('• Max 10% voltage drop to last device\n• Min #18 AWG for most circuits\n• Min #14 AWG for signaling over 15V\n• Supervised (Class A or B) circuits', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
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
    // Total current
    final totalCurrent = _deviceCount * _currentPerDevice;

    // Wire resistance (ohms per 1000 ft, round trip = ×2)
    const wireResistance = {
      '22': 16.5,
      '20': 10.4,
      '18': 6.51,
      '16': 4.09,
      '14': 2.58,
      '12': 1.62,
    };

    // Calculate voltage drop for each wire size and find minimum compliant
    String minWire = '#18';
    double vDrop = 0;
    double maxLen = 0;

    for (final entry in wireResistance.entries) {
      final r = entry.value;
      // V = I × R × (length/1000) × 2 (round trip)
      final drop = totalCurrent * r * (_runLength / 1000) * 2;
      final dropPct = (drop / _voltage) * 100;

      if (dropPct <= 10) {
        minWire = '#${entry.key}';
        vDrop = drop;
        // Calculate max length at this wire size
        maxLen = (0.10 * _voltage) / (totalCurrent * r * 2) * 1000;
        break;
      } else if (entry.key == '12') {
        // Even #12 doesn't work, calculate anyway
        minWire = '#12+';
        vDrop = drop;
        maxLen = (0.10 * _voltage) / (totalCurrent * r * 2) * 1000;
      }
    }

    final vDropPct = (vDrop / _voltage) * 100;
    final compliant = vDropPct <= 10;

    setState(() {
      _totalCurrent = totalCurrent;
      _voltageDrop = vDrop;
      _voltageDropPercent = vDropPct;
      _minWireSize = minWire;
      _maxLength = '${maxLen.toStringAsFixed(0)} ft';
      _isCompliant = compliant;
    });
  }

  void _reset() {
    setState(() {
      _circuitType = 'slc';
      _runLength = 500;
      _deviceCount = 20;
      _voltage = 24;
      _currentPerDevice = 0.015;
    });
    _calculate();
  }
}
