import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Feeder Calculator - Design System v2.6
/// NEC 430.24 - Feeder sizing for multiple motors
class MotorFeederScreen extends ConsumerStatefulWidget {
  const MotorFeederScreen({super.key});
  @override
  ConsumerState<MotorFeederScreen> createState() => _MotorFeederScreenState();
}

class _MotorFeederScreenState extends ConsumerState<MotorFeederScreen> {
  final List<_MotorEntry> _motors = [
    _MotorEntry(hp: 10, fla: 28),
    _MotorEntry(hp: 5, fla: 15.2),
    _MotorEntry(hp: 3, fla: 9.6),
  ];
  int _voltage = 230;

  double? _largestMotorFla;
  double? _otherMotorsTotal;
  double? _feederAmps;
  String? _wireSize;
  String? _conduitSize;

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
        title: Text('Motor Feeder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM VOLTAGE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['208V', '230V', '460V', '575V'], selectedIndex: _voltage == 208 ? 0 : _voltage == 230 ? 1 : _voltage == 460 ? 2 : 3, onChanged: (i) { setState(() => _voltage = [208, 230, 460, 575][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MOTORS'),
              const SizedBox(height: 12),
              ..._motors.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMotorRow(colors, e.key),
              )),
              _buildAddMotorButton(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FEEDER CALCULATION'),
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
        Expanded(child: Text('NEC 430.24 - 125% largest + 100% others', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

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

  Widget _buildMotorRow(ZaftoColors colors, int index) {
    final motor = _motors[index];
    final isLargest = motor.fla == _motors.map((m) => m.fla).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLargest ? colors.accentPrimary : colors.borderSubtle, width: isLargest ? 2 : 1),
      ),
      child: Row(children: [
        if (isLargest) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)),
          child: Text('LARGEST', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Motor ${index + 1}', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            Text('${motor.hp} HP', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(isDense: true, suffixText: 'A', suffixStyle: TextStyle(color: colors.textTertiary), border: InputBorder.none),
            controller: TextEditingController(text: motor.fla.toString()),
            onChanged: (v) { motor.fla = double.tryParse(v) ?? 0; _calculate(); },
          ),
        ),
        if (_motors.length > 1) IconButton(
          icon: Icon(LucideIcons.trash2, color: colors.error, size: 20),
          onPressed: () { setState(() => _motors.removeAt(index)); _calculate(); },
        ),
      ]),
    );
  }

  Widget _buildAddMotorButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { setState(() => _motors.add(_MotorEntry(hp: 5, fla: 15.2))); _calculate(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.plus, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text('Add Motor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_feederAmps?.toStringAsFixed(1) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps minimum feeder', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildSpecChip(colors, _wireSize ?? '#4 Cu', 'Wire'),
          const SizedBox(width: 12),
          _buildSpecChip(colors, _conduitSize ?? '1"', 'Conduit'),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Largest motor FLA', '${_largestMotorFla?.toStringAsFixed(1) ?? '0'} A'),
        _buildCalcRow(colors, 'Largest × 125%', '${((_largestMotorFla ?? 0) * 1.25).toStringAsFixed(1)} A'),
        _buildCalcRow(colors, 'Other motors total', '${_otherMotorsTotal?.toStringAsFixed(1) ?? '0'} A'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Minimum feeder', '${_feederAmps?.toStringAsFixed(1) ?? '0'} A', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
            const SizedBox(width: 8),
            Text('NEC 430.24', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecChip(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
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
    if (_motors.isEmpty) return;

    // Find largest motor
    double largest = 0;
    double others = 0;

    for (final motor in _motors) {
      if (motor.fla > largest) {
        others += largest; // Previous largest becomes "other"
        largest = motor.fla;
      } else {
        others += motor.fla;
      }
    }

    // NEC 430.24: 125% of largest + 100% of others
    final feeder = (largest * 1.25) + others;

    // Determine wire size (75°C copper)
    String wire;
    if (feeder <= 20) wire = '#12 Cu';
    else if (feeder <= 30) wire = '#10 Cu';
    else if (feeder <= 40) wire = '#8 Cu';
    else if (feeder <= 55) wire = '#6 Cu';
    else if (feeder <= 70) wire = '#4 Cu';
    else if (feeder <= 85) wire = '#3 Cu';
    else if (feeder <= 100) wire = '#2 Cu';
    else if (feeder <= 115) wire = '#1 Cu';
    else if (feeder <= 130) wire = '1/0 Cu';
    else if (feeder <= 150) wire = '2/0 Cu';
    else if (feeder <= 175) wire = '3/0 Cu';
    else if (feeder <= 200) wire = '4/0 Cu';
    else wire = '250 kcmil';

    // Determine conduit size (EMT, 3 conductors + ground)
    String conduit;
    if (feeder <= 30) conduit = '3/4"';
    else if (feeder <= 55) conduit = '1"';
    else if (feeder <= 85) conduit = '1-1/4"';
    else if (feeder <= 115) conduit = '1-1/2"';
    else if (feeder <= 175) conduit = '2"';
    else conduit = '2-1/2"';

    setState(() {
      _largestMotorFla = largest;
      _otherMotorsTotal = others;
      _feederAmps = feeder;
      _wireSize = wire;
      _conduitSize = conduit;
    });
  }

  void _reset() {
    setState(() {
      _motors.clear();
      _motors.addAll([
        _MotorEntry(hp: 10, fla: 28),
        _MotorEntry(hp: 5, fla: 15.2),
        _MotorEntry(hp: 3, fla: 9.6),
      ]);
      _voltage = 230;
    });
    _calculate();
  }
}

class _MotorEntry {
  double hp;
  double fla;
  _MotorEntry({required this.hp, required this.fla});
}
