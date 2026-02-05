import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Brake Caliper Piston Area Calculator
class BrakeCaliperScreen extends ConsumerStatefulWidget {
  const BrakeCaliperScreen({super.key});
  @override
  ConsumerState<BrakeCaliperScreen> createState() => _BrakeCaliperScreenState();
}

class _BrakeCaliperScreenState extends ConsumerState<BrakeCaliperScreen> {
  final _piston1Controller = TextEditingController();
  final _piston2Controller = TextEditingController();
  final _piston3Controller = TextEditingController();
  final _countController = TextEditingController(text: '2');

  double? _totalArea;
  double? _clampingForce;

  void _calculate() {
    final p1 = double.tryParse(_piston1Controller.text);
    final p2 = double.tryParse(_piston2Controller.text);
    final p3 = double.tryParse(_piston3Controller.text);
    final count = int.tryParse(_countController.text) ?? 2;

    if (p1 == null) {
      setState(() { _totalArea = null; });
      return;
    }

    double area = math.pi * math.pow(p1 / 2, 2) * count;
    if (p2 != null && p2 > 0) area += math.pi * math.pow(p2 / 2, 2) * count;
    if (p3 != null && p3 > 0) area += math.pi * math.pow(p3 / 2, 2) * count;

    // Assuming 1000 PSI line pressure for example
    final force = area * 1000;

    setState(() {
      _totalArea = area;
      _clampingForce = force;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _piston1Controller.clear();
    _piston2Controller.clear();
    _piston3Controller.clear();
    _countController.text = '2';
    setState(() { _totalArea = null; });
  }

  @override
  void dispose() {
    _piston1Controller.dispose();
    _piston2Controller.dispose();
    _piston3Controller.dispose();
    _countController.dispose();
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
        title: Text('Brake Caliper', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Piston 1 Diameter', unit: 'in', hint: 'Primary piston', controller: _piston1Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Piston 2 (optional)', unit: 'in', hint: 'Multi-piston caliper', controller: _piston2Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Piston 3 (optional)', unit: 'in', hint: '6-piston caliper', controller: _piston3Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pistons Per Size', unit: 'qty', hint: '2 for opposing pistons', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalArea != null) _buildResultsCard(colors),
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
        Text('Area = π × (D/2)² × Count', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Total piston area for clamping force calculation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Piston Area', '${_totalArea!.toStringAsFixed(2)} sq in', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Force @ 1000 PSI', '${_clampingForce!.toStringAsFixed(0)} lbs'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
