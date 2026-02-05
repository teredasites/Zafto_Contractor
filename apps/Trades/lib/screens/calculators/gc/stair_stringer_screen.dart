import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stair Stringer Calculator - Stringer layout and materials
class StairStringerScreen extends ConsumerStatefulWidget {
  const StairStringerScreen({super.key});
  @override
  ConsumerState<StairStringerScreen> createState() => _StairStringerScreenState();
}

class _StairStringerScreenState extends ConsumerState<StairStringerScreen> {
  final _totalRiseController = TextEditingController(text: '108');
  final _riserHeightController = TextEditingController(text: '7.5');
  final _treadDepthController = TextEditingController(text: '10');
  final _stairWidthController = TextEditingController(text: '36');

  String _stringerType = '2x12';

  int? _numberOfRisers;
  double? _stringerLength;
  int? _stringersNeeded;
  double? _angleOfIncline;

  @override
  void dispose() { _totalRiseController.dispose(); _riserHeightController.dispose(); _treadDepthController.dispose(); _stairWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final totalRise = double.tryParse(_totalRiseController.text);
    final riserHeight = double.tryParse(_riserHeightController.text);
    final treadDepth = double.tryParse(_treadDepthController.text);
    final stairWidth = double.tryParse(_stairWidthController.text);

    if (totalRise == null || riserHeight == null || treadDepth == null || stairWidth == null) {
      setState(() { _numberOfRisers = null; _stringerLength = null; _stringersNeeded = null; _angleOfIncline = null; });
      return;
    }

    // Calculate number of risers
    final numberOfRisers = (totalRise / riserHeight).round();
    final numberOfTreads = numberOfRisers - 1;

    // Total run
    final totalRun = numberOfTreads * treadDepth;

    // Stringer length (hypotenuse) plus extra for cuts
    final diagonal = math.sqrt(totalRise * totalRise + totalRun * totalRun);
    final stringerLength = diagonal + 12; // Add 12" for top and bottom cuts

    // Number of stringers based on width (max 16" apart)
    final stringersNeeded = ((stairWidth / 16).ceil() + 1).clamp(3, 10);

    // Angle of incline
    final angleRadians = math.atan(totalRise / totalRun);
    final angleOfIncline = angleRadians * 180 / math.pi;

    setState(() {
      _numberOfRisers = numberOfRisers;
      _stringerLength = stringerLength;
      _stringersNeeded = stringersNeeded;
      _angleOfIncline = angleOfIncline;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _totalRiseController.text = '108'; _riserHeightController.text = '7.5'; _treadDepthController.text = '10'; _stairWidthController.text = '36'; setState(() => _stringerType = '2x12'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stair Stringers', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STRINGER STOCK', ['2x10', '2x12', 'LVL'], _stringerType, (v) { setState(() => _stringerType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _totalRiseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stair Width', unit: 'inches', controller: _stairWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Riser Height', unit: 'inches', controller: _riserHeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tread Depth', unit: 'inches', controller: _treadDepthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_stringersNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STRINGERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stringersNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stringer Length (min)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_stringerLength! / 12).toStringAsFixed(1)}\' (${_stringerLength!.toStringAsFixed(0)}")', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Number of Risers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_numberOfRisers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Angle of Incline', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_angleOfIncline!.toStringAsFixed(1)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getStringerNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getStringerNote() {
    switch (_stringerType) {
      case '2x10': return '2x10: Max 5" effective throat depth after cuts. Use for 7" max rise.';
      case '2x12': return '2x12: Standard residential. Min 3.5" throat remaining after notches.';
      case 'LVL': return 'LVL stringers: Stronger, no knots. Required for longer spans or open risers.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
