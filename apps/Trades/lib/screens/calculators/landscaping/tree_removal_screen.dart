import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Removal Estimator - Cost factors
class TreeRemovalScreen extends ConsumerStatefulWidget {
  const TreeRemovalScreen({super.key});
  @override
  ConsumerState<TreeRemovalScreen> createState() => _TreeRemovalScreenState();
}

class _TreeRemovalScreenState extends ConsumerState<TreeRemovalScreen> {
  final _diameterController = TextEditingController(text: '24');
  final _heightController = TextEditingController(text: '40');

  String _access = 'easy';
  bool _stumpRemoval = true;

  double? _baseCost;
  double? _stumpCost;
  double? _totalCost;
  String? _difficulty;

  @override
  void dispose() { _diameterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final diameter = double.tryParse(_diameterController.text) ?? 24;
    final height = double.tryParse(_heightController.text) ?? 40;

    // Base cost per inch of diameter
    double costPerInch;
    String difficulty;
    switch (_access) {
      case 'easy':
        costPerInch = 20;
        difficulty = 'Standard';
        break;
      case 'moderate':
        costPerInch = 30;
        difficulty = 'Moderate';
        break;
      case 'difficult':
        costPerInch = 45;
        difficulty = 'Difficult';
        break;
      default:
        costPerInch = 25;
        difficulty = 'Standard';
    }

    // Adjust for height
    if (height > 50) {
      costPerInch *= 1.25;
    } else if (height > 75) {
      costPerInch *= 1.5;
    }

    final baseCost = diameter * costPerInch;

    // Stump grinding: ~$3-5 per inch diameter
    final stumpCost = _stumpRemoval ? diameter * 4 : 0.0;

    final total = baseCost + stumpCost;

    setState(() {
      _baseCost = baseCost;
      _stumpCost = stumpCost;
      _totalCost = total;
      _difficulty = difficulty;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _diameterController.text = '24'; _heightController.text = '40'; setState(() { _access = 'easy'; _stumpRemoval = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Removal', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SITE ACCESS', ['easy', 'moderate', 'difficult'], _access, {'easy': 'Easy', 'moderate': 'Moderate', 'difficult': 'Difficult'}, (v) { setState(() => _access = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trunk Diameter', unit: 'in', controller: _diameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Include stump grinding', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() { _stumpRemoval = !_stumpRemoval; }); _calculate(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _stumpRemoval ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _stumpRemoval ? colors.accentPrimary : colors.borderSubtle)),
                  child: Text(_stumpRemoval ? 'Yes' : 'No', style: TextStyle(color: _stumpRemoval ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            if (_totalCost != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ESTIMATE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tree removal', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_baseCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_stumpRemoval) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stump grinding', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_stumpCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Difficulty', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_difficulty', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Estimates vary by region. Get multiple quotes.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 20),
            _buildFactorsGuide(colors),
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

  Widget _buildFactorsGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COST FACTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small (<30\")', '\$150-400'),
        _buildTableRow(colors, 'Medium (30-60\")', '\$400-1,000'),
        _buildTableRow(colors, 'Large (60\"+)', '\$1,000-2,500+'),
        _buildTableRow(colors, 'Crane needed', '+\$500-2,000'),
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
