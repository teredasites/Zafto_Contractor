import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Catalytic Converter Sizing Calculator
class CatConverterScreen extends ConsumerStatefulWidget {
  const CatConverterScreen({super.key});
  @override
  ConsumerState<CatConverterScreen> createState() => _CatConverterScreenState();
}

class _CatConverterScreenState extends ConsumerState<CatConverterScreen> {
  final _displacementController = TextEditingController();
  final _hpController = TextEditingController();
  final _exhaustDiameterController = TextEditingController(text: '2.5');

  double? _minVolume;
  double? _recommendedVolume;
  String? _catType;
  String? _flowRating;

  void _calculate() {
    final displacement = double.tryParse(_displacementController.text);
    final hp = double.tryParse(_hpController.text);
    final exhaustD = double.tryParse(_exhaustDiameterController.text);

    if (displacement == null || hp == null || exhaustD == null) {
      setState(() { _minVolume = null; });
      return;
    }

    // Convert liters to cubic inches if under 10 (assume liters)
    final dispCi = displacement < 10 ? displacement * 61.024 : displacement;

    // Minimum substrate volume: 1.0-1.5x engine displacement
    final minVol = dispCi * 1.0;
    final recVol = dispCi * 1.25;

    // Determine cat type based on HP
    String type;
    String flow;
    if (hp < 300) {
      type = 'Standard OEM-style converter';
      flow = '${(hp * 2.5).toStringAsFixed(0)} CFM minimum';
    } else if (hp < 450) {
      type = 'High-flow metallic substrate cat';
      flow = '${(hp * 2.5).toStringAsFixed(0)} CFM minimum';
    } else if (hp < 650) {
      type = 'Racing high-flow cat (200 cell)';
      flow = '${(hp * 2.5).toStringAsFixed(0)} CFM minimum';
    } else {
      type = 'Ultra high-flow or cat delete (race only)';
      flow = '${(hp * 2.5).toStringAsFixed(0)}+ CFM required';
    }

    setState(() {
      _minVolume = minVol;
      _recommendedVolume = recVol;
      _catType = type;
      _flowRating = flow;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _hpController.clear();
    _exhaustDiameterController.text = '2.5';
    setState(() { _minVolume = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
    _hpController.dispose();
    _exhaustDiameterController.dispose();
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
        title: Text('Catalytic Converter Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Displacement', unit: 'L or ci', hint: 'Liters or cubic inches', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Horsepower', unit: 'HP', hint: 'Expected HP output', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Exhaust Pipe Diameter', unit: 'in', hint: 'Inlet/outlet size', controller: _exhaustDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minVolume != null) _buildResultsCard(colors),
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
        Text('Volume = Displacement x 1.0-1.5', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Substrate volume should match or exceed engine displacement', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Minimum Volume', '${_minVolume!.toStringAsFixed(0)} ci', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended Volume', '${_recommendedVolume!.toStringAsFixed(0)} ci'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Rating', _flowRating!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_catType!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Cell count: 100 (race) to 400 (emissions)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Note: Cat delete is illegal for street use. High-flow cats are 49-state legal.', style: TextStyle(color: colors.accentWarning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
