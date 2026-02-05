import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fire Pit Calculator - Fire pit materials estimation
class FirePitScreen extends ConsumerStatefulWidget {
  const FirePitScreen({super.key});
  @override
  ConsumerState<FirePitScreen> createState() => _FirePitScreenState();
}

class _FirePitScreenState extends ConsumerState<FirePitScreen> {
  final _diameterController = TextEditingController(text: '42');
  final _heightController = TextEditingController(text: '14');

  String _style = 'round';
  String _material = 'block';

  int? _blocks;
  int? _capBlocks;
  double? _gravelTons;
  int? _fireRingDiameter;

  @override
  void dispose() { _diameterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final diameter = double.tryParse(_diameterController.text) ?? 42;
    final height = double.tryParse(_heightController.text) ?? 14;

    final diameterFt = diameter / 12;
    final heightFt = height / 12;

    // Calculate blocks based on style
    int blocks;
    int capBlocks;

    if (_style == 'round') {
      // Circumference calculation
      final circumference = 3.14159 * diameterFt;
      // Blocks: 12\" wide, so circumference / 1 per row
      final blocksPerRow = (circumference * 12 / 12).ceil(); // 12\" block width
      // Rows: height / 4\" block height
      final rows = (height / 4).ceil();
      blocks = blocksPerRow * rows;
      capBlocks = blocksPerRow;
    } else {
      // Square
      final perimeter = diameterFt * 4;
      final blocksPerRow = (perimeter * 12 / 12).ceil();
      final rows = (height / 4).ceil();
      blocks = blocksPerRow * rows;
      capBlocks = blocksPerRow;
    }

    // Gravel for base: 6\" deep
    final baseArea = _style == 'round'
        ? 3.14159 * (diameterFt / 2) * (diameterFt / 2)
        : diameterFt * diameterFt;
    final gravelCuFt = baseArea * 0.5; // 6\" = 0.5'
    final gravelTons = (gravelCuFt / 27) * 1.4;

    // Fire ring: inner diameter minus wall thickness
    final fireRingDiameter = (diameter - 8).toInt(); // 8\" for double wall

    setState(() { _blocks = blocks; _capBlocks = capBlocks; _gravelTons = gravelTons; _fireRingDiameter = fireRingDiameter; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _diameterController.text = '42'; _heightController.text = '14'; setState(() { _style = 'round'; _material = 'block'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fire Pit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHAPE', ['round', 'square'], _style, {'round': 'Round', 'square': 'Square'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['block', 'stone', 'brick'], _material, {'block': 'Block', 'stone': 'Stone', 'brick': 'Brick'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: _style == 'round' ? 'Diameter' : 'Width', unit: 'inches', controller: _diameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_blocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WALL BLOCKS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap Blocks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capBlocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fire Ring Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fireRingDiameter\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Keep 10-20\' from structures. Check local codes. Use fire-rated blocks or line with steel ring. Never use river rocks (can explode).', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small', '30-36\" diameter'),
        _buildTableRow(colors, 'Medium', '36-42\" diameter'),
        _buildTableRow(colors, 'Large', '44-48\" diameter'),
        _buildTableRow(colors, 'Height', '12-18\" typical'),
        _buildTableRow(colors, 'Clearance', '10-20\' from structures'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
