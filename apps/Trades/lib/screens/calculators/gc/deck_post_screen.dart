import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Post Calculator - Support posts for deck
class DeckPostScreen extends ConsumerStatefulWidget {
  const DeckPostScreen({super.key});
  @override
  ConsumerState<DeckPostScreen> createState() => _DeckPostScreenState();
}

class _DeckPostScreenState extends ConsumerState<DeckPostScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '3');

  String _postSize = '6x6';
  String _beamSpacing = '8';

  int? _postsNeeded;
  double? _totalLinearFeet;
  int? _postBases;
  int? _postCaps;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final deckLength = double.tryParse(_lengthController.text);
    final deckWidth = double.tryParse(_widthController.text);
    final postHeight = double.tryParse(_heightController.text);
    final beamSpacingFeet = int.tryParse(_beamSpacing) ?? 8;

    if (deckLength == null || deckWidth == null || postHeight == null) {
      setState(() { _postsNeeded = null; _totalLinearFeet = null; _postBases = null; _postCaps = null; });
      return;
    }

    // Posts along length at beam spacing
    final postsPerRow = (deckLength / beamSpacingFeet).floor() + 1;

    // Number of beam rows (typically 2 for freestanding, 1 for ledger-attached)
    // Assume freestanding with 2 rows
    final beamRows = ((deckWidth / 8).ceil()).clamp(1, 3);

    final postsNeeded = postsPerRow * beamRows;
    final totalLinearFeet = postsNeeded * postHeight;

    // Hardware: one base and one cap per post
    final postBases = postsNeeded;
    final postCaps = postsNeeded;

    setState(() { _postsNeeded = postsNeeded; _totalLinearFeet = totalLinearFeet; _postBases = postBases; _postCaps = postCaps; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; _heightController.text = '3'; setState(() { _postSize = '6x6'; _beamSpacing = '8'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Deck Posts', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'POST SIZE', ['4x4', '4x6', '6x6'], _postSize, (v) { setState(() => _postSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'POST SPACING', ['6', '8', '10'], _beamSpacing, (v) { setState(() => _beamSpacing = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Deck Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Deck Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Post Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_postsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLinearFeet!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Post Bases', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postBases', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Post Caps/Beam Saddles', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postCaps', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getPostNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getPostNote() {
    switch (_postSize) {
      case '4x4': return '4x4 posts: Max height 8\'. Use only with single-ply beams. Not for guardrail posts.';
      case '4x6': return '4x6 posts: Better lateral stability. Good for guardrail posts up to 42" deck height.';
      case '6x6': return '6x6 posts: Required for decks >8\' high. Notch for beam bearing or use post caps.';
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
