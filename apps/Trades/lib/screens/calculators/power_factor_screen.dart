import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Power Factor Correction Calculator - Design System v2.6
class PowerFactorScreen extends ConsumerStatefulWidget {
  const PowerFactorScreen({super.key});
  @override
  ConsumerState<PowerFactorScreen> createState() => _PowerFactorScreenState();
}

class _PowerFactorScreenState extends ConsumerState<PowerFactorScreen> {
  final _kwController = TextEditingController();
  final _currentPfController = TextEditingController(text: '0.80');
  final _targetPfController = TextEditingController(text: '0.95');
  Map<String, dynamic>? _result;

  @override
  void dispose() { _kwController.dispose(); _currentPfController.dispose(); _targetPfController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Power Factor Correction', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(colors),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _calculate,
            child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.w600)),
          )),
          const SizedBox(height: 20),
          if (_result != null) ...[
            if (_result!.containsKey('error')) _buildErrorCard(colors, _result!['error']) else _buildResults(colors),
          ],
          const SizedBox(height: 16),
          _buildInfoCard(colors),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _kwController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: colors.textPrimary), decoration: InputDecoration(labelText: 'Real Power (kW)', labelStyle: TextStyle(color: colors.textTertiary), hintText: 'Enter load in kW', hintStyle: TextStyle(color: colors.textQuaternary), suffixText: 'kW', suffixStyle: TextStyle(color: colors.textTertiary), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderSubtle)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accentPrimary)))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(controller: _currentPfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: colors.textPrimary), decoration: InputDecoration(labelText: 'Current PF', labelStyle: TextStyle(color: colors.textTertiary), hintText: '0.80', hintStyle: TextStyle(color: colors.textQuaternary), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderSubtle)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accentPrimary))))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _targetPfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: colors.textPrimary), decoration: InputDecoration(labelText: 'Target PF', labelStyle: TextStyle(color: colors.textTertiary), hintText: '0.95', hintStyle: TextStyle(color: colors.textQuaternary), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderSubtle)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accentPrimary))))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildQuickButton(colors, '0.70 → 0.90', () { _currentPfController.text = '0.70'; _targetPfController.text = '0.90'; }),
          _buildQuickButton(colors, '0.80 → 0.95', () { _currentPfController.text = '0.80'; _targetPfController.text = '0.95'; }),
          _buildQuickButton(colors, '0.85 → 0.98', () { _currentPfController.text = '0.85'; _targetPfController.text = '0.98'; }),
        ]),
      ]),
    );
  }

  Widget _buildQuickButton(ZaftoColors colors, String label, VoidCallback onTap) {
    return GestureDetector(onTap: () { HapticFeedback.selectionClick(); onTap(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.borderSubtle)), child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))));
  }

  Widget _buildResults(ZaftoColors colors) {
    final r = _result!;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
        child: Column(children: [
          Text('Capacitor Required', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text('${r['kvarRequired'].toStringAsFixed(1)} kVAR', style: TextStyle(color: colors.accentSuccess, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('to improve PF from ${(r['currentPf'] * 100).toStringAsFixed(0)}% to ${(r['targetPf'] * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildComparisonCard(colors, title: 'Before', kva: r['currentKva'], kvar: r['currentKvar'], pf: r['currentPf'], isBefore: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildComparisonCard(colors, title: 'After', kva: r['newKva'], kvar: r['newKvar'], pf: r['targetPf'], isBefore: false)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(LucideIcons.trendingDown, color: colors.accentPrimary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Apparent Power Reduction', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('${r['currentReduction'].toStringAsFixed(1)}% lower kVA demand', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildComparisonCard(ZaftoColors colors, {required String title, required double kva, required double kvar, required double pf, required bool isBefore}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isBefore ? colors.bgBase : colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isBefore ? colors.borderSubtle : colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: isBefore ? colors.textTertiary : colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 10),
        _buildStatRow(colors, 'kVA', kva.toStringAsFixed(1)),
        _buildStatRow(colors, 'kVAR', kvar.toStringAsFixed(1)),
        _buildStatRow(colors, 'PF', '${(pf * 100).toStringAsFixed(0)}%'),
      ]),
    );
  }

  Widget _buildStatRow(ZaftoColors colors, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
    ]));
  }

  Widget _buildErrorCard(ZaftoColors colors, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.accentError.withValues(alpha: 0.3))),
      child: Row(children: [Icon(LucideIcons.alertCircle, color: colors.accentError), const SizedBox(width: 12), Text(message, style: TextStyle(color: colors.accentError))]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.info, color: colors.accentPrimary, size: 18), const SizedBox(width: 8), Text('Why Correct Power Factor?', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
        const SizedBox(height: 10),
        Text('• Reduce utility demand charges\n• Lower line losses (I²R)\n• Free up transformer capacity\n• Reduce voltage drop\n• Utilities often penalize PF < 0.90', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  void _calculate() {
    final kw = double.tryParse(_kwController.text);
    final currentPf = double.tryParse(_currentPfController.text);
    final targetPf = double.tryParse(_targetPfController.text);
    if (kw == null || currentPf == null || targetPf == null) { setState(() => _result = null); return; }
    if (currentPf <= 0 || currentPf > 1 || targetPf <= 0 || targetPf > 1) { setState(() => _result = null); return; }
    if (targetPf <= currentPf) { setState(() => _result = {'error': 'Target PF must be higher than current PF'}); return; }
    final theta1 = math.acos(currentPf); final theta2 = math.acos(targetPf);
    final tan1 = math.tan(theta1); final tan2 = math.tan(theta2);
    final kvarRequired = kw * (tan1 - tan2);
    final currentKva = kw / currentPf; final currentKvar = kw * tan1;
    final newKva = kw / targetPf; final newKvar = kw * tan2;
    final currentReduction = ((currentKva - newKva) / currentKva) * 100;
    setState(() { _result = {'kw': kw, 'currentPf': currentPf, 'targetPf': targetPf, 'kvarRequired': kvarRequired, 'currentKva': currentKva, 'currentKvar': currentKvar, 'newKva': newKva, 'newKvar': newKvar, 'currentReduction': currentReduction}; });
  }

  void _reset() { _kwController.clear(); _currentPfController.text = '0.80'; _targetPfController.text = '0.95'; setState(() => _result = null); }
}
