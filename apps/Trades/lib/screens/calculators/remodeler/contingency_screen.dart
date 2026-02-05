import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Contingency Calculator - Remodel contingency budget planning
class ContingencyScreen extends ConsumerStatefulWidget {
  const ContingencyScreen({super.key});
  @override
  ConsumerState<ContingencyScreen> createState() => _ContingencyScreenState();
}

class _ContingencyScreenState extends ConsumerState<ContingencyScreen> {
  final _budgetController = TextEditingController(text: '50000');
  final _homeAgeController = TextEditingController(text: '30');

  String _projectType = 'cosmetic';
  bool _unknownConditions = false;

  double? _recommendedPercent;
  double? _contingencyAmount;
  double? _totalWithContingency;
  String? _riskLevel;

  @override
  void dispose() { _budgetController.dispose(); _homeAgeController.dispose(); super.dispose(); }

  void _calculate() {
    final budget = double.tryParse(_budgetController.text) ?? 50000;
    final homeAge = int.tryParse(_homeAgeController.text) ?? 30;

    // Base contingency by project type
    double basePercent;
    switch (_projectType) {
      case 'cosmetic':
        basePercent = 10; // Paint, fixtures - low risk
        break;
      case 'kitchen':
        basePercent = 15; // Moderate risk
        break;
      case 'bathroom':
        basePercent = 20; // High risk (water damage common)
        break;
      case 'structural':
        basePercent = 25; // High risk
        break;
      case 'gut':
        basePercent = 30; // Very high risk
        break;
      default:
        basePercent = 15;
    }

    // Home age adjustment
    if (homeAge > 50) {
      basePercent += 10; // Pre-1975: knob-and-tube, lead, asbestos
    } else if (homeAge > 30) {
      basePercent += 5; // 1975-1995: possible issues
    }

    // Unknown conditions
    if (_unknownConditions) {
      basePercent += 5;
    }

    // Cap at 35%
    final recommendedPercent = basePercent.clamp(10.0, 35.0);
    final contingencyAmount = budget * (recommendedPercent / 100);
    final totalWithContingency = budget + contingencyAmount;

    // Risk level
    String riskLevel;
    if (recommendedPercent <= 12) {
      riskLevel = 'Low Risk';
    } else if (recommendedPercent <= 18) {
      riskLevel = 'Moderate Risk';
    } else if (recommendedPercent <= 25) {
      riskLevel = 'High Risk';
    } else {
      riskLevel = 'Very High Risk';
    }

    setState(() {
      _recommendedPercent = recommendedPercent;
      _contingencyAmount = contingencyAmount;
      _totalWithContingency = totalWithContingency;
      _riskLevel = riskLevel;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _budgetController.text = '50000'; _homeAgeController.text = '30'; setState(() { _projectType = 'cosmetic'; _unknownConditions = false; }); _calculate(); }

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
        title: Text('Contingency Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PROJECT TYPE', ['cosmetic', 'kitchen', 'bathroom', 'structural', 'gut'], _projectType, {'cosmetic': 'Cosmetic', 'kitchen': 'Kitchen', 'bathroom': 'Bath', 'structural': 'Structural', 'gut': 'Gut'}, (v) { setState(() => _projectType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Unknown Wall/Floor Conditions', _unknownConditions, (v) { setState(() => _unknownConditions = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Project Budget', unit: '\$', controller: _budgetController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Home Age', unit: 'years', controller: _homeAgeController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_recommendedPercent != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('CONTINGENCY', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _recommendedPercent! <= 15 ? colors.accentSuccess.withValues(alpha: 0.2) :
                             _recommendedPercent! <= 22 ? colors.accentWarning.withValues(alpha: 0.2) :
                             colors.accentError.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(_riskLevel!, style: TextStyle(
                      color: _recommendedPercent! <= 15 ? colors.accentSuccess :
                             _recommendedPercent! <= 22 ? colors.accentWarning :
                             colors.accentError,
                      fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${_recommendedPercent!.toStringAsFixed(0)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                  Text(_formatCurrency(_contingencyAmount!), style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Budget', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(double.tryParse(_budgetController.text) ?? 50000), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('+ Contingency', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatCurrency(_contingencyAmount!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Budget', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)), Text(_formatCurrency(_totalWithContingency!), style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Contingency covers unforeseen issues: rot, mold, outdated wiring, code upgrades, and change orders.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGuideTable(colors),
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
          Flexible(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildGuideTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONTINGENCY GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Cosmetic/new home', '10%'),
        _buildTableRow(colors, 'Kitchen remodel', '15%'),
        _buildTableRow(colors, 'Bathroom (water risk)', '20%'),
        _buildTableRow(colors, 'Old home (>50 yrs)', '25%'),
        _buildTableRow(colors, 'Gut renovation', '25-35%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
