import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Attic Insulation Calculator - Attic insulation requirements
class AtticInsulationScreen extends ConsumerStatefulWidget {
  const AtticInsulationScreen({super.key});
  @override
  ConsumerState<AtticInsulationScreen> createState() => _AtticInsulationScreenState();
}

class _AtticInsulationScreenState extends ConsumerState<AtticInsulationScreen> {
  final _areaController = TextEditingController(text: '1500');
  final _existingRController = TextEditingController(text: '11');

  String _targetR = 'R-49';
  String _addMethod = 'blown';

  double? _rValueNeeded;
  double? _depthToAdd;
  int? _bagsNeeded;

  @override
  void dispose() { _areaController.dispose(); _existingRController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final existingR = double.tryParse(_existingRController.text) ?? 0;

    if (area == null) {
      setState(() { _rValueNeeded = null; _depthToAdd = null; _bagsNeeded = null; });
      return;
    }

    // Target R-value
    double targetRValue;
    switch (_targetR) {
      case 'R-38': targetRValue = 38; break;
      case 'R-49': targetRValue = 49; break;
      case 'R-60': targetRValue = 60; break;
      default: targetRValue = 49;
    }

    final rValueNeeded = (targetRValue - existingR).clamp(0, 100);

    // Depth and bags based on method
    double rPerInch;
    double sqftPerBag;
    switch (_addMethod) {
      case 'blown':
        rPerInch = 2.5;  // Blown fiberglass
        sqftPerBag = 26; // At R-38
        break;
      case 'batts':
        rPerInch = 3.2;  // Fiberglass batts
        sqftPerBag = 75; // Per bag coverage
        break;
      case 'cellulose':
        rPerInch = 3.7;  // Cellulose
        sqftPerBag = 27;
        break;
      default:
        rPerInch = 2.5;
        sqftPerBag = 26;
    }

    final depthToAdd = rValueNeeded / rPerInch;

    // Adjust coverage for actual R needed vs R-38 reference
    final adjustedCoverage = sqftPerBag * (38 / (rValueNeeded > 0 ? rValueNeeded : 38));
    final bagsNeeded = rValueNeeded > 0 ? (area / adjustedCoverage).ceil() : 0;

    setState(() { _rValueNeeded = rValueNeeded.toDouble(); _depthToAdd = depthToAdd; _bagsNeeded = bagsNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '1500'; _existingRController.text = '11'; setState(() { _targetR = 'R-49'; _addMethod = 'blown'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Attic Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TARGET R-VALUE', ['R-38', 'R-49', 'R-60'], _targetR, (v) { setState(() => _targetR = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'ADD METHOD', ['blown', 'batts', 'cellulose'], _addMethod, (v) { setState(() => _addMethod = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Attic Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Existing R', unit: 'R-value', controller: _existingRController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rValueNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BAGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bagsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R-Value to Add', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('R-${_rValueNeeded!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Depth to Add', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_depthToAdd!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_rValueNeeded! <= 0 ? 'Already meets target R-value!' : 'Install perpendicular to existing batts. Air seal penetrations first for best results.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'blown': 'Blown FG', 'batts': 'Batts', 'cellulose': 'Cellulose'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
