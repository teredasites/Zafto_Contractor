import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Exhaust Pipe Size Calculator - Pipe diameter for HP
class ExhaustPipeSizeScreen extends ConsumerStatefulWidget {
  const ExhaustPipeSizeScreen({super.key});
  @override
  ConsumerState<ExhaustPipeSizeScreen> createState() => _ExhaustPipeSizeScreenState();
}

class _ExhaustPipeSizeScreenState extends ConsumerState<ExhaustPipeSizeScreen> {
  final _hpController = TextEditingController();
  final _cylindersController = TextEditingController(text: '8');

  double? _pipeDiameter;
  double? _pipeArea;
  String? _recommendation;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final cylinders = double.tryParse(_cylindersController.text);

    if (hp == null || cylinders == null || cylinders <= 0) {
      setState(() { _pipeDiameter = null; });
      return;
    }

    // Formula: Diameter = sqrt(HP / 13.5) for single exhaust
    // For dual exhaust (V6/V8), each pipe handles half
    final isDual = cylinders >= 6;
    final effectiveHp = isDual ? hp / 2 : hp;
    final diameter = _sqrt(effectiveHp / 13.5);
    final area = 3.14159 * (diameter / 2) * (diameter / 2);

    String rec;
    if (hp < 200) {
      rec = isDual ? '2.0" dual recommended' : '2.25" single recommended';
    } else if (hp < 350) {
      rec = isDual ? '2.25" dual recommended' : '2.5" single recommended';
    } else if (hp < 500) {
      rec = isDual ? '2.5" dual recommended' : '3.0" single recommended';
    } else if (hp < 700) {
      rec = isDual ? '3.0" dual recommended' : '3.5" single recommended';
    } else {
      rec = isDual ? '3.5"+ dual or true dual' : '4.0"+ single recommended';
    }

    setState(() {
      _pipeDiameter = diameter;
      _pipeArea = area;
      _recommendation = rec;
    });
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _cylindersController.text = '8';
    setState(() { _pipeDiameter = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _cylindersController.dispose();
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
        title: Text('Exhaust Pipe Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'HP', hint: 'Crank HP', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Cylinders', unit: 'cyl', hint: '4, 6, 8, etc.', controller: _cylindersController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pipeDiameter != null) _buildResultsCard(colors),
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
        Text('D = sqrt(HP / 13.5)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Minimum pipe diameter to support HP target', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final cylinders = int.tryParse(_cylindersController.text) ?? 8;
    final isDual = cylinders >= 6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Minimum Pipe Diameter', '${_pipeDiameter!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cross-Sectional Area', '${_pipeArea!.toStringAsFixed(2)} sq in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Exhaust Type', isDual ? 'Dual Exhaust' : 'Single Exhaust'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
