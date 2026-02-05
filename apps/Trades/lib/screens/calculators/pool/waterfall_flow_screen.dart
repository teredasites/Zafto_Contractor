import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Waterfall Flow Rate Calculator
class WaterfallFlowScreen extends ConsumerStatefulWidget {
  const WaterfallFlowScreen({super.key});
  @override
  ConsumerState<WaterfallFlowScreen> createState() => _WaterfallFlowScreenState();
}

class _WaterfallFlowScreenState extends ConsumerState<WaterfallFlowScreen> {
  final _widthController = TextEditingController();
  String _flowType = 'Sheet';

  double? _gpmRequired;
  double? _pumpHp;
  String? _recommendation;

  // GPM per inch of width by flow type
  static const Map<String, double> _flowFactors = {
    'Sheet': 1.5, // Thin sheet flow
    'Moderate': 2.5, // Nice visible flow
    'Heavy': 4.0, // Dramatic flow
  };

  void _calculate() {
    final width = double.tryParse(_widthController.text);

    if (width == null || width <= 0) {
      setState(() { _gpmRequired = null; });
      return;
    }

    final factor = _flowFactors[_flowType] ?? 2.5;
    final gpm = width * factor;

    // Rough pump sizing (assumes ~20 ft head)
    double hp;
    String recommendation;
    if (gpm <= 40) {
      hp = 0.5;
      recommendation = '1/2 HP dedicated pump';
    } else if (gpm <= 60) {
      hp = 0.75;
      recommendation = '3/4 HP dedicated pump';
    } else if (gpm <= 80) {
      hp = 1.0;
      recommendation = '1 HP dedicated pump';
    } else if (gpm <= 120) {
      hp = 1.5;
      recommendation = '1.5 HP dedicated pump';
    } else {
      hp = 2.0;
      recommendation = '2+ HP or multiple pumps';
    }

    setState(() {
      _gpmRequired = gpm;
      _pumpHp = hp;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.clear();
    setState(() { _gpmRequired = null; });
  }

  @override
  void dispose() {
    _widthController.dispose();
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
        title: Text('Waterfall Flow', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FLOW TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Waterfall Width', unit: 'in', hint: 'Width of spillway', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpmRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _flowFactors.keys.map((type) => ChoiceChip(
        label: Text(type),
        selected: _flowType == type,
        onSelected: (_) => setState(() { _flowType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('GPM = Width × Flow Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Sheet: 1.5, Moderate: 2.5, Heavy: 4 GPM/inch', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Required', '${_gpmRequired!.toStringAsFixed(0)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Pump Size', '${_pumpHp!.toStringAsFixed(1)} HP'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
