import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Intercooler Efficiency Calculator
class IntercoolerEfficiencyScreen extends ConsumerStatefulWidget {
  const IntercoolerEfficiencyScreen({super.key});
  @override
  ConsumerState<IntercoolerEfficiencyScreen> createState() => _IntercoolerEfficiencyScreenState();
}

class _IntercoolerEfficiencyScreenState extends ConsumerState<IntercoolerEfficiencyScreen> {
  final _ambientTempController = TextEditingController(text: '75');
  final _preIcTempController = TextEditingController();
  final _postIcTempController = TextEditingController();
  final _boostController = TextEditingController();

  double? _efficiency;
  double? _tempDrop;
  double? _densityGain;
  String? _performanceImpact;
  String? _rating;

  void _calculate() {
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final preIcTemp = double.tryParse(_preIcTempController.text);
    final postIcTemp = double.tryParse(_postIcTempController.text);
    final boost = double.tryParse(_boostController.text);

    if (ambientTemp == null || preIcTemp == null || postIcTemp == null) {
      setState(() { _efficiency = null; });
      return;
    }

    if (preIcTemp <= ambientTemp) {
      setState(() { _efficiency = null; });
      return;
    }

    // Intercooler efficiency = (Pre-IC Temp - Post-IC Temp) / (Pre-IC Temp - Ambient Temp) × 100
    final efficiency = ((preIcTemp - postIcTemp) / (preIcTemp - ambientTemp)) * 100;
    final tempDrop = preIcTemp - postIcTemp;

    // Air density increase calculation
    // Using ideal gas law approximation: density is inversely proportional to absolute temp
    // Convert to Rankine (F + 459.67)
    final preIcRankine = preIcTemp + 459.67;
    final postIcRankine = postIcTemp + 459.67;
    final densityGain = ((preIcRankine / postIcRankine) - 1) * 100;

    // Performance impact (rough estimate)
    // ~1% power gain per 10°F IAT reduction
    final hpGainPercent = tempDrop / 10;

    // Efficiency rating
    String rating;
    if (efficiency >= 85) {
      rating = 'Excellent - Race-grade efficiency';
    } else if (efficiency >= 70) {
      rating = 'Very Good - High-quality intercooler';
    } else if (efficiency >= 55) {
      rating = 'Good - Adequate for street use';
    } else if (efficiency >= 40) {
      rating = 'Fair - Consider upgrade for more boost';
    } else {
      rating = 'Poor - Intercooler undersized or clogged';
    }

    setState(() {
      _efficiency = efficiency.clamp(0, 100);
      _tempDrop = tempDrop;
      _densityGain = densityGain;
      _performanceImpact = 'Estimated ${hpGainPercent.toStringAsFixed(1)}% power gain from cooling';
      _rating = rating;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ambientTempController.text = '75';
    _preIcTempController.clear();
    _postIcTempController.clear();
    _boostController.clear();
    setState(() { _efficiency = null; });
  }

  @override
  void dispose() {
    _ambientTempController.dispose();
    _preIcTempController.dispose();
    _postIcTempController.dispose();
    _boostController.dispose();
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
        title: Text('Intercooler Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Ambient Temperature', unit: '\u00B0F', hint: 'Outside air temp', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pre-Intercooler Temp', unit: '\u00B0F', hint: 'Before IC (hot side)', controller: _preIcTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Post-Intercooler Temp', unit: '\u00B0F', hint: 'After IC (cold side)', controller: _postIcTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Pressure', unit: 'PSI', hint: 'Optional', controller: _boostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_efficiency != null) _buildResultsCard(colors),
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
        Text('Eff = (Pre - Post) / (Pre - Amb) × 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Measure intercooler cooling performance', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Efficiency', '${_efficiency!.toStringAsFixed(1)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Temperature Drop', '${_tempDrop!.toStringAsFixed(0)}\u00B0F'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Air Density Gain', '${_densityGain!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_rating!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(_performanceImpact!, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Tip: Measure temps at full boost, consistent RPM for accurate readings.',
            style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
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
