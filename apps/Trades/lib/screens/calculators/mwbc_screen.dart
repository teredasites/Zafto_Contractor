import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Multi-Wire Branch Circuit Calculator - Design System v2.6
class MwbcScreen extends ConsumerStatefulWidget {
  const MwbcScreen({super.key});
  @override
  ConsumerState<MwbcScreen> createState() => _MwbcScreenState();
}

class _MwbcScreenState extends ConsumerState<MwbcScreen> {
  double _loadA = 15.0;
  double _loadB = 12.0;
  int _circuitAmps = 20;
  final int _voltage = 120;

  double get _neutralCurrent => (_loadA - _loadB).abs();
  double get _maxLegCurrent => _loadA > _loadB ? _loadA : _loadB;
  double get _powerA => _loadA * _voltage;
  double get _powerB => _loadB * _voltage;
  double get _totalPower => _powerA + _powerB;
  bool get _isOverloaded => _maxLegCurrent > _circuitAmps;
  bool get _isBalanced => _neutralCurrent < 1.0;
  String get _wireSize { if (_circuitAmps <= 15) return '14 AWG'; if (_circuitAmps <= 20) return '12 AWG'; if (_circuitAmps <= 30) return '10 AWG'; return '8 AWG'; }
  String get _breakerConfig => '2-pole ${_circuitAmps}A';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Multi-Wire Branch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildInfoCard(colors),
        const SizedBox(height: 16),
        _buildInputCard(colors),
        const SizedBox(height: 16),
        _buildCircuitConfig(colors),
        const SizedBox(height: 20),
        _buildResultsCard(colors),
        const SizedBox(height: 16),
        _buildDiagramCard(colors),
        const SizedBox(height: 16),
        _buildCodeReference(colors),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('MWBC: Two ungrounded conductors sharing one neutral, fed from opposite phases (240V between hots).', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4))),
      ]),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LEG CURRENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors.accentError, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text('Phase A (Hot 1)', style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
        const SizedBox(height: 8),
        _buildSlider(colors, _loadA, (v) => setState(() => _loadA = v), colors.accentError),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text('Phase B (Hot 2)', style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
        const SizedBox(height: 8),
        _buildSlider(colors, _loadB, (v) => setState(() => _loadB = v), colors.accentInfo),
      ]),
    );
  }

  Widget _buildSlider(ZaftoColors colors, double value, Function(double) onChanged, Color color) {
    return Row(children: [
      Expanded(child: SliderTheme(
        data: SliderThemeData(activeTrackColor: color, inactiveTrackColor: color.withValues(alpha: 0.2), thumbColor: color, overlayColor: color.withValues(alpha: 0.1)),
        child: Slider(value: value, min: 0, max: 30, onChanged: onChanged),
      )),
      Container(width: 60, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6)), child: Text('${value.toStringAsFixed(1)}A', textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildCircuitConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CIRCUIT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text('Breaker Size', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 6),
        Row(children: [15, 20, 30].map((a) {
          final isSelected = _circuitAmps == a;
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _circuitAmps = a); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${a}A', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13))),
          ));
        }).toList()),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _isOverloaded ? colors.accentError : (_isBalanced ? colors.accentSuccess : colors.accentWarning);
    final statusText = _isOverloaded ? 'OVERLOADED' : (_isBalanced ? 'BALANCED' : 'UNBALANCED');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),
        Text('${_neutralCurrent.toStringAsFixed(1)}A', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('Neutral Current', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)), child: Column(children: [
          _buildRow(colors, 'Phase A Load', '${_loadA.toStringAsFixed(1)}A', false),
          const SizedBox(height: 8),
          _buildRow(colors, 'Phase B Load', '${_loadB.toStringAsFixed(1)}A', false),
          Divider(color: colors.borderSubtle, height: 20),
          _buildRow(colors, 'Total Power', '${(_totalPower / 1000).toStringAsFixed(2)} kW', false),
          const SizedBox(height: 8),
          _buildRow(colors, 'Breaker', _breakerConfig, false),
          const SizedBox(height: 8),
          _buildRow(colors, 'Wire Size', _wireSize, true),
        ])),
        if (_isOverloaded) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Load exceeds ${_circuitAmps}A breaker rating', style: TextStyle(color: colors.accentError, fontSize: 12))),
          ])),
        ],
      ]),
    );
  }

  Widget _buildDiagramCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MWBC CONFIGURATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _diagramRow(colors, 'Phase A (L1)', colors.accentError, '120V to N'),
          const SizedBox(height: 4),
          _diagramRow(colors, 'Phase B (L2)', colors.accentInfo, '120V to N'),
          const SizedBox(height: 4),
          _diagramRow(colors, 'Neutral', colors.textPrimary, 'Shared return'),
          const SizedBox(height: 4),
          _diagramRow(colors, 'Ground', colors.accentSuccess, 'Equipment ground'),
          Divider(color: colors.borderSubtle, height: 16),
          Row(children: [Icon(LucideIcons.link, color: colors.textTertiary, size: 14), const SizedBox(width: 8), Text('240V between L1-L2 (opposite phases)', style: TextStyle(color: colors.textTertiary, fontSize: 11))]),
        ])),
      ]),
    );
  }

  Widget _diagramRow(ZaftoColors colors, String label, Color color, String note) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
      Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
    ]);
  }

  Widget _buildRow(ZaftoColors colors, String label, String value, bool highlight) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500))]);

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 210.4 / 300.13(B)', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Must use 2-pole breaker or handle tie\n• Neutral carries unbalanced current only\n• 300.13(B): Neutral cannot be interrupted\n• All conductors from same cable/raceway', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
