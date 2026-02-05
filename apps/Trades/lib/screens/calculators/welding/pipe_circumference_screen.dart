import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Pipe Circumference Calculator - Pipe weld length calculations
class PipeCircumferenceScreen extends ConsumerStatefulWidget {
  const PipeCircumferenceScreen({super.key});
  @override
  ConsumerState<PipeCircumferenceScreen> createState() => _PipeCircumferenceScreenState();
}

class _PipeCircumferenceScreenState extends ConsumerState<PipeCircumferenceScreen> {
  final _pipeSizeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _sizeType = 'NPS';
  bool _useOD = false;

  double? _circumference;
  double? _totalLength;
  double? _odValue;

  // NPS to OD conversion (inches)
  static const Map<String, double> _npsToOD = {
    '1/2': 0.840,
    '3/4': 1.050,
    '1': 1.315,
    '1-1/4': 1.660,
    '1-1/2': 1.900,
    '2': 2.375,
    '2-1/2': 2.875,
    '3': 3.500,
    '4': 4.500,
    '6': 6.625,
    '8': 8.625,
    '10': 10.750,
    '12': 12.750,
    '14': 14.000,
    '16': 16.000,
    '18': 18.000,
    '20': 20.000,
    '24': 24.000,
  };

  void _calculate() {
    double? od;

    if (_useOD) {
      od = double.tryParse(_pipeSizeController.text);
    } else {
      od = _npsToOD[_pipeSizeController.text];
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (od == null || od <= 0) {
      setState(() { _circumference = null; });
      return;
    }

    final circumference = math.pi * od;
    final totalLength = circumference * quantity;

    setState(() {
      _circumference = circumference;
      _totalLength = totalLength;
      _odValue = od;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeSizeController.clear();
    _quantityController.text = '1';
    setState(() { _circumference = null; });
  }

  @override
  void dispose() {
    _pipeSizeController.dispose();
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
        title: Text('Pipe Circumference', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildInputToggle(colors),
            const SizedBox(height: 16),
            if (_useOD)
              ZaftoInputField(label: 'Outside Diameter', unit: 'in', hint: 'Pipe OD', controller: _pipeSizeController, onChanged: (_) => _calculate())
            else
              _buildNPSSelector(colors),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Quantity', unit: 'joints', hint: 'Number of welds', controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_circumference != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInputToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('NPS Size'), selected: !_useOD, onSelected: (_) => setState(() { _useOD = false; _pipeSizeController.clear(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Enter OD'), selected: _useOD, onSelected: (_) => setState(() { _useOD = true; _pipeSizeController.clear(); })),
    ]);
  }

  Widget _buildNPSSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _npsToOD.keys.map((nps) => ChoiceChip(
          label: Text(nps, style: const TextStyle(fontSize: 11)),
          selected: _pipeSizeController.text == nps,
          onSelected: (_) => setState(() { _pipeSizeController.text = nps; _calculate(); }),
        )).toList(),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('C = \u03C0 x OD', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Circumference = weld length per joint', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Circumference', '${_circumference!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'In Feet', '${(_circumference! / 12).toStringAsFixed(3)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Length', '${(_totalLength! / 12).toStringAsFixed(2)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pipe OD', '${_odValue!.toStringAsFixed(3)}"'),
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
