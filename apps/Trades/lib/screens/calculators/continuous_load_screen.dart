import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Continuous Load Calculator - Design System v2.6
class ContinuousLoadScreen extends ConsumerStatefulWidget {
  const ContinuousLoadScreen({super.key});
  @override
  ConsumerState<ContinuousLoadScreen> createState() => _ContinuousLoadScreenState();
}

class _ContinuousLoadScreenState extends ConsumerState<ContinuousLoadScreen> {
  final _continuousController = TextEditingController(text: '40');
  final _nonContinuousController = TextEditingController(text: '20');
  int _voltage = 240;
  bool _isSinglePhase = true;

  double get _continuousAmps => double.tryParse(_continuousController.text) ?? 0;
  double get _nonContinuousAmps => double.tryParse(_nonContinuousController.text) ?? 0;
  double get _continuousAdjusted => _continuousAmps * 1.25;
  double get _totalLoadAmps => _continuousAdjusted + _nonContinuousAmps;

  int get _breakerSize {
    final amps = _totalLoadAmps.ceil();
    const sizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200, 225, 250, 300, 350, 400];
    for (final size in sizes) { if (size >= amps) return size; }
    return ((amps / 50).ceil() * 50);
  }

  String get _wireSize {
    final b = _breakerSize;
    if (b <= 15) return '14 AWG'; if (b <= 20) return '12 AWG'; if (b <= 30) return '10 AWG'; if (b <= 40) return '8 AWG';
    if (b <= 55) return '6 AWG'; if (b <= 70) return '4 AWG'; if (b <= 85) return '3 AWG'; if (b <= 100) return '2 AWG';
    if (b <= 115) return '1 AWG'; if (b <= 130) return '1/0 AWG'; if (b <= 150) return '2/0 AWG'; if (b <= 175) return '3/0 AWG';
    if (b <= 200) return '4/0 AWG'; if (b <= 230) return '250 kcmil'; if (b <= 255) return '300 kcmil'; if (b <= 285) return '350 kcmil';
    return '400+ kcmil';
  }

  double get _totalKva => _isSinglePhase ? (_totalLoadAmps * _voltage) / 1000 : (_totalLoadAmps * _voltage * 1.732) / 1000;

  @override
  void dispose() { _continuousController.dispose(); _nonContinuousController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Continuous Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildInputCard(colors),
        const SizedBox(height: 16),
        _buildConfigCard(colors),
        const SizedBox(height: 20),
        _buildResultsCard(colors),
        const SizedBox(height: 16),
        _buildBreakdownCard(colors),
        const SizedBox(height: 16),
        _buildCodeReference(colors),
      ]),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOAD CURRENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.accentPrimary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text('Continuous (3+ hrs)', style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _continuousController, keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: '0', suffixText: 'A', suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 14), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.textSecondary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text('Non-Continuous', style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _nonContinuousController, keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: '0', suffixText: 'A', suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 14), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      ]),
    );
  }

  Widget _buildConfigCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phase', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [_phaseButton(colors, '1φ', true), const SizedBox(width: 8), _phaseButton(colors, '3φ', false)]),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voltage', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<int>(value: _voltage, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: [120, 208, 240, 277, 480].map((v) => DropdownMenuItem(value: v, child: Text('${v}V'))).toList(), onChanged: (v) => setState(() => _voltage = v!)),
            ),
          ])),
        ]),
      ]),
    );
  }

  Widget _phaseButton(ZaftoColors colors, String label, bool isSingle) {
    final isSelected = _isSinglePhase == isSingle;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _isSinglePhase = isSingle); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_breakerSize}A', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('Minimum OCPD Size', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildRow(colors, 'Calculated Load', '${_totalLoadAmps.toStringAsFixed(1)}A', false),
            const SizedBox(height: 10),
            _buildRow(colors, 'Wire Size (Cu 75°C)', _wireSize, true),
            const SizedBox(height: 10),
            _buildRow(colors, 'Total kVA', '${_totalKva.toStringAsFixed(1)}', false),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBreakdownCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CALCULATION BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildCalcRow(colors, 'Continuous Load', '${_continuousAmps.toStringAsFixed(1)}A', false),
        _buildCalcRow(colors, '× 125%', '${_continuousAdjusted.toStringAsFixed(1)}A', true),
        Divider(height: 20, color: colors.borderSubtle),
        _buildCalcRow(colors, 'Non-Continuous', '${_nonContinuousAmps.toStringAsFixed(1)}A', false),
        _buildCalcRow(colors, '× 100%', '${_nonContinuousAmps.toStringAsFixed(1)}A', false),
        Divider(height: 20, color: colors.borderSubtle),
        _buildCalcRow(colors, 'Total Required', '${_totalLoadAmps.toStringAsFixed(1)}A', true),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
      ]),
    );
  }

  Widget _buildRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 210.20(A)', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Continuous load = 3+ hours max current\n• OCPD ≥ 125% continuous + 100% non-cont.\n• Conductor sized same as OCPD\n• Exception: 100% rated breakers', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
