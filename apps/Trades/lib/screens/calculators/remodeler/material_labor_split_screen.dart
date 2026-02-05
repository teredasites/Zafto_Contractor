import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Material vs Labor Split Calculator - Budget allocation by project type
class MaterialLaborSplitScreen extends ConsumerStatefulWidget {
  const MaterialLaborSplitScreen({super.key});
  @override
  ConsumerState<MaterialLaborSplitScreen> createState() => _MaterialLaborSplitScreenState();
}

class _MaterialLaborSplitScreenState extends ConsumerState<MaterialLaborSplitScreen> {
  final _totalBudgetController = TextEditingController(text: '50000');

  String _projectType = 'kitchen';

  double? _materialBudget;
  double? _laborBudget;
  double? _materialPercent;
  double? _laborPercent;
  String? _projectNote;

  @override
  void dispose() { _totalBudgetController.dispose(); super.dispose(); }

  void _calculate() {
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 50000;

    // Material/Labor splits by project type (industry averages)
    double materialPercent;
    String projectNote;
    switch (_projectType) {
      case 'kitchen':
        materialPercent = 0.60; // 60% materials (cabinets, appliances)
        projectNote = 'Kitchen remodels are material-heavy due to cabinets and appliances.';
        break;
      case 'bathroom':
        materialPercent = 0.50; // 50/50 typical
        projectNote = 'Bathrooms balance materials with skilled labor for tile and plumbing.';
        break;
      case 'flooring':
        materialPercent = 0.55; // 55% materials
        projectNote = 'Flooring varies by material - hardwood is more labor, LVP less.';
        break;
      case 'painting':
        materialPercent = 0.25; // 25% paint, 75% labor
        projectNote = 'Painting is labor-intensive. Paint cost is small vs prep and application.';
        break;
      case 'electrical':
        materialPercent = 0.35; // 35% materials
        projectNote = 'Electrical is labor-heavy due to code requirements and skilled trade.';
        break;
      case 'plumbing':
        materialPercent = 0.40; // 40% materials
        projectNote = 'Plumbing labor includes access, repair, and code compliance.';
        break;
      case 'roofing':
        materialPercent = 0.45; // 45% materials
        projectNote = 'Roofing labor is physical and dangerous, commanding higher rates.';
        break;
      case 'deck':
        materialPercent = 0.50; // 50/50
        projectNote = 'Decks vary - composite is more material cost, wood is more labor.';
        break;
      default:
        materialPercent = 0.50;
        projectNote = 'Typical remodel splits 50/50 between materials and labor.';
    }

    final laborPercent = 1.0 - materialPercent;
    final materialBudget = totalBudget * materialPercent;
    final laborBudget = totalBudget * laborPercent;

    setState(() {
      _materialBudget = materialBudget;
      _laborBudget = laborBudget;
      _materialPercent = materialPercent * 100;
      _laborPercent = laborPercent * 100;
      _projectNote = projectNote;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _totalBudgetController.text = '50000'; setState(() { _projectType = 'kitchen'; }); _calculate(); }

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
        title: Text('Material vs Labor Split', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PROJECT TYPE', ['kitchen', 'bathroom', 'flooring', 'painting'], _projectType, {'kitchen': 'Kitchen', 'bathroom': 'Bathroom', 'flooring': 'Flooring', 'painting': 'Painting'}, (v) { setState(() => _projectType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['electrical', 'plumbing', 'roofing', 'deck'], _projectType, {'electrical': 'Electrical', 'plumbing': 'Plumbing', 'roofing': 'Roofing', 'deck': 'Deck'}, (v) { setState(() => _projectType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Budget', unit: '\$', controller: _totalBudgetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_materialBudget != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [
                    Text('MATERIALS', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_materialPercent!.toStringAsFixed(0)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text(_formatCurrency(_materialBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                  ])),
                  Container(width: 1, height: 60, color: colors.borderSubtle),
                  Expanded(child: Column(children: [
                    Text('LABOR', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_laborPercent!.toStringAsFixed(0)}%', style: TextStyle(color: colors.accentSuccess, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text(_formatCurrency(_laborBudget!), style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                  ])),
                ]),
                const SizedBox(height: 16),
                // Visual bar
                Container(
                  height: 24,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    Expanded(flex: _materialPercent!.toInt(), child: Container(color: colors.accentPrimary)),
                    Expanded(flex: _laborPercent!.toInt(), child: Container(color: colors.accentSuccess)),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_projectNote!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSplitTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
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

  Widget _buildSplitTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL SPLITS BY PROJECT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Kitchen', '60% / 40%'),
        _buildTableRow(colors, 'Bathroom', '50% / 50%'),
        _buildTableRow(colors, 'Painting', '25% / 75%'),
        _buildTableRow(colors, 'Electrical', '35% / 65%'),
        _buildTableRow(colors, 'Roofing', '45% / 55%'),
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
