import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Decomposed Granite Calculator - DG for paths
class DecomposedGraniteScreen extends ConsumerStatefulWidget {
  const DecomposedGraniteScreen({super.key});
  @override
  ConsumerState<DecomposedGraniteScreen> createState() => _DecomposedGraniteScreenState();
}

class _DecomposedGraniteScreenState extends ConsumerState<DecomposedGraniteScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _widthController = TextEditingController(text: '4');

  String _dgType = 'stabilized';
  String _depthIn = '3';

  double? _tonsNeeded;
  double? _baseGravelTons;
  double? _fabricSqFt;
  double? _edgingFt;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final width = double.tryParse(_widthController.text) ?? 4;
    final depth = double.tryParse(_depthIn) ?? 3;

    final area = length * width;
    final depthFt = depth / 12;
    final volumeCuFt = area * depthFt;
    final volumeCuYd = volumeCuFt / 27;

    // DG weight: ~1.5 tons per cubic yard
    final dgTons = volumeCuYd * 1.5;

    // Base gravel (for stabilized): 2" of 3/4" crushed
    double baseGravel = 0;
    if (_dgType == 'stabilized') {
      final baseVolume = area * (2 / 12) / 27;
      baseGravel = baseVolume * 1.4;
    }

    // Landscape fabric
    final fabric = area * 1.1; // 10% overlap

    // Edging
    final edging = (length + width) * 2;

    setState(() {
      _tonsNeeded = dgTons;
      _baseGravelTons = baseGravel;
      _fabricSqFt = fabric;
      _edgingFt = edging;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _widthController.text = '4'; setState(() { _dgType = 'stabilized'; _depthIn = '3'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Decomposed Granite', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'DG TYPE', ['loose', 'stabilized'], _dgType, {'loose': 'Loose DG', 'stabilized': 'Stabilized'}, (v) { setState(() => _dgType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'DEPTH', ['2', '3', '4'], _depthIn, {'2': '2\"', '3': '3\"', '4': '4\"'}, (v) { setState(() => _depthIn = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Path Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Path Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_tonsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DG NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tonsNeeded!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_baseGravelTons! > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseGravelTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landscape fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edging', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgingFt!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDgGuide(colors),
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

  Widget _buildDgGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DG INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Loose DG', 'Budget, rustic look'),
        _buildTableRow(colors, 'Stabilized', 'Binder, firmer surface'),
        _buildTableRow(colors, 'Compaction', 'Water + tamp layers'),
        _buildTableRow(colors, 'Edging', 'Steel or stone required'),
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
