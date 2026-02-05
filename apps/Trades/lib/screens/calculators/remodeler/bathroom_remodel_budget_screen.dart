import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bathroom Remodel Budget Calculator - Bathroom renovation budget estimation
class BathroomRemodelBudgetScreen extends ConsumerStatefulWidget {
  const BathroomRemodelBudgetScreen({super.key});
  @override
  ConsumerState<BathroomRemodelBudgetScreen> createState() => _BathroomRemodelBudgetScreenState();
}

class _BathroomRemodelBudgetScreenState extends ConsumerState<BathroomRemodelBudgetScreen> {
  final _sqftController = TextEditingController(text: '50');

  String _bathroomType = 'full';
  String _finishLevel = 'mid';
  bool _moveFixtures = false;

  double? _fixturesBudget;
  double? _tileBudget;
  double? _vanityBudget;
  double? _laborBudget;
  double? _totalBudget;

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text) ?? 50;

    // Base costs by bathroom type
    double fixtureBase;
    double tileMultiplier;
    switch (_bathroomType) {
      case 'half':
        fixtureBase = 1500; // Toilet + sink only
        tileMultiplier = 0.5;
        break;
      case 'full':
        fixtureBase = 3000; // Toilet + sink + tub/shower
        tileMultiplier = 1.0;
        break;
      case 'master':
        fixtureBase = 5000; // Toilet + double sink + shower + tub
        tileMultiplier = 1.5;
        break;
      default:
        fixtureBase = 3000;
        tileMultiplier = 1.0;
    }

    // Finish level multipliers
    double finishMultiplier;
    double tileCostPerSqft;
    double vanityCost;
    switch (_finishLevel) {
      case 'budget':
        finishMultiplier = 0.7;
        tileCostPerSqft = 8;
        vanityCost = 400;
        break;
      case 'mid':
        finishMultiplier = 1.0;
        tileCostPerSqft = 15;
        vanityCost = 1200;
        break;
      case 'high':
        finishMultiplier = 1.5;
        tileCostPerSqft = 30;
        vanityCost = 3000;
        break;
      case 'luxury':
        finishMultiplier = 2.5;
        tileCostPerSqft = 50;
        vanityCost = 6000;
        break;
      default:
        finishMultiplier = 1.0;
        tileCostPerSqft = 15;
        vanityCost = 1200;
    }

    // Moving fixtures adds significant cost
    final moveFixtureCost = _moveFixtures ? 3000 : 0;

    // Calculate budgets
    final fixturesBudget = fixtureBase * finishMultiplier;
    // Tile floor + walls (walls ~2x floor area for wet areas)
    final tileArea = sqft + (sqft * 2 * tileMultiplier);
    final tileBudget = tileArea * tileCostPerSqft;
    final vanityBudget = vanityCost * (_bathroomType == 'master' ? 1.5 : 1.0);

    final materialTotal = fixturesBudget + tileBudget + vanityBudget + moveFixtureCost;
    final laborBudget = materialTotal * 0.5; // Bathroom labor ~50% of materials
    final totalBudget = materialTotal + laborBudget;

    setState(() {
      _fixturesBudget = fixturesBudget;
      _tileBudget = tileBudget;
      _vanityBudget = vanityBudget;
      _laborBudget = laborBudget;
      _totalBudget = totalBudget;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '50'; setState(() { _bathroomType = 'full'; _finishLevel = 'mid'; _moveFixtures = false; }); _calculate(); }

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
        title: Text('Bathroom Remodel Budget', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BATHROOM TYPE', ['half', 'full', 'master'], _bathroomType, {'half': 'Half Bath', 'full': 'Full Bath', 'master': 'Master'}, (v) { setState(() => _bathroomType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FINISH LEVEL', ['budget', 'mid', 'high', 'luxury'], _finishLevel, {'budget': 'Budget', 'mid': 'Mid-Range', 'high': 'High-End', 'luxury': 'Luxury'}, (v) { setState(() => _finishLevel = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Moving Plumbing Fixtures', _moveFixtures, (v) { setState(() => _moveFixtures = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Bathroom Size', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalBudget != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BUDGET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_totalBudget!), style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fixtures', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_fixturesBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tile & Flooring', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_tileBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Vanity & Mirror', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_vanityBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_laborBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add 15-20% contingency. Hidden water damage common in bathroom remodels.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildCostTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL COST RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Half bath budget', '\$3k-6k'),
        _buildTableRow(colors, 'Full bath mid-range', '\$15k-30k'),
        _buildTableRow(colors, 'Master bath high-end', '\$40k-75k'),
        _buildTableRow(colors, 'Luxury master', '\$75k+'),
        _buildTableRow(colors, 'Cost per sq ft', '\$200-600'),
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
