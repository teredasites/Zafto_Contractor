import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mulch Ring Calculator - Circular mulch beds
class MulchRingScreen extends ConsumerStatefulWidget {
  const MulchRingScreen({super.key});
  @override
  ConsumerState<MulchRingScreen> createState() => _MulchRingScreenState();
}

class _MulchRingScreenState extends ConsumerState<MulchRingScreen> {
  final _outerRadiusController = TextEditingController(text: '4');
  final _innerRadiusController = TextEditingController(text: '0.5');
  final _ringCountController = TextEditingController(text: '5');

  String _depthIn = '3';

  double? _areaSqFt;
  double? _mulchCuYd;
  double? _bagCount;

  @override
  void dispose() { _outerRadiusController.dispose(); _innerRadiusController.dispose(); _ringCountController.dispose(); super.dispose(); }

  void _calculate() {
    final outerRadius = double.tryParse(_outerRadiusController.text) ?? 4;
    final innerRadius = double.tryParse(_innerRadiusController.text) ?? 0.5;
    final ringCount = int.tryParse(_ringCountController.text) ?? 5;
    final depth = double.tryParse(_depthIn) ?? 3;

    // Area of ring = π(R² - r²)
    final ringArea = 3.14159 * (outerRadius * outerRadius - innerRadius * innerRadius);
    final totalArea = ringArea * ringCount;

    final depthFt = depth / 12;
    final volumeCuFt = totalArea * depthFt;
    final volumeCuYd = volumeCuFt / 27;

    // 2 cu ft bags
    final bags = volumeCuFt / 2;

    setState(() {
      _areaSqFt = totalArea;
      _mulchCuYd = volumeCuYd;
      _bagCount = bags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _outerRadiusController.text = '4'; _innerRadiusController.text = '0.5'; _ringCountController.text = '5'; setState(() { _depthIn = '3'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mulch Rings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MULCH DEPTH', ['2', '3', '4'], _depthIn, {'2': '2\"', '3': '3\"', '4': '4\"'}, (v) { setState(() => _depthIn = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Outer Radius', unit: 'ft', controller: _outerRadiusController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Inner Radius', unit: 'ft', controller: _innerRadiusController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Trees', unit: '', controller: _ringCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_mulchCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MULCH NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_bagCount!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRingGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildRingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MULCH RING GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min radius', "3' from trunk"),
        _buildTableRow(colors, 'Ideal radius', "Drip line"),
        _buildTableRow(colors, 'Trunk gap', '3-6\" clearance'),
        _buildTableRow(colors, 'No volcano!', 'Keep flat, not mounded'),
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
