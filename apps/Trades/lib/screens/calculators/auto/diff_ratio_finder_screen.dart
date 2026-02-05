import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Differential Ratio Finder - Determine unknown diff ratio
class DiffRatioFinderScreen extends ConsumerStatefulWidget {
  const DiffRatioFinderScreen({super.key});
  @override
  ConsumerState<DiffRatioFinderScreen> createState() => _DiffRatioFinderScreenState();
}

class _DiffRatioFinderScreenState extends ConsumerState<DiffRatioFinderScreen> {
  final _driveshaftRevsController = TextEditingController();
  final _wheelRevsController = TextEditingController(text: '1');

  double? _diffRatio;

  void _calculate() {
    final driveshaftRevs = double.tryParse(_driveshaftRevsController.text);
    final wheelRevs = double.tryParse(_wheelRevsController.text);

    if (driveshaftRevs == null || wheelRevs == null || wheelRevs <= 0) {
      setState(() { _diffRatio = null; });
      return;
    }

    setState(() {
      _diffRatio = driveshaftRevs / wheelRevs;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _driveshaftRevsController.clear();
    _wheelRevsController.text = '1';
    setState(() { _diffRatio = null; });
  }

  @override
  void dispose() {
    _driveshaftRevsController.dispose();
    _wheelRevsController.dispose();
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
        title: Text('Diff Ratio Finder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Driveshaft Revolutions', unit: 'turns', hint: 'Count rotations', controller: _driveshaftRevsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Revolutions', unit: 'turns', hint: 'Usually 1', controller: _wheelRevsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_diffRatio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildInstructionsCard(colors),
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
        Text('Ratio = Driveshaft Turns / Wheel Turns', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Determine gear ratio without disassembly', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String? matchedRatio;
    final common = [2.73, 3.08, 3.23, 3.42, 3.55, 3.73, 3.90, 4.10, 4.30, 4.56, 4.88, 5.13];
    for (final ratio in common) {
      if ((_diffRatio! - ratio).abs() < 0.05) {
        matchedRatio = '${ratio.toStringAsFixed(2)}:1';
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Measured Ratio', '${_diffRatio!.toStringAsFixed(2)}:1', isPrimary: true),
        if (matchedRatio != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Likely Ratio', matchedRatio),
        ],
      ]),
    );
  }

  Widget _buildInstructionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HOW TO MEASURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Jack up rear axle (both wheels off ground)\n2. Put transmission in neutral\n3. Mark driveshaft and wheel\n4. Rotate wheel exactly one turn\n5. Count driveshaft rotations\n\nFor accuracy, rotate wheel 2+ turns and divide.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
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
