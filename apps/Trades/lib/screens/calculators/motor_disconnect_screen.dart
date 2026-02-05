import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Disconnect Calculator - Design System v2.6
/// NEC 430.109/110 - Motor disconnect requirements
class MotorDisconnectScreen extends ConsumerStatefulWidget {
  const MotorDisconnectScreen({super.key});
  @override
  ConsumerState<MotorDisconnectScreen> createState() => _MotorDisconnectScreenState();
}

class _MotorDisconnectScreenState extends ConsumerState<MotorDisconnectScreen> {
  double _motorHp = 5;
  int _voltage = 230;
  bool _singlePhase = false;
  String _motorType = 'induction';

  double? _motorFla;
  double? _minDisconnectAmps;
  String? _disconnectType;
  String? _necReference;
  bool? _requiresLineOfSight;
  String? _lockoutRequirement;

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
        title: Text('Motor Disconnect', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MOTOR'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Horsepower', value: _motorHp, min: 0.5, max: 100, unit: ' HP', onChanged: (v) { setState(() => _motorHp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['115V', '230V', '460V', '575V'], selectedIndex: _voltage == 115 ? 0 : _voltage == 230 ? 1 : _voltage == 460 ? 2 : 3, onChanged: (i) { setState(() => _voltage = [115, 230, 460, 575][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['1Ø', '3Ø'], selectedIndex: _singlePhase ? 0 : 1, onChanged: (i) { setState(() => _singlePhase = i == 0); _calculate(); }),
              const SizedBox(height: 12),
              _buildMotorTypeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DISCONNECT REQUIREMENTS'),
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
        Expanded(child: Text('NEC 430.109/110 - Disconnect sizing and requirements', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
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
          Text('${value.toStringAsFixed(value < 10 ? 1 : 0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: 199, onChanged: onChanged),
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

  Widget _buildMotorTypeSelector(ZaftoColors colors) {
    final types = [('Induction', 'induction'), ('Wound Rotor', 'wound_rotor'), ('Sync', 'synchronous')];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Motor Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: types.map((t) => GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _motorType = t.$2); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _motorType == t.$2 ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: _motorType == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(t.$1, style: TextStyle(color: _motorType == t.$2 ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        )).toList()),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_minDisconnectAmps?.toStringAsFixed(0) ?? '0'}A', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('minimum disconnect rating', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_disconnectType ?? 'Motor Circuit Switch', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Motor FLA', '${_motorFla?.toStringAsFixed(1) ?? '0'} A'),
        _buildCalcRow(colors, 'Min disconnect (115%)', '${_minDisconnectAmps?.toStringAsFixed(0) ?? '0'} A'),
        const SizedBox(height: 16),
        _buildRequirementRow(colors, 'Line of sight', _requiresLineOfSight ?? true ? 'Required or lockable' : 'Not required'),
        _buildRequirementRow(colors, 'Lockout', _lockoutRequirement ?? 'Capable'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
            const SizedBox(width: 8),
            Text(_necReference ?? 'NEC 430.109', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildRequirementRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(LucideIcons.checkCircle, color: colors.accentPrimary, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  void _calculate() {
    // Get motor FLA from NEC tables (simplified lookup)
    final fla = _getMotorFla(_motorHp, _voltage, _singlePhase);

    // NEC 430.110 - Disconnect rating
    // Must be at least 115% of motor FLA
    final minAmps = fla * 1.15;

    // Determine disconnect type
    String discType;
    if (_motorHp <= 2) {
      discType = 'General-use switch (2×FLA)';
    } else if (_motorHp <= 100) {
      discType = 'Motor circuit switch (HP rated)';
    } else {
      discType = 'Circuit breaker or molded case switch';
    }

    setState(() {
      _motorFla = fla;
      _minDisconnectAmps = minAmps;
      _disconnectType = discType;
      _necReference = 'NEC 430.109, 430.110';
      _requiresLineOfSight = true; // 430.102(A)
      _lockoutRequirement = 'Lockout capable per 430.102(B)';
    });
  }

  double _getMotorFla(double hp, int voltage, bool singlePhase) {
    // Simplified FLA lookup (NEC Tables 430.248, 430.250)
    if (singlePhase) {
      // Single phase 115/230V
      if (voltage <= 120) {
        if (hp <= 0.5) return 9.8;
        if (hp <= 1) return 16;
        if (hp <= 1.5) return 20;
        if (hp <= 2) return 24;
        if (hp <= 3) return 34;
        if (hp <= 5) return 56;
        if (hp <= 7.5) return 80;
        if (hp <= 10) return 100;
        return hp * 10;
      } else {
        if (hp <= 0.5) return 4.9;
        if (hp <= 1) return 8;
        if (hp <= 1.5) return 10;
        if (hp <= 2) return 12;
        if (hp <= 3) return 17;
        if (hp <= 5) return 28;
        if (hp <= 7.5) return 40;
        if (hp <= 10) return 50;
        return hp * 5;
      }
    } else {
      // Three phase
      if (voltage <= 230) {
        if (hp <= 0.5) return 2.5;
        if (hp <= 1) return 4.2;
        if (hp <= 1.5) return 6;
        if (hp <= 2) return 6.8;
        if (hp <= 3) return 9.6;
        if (hp <= 5) return 15.2;
        if (hp <= 7.5) return 22;
        if (hp <= 10) return 28;
        if (hp <= 15) return 42;
        if (hp <= 20) return 54;
        if (hp <= 25) return 68;
        if (hp <= 30) return 80;
        if (hp <= 40) return 104;
        if (hp <= 50) return 130;
        if (hp <= 60) return 154;
        if (hp <= 75) return 192;
        if (hp <= 100) return 248;
        return hp * 2.5;
      } else if (voltage <= 460) {
        if (hp <= 0.5) return 1.25;
        if (hp <= 1) return 2.1;
        if (hp <= 1.5) return 3;
        if (hp <= 2) return 3.4;
        if (hp <= 3) return 4.8;
        if (hp <= 5) return 7.6;
        if (hp <= 7.5) return 11;
        if (hp <= 10) return 14;
        if (hp <= 15) return 21;
        if (hp <= 20) return 27;
        if (hp <= 25) return 34;
        if (hp <= 30) return 40;
        if (hp <= 40) return 52;
        if (hp <= 50) return 65;
        if (hp <= 60) return 77;
        if (hp <= 75) return 96;
        if (hp <= 100) return 124;
        return hp * 1.24;
      } else {
        // 575V
        return hp * 1.0;
      }
    }
  }

  void _reset() {
    setState(() {
      _motorHp = 5;
      _voltage = 230;
      _singlePhase = false;
      _motorType = 'induction';
    });
    _calculate();
  }
}
