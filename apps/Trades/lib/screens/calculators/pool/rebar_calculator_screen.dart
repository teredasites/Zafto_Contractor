import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Rebar Calculator
class RebarCalculatorScreen extends ConsumerStatefulWidget {
  const RebarCalculatorScreen({super.key});
  @override
  ConsumerState<RebarCalculatorScreen> createState() => _RebarCalculatorScreenState();
}

class _RebarCalculatorScreenState extends ConsumerState<RebarCalculatorScreen> {
  final _surfaceAreaController = TextEditingController();
  final _spacingController = TextEditingController(text: '12');
  String _rebarSize = '#3 (3/8")';

  double? _linearFeet;
  double? _pounds;
  String? _ties;

  // Rebar weight per foot
  static const Map<String, double> _rebarWeights = {
    '#3 (3/8")': 0.376,
    '#4 (1/2")': 0.668,
    '#5 (5/8")': 1.043,
  };

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);
    final spacing = double.tryParse(_spacingController.text);

    if (surfaceArea == null || spacing == null || surfaceArea <= 0 || spacing <= 0) {
      setState(() { _linearFeet = null; });
      return;
    }

    // Calculate linear feet of rebar for grid pattern
    // Assume roughly square pool for simplicity
    final side = surfaceArea / 2; // Approximate perimeter ÷ 2 for length/width average
    final barsPerDirection = (side * 12 / spacing).ceil();
    final linearFeetPerLayer = barsPerDirection * side * 2; // Both directions
    final totalLinearFeet = linearFeetPerLayer * 2; // Floor + walls (simplified)

    final weightPerFoot = _rebarWeights[_rebarSize] ?? 0.376;
    final pounds = totalLinearFeet * weightPerFoot;

    // Tie wire: approximately 1 tie per intersection
    final intersections = barsPerDirection * barsPerDirection;
    final tieWire = (intersections * 0.02).toStringAsFixed(1); // ~0.02 lbs per tie

    setState(() {
      _linearFeet = totalLinearFeet;
      _pounds = pounds;
      _ties = '$intersections ties (~$tieWire lbs wire)';
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    _spacingController.text = '12';
    setState(() { _linearFeet = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
    _spacingController.dispose();
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
        title: Text('Pool Rebar', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('REBAR SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'Pool shell surface', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Spacing', unit: 'in', hint: '12" typical', controller: _spacingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linearFeet != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _rebarWeights.keys.map((size) => ChoiceChip(
        label: Text(size, style: const TextStyle(fontSize: 11)),
        selected: _rebarSize == size,
        onSelected: (_) => setState(() { _rebarSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('#3 rebar @ 12" OC typical', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Grid pattern in floor and walls', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Linear Feet', '${_linearFeet!.toStringAsFixed(0)} lf', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Weight', '${_pounds!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tie Wire', _ties!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add 10% for overlaps and waste. Check local codes for requirements.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
