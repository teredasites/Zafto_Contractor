import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Planting Calculator - Hole size and amendments
class TreePlantingScreen extends ConsumerStatefulWidget {
  const TreePlantingScreen({super.key});
  @override
  ConsumerState<TreePlantingScreen> createState() => _TreePlantingScreenState();
}

class _TreePlantingScreenState extends ConsumerState<TreePlantingScreen> {
  final _rootballController = TextEditingController(text: '24');
  final _countController = TextEditingController(text: '3');

  double? _holeDiameter;
  double? _holeDepth;
  double? _soilCuYd;
  double? _mulchCuYd;

  @override
  void dispose() { _rootballController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final rootballIn = double.tryParse(_rootballController.text) ?? 24;
    final count = int.tryParse(_countController.text) ?? 3;

    // Hole should be 2-3x rootball width, same depth as rootball
    final holeDiameterIn = rootballIn * 2.5;
    final holeDepthIn = rootballIn * 0.9; // Slightly less than rootball height

    final holeDiameterFt = holeDiameterIn / 12;
    final holeDepthFt = holeDepthIn / 12;
    final rootballFt = rootballIn / 12;

    // Backfill volume = hole volume - rootball volume
    final holeVolume = 3.14159 * (holeDiameterFt / 2) * (holeDiameterFt / 2) * holeDepthFt;
    final rootballVolume = 3.14159 * (rootballFt / 2) * (rootballFt / 2) * rootballFt;
    final backfillCuFt = (holeVolume - rootballVolume) * count;
    final soilCuYd = backfillCuFt / 27;

    // Mulch ring: 4' diameter, 3" deep per tree
    final mulchArea = 3.14159 * 2 * 2 * count; // 4' diameter
    final mulchCuFt = mulchArea * 0.25; // 3" depth
    final mulchCuYd = mulchCuFt / 27;

    setState(() {
      _holeDiameter = holeDiameterIn;
      _holeDepth = holeDepthIn;
      _soilCuYd = soilCuYd;
      _mulchCuYd = mulchCuYd;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _rootballController.text = '24'; _countController.text = '3'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Planting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Rootball Diameter', unit: 'in', controller: _rootballController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Number of Trees', unit: '', controller: _countController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Hole width: 2-3× rootball. Depth: same as rootball (not deeper).', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_holeDiameter != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('HOLE DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_holeDiameter!.toStringAsFixed(0)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_holeDepth!.toStringAsFixed(0)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text('MATERIALS NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Backfill/amendments', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mulch (3" rings)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlantingGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlantingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLANTING STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1. Dig hole', '2-3× rootball width'),
        _buildTableRow(colors, '2. Depth', 'Top of rootball at grade'),
        _buildTableRow(colors, '3. Remove', 'Burlap, wire basket'),
        _buildTableRow(colors, '4. Backfill', 'Native soil, no amendments'),
        _buildTableRow(colors, '5. Water', 'Deeply, settle soil'),
        _buildTableRow(colors, '6. Mulch', '3-4" away from trunk'),
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
