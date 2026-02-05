import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compost Calculator - Cubic yards by depth
class CompostScreen extends ConsumerStatefulWidget {
  const CompostScreen({super.key});
  @override
  ConsumerState<CompostScreen> createState() => _CompostScreenState();
}

class _CompostScreenState extends ConsumerState<CompostScreen> {
  final _areaController = TextEditingController(text: '500');
  final _depthController = TextEditingController(text: '2');

  String _application = 'amendment';

  double? _cubicYards;
  double? _bags2cuft;

  @override
  void dispose() { _areaController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 500;
    final depthInches = double.tryParse(_depthController.text) ?? 2;

    final depthFeet = depthInches / 12;
    final cubicFeet = area * depthFeet;
    final cubicYards = cubicFeet / 27;

    // 2 cubic foot bags
    final bags2cuft = cubicFeet / 2;

    setState(() {
      _cubicYards = cubicYards;
      _bags2cuft = bags2cuft;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '500'; _depthController.text = '2'; setState(() { _application = 'amendment'; }); _calculate(); }

  String _getDepthForApplication() {
    switch (_application) {
      case 'topdress': return '1/4-1/2';
      case 'amendment': return '2-3';
      case 'newbed': return '4-6';
      case 'planting': return '25% of hole';
      default: return '2-3';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['topdress', 'amendment', 'newbed', 'planting'], _application, {'topdress': 'Top Dress', 'amendment': 'Soil Amend', 'newbed': 'New Bed', 'planting': 'Planting'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Recommended depth for ${_application.replaceAll('_', ' ')}: ${_getDepthForApplication()}"', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_cubicYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COMPOST NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags2cuft!.ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_bags2cuft! * 2).ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCompostTypes(colors),
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

  Widget _buildCompostTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMPOST TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mushroom', 'High nitrogen, alkaline'),
        _buildTableRow(colors, 'Leaf mold', 'Mild, good structure'),
        _buildTableRow(colors, 'Manure', 'High nitrogen, aged'),
        _buildTableRow(colors, 'Garden', 'Balanced, general use'),
        _buildTableRow(colors, 'Worm castings', 'Premium, concentrated'),
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
