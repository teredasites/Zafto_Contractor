import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Collar Tie Calculator - Tie placement and sizing
class CollarTieCalculatorScreen extends ConsumerStatefulWidget {
  const CollarTieCalculatorScreen({super.key});
  @override
  ConsumerState<CollarTieCalculatorScreen> createState() => _CollarTieCalculatorScreenState();
}

class _CollarTieCalculatorScreenState extends ConsumerState<CollarTieCalculatorScreen> {
  final _ridgeLengthController = TextEditingController(text: '40');
  final _rafterSpanController = TextEditingController(text: '12');

  String _spacing = '48';

  int? _collarTies;
  String? _tieSize;
  double? _tieLength;

  @override
  void dispose() { _ridgeLengthController.dispose(); _rafterSpanController.dispose(); super.dispose(); }

  void _calculate() {
    final ridgeLength = double.tryParse(_ridgeLengthController.text);
    final rafterSpan = double.tryParse(_rafterSpanController.text);
    final spacingInches = int.tryParse(_spacing) ?? 48;

    if (ridgeLength == null || rafterSpan == null) {
      setState(() { _collarTies = null; _tieSize = null; _tieLength = null; });
      return;
    }

    // Collar ties typically installed at every other rafter pair or 4' OC max
    final lengthInches = ridgeLength * 12;
    final collarTies = (lengthInches / spacingInches).floor() + 1;

    // Tie length: approximately 1/3 of rafter span (installed in upper 1/3)
    final tieLength = rafterSpan * 0.4;

    // Size: 1x6 minimum, 2x4 for longer spans
    final tieSize = rafterSpan <= 10 ? '1x6' : '2x4';

    setState(() { _collarTies = collarTies; _tieSize = tieSize; _tieLength = tieLength; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _ridgeLengthController.text = '40'; _rafterSpanController.text = '12'; setState(() => _spacing = '48'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Collar Ties', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Ridge Length', unit: 'ft', controller: _ridgeLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rafter Span', unit: 'ft', controller: _rafterSpanController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_collarTies != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COLLAR TIES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_collarTies', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tie Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_tieSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tie Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tieLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Install in upper 1/3 of attic space. Use 3-10d nails per end minimum.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    return Row(children: ['32', '48'].map((s) {
      final isSelected = _spacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _spacing = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s == '32' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s" OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }
}
