import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// E85 Fuel Calculator - Ethanol content and fuel requirements
class E85FuelScreen extends ConsumerStatefulWidget {
  const E85FuelScreen({super.key});
  @override
  ConsumerState<E85FuelScreen> createState() => _E85FuelScreenState();
}

class _E85FuelScreenState extends ConsumerState<E85FuelScreen> {
  final _currentInjectorController = TextEditingController();
  final _ethanolContentController = TextEditingController(text: '85');

  double? _requiredInjector;
  double? _fuelIncrease;

  void _calculate() {
    final currentInjector = double.tryParse(_currentInjectorController.text);
    final ethanolContent = double.tryParse(_ethanolContentController.text) ?? 85;

    if (currentInjector == null) {
      setState(() { _requiredInjector = null; });
      return;
    }

    // E85 requires ~30% more fuel than gasoline (at E85)
    // Scale based on actual ethanol content
    final ethanolFraction = ethanolContent / 100;
    final fuelIncrease = ethanolFraction * 0.30; // 30% more at E85
    final required = currentInjector * (1 + fuelIncrease);

    setState(() {
      _fuelIncrease = fuelIncrease * 100;
      _requiredInjector = required;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentInjectorController.clear();
    _ethanolContentController.text = '85';
    setState(() { _requiredInjector = null; });
  }

  @override
  void dispose() {
    _currentInjectorController.dispose();
    _ethanolContentController.dispose();
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
        title: Text('E85 Fuel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Injector Size', unit: 'cc/min', hint: 'For gasoline tune', controller: _currentInjectorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ethanol Content', unit: '%', hint: 'E85 varies 51-83%', controller: _ethanolContentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredInjector != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildE85InfoCard(colors),
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
        Text('E85 requires ~30% more fuel', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Higher octane allows more timing/boost', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Fuel Increase', '${_fuelIncrease!.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Text('REQUIRED INJECTOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_requiredInjector!.toStringAsFixed(0)} cc/min', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Also verify fuel pump and line capacity support the increased flow.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildE85InfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('E85 FACTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildFactRow(colors, 'Octane', '100-105 equivalent'),
        _buildFactRow(colors, 'Stoich AFR', '9.8:1'),
        _buildFactRow(colors, 'Energy content', '~25% less than gasoline'),
        _buildFactRow(colors, 'Cooling effect', 'Higher latent heat'),
        _buildFactRow(colors, 'Seasonal variation', '51-83% ethanol'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Check compatibility! E85 attacks rubber/cork seals and some aluminum alloys.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildFactRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
