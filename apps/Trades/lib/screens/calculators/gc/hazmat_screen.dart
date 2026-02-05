import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hazmat Assessment Calculator - Pre-demo hazard checklist
class HazmatScreen extends ConsumerStatefulWidget {
  const HazmatScreen({super.key});
  @override
  ConsumerState<HazmatScreen> createState() => _HazmatScreenState();
}

class _HazmatScreenState extends ConsumerState<HazmatScreen> {
  final _yearBuiltController = TextEditingController(text: '1965');

  bool _asbestosRisk = false;
  bool _leadPaintRisk = false;
  bool _pcbRisk = false;
  bool _moldVisible = false;
  bool _fuelTanks = false;

  String? _riskLevel;
  List<String> _requiredTests = [];

  @override
  void dispose() { _yearBuiltController.dispose(); super.dispose(); }

  void _calculate() {
    final yearBuilt = int.tryParse(_yearBuiltController.text) ?? 2000;

    final List<String> tests = [];

    // Asbestos: Common in buildings before 1980
    final asbestosRisk = yearBuilt < 1980 || _asbestosRisk;
    if (asbestosRisk) tests.add('Asbestos survey');

    // Lead paint: Required for pre-1978 buildings
    final leadPaintRisk = yearBuilt < 1978 || _leadPaintRisk;
    if (leadPaintRisk) tests.add('Lead paint testing');

    // PCBs: Electrical equipment, caulk in pre-1979 buildings
    final pcbRisk = yearBuilt < 1979 || _pcbRisk;
    if (pcbRisk) tests.add('PCB testing (caulk, ballasts)');

    // Mold
    if (_moldVisible) tests.add('Mold assessment');

    // Fuel tanks
    if (_fuelTanks) tests.add('UST/AST inspection');

    // Determine risk level
    String riskLevel;
    if (tests.isEmpty) {
      riskLevel = 'LOW';
    } else if (tests.length <= 2) {
      riskLevel = 'MODERATE';
    } else {
      riskLevel = 'HIGH';
    }

    setState(() { _riskLevel = riskLevel; _requiredTests = tests; _asbestosRisk = asbestosRisk; _leadPaintRisk = leadPaintRisk; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _yearBuiltController.text = '1965'; setState(() { _asbestosRisk = false; _leadPaintRisk = false; _pcbRisk = false; _moldVisible = false; _fuelTanks = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Hazmat Assessment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Year Built', unit: 'year', controller: _yearBuiltController, onChanged: (_) => _calculate()),
            const SizedBox(height: 20),
            Text('ADDITIONAL RISK FACTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildToggleRow(colors, 'Visible mold/water damage', _moldVisible, (v) { setState(() => _moldVisible = v); _calculate(); }),
            const SizedBox(height: 8),
            _buildToggleRow(colors, 'Underground/above ground tanks', _fuelTanks, (v) { setState(() => _fuelTanks = v); _calculate(); }),
            const SizedBox(height: 8),
            _buildToggleRow(colors, 'Suspected PCB equipment', _pcbRisk, (v) { setState(() => _pcbRisk = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_riskLevel != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('HAZMAT RISK', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _riskLevel == 'LOW' ? colors.accentSuccess.withValues(alpha: 0.2) : _riskLevel == 'MODERATE' ? colors.accentWarning.withValues(alpha: 0.2) : colors.accentError.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(_riskLevel!, style: TextStyle(color: _riskLevel == 'LOW' ? colors.accentSuccess : _riskLevel == 'MODERATE' ? colors.accentWarning : colors.accentError, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text('REQUIRED TESTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_requiredTests.isEmpty)
                  Text('No specialized testing required', style: TextStyle(color: colors.accentSuccess, fontSize: 13))
                else
                  ..._requiredTests.map((test) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                      const SizedBox(width: 8),
                      Text(test, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                    ]),
                  )),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('STOP work if hazmat discovered. Licensed abatement required. OSHA/EPA regulations apply.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRegTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentWarning.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentWarning : colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, size: 20, color: value ? colors.accentWarning : colors.textTertiary),
        ]),
      ),
    );
  }

  Widget _buildRegTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('KEY DATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Pre-1978', 'Lead paint likely'),
        _buildTableRow(colors, 'Pre-1980', 'Asbestos likely'),
        _buildTableRow(colors, 'Pre-1979', 'PCBs in caulk/ballasts'),
        _buildTableRow(colors, 'Pre-1987', 'Underground tanks'),
        _buildTableRow(colors, 'Any age', 'Mold if moisture'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }
}
