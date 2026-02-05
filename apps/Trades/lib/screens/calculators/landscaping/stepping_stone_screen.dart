import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stepping Stone Calculator - Stones for pathway
class SteppingStoneScreen extends ConsumerStatefulWidget {
  const SteppingStoneScreen({super.key});
  @override
  ConsumerState<SteppingStoneScreen> createState() => _SteppingStoneScreenState();
}

class _SteppingStoneScreenState extends ConsumerState<SteppingStoneScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _spacingController = TextEditingController(text: '6');

  String _stoneSize = '18';

  int? _stonesNeeded;
  double? _sandBags;

  @override
  void dispose() { _lengthController.dispose(); _spacingController.dispose(); super.dispose(); }

  void _calculate() {
    final pathLength = double.tryParse(_lengthController.text) ?? 30;
    final spacingIn = double.tryParse(_spacingController.text) ?? 6;
    final stoneSizeIn = double.tryParse(_stoneSize) ?? 18;

    // Convert to feet
    final stoneSizeFt = stoneSizeIn / 12;
    final spacingFt = spacingIn / 12;

    // Stones needed
    final strideLength = stoneSizeFt + spacingFt;
    final stones = (pathLength / strideLength).ceil();

    // Sand: 2" bed per stone (50 lb bags cover ~0.5 sq ft at 2")
    final stoneSqFt = 3.14159 * (stoneSizeFt / 2) * (stoneSizeFt / 2);
    final totalSqFt = stoneSqFt * stones;
    final sandBags = totalSqFt / 0.5;

    setState(() {
      _stonesNeeded = stones;
      _sandBags = sandBags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _spacingController.text = '6'; setState(() { _stoneSize = '18'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stepping Stones', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STONE SIZE', ['12', '16', '18', '24'], _stoneSize, {'12': '12"', '16': '16"', '18': '18"', '24': '24"'}, (v) { setState(() => _stoneSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Path Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Spacing Between', unit: 'in', controller: _spacingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Typical stride: 24-30" center to center. Adjust spacing for comfort.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_stonesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STONES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stonesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sand bags (50 lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandBags!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stone size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stoneSize" diameter', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1. Layout', 'Walk path naturally'),
        _buildTableRow(colors, '2. Excavate', 'Stone thickness + 2"'),
        _buildTableRow(colors, '3. Sand bed', '2" leveling sand'),
        _buildTableRow(colors, '4. Set stone', '1/2" above grade'),
        _buildTableRow(colors, '5. Tamp', 'Rubber mallet'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
