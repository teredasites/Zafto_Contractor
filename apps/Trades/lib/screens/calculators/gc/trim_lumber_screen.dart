import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trim Lumber Calculator - Interior/exterior trim materials
class TrimLumberScreen extends ConsumerStatefulWidget {
  const TrimLumberScreen({super.key});
  @override
  ConsumerState<TrimLumberScreen> createState() => _TrimLumberScreenState();
}

class _TrimLumberScreenState extends ConsumerState<TrimLumberScreen> {
  final _linearFeetController = TextEditingController(text: '200');

  String _trimType = 'casing';
  String _trimSize = '2-1/4';
  String _stockLength = '16';

  int? _piecesNeeded;
  double? _wasteFactor;
  int? _nailsLbs;

  @override
  void dispose() { _linearFeetController.dispose(); super.dispose(); }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final stockLengthFeet = int.tryParse(_stockLength) ?? 16;

    if (linearFeet == null) {
      setState(() { _piecesNeeded = null; _wasteFactor = null; _nailsLbs = null; });
      return;
    }

    // Waste factor depends on trim type
    double waste;
    switch (_trimType) {
      case 'casing': waste = 1.15; break;  // 15% for miters
      case 'baseboard': waste = 1.10; break;  // 10% for cope/miter
      case 'crown': waste = 1.20; break;  // 20% for compound miters
      case 'chair': waste = 1.10; break;  // 10% standard
      default: waste = 1.15;
    }

    final totalLF = linearFeet * waste;
    final piecesNeeded = (totalLF / stockLengthFeet).ceil();

    // Finish nails: approximately 0.5 lb per 100 LF
    final nailsLbs = (linearFeet / 100 * 0.5).ceil();

    setState(() { _piecesNeeded = piecesNeeded; _wasteFactor = waste; _nailsLbs = nailsLbs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _linearFeetController.text = '200'; setState(() { _trimType = 'casing'; _trimSize = '2-1/4'; _stockLength = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trim Lumber', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TRIM TYPE', ['casing', 'baseboard', 'crown', 'chair'], _trimType, (v) { setState(() => _trimType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STOCK LENGTH', ['8', '12', '14', '16'], _stockLength, (v) { setState(() => _stockLength = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Linear Feet Needed', unit: 'LF', controller: _linearFeetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_piecesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PIECES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_piecesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_piecesNeeded! * int.parse(_stockLength))} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Waste Factor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${((_wasteFactor! - 1) * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Finish Nails (18ga)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_nailsLbs lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTrimNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    List<String> options;
    switch (_trimType) {
      case 'casing':
        options = ['2-1/4', '2-1/2', '3-1/4'];
        break;
      case 'baseboard':
        options = ['3-1/4', '4-1/4', '5-1/4'];
        break;
      case 'crown':
        options = ['2-5/8', '3-5/8', '4-5/8'];
        break;
      case 'chair':
        options = ['1-5/8', '2-1/2', '3'];
        break;
      default:
        options = ['2-1/4', '3-1/4', '4-1/4'];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _trimSize == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _trimSize = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o"', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  String _getTrimNote() {
    switch (_trimType) {
      case 'casing': return 'Door casing: Calculate 17 LF per door (both sides + head). Miter at 45°.';
      case 'baseboard': return 'Baseboard: Wall perimeter minus door widths. Cope inside corners for best fit.';
      case 'crown': return 'Crown molding: Compound miter cuts. Order 20% extra for waste on first install.';
      case 'chair': return 'Chair rail: Standard height 32"-36" from floor. Use adhesive + nails.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'casing': 'Casing', 'baseboard': 'Base', 'crown': 'Crown', 'chair': 'Chair Rail'};
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
