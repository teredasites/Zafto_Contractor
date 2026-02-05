import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Countertop Calculator - Kitchen/bath countertop estimation
class CountertopScreen extends ConsumerStatefulWidget {
  const CountertopScreen({super.key});
  @override
  ConsumerState<CountertopScreen> createState() => _CountertopScreenState();
}

class _CountertopScreenState extends ConsumerState<CountertopScreen> {
  final _lengthController = TextEditingController(text: '15');
  final _depthController = TextEditingController(text: '25');

  String _material = 'quartz';
  String _edge = 'eased';

  double? _sqft;
  double? _edgeLF;
  double? _slabs;

  @override
  void dispose() { _lengthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final depth = double.tryParse(_depthController.text) ?? 25;

    // Convert depth to feet
    final depthFt = depth / 12;
    final sqft = length * depthFt;

    // Edge linear feet (exposed edges)
    final edgeLF = length + (depthFt * 2); // Front + 2 ends typically

    // Slabs needed (standard slab ~55 sqft usable)
    final slabs = (sqft * 1.15) / 55; // 15% waste

    setState(() { _sqft = sqft; _edgeLF = edgeLF; _slabs = slabs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '15'; _depthController.text = '25'; setState(() { _material = 'quartz'; _edge = 'eased'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Countertop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['laminate', 'granite', 'quartz', 'marble'], _material, {'laminate': 'Laminate', 'granite': 'Granite', 'quartz': 'Quartz', 'marble': 'Marble'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'EDGE PROFILE', ['eased', 'bullnose', 'bevel', 'ogee'], _edge, {'eased': 'Eased', 'bullnose': 'Bullnose', 'bevel': 'Bevel', 'ogee': 'Ogee'}, (v) { setState(() => _edge = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COUNTER AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edge Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgeLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slabs (w/ waste)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_slabs!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard depth 25\". Add 1.5\" for overhang. Seams needed for runs >10\'.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPriceTable(colors),
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

  Widget _buildPriceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLED COST RANGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Laminate', '\$15-40/sqft'),
        _buildTableRow(colors, 'Granite', '\$50-150/sqft'),
        _buildTableRow(colors, 'Quartz', '\$60-150/sqft'),
        _buildTableRow(colors, 'Marble', '\$75-200/sqft'),
        _buildTableRow(colors, 'Butcher block', '\$40-100/sqft'),
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
