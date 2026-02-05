import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// A/C Vent Temperature Analysis
/// Analyzes vent output temperature and system performance
class AcVentTempScreen extends ConsumerStatefulWidget {
  const AcVentTempScreen({super.key});
  @override
  ConsumerState<AcVentTempScreen> createState() => _AcVentTempScreenState();
}

class _AcVentTempScreenState extends ConsumerState<AcVentTempScreen> {
  final _ventTempController = TextEditingController();
  final _ambientTempController = TextEditingController();
  final _humidityController = TextEditingController(text: '50');

  double? _tempDrop;
  String? _performance;
  String? _diagnosis;
  double? _expectedVentTemp;
  double? _efficiencyPercent;

  void _calculate() {
    final ventTemp = double.tryParse(_ventTempController.text);
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final humidity = double.tryParse(_humidityController.text) ?? 50;

    if (ventTemp == null || ambientTemp == null) {
      setState(() { _tempDrop = null; });
      return;
    }

    final tempDrop = ambientTemp - ventTemp;

    // Expected vent temp based on ambient and humidity
    // Higher humidity = harder to cool, so expected vent temp increases
    double expectedVent = 38 + (humidity - 50) * 0.1;
    if (ambientTemp > 95) {
      expectedVent += (ambientTemp - 95) * 0.3;
    }
    expectedVent = expectedVent.clamp(35, 55);

    // Calculate efficiency
    // Ideal temp drop is about 40-50F from ambient
    final idealDrop = 45.0;
    final efficiency = (tempDrop / idealDrop * 100).clamp(0, 150);

    String perf;
    String diag;

    if (ventTemp <= 40) {
      perf = 'EXCELLENT';
      diag = 'System operating at peak performance';
    } else if (ventTemp <= 45) {
      perf = 'GOOD';
      diag = 'Normal operation - adequate cooling';
    } else if (ventTemp <= 50) {
      perf = 'FAIR';
      diag = 'Slightly reduced performance - check refrigerant level';
    } else if (ventTemp <= 55) {
      perf = 'MARGINAL';
      diag = 'Below normal - possible low charge, restriction, or compressor issue';
    } else if (ventTemp <= 60) {
      perf = 'POOR';
      diag = 'Significant issue - check charge, compressor, and airflow';
    } else {
      perf = 'FAILING';
      diag = 'System not cooling - major component failure likely';
    }

    // Adjust for high ambient/humidity
    if (ambientTemp > 100 && ventTemp <= 55) {
      diag = '$diag (Note: High ambient temp affects performance)';
    }
    if (humidity > 70 && ventTemp <= 50) {
      diag = '$diag (Note: High humidity reduces efficiency)';
    }

    setState(() {
      _tempDrop = tempDrop;
      _performance = perf;
      _diagnosis = diag;
      _expectedVentTemp = expectedVent;
      _efficiencyPercent = efficiency.toDouble();
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ventTempController.clear();
    _ambientTempController.clear();
    _humidityController.text = '50';
    setState(() { _tempDrop = null; });
  }

  @override
  void dispose() {
    _ventTempController.dispose();
    _ambientTempController.dispose();
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
        title: Text('Vent Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vent Temperature', unit: 'F', hint: 'Center vent output temperature', controller: _ventTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temp', unit: 'F', hint: 'Outside air temperature', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Humidity', unit: '%', hint: 'Relative humidity', controller: _humidityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tempDrop != null) _buildResultsCard(colors),
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
        Text('Target Vent Temp: 38-48°F', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Measure at center dash vent, max A/C, recirculate', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color perfColor;
    switch (_performance) {
      case 'EXCELLENT':
        perfColor = Colors.green;
        break;
      case 'GOOD':
        perfColor = colors.accentPrimary;
        break;
      case 'FAIR':
        perfColor = Colors.amber;
        break;
      case 'MARGINAL':
        perfColor = Colors.orange;
        break;
      case 'POOR':
      case 'FAILING':
        perfColor = Colors.red;
        break;
      default:
        perfColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: perfColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(_performance!, style: TextStyle(color: perfColor, fontWeight: FontWeight.w700, fontSize: 22)),
        ),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Temperature Drop', '${_tempDrop!.toStringAsFixed(1)}°F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Efficiency', '${_efficiencyPercent!.toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Expected Vent Temp', '${_expectedVentTemp!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_diagnosis!, style: TextStyle(color: colors.textPrimary, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        _buildTempScale(colors),
      ]),
    );
  }

  Widget _buildTempScale(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text('Vent Temperature Scale', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildScaleItem(colors, '35-40°F', 'Excellent', Colors.green),
          _buildScaleItem(colors, '40-50°F', 'Good', colors.accentPrimary),
          _buildScaleItem(colors, '50-55°F', 'Fair', Colors.orange),
          _buildScaleItem(colors, '55°F+', 'Poor', Colors.red),
        ]),
      ]),
    );
  }

  Widget _buildScaleItem(ZaftoColors colors, String temp, String label, Color color) {
    return Column(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(temp, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
