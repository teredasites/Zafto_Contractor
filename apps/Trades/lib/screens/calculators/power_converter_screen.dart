import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Power Converter - Design System v2.6
class PowerConverterScreen extends ConsumerStatefulWidget {
  const PowerConverterScreen({super.key});
  @override
  ConsumerState<PowerConverterScreen> createState() => _PowerConverterScreenState();
}

enum ConvertFrom { kw, kva, amps }

class _PowerConverterScreenState extends ConsumerState<PowerConverterScreen> {
  ConvertFrom _convertFrom = ConvertFrom.kw;
  bool _isThreePhase = false;
  final _valueController = TextEditingController();
  final _voltageController = TextEditingController(text: '480');
  final _pfController = TextEditingController(text: '0.9');
  Map<String, double>? _results;

  @override
  void dispose() { _valueController.dispose(); _voltageController.dispose(); _pfController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Power Converter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildPhaseToggle(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'CONVERT FROM'),
            const SizedBox(height: 12),
            _buildConvertFromSelector(colors),
            const SizedBox(height: 24),
            ZaftoInputField(
              label: _getInputLabel(),
              unit: _getInputUnit(),
              controller: _valueController,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            ZaftoInputField(
              label: 'Voltage',
              unit: 'V',
              controller: _voltageController,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            ZaftoInputField(
              label: 'Power Factor',
              hint: '0.8 - 1.0',
              controller: _pfController,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
            const SizedBox(height: 24),
            _buildFormulasCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhaseToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _buildPhaseButton(colors, '1-PHASE', !_isThreePhase, () { HapticFeedback.selectionClick(); setState(() => _isThreePhase = false); _calculate(); }),
        _buildPhaseButton(colors, '3-PHASE', _isThreePhase, () { HapticFeedback.selectionClick(); setState(() => _isThreePhase = true); _calculate(); }),
      ]),
    );
  }

  Widget _buildPhaseButton(ZaftoColors colors, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
    )));
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildConvertFromSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: ConvertFrom.values.map((type) {
        final isSelected = type == _convertFrom;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _convertFrom = type; _results = null; }); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Text(type == ConvertFrom.kw ? 'kW' : type == ConvertFrom.kva ? 'kVA' : 'Amps', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RESULTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        _buildResultTile(colors, label: 'Kilowatts', value: '${_results!['kw']!.toStringAsFixed(2)} kW', icon: LucideIcons.zap, color: colors.accentWarning),
        const SizedBox(height: 12),
        _buildResultTile(colors, label: 'Apparent Power', value: '${_results!['kva']!.toStringAsFixed(2)} kVA', icon: LucideIcons.activity, color: colors.accentPrimary),
        const SizedBox(height: 12),
        _buildResultTile(colors, label: 'Current', value: '${_results!['amps']!.toStringAsFixed(1)} A', icon: LucideIcons.gauge, color: colors.accentSuccess),
      ]),
    );
  }

  Widget _buildResultTile(ZaftoColors colors, {required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }

  Widget _buildFormulasCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isThreePhase ? '3-PHASE FORMULAS' : '1-PHASE FORMULAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (_isThreePhase) ...[
          _buildFormulaRow(colors, 'kVA = (V × I × √3) / 1000'),
          _buildFormulaRow(colors, 'kW = kVA × PF'),
          _buildFormulaRow(colors, 'I = kVA × 1000 / (V × √3)'),
        ] else ...[
          _buildFormulaRow(colors, 'kVA = (V × I) / 1000'),
          _buildFormulaRow(colors, 'kW = kVA × PF'),
          _buildFormulaRow(colors, 'I = kVA × 1000 / V'),
        ],
      ]),
    );
  }

  Widget _buildFormulaRow(ZaftoColors colors, String formula) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(formula, style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 13)));

  String _getInputLabel() => _convertFrom == ConvertFrom.kw ? 'Kilowatts' : _convertFrom == ConvertFrom.kva ? 'kVA' : 'Amps';
  String _getInputUnit() => _convertFrom == ConvertFrom.kw ? 'kW' : _convertFrom == ConvertFrom.kva ? 'kVA' : 'A';

  void _calculate() {
    final value = double.tryParse(_valueController.text);
    final voltage = double.tryParse(_voltageController.text);
    final pf = double.tryParse(_pfController.text);
    if (value == null || voltage == null || voltage <= 0) { setState(() => _results = null); return; }
    final powerFactor = (pf ?? 0.9).clamp(0.1, 1.0);
    double kw, kva, amps;
    switch (_convertFrom) {
      case ConvertFrom.kw: kw = value; kva = kw / powerFactor; amps = _isThreePhase ? (kva * 1000) / (voltage * math.sqrt(3)) : (kva * 1000) / voltage; break;
      case ConvertFrom.kva: kva = value; kw = kva * powerFactor; amps = _isThreePhase ? (kva * 1000) / (voltage * math.sqrt(3)) : (kva * 1000) / voltage; break;
      case ConvertFrom.amps: amps = value; kva = _isThreePhase ? (amps * voltage * math.sqrt(3)) / 1000 : (amps * voltage) / 1000; kw = kva * powerFactor; break;
    }
    setState(() => _results = {'kw': kw, 'kva': kva, 'amps': amps});
  }

  void _reset() { _valueController.clear(); _voltageController.text = '480'; _pfController.text = '0.9'; setState(() { _convertFrom = ConvertFrom.kw; _isThreePhase = false; _results = null; }); }
}
