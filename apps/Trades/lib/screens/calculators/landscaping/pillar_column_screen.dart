import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pillar/Column Calculator - Block count for pillars
class PillarColumnScreen extends ConsumerStatefulWidget {
  const PillarColumnScreen({super.key});
  @override
  ConsumerState<PillarColumnScreen> createState() => _PillarColumnScreenState();
}

class _PillarColumnScreenState extends ConsumerState<PillarColumnScreen> {
  final _heightController = TextEditingController(text: '36');
  final _pillarCountController = TextEditingController(text: '2');

  String _pillarSize = '16';

  int? _blocksPerPillar;
  int? _totalBlocks;
  int? _capsNeeded;
  double? _concreteBags;

  @override
  void dispose() { _heightController.dispose(); _pillarCountController.dispose(); super.dispose(); }

  void _calculate() {
    final heightIn = double.tryParse(_heightController.text) ?? 36;
    final pillarCount = int.tryParse(_pillarCountController.text) ?? 2;
    final pillarSizeIn = double.tryParse(_pillarSize) ?? 16;

    // Standard pillar block: 4" high, wraps around to make pillar
    const blockHeightIn = 4.0;

    // Blocks per row depends on pillar size
    int blocksPerRow;
    if (pillarSizeIn <= 12) {
      blocksPerRow = 2; // 12" pillar: 2 half blocks
    } else if (pillarSizeIn <= 16) {
      blocksPerRow = 3; // 16" pillar: 3 blocks
    } else {
      blocksPerRow = 4; // 20"+ pillar: 4 blocks
    }

    final rows = (heightIn / blockHeightIn).ceil();
    final blocksPerPillar = blocksPerRow * rows;
    final totalBlocks = blocksPerPillar * pillarCount;

    // Cap per pillar
    final caps = pillarCount;

    // Concrete fill: ~0.5 bags per row per pillar
    final concrete = rows * pillarCount * 0.5;

    setState(() {
      _blocksPerPillar = blocksPerPillar;
      _totalBlocks = totalBlocks;
      _capsNeeded = caps;
      _concreteBags = concrete;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _heightController.text = '36'; _pillarCountController.text = '2'; setState(() { _pillarSize = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pillar/Column', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PILLAR SIZE', ['12', '16', '20'], _pillarSize, {'12': '12\" sq', '16': '16\" sq', '20': '20\" sq'}, (v) { setState(() => _pillarSize = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Qty', unit: '', controller: _pillarCountController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalBlocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL BLOCKS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalBlocks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per pillar', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksPerPillar blocks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap stones', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete fill (80 lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPillarGuide(colors),
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

  Widget _buildPillarGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PILLAR CONSTRUCTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Foundation', '12\" below frost'),
        _buildTableRow(colors, 'Core fill', 'Concrete + rebar'),
        _buildTableRow(colors, 'Block adhesive', 'Between courses'),
        _buildTableRow(colors, 'Cap adhesive', 'Landscape adhesive'),
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
