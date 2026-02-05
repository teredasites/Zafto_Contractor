import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dyno Correction Calculator - SAE/STD correction factors
class DynoCorrectionScreen extends ConsumerStatefulWidget {
  const DynoCorrectionScreen({super.key});
  @override
  ConsumerState<DynoCorrectionScreen> createState() => _DynoCorrectionScreenState();
}

class _DynoCorrectionScreenState extends ConsumerState<DynoCorrectionScreen> {
  final _observedHpController = TextEditingController();
  final _barometerController = TextEditingController(text: '29.92');
  final _tempController = TextEditingController(text: '77');
  final _humidityController = TextEditingController(text: '50');

  double? _correctedHp;
  double? _correctionFactor;

  void _calculate() {
    final observedHp = double.tryParse(_observedHpController.text);
    final barometer = double.tryParse(_barometerController.text) ?? 29.92;
    final tempF = double.tryParse(_tempController.text) ?? 77;
    final humidity = double.tryParse(_humidityController.text) ?? 50;

    if (observedHp == null) {
      setState(() { _correctedHp = null; });
      return;
    }

    // SAE J1349 correction factor (simplified)
    // CF = (29.92/P) * ((T + 460) / 537) * (1 - 0.378 * Pv/P)
    // Where Pv is vapor pressure based on humidity

    // Simplified SAE correction
    final tempRankine = tempF + 460;
    final stdTempRankine = 77 + 460; // 77°F standard

    // Pressure correction
    final pressureCorrection = 29.92 / barometer;

    // Temperature correction
    final tempCorrection = tempRankine / stdTempRankine;

    // Humidity has minor effect, simplified
    final humidityEffect = 1 - (humidity * 0.0003);

    final correctionFactor = pressureCorrection * tempCorrection * humidityEffect;
    final correctedHp = observedHp * correctionFactor;

    setState(() {
      _correctedHp = correctedHp;
      _correctionFactor = correctionFactor;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _observedHpController.clear();
    _barometerController.text = '29.92';
    _tempController.text = '77';
    _humidityController.text = '50';
    setState(() { _correctedHp = null; });
  }

  @override
  void dispose() {
    _observedHpController.dispose();
    _barometerController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
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
        title: Text('Dyno Correction', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Observed HP', unit: 'hp', hint: 'Dyno reading', controller: _observedHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Barometric Pressure', unit: 'inHg', hint: 'Std = 29.92', controller: _barometerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Temperature', unit: '°F', hint: 'Ambient temp', controller: _tempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Humidity', unit: '%', hint: 'Relative humidity', controller: _humidityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_correctedHp != null) _buildResultsCard(colors),
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
        Text('SAE J1349 Correction', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Standardize dyno readings to compare', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CORRECTED HP', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_correctedHp!.toStringAsFixed(1)} HP', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Correction Factor', '${_correctionFactor!.toStringAsFixed(4)}'),
        _buildResultRow(colors, 'HP Difference', '${(_correctedHp! - double.parse(_observedHpController.text)).toStringAsFixed(1)} HP'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('STD CONDITIONS (SAE J1349)', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('• 77°F (25°C)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• 29.92 inHg (101.3 kPa)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• 0% humidity (dry air)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
