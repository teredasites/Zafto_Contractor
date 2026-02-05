import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Foam Board Calculator - Rigid insulation sheathing
class FoamBoardScreen extends ConsumerStatefulWidget {
  const FoamBoardScreen({super.key});
  @override
  ConsumerState<FoamBoardScreen> createState() => _FoamBoardScreenState();
}

class _FoamBoardScreenState extends ConsumerState<FoamBoardScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');

  String _foamType = 'xps';
  String _thickness = '1';
  String _application = 'wall';

  double? _coverageArea;
  int? _sheetsNeeded;
  double? _rValue;
  int? _tapeRolls;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);

    if (length == null || width == null) {
      setState(() { _coverageArea = null; _sheetsNeeded = null; _rValue = null; _tapeRolls = null; });
      return;
    }

    double coverageArea;
    if (_application == 'wall') {
      // Wall: perimeter * assumed 9' height
      coverageArea = (length + width) * 2 * 9;
    } else {
      // Foundation/roof: area
      coverageArea = length * width;
    }

    // 4x8 sheet = 32 sq ft, add 10% waste
    final sheetsNeeded = ((coverageArea / 32) * 1.10).ceil();

    // R-value per inch by foam type
    double rPerInch;
    switch (_foamType) {
      case 'eps': rPerInch = 3.8; break;   // Expanded polystyrene
      case 'xps': rPerInch = 5.0; break;   // Extruded polystyrene
      case 'polyiso': rPerInch = 6.0; break; // Polyisocyanurate
      default: rPerInch = 5.0;
    }

    final thicknessNum = double.tryParse(_thickness) ?? 1.0;
    final rValue = rPerInch * thicknessNum;

    // Tape: seams roughly every 4' both directions
    final seamLength = (coverageArea / 4) * 2; // Rough estimate
    final tapeRolls = (seamLength / 50).ceil(); // 50 LF per roll

    setState(() { _coverageArea = coverageArea; _sheetsNeeded = sheetsNeeded; _rValue = rValue; _tapeRolls = tapeRolls; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; setState(() { _foamType = 'xps'; _thickness = '1'; _application = 'wall'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Foam Board', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FOAM TYPE', ['eps', 'xps', 'polyiso'], _foamType, (v) { setState(() => _foamType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'THICKNESS', ['1/2', '1', '1-1/2', '2'], _thickness, (v) { setState(() => _thickness = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'APPLICATION', ['wall', 'foundation', 'roof'], _application, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sheetsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHEETS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sheetsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverageArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R-Value', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('R-${_rValue!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tape Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tapeRolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getFoamNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getFoamNote() {
    switch (_foamType) {
      case 'eps': return 'EPS (white beadboard): Economical, permeable. Not for below-grade contact.';
      case 'xps': return 'XPS (pink/blue board): Water resistant. Good for below-grade and under slabs.';
      case 'polyiso': return 'Polyiso: Highest R per inch but loses R in cold. Use above grade only.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'eps': 'EPS', 'xps': 'XPS', 'polyiso': 'Polyiso', 'wall': 'Wall', 'foundation': 'Foundation', 'roof': 'Roof'};
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
