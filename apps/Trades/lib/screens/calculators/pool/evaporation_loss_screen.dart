import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Evaporation Loss Calculator
class EvaporationLossScreen extends ConsumerStatefulWidget {
  const EvaporationLossScreen({super.key});
  @override
  ConsumerState<EvaporationLossScreen> createState() => _EvaporationLossScreenState();
}

class _EvaporationLossScreenState extends ConsumerState<EvaporationLossScreen> {
  final _surfaceAreaController = TextEditingController();
  final _airTempController = TextEditingController(text: '85');
  final _waterTempController = TextEditingController(text: '82');
  final _humidityController = TextEditingController(text: '50');
  bool _hasCover = false;

  double? _gallonsPerDay;
  double? _gallonsPerWeek;
  double? _inchesPerDay;

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);
    final airTemp = double.tryParse(_airTempController.text);
    final waterTemp = double.tryParse(_waterTempController.text);
    final humidity = double.tryParse(_humidityController.text);

    if (surfaceArea == null || airTemp == null || waterTemp == null || humidity == null ||
        surfaceArea <= 0) {
      setState(() { _gallonsPerDay = null; });
      return;
    }

    // Simplified evaporation formula
    // Base: ~0.25" per day in moderate conditions
    // Adjust for temp differential and humidity
    double tempFactor = 1.0 + ((waterTemp - airTemp) * 0.02);
    if (tempFactor < 0.5) tempFactor = 0.5;
    double humidityFactor = 1.0 + ((50 - humidity) * 0.01);
    if (humidityFactor < 0.3) humidityFactor = 0.3;

    double inchesPerDay = 0.25 * tempFactor * humidityFactor;
    if (_hasCover) inchesPerDay *= 0.05; // Cover reduces evap by 95%

    // Convert to gallons: 1 inch over pool surface = 0.623 gal per sq ft
    final gallonsPerDay = surfaceArea * inchesPerDay * 0.623;
    final gallonsPerWeek = gallonsPerDay * 7;

    setState(() {
      _inchesPerDay = inchesPerDay;
      _gallonsPerDay = gallonsPerDay;
      _gallonsPerWeek = gallonsPerWeek;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    _airTempController.text = '85';
    _waterTempController.text = '82';
    _humidityController.text = '50';
    setState(() { _gallonsPerDay = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
    _airTempController.dispose();
    _waterTempController.dispose();
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
        title: Text('Evaporation Loss', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'L × W', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Air Temperature', unit: 'F', hint: 'Average air temp', controller: _airTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Water Temperature', unit: 'F', hint: 'Pool temp', controller: _waterTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Humidity', unit: '%', hint: 'Relative humidity', controller: _humidityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildCoverToggle(colors),
            const SizedBox(height: 32),
            if (_gallonsPerDay != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('No Cover'), selected: !_hasCover, onSelected: (_) => setState(() { _hasCover = false; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('With Cover'), selected: _hasCover, onSelected: (_) => setState(() { _hasCover = true; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Normal loss: 1/4" to 1/2" per day', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Covers reduce evaporation by 95%', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Inches/Day', '${_inchesPerDay!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gallons/Day', '${_gallonsPerDay!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gallons/Week', '${_gallonsPerWeek!.toStringAsFixed(0)} gal'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_hasCover
            ? 'Pool cover dramatically reduces water and heat loss!'
            : 'Loss > 1/4" daily may indicate a leak. Do bucket test.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
