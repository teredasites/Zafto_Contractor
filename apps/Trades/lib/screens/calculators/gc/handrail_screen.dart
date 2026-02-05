import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Handrail Calculator - Stair handrail materials
class HandrailScreen extends ConsumerStatefulWidget {
  const HandrailScreen({super.key});
  @override
  ConsumerState<HandrailScreen> createState() => _HandrailScreenState();
}

class _HandrailScreenState extends ConsumerState<HandrailScreen> {
  final _riseController = TextEditingController(text: '108');
  final _runController = TextEditingController(text: '120');

  String _railType = 'wood';
  String _sides = 'both';

  double? _railLength;
  double? _totalRailLength;
  int? _bracketsNeeded;
  int? _returnPieces;

  @override
  void dispose() { _riseController.dispose(); _runController.dispose(); super.dispose(); }

  void _calculate() {
    final riseInches = double.tryParse(_riseController.text);
    final runInches = double.tryParse(_runController.text);

    if (riseInches == null || runInches == null) {
      setState(() { _railLength = null; _totalRailLength = null; _bracketsNeeded = null; _returnPieces = null; });
      return;
    }

    // Rail length follows slope (hypotenuse)
    final diagonalInches = math.sqrt(riseInches * riseInches + runInches * runInches);

    // Add 12" for top and bottom extensions (returns to wall)
    final railLengthInches = diagonalInches + 24;
    final railLengthFeet = railLengthInches / 12;

    // Total based on sides
    final sidesCount = _sides == 'both' ? 2 : 1;
    final totalRailLength = railLengthFeet * sidesCount;

    // Brackets: every 4' plus ends
    final bracketsPerSide = (railLengthFeet / 4).ceil() + 1;
    final bracketsNeeded = bracketsPerSide * sidesCount;

    // Return fittings (wall returns at top and bottom)
    final returnPieces = 2 * sidesCount;

    setState(() {
      _railLength = railLengthFeet;
      _totalRailLength = totalRailLength;
      _bracketsNeeded = bracketsNeeded;
      _returnPieces = returnPieces;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '108'; _runController.text = '120'; setState(() { _railType = 'wood'; _sides = 'both'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Handrail', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'RAIL TYPE', ['wood', 'metal', 'pipe'], _railType, (v) { setState(() => _railType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SIDES', ['one', 'both'], _sides, (v) { setState(() => _sides = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Total Run', unit: 'inches', controller: _runController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_railLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL RAIL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalRailLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rail per Side', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_railLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Brackets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bracketsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Return Fittings', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_returnPieces', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getRailNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getRailNote() {
    switch (_railType) {
      case 'wood': return 'Wood: 1-1/4" to 2" diameter graspable. Height 34"-38" from tread nosing.';
      case 'metal': return 'Metal: 1-1/4" to 1-1/2" round or oval. Returns must not protrude into path.';
      case 'pipe': return 'Pipe rail: Schedule 40, 1-1/4" or 1-1/2" OD. Prime and paint or use galvanized.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'wood': 'Wood', 'metal': 'Metal', 'pipe': 'Pipe', 'one': 'One Side', 'both': 'Both Sides'};
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
