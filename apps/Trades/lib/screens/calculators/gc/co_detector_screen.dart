import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// CO Detector Calculator - Carbon monoxide alarm requirements
class CoDetectorScreen extends ConsumerStatefulWidget {
  const CoDetectorScreen({super.key});
  @override
  ConsumerState<CoDetectorScreen> createState() => _CoDetectorScreenState();
}

class _CoDetectorScreenState extends ConsumerState<CoDetectorScreen> {
  final _floorsController = TextEditingController(text: '2');

  bool _hasGarage = true;
  bool _hasFuelAppliance = true;

  bool? _required;
  int? _minimumQty;
  String? _placement;

  @override
  void dispose() { _floorsController.dispose(); super.dispose(); }

  void _calculate() {
    final floors = int.tryParse(_floorsController.text) ?? 1;

    // CO detectors required if:
    // - Attached garage, OR
    // - Fuel-burning appliances (gas, oil, wood, etc.)
    final required = _hasGarage || _hasFuelAppliance;

    int minimumQty;
    String placement;

    if (required) {
      // IRC R315: CO alarm outside each sleeping area on each level
      minimumQty = floors;
      placement = 'Outside each sleeping area on every level with sleeping rooms';
    } else {
      minimumQty = 0;
      placement = 'Not required (no attached garage or fuel appliances)';
    }

    setState(() { _required = required; _minimumQty = minimumQty; _placement = placement; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _floorsController.text = '2'; setState(() { _hasGarage = true; _hasFuelAppliance = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('CO Detectors', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Floors with Bedrooms', unit: 'levels', controller: _floorsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Attached Garage', _hasGarage, (v) { setState(() => _hasGarage = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Fuel Appliances', _hasFuelAppliance, (v) { setState(() => _hasFuelAppliance = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_required != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CO ALARMS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_required! ? 'REQUIRED' : 'NOT REQ', style: TextStyle(color: _required! ? colors.accentWarning : colors.accentSuccess, fontSize: 20, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Minimum Quantity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_minimumQty', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_placement!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRequirementsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
          child: Center(child: Text(value ? 'Yes' : 'No', style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    ]);
  }

  Widget _buildRequirementsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IRC R315 CO TRIGGERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildCheckItem(colors, 'Attached garage', true),
        _buildCheckItem(colors, 'Gas furnace/water heater', true),
        _buildCheckItem(colors, 'Fireplace (gas or wood)', true),
        _buildCheckItem(colors, 'Gas range/oven', true),
        _buildCheckItem(colors, 'All-electric home w/o garage', false),
      ]),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text, bool triggers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(triggers ? LucideIcons.alertTriangle : LucideIcons.checkCircle, size: 14, color: triggers ? colors.accentWarning : colors.accentSuccess),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(triggers ? 'Required' : 'Exempt', style: TextStyle(color: triggers ? colors.accentWarning : colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
