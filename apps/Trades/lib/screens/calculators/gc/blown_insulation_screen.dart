import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Blown Insulation Calculator - Loose-fill insulation
class BlownInsulationScreen extends ConsumerStatefulWidget {
  const BlownInsulationScreen({super.key});
  @override
  ConsumerState<BlownInsulationScreen> createState() => _BlownInsulationScreenState();
}

class _BlownInsulationScreenState extends ConsumerState<BlownInsulationScreen> {
  final _areaController = TextEditingController(text: '1500');

  String _material = 'fiberglass';
  String _rValue = 'R-38';

  int? _bagsNeeded;
  double? _depthInches;
  double? _coveragePerBag;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text);

    if (area == null) {
      setState(() { _bagsNeeded = null; _depthInches = null; _coveragePerBag = null; });
      return;
    }

    // Coverage per bag and depth varies by material and R-value
    double coveragePerBag;
    double depthInches;

    switch (_material) {
      case 'fiberglass':
        switch (_rValue) {
          case 'R-30': coveragePerBag = 40; depthInches = 10.25; break;
          case 'R-38': coveragePerBag = 26; depthInches = 13.75; break;
          case 'R-49': coveragePerBag = 19; depthInches = 17.75; break;
          case 'R-60': coveragePerBag = 15; depthInches = 21.5; break;
          default: coveragePerBag = 26; depthInches = 13.75;
        }
        break;
      case 'cellulose':
        switch (_rValue) {
          case 'R-30': coveragePerBag = 36; depthInches = 8.0; break;
          case 'R-38': coveragePerBag = 27; depthInches = 10.25; break;
          case 'R-49': coveragePerBag = 20; depthInches = 13.0; break;
          case 'R-60': coveragePerBag = 16; depthInches = 16.0; break;
          default: coveragePerBag = 27; depthInches = 10.25;
        }
        break;
      case 'mineral':
        switch (_rValue) {
          case 'R-30': coveragePerBag = 35; depthInches = 9.0; break;
          case 'R-38': coveragePerBag = 25; depthInches = 11.5; break;
          case 'R-49': coveragePerBag = 18; depthInches = 15.0; break;
          case 'R-60': coveragePerBag = 14; depthInches = 18.5; break;
          default: coveragePerBag = 25; depthInches = 11.5;
        }
        break;
      default:
        coveragePerBag = 26;
        depthInches = 13.75;
    }

    final bagsNeeded = (area / coveragePerBag).ceil();

    setState(() { _bagsNeeded = bagsNeeded; _depthInches = depthInches; _coveragePerBag = coveragePerBag; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '1500'; setState(() { _material = 'fiberglass'; _rValue = 'R-38'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Blown Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['fiberglass', 'cellulose', 'mineral'], _material, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'R-VALUE', ['R-30', 'R-38', 'R-49', 'R-60'], _rValue, (v) { setState(() => _rValue = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Attic Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bagsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BAGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bagsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Installed Depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_depthInches!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage per Bag', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coveragePerBag!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getMaterialNote() {
    switch (_material) {
      case 'fiberglass': return 'Fiberglass: Non-combustible. Mark depth rulers before blowing. Keep away from can lights.';
      case 'cellulose': return 'Cellulose: Recycled paper, fire-treated. Settles 15-20% over time. Denser = better R.';
      case 'mineral': return 'Mineral wool: Fire resistant, sound absorption. Heavier than fiberglass.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'fiberglass': 'Fiberglass', 'cellulose': 'Cellulose', 'mineral': 'Mineral'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
