import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Master Cylinder Calculator - Size and output pressure
class MasterCylinderScreen extends ConsumerStatefulWidget {
  const MasterCylinderScreen({super.key});
  @override
  ConsumerState<MasterCylinderScreen> createState() => _MasterCylinderScreenState();
}

class _MasterCylinderScreenState extends ConsumerState<MasterCylinderScreen> {
  final _boreController = TextEditingController();
  final _pedalForceController = TextEditingController(text: '100');
  final _pedalRatioController = TextEditingController(text: '6');
  final _boosterRatioController = TextEditingController(text: '3');

  double? _pistonArea;
  double? _linePressure;

  void _calculate() {
    final bore = double.tryParse(_boreController.text);
    final pedalForce = double.tryParse(_pedalForceController.text) ?? 100;
    final pedalRatio = double.tryParse(_pedalRatioController.text) ?? 6;
    final boosterRatio = double.tryParse(_boosterRatioController.text) ?? 1;

    if (bore == null || bore <= 0) {
      setState(() { _pistonArea = null; });
      return;
    }

    final area = math.pi * math.pow(bore / 2, 2);
    final totalForce = pedalForce * pedalRatio * boosterRatio;
    final pressure = totalForce / area;

    setState(() {
      _pistonArea = area;
      _linePressure = pressure;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boreController.clear();
    _pedalForceController.text = '100';
    _pedalRatioController.text = '6';
    _boosterRatioController.text = '3';
    setState(() { _pistonArea = null; });
  }

  @override
  void dispose() {
    _boreController.dispose();
    _pedalForceController.dispose();
    _pedalRatioController.dispose();
    _boosterRatioController.dispose();
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
        title: Text('Master Cylinder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Bore Diameter', unit: 'in', hint: 'MC piston diameter', controller: _boreController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pedal Force', unit: 'lbs', hint: 'Foot pressure', controller: _pedalForceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pedal Ratio', unit: ':1', hint: 'Mechanical advantage', controller: _pedalRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Booster Ratio', unit: ':1', hint: '1 if no booster', controller: _boosterRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pistonArea != null) _buildResultsCard(colors),
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
        Text('PSI = Force × Ratios / Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Smaller bore = more pressure but more pedal travel', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Line Pressure', '${_linePressure!.toStringAsFixed(0)} psi', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Piston Area', '${_pistonArea!.toStringAsFixed(3)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Common MC Sizes:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('7/8" - Light pedal, long travel\n1" - Balanced\n1-1/8" - Firm pedal, short travel', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
