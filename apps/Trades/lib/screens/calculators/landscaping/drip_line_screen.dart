import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drip Line Calculator - Tubing length for beds
class DripLineScreen extends ConsumerStatefulWidget {
  const DripLineScreen({super.key});
  @override
  ConsumerState<DripLineScreen> createState() => _DripLineScreenState();
}

class _DripLineScreenState extends ConsumerState<DripLineScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '4');

  String _emitterSpacing = '12';

  double? _totalLineFt;
  int? _emitterCount;
  double? _gphTotal;
  int? _runTime;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 4;
    final spacing = double.tryParse(_emitterSpacing) ?? 12;

    // Row spacing typically 12" for drip line
    final rowSpacingFt = 1.0;
    final rows = (width / rowSpacingFt).ceil();
    final totalLine = rows * length;

    // Emitters
    final spacingFt = spacing / 12;
    final emittersPerRow = (length / spacingFt).ceil();
    final totalEmitters = emittersPerRow * rows;

    // GPH (standard 0.5 GPH emitters in drip line)
    final gph = totalEmitters * 0.5;

    // Runtime for 1" of water (~0.6 gal/sq ft)
    final area = length * width;
    final gallonsNeeded = area * 0.6;
    final runtime = gallonsNeeded / gph * 60; // minutes

    setState(() {
      _totalLineFt = totalLine;
      _emitterCount = totalEmitters;
      _gphTotal = gph;
      _runTime = runtime.round();
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '4'; setState(() { _emitterSpacing = '12'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Drip Line', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EMITTER SPACING', ['6', '12', '18', '24'], _emitterSpacing, {'6': '6\"', '12': '12\"', '18': '18\"', '24': '24\"'}, (v) { setState(() => _emitterSpacing = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bed Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalLineFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DRIP LINE NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLineFt!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Emitters', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_emitterCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gphTotal!.toStringAsFixed(1)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Runtime for 1\"', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_runTime min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDripGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDripGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DRIP LINE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Row spacing', '12\" typical'),
        _buildTableRow(colors, 'Max run length', '200-300 ft'),
        _buildTableRow(colors, 'Pressure', '15-25 PSI'),
        _buildTableRow(colors, 'Filter', 'Required, 150 mesh'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
