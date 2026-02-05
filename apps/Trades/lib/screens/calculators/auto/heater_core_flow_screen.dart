import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Heater Core Flow Rate Calculator
class HeaterCoreFlowScreen extends ConsumerStatefulWidget {
  const HeaterCoreFlowScreen({super.key});
  @override
  ConsumerState<HeaterCoreFlowScreen> createState() => _HeaterCoreFlowScreenState();
}

class _HeaterCoreFlowScreenState extends ConsumerState<HeaterCoreFlowScreen> {
  final _btuRequiredController = TextEditingController(text: '25000');
  final _inletTempController = TextEditingController(text: '180');
  final _outletTempController = TextEditingController(text: '160');

  double? _flowRateGpm;
  double? _flowRateLpm;
  double? _heatOutput;
  String? _diagnosis;

  void _calculate() {
    final btuRequired = double.tryParse(_btuRequiredController.text);
    final inletTemp = double.tryParse(_inletTempController.text);
    final outletTemp = double.tryParse(_outletTempController.text);

    if (btuRequired == null || inletTemp == null || outletTemp == null) {
      setState(() { _flowRateGpm = null; });
      return;
    }

    final deltaT = inletTemp - outletTemp;
    if (deltaT <= 0) {
      setState(() { _flowRateGpm = null; });
      return;
    }

    // Heat transfer formula: Q = m * Cp * deltaT
    // For water/coolant: Q (BTU/hr) = GPM * 500 * deltaT
    // Therefore: GPM = Q / (500 * deltaT)
    final gpm = btuRequired / (500 * deltaT);
    final lpm = gpm * 3.785;

    // Actual heat output with calculated flow
    final actualBtu = gpm * 500 * deltaT;

    // Diagnosis based on typical values
    String diag;
    if (gpm < 1.5) {
      diag = 'Low flow - Check for clogged heater core or restricted hoses';
    } else if (gpm > 5.0) {
      diag = 'High flow - Consider adding flow restrictor for better heat transfer';
    } else if (deltaT < 15) {
      diag = 'Low temp drop - Excellent heat transfer, core in good condition';
    } else if (deltaT > 30) {
      diag = 'High temp drop - Possible low flow or partially blocked core';
    } else {
      diag = 'Normal operating range - System functioning properly';
    }

    setState(() {
      _flowRateGpm = gpm;
      _flowRateLpm = lpm;
      _heatOutput = actualBtu;
      _diagnosis = diag;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _btuRequiredController.text = '25000';
    _inletTempController.text = '180';
    _outletTempController.text = '160';
    setState(() { _flowRateGpm = null; });
  }

  @override
  void dispose() {
    _btuRequiredController.dispose();
    _inletTempController.dispose();
    _outletTempController.dispose();
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
        title: Text('Heater Core Flow', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Heat Required', unit: 'BTU/hr', hint: 'Typical: 20,000-35,000', controller: _btuRequiredController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Inlet Temperature', unit: 'F', hint: 'Coolant entering core', controller: _inletTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Outlet Temperature', unit: 'F', hint: 'Coolant leaving core', controller: _outletTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_flowRateGpm != null) _buildResultsCard(colors),
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
        Text('GPM = BTU / (500 x Delta T)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Typical heater core: 2-4 GPM at 20°F drop', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final inletTemp = double.tryParse(_inletTempController.text) ?? 180;
    final outletTemp = double.tryParse(_outletTempController.text) ?? 160;
    final deltaT = inletTemp - outletTemp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Required Flow Rate', '${_flowRateGpm!.toStringAsFixed(2)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Rate (Metric)', '${_flowRateLpm!.toStringAsFixed(2)} L/min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Temperature Drop', '${deltaT.toStringAsFixed(0)}°F'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Heat Output', '${(_heatOutput! / 1000).toStringAsFixed(1)}k BTU/hr'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_diagnosis!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          ]),
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
