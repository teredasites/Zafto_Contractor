import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Automotive Labor Time Estimator
class LaborTimeScreen extends ConsumerStatefulWidget {
  const LaborTimeScreen({super.key});
  @override
  ConsumerState<LaborTimeScreen> createState() => _LaborTimeScreenState();
}

class _LaborTimeScreenState extends ConsumerState<LaborTimeScreen> {
  final _bookTimeController = TextEditingController();
  final _laborRateController = TextEditingController(text: '125');
  String _techSkill = 'Average';
  String _vehicleCondition = 'Normal';

  double? _actualTime;
  double? _laborCost;
  String? _recommendation;

  // Skill level multipliers
  static const Map<String, double> _skillMultipliers = {
    'Expert': 0.75,
    'Average': 1.0,
    'Novice': 1.5,
  };

  // Vehicle condition multipliers
  static const Map<String, double> _conditionMultipliers = {
    'New/Clean': 0.9,
    'Normal': 1.0,
    'Rusty/Difficult': 1.5,
    'Severe Rust': 2.0,
  };

  void _calculate() {
    final bookTime = double.tryParse(_bookTimeController.text);
    final laborRate = double.tryParse(_laborRateController.text);

    if (bookTime == null || laborRate == null || bookTime <= 0 || laborRate <= 0) {
      setState(() { _actualTime = null; });
      return;
    }

    final skillMult = _skillMultipliers[_techSkill]!;
    final condMult = _conditionMultipliers[_vehicleCondition]!;

    final actualTime = bookTime * skillMult * condMult;
    final laborCost = bookTime * laborRate; // Shops charge book time

    String recommendation;
    if (condMult > 1.3) {
      recommendation = 'Expect extra time for rust/difficult access';
    } else if (skillMult < 1.0) {
      recommendation = 'Experienced tech may beat book time';
    } else {
      recommendation = 'Book time is based on ideal conditions';
    }

    setState(() {
      _actualTime = actualTime;
      _laborCost = laborCost;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _bookTimeController.clear();
    _laborRateController.text = '125';
    setState(() { _actualTime = null; });
  }

  @override
  void dispose() {
    _bookTimeController.dispose();
    _laborRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Labor Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Book Time', unit: 'hrs', hint: 'From labor guide', controller: _bookTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Labor Rate', unit: '\$/hr', hint: 'Shop rate', controller: _laborRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('TECHNICIAN SKILL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSkillSelector(colors),
            const SizedBox(height: 16),
            Text('VEHICLE CONDITION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildConditionSelector(colors),
            const SizedBox(height: 32),
            if (_actualTime != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSkillSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skillMultipliers.keys.map((skill) => ChoiceChip(
        label: Text(skill),
        selected: _techSkill == skill,
        onSelected: (_) => setState(() { _techSkill = skill; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildConditionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditionMultipliers.keys.map((cond) => ChoiceChip(
        label: Text(cond, style: const TextStyle(fontSize: 10)),
        selected: _vehicleCondition == cond,
        onSelected: (_) => setState(() { _vehicleCondition = cond; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Actual = Book × Skill × Condition', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Shops charge book time regardless of actual', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Estimated Actual', '${_actualTime!.toStringAsFixed(1)} hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Labor Cost', '\$${_laborCost!.toStringAsFixed(2)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
