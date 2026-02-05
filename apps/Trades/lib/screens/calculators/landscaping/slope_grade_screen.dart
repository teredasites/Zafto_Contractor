import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slope/Grade Calculator - Grade percentage and ratio
class SlopeGradeScreen extends ConsumerStatefulWidget {
  const SlopeGradeScreen({super.key});
  @override
  ConsumerState<SlopeGradeScreen> createState() => _SlopeGradeScreenState();
}

class _SlopeGradeScreenState extends ConsumerState<SlopeGradeScreen> {
  final _riseController = TextEditingController(text: '6');
  final _runController = TextEditingController(text: '100');

  String _inputUnit = 'inches';

  double? _gradePercent;
  String? _ratio;
  double? _degrees;
  String? _classification;

  @override
  void dispose() { _riseController.dispose(); _runController.dispose(); super.dispose(); }

  void _calculate() {
    var rise = double.tryParse(_riseController.text) ?? 6;
    var run = double.tryParse(_runController.text) ?? 100;

    // Convert to same units (inches)
    if (_inputUnit == 'feet') {
      rise *= 12;
      run *= 12;
    }

    if (run == 0) {
      setState(() {
        _gradePercent = null;
        _ratio = null;
        _degrees = null;
        _classification = null;
      });
      return;
    }

    final gradePercent = (rise / run) * 100;
    final ratio = run / rise;
    final degrees = 57.2958 * (rise / run).abs(); // atan approximation for small angles

    String classification;
    if (gradePercent < 1) {
      classification = 'Nearly flat';
    } else if (gradePercent < 3) {
      classification = 'Gentle slope';
    } else if (gradePercent < 8) {
      classification = 'Moderate slope';
    } else if (gradePercent < 15) {
      classification = 'Steep slope';
    } else {
      classification = 'Very steep';
    }

    setState(() {
      _gradePercent = gradePercent;
      _ratio = '1:${ratio.toStringAsFixed(1)}';
      _degrees = degrees;
      _classification = classification;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '6'; _runController.text = '100'; setState(() { _inputUnit = 'inches'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Slope & Grade', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'INPUT UNIT', ['inches', 'feet'], _inputUnit, {'inches': 'Inches', 'feet': 'Feet'}, (v) { setState(() => _inputUnit = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Rise (vertical)', unit: _inputUnit == 'inches' ? 'in' : 'ft', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Run (horizontal)', unit: _inputUnit == 'inches' ? 'in' : 'ft', controller: _runController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gradePercent != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRADE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gradePercent!.toStringAsFixed(2)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_ratio', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Degrees', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_degrees!.toStringAsFixed(1)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Classification', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_classification', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGradeGuide(colors),
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

  Widget _buildGradeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDED GRADES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Away from foundation', '2-5%'),
        _buildTableRow(colors, 'Lawn/turf', '1-3%'),
        _buildTableRow(colors, 'Patio/walkway', '1-2%'),
        _buildTableRow(colors, 'Driveway max', '12-15%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
