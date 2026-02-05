import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Retaining Wall Calculator - Retaining wall materials estimation
class RetainingWallScreen extends ConsumerStatefulWidget {
  const RetainingWallScreen({super.key});
  @override
  ConsumerState<RetainingWallScreen> createState() => _RetainingWallScreenState();
}

class _RetainingWallScreenState extends ConsumerState<RetainingWallScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '3');

  String _material = 'block';
  bool _needsDrain = true;

  int? _blocks;
  int? _capBlocks;
  double? _gravelTons;
  double? _drainPipeFeet;
  double? _fabricSqft;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final height = double.tryParse(_heightController.text) ?? 3;

    // Block calculations (standard 12\" x 4\" face)
    final blocksPerSqft = 3; // ~3 blocks per sq ft of wall face
    final wallSqft = length * height;
    final blocks = (wallSqft * blocksPerSqft * 1.05).ceil(); // +5% waste

    // Cap blocks: 1 per foot of wall
    final capBlocks = (length * 1.05).ceil();

    // Gravel for base and backfill
    // Base: 6\" deep x 24\" wide
    // Backfill: 12\" behind wall x height
    final baseCuFt = length * 0.5 * 2; // 6\" = 0.5', 24\" = 2'
    final backfillCuFt = length * 1 * height; // 12\" = 1' behind
    final totalCuFt = baseCuFt + backfillCuFt;
    final gravelTons = (totalCuFt / 27) * 1.4; // 1.4 tons per cu yd

    // Drain pipe if needed
    final drainPipeFeet = _needsDrain ? length * 1.1 : 0.0;

    // Filter fabric
    final fabricSqft = length * (height + 2) * 1.2; // wrap behind and under

    setState(() { _blocks = blocks; _capBlocks = capBlocks; _gravelTons = gravelTons; _drainPipeFeet = drainPipeFeet; _fabricSqft = fabricSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _heightController.text = '3'; setState(() { _material = 'block'; _needsDrain = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Retaining Wall', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['block', 'timber', 'boulder', 'poured'], _material, {'block': 'Block', 'timber': 'Timber', 'boulder': 'Boulder', 'poured': 'Poured'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Drainage System', _needsDrain, (v) { setState(() => _needsDrain = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_blocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_material == 'block' ? 'WALL BLOCKS' : 'WALL UNITS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap Units', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capBlocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_needsDrain) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drain Pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_drainPipeFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Filter Fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Walls over 4\' typically require engineering. Check local codes. Always include drainage system.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGuidelinesTable(colors),
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

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildGuidelinesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Base depth', '6\" compacted gravel'),
        _buildTableRow(colors, 'Base width', 'Wall width + 6\"'),
        _buildTableRow(colors, 'Setback', '1\" per course'),
        _buildTableRow(colors, 'Geogrid', 'Every 2 courses if >3\''),
        _buildTableRow(colors, 'Engineer req.', '>4\' height typically'),
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
