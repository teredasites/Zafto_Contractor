import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// BOV Calculator - Blow-off valve sizing
class BovScreen extends ConsumerStatefulWidget {
  const BovScreen({super.key});
  @override
  ConsumerState<BovScreen> createState() => _BovScreenState();
}

class _BovScreenState extends ConsumerState<BovScreen> {
  final _horsepowerController = TextEditingController();
  final _boostController = TextEditingController();

  double? _airflowCfm;
  String? _recommendedSize;
  String? _valveType;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final boost = double.tryParse(_boostController.text);

    if (horsepower == null) {
      setState(() { _airflowCfm = null; });
      return;
    }

    // Approximate CFM requirement
    final airflowCfm = horsepower * 1.5;

    String size;
    String type;

    if (horsepower < 300) {
      size = '25-32mm';
      type = 'Single piston / diaphragm';
    } else if (horsepower < 500) {
      size = '38-40mm';
      type = 'Single piston';
    } else if (horsepower < 700) {
      size = '44-50mm';
      type = 'Dual piston or large single';
    } else {
      size = '50mm+ or dual BOV';
      type = 'Race-spec dual piston';
    }

    setState(() {
      _airflowCfm = airflowCfm;
      _recommendedSize = size;
      _valveType = type;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _boostController.clear();
    setState(() { _airflowCfm = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
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
        title: Text('Blow-Off Valve', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Horsepower', unit: 'hp', hint: 'Target power', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Pressure', unit: 'psi', hint: 'Peak boost', controller: _boostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_airflowCfm != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildBovTypesCard(colors),
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
        Text('Size BOV for airflow capacity', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Prevents compressor surge on throttle lift', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BOV SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Airflow Requirement', '~${_airflowCfm!.toStringAsFixed(0)} CFM'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('RECOMMENDED', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_recommendedSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_valveType!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBovTypesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BOV vs BYPASS VALVE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTypeRow(colors, 'Blow-Off (Vent)', 'Vents to atmosphere - "psshh" sound'),
        _buildTypeRow(colors, 'Bypass (Recirc)', 'Returns air to intake - quieter, better for MAF'),
        _buildTypeRow(colors, 'Hybrid', 'Adjustable vent/recirc ratio'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('MAF-based cars should use bypass/recirc to prevent rich spikes and stalling.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTypeRow(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
