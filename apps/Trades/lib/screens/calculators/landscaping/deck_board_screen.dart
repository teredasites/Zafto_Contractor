import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Board Calculator - Boards and screws
class DeckBoardScreen extends ConsumerStatefulWidget {
  const DeckBoardScreen({super.key});
  @override
  ConsumerState<DeckBoardScreen> createState() => _DeckBoardScreenState();
}

class _DeckBoardScreenState extends ConsumerState<DeckBoardScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');

  String _boardWidth = '5.5';
  String _boardLength = '16';
  double _wasteFactor = 10;

  int? _boardsNeeded;
  int? _screws;
  double? _linearFeet;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final deckLength = double.tryParse(_lengthController.text) ?? 16;
    final deckWidth = double.tryParse(_widthController.text) ?? 12;
    final boardWidthIn = double.tryParse(_boardWidth) ?? 5.5;
    final boardLengthFt = double.tryParse(_boardLength) ?? 16;

    // Convert board width to feet (add 1/8" gap)
    final boardCoverageIn = boardWidthIn + 0.125;
    final boardCoverageFt = boardCoverageIn / 12;

    // Number of boards across the deck
    final boardsAcross = (deckWidth / boardCoverageFt).ceil();

    // How many board lengths needed for deck length
    final lengthsNeeded = (deckLength / boardLengthFt).ceil();

    final baseBoards = boardsAcross * lengthsNeeded;
    final boardsWithWaste = (baseBoards * (1 + _wasteFactor / 100)).ceil();

    // Linear feet
    final linearFeet = boardsWithWaste * boardLengthFt;

    // Screws: 2 per joist crossing (assuming 16" OC joists)
    final joistCrossings = (deckLength / 1.33).ceil(); // 16" = 1.33 ft
    final screwsPerBoard = joistCrossings * 2;
    final totalScrews = boardsAcross * screwsPerBoard;

    setState(() {
      _boardsNeeded = boardsWithWaste;
      _screws = totalScrews;
      _linearFeet = linearFeet;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; setState(() { _boardWidth = '5.5'; _boardLength = '16'; _wasteFactor = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Deck Boards', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BOARD WIDTH', ['5.5', '3.5'], _boardWidth, {'5.5': '5.5" (2×6)', '3.5': '3.5" (2×4)'}, (v) { setState(() => _boardWidth = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'BOARD LENGTH', ['8', '12', '16', '20'], _boardLength, {'8': "8'", '12': "12'", '16': "16'", '20': "20'"}, (v) { setState(() => _boardLength = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Deck Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Deck Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 20, divisions: 3, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_boardsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BOARDS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boardsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Linear feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_linearFeet!.toStringAsFixed(0)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deck screws', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_screws', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deck area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${((double.tryParse(_lengthController.text) ?? 16) * (double.tryParse(_widthController.text) ?? 12)).toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDeckGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDeckGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DECKING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Board gap', '1/8" for drainage'),
        _buildTableRow(colors, 'Screws per joist', '2 per board'),
        _buildTableRow(colors, 'Joist spacing', '16" OC typical'),
        _buildTableRow(colors, 'Overhang', '1-2" past frame'),
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
