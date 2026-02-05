import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Overall Gear Ratio Calculator - Combined trans and diff ratio
class OverallGearRatioScreen extends ConsumerStatefulWidget {
  const OverallGearRatioScreen({super.key});
  @override
  ConsumerState<OverallGearRatioScreen> createState() => _OverallGearRatioScreenState();
}

class _OverallGearRatioScreenState extends ConsumerState<OverallGearRatioScreen> {
  final _transRatioController = TextEditingController();
  final _diffRatioController = TextEditingController();
  final _transferCaseController = TextEditingController(text: '1.0');

  double? _overallRatio;

  void _calculate() {
    final transRatio = double.tryParse(_transRatioController.text);
    final diffRatio = double.tryParse(_diffRatioController.text);
    final transferCase = double.tryParse(_transferCaseController.text) ?? 1.0;

    if (transRatio == null || diffRatio == null) {
      setState(() { _overallRatio = null; });
      return;
    }

    setState(() {
      _overallRatio = transRatio * diffRatio * transferCase;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _transRatioController.clear();
    _diffRatioController.clear();
    _transferCaseController.text = '1.0';
    setState(() { _overallRatio = null; });
  }

  @override
  void dispose() {
    _transRatioController.dispose();
    _diffRatioController.dispose();
    _transferCaseController.dispose();
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
        title: Text('Overall Gear Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Transmission Ratio', unit: ':1', hint: '1st gear ratio', controller: _transRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Differential Ratio', unit: ':1', hint: 'Final drive', controller: _diffRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Transfer Case (4WD)', unit: ':1', hint: '1.0 if N/A', controller: _transferCaseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_overallRatio != null) _buildResultsCard(colors),
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
        Text('Overall = Trans × Diff × T-Case', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Total mechanical advantage at each gear', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_overallRatio! > 15) {
      analysis = 'Crawler ratio - extreme low-speed torque for off-road';
    } else if (_overallRatio! > 10) {
      analysis = 'Aggressive launch ratio - good for heavy loads or racing';
    } else if (_overallRatio! > 6) {
      analysis = 'Typical 1st gear ratio - balanced acceleration';
    } else {
      analysis = 'Highway cruising ratio - fuel economy focus';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Overall Ratio', '${_overallRatio!.toStringAsFixed(2)}:1', isPrimary: true),
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
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
