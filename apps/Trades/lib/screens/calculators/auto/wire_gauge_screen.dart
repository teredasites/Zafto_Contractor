import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wire Gauge Calculator - Select proper wire size for automotive circuits
class WireGaugeScreen extends ConsumerStatefulWidget {
  const WireGaugeScreen({super.key});
  @override
  ConsumerState<WireGaugeScreen> createState() => _WireGaugeScreenState();
}

class _WireGaugeScreenState extends ConsumerState<WireGaugeScreen> {
  final _ampsController = TextEditingController();
  final _lengthController = TextEditingController();
  final _voltageDropController = TextEditingController(text: '3');

  String? _recommendedGauge;
  double? _actualDrop;

  // Wire resistance per foot (ohms) for common gauges
  final Map<String, double> _wireResistance = {
    '18 AWG': 0.00651,
    '16 AWG': 0.00409,
    '14 AWG': 0.00257,
    '12 AWG': 0.00162,
    '10 AWG': 0.00102,
    '8 AWG': 0.000641,
    '6 AWG': 0.000403,
    '4 AWG': 0.000253,
    '2 AWG': 0.000159,
    '0 AWG': 0.0001,
  };

  // Max amps for each gauge (chassis wiring)
  final Map<String, int> _maxAmps = {
    '18 AWG': 10,
    '16 AWG': 15,
    '14 AWG': 20,
    '12 AWG': 25,
    '10 AWG': 35,
    '8 AWG': 50,
    '6 AWG': 65,
    '4 AWG': 85,
    '2 AWG': 115,
    '0 AWG': 150,
  };

  void _calculate() {
    final amps = double.tryParse(_ampsController.text);
    final length = double.tryParse(_lengthController.text);
    final maxDrop = double.tryParse(_voltageDropController.text) ?? 3;

    if (amps == null || length == null) {
      setState(() { _recommendedGauge = null; });
      return;
    }

    // Find smallest gauge that works
    String? selectedGauge;
    double? voltageDrop;

    for (final entry in _wireResistance.entries) {
      final gauge = entry.key;
      final resistance = entry.value;
      final maxAmp = _maxAmps[gauge]!;

      if (amps > maxAmp) continue;

      // Voltage drop = I × R × 2 (round trip)
      final drop = amps * resistance * length * 2;
      final dropPercent = (drop / 12) * 100;

      if (dropPercent <= maxDrop) {
        selectedGauge = gauge;
        voltageDrop = dropPercent;
        break;
      }
    }

    setState(() {
      _recommendedGauge = selectedGauge;
      _actualDrop = voltageDrop;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ampsController.clear();
    _lengthController.clear();
    _voltageDropController.text = '3';
    setState(() { _recommendedGauge = null; });
  }

  @override
  void dispose() {
    _ampsController.dispose();
    _lengthController.dispose();
    _voltageDropController.dispose();
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
        title: Text('Wire Gauge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Draw', unit: 'amps', hint: 'Circuit amperage', controller: _ampsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wire Length (One Way)', unit: 'ft', hint: 'To load', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Voltage Drop', unit: '%', hint: 'Typical: 3%', controller: _voltageDropController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedGauge != null) _buildResultsCard(colors),
            if (_recommendedGauge == null && _ampsController.text.isNotEmpty) _buildNoMatchCard(colors),
            const SizedBox(height: 24),
            _buildReferenceCard(colors),
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
        Text('V-Drop = I × R × Length × 2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Keep voltage drop under 3% for reliable operation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_recommendedGauge!, style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Voltage Drop', '${_actualDrop!.toStringAsFixed(2)}%'),
        _buildResultRow(colors, 'Max Capacity', '${_maxAmps[_recommendedGauge]} amps'),
      ]),
    );
  }

  Widget _buildNoMatchCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('No standard gauge meets requirements. Consider shorter runs, larger cable, or multiple circuits.', style: TextStyle(color: colors.error, fontSize: 13)),
    );
  }

  Widget _buildReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('QUICK REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._maxAmps.entries.take(6).map((e) => _buildRefRow(colors, e.key, '${e.value} amps')),
      ]),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String gauge, String amps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(gauge, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(amps, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
