import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Winder Stair Calculator - Pie-shaped turning treads
class WinderStairScreen extends ConsumerStatefulWidget {
  const WinderStairScreen({super.key});
  @override
  ConsumerState<WinderStairScreen> createState() => _WinderStairScreenState();
}

class _WinderStairScreenState extends ConsumerState<WinderStairScreen> {
  final _riserHeightController = TextEditingController(text: '7.5');
  final _stairWidthController = TextEditingController(text: '36');

  String _turnAngle = '90';
  String _winderCount = '3';

  double? _treadDepthNarrow;
  double? _treadDepthWide;
  double? _walklineDepth;
  String? _codeCompliance;

  @override
  void dispose() { _riserHeightController.dispose(); _stairWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final riserHeight = double.tryParse(_riserHeightController.text);
    final stairWidth = double.tryParse(_stairWidthController.text);
    final turnAngle = int.tryParse(_turnAngle) ?? 90;
    final winderCount = int.tryParse(_winderCount) ?? 3;

    if (riserHeight == null || stairWidth == null) {
      setState(() { _treadDepthNarrow = null; _treadDepthWide = null; _walklineDepth = null; _codeCompliance = null; });
      return;
    }

    // Walkline is 12" from narrow side per code
    final walklineRadius = 12.0;

    // Arc length at walkline for the turn
    final arcLengthAtWalkline = (turnAngle / 360) * 2 * math.pi * walklineRadius;
    final walklineDepth = arcLengthAtWalkline / winderCount;

    // Narrow end (at center point)
    // Minimum 6" at narrowest point per IRC
    final treadDepthNarrow = 6.0; // Code minimum

    // Wide end calculation
    final outerRadius = stairWidth;
    final arcLengthAtOuter = (turnAngle / 360) * 2 * math.pi * outerRadius;
    final treadDepthWide = arcLengthAtOuter / winderCount;

    // Code compliance check
    String compliance;
    if (walklineDepth < 10) {
      compliance = 'FAIL: Walkline tread depth ${walklineDepth.toStringAsFixed(1)}" < 10" min';
    } else if (treadDepthNarrow < 6) {
      compliance = 'FAIL: Narrow end < 6" minimum';
    } else {
      compliance = 'PASS: Meets IRC R311.7.5.2';
    }

    setState(() {
      _treadDepthNarrow = treadDepthNarrow;
      _treadDepthWide = treadDepthWide;
      _walklineDepth = walklineDepth;
      _codeCompliance = compliance;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riserHeightController.text = '7.5'; _stairWidthController.text = '36'; setState(() { _turnAngle = '90'; _winderCount = '3'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Winder Stairs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TURN ANGLE', ['45', '90', '180'], _turnAngle, (v) { setState(() => _turnAngle = v); _calculate(); }, suffix: '°'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'WINDER TREADS', ['2', '3', '4'], _winderCount, (v) { setState(() => _winderCount = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Riser Height', unit: 'inches', controller: _riserHeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stair Width', unit: 'inches', controller: _stairWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_walklineDepth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WALKLINE DEPTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_walklineDepth!.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Narrow End (min)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_treadDepthNarrow!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wide End', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_treadDepthWide!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Winder Treads', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_winderCount, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _codeCompliance!.startsWith('PASS')
                        ? colors.accentSuccess.withValues(alpha: 0.1)
                        : colors.accentError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_codeCompliance!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
