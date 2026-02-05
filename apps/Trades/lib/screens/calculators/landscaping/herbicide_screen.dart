import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Herbicide Calculator - Oz per gallon mix rates
class HerbicideScreen extends ConsumerStatefulWidget {
  const HerbicideScreen({super.key});
  @override
  ConsumerState<HerbicideScreen> createState() => _HerbicideScreenState();
}

class _HerbicideScreenState extends ConsumerState<HerbicideScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _rateController = TextEditingController(text: '1.5');
  final _tankController = TextEditingController(text: '4');

  String _rateUnit = 'oz_per_gal';

  double? _totalProduct;
  double? _waterNeeded;
  int? _tankLoads;

  @override
  void dispose() { _areaController.dispose(); _rateController.dispose(); _tankController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final rate = double.tryParse(_rateController.text) ?? 1.5;
    final tankSize = double.tryParse(_tankController.text) ?? 4;

    // Standard coverage: 1 gallon per 1000 sq ft
    final gallonsNeeded = area / 1000;

    double productOz;
    if (_rateUnit == 'oz_per_gal') {
      productOz = rate * gallonsNeeded;
    } else {
      // oz per 1000 sq ft
      productOz = rate * (area / 1000);
    }

    final tankLoads = (gallonsNeeded / tankSize).ceil();

    setState(() {
      _totalProduct = productOz;
      _waterNeeded = gallonsNeeded;
      _tankLoads = tankLoads;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _rateController.text = '1.5'; _tankController.text = '4'; setState(() { _rateUnit = 'oz_per_gal'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Herbicide Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'RATE TYPE', ['oz_per_gal', 'oz_per_1000'], _rateUnit, {'oz_per_gal': 'Oz/Gallon', 'oz_per_1000': 'Oz/1000 sq ft'}, (v) { setState(() => _rateUnit = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Treatment Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Product Rate', unit: 'oz', controller: _rateController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tank Size', unit: 'gal', controller: _tankController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Always read product label. Rates vary by weed type and product concentration.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_totalProduct != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PRODUCT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalProduct!.toStringAsFixed(1)} oz', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_waterNeeded!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tank loads', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tankLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per tank load', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_totalProduct! / _tankLoads!).toStringAsFixed(1)} oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSafetyTips(colors),
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

  Widget _buildSafetyTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best temp', '60-85°F'),
        _buildTableRow(colors, 'Wind', 'Under 10 mph'),
        _buildTableRow(colors, 'Rain free', '24 hours after'),
        _buildTableRow(colors, 'Calibrate', 'Walk speed consistent'),
        _buildTableRow(colors, 'PPE', 'Gloves, long sleeves'),
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
