import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stair Carpet Calculator - Stair runner estimation
class StairCarpetScreen extends ConsumerStatefulWidget {
  const StairCarpetScreen({super.key});
  @override
  ConsumerState<StairCarpetScreen> createState() => _StairCarpetScreenState();
}

class _StairCarpetScreenState extends ConsumerState<StairCarpetScreen> {
  final _stepsController = TextEditingController(text: '13');
  final _widthController = TextEditingController(text: '36');
  final _treadController = TextEditingController(text: '10');
  final _riserController = TextEditingController(text: '7.5');

  String _style = 'runner';

  double? _totalSqft;
  double? _runnerLF;
  double? _padSqft;
  int? _grippers;

  @override
  void dispose() { _stepsController.dispose(); _widthController.dispose(); _treadController.dispose(); _riserController.dispose(); super.dispose(); }

  void _calculate() {
    final steps = int.tryParse(_stepsController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 36;
    final tread = double.tryParse(_treadController.text) ?? 10;
    final riser = double.tryParse(_riserController.text) ?? 7.5;

    final widthFt = width / 12;
    final treadFt = tread / 12;
    final riserFt = riser / 12;

    // Each step: tread + riser + 1" wrap
    final stepLength = treadFt + riserFt + (1 / 12);
    final totalLength = stepLength * steps;

    // Runner width (typically 27" or 32")
    double runnerWidth;
    if (_style == 'runner') {
      runnerWidth = 27 / 12; // 27" runner standard
    } else {
      runnerWidth = widthFt; // Wall-to-wall
    }

    final totalSqft = totalLength * runnerWidth;
    final runnerLF = totalLength;

    // Pad for each step
    final padSqft = steps * (treadFt * runnerWidth);

    // Gripper strips: 2 per step
    final grippers = steps * 2;

    setState(() { _totalSqft = totalSqft; _runnerLF = runnerLF; _padSqft = padSqft; _grippers = grippers; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _stepsController.text = '13'; _widthController.text = '36'; _treadController.text = '10'; _riserController.text = '7.5'; setState(() => _style = 'runner'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stair Carpet', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Number of Steps', unit: 'qty', controller: _stepsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stair Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Tread Depth', unit: 'inches', controller: _treadController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Riser Height', unit: 'inches', controller: _riserController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CARPET NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Runner Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_runnerLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pad Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_padSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gripper Strips', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_grippers pcs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard runners are 27\" or 32\" wide. Use low-pile for stairs. Hollywood wrap shows tread edge.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['runner', 'wall'];
    final labels = {'runner': 'Runner', 'wall': 'Wall-to-Wall'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _style == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _style = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION METHODS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Waterfall', 'Over nose, straight down'),
        _buildTableRow(colors, 'Hollywood', 'Wraps under tread'),
        _buildTableRow(colors, 'Cap & band', 'Separate tread pieces'),
        _buildTableRow(colors, 'Runner', 'Centered, wood showing'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
