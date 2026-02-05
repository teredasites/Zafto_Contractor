import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Square Footage Calculator - Area calculations
class SqftScreen extends ConsumerStatefulWidget {
  const SqftScreen({super.key});
  @override
  ConsumerState<SqftScreen> createState() => _SqftScreenState();
}

class _SqftScreenState extends ConsumerState<SqftScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');

  String _shape = 'rectangle';
  String _unit = 'feet';

  double? _areaSqFt;
  double? _areaSqYd;
  double? _areaAcres;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);

    if (length == null) {
      setState(() { _areaSqFt = null; _areaSqYd = null; _areaAcres = null; });
      return;
    }

    double areaSqFt;

    // Convert input to feet if needed
    double l = length;
    double w = width ?? length;
    if (_unit == 'inches') { l /= 12; w /= 12; }
    else if (_unit == 'yards') { l *= 3; w *= 3; }

    switch (_shape) {
      case 'rectangle':
        areaSqFt = l * w;
        break;
      case 'triangle':
        areaSqFt = (l * w) / 2;
        break;
      case 'circle':
        // Length is diameter
        final radius = l / 2;
        areaSqFt = 3.14159 * radius * radius;
        break;
      default:
        areaSqFt = l * w;
    }

    final areaSqYd = areaSqFt / 9;
    final areaAcres = areaSqFt / 43560;

    setState(() { _areaSqFt = areaSqFt; _areaSqYd = areaSqYd; _areaAcres = areaAcres; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; setState(() { _shape = 'rectangle'; _unit = 'feet'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Square Footage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHAPE', ['rectangle', 'triangle', 'circle'], _shape, {'rectangle': 'Rectangle', 'triangle': 'Triangle', 'circle': 'Circle'}, (v) { setState(() => _shape = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'UNITS', ['inches', 'feet', 'yards'], _unit, {'inches': 'Inches', 'feet': 'Feet', 'yards': 'Yards'}, (v) { setState(() => _unit = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: _shape == 'circle' ? 'Diameter' : 'Length', unit: _unit, controller: _lengthController, onChanged: (_) => _calculate())),
              if (_shape != 'circle') ...[
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: _shape == 'triangle' ? 'Base Height' : 'Width', unit: _unit, controller: _widthController, onChanged: (_) => _calculate())),
              ],
            ]),
            const SizedBox(height: 32),
            if (_areaSqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Square Yards', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqYd!.toStringAsFixed(2)} sq yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Acres', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaAcres!.toStringAsFixed(4)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('For irregular shapes, break into rectangles/triangles and add together.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildConversionsTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildConversionsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONVERSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1 sq yard', '9 sq ft'),
        _buildTableRow(colors, '1 acre', '43,560 sq ft'),
        _buildTableRow(colors, '1 sq meter', '10.764 sq ft'),
        _buildTableRow(colors, '100 sq ft', '1 square (roofing)'),
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
