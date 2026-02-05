import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drip Irrigation Calculator - Emitters and tubing
class DripIrrigationScreen extends ConsumerStatefulWidget {
  const DripIrrigationScreen({super.key});
  @override
  ConsumerState<DripIrrigationScreen> createState() => _DripIrrigationScreenState();
}

class _DripIrrigationScreenState extends ConsumerState<DripIrrigationScreen> {
  final _plantsController = TextEditingController(text: '20');
  final _gphController = TextEditingController(text: '1');
  final _spacingController = TextEditingController(text: '3');
  final _rowLengthController = TextEditingController(text: '50');

  String _calcType = 'plants';

  int? _emitters;
  double? _totalGph;
  double? _tubing;
  double? _runTime;

  @override
  void dispose() { _plantsController.dispose(); _gphController.dispose(); _spacingController.dispose(); _rowLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final gphPerEmitter = double.tryParse(_gphController.text) ?? 1;

    int emitters;
    double tubing;

    if (_calcType == 'plants') {
      emitters = int.tryParse(_plantsController.text) ?? 20;
      tubing = emitters * 2; // Estimate 2 ft tubing per plant
    } else {
      final rowLength = double.tryParse(_rowLengthController.text) ?? 50;
      final spacing = double.tryParse(_spacingController.text) ?? 3;
      emitters = (rowLength / spacing).ceil();
      tubing = rowLength;
    }

    final totalGph = emitters * gphPerEmitter;
    // Run time to deliver 1 gallon per plant
    final runTime = 60 / gphPerEmitter; // minutes

    setState(() {
      _emitters = emitters;
      _totalGph = totalGph;
      _tubing = tubing;
      _runTime = runTime;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _plantsController.text = '20'; _gphController.text = '1'; _spacingController.text = '3'; _rowLengthController.text = '50'; setState(() { _calcType = 'plants'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Drip Irrigation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'CALCULATE BY', ['plants', 'row'], _calcType, {'plants': 'Plant Count', 'row': 'Row Length'}, (v) { setState(() => _calcType = v); _calculate(); }),
            const SizedBox(height: 20),
            if (_calcType == 'plants')
              ZaftoInputField(label: 'Number of Plants', unit: '', controller: _plantsController, onChanged: (_) => _calculate())
            else ...[
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Row Length', unit: 'ft', controller: _rowLengthController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Emitter Spacing', unit: 'ft', controller: _spacingController, onChanged: (_) => _calculate())),
              ]),
            ],
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Emitter Flow Rate', unit: 'GPH', controller: _gphController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_emitters != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EMITTERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_emitters', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalGph!.toStringAsFixed(1)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tubing needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubing!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Run time (1 gal/plant)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_runTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check pressure: Most drip systems need 15-30 PSI with a pressure regulator.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildEmitterGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildEmitterGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EMITTER FLOW RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '0.5 GPH', 'Containers, small plants'),
        _buildTableRow(colors, '1 GPH', 'Most plants, shrubs'),
        _buildTableRow(colors, '2 GPH', 'Trees, large shrubs'),
        _buildTableRow(colors, '4 GPH', 'Trees, fast drainage'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
