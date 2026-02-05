import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Railing Calculator - Deck/stair railing materials
class RailingScreen extends ConsumerStatefulWidget {
  const RailingScreen({super.key});
  @override
  ConsumerState<RailingScreen> createState() => _RailingScreenState();
}

class _RailingScreenState extends ConsumerState<RailingScreen> {
  final _linearFeetController = TextEditingController(text: '48');
  final _heightController = TextEditingController(text: '36');

  String _railingType = 'wood';
  String _postSpacing = '6';

  int? _postsNeeded;
  int? _topRailLF;
  int? _bottomRailLF;
  int? _balusterCount;

  @override
  void dispose() { _linearFeetController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final heightInches = double.tryParse(_heightController.text);
    final postSpacingFeet = int.tryParse(_postSpacing) ?? 6;

    if (linearFeet == null || heightInches == null) {
      setState(() { _postsNeeded = null; _topRailLF = null; _bottomRailLF = null; _balusterCount = null; });
      return;
    }

    // Posts at spacing intervals plus ends
    final postsNeeded = (linearFeet / postSpacingFeet).ceil() + 1;

    // Rails run the full length
    final topRailLF = linearFeet.ceil();
    final bottomRailLF = linearFeet.ceil();

    // Balusters: max 4" spacing per code, typically 3-7/8" on center
    // About 3 balusters per linear foot
    final balusterCount = (linearFeet * 3).ceil();

    setState(() { _postsNeeded = postsNeeded; _topRailLF = topRailLF; _bottomRailLF = bottomRailLF; _balusterCount = balusterCount; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _linearFeetController.text = '48'; _heightController.text = '36'; setState(() { _railingType = 'wood'; _postSpacing = '6'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Railing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'RAILING TYPE', ['wood', 'composite', 'aluminum', 'cable'], _railingType, (v) { setState(() => _railingType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'POST SPACING', ['4', '6', '8'], _postSpacing, (v) { setState(() => _postSpacing = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Linear Feet', unit: 'ft', controller: _linearFeetController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rail Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_postsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Top Rail', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_topRailLF LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bottom Rail', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bottomRailLF LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_railingType == 'cable' ? 'Cable Runs' : 'Balusters', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_balusterCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getRailingNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getRailingNote() {
    switch (_railingType) {
      case 'wood': return 'Code: 36" min height for residential, 42" for commercial. 4" max baluster spacing.';
      case 'composite': return 'Composite rails: Pre-routed for balusters. Match decking brand for color consistency.';
      case 'aluminum': return 'Aluminum: Powder-coated, low maintenance. Check load ratings for post mount.';
      case 'cable': return 'Cable rail: 3" max spacing per IRC. Intermediate posts every 4\' for deflection.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'wood': 'Wood', 'composite': 'Composite', 'aluminum': 'Aluminum', 'cable': 'Cable'};
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
