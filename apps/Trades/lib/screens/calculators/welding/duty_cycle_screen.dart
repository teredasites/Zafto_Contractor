import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Duty Cycle Calculator - Welder duty cycle calculations
class DutyCycleScreen extends ConsumerStatefulWidget {
  const DutyCycleScreen({super.key});
  @override
  ConsumerState<DutyCycleScreen> createState() => _DutyCycleScreenState();
}

class _DutyCycleScreenState extends ConsumerState<DutyCycleScreen> {
  final _ratedAmpsController = TextEditingController();
  final _ratedDutyCycleController = TextEditingController(text: '60');
  final _desiredAmpsController = TextEditingController();

  double? _actualDutyCycle;
  double? _maxArcTime;
  String? _notes;

  void _calculate() {
    final ratedAmps = double.tryParse(_ratedAmpsController.text);
    final ratedDutyCycle = double.tryParse(_ratedDutyCycleController.text) ?? 60;
    final desiredAmps = double.tryParse(_desiredAmpsController.text);

    if (ratedAmps == null || desiredAmps == null || desiredAmps <= 0) {
      setState(() { _actualDutyCycle = null; });
      return;
    }

    // Duty cycle formula: DC2 = DC1 × (I1/I2)²
    // Where DC1 = rated duty cycle, I1 = rated amps, I2 = desired amps
    final actualDutyCycle = ratedDutyCycle * math.pow(ratedAmps / desiredAmps, 2);

    // Cap at 100%
    final cappedDutyCycle = actualDutyCycle > 100 ? 100.0 : actualDutyCycle;

    // Max arc time in 10-minute period
    final maxArcTime = cappedDutyCycle / 10; // minutes per 10-min period

    String notes;
    if (cappedDutyCycle >= 100) {
      notes = 'Can weld continuously at this amperage';
    } else if (cappedDutyCycle >= 60) {
      notes = 'Good duty cycle for production work';
    } else if (cappedDutyCycle >= 40) {
      notes = 'Adequate for intermittent welding';
    } else {
      notes = 'Low duty cycle - allow cooling between welds';
    }

    setState(() {
      _actualDutyCycle = cappedDutyCycle;
      _maxArcTime = maxArcTime;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ratedAmpsController.clear();
    _ratedDutyCycleController.text = '60';
    _desiredAmpsController.clear();
    setState(() { _actualDutyCycle = null; });
  }

  @override
  void dispose() {
    _ratedAmpsController.dispose();
    _ratedDutyCycleController.dispose();
    _desiredAmpsController.dispose();
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
        title: Text('Duty Cycle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Rated Amperage', unit: 'A', hint: 'From machine nameplate', controller: _ratedAmpsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rated Duty Cycle', unit: '%', hint: '60% typical', controller: _ratedDutyCycleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Desired Amperage', unit: 'A', hint: 'What you want to run', controller: _desiredAmpsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_actualDutyCycle != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('DC2 = DC1 x (I1/I2)\u00B2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Calculate actual duty cycle at different amperages', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Duty Cycle', '${_actualDutyCycle!.toStringAsFixed(0)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Arc Time/10 min', '${_maxArcTime!.toStringAsFixed(1)} min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cool Time/10 min', '${(10 - _maxArcTime!).toStringAsFixed(1)} min'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
