import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landscape Fabric Calculator - Rolls needed
class FabricCoverageScreen extends ConsumerStatefulWidget {
  const FabricCoverageScreen({super.key});
  @override
  ConsumerState<FabricCoverageScreen> createState() => _FabricCoverageScreenState();
}

class _FabricCoverageScreenState extends ConsumerState<FabricCoverageScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '6');

  String _rollWidth = '3';
  double _overlapIn = 6;

  double? _areaSqFt;
  double? _fabricSqFt;
  double? _rollsNeeded;
  int? _stakesNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final width = double.tryParse(_widthController.text) ?? 6;
    final rollWidthFt = double.tryParse(_rollWidth) ?? 3;

    final area = length * width;

    // Account for overlap
    final overlapFt = _overlapIn / 12;
    final effectiveWidth = rollWidthFt - overlapFt;

    // Number of strips needed
    final strips = (width / effectiveWidth).ceil();
    final fabricLength = length * strips;
    final fabricSqFt = fabricLength * rollWidthFt;

    // Standard rolls: 3' × 100' or 4' × 100'
    final rollSqFt = rollWidthFt * 100;
    final rolls = fabricSqFt / rollSqFt;

    // Stakes: 1 per 2 sq ft on edges, 1 per 4 sq ft interior
    final perimeter = (length + width) * 2;
    final perimeterStakes = (perimeter / 2).ceil();
    final interiorStakes = (area / 8).ceil();
    final totalStakes = perimeterStakes + interiorStakes;

    setState(() {
      _areaSqFt = area;
      _fabricSqFt = fabricSqFt;
      _rollsNeeded = rolls;
      _stakesNeeded = totalStakes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '6'; setState(() { _rollWidth = '3'; _overlapIn = 6; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landscape Fabric', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROLL WIDTH', ['3', '4', '6'], _rollWidth, {'3': "3'", '4': "4'", '6': "6'"}, (v) { setState(() => _rollWidth = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bed Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('Overlap:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _overlapIn, min: 3, max: 12, divisions: 3, label: '${_overlapIn.toInt()}"', onChanged: (v) { setState(() => _overlapIn = v); _calculate(); })),
              Text('${_overlapIn.toInt()}"', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_fabricSqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROLLS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rollsNeeded!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Text("$_rollWidth' × 100' rolls", style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bed area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fabric with overlap', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_stakesNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFabricGuide(colors),
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

  Widget _buildFabricGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FABRIC TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Woven', 'Heavy duty, paths'),
        _buildTableRow(colors, 'Non-woven', 'Beds, water drainage'),
        _buildTableRow(colors, 'Overlap', '6-12" minimum'),
        _buildTableRow(colors, 'Stakes', 'Every 2-3 ft edges'),
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
