import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Border Wall Calculator - Low decorative walls
class BorderWallScreen extends ConsumerStatefulWidget {
  const BorderWallScreen({super.key});
  @override
  ConsumerState<BorderWallScreen> createState() => _BorderWallScreenState();
}

class _BorderWallScreenState extends ConsumerState<BorderWallScreen> {
  final _lengthController = TextEditingController(text: '20');

  String _wallHeight = '12';
  String _blockType = 'standard';

  int? _blocksNeeded;
  int? _capsNeeded;
  double? _gravelBags;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final heightIn = double.tryParse(_wallHeight) ?? 12;

    // Block dimensions vary by type
    double blockWidthIn;
    double blockHeightIn;
    switch (_blockType) {
      case 'standard':
        blockWidthIn = 12;
        blockHeightIn = 4;
        break;
      case 'split':
        blockWidthIn = 12;
        blockHeightIn = 4;
        break;
      case 'tumbled':
        blockWidthIn = 9;
        blockHeightIn = 4;
        break;
      default:
        blockWidthIn = 12;
        blockHeightIn = 4;
    }

    final lengthIn = length * 12;
    final blocksPerRow = (lengthIn / blockWidthIn).ceil();
    final rows = (heightIn / blockHeightIn).ceil();
    final totalBlocks = blocksPerRow * rows;

    // Caps
    final caps = blocksPerRow;

    // Gravel base: 6" deep, 12" wide
    final gravelCuFt = length * 1 * 0.5; // 1' wide, 0.5' deep
    final gravelBags = gravelCuFt / 0.5; // 0.5 cu ft bags

    setState(() {
      _blocksNeeded = totalBlocks;
      _capsNeeded = caps;
      _gravelBags = gravelBags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; setState(() { _wallHeight = '12'; _blockType = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Border Wall', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BLOCK STYLE', ['standard', 'split', 'tumbled'], _blockType, {'standard': 'Standard', 'split': 'Split Face', 'tumbled': 'Tumbled'}, (v) { setState(() => _blockType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'WALL HEIGHT', ['8', '12', '16'], _wallHeight, {'8': '8\"', '12': '12\"', '16': '16\"'}, (v) { setState(() => _wallHeight = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Wall Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_blocksNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BLOCKS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap stones', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel (0.5 cu ft bags)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_gravelBags!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBorderGuide(colors),
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

  Widget _buildBorderGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Base', '4-6\" compacted gravel'),
        _buildTableRow(colors, 'Leveling', 'First course critical'),
        _buildTableRow(colors, 'Offset', 'Stagger joints'),
        _buildTableRow(colors, 'Adhesive', 'Cap stones only'),
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
