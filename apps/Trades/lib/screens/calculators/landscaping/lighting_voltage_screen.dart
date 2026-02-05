import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lighting Voltage Drop Calculator - Low voltage landscape lighting
class LightingVoltageScreen extends ConsumerStatefulWidget {
  const LightingVoltageScreen({super.key});
  @override
  ConsumerState<LightingVoltageScreen> createState() => _LightingVoltageScreenState();
}

class _LightingVoltageScreenState extends ConsumerState<LightingVoltageScreen> {
  final _totalWattsController = TextEditingController(text: '100');
  final _runLengthController = TextEditingController(text: '100');

  String _wireGauge = '12';

  double? _voltageDrop;
  double? _voltageAtEnd;
  bool? _acceptable;
  String? _recommendation;

  @override
  void dispose() { _totalWattsController.dispose(); _runLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final watts = double.tryParse(_totalWattsController.text) ?? 100;
    final length = double.tryParse(_runLengthController.text) ?? 100;
    final gauge = int.tryParse(_wireGauge) ?? 12;

    // 12V system
    const voltage = 12.0;
    final amps = watts / voltage;

    // Resistance per 1000 ft (ohms) - approximate
    double ohmsPer1000;
    switch (gauge) {
      case 16:
        ohmsPer1000 = 4.0;
        break;
      case 14:
        ohmsPer1000 = 2.5;
        break;
      case 12:
        ohmsPer1000 = 1.6;
        break;
      case 10:
        ohmsPer1000 = 1.0;
        break;
      default:
        ohmsPer1000 = 1.6;
    }

    // Voltage drop = I × R × 2 (round trip)
    final resistance = (length / 1000) * ohmsPer1000;
    final drop = amps * resistance * 2;
    final endVoltage = voltage - drop;

    // 10% max drop acceptable (1.2V)
    final ok = drop <= 1.2;

    String recommendation;
    if (ok) {
      recommendation = 'Wire size is adequate';
    } else if (gauge > 10) {
      recommendation = 'Use heavier gauge wire';
    } else {
      recommendation = 'Split into multiple runs';
    }

    setState(() {
      _voltageDrop = drop;
      _voltageAtEnd = endVoltage;
      _acceptable = ok;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _totalWattsController.text = '100'; _runLengthController.text = '100'; setState(() { _wireGauge = '12'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lighting Voltage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WIRE GAUGE', ['16', '14', '12', '10'], _wireGauge, {'16': '16 AWG', '14': '14 AWG', '12': '12 AWG', '10': '10 AWG'}, (v) { setState(() => _wireGauge = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Fixture Watts', unit: 'W', controller: _totalWattsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wire Run Length', unit: 'ft', controller: _runLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_voltageDrop != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('VOLTAGE DROP', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_voltageDrop!.toStringAsFixed(2)}V', style: TextStyle(color: _acceptable! ? colors.accentSuccess : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Voltage at end', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_voltageAtEnd!.toStringAsFixed(1)}V', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_acceptable! ? 'Acceptable' : 'Too much drop', style: TextStyle(color: _acceptable! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            if (_recommendation != null && !_acceptable!) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_recommendation!, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 20),
            _buildLightingGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildLightingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WIRE CAPACITY (12V)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '16 AWG', '48W @ 100ft'),
        _buildTableRow(colors, '14 AWG', '72W @ 100ft'),
        _buildTableRow(colors, '12 AWG', '100W @ 100ft'),
        _buildTableRow(colors, '10 AWG', '150W @ 100ft'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
