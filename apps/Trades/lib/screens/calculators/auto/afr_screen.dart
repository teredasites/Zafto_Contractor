import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Air/Fuel Ratio Calculator - Stoichiometric and target AFR
class AfrScreen extends ConsumerStatefulWidget {
  const AfrScreen({super.key});
  @override
  ConsumerState<AfrScreen> createState() => _AfrScreenState();
}

class _AfrScreenState extends ConsumerState<AfrScreen> {
  final _afrController = TextEditingController();
  String _fuelType = 'gasoline';

  double? _lambda;
  String? _condition;

  static const Map<String, double> _stoich = {
    'gasoline': 14.7,
    'e85': 9.8,
    'methanol': 6.4,
    'diesel': 14.5,
  };

  void _calculate() {
    final afr = double.tryParse(_afrController.text);
    final stoich = _stoich[_fuelType]!;

    if (afr == null || afr <= 0) {
      setState(() { _lambda = null; });
      return;
    }

    final lambda = afr / stoich;
    String condition;
    if (lambda < 0.85) {
      condition = 'Very Rich - power/cold start enrichment';
    } else if (lambda < 0.95) {
      condition = 'Rich - WOT target for power';
    } else if (lambda < 1.05) {
      condition = 'Stoichiometric - balanced combustion';
    } else if (lambda < 1.10) {
      condition = 'Lean - cruise/economy';
    } else {
      condition = 'Very Lean - risk of detonation';
    }

    setState(() {
      _lambda = lambda;
      _condition = condition;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _afrController.clear();
    setState(() { _lambda = null; });
  }

  @override
  void dispose() {
    _afrController.dispose();
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
        title: Text('Air/Fuel Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildFuelSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Air/Fuel Ratio', unit: ':1', hint: 'Measured AFR', controller: _afrController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lambda != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFuelSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _stoich.keys.map((fuel) => ChoiceChip(
        label: Text(fuel.toUpperCase()),
        selected: _fuelType == fuel,
        onSelected: (_) => setState(() { _fuelType = fuel; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Lambda = AFR / Stoichiometric', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Stoich: Gas 14.7, E85 9.8, Methanol 6.4', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Lambda', _lambda!.toStringAsFixed(3), isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Stoich for ${_fuelType}', '${_stoich[_fuelType]}:1'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_condition!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
