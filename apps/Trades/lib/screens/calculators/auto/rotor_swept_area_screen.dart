import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Rotor Swept Area Calculator - Brake rotor surface area
class RotorSweptAreaScreen extends ConsumerStatefulWidget {
  const RotorSweptAreaScreen({super.key});
  @override
  ConsumerState<RotorSweptAreaScreen> createState() => _RotorSweptAreaScreenState();
}

class _RotorSweptAreaScreenState extends ConsumerState<RotorSweptAreaScreen> {
  final _outerDiameterController = TextEditingController();
  final _innerDiameterController = TextEditingController();
  final _rotorCountController = TextEditingController(text: '4');

  double? _sweptArea;
  double? _totalArea;

  void _calculate() {
    final outerDia = double.tryParse(_outerDiameterController.text);
    final innerDia = double.tryParse(_innerDiameterController.text);
    final rotorCount = int.tryParse(_rotorCountController.text) ?? 4;

    if (outerDia == null || innerDia == null) {
      setState(() { _sweptArea = null; });
      return;
    }

    // Swept area = π × (outer radius² - inner radius²) × 2 sides
    final outerRadius = outerDia / 2;
    final innerRadius = innerDia / 2;
    final areaPerRotor = math.pi * (math.pow(outerRadius, 2) - math.pow(innerRadius, 2)) * 2;
    final total = areaPerRotor * rotorCount;

    setState(() {
      _sweptArea = areaPerRotor;
      _totalArea = total;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _outerDiameterController.clear();
    _innerDiameterController.clear();
    _rotorCountController.text = '4';
    setState(() { _sweptArea = null; });
  }

  @override
  void dispose() {
    _outerDiameterController.dispose();
    _innerDiameterController.dispose();
    _rotorCountController.dispose();
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
        title: Text('Rotor Swept Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Outer Diameter', unit: 'in', hint: 'Rotor OD', controller: _outerDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Inner Diameter', unit: 'in', hint: 'Inner pad sweep', controller: _innerDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rotor Count', unit: 'rotors', hint: '4 for typical car', controller: _rotorCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sweptArea != null) _buildResultsCard(colors),
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
        Text('Area = π × (R²outer - R²inner) × 2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('More swept area = better heat dissipation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Per Rotor', '${_sweptArea!.toStringAsFixed(1)} sq in', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total System', '${_totalArea!.toStringAsFixed(1)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Larger swept area improves fade resistance during repeated hard braking.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
