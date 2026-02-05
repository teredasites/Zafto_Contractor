import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Anchor Bolt Layout - Quantity and spacing
class AnchorBoltScreen extends ConsumerStatefulWidget {
  const AnchorBoltScreen({super.key});
  @override
  ConsumerState<AnchorBoltScreen> createState() => _AnchorBoltScreenState();
}

class _AnchorBoltScreenState extends ConsumerState<AnchorBoltScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _doorsController = TextEditingController(text: '2');
  final _windowsController = TextEditingController(text: '6');

  String _spacing = '6';

  int? _perimeterBolts;
  int? _openingBolts;
  int? _totalBolts;

  @override
  void dispose() { _perimeterController.dispose(); _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final spacingFeet = int.tryParse(_spacing) ?? 6;

    if (perimeter == null) {
      setState(() { _perimeterBolts = null; _openingBolts = null; _totalBolts = null; });
      return;
    }

    // Perimeter bolts at spacing (max 6' OC per IRC R403.1.6)
    final perimeterBolts = (perimeter / spacingFeet).ceil();

    // Additional bolts within 12" of each side of openings
    final openingBolts = (doors + windows) * 2;

    final totalBolts = perimeterBolts + openingBolts;

    setState(() { _perimeterBolts = perimeterBolts; _openingBolts = openingBolts; _totalBolts = totalBolts; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _doorsController.text = '2'; _windowsController.text = '6'; setState(() => _spacing = '6'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Anchor Bolts', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Foundation Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBolts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL ANCHOR BOLTS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalBolts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perimeter Bolts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_perimeterBolts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Opening Bolts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_openingBolts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use 1/2" x 10" J-bolts minimum. Embed 7" min into concrete. 7" from end of sill plate.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    final options = ['4', '6'];
    return Row(children: options.map((s) {
      final isSelected = _spacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _spacing = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s == '4' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s\' OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }
}
