import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../utils/calculations.dart';
import '../../data/wire_tables.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Wire Sizing Calculator - Design System v2.6
class WireSizingScreen extends ConsumerStatefulWidget {
  const WireSizingScreen({super.key});
  @override
  ConsumerState<WireSizingScreen> createState() => _WireSizingScreenState();
}

class _WireSizingScreenState extends ConsumerState<WireSizingScreen> {
  final _loadAmpsController = TextEditingController();
  final _distanceController = TextEditingController();
  
  int _breakerAmps = 20;
  int _systemVoltage = 120;
  ConductorMaterial _material = ConductorMaterial.copper;
  TempRating _tempRating = TempRating.temp75c;
  bool _isThreePhase = false;
  WireSizingResult? _result;

  static const List<int> _breakerOptions = [15, 20, 30, 40, 50, 60, 70, 80, 100, 125, 150, 200];
  static const List<int> _voltageOptions = [120, 208, 240, 277, 480];

  @override
  void dispose() { _loadAmpsController.dispose(); _distanceController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wire Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll, tooltip: 'Clear all')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CIRCUIT PARAMETERS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Load Current',
                unit: 'A',
                hint: 'Actual load amperage',
                controller: _loadAmpsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'One-Way Distance',
                unit: 'ft',
                hint: 'Wire run length',
                controller: _distanceController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputFieldDropdown<int>(
                label: 'Breaker Size',
                value: _breakerAmps,
                items: _breakerOptions,
                itemLabel: (v) => '$v A',
                onChanged: (v) { setState(() => _breakerAmps = v); _calculate(); },
              ),
              const SizedBox(height: 12),
              ZaftoInputFieldDropdown<int>(
                label: 'System Voltage',
                value: _systemVoltage,
                items: _voltageOptions,
                itemLabel: (v) => '$v V',
                onChanged: (v) { setState(() => _systemVoltage = v); _calculate(); },
              ),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Conductor Material', options: const ['Copper', 'Aluminum'], selectedIndex: _material == ConductorMaterial.copper ? 0 : 1, onChanged: (i) { setState(() => _material = i == 0 ? ConductorMaterial.copper : ConductorMaterial.aluminum); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['Single (1Φ)', 'Three (3Φ)'], selectedIndex: _isThreePhase ? 1 : 0, onChanged: (i) { setState(() => _isThreePhase = i == 1); _calculate(); }),
              const SizedBox(height: 32),
              if (_result != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED MATERIALS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildSectionHeader(colors, 'COMPLIANCE CHECKS'),
                const SizedBox(height: 12),
                _buildComplianceCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Enter load and distance to get complete material list with NEC compliance check.', style: TextStyle(color: colors.accentSuccess, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(index); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: EdgeInsets.only(right: index < options.length - 1 ? 8 : 0),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
              child: Text(options[index], textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
            ),
          ));
        })),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        _buildResultRow(colors, icon: LucideIcons.zap, label: 'Wire Size', value: _result!.recommendedWire?.displayName ?? 'N/A', sublabel: '${_result!.material.name} THHN', color: colors.accentSuccess),
        Divider(color: colors.borderSubtle, height: 24),
        _buildResultRow(colors, icon: LucideIcons.zap, label: 'Ground Wire', value: _result!.material == ConductorMaterial.copper ? _result!.groundWireCopper ?? 'N/A' : _result!.groundWireAluminum ?? 'N/A', sublabel: 'AWG ${_result!.material.name}', color: colors.accentWarning),
        Divider(color: colors.borderSubtle, height: 24),
        _buildResultRow(colors, icon: LucideIcons.circle, label: 'Conduit', value: _result!.recommendedConduit?.displayName ?? 'N/A', sublabel: _result!.conduitType.shortName, color: colors.accentPrimary),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, {required IconData icon, required String label, required String value, required String sublabel, required Color color}) {
    return Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        Text(sublabel, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ])),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 22)),
    ]);
  }

  Widget _buildComplianceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        _buildCheckRow(colors, label: 'Ampacity', value: '${_result!.wireAmpacity ?? 0}A @ 75°C', passed: _result!.ampacityPasses, necRef: 'NEC 310.16'),
        const SizedBox(height: 12),
        _buildCheckRow(colors, label: 'Voltage Drop', value: '${_result!.voltageDropPercent.toStringAsFixed(2)}%', passed: _result!.voltageDropPasses, necRef: 'NEC 210.19(A)'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (_result!.allChecksPassed ? colors.accentSuccess : colors.accentError).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_result!.allChecksPassed ? LucideIcons.checkCircle : LucideIcons.xCircle, color: _result!.allChecksPassed ? colors.accentSuccess : colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text(_result!.allChecksPassed ? 'ALL CHECKS PASSED' : 'FAILED - SEE ABOVE', style: TextStyle(color: _result!.allChecksPassed ? colors.accentSuccess : colors.accentError, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCheckRow(ZaftoColors colors, {required String label, required String value, required bool passed, required String necRef}) {
    final color = passed ? colors.accentSuccess : colors.accentError;
    return Row(children: [
      Icon(passed ? LucideIcons.checkCircle : LucideIcons.xCircle, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        Text(necRef, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]);
  }

  void _calculate() {
    final loadAmps = double.tryParse(_loadAmpsController.text);
    final distance = double.tryParse(_distanceController.text);
    if (loadAmps == null || distance == null || loadAmps <= 0 || distance <= 0) { setState(() => _result = null); return; }
    final result = WireSizing.calculate(loadAmps: loadAmps, distanceFeet: distance, systemVoltage: _systemVoltage.toDouble(), breakerAmps: _breakerAmps, tempRating: _tempRating, material: _material, isThreePhase: _isThreePhase);
    setState(() => _result = result);
  }

  void _clearAll() { _loadAmpsController.clear(); _distanceController.clear(); setState(() { _breakerAmps = 20; _systemVoltage = 120; _material = ConductorMaterial.copper; _isThreePhase = false; _result = null; }); }
}
