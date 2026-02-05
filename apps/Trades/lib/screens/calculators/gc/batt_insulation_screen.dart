import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Batt Insulation Calculator - Fiberglass/mineral wool batts
class BattInsulationScreen extends ConsumerStatefulWidget {
  const BattInsulationScreen({super.key});
  @override
  ConsumerState<BattInsulationScreen> createState() => _BattInsulationScreenState();
}

class _BattInsulationScreenState extends ConsumerState<BattInsulationScreen> {
  final _areaController = TextEditingController(text: '1200');

  String _rValue = 'R-19';
  String _cavityWidth = '16';

  double? _sqftNeeded;
  int? _bagsNeeded;
  double? _rValueNum;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text);

    if (area == null) {
      setState(() { _sqftNeeded = null; _bagsNeeded = null; _rValueNum = null; });
      return;
    }

    // Add 5% waste for cutting
    final sqftNeeded = area * 1.05;

    // Bag coverage varies by R-value and cavity width
    double sqftPerBag;
    double rValueNum;
    switch (_rValue) {
      case 'R-11':
        rValueNum = 11;
        sqftPerBag = _cavityWidth == '16' ? 135 : 87.5;
        break;
      case 'R-13':
        rValueNum = 13;
        sqftPerBag = _cavityWidth == '16' ? 106 : 68.75;
        break;
      case 'R-15':
        rValueNum = 15;
        sqftPerBag = _cavityWidth == '16' ? 88 : 57;
        break;
      case 'R-19':
        rValueNum = 19;
        sqftPerBag = _cavityWidth == '16' ? 75 : 48.75;
        break;
      case 'R-30':
        rValueNum = 30;
        sqftPerBag = _cavityWidth == '16' ? 58 : 37.5;
        break;
      case 'R-38':
        rValueNum = 38;
        sqftPerBag = _cavityWidth == '16' ? 44 : 28.5;
        break;
      default:
        rValueNum = 19;
        sqftPerBag = 75;
    }

    final bagsNeeded = (sqftNeeded / sqftPerBag).ceil();

    setState(() { _sqftNeeded = sqftNeeded; _bagsNeeded = bagsNeeded; _rValueNum = rValueNum; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '1200'; setState(() { _rValue = 'R-19'; _cavityWidth = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Batt Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'R-VALUE', ['R-11', 'R-13', 'R-19', 'R-30'], _rValue, (v) { setState(() => _rValue = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'CAVITY WIDTH', ['16', '24'], _cavityWidth, (v) { setState(() => _cavityWidth = v); _calculate(); }, suffix: '" OC'),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Insulate', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bagsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BAGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bagsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage w/ Waste', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqftNeeded!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R-Value', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rValueNum!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getRValueNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getRValueNote() {
    switch (_rValue) {
      case 'R-11': return 'R-11: 3.5" thick, 2x4 walls. Minimum for exterior walls in most climates.';
      case 'R-13': return 'R-13: 3.5" thick, 2x4 walls. Standard for exterior walls, fits snugly.';
      case 'R-19': return 'R-19: 6.25" thick, 2x6 walls or floors. Good for cold climates.';
      case 'R-30': return 'R-30: 10" thick, attic floors. Standard attic insulation in moderate climates.';
      case 'R-38': return 'R-38: 12" thick, attic floors. Recommended for cold climate attics.';
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
            child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
