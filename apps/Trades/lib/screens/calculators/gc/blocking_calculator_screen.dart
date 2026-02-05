import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Blocking Calculator - Fire blocking, bridging
class BlockingCalculatorScreen extends ConsumerStatefulWidget {
  const BlockingCalculatorScreen({super.key});
  @override
  ConsumerState<BlockingCalculatorScreen> createState() => _BlockingCalculatorScreenState();
}

class _BlockingCalculatorScreenState extends ConsumerState<BlockingCalculatorScreen> {
  final _floorLengthController = TextEditingController(text: '40');
  final _wallHeightController = TextEditingController(text: '9');
  final _wallLengthController = TextEditingController(text: '100');

  String _joistSpacing = '16';
  bool _needsMidSpanBlocking = true;

  int? _floorBlocks;
  int? _fireBlocks;
  int? _totalBlocks;

  @override
  void dispose() { _floorLengthController.dispose(); _wallHeightController.dispose(); _wallLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final floorLength = double.tryParse(_floorLengthController.text);
    final wallHeight = double.tryParse(_wallHeightController.text);
    final wallLength = double.tryParse(_wallLengthController.text);
    final spacingInches = int.tryParse(_joistSpacing) ?? 16;

    if (floorLength == null || wallHeight == null || wallLength == null) {
      setState(() { _floorBlocks = null; _fireBlocks = null; _totalBlocks = null; });
      return;
    }

    // Floor blocking (mid-span for spans > 8')
    int floorBlocks = 0;
    if (_needsMidSpanBlocking) {
      final joistBays = (floorLength * 12 / spacingInches).floor();
      floorBlocks = joistBays; // One block per bay
    }

    // Fire blocking (every 10' vertical, at floor/ceiling lines)
    // Simplified: blocks per linear foot of wall at each level
    final fireBlockRows = (wallHeight / 10).ceil();
    final blocksPerRow = (wallLength * 12 / spacingInches).floor();
    final fireBlocks = fireBlockRows * blocksPerRow;

    setState(() { _floorBlocks = floorBlocks; _fireBlocks = fireBlocks; _totalBlocks = floorBlocks + fireBlocks; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _floorLengthController.text = '40'; _wallHeightController.text = '9'; _wallLengthController.text = '100'; setState(() { _joistSpacing = '16'; _needsMidSpanBlocking = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Blocking Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 16),
            _buildMidSpanToggle(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Floor Area Length', unit: 'ft', controller: _floorLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'ft', controller: _wallHeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Length', unit: 'ft', controller: _wallLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBlocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Blocking', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_floorBlocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fire Blocking', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fireBlocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BLOCKS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalBlocks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    return Row(children: ['16', '24'].map((s) {
      final isSelected = _joistSpacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _joistSpacing = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s == '16' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s" OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }

  Widget _buildMidSpanToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _needsMidSpanBlocking = !_needsMidSpanBlocking); _calculate(); },
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(children: [
          Icon(_needsMidSpanBlocking ? LucideIcons.checkSquare : LucideIcons.square, color: _needsMidSpanBlocking ? colors.accentPrimary : colors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('Mid-Span Floor Blocking', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }
}
