import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compressor Map Calculator - Turbo sizing and efficiency
class CompressorMapScreen extends ConsumerStatefulWidget {
  const CompressorMapScreen({super.key});
  @override
  ConsumerState<CompressorMapScreen> createState() => _CompressorMapScreenState();
}

class _CompressorMapScreenState extends ConsumerState<CompressorMapScreen> {
  final _targetHpController = TextEditingController();
  final _pressureRatioController = TextEditingController(text: '2.0');
  final _efficiencyController = TextEditingController(text: '70');

  double? _airflowLbMin;
  double? _airflowCfm;

  void _calculate() {
    final targetHp = double.tryParse(_targetHpController.text);
    final pressureRatio = double.tryParse(_pressureRatioController.text) ?? 2.0;
    final efficiency = double.tryParse(_efficiencyController.text) ?? 70;

    if (targetHp == null || pressureRatio <= 0) {
      setState(() { _airflowLbMin = null; });
      return;
    }

    // Approximate: 1 HP requires ~1.5 CFM at sea level
    // Adjusted for pressure ratio and efficiency
    final airflowLbMin = (targetHp * 10.0) / 60.0; // lb/min approximation
    final airflowCfm = targetHp * 1.5 * (efficiency / 100);

    setState(() {
      _airflowLbMin = airflowLbMin;
      _airflowCfm = airflowCfm;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _targetHpController.clear();
    _pressureRatioController.text = '2.0';
    _efficiencyController.text = '70';
    setState(() { _airflowLbMin = null; });
  }

  @override
  void dispose() {
    _targetHpController.dispose();
    _pressureRatioController.dispose();
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
        title: Text('Compressor Map', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'Desired output', controller: _targetHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pressure Ratio', unit: ':1', hint: '2.0 = ~15 psi', controller: _pressureRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compressor Efficiency', unit: '%', hint: 'Typical 65-78%', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_airflowLbMin != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTurboSizeGuide(colors),
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
        Text('Size turbo for target power', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Match compressor to airflow needs', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('REQUIRED AIRFLOW', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_airflowLbMin!.toStringAsFixed(1)} lb/min', style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('~${_airflowCfm!.toStringAsFixed(0)} CFM', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Find this airflow at your pressure ratio on the compressor map. Aim for 65-78% efficiency island.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTurboSizeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL TURBO SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSizeRow(colors, '200-350 HP', 'GT28, GT30'),
        _buildSizeRow(colors, '350-500 HP', 'GT35, GTX35'),
        _buildSizeRow(colors, '500-700 HP', 'GT40, GTX40'),
        _buildSizeRow(colors, '700-1000 HP', 'GT45, GTX45'),
        _buildSizeRow(colors, '1000+ HP', 'GT47+, Twin setup'),
      ]),
    );
  }

  Widget _buildSizeRow(ZaftoColors colors, String power, String turbos) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(power, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(turbos, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
