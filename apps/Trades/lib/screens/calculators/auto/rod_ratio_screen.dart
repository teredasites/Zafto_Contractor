import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rod Ratio Calculator - Rod length / Stroke analysis
class RodRatioScreen extends ConsumerStatefulWidget {
  const RodRatioScreen({super.key});
  @override
  ConsumerState<RodRatioScreen> createState() => _RodRatioScreenState();
}

class _RodRatioScreenState extends ConsumerState<RodRatioScreen> {
  final _rodLengthController = TextEditingController();
  final _strokeController = TextEditingController();

  double? _rodRatio;
  String? _analysis;

  void _calculate() {
    final rod = double.tryParse(_rodLengthController.text);
    final stroke = double.tryParse(_strokeController.text);

    if (rod == null || stroke == null || stroke <= 0) {
      setState(() { _rodRatio = null; _analysis = null; });
      return;
    }

    final ratio = rod / stroke;
    String analysis;
    if (ratio < 1.5) {
      analysis = 'Short rod - more piston thrust, quicker dwell at TDC';
    } else if (ratio < 1.7) {
      analysis = 'Moderate ratio - balanced performance';
    } else if (ratio < 1.9) {
      analysis = 'Long rod - less thrust, longer dwell, better for NA';
    } else {
      analysis = 'Very long rod - reduced friction, high RPM friendly';
    }

    setState(() {
      _rodRatio = ratio;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _rodLengthController.clear();
    _strokeController.clear();
    setState(() { _rodRatio = null; _analysis = null; });
  }

  @override
  void dispose() {
    _rodLengthController.dispose();
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
        title: Text('Rod Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Rod Length', unit: 'in', hint: 'Center to center', controller: _rodLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Crankshaft stroke', controller: _strokeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rodRatio != null) _buildResultsCard(colors),
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
        Text('Rod Ratio = Rod Length / Stroke', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Affects piston dwell time and side thrust', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Rod Ratio', '${_rodRatio!.toStringAsFixed(3)}:1', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
