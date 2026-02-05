import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Subcool Calculator - Liquid line subcooling
class SubcoolScreen extends ConsumerStatefulWidget {
  const SubcoolScreen({super.key});
  @override
  ConsumerState<SubcoolScreen> createState() => _SubcoolScreenState();
}

class _SubcoolScreenState extends ConsumerState<SubcoolScreen> {
  final _highSidePressureController = TextEditingController();
  final _liquidLineTempController = TextEditingController();

  double? _satTemp;
  double? _subcool;
  String? _status;

  void _calculate() {
    final highSidePressure = double.tryParse(_highSidePressureController.text);
    final liquidLineTemp = double.tryParse(_liquidLineTempController.text);

    if (highSidePressure == null || liquidLineTemp == null) {
      setState(() { _subcool = null; });
      return;
    }

    // R-134a P/T approximation (simplified)
    // Saturation temp ≈ pressure * 0.43 + 32 (rough approximation)
    final satTemp = highSidePressure * 0.43 + 32;
    final subcool = satTemp - liquidLineTemp;

    String status;
    if (subcool < 5) {
      status = 'Low subcool - possible low charge or restriction';
    } else if (subcool <= 15) {
      status = 'Normal subcooling range';
    } else {
      status = 'High subcool - possible overcharge or airflow issue';
    }

    setState(() {
      _satTemp = satTemp;
      _subcool = subcool;
      _status = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _highSidePressureController.clear();
    _liquidLineTempController.clear();
    setState(() { _subcool = null; });
  }

  @override
  void dispose() {
    _highSidePressureController.dispose();
    _liquidLineTempController.dispose();
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
        title: Text('Subcooling', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'High Side Pressure', unit: 'psi', hint: 'Red gauge', controller: _highSidePressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Liquid Line Temp', unit: '°F', hint: 'At condenser outlet', controller: _liquidLineTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_subcool != null) _buildResultsCard(colors),
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
        Text('Subcool = Sat Temp - Liquid Temp', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Measures how much liquid is cooled below saturation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_subcool! >= 5 && _subcool! <= 15) {
      statusColor = colors.accentSuccess;
    } else if (_subcool! < 5) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('SUBCOOLING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_subcool!.toStringAsFixed(1)}°F', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Sat temp: ${_satTemp!.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        Text('Target: 8-12°F subcooling', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }
}
