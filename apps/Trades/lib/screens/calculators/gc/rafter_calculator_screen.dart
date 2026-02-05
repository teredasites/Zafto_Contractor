import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rafter Calculator - Roof framing
class RafterCalculatorScreen extends ConsumerStatefulWidget {
  const RafterCalculatorScreen({super.key});
  @override
  ConsumerState<RafterCalculatorScreen> createState() => _RafterCalculatorScreenState();
}

class _RafterCalculatorScreenState extends ConsumerState<RafterCalculatorScreen> {
  final _runController = TextEditingController(text: '12');
  final _ridgeLengthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');

  String _spacing = '16';

  int? _rafterCount;
  double? _rafterLength;
  String? _rafterSize;

  @override
  void dispose() {
    _runController.dispose();
    _ridgeLengthController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final run = double.tryParse(_runController.text);
    final ridgeLength = double.tryParse(_ridgeLengthController.text);
    final pitch = double.tryParse(_pitchController.text);
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (run == null || ridgeLength == null || pitch == null) {
      setState(() { _rafterCount = null; _rafterLength = null; _rafterSize = null; });
      return;
    }

    // Rafter length using pitch factor
    final rise = run * (pitch / 12);
    final rafterLength = math.sqrt(run * run + rise * rise) + 1; // +1 for overhang

    // Rafter count: both sides of ridge
    final lengthInches = ridgeLength * 12;
    final raftersPerSide = (lengthInches / spacingInches).floor() + 1;
    final rafterCount = raftersPerSide * 2;

    // Size recommendation based on span
    String rafterSize;
    if (run <= 8) rafterSize = '2x6';
    else if (run <= 12) rafterSize = '2x8';
    else if (run <= 16) rafterSize = '2x10';
    else rafterSize = '2x12';

    setState(() {
      _rafterCount = rafterCount;
      _rafterLength = rafterLength;
      _rafterSize = rafterSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _runController.text = '12';
    _ridgeLengthController.text = '30';
    _pitchController.text = '6';
    setState(() => _spacing = '16');
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rafter Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSpacingSelector(colors),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Run', unit: 'ft', hint: 'Horizontal', controller: _runController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Pitch', unit: '/12', hint: 'Rise per foot', controller: _pitchController, onChanged: (_) => _calculate())),
              ]),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Ridge Length', unit: 'ft', hint: 'Building length', controller: _ridgeLengthController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_rafterCount != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    return Row(children: ['16', '24'].map((s) {
      final isSelected = _spacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _spacing = s); _calculate(); },
        child: Container(
          margin: EdgeInsets.only(right: s == '16' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s" OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RAFTERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Text('$_rafterCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rafter Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rafterLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recommended Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_rafterSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
      ]),
    );
  }
}
