import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drop Cloth Calculator - Floor protection estimation
class DropClothScreen extends ConsumerStatefulWidget {
  const DropClothScreen({super.key});
  @override
  ConsumerState<DropClothScreen> createState() => _DropClothScreenState();
}

class _DropClothScreenState extends ConsumerState<DropClothScreen> {
  final _lengthController = TextEditingController(text: '15');
  final _widthController = TextEditingController(text: '12');

  String _type = 'canvas';

  double? _areaSqft;
  int? _cloths9x12;
  int? _cloths4x15;
  double? _plasticSqft;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;

    final areaSqft = length * width;

    // Standard drop cloth sizes
    final cloths9x12 = (areaSqft / 108).ceil(); // 9x12 = 108 sqft
    final cloths4x15 = (areaSqft / 60).ceil(); // 4x15 = 60 sqft (runner)

    // Plastic sheeting: sold by linear foot, 9' wide
    final plasticSqft = areaSqft * 1.1; // Add 10% overlap

    setState(() { _areaSqft = areaSqft; _cloths9x12 = cloths9x12; _cloths4x15 = cloths4x15; _plasticSqft = plasticSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '15'; _widthController.text = '12'; setState(() => _type = 'canvas'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Drop Cloth', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Room Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_areaSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FLOOR AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('9\' x 12\' Cloths', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cloths9x12', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('4\' x 15\' Runners', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cloths4x15', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plastic (if using)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_plasticSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  String _getTypeTip() {
    switch (_type) {
      case 'canvas':
        return 'Canvas is reusable, absorbs drips. Best for professional use. Heavy but won\'t slip.';
      case 'plastic':
        return 'Plastic is cheapest, disposable. Slippery - tape down edges. Use for dust containment.';
      case 'paper':
        return 'Paper/cardboard protects from feet traffic. Use with plastic underneath for liquid.';
      default:
        return 'Match drop cloth to task. Canvas for painting, plastic for dust, paper for traffic.';
    }
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['canvas', 'plastic', 'paper'];
    final labels = {'canvas': 'Canvas', 'plastic': 'Plastic', 'paper': 'Paper/Board'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
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
        _buildTableRow(colors, '4\' x 12\'', '48 sqft - Small room'),
        _buildTableRow(colors, '4\' x 15\'', '60 sqft - Runner'),
        _buildTableRow(colors, '6\' x 9\'', '54 sqft - Work area'),
        _buildTableRow(colors, '9\' x 12\'', '108 sqft - Full room'),
        _buildTableRow(colors, '12\' x 15\'', '180 sqft - Large room'),
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
