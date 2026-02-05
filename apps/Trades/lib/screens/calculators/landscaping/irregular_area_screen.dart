import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Irregular Area Calculator - Complex shape estimation
class IrregularAreaScreen extends ConsumerStatefulWidget {
  const IrregularAreaScreen({super.key});
  @override
  ConsumerState<IrregularAreaScreen> createState() => _IrregularAreaScreenState();
}

class _IrregularAreaScreenState extends ConsumerState<IrregularAreaScreen> {
  final _baseController = TextEditingController(text: '50');
  final _heightController = TextEditingController(text: '30');
  final _side1Controller = TextEditingController(text: '40');
  final _side2Controller = TextEditingController(text: '35');

  String _method = 'trapezoid';

  double? _area;

  @override
  void dispose() { _baseController.dispose(); _heightController.dispose(); _side1Controller.dispose(); _side2Controller.dispose(); super.dispose(); }

  void _calculate() {
    final base = double.tryParse(_baseController.text) ?? 50;
    final height = double.tryParse(_heightController.text) ?? 30;
    final side1 = double.tryParse(_side1Controller.text) ?? 40;
    final side2 = double.tryParse(_side2Controller.text) ?? 35;

    double area;

    switch (_method) {
      case 'trapezoid':
        area = ((base + side1) / 2) * height;
        break;
      case 'triangle':
        area = (base * height) / 2;
        break;
      case 'lshape':
        // L-shape: two rectangles
        area = (base * height) + (side1 * side2);
        break;
      case 'average':
        // Average width method for irregular
        area = ((base + side1 + side2) / 3) * height;
        break;
      default:
        area = base * height;
    }

    setState(() { _area = area; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _baseController.text = '50'; _heightController.text = '30'; _side1Controller.text = '40'; _side2Controller.text = '35'; setState(() { _method = 'trapezoid'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Irregular Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'METHOD', ['trapezoid', 'triangle', 'lshape', 'average'], _method, {'trapezoid': 'Trapezoid', 'triangle': 'Triangle', 'lshape': 'L-Shape', 'average': 'Avg Width'}, (v) { setState(() => _method = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: _method == 'triangle' ? 'Base' : 'Base/Side A', unit: 'ft', controller: _baseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height/Length', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            if (_method != 'triangle') Row(children: [
              Expanded(child: ZaftoInputField(label: _method == 'trapezoid' ? 'Top/Side B' : 'Section 2 Width', unit: 'ft', controller: _side1Controller, onChanged: (_) => _calculate())),
              if (_method == 'lshape' || _method == 'average') ...[
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: _method == 'lshape' ? 'Section 2 Length' : 'Side C', unit: 'ft', controller: _side2Controller, onChanged: (_) => _calculate())),
              ],
            ]),
            const SizedBox(height: 32),
            if (_area != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ESTIMATED AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_area!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMethodDescription(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTipsCard(colors),
          ]),
        ),
      ),
    );
  }

  String _getMethodDescription() {
    switch (_method) {
      case 'trapezoid': return 'Trapezoid: (Base + Top) / 2 x Height. Good for beds wider at one end.';
      case 'triangle': return 'Triangle: Base x Height / 2. Good for corner beds.';
      case 'lshape': return 'L-Shape: Two rectangles added together. Enter dimensions for each section.';
      case 'average': return 'Average Width: Take 3 width measurements, average them, multiply by length.';
      default: return '';
    }
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

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASURING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Break complex shapes into simple shapes', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text('2. Measure longest and shortest widths', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text('3. Add 5-10% for waste/odd corners', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text('4. Use string/stakes for curves', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
