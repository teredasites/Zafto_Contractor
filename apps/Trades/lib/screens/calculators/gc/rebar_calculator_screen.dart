import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rebar Calculator - Reinforcement needs
class RebarCalculatorScreen extends ConsumerStatefulWidget {
  const RebarCalculatorScreen({super.key});
  @override
  ConsumerState<RebarCalculatorScreen> createState() => _RebarCalculatorScreenState();
}

class _RebarCalculatorScreenState extends ConsumerState<RebarCalculatorScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');

  String _spacing = '12';
  String _barSize = '#4';

  int? _longBars;
  int? _shortBars;
  int? _totalBars;
  double? _totalLinearFeet;
  double? _weightLbs;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final spacingInches = int.tryParse(_spacing) ?? 12;

    if (length == null || width == null) {
      setState(() { _longBars = null; _shortBars = null; _totalBars = null; _totalLinearFeet = null; _weightLbs = null; });
      return;
    }

    // Bars running length direction
    final longBars = ((width * 12) / spacingInches).floor() + 1;
    // Bars running width direction
    final shortBars = ((length * 12) / spacingInches).floor() + 1;

    final totalBars = longBars + shortBars;
    final totalLinearFeet = (longBars * length) + (shortBars * width);

    // Weight per foot by bar size
    double lbsPerFoot;
    switch (_barSize) {
      case '#3': lbsPerFoot = 0.376; break;
      case '#4': lbsPerFoot = 0.668; break;
      case '#5': lbsPerFoot = 1.043; break;
      case '#6': lbsPerFoot = 1.502; break;
      default: lbsPerFoot = 0.668;
    }
    final weightLbs = totalLinearFeet * lbsPerFoot;

    setState(() { _longBars = longBars; _shortBars = shortBars; _totalBars = totalBars; _totalLinearFeet = totalLinearFeet; _weightLbs = weightLbs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; setState(() { _spacing = '12'; _barSize = '#4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rebar Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BAR SIZE', ['#3', '#4', '#5', '#6'], _barSize, (v) { setState(() => _barSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SPACING', ['12', '16', '18', '24'], _spacing, (v) { setState(() => _spacing = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBars != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BARS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalBars', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Long Direction', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_longBars bars', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Short Direction', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_shortBars bars', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLinearFeet!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Weight', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weightLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
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
