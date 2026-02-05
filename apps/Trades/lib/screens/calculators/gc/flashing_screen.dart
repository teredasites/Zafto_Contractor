import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flashing Calculator - Metal flashing requirements
class FlashingScreen extends ConsumerStatefulWidget {
  const FlashingScreen({super.key});
  @override
  ConsumerState<FlashingScreen> createState() => _FlashingScreenState();
}

class _FlashingScreenState extends ConsumerState<FlashingScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _windowsController = TextEditingController(text: '8');
  final _doorsController = TextEditingController(text: '3');

  String _material = 'aluminum';

  double? _dripEdge;
  double? _stepFlashing;
  double? _windowFlashing;
  double? _doorFlashing;

  @override
  void dispose() { _lengthController.dispose(); _windowsController.dispose(); _doorsController.dispose(); super.dispose(); }

  void _calculate() {
    final roofEdge = double.tryParse(_lengthController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final doors = int.tryParse(_doorsController.text) ?? 0;

    // Drip edge: 10' pieces, add 10% waste
    final dripEdge = (roofEdge * 1.1) / 10;

    // Step flashing: ~2 pcs per linear foot of roof/wall intersection
    // Assume 20' average for typical home
    final stepFlashing = 20.0 * 2;

    // Window head flashing: 4' per window avg
    final windowFlashing = windows * 4.0;

    // Door flashing: 5' per door avg
    final doorFlashing = doors * 5.0;

    setState(() { _dripEdge = dripEdge; _stepFlashing = stepFlashing; _windowFlashing = windowFlashing; _doorFlashing = doorFlashing; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _windowsController.text = '8'; _doorsController.text = '3'; setState(() => _material = 'aluminum'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Edge Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Ext. Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_dripEdge != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('FLASHING NEEDS', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drip Edge (10\' pcs)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_dripEdge!.ceil()}', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Step Flashing (pcs)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stepFlashing!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Window Flashing (lf)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_windowFlashing!.toStringAsFixed(0)}\'', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Door Flashing (lf)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_doorFlashing!.toStringAsFixed(0)}\'', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Install kick-out at wall/roof transitions. Integrate with WRB properly.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFlashingTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['aluminum', 'galv', 'copper', 'lead'];
    final labels = {'aluminum': 'Aluminum', 'galv': 'Galvanized', 'copper': 'Copper', 'lead': 'Lead'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _material == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildFlashingTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLASHING TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Drip edge', 'Eaves & rakes'),
        _buildTableRow(colors, 'Step flashing', 'Wall/roof intersection'),
        _buildTableRow(colors, 'Counter flashing', 'Into masonry'),
        _buildTableRow(colors, 'Valley', 'W-style or closed'),
        _buildTableRow(colors, 'Kick-out', 'Sidewall termination'),
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
