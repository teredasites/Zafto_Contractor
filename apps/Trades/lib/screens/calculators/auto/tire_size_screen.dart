import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tire Size Calculator - Decode tire dimensions from size code
class TireSizeScreen extends ConsumerStatefulWidget {
  const TireSizeScreen({super.key});
  @override
  ConsumerState<TireSizeScreen> createState() => _TireSizeScreenState();
}

class _TireSizeScreenState extends ConsumerState<TireSizeScreen> {
  final _widthController = TextEditingController();
  final _aspectController = TextEditingController();
  final _wheelController = TextEditingController();

  double? _diameter;
  double? _sidewall;
  double? _circumference;
  double? _revsPerMile;

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final aspect = double.tryParse(_aspectController.text);
    final wheel = double.tryParse(_wheelController.text);

    if (width == null || aspect == null || wheel == null) {
      setState(() { _diameter = null; });
      return;
    }

    // Sidewall height in inches = (width mm × aspect%) / 25.4
    final sidewallMm = width * (aspect / 100);
    final sidewallIn = sidewallMm / 25.4;

    // Total diameter = wheel + (2 × sidewall)
    final diameter = wheel + (2 * sidewallIn);
    final circumference = diameter * 3.14159;
    final revsPerMile = 63360 / circumference;

    setState(() {
      _sidewall = sidewallIn;
      _diameter = diameter;
      _circumference = circumference;
      _revsPerMile = revsPerMile;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.clear();
    _aspectController.clear();
    _wheelController.clear();
    setState(() { _diameter = null; });
  }

  @override
  void dispose() {
    _widthController.dispose();
    _aspectController.dispose();
    _wheelController.dispose();
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
        title: Text('Tire Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Width', unit: 'mm', hint: 'e.g. 275', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Aspect Ratio', unit: '%', hint: 'e.g. 40', controller: _aspectController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Diameter', unit: 'in', hint: 'e.g. 18', controller: _wheelController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_diameter != null) _buildResultsCard(colors),
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
        Text('Example: 275/40R18', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Width (mm) / Aspect (%) R Wheel (in)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Overall Diameter', '${_diameter!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Sidewall Height', '${_sidewall!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Circumference', '${_circumference!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Revs Per Mile', '${_revsPerMile!.toStringAsFixed(0)}'),
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
