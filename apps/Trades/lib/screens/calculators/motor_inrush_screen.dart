import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Starting / Inrush Calculator - Design System v2.6
class MotorInrushScreen extends ConsumerStatefulWidget {
  const MotorInrushScreen({super.key});
  @override
  ConsumerState<MotorInrushScreen> createState() => _MotorInrushScreenState();
}

class _MotorInrushScreenState extends ConsumerState<MotorInrushScreen> {
  double _hp = 10;
  int _voltage = 480;
  bool _isThreePhase = true;
  String _lrcCode = 'G';

  static const Map<String, double> _lrcKvaPerHp = {'A': 3.15, 'B': 3.55, 'C': 4.0, 'D': 4.5, 'E': 5.0, 'F': 5.6, 'G': 6.3, 'H': 7.1, 'J': 8.0, 'K': 9.0, 'L': 10.0, 'M': 11.2, 'N': 12.5, 'P': 14.0, 'R': 16.0, 'S': 18.0, 'T': 20.0, 'U': 22.4};

  double get _fla => _isThreePhase ? (_hp * 746) / (_voltage * 1.732 * 0.9 * 0.85) : (_hp * 746) / (_voltage * 0.9 * 0.85);
  double get _lrcKva => (_lrcKvaPerHp[_lrcCode] ?? 6.3) * _hp;
  double get _inrushAmps => _isThreePhase ? (_lrcKva * 1000) / (_voltage * 1.732) : (_lrcKva * 1000) / _voltage;
  double get _inrushMultiplier => _fla > 0 ? _inrushAmps / _fla : 0;
  String get _startingDuration { if (_hp <= 5) return '2-4 sec'; if (_hp <= 25) return '4-8 sec'; if (_hp <= 100) return '8-15 sec'; return '15-30 sec'; }
  int get _maxOcpd { final maxAmps = _fla * 2.5; const sizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500, 600]; for (final size in sizes) { if (size >= maxAmps) return size; } return 600; }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Motor Inrush', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildMotorConfig(colors),
        const SizedBox(height: 16),
        _buildLrcSelector(colors),
        const SizedBox(height: 20),
        _buildResultsCard(colors),
        const SizedBox(height: 16),
        _buildLrcTable(colors),
        const SizedBox(height: 16),
        _buildCodeReference(colors),
      ]),
    );
  }

  Widget _buildMotorConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MOTOR SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text('Horsepower', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [1.0, 2.0, 3.0, 5.0, 7.5, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0, 75.0, 100.0].map((hp) {
          final isSelected = _hp == hp;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _hp = hp); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${hp.toStringAsFixed(hp == hp.toInt() ? 0 : 1)}', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 12))),
          );
        }).toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phase', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [_phaseBtn(colors, '1φ', false), const SizedBox(width: 8), _phaseBtn(colors, '3φ', true)]),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voltage', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: DropdownButton<int>(value: _voltage, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: (_isThreePhase ? [208, 230, 460, 480, 575] : [115, 120, 208, 230, 240]).map((v) => DropdownMenuItem(value: v, child: Text('${v}V'))).toList(), onChanged: (v) => setState(() => _voltage = v!))),
          ])),
        ]),
      ]),
    );
  }

  Widget _phaseBtn(ZaftoColors colors, String label, bool isThree) {
    final isSelected = _isThreePhase == isThree;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() { _isThreePhase = isThree; _voltage = isThree ? 480 : 240; }); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13))),
    );
  }

  Widget _buildLrcSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('LOCKED ROTOR CODE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)), const Spacer(), Text('(from nameplate)', style: TextStyle(color: colors.textTertiary, fontSize: 10))]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: _lrcKvaPerHp.keys.map((code) {
          final isSelected = _lrcCode == code;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _lrcCode = code); },
            child: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(code, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text('Code G is typical for general purpose motors', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_inrushAmps.toStringAsFixed(0)}A', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('Inrush / Locked Rotor Current', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text('${_inrushMultiplier.toStringAsFixed(1)}× FLA', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)), child: Column(children: [
          _buildRow(colors, 'Full Load Amps', '${_fla.toStringAsFixed(1)}A', false),
          const SizedBox(height: 10),
          _buildRow(colors, 'LRC kVA', '${_lrcKva.toStringAsFixed(1)}', false),
          const SizedBox(height: 10),
          _buildRow(colors, 'Starting Duration', _startingDuration, false),
          Divider(color: colors.borderSubtle, height: 20),
          _buildRow(colors, 'Max OCPD (250%)', '${_maxOcpd}A', true),
        ])),
      ]),
    );
  }

  Widget _buildLrcTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC TABLE 430.251(B)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('kVA per HP by Code Letter', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        Wrap(spacing: 4, runSpacing: 4, children: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'].map((code) {
          final kva = _lrcKvaPerHp[code]!;
          final isSelected = _lrcCode == code;
          return Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase, borderRadius: BorderRadius.circular(6), border: isSelected ? Border.all(color: colors.accentPrimary) : null), child: Column(children: [Text(code, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)), Text('$kva', style: TextStyle(color: colors.textTertiary, fontSize: 10))]));
        }).toList()),
      ]),
    );
  }

  Widget _buildRow(ZaftoColors colors, String label, String value, bool highlight) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500))]);

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 430.251', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• LRC code on motor nameplate\n• Higher code = higher inrush\n• Used for OCPD coordination\n• Consider soft starters for high HP', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
