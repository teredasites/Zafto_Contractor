import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Board Feet Calculator - Lumber volume measurement
class BoardFeetScreen extends ConsumerStatefulWidget {
  const BoardFeetScreen({super.key});
  @override
  ConsumerState<BoardFeetScreen> createState() => _BoardFeetScreenState();
}

class _BoardFeetScreenState extends ConsumerState<BoardFeetScreen> {
  final _thicknessController = TextEditingController(text: '2');
  final _widthController = TextEditingController(text: '6');
  final _lengthController = TextEditingController(text: '12');
  final _quantityController = TextEditingController(text: '50');

  String _priceUnit = 'bf';
  final _priceController = TextEditingController(text: '1.50');

  double? _boardFeetEach;
  double? _totalBoardFeet;
  double? _totalCost;

  @override
  void dispose() { _thicknessController.dispose(); _widthController.dispose(); _lengthController.dispose(); _quantityController.dispose(); _priceController.dispose(); super.dispose(); }

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final width = double.tryParse(_widthController.text);
    final length = double.tryParse(_lengthController.text);
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (thickness == null || width == null || length == null || quantity == null) {
      setState(() { _boardFeetEach = null; _totalBoardFeet = null; _totalCost = null; });
      return;
    }

    // Board feet = (thickness" × width" × length') / 12
    final boardFeetEach = (thickness * width * length) / 12;
    final totalBoardFeet = boardFeetEach * quantity;

    double? totalCost;
    if (price != null) {
      if (_priceUnit == 'bf') {
        totalCost = totalBoardFeet * price;
      } else {
        totalCost = quantity * price;
      }
    }

    setState(() { _boardFeetEach = boardFeetEach; _totalBoardFeet = totalBoardFeet; _totalCost = totalCost; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _thicknessController.text = '2'; _widthController.text = '6'; _lengthController.text = '12'; _quantityController.text = '50'; _priceController.text = '1.50'; setState(() => _priceUnit = 'bf'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Board Feet', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Quantity', unit: 'pcs', controller: _quantityController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 20),
            _buildSelector(colors, 'PRICE PER', ['bf', 'piece'], _priceUnit, (v) { setState(() => _priceUnit = v); _calculate(); }),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Price', unit: '\$', controller: _priceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalBoardFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BOARD FEET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalBoardFeet!.toStringAsFixed(1)} BF', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Board Feet Each', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_boardFeetEach!.toStringAsFixed(2)} BF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_totalCost != null) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Formula: (T" × W" × L\') / 12 = Board Feet. Use nominal dimensions for standard lumber.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'bf': 'Board Foot', 'piece': 'Per Piece'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
