import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landscape Stair Calculator - Steps for slopes
class StairStepScreen extends ConsumerStatefulWidget {
  const StairStepScreen({super.key});
  @override
  ConsumerState<StairStepScreen> createState() => _StairStepScreenState();
}

class _StairStepScreenState extends ConsumerState<StairStepScreen> {
  final _riseController = TextEditingController(text: '36');
  final _stepRiseController = TextEditingController(text: '6');

  String _material = 'block';

  int? _stepsNeeded;
  double? _runLength;
  int? _blocksPerStep;
  int? _totalBlocks;

  @override
  void dispose() { _riseController.dispose(); _stepRiseController.dispose(); super.dispose(); }

  void _calculate() {
    final totalRise = double.tryParse(_riseController.text) ?? 36;
    final stepRise = double.tryParse(_stepRiseController.text) ?? 6;

    if (stepRise <= 0) {
      setState(() { _stepsNeeded = null; });
      return;
    }

    final steps = (totalRise / stepRise).ceil();

    // Ideal outdoor step: 6" rise, 14-16" tread
    // Run formula: 2×Rise + Tread = 26"
    final idealTread = 26 - (2 * stepRise);
    final treadUsed = idealTread.clamp(12.0, 18.0);
    final runLength = (steps * treadUsed) / 12; // Convert to feet

    // Blocks per step based on material
    int blocksPerStep;
    switch (_material) {
      case 'block': // Standard wall block (12" wide)
        blocksPerStep = 3; // Assuming 36" wide steps
        break;
      case 'paver': // Pavers for tread
        blocksPerStep = 6; // 6 pavers across
        break;
      case 'natural': // Natural stone
        blocksPerStep = 2; // Larger stones
        break;
      default:
        blocksPerStep = 3;
    }

    final totalBlocks = steps * blocksPerStep;

    setState(() {
      _stepsNeeded = steps;
      _runLength = runLength;
      _blocksPerStep = blocksPerStep;
      _totalBlocks = totalBlocks;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '36'; _stepRiseController.text = '6'; setState(() { _material = 'block'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landscape Steps', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['block', 'paver', 'natural'], _material, {'block': 'Wall Block', 'paver': 'Pavers', 'natural': 'Natural Stone'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Step Rise', unit: 'inches', controller: _stepRiseController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Outdoor ideal: 5-7" rise, 14-16" tread. Formula: 2×Rise + Tread = 26"', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_stepsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STEPS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stepsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total run length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_runLength!.toStringAsFixed(1)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Blocks/pavers per step', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksPerStep', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total materials', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalBlocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStepGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStepGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STEP DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Outdoor rise', '5-7" (6" ideal)'),
        _buildTableRow(colors, 'Outdoor tread', '14-16"'),
        _buildTableRow(colors, 'Min width', "36\" (48\" better)"),
        _buildTableRow(colors, 'Landing', 'Every 5-6 steps'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
