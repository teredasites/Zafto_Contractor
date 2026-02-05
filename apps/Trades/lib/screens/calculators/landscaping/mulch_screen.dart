import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mulch Calculator - Cubic yards by depth
class MulchScreen extends ConsumerStatefulWidget {
  const MulchScreen({super.key});
  @override
  ConsumerState<MulchScreen> createState() => _MulchScreenState();
}

class _MulchScreenState extends ConsumerState<MulchScreen> {
  final _areaController = TextEditingController(text: '500');
  final _depthController = TextEditingController(text: '3');

  String _mulchType = 'hardwood';

  double? _cubicYards;
  double? _bags2cuft;
  double? _bags3cuft;

  @override
  void dispose() { _areaController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 500;
    final depthInches = double.tryParse(_depthController.text) ?? 3;

    final depthFeet = depthInches / 12;
    final cubicFeet = area * depthFeet;
    final cubicYards = cubicFeet / 27;

    final bags2cuft = cubicFeet / 2;
    final bags3cuft = cubicFeet / 3;

    setState(() {
      _cubicYards = cubicYards;
      _bags2cuft = bags2cuft;
      _bags3cuft = bags3cuft;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '500'; _depthController.text = '3'; setState(() { _mulchType = 'hardwood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mulch Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MULCH TYPE', ['hardwood', 'cedar', 'pine', 'rubber'], _mulchType, {'hardwood': 'Hardwood', 'cedar': 'Cedar', 'pine': 'Pine Bark', 'rubber': 'Rubber'}, (v) { setState(() => _mulchType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cubicYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MULCH NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags2cuft!.ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('3 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags3cuft!.ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Bulk delivery is usually more economical for orders over 3 cubic yards.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDepthGuide(colors),
            const SizedBox(height: 16),
            _buildMulchInfo(colors),
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

  Widget _buildDepthGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDED DEPTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Flower beds', '2-3"'),
        _buildTableRow(colors, 'Shrub beds', '3-4"'),
        _buildTableRow(colors, 'Tree rings', '2-4"'),
        _buildTableRow(colors, 'Pathways', '3-4"'),
        _buildTableRow(colors, 'Playgrounds', '6-12"'),
      ]),
    );
  }

  Widget _buildMulchInfo(ZaftoColors colors) {
    String info;
    switch (_mulchType) {
      case 'hardwood':
        info = 'Hardwood: Decomposes slowly, adds nutrients. May mat if too thick.';
        break;
      case 'cedar':
        info = 'Cedar: Natural pest repellent, aromatic. Longer lasting than hardwood.';
        break;
      case 'pine':
        info = 'Pine Bark: Lightweight, acidic. Good for acid-loving plants.';
        break;
      case 'rubber':
        info = 'Rubber: Permanent, no decomposition. Best for playgrounds. Does not add nutrients.';
        break;
      default:
        info = '';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(info, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
