import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fillet Weld Size Calculator - Leg size from material thickness
class FilletWeldSizeScreen extends ConsumerStatefulWidget {
  const FilletWeldSizeScreen({super.key});
  @override
  ConsumerState<FilletWeldSizeScreen> createState() => _FilletWeldSizeScreenState();
}

class _FilletWeldSizeScreenState extends ConsumerState<FilletWeldSizeScreen> {
  final _thicknessController = TextEditingController();
  bool _isFullStrength = true;

  double? _minLegSize;
  double? _maxLegSize;
  double? _throatSize;
  String? _codeMin;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    if (thickness == null || thickness <= 0) {
      setState(() { _minLegSize = null; });
      return;
    }

    // AWS D1.1 minimum fillet weld sizes
    String codeMin;
    double minLeg;
    if (thickness <= 0.25) {
      minLeg = 0.125; codeMin = '1/8" (3mm)';
    } else if (thickness <= 0.5) {
      minLeg = 0.1875; codeMin = '3/16" (5mm)';
    } else if (thickness <= 0.75) {
      minLeg = 0.25; codeMin = '1/4" (6mm)';
    } else if (thickness <= 1.5) {
      minLeg = 0.3125; codeMin = '5/16" (8mm)';
    } else if (thickness <= 2.25) {
      minLeg = 0.375; codeMin = '3/8" (10mm)';
    } else if (thickness <= 6) {
      minLeg = 0.5; codeMin = '1/2" (12mm)';
    } else {
      minLeg = 0.625; codeMin = '5/8" (16mm)';
    }

    // Max practical size = thickness of thinner member
    final maxLeg = thickness;
    // Throat = leg × 0.707 (for equal leg fillet)
    final throat = (_isFullStrength ? maxLeg : minLeg) * 0.707;

    setState(() {
      _minLegSize = minLeg;
      _maxLegSize = maxLeg;
      _throatSize = throat;
      _codeMin = codeMin;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _minLegSize = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('Fillet Weld Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Thinner Material', unit: 'in', hint: 'Base metal thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildToggle(colors),
            const SizedBox(height: 32),
            if (_minLegSize != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: Text('Full Strength'), selected: _isFullStrength, onSelected: (_) => setState(() { _isFullStrength = true; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: Text('Minimum'), selected: !_isFullStrength, onSelected: (_) => setState(() { _isFullStrength = false; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Throat = Leg × 0.707', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Per AWS D1.1 minimum fillet weld sizes', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'AWS Minimum', _codeMin!, isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Leg Size', '${_minLegSize!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Leg Size', '${_maxLegSize!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Effective Throat', '${_throatSize!.toStringAsFixed(3)}"'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
