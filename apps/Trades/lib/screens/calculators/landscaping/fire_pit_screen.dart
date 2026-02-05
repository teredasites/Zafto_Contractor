import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fire Pit Calculator - Block count for circular pit
class FirePitScreen extends ConsumerStatefulWidget {
  const FirePitScreen({super.key});
  @override
  ConsumerState<FirePitScreen> createState() => _FirePitScreenState();
}

class _FirePitScreenState extends ConsumerState<FirePitScreen> {
  final _diameterController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '12');

  String _blockType = 'wall';

  int? _blocksNeeded;
  int? _capsNeeded;
  double? _gravelBags;
  int? _rows;

  @override
  void dispose() { _diameterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final diameterFt = double.tryParse(_diameterController.text) ?? 4;
    final heightIn = double.tryParse(_heightController.text) ?? 12;

    // Block dimensions
    double blockWidthIn;
    double blockHeightIn;
    switch (_blockType) {
      case 'wall': // Retaining wall block
        blockWidthIn = 12;
        blockHeightIn = 4;
        break;
      case 'trapezoid': // Trapezoid fire pit block
        blockWidthIn = 9; // Average of tapered
        blockHeightIn = 4;
        break;
      case 'paver': // Paver blocks
        blockWidthIn = 8;
        blockHeightIn = 4;
        break;
      default:
        blockWidthIn = 12;
        blockHeightIn = 4;
    }

    // Circumference
    final circumferenceIn = diameterFt * 12 * 3.14159;
    final blocksPerRow = (circumferenceIn / blockWidthIn).ceil();
    final rows = (heightIn / blockHeightIn).ceil();
    final totalBlocks = blocksPerRow * rows;

    // Caps for top row
    final caps = blocksPerRow;

    // Gravel base (50 lb bags cover ~0.5 cu ft)
    final baseCuFt = 3.14159 * (diameterFt / 2) * (diameterFt / 2) * (4 / 12); // 4" base
    final gravelBags = baseCuFt / 0.5;

    setState(() {
      _blocksNeeded = totalBlocks;
      _capsNeeded = caps;
      _gravelBags = gravelBags;
      _rows = rows;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _diameterController.text = '4'; _heightController.text = '12'; setState(() { _blockType = 'wall'; }); _calculate(); }

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
            _buildSelector(colors, 'BLOCK TYPE', ['wall', 'trapezoid', 'paver'], _blockType, {'wall': 'Wall Block', 'trapezoid': 'Trapezoid', 'paver': 'Paver'}, (v) { setState(() => _blockType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Inside Diameter', unit: 'ft', controller: _diameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_blocksNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BLOCKS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Block rows', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rows', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap blocks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel bags (50 lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelBags!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFirePitGuide(colors),
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

  Widget _buildFirePitGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FIRE PIT SAFETY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min clearance', "10' from structures"),
        _buildTableRow(colors, 'Ideal diameter', "3-4' inside"),
        _buildTableRow(colors, 'Wall height', '12-14"'),
        _buildTableRow(colors, 'Base', '4" gravel for drainage'),
        _buildTableRow(colors, 'Fire bricks', 'Optional inner liner'),
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
