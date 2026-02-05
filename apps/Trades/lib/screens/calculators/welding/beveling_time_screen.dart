import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Beveling Time Calculator - Estimate pipe/plate beveling time
class BevelingTimeScreen extends ConsumerStatefulWidget {
  const BevelingTimeScreen({super.key});
  @override
  ConsumerState<BevelingTimeScreen> createState() => _BevelingTimeScreenState();
}

class _BevelingTimeScreenState extends ConsumerState<BevelingTimeScreen> {
  final _diameterController = TextEditingController();
  final _thicknessController = TextEditingController(text: '0.5');
  final _quantityController = TextEditingController(text: '1');
  String _material = 'Carbon Steel';
  String _method = 'Grinder';

  double? _bevelingTime;
  double? _totalTime;
  String? _notes;

  // Beveling rates (inches per minute of circumference)
  static const Map<String, double> _bevelRates = {
    'Grinder': 2.0,
    'Torch': 4.0,
    'Plasma': 8.0,
    'Pipe Beveler': 15.0,
    'Machine': 20.0,
  };

  // Material difficulty factors
  static const Map<String, double> _materialFactors = {
    'Carbon Steel': 1.0,
    'Stainless': 1.4,
    'Chrome-Moly': 1.3,
    'Aluminum': 0.8,
    'Inconel': 1.6,
  };

  void _calculate() {
    final diameter = double.tryParse(_diameterController.text);
    final thickness = double.tryParse(_thicknessController.text) ?? 0.5;
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (diameter == null || diameter <= 0) {
      setState(() { _bevelingTime = null; });
      return;
    }

    final circumference = math.pi * diameter;
    final bevelRate = _bevelRates[_method] ?? 2.0;
    final materialFactor = _materialFactors[_material] ?? 1.0;

    // Thickness factor (thicker = slower)
    final thicknessFactor = 1 + (thickness - 0.25) * 0.5;

    // Time in minutes
    final bevelingTimePerJoint = (circumference / bevelRate) * materialFactor * thicknessFactor;
    final totalTime = bevelingTimePerJoint * quantity;

    String notes;
    if (_method == 'Grinder') {
      notes = 'Hand grinding - good for field work, slowest method';
    } else if (_method == 'Torch') {
      notes = 'Oxy-fuel bevel - requires cleanup grinding';
    } else if (_method == 'Plasma') {
      notes = 'Plasma bevel - faster but may need grinding';
    } else if (_method == 'Pipe Beveler') {
      notes = 'Portable pipe beveler - consistent, efficient';
    } else {
      notes = 'Stationary beveling machine - production rates';
    }

    setState(() {
      _bevelingTime = bevelingTimePerJoint;
      _totalTime = totalTime;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _diameterController.clear();
    _thicknessController.text = '0.5';
    _quantityController.text = '1';
    setState(() { _bevelingTime = null; });
  }

  @override
  void dispose() {
    _diameterController.dispose();
    _thicknessController.dispose();
    _quantityController.dispose();
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
        title: Text('Beveling Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Beveling Method', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMethodSelector(colors),
            const SizedBox(height: 16),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pipe/Plate Diameter', unit: 'in', hint: 'OD or length', controller: _diameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wall/Plate Thickness', unit: 'in', hint: 'Material thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Quantity', unit: 'pcs', hint: 'Number of bevels', controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bevelingTime != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bevelRates.keys.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 11)),
        selected: _method == m,
        onSelected: (_) => setState(() { _method = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _materialFactors.keys.map((m) => ChoiceChip(
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
        Text('Beveling Time Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate joint preparation beveling time', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Time', '${_totalTime!.toStringAsFixed(0)} min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Bevel', '${_bevelingTime!.toStringAsFixed(1)} min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hours', '${(_totalTime! / 60).toStringAsFixed(2)} hrs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
