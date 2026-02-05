import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bore/Stroke Ratio Calculator - Engine character analysis
class BoreStrokeRatioScreen extends ConsumerStatefulWidget {
  const BoreStrokeRatioScreen({super.key});
  @override
  ConsumerState<BoreStrokeRatioScreen> createState() => _BoreStrokeRatioScreenState();
}

class _BoreStrokeRatioScreenState extends ConsumerState<BoreStrokeRatioScreen> {
  final _boreController = TextEditingController();
  final _strokeController = TextEditingController();

  double? _ratio;
  String? _engineType;

  void _calculate() {
    final bore = double.tryParse(_boreController.text);
    final stroke = double.tryParse(_strokeController.text);

    if (bore == null || stroke == null || stroke <= 0) {
      setState(() { _ratio = null; });
      return;
    }

    final ratio = bore / stroke;
    String type;
    if (ratio < 0.95) {
      type = 'Undersquare (Long Stroke)';
    } else if (ratio <= 1.05) {
      type = 'Square';
    } else {
      type = 'Oversquare (Short Stroke)';
    }

    setState(() {
      _ratio = ratio;
      _engineType = type;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boreController.clear();
    _strokeController.clear();
    setState(() { _ratio = null; });
  }

  @override
  void dispose() {
    _boreController.dispose();
    _strokeController.dispose();
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
        title: Text('Bore/Stroke Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Bore', unit: 'in', hint: 'Cylinder diameter', controller: _boreController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Piston travel', controller: _strokeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_ratio != null) _buildResultsCard(colors),
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
        Text('Ratio = Bore / Stroke', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Determines engine breathing vs torque characteristics', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_ratio! < 0.95) {
      analysis = 'Better low-end torque, lower piston speeds, diesel-like. Good for towing/economy.';
    } else if (_ratio! <= 1.05) {
      analysis = 'Balanced performance. Good compromise between torque and RPM capability.';
    } else {
      analysis = 'Higher RPM potential, larger valves possible, race-oriented. Better breathing.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Bore/Stroke Ratio', _ratio!.toStringAsFixed(3), isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Engine Type', _engineType!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
