import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slope Calculator - Grade percentage for drainage
class SlopeCalculatorScreen extends ConsumerStatefulWidget {
  const SlopeCalculatorScreen({super.key});
  @override
  ConsumerState<SlopeCalculatorScreen> createState() => _SlopeCalculatorScreenState();
}

class _SlopeCalculatorScreenState extends ConsumerState<SlopeCalculatorScreen> {
  final _riseController = TextEditingController(text: '6');
  final _runController = TextEditingController(text: '100');

  String _inputUnit = 'inches_feet';

  double? _slopePercent;
  double? _slopeRatio;
  double? _slopeDegrees;

  @override
  void dispose() { _riseController.dispose(); _runController.dispose(); super.dispose(); }

  void _calculate() {
    final rise = double.tryParse(_riseController.text) ?? 6;
    final run = double.tryParse(_runController.text) ?? 100;

    if (run <= 0) {
      setState(() { _slopePercent = null; _slopeRatio = null; _slopeDegrees = null; });
      return;
    }

    double riseInFeet;
    double runInFeet;

    switch (_inputUnit) {
      case 'inches_feet':
        riseInFeet = rise / 12;
        runInFeet = run;
        break;
      case 'feet_feet':
        riseInFeet = rise;
        runInFeet = run;
        break;
      case 'inches_inches':
        riseInFeet = rise / 12;
        runInFeet = run / 12;
        break;
      default:
        riseInFeet = rise / 12;
        runInFeet = run;
    }

    final slopePercent = (riseInFeet / runInFeet) * 100;
    final slopeRatio = runInFeet / riseInFeet;
    final slopeDegrees = math.atan(riseInFeet / runInFeet) * (180 / math.pi);

    setState(() {
      _slopePercent = slopePercent;
      _slopeRatio = slopeRatio;
      _slopeDegrees = slopeDegrees;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '6'; _runController.text = '100'; setState(() { _inputUnit = 'inches_feet'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Slope Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'INPUT UNITS', ['inches_feet', 'feet_feet', 'inches_inches'], _inputUnit, {'inches_feet': 'in / ft', 'feet_feet': 'ft / ft', 'inches_inches': 'in / in'}, (v) { setState(() => _inputUnit = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Rise (vertical)', unit: _inputUnit.startsWith('inches') ? 'in' : 'ft', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Run (horizontal)', unit: _inputUnit.endsWith('feet') ? 'ft' : 'in', controller: _runController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_slopePercent != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SLOPE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_slopePercent!.toStringAsFixed(2)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1:${_slopeRatio!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Degrees', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_slopeDegrees!.toStringAsFixed(2)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _getSlopeColor(colors), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSlopeRecommendation(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGradeTable(colors),
          ]),
        ),
      ),
    );
  }

  Color _getSlopeColor(ZaftoColors colors) {
    if (_slopePercent == null) return colors.bgElevated;
    if (_slopePercent! < 1) return colors.accentError.withValues(alpha: 0.1);
    if (_slopePercent! >= 1 && _slopePercent! <= 3) return colors.accentSuccess.withValues(alpha: 0.1);
    if (_slopePercent! > 3 && _slopePercent! <= 5) return colors.accentWarning.withValues(alpha: 0.1);
    return colors.accentError.withValues(alpha: 0.1);
  }

  String _getSlopeRecommendation() {
    if (_slopePercent == null) return '';
    if (_slopePercent! < 1) return 'Too flat - water may pool. Minimum 1% for drainage.';
    if (_slopePercent! >= 1 && _slopePercent! <= 2) return 'Ideal for lawns and patios. Good drainage without erosion.';
    if (_slopePercent! > 2 && _slopePercent! <= 3) return 'Good for drainage. Upper limit for comfortable walking.';
    if (_slopePercent! > 3 && _slopePercent! <= 5) return 'Moderate slope. May need terracing for planting beds.';
    return 'Steep slope. Consider retaining walls or terracing.';
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

  Widget _buildGradeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDED GRADES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Lawn drainage', '1-2%'),
        _buildTableRow(colors, 'Patio/walkway', '1-2%'),
        _buildTableRow(colors, 'Driveway', '1-5%'),
        _buildTableRow(colors, 'Swale/channel', '1-3%'),
        _buildTableRow(colors, 'ADA ramp max', '8.33% (1:12)'),
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
