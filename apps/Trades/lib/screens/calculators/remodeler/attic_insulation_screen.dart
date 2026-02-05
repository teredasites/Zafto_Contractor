import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Attic Insulation Calculator - Blown/batt insulation estimation
class AtticInsulationScreen extends ConsumerStatefulWidget {
  const AtticInsulationScreen({super.key});
  @override
  ConsumerState<AtticInsulationScreen> createState() => _AtticInsulationScreenState();
}

class _AtticInsulationScreenState extends ConsumerState<AtticInsulationScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _currentRController = TextEditingController(text: '11');

  String _type = 'blown';
  String _targetR = 'r49';

  double? _sqft;
  int? _bags;
  int? _batts;
  double? _depthNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _currentRController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final currentR = double.tryParse(_currentRController.text) ?? 0;

    final sqft = length * width;

    // Target R-value
    double targetRValue;
    switch (_targetR) {
      case 'r38':
        targetRValue = 38;
        break;
      case 'r49':
        targetRValue = 49;
        break;
      case 'r60':
        targetRValue = 60;
        break;
      default:
        targetRValue = 49;
    }

    final rNeeded = targetRValue - currentR;

    // Blown fiberglass: ~2.5 R per inch, ~30 sqft coverage per bag at R-30
    // Blown cellulose: ~3.5 R per inch, ~40 sqft coverage per bag at R-30
    double depthNeeded;
    int bags;
    int batts;

    if (_type == 'blown') {
      depthNeeded = rNeeded / 2.8; // Average blown insulation
      final bagsCoverage = 30.0; // sqft per bag at moderate depth
      bags = (sqft / bagsCoverage * (rNeeded / 30)).ceil();
      batts = 0;
    } else {
      // Batts: R-30 = 10", R-38 = 12", R-49 = 16"
      depthNeeded = rNeeded / 3.0; // Approximate
      bags = 0;
      // Batts: typically 15" wide, cover 40 sqft per package
      batts = (sqft / 40).ceil();
    }

    setState(() { _sqft = sqft; _bags = bags; _batts = batts; _depthNeeded = depthNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; _currentRController.text = '11'; setState(() { _type = 'blown'; _targetR = 'r49'; }); _calculate(); }

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
            _buildSelector(colors, 'TYPE', ['blown', 'batt'], _type, {'blown': 'Blown-In', 'batt': 'Batts'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TARGET R-VALUE', ['r38', 'r49', 'r60'], _targetR, {'r38': 'R-38', 'r49': 'R-49', 'r60': 'R-60'}, (v) { setState(() => _targetR = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Attic Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Attic Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current R-Value', unit: 'R', controller: _currentRController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_type == 'blown' ? 'BAGS NEEDED' : 'BATT PACKAGES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_type == 'blown' ? '~$_bags' : '~$_batts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Attic Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Depth to Add', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_depthNeeded!.toStringAsFixed(1)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Maintain ventilation! Don\'t block soffit vents. Use baffles at eaves. R-49 is DOE recommended.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRValueTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildRValueTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CURRENT INSULATION DEPTH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '3-4\" fiberglass', '~R-11'),
        _buildTableRow(colors, '6-7\" fiberglass', '~R-19'),
        _buildTableRow(colors, '10\" fiberglass', '~R-30'),
        _buildTableRow(colors, '14\" fiberglass', '~R-38'),
        _buildTableRow(colors, '18\"+ fiberglass', '~R-49'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
