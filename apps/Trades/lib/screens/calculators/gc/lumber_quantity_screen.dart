import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lumber Quantity Calculator - Framing lumber takeoff
class LumberQuantityScreen extends ConsumerStatefulWidget {
  const LumberQuantityScreen({super.key});
  @override
  ConsumerState<LumberQuantityScreen> createState() => _LumberQuantityScreenState();
}

class _LumberQuantityScreenState extends ConsumerState<LumberQuantityScreen> {
  final _linearFeetController = TextEditingController(text: '500');

  String _lumberSize = '2x4';
  String _stockLength = '8';

  int? _piecesNeeded;
  double? _boardFeet;
  double? _wasteFeet;

  @override
  void dispose() { _linearFeetController.dispose(); super.dispose(); }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final stockLength = int.tryParse(_stockLength) ?? 8;

    if (linearFeet == null) {
      setState(() { _piecesNeeded = null; _boardFeet = null; _wasteFeet = null; });
      return;
    }

    // Add 10% waste
    final totalLF = linearFeet * 1.10;

    // Pieces needed at stock length
    final piecesNeeded = (totalLF / stockLength).ceil();

    // Calculate board feet
    double thickness, width;
    switch (_lumberSize) {
      case '2x4': thickness = 2; width = 4; break;
      case '2x6': thickness = 2; width = 6; break;
      case '2x8': thickness = 2; width = 8; break;
      case '2x10': thickness = 2; width = 10; break;
      case '2x12': thickness = 2; width = 12; break;
      default: thickness = 2; width = 4;
    }

    // Board feet = (pieces × thickness × width × length) / 12
    final actualLF = piecesNeeded * stockLength;
    final boardFeet = (thickness * width * actualLF) / 12;

    final wasteFeet = actualLF - linearFeet;

    setState(() { _piecesNeeded = piecesNeeded; _boardFeet = boardFeet; _wasteFeet = wasteFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _linearFeetController.text = '500'; setState(() { _lumberSize = '2x4'; _stockLength = '8'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lumber Quantity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LUMBER SIZE', ['2x4', '2x6', '2x8', '2x10'], _lumberSize, (v) { setState(() => _lumberSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STOCK LENGTH', ['8', '10', '12', '16'], _stockLength, (v) { setState(() => _stockLength = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Linear Feet Needed', unit: 'LF', controller: _linearFeetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_piecesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PIECES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_piecesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Board Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_boardFeet!.toStringAsFixed(1)} BF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_piecesNeeded! * int.parse(_stockLength))} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Waste Allowance', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wasteFeet!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Includes 10% waste factor. Optimize cuts to minimize waste. Bundle pricing may reduce cost.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
