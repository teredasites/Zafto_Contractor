import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Outdoor Stairs Calculator - Steps and materials
class StairsOutdoorScreen extends ConsumerStatefulWidget {
  const StairsOutdoorScreen({super.key});
  @override
  ConsumerState<StairsOutdoorScreen> createState() => _StairsOutdoorScreenState();
}

class _StairsOutdoorScreenState extends ConsumerState<StairsOutdoorScreen> {
  final _riseController = TextEditingController(text: '36');
  final _widthController = TextEditingController(text: '48');

  String _material = 'paver';

  int? _stepCount;
  double? _riserHeight;
  double? _treadDepth;
  double? _totalRun;
  int? _blocksNeeded;

  @override
  void dispose() { _riseController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final totalRiseIn = double.tryParse(_riseController.text) ?? 36;
    final widthIn = double.tryParse(_widthController.text) ?? 48;

    // Standard outdoor riser: 6-8", aim for 7"
    const idealRiser = 7.0;
    final steps = (totalRiseIn / idealRiser).round();
    final actualRiser = totalRiseIn / steps;

    // Standard outdoor tread: 11-14", use 12"
    const treadDepth = 12.0;
    final totalRun = (steps - 1) * treadDepth;

    // Materials vary by type
    int blocks;
    switch (_material) {
      case 'paver':
        // Paver steps: each step needs blocks for riser + treads
        // Riser blocks: 2 high per step (6" blocks)
        // Tread pavers: width × depth
        final riserBlocksPerStep = 2 * (widthIn / 12).ceil();
        final treadPaversPerStep = (widthIn / 6).ceil() * 2; // 6" pavers, 2 deep
        blocks = (riserBlocksPerStep + treadPaversPerStep) * steps;
        break;
      case 'block':
        // Wall block steps
        final blocksPerRow = (widthIn / 12).ceil();
        final rowsPerStep = 2; // 2 courses high
        blocks = blocksPerRow * rowsPerStep * steps;
        break;
      case 'stone':
        // Natural stone - estimate treads
        blocks = steps; // 1 large stone per step
        break;
      default:
        blocks = steps * 4;
    }

    setState(() {
      _stepCount = steps;
      _riserHeight = actualRiser;
      _treadDepth = treadDepth;
      _totalRun = totalRun;
      _blocksNeeded = blocks;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '36'; _widthController.text = '48'; setState(() { _material = 'paver'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Outdoor Stairs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['paver', 'block', 'stone'], _material, {'paver': 'Paver', 'block': 'Wall Block', 'stone': 'Natural Stone'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'in', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Step Width', unit: 'in', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_stepCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NUMBER OF STEPS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stepCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Riser height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_riserHeight!.toStringAsFixed(1)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tread depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_treadDepth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total run', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalRun!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. ${_material == 'stone' ? 'stones' : 'blocks'}', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_blocksNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStairGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStairGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OUTDOOR STAIR SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Riser height', '6-8\" (7\" ideal)'),
        _buildTableRow(colors, 'Tread depth', '11-14\" (12\" ideal)'),
        _buildTableRow(colors, '2R + T rule', '24-26\" total'),
        _buildTableRow(colors, 'Min width', '36\" (48\" better)'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
