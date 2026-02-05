/// Electrical Formulas Reference - Design System v2.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class FormulasScreen extends ConsumerWidget {
  const FormulasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Formulas', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _FormulaSection(title: "OHM'S LAW", colors: colors, formulas: const [_Formula(name: 'Voltage', formula: 'E = I × R', unit: 'Volts'), _Formula(name: 'Current', formula: 'I = E / R', unit: 'Amps'), _Formula(name: 'Resistance', formula: 'R = E / I', unit: 'Ohms')]),
        _FormulaSection(title: 'POWER (DC & 1Φ AC)', colors: colors, formulas: const [_Formula(name: 'Power', formula: 'P = E × I', unit: 'Watts'), _Formula(name: 'Power', formula: 'P = I² × R', unit: 'Watts'), _Formula(name: 'Power', formula: 'P = E² / R', unit: 'Watts'), _Formula(name: 'Current', formula: 'I = P / E', unit: 'Amps')]),
        _FormulaSection(title: 'POWER (1Φ AC with PF)', colors: colors, formulas: const [_Formula(name: 'Real Power', formula: 'P = E × I × PF', unit: 'Watts'), _Formula(name: 'Apparent Power', formula: 'S = E × I', unit: 'VA'), _Formula(name: 'Power Factor', formula: 'PF = P / S', unit: 'decimal'), _Formula(name: 'Current', formula: 'I = P / (E × PF)', unit: 'Amps')]),
        _FormulaSection(title: 'POWER (3Φ AC)', colors: colors, formulas: const [_Formula(name: 'Real Power', formula: 'P = √3 × E × I × PF', unit: 'Watts'), _Formula(name: 'Apparent Power', formula: 'S = √3 × E × I', unit: 'VA'), _Formula(name: 'Current', formula: 'I = P / (√3 × E × PF)', unit: 'Amps')]),
        _FormulaSection(title: 'VOLTAGE DROP', colors: colors, formulas: const [_Formula(name: 'VD (1Φ)', formula: 'VD = 2 × K × I × D / CM', unit: 'Volts'), _Formula(name: 'VD (3Φ)', formula: 'VD = √3 × K × I × D / CM', unit: 'Volts'), _Formula(name: 'K (Copper)', formula: 'K = 12.9', unit: 'Ω·cmil/ft'), _Formula(name: 'K (Aluminum)', formula: 'K = 21.2', unit: 'Ω·cmil/ft')]),
        _FormulaSection(title: 'MOTOR CALCULATIONS', colors: colors, formulas: const [_Formula(name: 'HP to kW', formula: 'kW = HP × 0.746', unit: 'kW'), _Formula(name: 'kW to HP', formula: 'HP = kW / 0.746', unit: 'HP'), _Formula(name: 'Motor FLA (1Φ)', formula: 'I = (HP × 746) / (E × Eff × PF)', unit: 'Amps'), _Formula(name: 'Synchronous Speed', formula: 'RPM = (120 × f) / P', unit: 'RPM')]),
        _FormulaSection(title: 'TRANSFORMER', colors: colors, formulas: const [_Formula(name: 'Turns Ratio', formula: 'a = Np / Ns = Ep / Es', unit: ''), _Formula(name: 'kVA (1Φ)', formula: 'kVA = (E × I) / 1000', unit: 'kVA'), _Formula(name: 'kVA (3Φ)', formula: 'kVA = (√3 × E × I) / 1000', unit: 'kVA')]),
        _FormulaSection(title: 'USEFUL CONSTANTS', colors: colors, formulas: const [_Formula(name: '√3', formula: '1.732', unit: ''), _Formula(name: '1/√3', formula: '0.577', unit: ''), _Formula(name: 'π', formula: '3.1416', unit: '')]),
        const SizedBox(height: 16),
        _buildLegend(colors),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildLegend(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Variables', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 8, children: [_VarChip('E', 'Voltage', colors), _VarChip('I', 'Current', colors), _VarChip('R', 'Resistance', colors), _VarChip('P', 'Power', colors), _VarChip('PF', 'Power Factor', colors), _VarChip('D', 'Distance', colors), _VarChip('CM', 'Circ Mils', colors), _VarChip('f', 'Frequency', colors)]),
      ]),
    );
  }
}

class _Formula { final String name; final String formula; final String unit; const _Formula({required this.name, required this.formula, required this.unit}); }

class _FormulaSection extends StatelessWidget {
  final String title; final List<_Formula> formulas; final ZaftoColors colors;
  const _FormulaSection({required this.title, required this.formulas, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderDefault)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(13))), child: Text(title, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
        ...formulas.map((f) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderDefault.withValues(alpha: 0.5)))),
          child: Row(children: [Expanded(flex: 2, child: Text(f.name, style: TextStyle(color: colors.textSecondary, fontSize: 13))), Expanded(flex: 3, child: Text(f.formula, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary))), SizedBox(width: 60, child: Text(f.unit, style: TextStyle(color: colors.textTertiary, fontSize: 11), textAlign: TextAlign.right))]),
        )),
      ]),
    );
  }
}

class _VarChip extends StatelessWidget {
  final String symbol; final String meaning; final ZaftoColors colors;
  const _VarChip(this.symbol, this.meaning, this.colors);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text(symbol, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12))), const SizedBox(width: 4), Text(meaning, style: TextStyle(color: colors.textTertiary, fontSize: 11))]);
}
