import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Heat Input Calculator - Joules per inch
class HeatInputScreen extends ConsumerStatefulWidget {
  const HeatInputScreen({super.key});
  @override
  ConsumerState<HeatInputScreen> createState() => _HeatInputScreenState();
}

class _HeatInputScreenState extends ConsumerState<HeatInputScreen> {
  final _voltageController = TextEditingController();
  final _amperageController = TextEditingController();
  final _travelSpeedController = TextEditingController();

  double? _heatInputJin;
  double? _heatInputKjin;
  String? _analysis;

  void _calculate() {
    final voltage = double.tryParse(_voltageController.text);
    final amperage = double.tryParse(_amperageController.text);
    final speed = double.tryParse(_travelSpeedController.text);

    if (voltage == null || amperage == null || speed == null || speed <= 0) {
      setState(() { _heatInputJin = null; });
      return;
    }

    // Heat Input = (Voltage × Amperage × 60) / Travel Speed (in/min)
    final jin = (voltage * amperage * 60) / speed;
    final kjin = jin / 1000;

    String analysis;
    if (kjin < 20) {
      analysis = 'Low heat input - good for thin materials, less distortion';
    } else if (kjin < 50) {
      analysis = 'Moderate heat input - typical for structural work';
    } else if (kjin < 80) {
      analysis = 'High heat input - may need preheat/interpass control';
    } else {
      analysis = 'Very high heat input - risk of grain growth, review WPS';
    }

    setState(() {
      _heatInputJin = jin;
      _heatInputKjin = kjin;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _voltageController.clear();
    _amperageController.clear();
    _travelSpeedController.clear();
    setState(() { _heatInputJin = null; });
  }

  @override
  void dispose() {
    _voltageController.dispose();
    _amperageController.dispose();
    _travelSpeedController.dispose();
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
        title: Text('Heat Input', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Voltage', unit: 'V', hint: 'Arc voltage', controller: _voltageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Amperage', unit: 'A', hint: 'Welding current', controller: _amperageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Travel Speed', unit: 'in/min', hint: 'IPM', controller: _travelSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_heatInputJin != null) _buildResultsCard(colors),
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
        Text('HI = (V × A × 60) / Speed', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Critical for controlling HAZ properties', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Heat Input', '${_heatInputKjin!.toStringAsFixed(1)} kJ/in', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Joules/inch', '${_heatInputJin!.toStringAsFixed(0)} J/in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
