import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Kitchen Remodel Budget Calculator - Kitchen renovation budget estimation
class KitchenRemodelBudgetScreen extends ConsumerStatefulWidget {
  const KitchenRemodelBudgetScreen({super.key});
  @override
  ConsumerState<KitchenRemodelBudgetScreen> createState() => _KitchenRemodelBudgetScreenState();
}

class _KitchenRemodelBudgetScreenState extends ConsumerState<KitchenRemodelBudgetScreen> {
  final _sqftController = TextEditingController(text: '150');
  final _cabinetLfController = TextEditingController(text: '25');

  String _finishLevel = 'mid';
  String _layoutChange = 'none';

  double? _cabinetBudget;
  double? _countertopBudget;
  double? _applianceBudget;
  double? _laborBudget;
  double? _totalBudget;

  @override
  void dispose() { _sqftController.dispose(); _cabinetLfController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text) ?? 150;
    final cabinetLf = double.tryParse(_cabinetLfController.text) ?? 25;

    // Cost per LF of cabinets by finish level
    double cabinetCostPerLf;
    double countertopCostPerSqft;
    double appliancePackage;
    double laborMultiplier;

    switch (_finishLevel) {
      case 'budget':
        cabinetCostPerLf = 150; // Stock cabinets
        countertopCostPerSqft = 40; // Laminate
        appliancePackage = 2500;
        laborMultiplier = 0.3;
        break;
      case 'mid':
        cabinetCostPerLf = 350; // Semi-custom
        countertopCostPerSqft = 75; // Granite/quartz
        appliancePackage = 5000;
        laborMultiplier = 0.4;
        break;
      case 'high':
        cabinetCostPerLf = 650; // Custom
        countertopCostPerSqft = 125; // Premium stone
        appliancePackage = 12000;
        laborMultiplier = 0.5;
        break;
      case 'luxury':
        cabinetCostPerLf = 1200; // Fully custom
        countertopCostPerSqft = 200; // Exotic stone
        appliancePackage = 25000;
        laborMultiplier = 0.6;
        break;
      default:
        cabinetCostPerLf = 350;
        countertopCostPerSqft = 75;
        appliancePackage = 5000;
        laborMultiplier = 0.4;
    }

    // Layout change cost adder
    double layoutAdder = 0;
    switch (_layoutChange) {
      case 'minor':
        layoutAdder = 3000; // Move one appliance
        break;
      case 'major':
        layoutAdder = 8000; // Move plumbing/gas
        break;
      case 'walls':
        layoutAdder = 15000; // Remove/add walls
        break;
    }

    // Calculate budgets
    final cabinetBudget = cabinetLf * cabinetCostPerLf;
    final countertopSqft = cabinetLf * 2; // ~2 sq ft per LF of base
    final countertopBudget = countertopSqft * countertopCostPerSqft;
    final applianceBudget = appliancePackage;

    final materialTotal = cabinetBudget + countertopBudget + applianceBudget + layoutAdder;
    final laborBudget = materialTotal * laborMultiplier;
    final totalBudget = materialTotal + laborBudget;

    setState(() {
      _cabinetBudget = cabinetBudget;
      _countertopBudget = countertopBudget;
      _applianceBudget = applianceBudget;
      _laborBudget = laborBudget;
      _totalBudget = totalBudget;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '150'; _cabinetLfController.text = '25'; setState(() { _finishLevel = 'mid'; _layoutChange = 'none'; }); _calculate(); }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Kitchen Remodel Budget', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FINISH LEVEL', ['budget', 'mid', 'high', 'luxury'], _finishLevel, {'budget': 'Budget', 'mid': 'Mid-Range', 'high': 'High-End', 'luxury': 'Luxury'}, (v) { setState(() => _finishLevel = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'LAYOUT CHANGE', ['none', 'minor', 'major', 'walls'], _layoutChange, {'none': 'None', 'minor': 'Minor', 'major': 'Major', 'walls': 'Walls'}, (v) { setState(() => _layoutChange = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Kitchen Size', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cabinet Run', unit: 'LF', controller: _cabinetLfController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBudget != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BUDGET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_totalBudget!), style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cabinets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_cabinetBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Countertops', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_countertopBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Appliances', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_applianceBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_laborBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add 10-20% contingency for unknowns. Permits, design fees, and temporary kitchen not included.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCostTable(colors),
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

  Widget _buildCostTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL COST RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Budget remodel', '\$15k-30k'),
        _buildTableRow(colors, 'Mid-range remodel', '\$30k-60k'),
        _buildTableRow(colors, 'High-end remodel', '\$60k-100k'),
        _buildTableRow(colors, 'Luxury remodel', '\$100k+'),
        _buildTableRow(colors, 'Cost per sq ft', '\$150-500'),
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
