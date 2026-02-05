import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// 12V Voltage Drop Calculator - Wire gauge for automotive circuits
class VoltageDrop12vScreen extends ConsumerStatefulWidget {
  const VoltageDrop12vScreen({super.key});
  @override
  ConsumerState<VoltageDrop12vScreen> createState() => _VoltageDrop12vScreenState();
}

class _VoltageDrop12vScreenState extends ConsumerState<VoltageDrop12vScreen> {
  final _ampsController = TextEditingController();
  final _lengthController = TextEditingController();
  final _gaugeController = TextEditingController();

  double? _voltageDrop;
  double? _dropPercent;
  String? _recommendation;

  // Resistance per foot (milliohms) by AWG
  static const Map<int, double> _resistance = {
    0: 0.0983, 2: 0.156, 4: 0.249, 6: 0.395, 8: 0.628,
    10: 0.999, 12: 1.588, 14: 2.525, 16: 4.016, 18: 6.385,
  };

  void _calculate() {
    final amps = double.tryParse(_ampsController.text);
    final length = double.tryParse(_lengthController.text);
    final gauge = int.tryParse(_gaugeController.text);

    if (amps == null || length == null || gauge == null || !_resistance.containsKey(gauge)) {
      setState(() { _voltageDrop = null; });
      return;
    }

    // V = I × R × 2 (round trip)
    final resistance = _resistance[gauge]! / 1000; // Convert to ohms
    final drop = amps * resistance * length * 2;
    final percent = (drop / 12.6) * 100;

    String rec;
    if (percent <= 3) {
      rec = 'Excellent - minimal power loss';
    } else if (percent <= 5) {
      rec = 'Acceptable for most applications';
    } else if (percent <= 10) {
      rec = 'High - may cause dim lights or slow motors';
    } else {
      rec = 'Excessive - use larger wire gauge';
    }

    setState(() {
      _voltageDrop = drop;
      _dropPercent = percent;
      _recommendation = rec;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ampsController.clear();
    _lengthController.clear();
    _gaugeController.clear();
    setState(() { _voltageDrop = null; });
  }

  @override
  void dispose() {
    _ampsController.dispose();
    _lengthController.dispose();
    _gaugeController.dispose();
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
        title: Text('12V Voltage Drop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Draw', unit: 'A', hint: 'Load amperage', controller: _ampsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wire Length', unit: 'ft', hint: 'One way distance', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wire Gauge', unit: 'AWG', hint: '10, 12, 14, 16, 18', controller: _gaugeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_voltageDrop != null) _buildResultsCard(colors),
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
        Text('V Drop = Amps × Resistance × Length × 2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Keep drop under 3% for critical circuits', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Voltage Drop', '${_voltageDrop!.toStringAsFixed(2)} V', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Drop Percent', '${_dropPercent!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
