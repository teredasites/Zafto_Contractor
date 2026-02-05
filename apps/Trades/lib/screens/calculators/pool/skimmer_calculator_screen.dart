import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Skimmer Calculator
class SkimmerCalculatorScreen extends ConsumerStatefulWidget {
  const SkimmerCalculatorScreen({super.key});
  @override
  ConsumerState<SkimmerCalculatorScreen> createState() => _SkimmerCalculatorScreenState();
}

class _SkimmerCalculatorScreenState extends ConsumerState<SkimmerCalculatorScreen> {
  final _surfaceAreaController = TextEditingController();
  bool _hasWaterFeature = false;

  int? _skimmersNeeded;
  String? _placement;

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);

    if (surfaceArea == null || surfaceArea <= 0) {
      setState(() { _skimmersNeeded = null; });
      return;
    }

    // Rule: 1 skimmer per 400-500 sq ft of surface area
    // Water features add debris, so use 400 sq ft
    final sqFtPerSkimmer = _hasWaterFeature ? 400 : 500;
    int skimmers = (surfaceArea / sqFtPerSkimmer).ceil();
    if (skimmers < 1) skimmers = 1;

    String placement;
    if (skimmers == 1) {
      placement = 'Place on downwind side of pool';
    } else if (skimmers == 2) {
      placement = 'Place on opposite ends, downwind side';
    } else {
      placement = 'Distribute evenly around perimeter';
    }

    setState(() {
      _skimmersNeeded = skimmers;
      _placement = placement;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    setState(() { _skimmersNeeded = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
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
        title: Text('Skimmer Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'L × W', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildFeatureToggle(colors),
            const SizedBox(height: 32),
            if (_skimmersNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFeatureToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Standard Pool'), selected: !_hasWaterFeature, onSelected: (_) => setState(() { _hasWaterFeature = false; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Water Features'), selected: _hasWaterFeature, onSelected: (_) => setState(() { _hasWaterFeature = true; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('1 Skimmer per 400-500 sq ft', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Position on downwind side for best debris capture', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Skimmers Needed', '$_skimmersNeeded', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_placement!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 32 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
