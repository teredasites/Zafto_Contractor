import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Xeriscape Calculator - Water-wise landscaping materials
class XeriscapeScreen extends ConsumerStatefulWidget {
  const XeriscapeScreen({super.key});
  @override
  ConsumerState<XeriscapeScreen> createState() => _XeriscapeScreenState();
}

class _XeriscapeScreenState extends ConsumerState<XeriscapeScreen> {
  final _areaController = TextEditingController(text: '500');

  String _coverType = 'gravel';

  double? _materialTons;
  double? _fabricSqFt;
  int? _plantCount;
  double? _waterSavings;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 500;

    double materialTons;
    int plants;
    double waterSavingsPercent;

    switch (_coverType) {
      case 'gravel':
        // 3" depth gravel
        final volumeCuFt = area * 0.25;
        materialTons = (volumeCuFt / 27) * 1.4;
        plants = (area / 25).ceil(); // 1 plant per 25 sq ft
        waterSavingsPercent = 75;
        break;
      case 'mulch':
        // 4" depth mulch
        final volumeCuFt = area * (4 / 12);
        materialTons = (volumeCuFt / 27) * 0.5; // mulch is lighter
        plants = (area / 16).ceil(); // denser planting
        waterSavingsPercent = 50;
        break;
      case 'groundcover':
        materialTons = 0;
        plants = (area / 4).ceil(); // 1 per 4 sq ft
        waterSavingsPercent = 60;
        break;
      default:
        materialTons = 0;
        plants = (area / 25).ceil();
        waterSavingsPercent = 50;
    }

    final fabric = area * 1.1; // 10% overlap

    setState(() {
      _materialTons = materialTons;
      _fabricSqFt = fabric;
      _plantCount = plants;
      _waterSavings = waterSavingsPercent;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '500'; setState(() { _coverType = 'gravel'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Xeriscape', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GROUND COVER', ['gravel', 'mulch', 'groundcover'], _coverType, {'gravel': 'Gravel/Rock', 'mulch': 'Bark Mulch', 'groundcover': 'Plants Only'}, (v) { setState(() => _coverType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_plantCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MATERIALS NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                if (_materialTons! > 0) _buildMaterialRow(colors, _coverType == 'gravel' ? 'Gravel' : 'Mulch', '${_materialTons!.toStringAsFixed(2)} tons'),
                _buildMaterialRow(colors, 'Drought-tolerant plants', '$_plantCount'),
                _buildMaterialRow(colors, 'Landscape fabric', '${_fabricSqFt!.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Est. water savings', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text('${_waterSavings!.toStringAsFixed(0)}%', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildXeriscapeGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildXeriscapeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('XERISCAPE PRINCIPLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Planning', 'Group by water needs'),
        _buildTableRow(colors, 'Soil', 'Improve drainage'),
        _buildTableRow(colors, 'Mulch', '3-4\" depth'),
        _buildTableRow(colors, 'Irrigation', 'Drip, efficient'),
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
