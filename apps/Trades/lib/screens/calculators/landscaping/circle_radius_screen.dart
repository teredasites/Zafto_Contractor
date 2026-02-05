import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Circle/Radius Calculator - Round beds and circular areas
class CircleRadiusScreen extends ConsumerStatefulWidget {
  const CircleRadiusScreen({super.key});
  @override
  ConsumerState<CircleRadiusScreen> createState() => _CircleRadiusScreenState();
}

class _CircleRadiusScreenState extends ConsumerState<CircleRadiusScreen> {
  final _radiusController = TextEditingController(text: '10');

  String _inputType = 'radius';

  double? _area;
  double? _circumference;
  double? _diameter;
  double? _radius;

  @override
  void dispose() { _radiusController.dispose(); super.dispose(); }

  void _calculate() {
    final input = double.tryParse(_radiusController.text) ?? 10;

    double radius;
    switch (_inputType) {
      case 'radius':
        radius = input;
        break;
      case 'diameter':
        radius = input / 2;
        break;
      case 'circumference':
        radius = input / (2 * math.pi);
        break;
      default:
        radius = input;
    }

    final area = math.pi * radius * radius;
    final circumference = 2 * math.pi * radius;
    final diameter = radius * 2;

    setState(() {
      _area = area;
      _circumference = circumference;
      _diameter = diameter;
      _radius = radius;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _radiusController.text = '10'; setState(() { _inputType = 'radius'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Circle/Radius', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'INPUT TYPE', ['radius', 'diameter', 'circumference'], _inputType, {'radius': 'Radius', 'diameter': 'Diameter', 'circumference': 'Circumf.'}, (v) { setState(() => _inputType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: _inputType == 'radius' ? 'Radius' : _inputType == 'diameter' ? 'Diameter' : 'Circumference', unit: 'ft', controller: _radiusController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_area != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_area!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Radius', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_radius!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_diameter!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Circumference', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_circumference!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFormulasCard(colors),
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

  Widget _buildFormulasCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CIRCLE FORMULAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Area', 'pi x r x r'),
        _buildTableRow(colors, 'Circumference', '2 x pi x r'),
        _buildTableRow(colors, 'Diameter', '2 x r'),
        _buildTableRow(colors, 'pi value', '3.14159'),
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
