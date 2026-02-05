import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wall Insulation Calculator - Wall cavity insulation
class WallInsulationScreen extends ConsumerStatefulWidget {
  const WallInsulationScreen({super.key});
  @override
  ConsumerState<WallInsulationScreen> createState() => _WallInsulationScreenState();
}

class _WallInsulationScreenState extends ConsumerState<WallInsulationScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _heightController = TextEditingController(text: '9');

  String _wallType = '2x6';
  String _insulation = 'batt';

  double? _wallArea;
  double? _rValue;
  int? _bagsNeeded;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final height = double.tryParse(_heightController.text);

    if (perimeter == null || height == null) {
      setState(() { _wallArea = null; _rValue = null; _bagsNeeded = null; });
      return;
    }

    final wallArea = perimeter * height;

    // R-value and coverage based on wall type and insulation
    double rValue;
    double sqftPerBag;

    switch (_wallType) {
      case '2x4':
        switch (_insulation) {
          case 'batt': rValue = 13; sqftPerBag = 106; break;
          case 'blown': rValue = 13; sqftPerBag = 80; break;
          case 'spray': rValue = 13; sqftPerBag = 100; break;
          default: rValue = 13; sqftPerBag = 106;
        }
        break;
      case '2x6':
        switch (_insulation) {
          case 'batt': rValue = 21; sqftPerBag = 75; break;
          case 'blown': rValue = 21; sqftPerBag = 60; break;
          case 'spray': rValue = 21; sqftPerBag = 100; break;
          default: rValue = 21; sqftPerBag = 75;
        }
        break;
      case '2x8':
        switch (_insulation) {
          case 'batt': rValue = 25; sqftPerBag = 60; break;
          case 'blown': rValue = 25; sqftPerBag = 45; break;
          case 'spray': rValue = 25; sqftPerBag = 100; break;
          default: rValue = 25; sqftPerBag = 60;
        }
        break;
      default:
        rValue = 21;
        sqftPerBag = 75;
    }

    // Add 5% waste
    final bagsNeeded = ((wallArea * 1.05) / sqftPerBag).ceil();

    setState(() { _wallArea = wallArea; _rValue = rValue; _bagsNeeded = bagsNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _heightController.text = '9'; setState(() { _wallType = '2x6'; _insulation = 'batt'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wall Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WALL TYPE', ['2x4', '2x6', '2x8'], _wallType, (v) { setState(() => _wallType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'INSULATION', ['batt', 'blown', 'spray'], _insulation, (v) { setState(() => _insulation = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_bagsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BAGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bagsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R-Value', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('R-${_rValue!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Fill cavities completely. Don\'t compress batts. Install vapor retarder on warm side.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'batt': 'Batt', 'blown': 'Blown', 'spray': 'Spray'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
