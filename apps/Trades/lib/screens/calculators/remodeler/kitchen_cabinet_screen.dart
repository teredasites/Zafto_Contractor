import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Kitchen Cabinet Calculator - Cabinet layout and quantity
class KitchenCabinetScreen extends ConsumerStatefulWidget {
  const KitchenCabinetScreen({super.key});
  @override
  ConsumerState<KitchenCabinetScreen> createState() => _KitchenCabinetScreenState();
}

class _KitchenCabinetScreenState extends ConsumerState<KitchenCabinetScreen> {
  final _wallLengthController = TextEditingController(text: '20');
  final _upperController = TextEditingController(text: '12');
  final _baseController = TextEditingController(text: '15');

  String _layout = 'lshape';

  int? _baseCabinets;
  int? _wallCabinets;
  double? _linearFeet;
  int? _hinges;

  @override
  void dispose() { _wallLengthController.dispose(); _upperController.dispose(); _baseController.dispose(); super.dispose(); }

  void _calculate() {
    final wallLength = double.tryParse(_wallLengthController.text) ?? 0;
    final upperLF = double.tryParse(_upperController.text) ?? 0;
    final baseLF = double.tryParse(_baseController.text) ?? 0;

    // Standard cabinet widths: base 12-36", upper 12-36"
    // Average 24" per cabinet
    final baseCabinets = (baseLF / 2).ceil(); // 24" avg
    final wallCabinets = (upperLF / 2).ceil();

    final linearFeet = baseLF + upperLF;

    // Hinges: 2 per door, avg 1.5 doors per cabinet
    final totalDoors = ((baseCabinets + wallCabinets) * 1.5).ceil();
    final hinges = totalDoors * 2;

    setState(() { _baseCabinets = baseCabinets; _wallCabinets = wallCabinets; _linearFeet = linearFeet; _hinges = hinges; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _wallLengthController.text = '20'; _upperController.text = '12'; _baseController.text = '15'; setState(() => _layout = 'lshape'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Kitchen Cabinets', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Wall Length', unit: 'feet', controller: _wallLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Base Cabinets', unit: 'linear ft', controller: _baseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Cabinets', unit: 'linear ft', controller: _upperController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_baseCabinets != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LINEAR FT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Cabinets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_baseCabinets units', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Cabinets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_wallCabinets units', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinges Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_hinges', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard base height 34.5\", wall 30-42\". Leave 18\" between base and wall cabinets.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['galley', 'lshape', 'ushape', 'island'];
    final labels = {'galley': 'Galley', 'lshape': 'L-Shape', 'ushape': 'U-Shape', 'island': 'Island'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('KITCHEN LAYOUT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _layout == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _layout = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Base cabinet', '24\" deep x 34.5\" high'),
        _buildTableRow(colors, 'Wall cabinet', '12\" deep x 30-42\" high'),
        _buildTableRow(colors, 'Tall pantry', '24\" deep x 84-96\" high'),
        _buildTableRow(colors, 'Sink base', '30-36\" wide'),
        _buildTableRow(colors, 'Corner base', '36\" each direction'),
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
