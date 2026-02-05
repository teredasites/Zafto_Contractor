import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Whole House Estimator - Comprehensive home renovation budget
class WholeHouseEstimatorScreen extends ConsumerStatefulWidget {
  const WholeHouseEstimatorScreen({super.key});
  @override
  ConsumerState<WholeHouseEstimatorScreen> createState() => _WholeHouseEstimatorScreenState();
}

class _WholeHouseEstimatorScreenState extends ConsumerState<WholeHouseEstimatorScreen> {
  final _sqftController = TextEditingController(text: '2000');
  final _bathroomsController = TextEditingController(text: '2');

  String _projectScope = 'cosmetic';
  String _finishLevel = 'mid';

  double? _kitchenBudget;
  double? _bathroomBudget;
  double? _flooringBudget;
  double? _paintBudget;
  double? _otherBudget;
  double? _totalBudget;
  double? _costPerSqft;

  @override
  void dispose() { _sqftController.dispose(); _bathroomsController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text) ?? 2000;
    final bathrooms = int.tryParse(_bathroomsController.text) ?? 2;

    // Cost per sq ft by scope
    double baseCostPerSqft;
    switch (_projectScope) {
      case 'cosmetic':
        baseCostPerSqft = 25; // Paint, floors, fixtures
        break;
      case 'moderate':
        baseCostPerSqft = 75; // + Kitchen/bath updates
        break;
      case 'major':
        baseCostPerSqft = 150; // + Layout changes
        break;
      case 'gut':
        baseCostPerSqft = 250; // Down to studs
        break;
      default:
        baseCostPerSqft = 75;
    }

    // Finish level multiplier
    double finishMultiplier;
    switch (_finishLevel) {
      case 'budget':
        finishMultiplier = 0.7;
        break;
      case 'mid':
        finishMultiplier = 1.0;
        break;
      case 'high':
        finishMultiplier = 1.5;
        break;
      case 'luxury':
        finishMultiplier = 2.5;
        break;
      default:
        finishMultiplier = 1.0;
    }

    final adjustedCostPerSqft = baseCostPerSqft * finishMultiplier;
    final totalBudget = sqft * adjustedCostPerSqft;

    // Budget breakdown (typical percentages)
    final kitchenBudget = totalBudget * 0.30; // 30% kitchen
    final bathroomBudget = totalBudget * 0.20 * (bathrooms / 2); // 20% base, scaled by bathroom count
    final flooringBudget = totalBudget * 0.15;
    final paintBudget = totalBudget * 0.05;
    final otherBudget = totalBudget - kitchenBudget - bathroomBudget - flooringBudget - paintBudget;

    setState(() {
      _kitchenBudget = kitchenBudget;
      _bathroomBudget = bathroomBudget;
      _flooringBudget = flooringBudget;
      _paintBudget = paintBudget;
      _otherBudget = otherBudget;
      _totalBudget = totalBudget;
      _costPerSqft = adjustedCostPerSqft;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '2000'; _bathroomsController.text = '2'; setState(() { _projectScope = 'cosmetic'; _finishLevel = 'mid'; }); _calculate(); }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
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
        title: Text('Whole House Estimator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PROJECT SCOPE', ['cosmetic', 'moderate', 'major', 'gut'], _projectScope, {'cosmetic': 'Cosmetic', 'moderate': 'Moderate', 'major': 'Major', 'gut': 'Gut Reno'}, (v) { setState(() => _projectScope = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FINISH LEVEL', ['budget', 'mid', 'high', 'luxury'], _finishLevel, {'budget': 'Budget', 'mid': 'Mid-Range', 'high': 'High-End', 'luxury': 'Luxury'}, (v) { setState(() => _finishLevel = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'House Size', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bathrooms', unit: 'qty', controller: _bathroomsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBudget != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BUDGET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_totalBudget!), style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cost Per Sq Ft', style: TextStyle(color: colors.textTertiary, fontSize: 12)), Text('\$${_costPerSqft!.toStringAsFixed(0)}/sf', style: TextStyle(color: colors.textSecondary, fontSize: 12))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Kitchen (30%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_kitchenBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bathrooms (20%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_bathroomBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Flooring (15%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_flooringBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Paint (5%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_paintBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Other (Elec, HVAC, etc.)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_otherBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add 20-25% contingency for whole house projects. Older homes may have hidden issues.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildScopeTable(colors),
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

  Widget _buildScopeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SCOPE DEFINITIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Cosmetic', 'Paint, floors, fixtures'),
        _buildTableRow(colors, 'Moderate', '+ Kitchen/bath refresh'),
        _buildTableRow(colors, 'Major', '+ Layout changes'),
        _buildTableRow(colors, 'Gut renovation', 'Down to studs'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
