import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Planter Box Calculator - Soil volume for planters
class PlanterBoxScreen extends ConsumerStatefulWidget {
  const PlanterBoxScreen({super.key});
  @override
  ConsumerState<PlanterBoxScreen> createState() => _PlanterBoxScreenState();
}

class _PlanterBoxScreenState extends ConsumerState<PlanterBoxScreen> {
  final _lengthController = TextEditingController(text: '36');
  final _widthController = TextEditingController(text: '12');
  final _depthController = TextEditingController(text: '12');

  String _shape = 'rectangle';

  double? _volumeCuFt;
  double? _soilBags;
  double? _drainageGravelCuFt;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 36;
    final width = double.tryParse(_widthController.text) ?? 12;
    final depth = double.tryParse(_depthController.text) ?? 12;

    // Convert to feet
    final lengthFt = length / 12;
    final widthFt = width / 12;
    final depthFt = depth / 12;

    double volumeCuFt;
    if (_shape == 'rectangle') {
      volumeCuFt = lengthFt * widthFt * depthFt;
    } else {
      // Circle: diameter = length, radius = length/2
      final radiusFt = lengthFt / 2;
      volumeCuFt = 3.14159 * radiusFt * radiusFt * depthFt;
    }

    // Drainage gravel: bottom 2" (accounting for this in soil)
    final gravelDepthFt = 2 / 12;
    double gravelCuFt;
    if (_shape == 'rectangle') {
      gravelCuFt = lengthFt * widthFt * gravelDepthFt;
    } else {
      final radiusFt = lengthFt / 2;
      gravelCuFt = 3.14159 * radiusFt * radiusFt * gravelDepthFt;
    }

    // Net soil volume
    final soilCuFt = volumeCuFt - gravelCuFt;

    // Standard potting soil bag = 2 cu ft
    final bags = soilCuFt / 2;

    setState(() {
      _volumeCuFt = volumeCuFt;
      _soilBags = bags;
      _drainageGravelCuFt = gravelCuFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '36'; _widthController.text = '12'; _depthController.text = '12'; setState(() { _shape = 'rectangle'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Planter Box', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHAPE', ['rectangle', 'circle'], _shape, {'rectangle': 'Rectangle', 'circle': 'Round'}, (v) { setState(() => _shape = v); _calculate(); }),
            const SizedBox(height: 20),
            if (_shape == 'rectangle') Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'in', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'in', controller: _widthController, onChanged: (_) => _calculate())),
            ]) else ZaftoInputField(label: 'Diameter', unit: 'in', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'in', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_volumeCuFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POTTING SOIL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilBags!.toStringAsFixed(1)} bags', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Text('2 cu ft bags', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuFt!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drainage gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_drainageGravelCuFt!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlanterGuide(colors),
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

  Widget _buildPlanterGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLANTER TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Drainage holes', 'Required'),
        _buildTableRow(colors, 'Gravel layer', '1-2\" at bottom'),
        _buildTableRow(colors, 'Soil level', '1\" below rim'),
        _buildTableRow(colors, 'Settling', 'Add 10% more'),
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
