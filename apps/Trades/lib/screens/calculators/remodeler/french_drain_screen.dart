import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// French Drain Calculator - Drainage system estimation
class FrenchDrainScreen extends ConsumerStatefulWidget {
  const FrenchDrainScreen({super.key});
  @override
  ConsumerState<FrenchDrainScreen> createState() => _FrenchDrainScreenState();
}

class _FrenchDrainScreenState extends ConsumerState<FrenchDrainScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _depthController = TextEditingController(text: '18');
  final _widthController = TextEditingController(text: '12');

  String _location = 'exterior';

  double? _gravelCuYd;
  double? _pipeFeet;
  double? _fabricSqft;
  double? _excavationCuYd;

  @override
  void dispose() { _lengthController.dispose(); _depthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final depth = double.tryParse(_depthController.text) ?? 18;
    final width = double.tryParse(_widthController.text) ?? 12;

    final depthFt = depth / 12;
    final widthFt = width / 12;

    // Excavation volume
    final excavationCuFt = length * depthFt * widthFt;
    final excavationCuYd = excavationCuFt / 27;

    // Gravel: fill trench minus pipe volume
    final gravelCuFt = excavationCuFt * 0.85; // 85% fill after pipe
    final gravelCuYd = gravelCuFt / 27;

    // Pipe: same as length + 10% for fittings
    final pipeFeet = length * 1.10;

    // Landscape fabric: wrap trench (bottom + 2 sides)
    final fabricWidth = widthFt + (depthFt * 2) + 1; // +1 for overlap
    final fabricSqft = fabricWidth * length;

    setState(() { _gravelCuYd = gravelCuYd; _pipeFeet = pipeFeet; _fabricSqft = fabricSqft; _excavationCuYd = excavationCuYd; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _depthController.text = '18'; _widthController.text = '12'; setState(() => _location = 'exterior'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('French Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Drain Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trench Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Trench Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gravelCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAVEL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perf Pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pipeFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Filter Fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Excavation', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_excavationCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Slope: 1\" per 8\' minimum. Use 4\" perforated pipe holes down. Wrap with fabric before gravel.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpecsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['exterior', 'interior', 'footer'];
    final labels = {'exterior': 'Exterior', 'interior': 'Interior', 'footer': 'Footer'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LOCATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _location == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _location = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSpecsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FRENCH DRAIN SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min depth', '12-18\"'),
        _buildTableRow(colors, 'Min width', '6-12\"'),
        _buildTableRow(colors, 'Slope', '1\" per 8\' min'),
        _buildTableRow(colors, 'Gravel size', '3/4\" - 1.5\"'),
        _buildTableRow(colors, 'Pipe size', '4\" standard'),
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
