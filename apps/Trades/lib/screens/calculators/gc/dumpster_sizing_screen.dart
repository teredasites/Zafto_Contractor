import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dumpster Sizing Calculator - Roll-off container selection
class DumpsterSizingScreen extends ConsumerStatefulWidget {
  const DumpsterSizingScreen({super.key});
  @override
  ConsumerState<DumpsterSizingScreen> createState() => _DumpsterSizingScreenState();
}

class _DumpsterSizingScreenState extends ConsumerState<DumpsterSizingScreen> {
  final _cubicYardsController = TextEditingController(text: '30');

  String _project = 'remodel';
  String _material = 'mixed';

  String? _recommendedSize;
  int? _dumpsterQty;
  double? _weightLimit;

  @override
  void dispose() { _cubicYardsController.dispose(); super.dispose(); }

  void _calculate() {
    final cubicYards = double.tryParse(_cubicYardsController.text);

    if (cubicYards == null) {
      setState(() { _recommendedSize = null; _dumpsterQty = null; _weightLimit = null; });
      return;
    }

    // Weight limits per material type (tons)
    double tonsPerCY;
    switch (_material) {
      case 'concrete': tonsPerCY = 1.5; break;
      case 'roofing': tonsPerCY = 0.35; break;
      case 'mixed': tonsPerCY = 0.2; break;
      case 'drywall': tonsPerCY = 0.25; break;
      default: tonsPerCY = 0.2;
    }

    // Determine best dumpster size
    String recommendedSize;
    int capacity;
    double weightLimit;

    if (cubicYards <= 10) {
      recommendedSize = '10 Yard';
      capacity = 10;
      weightLimit = 2;
    } else if (cubicYards <= 15) {
      recommendedSize = '15 Yard';
      capacity = 15;
      weightLimit = 3;
    } else if (cubicYards <= 20) {
      recommendedSize = '20 Yard';
      capacity = 20;
      weightLimit = 4;
    } else if (cubicYards <= 30) {
      recommendedSize = '30 Yard';
      capacity = 30;
      weightLimit = 5;
    } else {
      recommendedSize = '40 Yard';
      capacity = 40;
      weightLimit = 6;
    }

    // Check if weight limit is issue
    final estimatedWeight = cubicYards * tonsPerCY;
    if (_material == 'concrete' && estimatedWeight > weightLimit) {
      // Need smaller loads for heavy material
      final maxCYByWeight = weightLimit / tonsPerCY;
      capacity = maxCYByWeight.floor();
      if (capacity <= 10) recommendedSize = '10 Yard (weight limited)';
      else if (capacity <= 15) recommendedSize = '15 Yard (weight limited)';
      else recommendedSize = '20 Yard (weight limited)';
    }

    final dumpsterQty = (cubicYards / capacity).ceil();

    setState(() { _recommendedSize = recommendedSize; _dumpsterQty = dumpsterQty; _weightLimit = weightLimit; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _cubicYardsController.text = '30'; setState(() { _project = 'remodel'; _material = 'mixed'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dumpster Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL TYPE', ['mixed', 'concrete', 'roofing', 'drywall'], _material, {'mixed': 'Mixed', 'concrete': 'Concrete', 'roofing': 'Roofing', 'drywall': 'Drywall'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Debris Volume', unit: 'cubic yards', controller: _cubicYardsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_recommendedSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 22, fontWeight: FontWeight.w700)))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Dumpsters Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_dumpsterQty', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weight Limit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weightLimit!.toStringAsFixed(0)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Concrete/heavy debris has weight limits. Overage fees apply. Level load - no overflow.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DUMPSTER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '10 Yard', '12x8x3.5 ft, 2 ton'),
        _buildTableRow(colors, '15 Yard', '16x8x4 ft, 3 ton'),
        _buildTableRow(colors, '20 Yard', '22x8x4 ft, 4 ton'),
        _buildTableRow(colors, '30 Yard', '22x8x6 ft, 5 ton'),
        _buildTableRow(colors, '40 Yard', '22x8x8 ft, 6 ton'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }
}
