import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Waterproofing Calculator - Foundation/deck waterproofing
class WaterproofingScreen extends ConsumerStatefulWidget {
  const WaterproofingScreen({super.key});
  @override
  ConsumerState<WaterproofingScreen> createState() => _WaterproofingScreenState();
}

class _WaterproofingScreenState extends ConsumerState<WaterproofingScreen> {
  final _lengthController = TextEditingController(text: '120');
  final _heightController = TextEditingController(text: '8');

  String _application = 'foundation';
  String _product = 'membrane';

  double? _sqft;
  double? _gallons;
  double? _rollsNeeded;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final height = double.tryParse(_heightController.text);

    if (length == null || height == null) {
      setState(() { _sqft = null; _gallons = null; _rollsNeeded = null; });
      return;
    }

    final sqft = length * height;

    double gallons = 0;
    double rollsNeeded = 0;

    switch (_product) {
      case 'membrane':
        // Self-adhering membrane: 200 sqft per roll
        rollsNeeded = (sqft / 200).ceil().toDouble();
        gallons = 0;
        break;
      case 'coating':
        // Liquid coating: 50-100 sqft per gallon (2 coats)
        gallons = (sqft / 75) * 2;
        rollsNeeded = 0;
        break;
      case 'spray':
        // Spray-applied: 100 sqft per gallon
        gallons = sqft / 100;
        rollsNeeded = 0;
        break;
      case 'dimple':
        // Dimple board: 300 sqft per roll
        rollsNeeded = (sqft / 300).ceil().toDouble();
        gallons = 0;
        break;
    }

    setState(() { _sqft = sqft; _gallons = gallons; _rollsNeeded = rollsNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '120'; _heightController.text = '8'; setState(() { _application = 'foundation'; _product = 'membrane'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Waterproofing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['foundation', 'deck', 'shower', 'roof'], _application, {'foundation': 'Foundation', 'deck': 'Deck', 'shower': 'Shower', 'roof': 'Roof'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PRODUCT TYPE', ['membrane', 'coating', 'spray', 'dimple'], _product, {'membrane': 'Membrane', 'coating': 'Coating', 'spray': 'Spray', 'dimple': 'Dimple Bd'}, (v) { setState(() => _product = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length/Perimeter', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height/Width', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COVERAGE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_rollsNeeded! > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rolls Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rollsNeeded!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_gallons! > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gallons Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Overlap seams 4-6". Extend above grade 4-6". Allow cure time before backfill.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildProductTable(colors),
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

  Widget _buildProductTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WATERPROOFING TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Membrane', 'Self-adhering, peel & stick'),
        _buildTableRow(colors, 'Coating', 'Brush/roll applied liquid'),
        _buildTableRow(colors, 'Spray', 'Spray-applied elastomeric'),
        _buildTableRow(colors, 'Dimple board', 'Drainage mat protection'),
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
