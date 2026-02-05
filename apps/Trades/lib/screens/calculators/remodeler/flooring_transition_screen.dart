import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flooring Transition Calculator - Transition strip estimation
class FlooringTransitionScreen extends ConsumerStatefulWidget {
  const FlooringTransitionScreen({super.key});
  @override
  ConsumerState<FlooringTransitionScreen> createState() => _FlooringTransitionScreenState();
}

class _FlooringTransitionScreenState extends ConsumerState<FlooringTransitionScreen> {
  final _doorsController = TextEditingController(text: '5');
  final _doorWidthController = TextEditingController(text: '36');
  final _openingsController = TextEditingController(text: '2');

  String _type = 'tbar';

  double? _totalLF;
  int? _strips36;
  int? _strips72;

  @override
  void dispose() { _doorsController.dispose(); _doorWidthController.dispose(); _openingsController.dispose(); super.dispose(); }

  void _calculate() {
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final doorWidth = double.tryParse(_doorWidthController.text) ?? 36;
    final openings = int.tryParse(_openingsController.text) ?? 0;

    final doorWidthFt = doorWidth / 12;

    // Door transitions
    final doorLF = doors * doorWidthFt;

    // Open floor transitions (typically 3-4' spans)
    final openingLF = openings * 3.5;

    final totalLF = doorLF + openingLF;

    // Strips come in 36" and 72" lengths
    final strips36 = (totalLF / 3).ceil();
    final strips72 = (totalLF / 6).ceil();

    setState(() { _totalLF = totalLF; _strips36 = strips36; _strips72 = strips72; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _doorsController.text = '5'; _doorWidthController.text = '36'; _openingsController.text = '2'; setState(() => _type = 'tbar'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Flooring Transition', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Door Transitions', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Width', unit: 'inches', controller: _doorWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Open Spans', unit: 'qty', controller: _openingsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalLF != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('36\" Strips', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_strips36', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('72\" Strips (alt)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_strips72', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Match transition type to height difference. T-bar for same height, reducer for different.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['tbar', 'reducer', 'endcap', 'stair'];
    final labels = {'tbar': 'T-Bar', 'reducer': 'Reducer', 'endcap': 'End Cap', 'stair': 'Stair Nose'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TRANSITION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRANSITION USES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'T-Bar / T-Mold', 'Same height floors'),
        _buildTableRow(colors, 'Reducer', 'High to low floor'),
        _buildTableRow(colors, 'End Cap', 'Floor to wall/door'),
        _buildTableRow(colors, 'Stair Nose', 'Stair treads'),
        _buildTableRow(colors, 'Carpet Reducer', 'Hard floor to carpet'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
