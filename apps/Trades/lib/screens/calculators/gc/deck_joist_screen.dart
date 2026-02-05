import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Joist Calculator - Deck framing joists
class DeckJoistScreen extends ConsumerStatefulWidget {
  const DeckJoistScreen({super.key});
  @override
  ConsumerState<DeckJoistScreen> createState() => _DeckJoistScreenState();
}

class _DeckJoistScreenState extends ConsumerState<DeckJoistScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');

  String _joistSize = '2x8';
  String _spacing = '16';

  int? _joistsNeeded;
  int? _hangersNeeded;
  int? _blockingPieces;
  double? _linearFeet;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final deckLength = double.tryParse(_lengthController.text);
    final deckWidth = double.tryParse(_widthController.text);
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (deckLength == null || deckWidth == null) {
      setState(() { _joistsNeeded = null; _hangersNeeded = null; _blockingPieces = null; _linearFeet = null; });
      return;
    }

    // Joists run across width direction typically
    final joistsNeeded = ((deckLength * 12) / spacingInches).floor() + 1;

    // Joist hangers needed (one each end unless cantilever)
    final hangersNeeded = joistsNeeded * 2;

    // Blocking between joists at mid-span for spans over 8'
    int blockingPieces = 0;
    if (deckWidth > 8) {
      blockingPieces = joistsNeeded - 1;
    }

    // Total linear feet of joist material
    final linearFeet = joistsNeeded * deckWidth;

    setState(() { _joistsNeeded = joistsNeeded; _hangersNeeded = hangersNeeded; _blockingPieces = blockingPieces; _linearFeet = linearFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; setState(() { _joistSize = '2x8'; _spacing = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Deck Joists', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'JOIST SIZE', ['2x6', '2x8', '2x10', '2x12'], _joistSize, (v) { setState(() => _joistSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SPACING', ['12', '16', '24'], _spacing, (v) { setState(() => _spacing = v); _calculate(); }, suffix: '" OC'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Deck Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Joist Span', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_joistsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('JOISTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_joistsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joist Hangers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hangersNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Blocking Pieces', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blockingPieces', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSpanNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getSpanNote() {
    switch (_joistSize) {
      case '2x6': return '2x6 PT: Max span 9\'9" @ 16" OC. Use for low decks or short spans only.';
      case '2x8': return '2x8 PT: Max span 13\'1" @ 16" OC. Common residential deck joist.';
      case '2x10': return '2x10 PT: Max span 16\'5" @ 16" OC. For longer spans or heavy loads.';
      case '2x12': return '2x12 PT: Max span 19\'1" @ 16" OC. Maximum wood deck joist span.';
      default: return '';
    }
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
