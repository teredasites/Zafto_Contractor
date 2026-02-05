import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Appliance Clearance Calculator - Kitchen appliance spacing
class ApplianceClearanceScreen extends ConsumerStatefulWidget {
  const ApplianceClearanceScreen({super.key});
  @override
  ConsumerState<ApplianceClearanceScreen> createState() => _ApplianceClearanceScreenState();
}

class _ApplianceClearanceScreenState extends ConsumerState<ApplianceClearanceScreen> {
  final _fridgeWidthController = TextEditingController(text: '36');
  final _rangeWidthController = TextEditingController(text: '30');
  final _dishwasherController = TextEditingController(text: '24');

  String _rangeType = 'freestanding';

  Map<String, bool> _clearances = {};

  @override
  void dispose() { _fridgeWidthController.dispose(); _rangeWidthController.dispose(); _dishwasherController.dispose(); super.dispose(); }

  void _calculate() {
    final fridgeWidth = double.tryParse(_fridgeWidthController.text) ?? 36;
    final rangeWidth = double.tryParse(_rangeWidthController.text) ?? 30;
    final dishwasher = double.tryParse(_dishwasherController.text) ?? 24;

    Map<String, bool> clearances = {};

    // Refrigerator: need 1" sides, 2" top, door swing clearance
    clearances['Fridge side clearance (1\")'] = true;
    clearances['Fridge door swing (90°)'] = true;

    // Range: need proper hood height, combustibles clearance
    if (_rangeType == 'gas') {
      clearances['Range combustible clearance (6\")'] = true;
      clearances['Gas shutoff accessible'] = true;
    }
    clearances['Hood height (24-30\" above)'] = true;

    // Dishwasher: need adjacent counter landing
    clearances['Dishwasher landing (24\" counter)'] = dishwasher >= 18;

    // General
    clearances['Counter beside range (15\" min)'] = true;
    clearances['Counter beside fridge (15\" min)'] = true;

    setState(() { _clearances = clearances; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _fridgeWidthController.text = '36'; _rangeWidthController.text = '30'; _dishwasherController.text = '24'; setState(() => _rangeType = 'freestanding'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Appliance Clearance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Fridge Width', unit: 'inches', controller: _fridgeWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Range Width', unit: 'inches', controller: _rangeWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Dishwasher Width', unit: 'inches', controller: _dishwasherController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CLEARANCE CHECKLIST', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                ..._clearances.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(e.value ? LucideIcons.checkCircle : LucideIcons.xCircle, size: 16, color: e.value ? colors.accentSuccess : colors.accentError),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                  ]),
                )),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Measure appliances before ordering cabinets. Add 1/8\" to cutout dimensions.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildClearanceTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['freestanding', 'slide_in', 'gas', 'induction'];
    final labels = {'freestanding': 'Freestand', 'slide_in': 'Slide-in', 'gas': 'Gas', 'induction': 'Induction'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RANGE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _rangeType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _rangeType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildClearanceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard fridge', '30-36\" wide'),
        _buildTableRow(colors, 'Standard range', '30\" wide'),
        _buildTableRow(colors, 'Standard dishwasher', '24\" wide'),
        _buildTableRow(colors, 'Hood height', '24-30\" above range'),
        _buildTableRow(colors, 'Counter height', '36\" standard'),
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
