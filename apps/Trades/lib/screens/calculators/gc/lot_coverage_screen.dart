import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lot Coverage Calculator - Zoning impervious coverage
class LotCoverageScreen extends ConsumerStatefulWidget {
  const LotCoverageScreen({super.key});
  @override
  ConsumerState<LotCoverageScreen> createState() => _LotCoverageScreenState();
}

class _LotCoverageScreenState extends ConsumerState<LotCoverageScreen> {
  final _lotSizeController = TextEditingController(text: '10000');
  final _buildingController = TextEditingController(text: '2000');
  final _driveController = TextEditingController(text: '600');
  final _patioController = TextEditingController(text: '400');
  final _maxCoverageController = TextEditingController(text: '40');

  double? _totalCoverage;
  double? _coveragePct;
  double? _remaining;
  bool? _compliant;

  @override
  void dispose() { _lotSizeController.dispose(); _buildingController.dispose(); _driveController.dispose(); _patioController.dispose(); _maxCoverageController.dispose(); super.dispose(); }

  void _calculate() {
    final lotSize = double.tryParse(_lotSizeController.text);
    final building = double.tryParse(_buildingController.text) ?? 0;
    final drive = double.tryParse(_driveController.text) ?? 0;
    final patio = double.tryParse(_patioController.text) ?? 0;
    final maxPct = double.tryParse(_maxCoverageController.text) ?? 40;

    if (lotSize == null || lotSize == 0) {
      setState(() { _totalCoverage = null; _coveragePct = null; _remaining = null; _compliant = null; });
      return;
    }

    final totalCoverage = building + drive + patio;
    final coveragePct = (totalCoverage / lotSize) * 100;
    final maxAllowed = lotSize * (maxPct / 100);
    final remaining = maxAllowed - totalCoverage;
    final compliant = coveragePct <= maxPct;

    setState(() { _totalCoverage = totalCoverage; _coveragePct = coveragePct; _remaining = remaining; _compliant = compliant; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lotSizeController.text = '10000'; _buildingController.text = '2000'; _driveController.text = '600'; _patioController.text = '400'; _maxCoverageController.text = '40'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lot Coverage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Lot Size', unit: 'sq ft', controller: _lotSizeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Max Coverage', unit: '%', controller: _maxCoverageController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('IMPERVIOUS AREAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Building Footprint', unit: 'sq ft', controller: _buildingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Driveway/Walks', unit: 'sq ft', controller: _driveController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Patio/Deck', unit: 'sq ft', controller: _patioController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalCoverage != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('LOT COVERAGE', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Text('${_coveragePct!.toStringAsFixed(1)}%', style: TextStyle(color: _compliant! ? colors.accentSuccess : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Impervious Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalCoverage!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Remaining Allowed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_remaining!.toStringAsFixed(0)} sq ft', style: TextStyle(color: _remaining! >= 0 ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_compliant! ? 'COMPLIANT' : 'OVER LIMIT', style: TextStyle(color: _compliant! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check local zoning for exact limits. Pervious pavers may reduce calculated coverage.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCoverageTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverageTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL LIMITS BY ZONE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Rural/Agricultural', '10-20%'),
        _buildTableRow(colors, 'Suburban Residential', '25-40%'),
        _buildTableRow(colors, 'Urban Residential', '40-60%'),
        _buildTableRow(colors, 'Commercial', '70-90%'),
        _buildTableRow(colors, 'Industrial', '80-95%'),
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
