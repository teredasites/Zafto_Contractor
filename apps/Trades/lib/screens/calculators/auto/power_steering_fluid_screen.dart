import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Power Steering Fluid Calculator
class PowerSteeringFluidScreen extends ConsumerStatefulWidget {
  const PowerSteeringFluidScreen({super.key});
  @override
  ConsumerState<PowerSteeringFluidScreen> createState() => _PowerSteeringFluidScreenState();
}

class _PowerSteeringFluidScreenState extends ConsumerState<PowerSteeringFluidScreen> {
  String _vehicleMake = 'Domestic';
  String _fluidCondition = 'Red/Clear';

  String? _fluidType;
  String? _capacity;
  String? _recommendation;

  // Fluid types by manufacturer
  static const Map<String, String> _fluidTypes = {
    'Domestic': 'ATF or PS Fluid',
    'Honda': 'Honda PS Fluid only',
    'Toyota': 'Dexron ATF',
    'European': 'CHF 11S or Pentosin',
    'Korean': 'ATF or PS Fluid',
  };

  void _calculate() {
    final fluidType = _fluidTypes[_vehicleMake]!;

    String recommendation;
    String capacity = '1-2 pints typical';

    if (_fluidCondition == 'Red/Clear') {
      recommendation = 'Fluid is good. Check level and top off if needed.';
    } else if (_fluidCondition == 'Dark Red') {
      recommendation = 'Aging fluid. Plan flush within next service.';
    } else if (_fluidCondition == 'Brown/Black') {
      recommendation = 'Oxidized fluid. Flush system to prevent pump damage.';
    } else {
      recommendation = 'Milky = water contamination. Immediate flush required!';
    }

    setState(() {
      _fluidType = fluidType;
      _capacity = capacity;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleMake = 'Domestic';
    _fluidCondition = 'Red/Clear';
    setState(() { _fluidType = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Power Steering Fluid', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('VEHICLE MANUFACTURER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildMakeSelector(colors),
            const SizedBox(height: 16),
            Text('FLUID CONDITION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildConditionSelector(colors),
            const SizedBox(height: 32),
            if (_fluidType != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMakeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fluidTypes.keys.map((make) => ChoiceChip(
        label: Text(make, style: const TextStyle(fontSize: 11)),
        selected: _vehicleMake == make,
        onSelected: (_) => setState(() { _vehicleMake = make; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildConditionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Red/Clear', 'Dark Red', 'Brown/Black', 'Milky'].map((cond) => ChoiceChip(
        label: Text(cond, style: const TextStyle(fontSize: 11)),
        selected: _fluidCondition == cond,
        onSelected: (_) => setState(() { _fluidCondition = cond; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Fluid type is vehicle-specific', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Wrong fluid can damage seals and pump', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isBad = _fluidCondition == 'Brown/Black' || _fluidCondition == 'Milky';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isBad ? Colors.orange.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Fluid Type', _fluidType!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Typical Capacity', _capacity!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isBad ? Colors.orange.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: isBad ? Colors.orange : colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
