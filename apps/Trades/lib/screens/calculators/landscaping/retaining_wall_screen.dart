import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Retaining Wall Calculator - Block count and materials
class RetainingWallScreen extends ConsumerStatefulWidget {
  const RetainingWallScreen({super.key});
  @override
  ConsumerState<RetainingWallScreen> createState() => _RetainingWallScreenState();
}

class _RetainingWallScreenState extends ConsumerState<RetainingWallScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '24');

  String _blockType = 'standard';
  double _wasteFactor = 10;

  int? _blocksNeeded;
  int? _capsNeeded;
  double? _gravelTons;
  double? _backfillTons;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final heightInches = double.tryParse(_heightController.text) ?? 24;

    // Block dimensions by type
    double blockWidth; // face width in inches
    double blockHeight; // face height in inches
    double blockDepth; // depth in inches
    switch (_blockType) {
      case 'standard': // 12" x 4" face
        blockWidth = 12;
        blockHeight = 4;
        blockDepth = 8;
        break;
      case 'large': // 18" x 6" face
        blockWidth = 18;
        blockHeight = 6;
        blockDepth = 12;
        break;
      case 'versa': // 16" x 6" face
        blockWidth = 16;
        blockHeight = 6;
        blockDepth = 12;
        break;
      default:
        blockWidth = 12;
        blockHeight = 4;
        blockDepth = 8;
    }

    final lengthInches = length * 12;
    final blocksPerRow = (lengthInches / blockWidth).ceil();
    final rows = (heightInches / blockHeight).ceil();
    final baseBlocks = blocksPerRow * rows;
    final blocksWithWaste = (baseBlocks * (1 + _wasteFactor / 100)).ceil();

    // Caps = 1 per linear foot
    final caps = length.ceil();

    // Gravel base: 6" deep x 24" wide (behind wall + under)
    final gravelCuFt = (length * 2 * 0.5); // 24" wide x 6" deep
    final gravelTons = (gravelCuFt / 27) * 1.35;

    // Backfill: behind wall, 12" wide x wall height
    final backfillCuFt = length * 1 * (heightInches / 12);
    final backfillTons = (backfillCuFt / 27) * 1.35;

    setState(() {
      _blocksNeeded = blocksWithWaste;
      _capsNeeded = caps;
      _gravelTons = gravelTons;
      _backfillTons = backfillTons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _heightController.text = '24'; setState(() { _blockType = 'standard'; _wasteFactor = 10; }); _calculate(); }

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
            _buildSelector(colors, 'BLOCK TYPE', ['standard', 'large', 'versa'], _blockType, {'standard': '12x4"', 'large': '18x6"', 'versa': '16x6"'}, (v) { setState(() => _blockType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 15, divisions: 2, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_blocksNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BLOCKS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap blocks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Backfill gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_backfillTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Walls over 4\' typically require engineering and permits.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
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

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Base', '6" compacted gravel'),
        _buildTableRow(colors, 'First course', 'Bury 1" below grade'),
        _buildTableRow(colors, 'Setback', '1/4" per course'),
        _buildTableRow(colors, 'Drainage', 'Perf pipe behind base'),
        _buildTableRow(colors, 'Geogrid', 'Every 2\' over 2\''),
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
