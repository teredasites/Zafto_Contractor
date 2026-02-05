import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Turbo Sizing Calculator - CFM and pressure ratio for HP target
class TurboSizingScreen extends ConsumerStatefulWidget {
  const TurboSizingScreen({super.key});
  @override
  ConsumerState<TurboSizingScreen> createState() => _TurboSizingScreenState();
}

class _TurboSizingScreenState extends ConsumerState<TurboSizingScreen> {
  final _hpController = TextEditingController();
  final _boostController = TextEditingController(text: '15');
  final _efficiencyController = TextEditingController(text: '70');

  double? _cfmRequired;
  double? _pressureRatio;
  String? _turboSuggestion;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final boost = double.tryParse(_boostController.text);
    final efficiency = double.tryParse(_efficiencyController.text);

    if (hp == null || boost == null || efficiency == null) {
      setState(() { _cfmRequired = null; });
      return;
    }

    // CFM = HP × 1.5 (rough rule for boosted engines)
    final cfm = hp * 1.5;
    // Pressure ratio = (Boost + 14.7) / 14.7
    final pr = (boost + 14.7) / 14.7;

    String suggestion;
    if (cfm < 400) {
      suggestion = 'Small frame turbo (GT28, T3)';
    } else if (cfm < 600) {
      suggestion = 'Medium frame (GT35, T4)';
    } else if (cfm < 900) {
      suggestion = 'Large frame (GT40, T6)';
    } else {
      suggestion = 'XL frame or twin turbo setup';
    }

    setState(() {
      _cfmRequired = cfm;
      _pressureRatio = pr;
      _turboSuggestion = suggestion;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _boostController.text = '15';
    _efficiencyController.text = '70';
    setState(() { _cfmRequired = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _boostController.dispose();
    _efficiencyController.dispose();
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
        title: Text('Turbo Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'HP', hint: 'Wheel or crank', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Pressure', unit: 'PSI', hint: 'Target boost', controller: _boostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compressor Efficiency', unit: '%', hint: '65-75% typical', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cfmRequired != null) _buildResultsCard(colors),
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
        Text('PR = (Boost + 14.7) / 14.7', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Match compressor map to CFM and PR', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Airflow Required', '${_cfmRequired!.toStringAsFixed(0)} CFM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pressure Ratio', '${_pressureRatio!.toStringAsFixed(2)}:1'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_turboSuggestion!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
