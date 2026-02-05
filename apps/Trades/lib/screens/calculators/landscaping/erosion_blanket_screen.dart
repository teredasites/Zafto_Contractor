import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Erosion Blanket Calculator - Coverage for slopes
class ErosionBlanketScreen extends ConsumerStatefulWidget {
  const ErosionBlanketScreen({super.key});
  @override
  ConsumerState<ErosionBlanketScreen> createState() => _ErosionBlanketScreenState();
}

class _ErosionBlanketScreenState extends ConsumerState<ErosionBlanketScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '20');

  String _blanketType = 'straw';
  double _overlapPercent = 6;

  double? _areaSqFt;
  double? _totalWithOverlap;
  double? _rollsNeeded;
  int? _stakesNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final width = double.tryParse(_widthController.text) ?? 20;

    final area = length * width;
    final overlapMultiplier = 1 + (_overlapPercent / 100);
    final totalArea = area * overlapMultiplier;

    // Roll sizes vary by type
    double rollSqFt;
    switch (_blanketType) {
      case 'straw':
        rollSqFt = 8 * 112.5; // 8' × 112.5'
        break;
      case 'coir':
        rollSqFt = 6.5 * 82; // 6.5' × 82'
        break;
      case 'excelsior':
        rollSqFt = 8 * 90; // 8' × 90'
        break;
      default:
        rollSqFt = 8 * 112.5;
    }

    final rolls = totalArea / rollSqFt;

    // Stakes: 1 per 3 sq ft on slopes
    final stakes = (totalArea / 3).ceil();

    setState(() {
      _areaSqFt = area;
      _totalWithOverlap = totalArea;
      _rollsNeeded = rolls;
      _stakesNeeded = stakes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '20'; setState(() { _blanketType = 'straw'; _overlapPercent = 6; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Erosion Blanket', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BLANKET TYPE', ['straw', 'coir', 'excelsior'], _blanketType, {'straw': 'Straw', 'coir': 'Coir/Jute', 'excelsior': 'Excelsior'}, (v) { setState(() => _blanketType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Slope Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Slope Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('Overlap:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _overlapPercent, min: 3, max: 12, divisions: 3, label: '${_overlapPercent.toInt()}%', onChanged: (v) { setState(() => _overlapPercent = v); _calculate(); })),
              Text('${_overlapPercent.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_rollsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROLLS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rollsNeeded!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slope area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('With overlap', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalWithOverlap!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_stakesNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBlanketGuide(colors),
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

  Widget _buildBlanketGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BLANKET SELECTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Straw', '1-2 yr, light slopes'),
        _buildTableRow(colors, 'Coir/Jute', '2-5 yr, moderate'),
        _buildTableRow(colors, 'Excelsior', '1-2 yr, heavy flow'),
        _buildTableRow(colors, 'Stakes', '6" steel, every 3 ft'),
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
