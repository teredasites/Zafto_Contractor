import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slab Calculator - Thickness and area
class SlabCalculatorScreen extends ConsumerStatefulWidget {
  const SlabCalculatorScreen({super.key});
  @override
  ConsumerState<SlabCalculatorScreen> createState() => _SlabCalculatorScreenState();
}

class _SlabCalculatorScreenState extends ConsumerState<SlabCalculatorScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _thicknessController = TextEditingController(text: '4');

  bool _thickenedEdge = true;

  double? _slabArea;
  double? _concreteYards;
  double? _edgeYards;
  double? _totalYards;
  int? _meshRolls;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final thicknessInches = double.tryParse(_thicknessController.text);

    if (length == null || width == null || thicknessInches == null) {
      setState(() { _slabArea = null; _concreteYards = null; _edgeYards = null; _totalYards = null; _meshRolls = null; });
      return;
    }

    final thicknessFeet = thicknessInches / 12;
    final slabArea = length * width;
    final concreteYards = (slabArea * thicknessFeet) / 27;

    // Thickened edge: 12" wide x 12" deep around perimeter
    double edgeYards = 0;
    if (_thickenedEdge) {
      final perimeter = (length + width) * 2;
      final edgeVolume = perimeter * 1 * (12 / 12 - thicknessFeet); // Extra depth beyond slab
      edgeYards = edgeVolume / 27;
    }

    final totalYards = concreteYards + edgeYards;

    // Wire mesh: 6x6 W1.4/W1.4 rolls cover 750 sq ft
    final meshRolls = (slabArea / 750).ceil();

    setState(() { _slabArea = slabArea; _concreteYards = concreteYards; _edgeYards = edgeYards; _totalYards = totalYards; _meshRolls = meshRolls; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; _thicknessController.text = '4'; setState(() => _thickenedEdge = true); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Slab Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            _buildThickenedEdgeToggle(colors),
            const SizedBox(height: 32),
            if (_totalYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL CONCRETE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalYards!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slab Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_slabArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slab Concrete', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteYards!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_thickenedEdge) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Thickened Edge', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgeYards!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wire Mesh Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_meshRolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildThickenedEdgeToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _thickenedEdge = !_thickenedEdge); _calculate(); },
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(children: [
          Icon(_thickenedEdge ? LucideIcons.checkSquare : LucideIcons.square, color: _thickenedEdge ? colors.accentPrimary : colors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('Include Thickened Edge', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }
}
