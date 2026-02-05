import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Decking Calculator - Deck boards and materials
class DeckingScreen extends ConsumerStatefulWidget {
  const DeckingScreen({super.key});
  @override
  ConsumerState<DeckingScreen> createState() => _DeckingScreenState();
}

class _DeckingScreenState extends ConsumerState<DeckingScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');

  String _boardWidth = '5.5';
  String _boardLength = '16';
  String _material = 'composite';

  double? _deckArea;
  int? _boardsNeeded;
  int? _screwsLbs;
  double? _materialCost;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final deckLength = double.tryParse(_lengthController.text);
    final deckWidth = double.tryParse(_widthController.text);
    final boardWidthInches = double.tryParse(_boardWidth) ?? 5.5;
    final boardLengthFeet = int.tryParse(_boardLength) ?? 16;

    if (deckLength == null || deckWidth == null) {
      setState(() { _deckArea = null; _boardsNeeded = null; _screwsLbs = null; _materialCost = null; });
      return;
    }

    final deckArea = deckLength * deckWidth;

    // Board coverage: width in feet × length
    // Account for 1/8" gap between boards
    final effectiveBoardWidth = (boardWidthInches + 0.125) / 12;
    final boardCoverage = effectiveBoardWidth * boardLengthFeet;

    // Boards needed with 10% waste
    final boardsNeeded = ((deckArea / boardCoverage) * 1.10).ceil();

    // Screws: ~350 per 100 sq ft for hidden fasteners, ~500 for face screw
    final screwsLbs = (deckArea / 100 * 2).ceil(); // Roughly 2 lbs per 100 sq ft

    // Material cost estimate per board
    double costPerBoard;
    switch (_material) {
      case 'pt': costPerBoard = boardLengthFeet * 1.50; break; // Pressure treated ~$1.50/LF
      case 'cedar': costPerBoard = boardLengthFeet * 3.00; break; // Cedar ~$3/LF
      case 'composite': costPerBoard = boardLengthFeet * 4.50; break; // Composite ~$4.50/LF
      case 'pvc': costPerBoard = boardLengthFeet * 6.00; break; // PVC ~$6/LF
      default: costPerBoard = boardLengthFeet * 4.50;
    }

    final materialCost = boardsNeeded * costPerBoard;

    setState(() { _deckArea = deckArea; _boardsNeeded = boardsNeeded; _screwsLbs = screwsLbs; _materialCost = materialCost; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; setState(() { _boardWidth = '5.5'; _boardLength = '16'; _material = 'composite'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Decking', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['pt', 'cedar', 'composite', 'pvc'], _material, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'BOARD LENGTH', ['12', '16', '20'], _boardLength, (v) { setState(() => _boardLength = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Deck Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Deck Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_boardsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BOARDS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boardsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deck Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_deckArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Screws', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_screwsLbs lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Board Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_materialCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getMaterialNote() {
    switch (_material) {
      case 'pt': return 'Pressure treated: Let dry 2-4 weeks before staining. Re-seal annually.';
      case 'cedar': return 'Western red cedar: Natural rot resistance. Seal to prevent graying.';
      case 'composite': return 'Composite: Low maintenance, 25+ year warranty. Requires ventilation below.';
      case 'pvc': return 'PVC/cellular: Zero wood content, waterproof. May expand/contract with temperature.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'pt': 'PT Wood', 'cedar': 'Cedar', 'composite': 'Composite', 'pvc': 'PVC'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('${labels[o] ?? o}$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
