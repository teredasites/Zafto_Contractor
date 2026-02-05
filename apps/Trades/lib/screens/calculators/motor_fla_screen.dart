import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../data/nec_tables.dart';

/// Motor FLA Calculator - Design System v2.6
class MotorFlaScreen extends ConsumerStatefulWidget {
  const MotorFlaScreen({super.key});
  @override
  ConsumerState<MotorFlaScreen> createState() => _MotorFlaScreenState();
}

class _MotorFlaScreenState extends ConsumerState<MotorFlaScreen> {
  bool _isThreePhase = false;
  double _selectedHp = 1.0;
  int _selectedVoltage = 120;
  double? _fla;

  static const List<double> _singlePhaseHp = [0.167, 0.25, 0.333, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0, 7.5, 10.0];
  static const List<double> _threePhaseHp = [0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0, 7.5, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0, 60.0, 75.0, 100.0, 125.0, 150.0, 200.0];
  List<double> get _availableHp => _isThreePhase ? _threePhaseHp : _singlePhaseHp;
  List<int> get _availableVoltages => _isThreePhase ? [200, 208, 230, 460, 575] : [115, 200, 208, 230];

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Motor FLA', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildNecRefCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'MOTOR TYPE'),
            const SizedBox(height: 12),
            _buildPhaseToggle(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'HORSEPOWER'),
            const SizedBox(height: 12),
            _buildHpSelector(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'VOLTAGE'),
            const SizedBox(height: 12),
            _buildVoltageSelector(colors),
            const SizedBox(height: 32),
            _buildSectionHeader(colors, 'FULL LOAD AMPS'),
            const SizedBox(height: 12),
            _buildResultCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNecRefCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(LucideIcons.zap, color: colors.accentWarning, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isThreePhase ? 'NEC Table 430.250' : 'NEC Table 430.248', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          Text(_isThreePhase ? 'Three-Phase AC Motors' : 'Single-Phase AC Motors', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ])),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildPhaseToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _isThreePhase = false; _selectedHp = _availableHp.first; _selectedVoltage = _availableVoltages.first; }); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: !_isThreePhase ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Single Phase', style: TextStyle(color: !_isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: !_isThreePhase ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
              Text('1Φ', style: TextStyle(color: !_isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary, fontWeight: FontWeight.w700, fontSize: 20)),
            ]),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _isThreePhase = true; _selectedHp = _availableHp.first; _selectedVoltage = _availableVoltages.first; }); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: _isThreePhase ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Three Phase', style: TextStyle(color: _isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: _isThreePhase ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
              Text('3Φ', style: TextStyle(color: _isThreePhase ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary, fontWeight: FontWeight.w700, fontSize: 20)),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildHpSelector(ZaftoColors colors) {
    return Wrap(spacing: 8, runSpacing: 8, children: _availableHp.map((hp) {
      final isSelected = hp == _selectedHp;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedHp = hp); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('${_formatHp(hp)} HP', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        ),
      );
    }).toList());
  }

  Widget _buildVoltageSelector(ZaftoColors colors) {
    return Wrap(spacing: 8, runSpacing: 8, children: _availableVoltages.map((v) {
      final isSelected = v == _selectedVoltage;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedVoltage = v); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: isSelected ? colors.accentWarning : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentWarning : colors.borderSubtle)),
          child: Text('$v V', style: TextStyle(color: isSelected ? Colors.black : colors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        ),
      );
    }).toList());
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text(_fla != null ? _fla!.toStringAsFixed(1) : '--', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w700, fontSize: 56)),
        Text('AMPS', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w500, letterSpacing: 2, fontSize: 18)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildSpecItem(colors, 'Motor', '${_formatHp(_selectedHp)} HP'),
          _buildSpecItem(colors, 'Voltage', '$_selectedVoltage V'),
          _buildSpecItem(colors, 'Phase', _isThreePhase ? '3Φ' : '1Φ'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, color: colors.textTertiary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Use 125% of FLA for conductor sizing (NEC 430.22)', style: TextStyle(color: colors.textTertiary, fontSize: 12))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
    ]);
  }

  String _formatHp(double hp) {
    if (hp == 0.167) return '1/6'; if (hp == 0.25) return '1/4'; if (hp == 0.333) return '1/3'; if (hp == 0.5) return '1/2'; if (hp == 0.75) return '3/4';
    if (hp == hp.truncate()) return hp.truncate().toString(); return hp.toString();
  }

  void _calculate() {
    double? fla;
    if (_isThreePhase) { fla = ThreePhaseMotorFla.getFla(_selectedHp, _selectedVoltage); }
    else { fla = SinglePhaseMotorFla.getFla(_selectedHp, _selectedVoltage); }
    setState(() => _fla = fla);
  }
}
