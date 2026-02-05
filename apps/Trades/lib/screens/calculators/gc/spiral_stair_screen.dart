import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spiral Stair Calculator - Helical stair dimensions
class SpiralStairScreen extends ConsumerStatefulWidget {
  const SpiralStairScreen({super.key});
  @override
  ConsumerState<SpiralStairScreen> createState() => _SpiralStairScreenState();
}

class _SpiralStairScreenState extends ConsumerState<SpiralStairScreen> {
  final _floorToFloorController = TextEditingController(text: '108');
  final _diameterController = TextEditingController(text: '60');

  String _rotation = '360';

  int? _numberOfTreads;
  double? _riserHeight;
  double? _treadAngle;
  double? _walklineDepth;
  String? _codeCompliance;

  @override
  void dispose() { _floorToFloorController.dispose(); _diameterController.dispose(); super.dispose(); }

  void _calculate() {
    final floorToFloor = double.tryParse(_floorToFloorController.text);
    final diameter = double.tryParse(_diameterController.text);
    final rotation = int.tryParse(_rotation) ?? 360;

    if (floorToFloor == null || diameter == null) {
      setState(() { _numberOfTreads = null; _riserHeight = null; _treadAngle = null; _walklineDepth = null; _codeCompliance = null; });
      return;
    }

    // Target riser height 7.5"
    final targetRiser = 7.5;
    final numberOfTreads = (floorToFloor / targetRiser).round();
    final actualRiserHeight = floorToFloor / numberOfTreads;

    // Tread angle (degrees per tread)
    final treadAngle = rotation / numberOfTreads;

    // Walkline at 12" from center
    final walklineRadius = 12.0;
    final walklineCircumference = 2 * math.pi * walklineRadius;
    final walklineArc = (rotation / 360) * walklineCircumference;
    final walklineDepth = walklineArc / numberOfTreads;

    // Code compliance (IRC R311.7.10.1)
    String compliance;
    final minClearWidth = (diameter - 8) / 2; // Center column ~8"

    if (diameter < 60) {
      compliance = 'FAIL: Min 60" diameter for secondary means of egress';
    } else if (walklineDepth < 7.5) {
      compliance = 'FAIL: Walkline tread depth ${walklineDepth.toStringAsFixed(1)}" < 7.5" min';
    } else if (actualRiserHeight > 9.5) {
      compliance = 'FAIL: Riser height ${actualRiserHeight.toStringAsFixed(1)}" > 9.5" max';
    } else if (minClearWidth < 26) {
      compliance = 'WARNING: Clear width ${minClearWidth.toStringAsFixed(0)}" may not meet 26" min';
    } else {
      compliance = 'PASS: Meets IRC R311.7.10';
    }

    setState(() {
      _numberOfTreads = numberOfTreads;
      _riserHeight = actualRiserHeight;
      _treadAngle = treadAngle;
      _walklineDepth = walklineDepth;
      _codeCompliance = compliance;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _floorToFloorController.text = '108'; _diameterController.text = '60'; setState(() => _rotation = '360'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Spiral Stairs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROTATION', ['270', '360', '450', '540'], _rotation, (v) { setState(() => _rotation = v); _calculate(); }, suffix: '°'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Floor to Floor', unit: 'inches', controller: _floorToFloorController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Diameter', unit: 'inches', controller: _diameterController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_numberOfTreads != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NUMBER OF TREADS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_numberOfTreads', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Riser Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_riserHeight!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tread Angle', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_treadAngle!.toStringAsFixed(1)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Walkline Depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_walklineDepth!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _codeCompliance!.startsWith('PASS')
                        ? colors.accentSuccess.withValues(alpha: 0.1)
                        : _codeCompliance!.startsWith('WARNING')
                            ? colors.accentWarning.withValues(alpha: 0.1)
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
