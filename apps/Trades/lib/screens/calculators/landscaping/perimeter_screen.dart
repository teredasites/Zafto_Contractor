import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Perimeter Calculator - Edging needs
class PerimeterScreen extends ConsumerStatefulWidget {
  const PerimeterScreen({super.key});
  @override
  ConsumerState<PerimeterScreen> createState() => _PerimeterScreenState();
}

class _PerimeterScreenState extends ConsumerState<PerimeterScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');

  String _shape = 'rectangle';

  double? _perimeter;
  double? _edgingNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final width = double.tryParse(_widthController.text) ?? 30;

    double perimeter;

    switch (_shape) {
      case 'rectangle':
        perimeter = 2 * (length + width);
        break;
      case 'square':
        perimeter = 4 * length;
        break;
      case 'circle':
        perimeter = math.pi * length; // diameter input
        break;
      case 'triangle':
        // Assumes isosceles with base = length, equal sides estimated
        final side = math.sqrt((width * width) + ((length / 2) * (length / 2)));
        perimeter = length + (2 * side);
        break;
      default:
        perimeter = 2 * (length + width);
    }

    // Add 10% for waste/curves
    final edgingNeeded = perimeter * 1.10;

    setState(() {
      _perimeter = perimeter;
      _edgingNeeded = edgingNeeded;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; setState(() { _shape = 'rectangle'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Perimeter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHAPE', ['rectangle', 'square', 'circle', 'triangle'], _shape, {'rectangle': 'Rectangle', 'square': 'Square', 'circle': 'Circle', 'triangle': 'Triangle'}, (v) { setState(() => _shape = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: _shape == 'circle' ? 'Diameter' : _shape == 'triangle' ? 'Base' : 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              if (_shape == 'rectangle' || _shape == 'triangle') ...[
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: _shape == 'triangle' ? 'Height' : 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
              ],
            ]),
            const SizedBox(height: 32),
            if (_perimeter != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PERIMETER', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_perimeter!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edging Needed (+10%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgingNeeded!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add 10% for waste, curves, and overlaps. Edging typically sold in 20 ft sections.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildEdgingTable(colors),
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

  Widget _buildEdgingTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON EDGING TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Steel edging', '4" height, 16 ft sections'),
        _buildTableRow(colors, 'Aluminum', '4" height, flexible'),
        _buildTableRow(colors, 'Plastic roll', '4-6", 20-60 ft rolls'),
        _buildTableRow(colors, 'Brick/paver', '4" x 8" typical'),
        _buildTableRow(colors, 'Concrete', '6" x 12" x 2" blocks'),
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
