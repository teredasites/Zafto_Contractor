import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// O2 Sensor Calculator - Diagnose O2 sensor readings and AFR
class O2SensorScreen extends ConsumerStatefulWidget {
  const O2SensorScreen({super.key});
  @override
  ConsumerState<O2SensorScreen> createState() => _O2SensorScreenState();
}

class _O2SensorScreenState extends ConsumerState<O2SensorScreen> {
  final _voltageController = TextEditingController();
  String _sensorType = 'narrowband';

  String? _condition;
  String? _afr;
  Color? _statusColor;

  void _calculate() {
    final voltage = double.tryParse(_voltageController.text);

    if (voltage == null) {
      setState(() { _condition = null; });
      return;
    }

    String condition;
    String afr;
    Color statusColor;

    if (_sensorType == 'narrowband') {
      // Narrowband O2: 0.1V-0.9V typical range
      if (voltage < 0.1) {
        condition = 'Very Lean or Sensor Fault';
        afr = '> 16:1';
        statusColor = Colors.red;
      } else if (voltage < 0.45) {
        condition = 'Lean';
        afr = '15-16:1';
        statusColor = Colors.orange;
      } else if (voltage >= 0.45 && voltage <= 0.55) {
        condition = 'Stoichiometric (Ideal)';
        afr = '14.7:1';
        statusColor = Colors.green;
      } else if (voltage <= 0.9) {
        condition = 'Rich';
        afr = '12-14:1';
        statusColor = Colors.orange;
      } else {
        condition = 'Very Rich or Sensor Fault';
        afr = '< 12:1';
        statusColor = Colors.red;
      }
    } else {
      // Wideband: Typically 0-5V = 10:1 to 20:1 AFR
      final calculatedAfr = 10 + (voltage / 5) * 10;
      afr = '${calculatedAfr.toStringAsFixed(1)}:1';

      if (calculatedAfr < 12) {
        condition = 'Very Rich - Risk of damage';
        statusColor = Colors.red;
      } else if (calculatedAfr < 14) {
        condition = 'Rich - Power/WOT range';
        statusColor = Colors.orange;
      } else if (calculatedAfr >= 14 && calculatedAfr <= 15) {
        condition = 'Stoichiometric - Cruise';
        statusColor = Colors.green;
      } else if (calculatedAfr <= 16) {
        condition = 'Lean - Economy';
        statusColor = Colors.orange;
      } else {
        condition = 'Very Lean - Risk of damage';
        statusColor = Colors.red;
      }
    }

    setState(() {
      _condition = condition;
      _afr = afr;
      _statusColor = statusColor;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _voltageController.clear();
    setState(() { _condition = null; });
  }

  @override
  void dispose() {
    _voltageController.dispose();
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
        title: Text('O2 Sensor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSensorTypeSelector(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Sensor Voltage', unit: 'V', hint: 'Live reading', controller: _voltageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_condition != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildDiagnosticTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSensorTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SENSOR TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTypeOption(colors, 'narrowband', 'Narrowband')),
          const SizedBox(width: 12),
          Expanded(child: _buildTypeOption(colors, 'wideband', 'Wideband')),
        ]),
      ]),
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String label) {
    final isSelected = _sensorType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _sensorType = value;
          _voltageController.clear();
          _condition = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: _statusColor!.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('READING ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(_afr!, style: TextStyle(color: _statusColor, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('Air-Fuel Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _statusColor!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_condition!, style: TextStyle(color: _statusColor, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildDiagnosticTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DIAGNOSTIC TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('Narrowband O2:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• Should switch 0.1V-0.9V at idle', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Stuck high/low = faulty sensor', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Slow switching = aging sensor', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Text('Wideband O2:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• More precise AFR reading', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check heater circuit if slow warmup', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Calibrate with known AFR if possible', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
