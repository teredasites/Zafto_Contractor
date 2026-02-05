import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Triangle Area Calculator - Triangular sections
class TriangleAreaScreen extends ConsumerStatefulWidget {
  const TriangleAreaScreen({super.key});
  @override
  ConsumerState<TriangleAreaScreen> createState() => _TriangleAreaScreenState();
}

class _TriangleAreaScreenState extends ConsumerState<TriangleAreaScreen> {
  final _baseController = TextEditingController(text: '20');
  final _heightController = TextEditingController(text: '15');
  final _side1Controller = TextEditingController(text: '18');
  final _side2Controller = TextEditingController(text: '18');

  String _method = 'base_height';

  double? _area;
  double? _perimeter;

  @override
  void dispose() { _baseController.dispose(); _heightController.dispose(); _side1Controller.dispose(); _side2Controller.dispose(); super.dispose(); }

  void _calculate() {
    final base = double.tryParse(_baseController.text) ?? 20;
    final height = double.tryParse(_heightController.text) ?? 15;
    final side1 = double.tryParse(_side1Controller.text) ?? 18;
    final side2 = double.tryParse(_side2Controller.text) ?? 18;

    double area;
    double perimeter;

    switch (_method) {
      case 'base_height':
        area = (base * height) / 2;
        // Estimate perimeter using Pythagorean approximation
        final halfBase = base / 2;
        final sideEstimate = math.sqrt(halfBase * halfBase + height * height);
        perimeter = base + (sideEstimate * 2);
        break;
      case 'three_sides':
        // Heron's formula
        final s = (base + side1 + side2) / 2;
        area = math.sqrt(s * (s - base) * (s - side1) * (s - side2));
        perimeter = base + side1 + side2;
        break;
      default:
        area = (base * height) / 2;
        perimeter = base * 3;
    }

    setState(() {
      _area = area;
      _perimeter = perimeter;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _baseController.text = '20'; _heightController.text = '15'; _side1Controller.text = '18'; _side2Controller.text = '18'; setState(() { _method = 'base_height'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Triangle Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'METHOD', ['base_height', 'three_sides'], _method, {'base_height': 'Base x Height', 'three_sides': 'Three Sides'}, (v) { setState(() => _method = v); _calculate(); }),
            const SizedBox(height: 20),
            if (_method == 'base_height') ...[
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Base', unit: 'ft', controller: _baseController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
              ]),
            ] else ...[
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Side A', unit: 'ft', controller: _baseController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Side B', unit: 'ft', controller: _side1Controller, onChanged: (_) => _calculate())),
              ]),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Side C', unit: 'ft', controller: _side2Controller, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 32),
            if (_area != null && _area!.isFinite) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_area!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perimeter', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_perimeter!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_method == 'base_height' ? 'Base x Height / 2. Height is perpendicular distance from base to opposite point.' : "Heron's formula using all three sides. Sides must form valid triangle.", style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypesCard(colors),
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

  Widget _buildTypesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRIANGLE TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Equilateral', 'All sides equal'),
        _buildTableRow(colors, 'Isosceles', 'Two sides equal'),
        _buildTableRow(colors, 'Scalene', 'No sides equal'),
        _buildTableRow(colors, 'Right', 'One 90 deg angle'),
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
