import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Fluid Service Calculator
class BrakeFluidServiceScreen extends ConsumerStatefulWidget {
  const BrakeFluidServiceScreen({super.key});
  @override
  ConsumerState<BrakeFluidServiceScreen> createState() => _BrakeFluidServiceScreenState();
}

class _BrakeFluidServiceScreenState extends ConsumerState<BrakeFluidServiceScreen> {
  final _moistureController = TextEditingController();
  String _fluidType = 'DOT 3';
  int _yearsSinceChange = 2;

  String? _condition;
  String? _recommendation;
  bool? _needsService;

  void _calculate() {
    final moisture = double.tryParse(_moistureController.text);

    String condition;
    String recommendation;
    bool needsService;

    // Moisture content analysis
    if (moisture != null) {
      if (moisture <= 1.0) {
        condition = 'Good - Low moisture';
        needsService = false;
        recommendation = 'Fluid is in good condition. Retest in 1 year.';
      } else if (moisture <= 2.0) {
        condition = 'Fair - Monitor';
        needsService = false;
        recommendation = 'Moisture rising. Plan flush within 6 months.';
      } else if (moisture <= 3.0) {
        condition = 'Poor - Service soon';
        needsService = true;
        recommendation = 'High moisture reduces boiling point. Flush recommended.';
      } else {
        condition = 'Critical - Service now';
        needsService = true;
        recommendation = 'Dangerous moisture level. Immediate flush required!';
      }
    } else {
      // Time-based recommendation
      if (_yearsSinceChange >= 3) {
        condition = 'Due by time';
        needsService = true;
        recommendation = 'Most manufacturers recommend 2-3 year intervals';
      } else if (_yearsSinceChange >= 2) {
        condition = 'Monitor';
        needsService = false;
        recommendation = 'Test moisture content or plan service soon';
      } else {
        condition = 'OK';
        needsService = false;
        recommendation = 'Continue normal maintenance schedule';
      }
    }

    setState(() {
      _condition = condition;
      _recommendation = recommendation;
      _needsService = needsService;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moistureController.clear();
    _yearsSinceChange = 2;
    setState(() { _condition = null; });
  }

  @override
  void dispose() {
    _moistureController.dispose();
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
        title: Text('Brake Fluid Service', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FLUID TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildFluidSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Moisture Content', unit: '%', hint: 'From tester (optional)', controller: _moistureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('YEARS SINCE CHANGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildYearSelector(colors),
            const SizedBox(height: 32),
            if (_condition != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFluidSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['DOT 3', 'DOT 4', 'DOT 5.1', 'DOT 5'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _fluidType == type,
        onSelected: (_) => setState(() { _fluidType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildYearSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [1, 2, 3, 4, 5].map((year) => ChoiceChip(
        label: Text('$year yr'),
        selected: _yearsSinceChange == year,
        onSelected: (_) => setState(() { _yearsSinceChange = year; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Moisture absorbs through hoses', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('>3% moisture significantly lowers boiling point', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isUrgent = _needsService == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isUrgent ? Colors.orange.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isUrgent ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_condition!, style: TextStyle(color: isUrgent ? Colors.orange : Colors.green, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Text('DOT 5 (silicone) cannot mix with glycol-based fluids', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }
}
