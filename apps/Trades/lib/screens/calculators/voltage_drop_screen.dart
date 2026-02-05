import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../utils/calculations.dart';
import '../../data/wire_tables.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Voltage Drop Calculator - Design System v2.6
class VoltageDropScreen extends ConsumerStatefulWidget {
  const VoltageDropScreen({super.key});
  @override
  ConsumerState<VoltageDropScreen> createState() => _VoltageDropScreenState();
}

class _VoltageDropScreenState extends ConsumerState<VoltageDropScreen> {
  final _currentController = TextEditingController();
  final _distanceController = TextEditingController();
  
  int _systemVoltage = 120;
  WireSize _wireSize = WireSize.awg12;
  ConductorMaterial _material = ConductorMaterial.copper;
  bool _isThreePhase = false;
  
  double? _vdVolts;
  double? _vdPercent;
  bool? _passes;

  static const List<int> _voltageOptions = [120, 208, 240, 277, 480];

  @override
  void dispose() {
    _currentController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Voltage Drop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll, tooltip: 'Clear all'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PARAMETERS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Current',
                unit: 'A',
                hint: 'Load amperage',
                controller: _currentController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Distance',
                unit: 'ft',
                hint: 'One-way length',
                controller: _distanceController,
                onChanged: (_) => _calculate(),
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
              ZaftoInputFieldDropdown<WireSize>(
                label: 'Wire Size',
                value: _wireSize,
                items: WireSize.values.where((w) => w.numericValue >= -3 && w.numericValue <= 14).toList(),
                itemLabel: (w) => w.displayName,
                onChanged: (v) { setState(() => _wireSize = v); _calculate(); },
              ),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Material', options: const ['Copper', 'Aluminum'], selectedIndex: _material == ConductorMaterial.copper ? 0 : 1, onChanged: (i) { setState(() => _material = i == 0 ? ConductorMaterial.copper : ConductorMaterial.aluminum); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['Single (1Φ)', 'Three (3Φ)'], selectedIndex: _isThreePhase ? 1 : 0, onChanged: (i) { setState(() => _isThreePhase = i == 1); _calculate(); }),
              const SizedBox(height: 32),
              if (_vdVolts != null && _vdPercent != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('VD = (2 × K × I × D) / CM', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 15)),
        const SizedBox(height: 8),
        Text('NEC recommends ≤3% for branch circuits', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

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
    final color = _passes! ? colors.accentSuccess : colors.accentError;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_vdPercent!.toStringAsFixed(2)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 48)),
        const SizedBox(height: 4),
        Text('Voltage Drop', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildDetailItem(colors, label: 'Drop', value: '${_vdVolts!.toStringAsFixed(2)} V'),
          _buildDetailItem(colors, label: 'Delivered', value: '${(_systemVoltage - _vdVolts!).toStringAsFixed(1)} V'),
          _buildDetailItem(colors, label: 'Limit', value: '≤3.0%'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_passes! ? LucideIcons.checkCircle : LucideIcons.xCircle, color: color, size: 20),
            const SizedBox(width: 8),
            Text(_passes! ? 'PASSES NEC' : 'EXCEEDS 3% LIMIT', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetailItem(ZaftoColors colors, {required String label, required String value}) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
    ]);
  }

  void _calculate() {
    final current = double.tryParse(_currentController.text);
    final distance = double.tryParse(_distanceController.text);
    if (current == null || distance == null || current <= 0 || distance <= 0) {
      setState(() { _vdVolts = null; _vdPercent = null; _passes = null; });
      return;
    }
    final vdVolts = VoltageDrop.calculate(currentAmps: current, distanceFeet: distance, wireSize: _wireSize, material: _material, phaseMultiplier: _isThreePhase ? 1.732 : 2.0);
    final vdPercent = (vdVolts / _systemVoltage) * 100;
    setState(() { _vdVolts = vdVolts; _vdPercent = vdPercent; _passes = vdPercent <= 3.0; });
  }

  void _clearAll() {
    _currentController.clear();
    _distanceController.clear();
    setState(() { _systemVoltage = 120; _wireSize = WireSize.awg12; _material = ConductorMaterial.copper; _isThreePhase = false; _vdVolts = null; _vdPercent = null; _passes = null; });
  }
}
