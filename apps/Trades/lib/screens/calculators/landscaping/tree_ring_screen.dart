import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Ring Calculator - Mulch for circular beds around trees
class TreeRingScreen extends ConsumerStatefulWidget {
  const TreeRingScreen({super.key});
  @override
  ConsumerState<TreeRingScreen> createState() => _TreeRingScreenState();
}

class _TreeRingScreenState extends ConsumerState<TreeRingScreen> {
  final _diameterController = TextEditingController(text: '6');
  final _trunkController = TextEditingController(text: '6');
  final _depthController = TextEditingController(text: '3');
  final _countController = TextEditingController(text: '5');

  double? _mulchCuYd;
  double? _edgingFt;
  double? _areaSqFt;

  @override
  void dispose() { _diameterController.dispose(); _trunkController.dispose(); _depthController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final diameterFt = double.tryParse(_diameterController.text) ?? 6;
    final trunkIn = double.tryParse(_trunkController.text) ?? 6;
    final depthIn = double.tryParse(_depthController.text) ?? 3;
    final count = int.tryParse(_countController.text) ?? 5;

    final radiusFt = diameterFt / 2;
    final trunkRadiusFt = (trunkIn / 2) / 12;

    final outerArea = 3.14159 * radiusFt * radiusFt;
    final innerArea = 3.14159 * trunkRadiusFt * trunkRadiusFt;
    final ringArea = outerArea - innerArea;
    final totalArea = ringArea * count;

    final depthFt = depthIn / 12;
    final cubicFeet = totalArea * depthFt;
    final cubicYards = cubicFeet / 27;

    final circumference = 3.14159 * diameterFt;
    final totalEdging = circumference * count;

    setState(() {
      _mulchCuYd = cubicYards;
      _edgingFt = totalEdging;
      _areaSqFt = totalArea;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _diameterController.text = '6'; _trunkController.text = '6'; _depthController.text = '3'; _countController.text = '5'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Rings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Ring Diameter', unit: 'ft', controller: _diameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Trunk Diameter', unit: 'in', controller: _trunkController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Mulch Depth', unit: 'in', controller: _depthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Number of Trees', unit: '', controller: _countController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Keep mulch 3-4" away from trunk. Do not volcano mulch!', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_mulchCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MULCH NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edging needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgingFt!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_mulchCuYd! * 13.5).ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMulchGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMulchGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TREE RING SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Young tree', "3-4' diameter"),
        _buildTableRow(colors, 'Medium tree', "5-6' diameter"),
        _buildTableRow(colors, 'Mature tree', "8-10' diameter"),
        _buildTableRow(colors, 'Ideal depth', '2-4"'),
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
