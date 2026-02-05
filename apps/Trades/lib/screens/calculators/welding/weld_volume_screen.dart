import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Weld Volume Calculator - Cross-sectional area and volume
class WeldVolumeScreen extends ConsumerStatefulWidget {
  const WeldVolumeScreen({super.key});
  @override
  ConsumerState<WeldVolumeScreen> createState() => _WeldVolumeScreenState();
}

class _WeldVolumeScreenState extends ConsumerState<WeldVolumeScreen> {
  final _lengthController = TextEditingController();
  final _dim1Controller = TextEditingController();
  final _dim2Controller = TextEditingController();
  String _weldType = 'Fillet';

  double? _area;
  double? _volume;
  double? _weight;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final dim1 = double.tryParse(_dim1Controller.text);
    final dim2 = double.tryParse(_dim2Controller.text);

    if (length == null || dim1 == null || length <= 0 || dim1 <= 0) {
      setState(() { _area = null; });
      return;
    }

    double area;
    if (_weldType == 'Fillet') {
      // Equal leg fillet: A = leg^2 / 2
      area = (dim1 * dim1) / 2;
    } else if (_weldType == 'Unequal Fillet') {
      // Unequal leg: A = leg1 * leg2 / 2
      final leg2 = dim2 ?? dim1;
      area = (dim1 * leg2) / 2;
    } else if (_weldType == 'V-Groove') {
      // V-groove: A = thickness * root opening + triangular area
      final thickness = dim1;
      final rootOpening = dim2 ?? 0.125;
      final grooveAngle = 60; // degrees, typical
      final halfAngle = grooveAngle / 2 * (math.pi / 180);
      area = (thickness * rootOpening) + (thickness * thickness * math.tan(halfAngle));
    } else if (_weldType == 'Square Groove') {
      // Square groove: A = thickness * gap
      final thickness = dim1;
      final gap = dim2 ?? 0.125;
      area = thickness * gap;
    } else {
      // Bevel: A = 0.5 * thickness * (thickness * tan(angle))
      final thickness = dim1;
      area = 0.5 * thickness * thickness * math.tan(37.5 * math.pi / 180);
    }

    // Volume in cubic inches (length in feet)
    final volume = area * length * 12;

    // Weight (steel density 0.284 lb/cu in)
    final weight = volume * 0.284;

    setState(() {
      _area = area;
      _volume = volume;
      _weight = weight;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _dim1Controller.clear();
    _dim2Controller.clear();
    setState(() { _area = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _dim1Controller.dispose();
    _dim2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Weld Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Linear feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(
              label: _weldType.contains('Fillet') ? 'Leg Size' : 'Thickness',
              unit: 'in',
              hint: _weldType.contains('Fillet') ? 'Fillet leg' : 'Material thickness',
              controller: _dim1Controller,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            if (_weldType != 'Fillet' && _weldType != 'Bevel') ZaftoInputField(
              label: _weldType == 'Unequal Fillet' ? 'Second Leg' : 'Root/Gap',
              unit: 'in',
              hint: _weldType == 'Unequal Fillet' ? 'Second leg size' : 'Root opening',
              controller: _dim2Controller,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 32),
            if (_area != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Fillet', 'Unequal Fillet', 'V-Groove', 'Square Groove', 'Bevel'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t, style: const TextStyle(fontSize: 11)),
        selected: _weldType == t,
        onSelected: (_) => setState(() { _weldType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Volume = Area x Length', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Calculate weld metal volume and weight', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Weld Metal', '${_weight!.toStringAsFixed(2)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Volume', '${_volume!.toStringAsFixed(3)} cu in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cross-Section', '${_area!.toStringAsFixed(4)} sq in'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
