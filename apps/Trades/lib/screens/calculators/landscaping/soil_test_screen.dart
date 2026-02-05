import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Soil Test Interpreter - Amendment recommendations
class SoilTestScreen extends ConsumerStatefulWidget {
  const SoilTestScreen({super.key});
  @override
  ConsumerState<SoilTestScreen> createState() => _SoilTestScreenState();
}

class _SoilTestScreenState extends ConsumerState<SoilTestScreen> {
  final _phController = TextEditingController(text: '6.5');
  final _nController = TextEditingController(text: '40');
  final _pController = TextEditingController(text: '30');
  final _kController = TextEditingController(text: '150');

  String? _phStatus;
  String? _nStatus;
  String? _pStatus;
  String? _kStatus;
  List<String> _recommendations = [];

  @override
  void dispose() { _phController.dispose(); _nController.dispose(); _pController.dispose(); _kController.dispose(); super.dispose(); }

  void _calculate() {
    final ph = double.tryParse(_phController.text) ?? 6.5;
    final n = double.tryParse(_nController.text) ?? 40;
    final p = double.tryParse(_pController.text) ?? 30;
    final k = double.tryParse(_kController.text) ?? 150;

    final recommendations = <String>[];

    // pH interpretation
    String phStatus;
    if (ph < 5.5) {
      phStatus = 'Very Acidic';
      recommendations.add('Apply lime: 50-100 lbs/1000 sq ft');
    } else if (ph < 6.0) {
      phStatus = 'Acidic';
      recommendations.add('Apply lime: 25-50 lbs/1000 sq ft');
    } else if (ph <= 7.0) {
      phStatus = 'Optimal';
    } else if (ph <= 7.5) {
      phStatus = 'Alkaline';
      recommendations.add('Apply sulfur: 5-10 lbs/1000 sq ft');
    } else {
      phStatus = 'Very Alkaline';
      recommendations.add('Apply sulfur: 10-20 lbs/1000 sq ft');
    }

    // Nitrogen (ppm)
    String nStatus;
    if (n < 25) {
      nStatus = 'Low';
      recommendations.add('Apply nitrogen fertilizer');
    } else if (n <= 50) {
      nStatus = 'Adequate';
    } else {
      nStatus = 'High';
    }

    // Phosphorus (ppm)
    String pStatus;
    if (p < 15) {
      pStatus = 'Low';
      recommendations.add('Apply phosphorus (bone meal or 0-46-0)');
    } else if (p <= 40) {
      pStatus = 'Adequate';
    } else {
      pStatus = 'High';
    }

    // Potassium (ppm)
    String kStatus;
    if (k < 100) {
      kStatus = 'Low';
      recommendations.add('Apply potassium (potash or 0-0-60)');
    } else if (k <= 200) {
      kStatus = 'Adequate';
    } else {
      kStatus = 'High';
    }

    if (recommendations.isEmpty) {
      recommendations.add('Soil nutrients are adequate');
    }

    setState(() {
      _phStatus = phStatus;
      _nStatus = nStatus;
      _pStatus = pStatus;
      _kStatus = kStatus;
      _recommendations = recommendations;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _phController.text = '6.5'; _nController.text = '40'; _pController.text = '30'; _kController.text = '150'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Soil Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'pH', unit: '', controller: _phController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Nitrogen', unit: 'ppm', controller: _nController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Phosphorus', unit: 'ppm', controller: _pController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Potassium', unit: 'ppm', controller: _kController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 24),
            if (_phStatus != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RESULTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildResultRow(colors, 'pH', _phStatus!),
                _buildResultRow(colors, 'Nitrogen (N)', _nStatus!),
                _buildResultRow(colors, 'Phosphorus (P)', _pStatus!),
                _buildResultRow(colors, 'Potassium (K)', _kStatus!),
              ]),
            ),
            const SizedBox(height: 16),
            if (_recommendations.isNotEmpty) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RECOMMENDATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                ..._recommendations.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ', style: TextStyle(color: colors.accentPrimary, fontSize: 12)),
                    Expanded(child: Text(r, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
                  ]),
                )),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLevelsGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String status) {
    Color statusColor;
    if (status == 'Optimal' || status == 'Adequate') {
      statusColor = colors.accentSuccess;
    } else if (status.contains('Very')) {
      statusColor = colors.accentError;
    } else {
      statusColor = colors.accentWarning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildLevelsGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OPTIMAL RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'pH (turf)', '6.0-7.0'),
        _buildTableRow(colors, 'Nitrogen', '25-50 ppm'),
        _buildTableRow(colors, 'Phosphorus', '15-40 ppm'),
        _buildTableRow(colors, 'Potassium', '100-200 ppm'),
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
