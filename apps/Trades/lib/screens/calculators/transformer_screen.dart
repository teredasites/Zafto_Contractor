import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Transformer Sizing Calculator - Design System v2.6
class TransformerScreen extends ConsumerStatefulWidget {
  const TransformerScreen({super.key});
  @override
  ConsumerState<TransformerScreen> createState() => _TransformerScreenState();
}

class _TransformerScreenState extends ConsumerState<TransformerScreen> {
  bool _isThreePhase = false;
  final _loadController = TextEditingController();
  final _voltageController = TextEditingController(text: '480');
  final _pfController = TextEditingController(text: '0.9');
  final _effController = TextEditingController(text: '0.95');
  double? _kva;
  double? _amps;
  int? _recommendedSize;

  static const List<int> _standardSizes = [3, 5, 7, 10, 15, 25, 30, 37, 45, 50, 75, 100, 112, 150, 167, 200, 225, 250, 300, 333, 400, 500, 750, 1000, 1500, 2000, 2500, 3000];

  @override
  void dispose() { _loadController.dispose(); _voltageController.dispose(); _pfController.dispose(); _effController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Transformer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildPhaseSelector(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'LOAD PARAMETERS'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Load', unit: 'kW', hint: 'Connected load', controller: _loadController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Secondary Voltage', unit: 'V', hint: '208, 240, 480', controller: _voltageController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Power Factor', hint: '0.8 - 1.0', controller: _pfController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Efficiency', hint: '0.9 - 0.98', controller: _effController),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ),
            const SizedBox(height: 24),
            if (_kva != null) _buildResults(colors),
            const SizedBox(height: 24),
            _buildStandardSizesCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhaseSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _isThreePhase = false); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: !_isThreePhase ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Text('1-PHASE', textAlign: TextAlign.center, style: TextStyle(color: !_isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _isThreePhase = true); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _isThreePhase ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Text('3-PHASE', textAlign: TextAlign.center, style: TextStyle(color: _isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        )),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('$_recommendedSize', style: TextStyle(color: colors.accentSuccess, fontSize: 64, fontWeight: FontWeight.w700)),
        Text('kVA RECOMMENDED', style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
        const SizedBox(height: 20),
        _buildResultRow(colors, label: 'Calculated kVA', value: '${_kva!.toStringAsFixed(1)} kVA'),
        const SizedBox(height: 8),
        _buildResultRow(colors, label: 'Secondary Amps', value: '${_amps!.toStringAsFixed(1)} A'),
        const SizedBox(height: 8),
        _buildResultRow(colors, label: 'Phase', value: _isThreePhase ? '3-Phase' : '1-Phase'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStandardSizesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD TRANSFORMER SIZES (kVA)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [3, 5, 7.5, 10, 15, 25, 37.5, 50, 75, 100, 150, 200, 250, 300, 500, 750, 1000].map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6)),
          child: Text('$s', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        )).toList()),
      ]),
    );
  }

  void _calculate() {
    final colors = ref.read(zaftoColorsProvider);
    final load = double.tryParse(_loadController.text);
    final voltage = double.tryParse(_voltageController.text);
    final pf = double.tryParse(_pfController.text);
    final eff = double.tryParse(_effController.text);
    if (load == null || load <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid load'), backgroundColor: colors.accentError)); return; }
    if (voltage == null || voltage <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid voltage'), backgroundColor: colors.accentError)); return; }
    final powerFactor = (pf ?? 0.9).clamp(0.5, 1.0);
    final efficiency = (eff ?? 0.95).clamp(0.8, 1.0);
    final kva = load / (powerFactor * efficiency);
    double amps = _isThreePhase ? (kva * 1000) / (voltage * math.sqrt(3)) : (kva * 1000) / voltage;
    int recommended = _standardSizes.last;
    for (final size in _standardSizes) { if (size >= kva) { recommended = size; break; } }
    setState(() { _kva = kva; _amps = amps; _recommendedSize = recommended; });
  }

  void _reset() { _loadController.clear(); _voltageController.text = '480'; _pfController.text = '0.9'; _effController.text = '0.95'; setState(() { _isThreePhase = false; _kva = null; _amps = null; _recommendedSize = null; }); }
}
