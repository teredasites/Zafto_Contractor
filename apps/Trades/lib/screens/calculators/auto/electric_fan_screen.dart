import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Electric Fan Calculator - CFM requirements and sizing
class ElectricFanScreen extends ConsumerStatefulWidget {
  const ElectricFanScreen({super.key});
  @override
  ConsumerState<ElectricFanScreen> createState() => _ElectricFanScreenState();
}

class _ElectricFanScreenState extends ConsumerState<ElectricFanScreen> {
  final _horsepowerController = TextEditingController();
  final _radiatorAreaController = TextEditingController();

  double? _requiredCfm;
  double? _ampDraw;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final radiatorArea = double.tryParse(_radiatorAreaController.text);

    if (horsepower == null) {
      setState(() { _requiredCfm = null; });
      return;
    }

    // Rule of thumb: 2-3 CFM per HP for adequate cooling at idle
    final requiredCfm = horsepower * 2.5;

    // Estimate amp draw: ~1 amp per 100 CFM (rough)
    final ampDraw = requiredCfm / 100 * 1.2;

    setState(() {
      _requiredCfm = requiredCfm;
      _ampDraw = ampDraw;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _radiatorAreaController.clear();
    setState(() { _requiredCfm = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _radiatorAreaController.dispose();
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
        title: Text('Electric Fan', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'hp', hint: 'Peak output', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Radiator Area', unit: 'sq in', hint: 'H × W (optional)', controller: _radiatorAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredCfm != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildFanGuide(colors),
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
        Text('~2.5 CFM per HP minimum', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Critical for cooling at idle and low speeds', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String recommendation;
    if (_requiredCfm! < 1500) {
      recommendation = 'Single 12" fan should suffice';
    } else if (_requiredCfm! < 2500) {
      recommendation = 'Single 14-16" fan or dual 12" fans';
    } else if (_requiredCfm! < 4000) {
      recommendation = 'Dual 14" fans or large single puller';
    } else {
      recommendation = 'Dual 16" high-output fans needed';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('MINIMUM AIRFLOW', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_requiredCfm!.toStringAsFixed(0)} CFM', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Est. Current Draw', '${_ampDraw!.toStringAsFixed(0)}+ amps'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('RECOMMENDATION', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(recommendation, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFanGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FAN SELECTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTipRow(colors, 'Puller fan', 'Mounted behind radiator, most common'),
        _buildTipRow(colors, 'Pusher fan', 'In front of radiator, auxiliary'),
        _buildTipRow(colors, 'Shroud', 'Critical - fans only cool shrouded area'),
        _buildTipRow(colors, 'Curved blade', 'More efficient, quieter'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Use relay and proper gauge wiring. High-output fans can draw 30+ amps.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String term, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(term, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
