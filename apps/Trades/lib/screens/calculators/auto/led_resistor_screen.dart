import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// LED Resistor Calculator - Calculate resistor for LED circuits
class LedResistorScreen extends ConsumerStatefulWidget {
  const LedResistorScreen({super.key});
  @override
  ConsumerState<LedResistorScreen> createState() => _LedResistorScreenState();
}

class _LedResistorScreenState extends ConsumerState<LedResistorScreen> {
  final _supplyVoltageController = TextEditingController(text: '12');
  final _ledVoltageController = TextEditingController(text: '2.0');
  final _ledCurrentController = TextEditingController(text: '20');
  final _ledCountController = TextEditingController(text: '1');

  double? _resistorOhms;
  double? _resistorWatts;
  String? _standardResistor;

  final List<double> _standardValues = [
    10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82,
    100, 120, 150, 180, 220, 270, 330, 390, 470, 560, 680, 820,
    1000, 1200, 1500, 1800, 2200, 2700, 3300, 3900, 4700, 5600, 6800, 8200,
    10000,
  ];

  void _calculate() {
    final supplyV = double.tryParse(_supplyVoltageController.text);
    final ledV = double.tryParse(_ledVoltageController.text);
    final ledMa = double.tryParse(_ledCurrentController.text);
    final ledCount = int.tryParse(_ledCountController.text) ?? 1;

    if (supplyV == null || ledV == null || ledMa == null || ledMa <= 0) {
      setState(() { _resistorOhms = null; });
      return;
    }

    final ledI = ledMa / 1000; // Convert to amps
    final totalLedV = ledV * ledCount;

    if (totalLedV >= supplyV) {
      setState(() { _resistorOhms = null; });
      return;
    }

    final resistor = (supplyV - totalLedV) / ledI;
    final watts = (supplyV - totalLedV) * ledI;

    // Find nearest standard resistor (round up for safety)
    String? standard;
    for (final val in _standardValues) {
      if (val >= resistor) {
        standard = val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0);
        break;
      }
    }

    setState(() {
      _resistorOhms = resistor;
      _resistorWatts = watts;
      _standardResistor = standard;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _supplyVoltageController.text = '12';
    _ledVoltageController.text = '2.0';
    _ledCurrentController.text = '20';
    _ledCountController.text = '1';
    setState(() { _resistorOhms = null; });
  }

  @override
  void dispose() {
    _supplyVoltageController.dispose();
    _ledVoltageController.dispose();
    _ledCurrentController.dispose();
    _ledCountController.dispose();
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
        title: Text('LED Resistor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Supply Voltage', unit: 'V', hint: '12V typical', controller: _supplyVoltageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'LED Forward Voltage', unit: 'V', hint: 'Per LED', controller: _ledVoltageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'LED Current', unit: 'mA', hint: '20mA typical', controller: _ledCurrentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'LEDs in Series', unit: 'count', hint: '1 for single LED', controller: _ledCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_resistorOhms != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildLedVoltagesCard(colors),
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
        Text('R = (Vs - Vled) / I', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Resistor limits current to protect LED', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final wattsRating = _resistorWatts! < 0.25 ? '1/4W' : (_resistorWatts! < 0.5 ? '1/2W' : '1W+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RESISTOR NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_resistorOhms!.toStringAsFixed(0)}Ω', style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
        if (_standardResistor != null)
          Text('Use ${_standardResistor}Ω standard', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Power Dissipation', '${(_resistorWatts! * 1000).toStringAsFixed(0)} mW'),
        _buildResultRow(colors, 'Minimum Rating', wattsRating),
      ]),
    );
  }

  Widget _buildLedVoltagesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL LED VOLTAGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildLedRow(colors, 'Red', '1.8-2.2V', const Color(0xFFFF0000)),
        _buildLedRow(colors, 'Yellow', '2.0-2.2V', const Color(0xFFFFEB3B)),
        _buildLedRow(colors, 'Green', '2.0-3.0V', const Color(0xFF4CAF50)),
        _buildLedRow(colors, 'Blue', '3.0-3.5V', const Color(0xFF2196F3)),
        _buildLedRow(colors, 'White', '3.0-3.5V', const Color(0xFFFFFFFF)),
      ]),
    );
  }

  Widget _buildLedRow(ZaftoColors colors, String color, String voltage, Color ledColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: ledColor, shape: BoxShape.circle, border: Border.all(color: colors.borderSubtle))),
        const SizedBox(width: 8),
        Text(color, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const Spacer(),
        Text(voltage, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
