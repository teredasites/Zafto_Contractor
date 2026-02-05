import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Oil Change Interval Calculator
class OilChangeIntervalScreen extends ConsumerStatefulWidget {
  const OilChangeIntervalScreen({super.key});
  @override
  ConsumerState<OilChangeIntervalScreen> createState() => _OilChangeIntervalScreenState();
}

class _OilChangeIntervalScreenState extends ConsumerState<OilChangeIntervalScreen> {
  final _annualMilesController = TextEditingController(text: '12000');
  String _oilType = 'Full Synthetic';
  String _drivingCondition = 'Normal';

  int? _intervalMiles;
  int? _changesPerYear;
  String? _recommendation;

  // Base intervals by oil type
  static const Map<String, int> _baseIntervals = {
    'Conventional': 3000,
    'Synthetic Blend': 5000,
    'Full Synthetic': 7500,
    'Extended Synthetic': 10000,
  };

  // Driving condition multipliers
  static const Map<String, double> _conditionMultipliers = {
    'Normal': 1.0,
    'Highway': 1.2,
    'City/Stop-Go': 0.7,
    'Severe/Towing': 0.5,
  };

  void _calculate() {
    final annualMiles = double.tryParse(_annualMilesController.text);

    if (annualMiles == null || annualMiles <= 0) {
      setState(() { _intervalMiles = null; });
      return;
    }

    final baseInterval = _baseIntervals[_oilType]!;
    final multiplier = _conditionMultipliers[_drivingCondition]!;
    final adjustedInterval = (baseInterval * multiplier).round();

    final changesPerYear = (annualMiles / adjustedInterval).ceil();

    String recommendation;
    if (_drivingCondition == 'Severe/Towing') {
      recommendation = 'Severe service: Check oil level frequently';
    } else if (_oilType == 'Extended Synthetic' && _drivingCondition == 'Highway') {
      recommendation = 'Extended intervals OK with oil analysis';
    } else {
      recommendation = 'Follow manufacturer recommendations when possible';
    }

    setState(() {
      _intervalMiles = adjustedInterval;
      _changesPerYear = changesPerYear;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _annualMilesController.text = '12000';
    setState(() { _intervalMiles = null; });
  }

  @override
  void dispose() {
    _annualMilesController.dispose();
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
        title: Text('Oil Change Interval', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('OIL TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildOilTypeSelector(colors),
            const SizedBox(height: 16),
            Text('DRIVING CONDITIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildConditionSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Annual Miles', unit: 'mi/yr', hint: 'Yearly driving', controller: _annualMilesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_intervalMiles != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildOilTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _baseIntervals.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 10)),
        selected: _oilType == type,
        onSelected: (_) => setState(() { _oilType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildConditionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditionMultipliers.keys.map((cond) => ChoiceChip(
        label: Text(cond, style: const TextStyle(fontSize: 10)),
        selected: _drivingCondition == cond,
        onSelected: (_) => setState(() { _drivingCondition = cond; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Interval = Base × Condition Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Adjusted for oil type and driving habits', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Change Interval', '${_intervalMiles!} mi', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Changes/Year', '$_changesPerYear'),
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
