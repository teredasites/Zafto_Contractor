import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// 1/4 Mile ET Calculator - ET from HP and weight
class QuarterMileScreen extends ConsumerStatefulWidget {
  const QuarterMileScreen({super.key});
  @override
  ConsumerState<QuarterMileScreen> createState() => _QuarterMileScreenState();
}

class _QuarterMileScreenState extends ConsumerState<QuarterMileScreen> {
  final _hpController = TextEditingController();
  final _weightController = TextEditingController();

  double? _etSeconds;
  double? _trapMph;
  double? _eighthMileEt;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final weight = double.tryParse(_weightController.text);

    if (hp == null || weight == null || hp <= 0) {
      setState(() { _etSeconds = null; });
      return;
    }

    // ET = 5.825 × (Weight / HP)^(1/3)
    final et = 5.825 * math.pow(weight / hp, 1/3);
    // Trap Speed = 234 × (HP / Weight)^(1/3)
    final trap = 234 * math.pow(hp / weight, 1/3);
    // 1/8 mile ET ≈ 1/4 mile × 0.632
    final eighth = et * 0.632;

    setState(() {
      _etSeconds = et;
      _trapMph = trap.toDouble();
      _eighthMileEt = eighth;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _weightController.clear();
    setState(() { _etSeconds = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _weightController.dispose();
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
        title: Text('1/4 Mile ET', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Wheel Horsepower', unit: 'WHP', hint: 'Dyno-proven', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'With driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_etSeconds != null) _buildResultsCard(colors),
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
        Text('ET = 5.825 × (Weight / HP)^(1/3)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Assumes optimal traction and launch', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, '1/4 Mile ET', '${_etSeconds!.toStringAsFixed(2)} sec', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Trap Speed', '${_trapMph!.toStringAsFixed(1)} MPH'),
        const SizedBox(height: 12),
        _buildResultRow(colors, '1/8 Mile ET', '${_eighthMileEt!.toStringAsFixed(2)} sec'),
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
