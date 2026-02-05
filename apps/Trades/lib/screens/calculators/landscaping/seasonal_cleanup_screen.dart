import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Seasonal Cleanup Calculator - Spring/fall cleanup pricing
class SeasonalCleanupScreen extends ConsumerStatefulWidget {
  const SeasonalCleanupScreen({super.key});
  @override
  ConsumerState<SeasonalCleanupScreen> createState() => _SeasonalCleanupScreenState();
}

class _SeasonalCleanupScreenState extends ConsumerState<SeasonalCleanupScreen> {
  final _lawnAreaController = TextEditingController(text: '10000');
  final _bedAreaController = TextEditingController(text: '500');

  String _season = 'fall';
  String _treeCount = 'few';

  double? _laborHours;
  double? _debrisBags;
  double? _estimatedPrice;
  double? _dumpFee;

  @override
  void dispose() { _lawnAreaController.dispose(); _bedAreaController.dispose(); super.dispose(); }

  void _calculate() {
    final lawnArea = double.tryParse(_lawnAreaController.text) ?? 10000;
    final bedArea = double.tryParse(_bedAreaController.text) ?? 500;

    // Base hours per 1000 sq ft
    double hoursPerK = _season == 'fall' ? 0.4 : 0.3; // Fall takes longer

    // Tree multiplier
    double treeMult;
    switch (_treeCount) {
      case 'none':
        treeMult = 0.5;
        break;
      case 'few':
        treeMult = 1.0;
        break;
      case 'many':
        treeMult = 1.5;
        break;
      case 'heavily':
        treeMult = 2.0;
        break;
      default:
        treeMult = 1.0;
    }

    final lawnHours = (lawnArea / 1000) * hoursPerK * treeMult;
    final bedHours = (bedArea / 100) * 0.25; // 15 min per 100 sq ft beds
    final totalHours = lawnHours + bedHours;

    // Debris estimate: roughly 1 bag per 500 sq ft in fall, 1 per 1000 in spring
    final bagsPer = _season == 'fall' ? 500.0 : 1000.0;
    final bags = ((lawnArea + bedArea) / bagsPer) * treeMult;

    // Pricing: $45/hr labor + $5/bag disposal
    final laborCost = totalHours * 45;
    final dumpCost = bags * 5;
    final total = laborCost + dumpCost;

    setState(() {
      _laborHours = totalHours;
      _debrisBags = bags;
      _estimatedPrice = total;
      _dumpFee = dumpCost;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lawnAreaController.text = '10000'; _bedAreaController.text = '500'; setState(() { _season = 'fall'; _treeCount = 'few'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Seasonal Cleanup', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SEASON', ['spring', 'fall'], _season, {'spring': 'Spring', 'fall': 'Fall'}, (v) { setState(() => _season = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'TREE COVERAGE', ['none', 'few', 'many', 'heavily'], _treeCount, {'none': 'None', 'few': 'Few', 'many': 'Many', 'heavily': 'Heavy'}, (v) { setState(() => _treeCount = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _lawnAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Bed Area', unit: 'sq ft', controller: _bedAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedPrice != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ESTIMATED PRICE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_estimatedPrice!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor hours', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Debris bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_debrisBags!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Disposal fee', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_dumpFee!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCleanupGuide(colors),
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

  Widget _buildCleanupGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLEANUP CHECKLIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Spring', 'Debris, dead, thatch'),
        _buildTableRow(colors, 'Fall', 'Leaves, cutbacks, mulch'),
        _buildTableRow(colors, 'Beds', 'Weed, edge, refresh'),
        _buildTableRow(colors, 'Gutters', 'Add-on service'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
