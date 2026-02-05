import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// A/C High/Low Pressure Analyzer
/// Analyzes refrigerant pressures and diagnoses system conditions
class AcPressureScreen extends ConsumerStatefulWidget {
  const AcPressureScreen({super.key});
  @override
  ConsumerState<AcPressureScreen> createState() => _AcPressureScreenState();
}

class _AcPressureScreenState extends ConsumerState<AcPressureScreen> {
  final _lowPressureController = TextEditingController();
  final _highPressureController = TextEditingController();
  final _ambientTempController = TextEditingController();

  String? _diagnosis;
  String? _lowStatus;
  String? _highStatus;
  double? _expectedLow;
  double? _expectedHigh;

  void _calculate() {
    final lowPsi = double.tryParse(_lowPressureController.text);
    final highPsi = double.tryParse(_highPressureController.text);
    final ambientTemp = double.tryParse(_ambientTempController.text);

    if (lowPsi == null || highPsi == null) {
      setState(() { _diagnosis = null; });
      return;
    }

    // Expected pressures based on ambient temp (R-134a typical values)
    double expLow = 25; // Default low side
    double expHigh = 150; // Default high side

    if (ambientTemp != null) {
      // Low side: 25-45 PSI typical, varies slightly with temp
      expLow = 25 + (ambientTemp - 70) * 0.15;
      expLow = expLow.clamp(20, 50);

      // High side: roughly 2.2-2.5x ambient temp for R-134a
      expHigh = ambientTemp * 2.35;
      expHigh = expHigh.clamp(120, 300);
    }

    // Analyze low side
    String lowStat;
    if (lowPsi < expLow - 10) {
      lowStat = 'LOW';
    } else if (lowPsi > expLow + 15) {
      lowStat = 'HIGH';
    } else {
      lowStat = 'NORMAL';
    }

    // Analyze high side
    String highStat;
    if (highPsi < expHigh - 30) {
      highStat = 'LOW';
    } else if (highPsi > expHigh + 40) {
      highStat = 'HIGH';
    } else {
      highStat = 'NORMAL';
    }

    // Diagnosis based on pressure combinations
    String diag;
    if (lowStat == 'LOW' && highStat == 'LOW') {
      diag = 'Low Refrigerant Charge - Check for leaks';
    } else if (lowStat == 'HIGH' && highStat == 'LOW') {
      diag = 'Compressor Weak/Failing - Poor compression';
    } else if (lowStat == 'LOW' && highStat == 'HIGH') {
      diag = 'Restriction in System - Check orifice/TXV';
    } else if (lowStat == 'HIGH' && highStat == 'HIGH') {
      diag = 'Overcharged or Poor Condenser Airflow';
    } else if (lowStat == 'NORMAL' && highStat == 'NORMAL') {
      diag = 'System Operating Normally';
    } else if (lowStat == 'HIGH' && highStat == 'NORMAL') {
      diag = 'Possible TXV/Orifice Issue or Overcharge';
    } else if (lowStat == 'LOW' && highStat == 'NORMAL') {
      diag = 'Slight Undercharge or Restriction';
    } else if (lowStat == 'NORMAL' && highStat == 'HIGH') {
      diag = 'Condenser Airflow Issue or Fan Problem';
    } else {
      diag = 'Check Condenser Fan Operation';
    }

    setState(() {
      _diagnosis = diag;
      _lowStatus = lowStat;
      _highStatus = highStat;
      _expectedLow = expLow;
      _expectedHigh = expHigh;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lowPressureController.clear();
    _highPressureController.clear();
    _ambientTempController.clear();
    setState(() { _diagnosis = null; });
  }

  @override
  void dispose() {
    _lowPressureController.dispose();
    _highPressureController.dispose();
    _ambientTempController.dispose();
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
        title: Text('A/C Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Low Side Pressure', unit: 'PSI', hint: 'Blue gauge reading', controller: _lowPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'High Side Pressure', unit: 'PSI', hint: 'Red gauge reading', controller: _highPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temp', unit: 'F', hint: 'Current outdoor temperature', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_diagnosis != null) _buildResultsCard(colors),
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
        Text('R-134a: High Side ~ Ambient x 2.2-2.5', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Low Side: 25-45 PSI typical at idle', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final lowColor = _lowStatus == 'NORMAL' ? colors.accentPrimary : (_lowStatus == 'LOW' ? Colors.blue : Colors.orange);
    final highColor = _highStatus == 'NORMAL' ? colors.accentPrimary : (_highStatus == 'LOW' ? Colors.blue : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_diagnosis!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        _buildStatusRow(colors, 'Low Side', _lowStatus!, lowColor),
        const SizedBox(height: 12),
        _buildStatusRow(colors, 'High Side', _highStatus!, highColor),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Expected Low', '${_expectedLow!.toStringAsFixed(0)} PSI'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Expected High', '${_expectedHigh!.toStringAsFixed(0)} PSI'),
      ]),
    );
  }

  Widget _buildStatusRow(ZaftoColors colors, String label, String status, Color statusColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
