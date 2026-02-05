import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Irrigation Cost Calculator - Water usage and cost
class IrrigationCostScreen extends ConsumerStatefulWidget {
  const IrrigationCostScreen({super.key});
  @override
  ConsumerState<IrrigationCostScreen> createState() => _IrrigationCostScreenState();
}

class _IrrigationCostScreenState extends ConsumerState<IrrigationCostScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _rateController = TextEditingController(text: '4.50');
  final _depthController = TextEditingController(text: '1.0');

  String _frequency = 'weekly';

  double? _gallonsPerWatering;
  double? _monthlyGallons;
  double? _monthlyCost;
  double? _seasonCost;

  @override
  void dispose() { _areaController.dispose(); _rateController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final ratePer1000 = double.tryParse(_rateController.text) ?? 4.50;
    final depthIn = double.tryParse(_depthController.text) ?? 1.0;

    // Gallons per watering: area * depth * 0.623 gal/sq ft/in
    final gallonsPerWater = area * depthIn * 0.623;

    // Waterings per month
    double wateringsPerMonth;
    switch (_frequency) {
      case 'daily':
        wateringsPerMonth = 30;
        break;
      case 'every_other':
        wateringsPerMonth = 15;
        break;
      case 'twice_weekly':
        wateringsPerMonth = 8.6;
        break;
      case 'weekly':
        wateringsPerMonth = 4.3;
        break;
      default:
        wateringsPerMonth = 4.3;
    }

    final monthlyGal = gallonsPerWater * wateringsPerMonth;
    final monthlyCost = (monthlyGal / 1000) * ratePer1000;
    final seasonCost = monthlyCost * 6; // 6-month season

    setState(() {
      _gallonsPerWatering = gallonsPerWater;
      _monthlyGallons = monthlyGal;
      _monthlyCost = monthlyCost;
      _seasonCost = seasonCost;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _rateController.text = '4.50'; _depthController.text = '1.0'; setState(() { _frequency = 'weekly'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Irrigation Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WATERING FREQUENCY', ['daily', 'every_other', 'twice_weekly', 'weekly'], _frequency, {'daily': 'Daily', 'every_other': 'Every Other', 'twice_weekly': '2x Week', 'weekly': 'Weekly'}, (v) { setState(() => _frequency = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Water Rate', unit: '\$/1000 gal', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Water Depth', unit: 'in', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_monthlyCost != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MONTHLY COST', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_monthlyCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per watering', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_gallonsPerWatering! / 1000).toStringAsFixed(1)}K gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Monthly usage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_monthlyGallons! / 1000).toStringAsFixed(1)}K gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('6-month season', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_seasonCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCostGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCostGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WATER SAVING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best time', 'Early morning'),
        _buildTableRow(colors, 'Depth needed', '1\" per week'),
        _buildTableRow(colors, 'Rain sensor', 'Saves 20-30%'),
        _buildTableRow(colors, 'Smart controller', 'Saves 15-25%'),
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
