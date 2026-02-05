import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Intercooler Calculator - Sizing and efficiency
class IntercoolerScreen extends ConsumerStatefulWidget {
  const IntercoolerScreen({super.key});
  @override
  ConsumerState<IntercoolerScreen> createState() => _IntercoolerScreenState();
}

class _IntercoolerScreenState extends ConsumerState<IntercoolerScreen> {
  final _horsepowerController = TextEditingController();
  final _boostController = TextEditingController();
  final _ambientTempController = TextEditingController(text: '80');

  double? _heatRejection;
  double? _minCoreVolume;
  double? _chargeAirTemp;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final boost = double.tryParse(_boostController.text);
    final ambientTemp = double.tryParse(_ambientTempController.text) ?? 80;

    if (horsepower == null || boost == null) {
      setState(() { _heatRejection = null; });
      return;
    }

    // Heat rejection approximation: ~0.7 BTU/min per HP
    final heatRejection = horsepower * 0.7;
    // Core volume rule of thumb: ~0.5 cubic inch per HP
    final minCoreVolume = horsepower * 0.5;
    // Charge air temp estimate (with ~70% efficient intercooler)
    final pressureRatio = (boost + 14.7) / 14.7;
    final compressorOutTemp = (ambientTemp + 460) * (pressureRatio * 0.283) - 460 + ambientTemp;
    final chargeAirTemp = ambientTemp + (compressorOutTemp - ambientTemp) * 0.3;

    setState(() {
      _heatRejection = heatRejection;
      _minCoreVolume = minCoreVolume;
      _chargeAirTemp = chargeAirTemp;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _boostController.clear();
    _ambientTempController.text = '80';
    setState(() { _heatRejection = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _boostController.dispose();
    _ambientTempController.dispose();
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
        title: Text('Intercooler', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'At wheels', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Pressure', unit: 'psi', hint: 'Peak boost', controller: _boostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temperature', unit: '°F', hint: 'Outside air', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_heatRejection != null) _buildResultsCard(colors),
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
        Text('Size intercooler for power level', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Cooler charge air = denser air = more power', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('INTERCOOLER REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Heat Rejection', '${_heatRejection!.toStringAsFixed(0)} BTU/min'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Min Core Volume', '${_minCoreVolume!.toStringAsFixed(0)} cu in'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Est. Charge Temp', '${_chargeAirTemp!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SIZING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('• Front mount: best cooling, longest piping', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• Top mount: shorter piping, heat soak risk', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• Bar & plate: better cooling, more weight', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• Tube & fin: lighter, less efficient', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
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
