import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rim Joist Calculator - Perimeter framing
class RimJoistScreen extends ConsumerStatefulWidget {
  const RimJoistScreen({super.key});
  @override
  ConsumerState<RimJoistScreen> createState() => _RimJoistScreenState();
}

class _RimJoistScreenState extends ConsumerState<RimJoistScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');

  String _joistDepth = '2x10';

  double? _perimeter;
  int? _boards;
  int? _nails;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);

    if (length == null || width == null) {
      setState(() { _perimeter = null; _boards = null; _nails = null; });
      return;
    }

    final perimeter = (length + width) * 2;
    final boards = (perimeter / 16).ceil(); // 16' boards
    final nails = (perimeter * 4).round(); // ~4 nails per LF (16d @ 6" OC top/bottom)

    setState(() { _perimeter = perimeter; _boards = boards; _nails = nails; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; setState(() => _joistDepth = '2x10'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rim Joist', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSizeSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_perimeter != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RIM BOARD SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_joistDepth, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perimeter', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_perimeter!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('16\' Boards', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boards', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('16d Nails', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_nails', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['2x8', '2x10', '2x12'];
    return Row(children: sizes.map((s) {
      final isSelected = _joistDepth == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _joistDepth = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s != sizes.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text(s, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }
}
