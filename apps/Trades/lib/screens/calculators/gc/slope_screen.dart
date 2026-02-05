import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slope Calculator - Grade and slope conversions
class SlopeScreen extends ConsumerStatefulWidget {
  const SlopeScreen({super.key});
  @override
  ConsumerState<SlopeScreen> createState() => _SlopeScreenState();
}

class _SlopeScreenState extends ConsumerState<SlopeScreen> {
  final _riseController = TextEditingController(text: '6');
  final _runController = TextEditingController(text: '100');

  String _inputType = 'rise_run';

  double? _percentGrade;
  double? _ratio;
  double? _degrees;
  String? _inchesPerFoot;

  @override
  void dispose() { _riseController.dispose(); _runController.dispose(); super.dispose(); }

  void _calculate() {
    final rise = double.tryParse(_riseController.text);
    final run = double.tryParse(_runController.text);

    if (rise == null || run == null || run == 0) {
      setState(() { _percentGrade = null; _ratio = null; _degrees = null; _inchesPerFoot = null; });
      return;
    }

    double percentGrade;
    double ratio;
    double degrees;
    double inchesPerFoot;

    switch (_inputType) {
      case 'rise_run':
        percentGrade = (rise / run) * 100;
        ratio = run / rise;
        degrees = math.atan(rise / run) * 180 / math.pi;
        inchesPerFoot = (rise / run) * 12;
        break;
      case 'percent':
        percentGrade = rise; // Rise field used as percent input
        ratio = 100 / rise;
        degrees = math.atan(rise / 100) * 180 / math.pi;
        inchesPerFoot = rise * 12 / 100;
        break;
      case 'ratio':
        ratio = rise; // Rise field used as ratio (1:X)
        percentGrade = (1 / rise) * 100;
        degrees = math.atan(1 / rise) * 180 / math.pi;
        inchesPerFoot = 12 / rise;
        break;
      default:
        percentGrade = (rise / run) * 100;
        ratio = run / rise;
        degrees = math.atan(rise / run) * 180 / math.pi;
        inchesPerFoot = (rise / run) * 12;
    }

    setState(() {
      _percentGrade = percentGrade;
      _ratio = ratio;
      _degrees = degrees;
      _inchesPerFoot = '${inchesPerFoot.toStringAsFixed(2)}"';
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '6'; _runController.text = '100'; setState(() => _inputType = 'rise_run'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Slope', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'INPUT TYPE', ['rise_run', 'percent', 'ratio'], _inputType, (v) { setState(() => _inputType = v); _calculate(); }),
            const SizedBox(height: 20),
            if (_inputType == 'rise_run') ...[
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Rise', unit: 'ft', controller: _riseController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Run', unit: 'ft', controller: _runController, onChanged: (_) => _calculate())),
              ]),
            ] else if (_inputType == 'percent') ...[
              ZaftoInputField(label: 'Percent Grade', unit: '%', controller: _riseController, onChanged: (_) => _calculate()),
            ] else ...[
              ZaftoInputField(label: 'Ratio (1:X)', unit: 'X', controller: _riseController, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 32),
            if (_percentGrade != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PERCENT GRADE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_percentGrade!.toStringAsFixed(2)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1:${_ratio!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Degrees', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_degrees!.toStringAsFixed(2)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Inches per Foot', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_inchesPerFoot!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Common slopes: Drainage 2% (1:50), Ramps 8.3% (1:12), Driveways 10% max.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'rise_run': 'Rise/Run', 'percent': 'Percent', 'ratio': 'Ratio'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
