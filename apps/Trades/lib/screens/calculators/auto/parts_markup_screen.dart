import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Parts Markup Calculator - Calculate retail pricing
class PartsMarkupScreen extends ConsumerStatefulWidget {
  const PartsMarkupScreen({super.key});
  @override
  ConsumerState<PartsMarkupScreen> createState() => _PartsMarkupScreenState();
}

class _PartsMarkupScreenState extends ConsumerState<PartsMarkupScreen> {
  final _costController = TextEditingController();
  final _markupController = TextEditingController(text: '40');

  double? _retailPrice;
  double? _profit;

  void _calculate() {
    final cost = double.tryParse(_costController.text);
    final markupPercent = double.tryParse(_markupController.text) ?? 40;

    if (cost == null) {
      setState(() { _retailPrice = null; });
      return;
    }

    final retail = cost * (1 + markupPercent / 100);
    final profit = retail - cost;

    setState(() {
      _retailPrice = retail;
      _profit = profit;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _costController.clear();
    _markupController.text = '40';
    setState(() { _retailPrice = null; });
  }

  @override
  void dispose() {
    _costController.dispose();
    _markupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Parts Markup', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Part Cost', unit: '\$', hint: 'Your cost', controller: _costController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Markup', unit: '%', hint: 'Typical 30-50%', controller: _markupController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_retailPrice != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildMarkupGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Retail = Cost × (1 + Markup%)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate customer pricing for parts', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RETAIL PRICE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('\$${_retailPrice!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Your Cost', '\$${double.parse(_costController.text).toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Profit', '\$${_profit!.toStringAsFixed(2)}'),
      ]),
    );
  }

  Widget _buildMarkupGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL MARKUPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildMarkupRow(colors, 'OEM parts', '30-40%'),
        _buildMarkupRow(colors, 'Aftermarket quality', '40-50%'),
        _buildMarkupRow(colors, 'Economy parts', '50-70%'),
        _buildMarkupRow(colors, 'Special order', '25-35%'),
        _buildMarkupRow(colors, 'Fluids/filters', '50-100%'),
        const SizedBox(height: 12),
        Text('Markup varies by shop policy, part type, and competition.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildMarkupRow(ZaftoColors colors, String category, String markup) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(category, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(markup, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
