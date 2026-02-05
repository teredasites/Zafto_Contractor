import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Cooling Rate Calculator - Weld cooling rate estimation
class CoolingRateScreen extends ConsumerStatefulWidget {
  const CoolingRateScreen({super.key});
  @override
  ConsumerState<CoolingRateScreen> createState() => _CoolingRateScreenState();
}

class _CoolingRateScreenState extends ConsumerState<CoolingRateScreen> {
  final _thicknessController = TextEditingController();
  final _heatInputController = TextEditingController(text: '40');
  final _preheatController = TextEditingController(text: '70');
  String _material = 'Carbon Steel';

  double? _coolingRate;
  double? _t8to5;
  String? _analysis;

  // Thermal conductivity factors (relative to carbon steel)
  static const Map<String, double> _conductivityFactor = {
    'Carbon Steel': 1.0,
    'Low Alloy': 0.9,
    'Stainless 300': 0.4,
    'Stainless 400': 0.6,
    'Aluminum': 5.0,
    'Copper': 8.0,
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final heatInput = double.tryParse(_heatInputController.text) ?? 40;
    final preheat = double.tryParse(_preheatController.text) ?? 70;

    if (thickness == null || thickness <= 0 || heatInput <= 0) {
      setState(() { _coolingRate = null; });
      return;
    }

    final conductivity = _conductivityFactor[_material] ?? 1.0;

    // Simplified Rosenthal cooling rate approximation
    // R = 2πk(Tc - T0)² / H for thin plate
    // Where k = thermal conductivity, Tc = critical temp, T0 = preheat, H = heat input

    // For steel, critical temp ~550°C (1022°F) for martensite
    final criticalTemp = _material.contains('Steel') ? 1022.0 : 800.0;
    final tempDiff = criticalTemp - preheat;

    // Simplified cooling rate calculation
    double coolingRate;
    if (thickness < 0.5) {
      // Thin plate (2D heat flow)
      coolingRate = (conductivity * tempDiff * tempDiff) / (heatInput * thickness);
    } else {
      // Thick plate (3D heat flow)
      coolingRate = (conductivity * math.pow(tempDiff, 1.5)) / (heatInput * math.sqrt(thickness));
    }

    // Scale to reasonable range (°F/s at 550°C)
    coolingRate = coolingRate * 0.5;

    // Estimate t8/5 time (time to cool from 800°C to 500°C)
    final t8to5 = 300 / coolingRate; // 300°C temperature drop

    String analysis;
    if (coolingRate > 50) {
      analysis = 'Fast cooling - risk of hardening/cracking. Increase preheat or heat input';
    } else if (coolingRate > 20) {
      analysis = 'Moderate cooling - acceptable for most carbon steels';
    } else if (coolingRate > 5) {
      analysis = 'Slow cooling - good for crack-sensitive materials';
    } else {
      analysis = 'Very slow cooling - may affect mechanical properties';
    }

    setState(() {
      _coolingRate = coolingRate;
      _t8to5 = t8to5;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _heatInputController.text = '40';
    _preheatController.text = '70';
    setState(() { _coolingRate = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _heatInputController.dispose();
    _preheatController.dispose();
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
        title: Text('Cooling Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Thickness', unit: 'in', hint: 'Material thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Heat Input', unit: 'kJ/in', hint: '40 kJ/in typical', controller: _heatInputController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Preheat Temp', unit: 'F', hint: '70F ambient', controller: _preheatController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_coolingRate != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conductivityFactor.keys.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 11)),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Weld Cooling Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate HAZ cooling behavior', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Cooling Rate', '${_coolingRate!.toStringAsFixed(1)} \u00B0F/s', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 't8/5 Time', '${_t8to5!.toStringAsFixed(1)} sec'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
