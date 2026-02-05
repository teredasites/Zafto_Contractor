import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Form Board Calculator - Concrete forming materials
class FormBoardScreen extends ConsumerStatefulWidget {
  const FormBoardScreen({super.key});
  @override
  ConsumerState<FormBoardScreen> createState() => _FormBoardScreenState();
}

class _FormBoardScreenState extends ConsumerState<FormBoardScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _heightController = TextEditingController(text: '8');

  String _boardWidth = '12';
  String _reuses = '3';

  int? _boardsNeeded;
  int? _linearFeet;
  int? _stakes;
  int? _braces;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final heightInches = double.tryParse(_heightController.text);
    final boardWidthInches = int.tryParse(_boardWidth) ?? 12;
    final reuses = int.tryParse(_reuses) ?? 3;

    if (perimeter == null || heightInches == null) {
      setState(() { _boardsNeeded = null; _linearFeet = null; _stakes = null; _braces = null; });
      return;
    }

    // Both sides of pour
    final totalLinearFeet = (perimeter * 2).ceil();

    // Boards stacked to reach height
    final boardsHigh = (heightInches / boardWidthInches).ceil();
    final totalBoards = (totalLinearFeet / 8).ceil() * boardsHigh; // 8' boards

    // Adjust for reuse factor
    final boardsNeeded = (totalBoards / reuses).ceil();

    // Stakes every 2' on center
    final stakes = (totalLinearFeet / 2).ceil();

    // Braces every 4' on center
    final braces = (totalLinearFeet / 4).ceil();

    setState(() { _boardsNeeded = boardsNeeded; _linearFeet = totalLinearFeet; _stakes = stakes; _braces = braces; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _heightController.text = '8'; setState(() { _boardWidth = '12'; _reuses = '3'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Form Boards', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BOARD WIDTH', ['6', '8', '10', '12'], _boardWidth, (v) { setState(() => _boardWidth = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'EXPECTED REUSES', ['1', '2', '3', '4'], _reuses, (v) { setState(() => _reuses = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Form Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_boardsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FORM BOARDS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boardsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_linearFeet LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes (2\' OC)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stakes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Braces (4\' OC)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_braces', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use 2x lumber or plywood. Oil forms before pour for easier stripping.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
