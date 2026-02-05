import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Groove Weld Area Calculator - Cross-sectional area for groove welds
class GrooveWeldAreaScreen extends ConsumerStatefulWidget {
  const GrooveWeldAreaScreen({super.key});
  @override
  ConsumerState<GrooveWeldAreaScreen> createState() => _GrooveWeldAreaScreenState();
}

class _GrooveWeldAreaScreenState extends ConsumerState<GrooveWeldAreaScreen> {
  final _thicknessController = TextEditingController();
  final _rootOpeningController = TextEditingController(text: '0.125');
  final _rootFaceController = TextEditingController(text: '0.0625');
  final _grooveAngleController = TextEditingController(text: '60');
  String _grooveType = 'Single V';

  double? _area;
  double? _areaPerFoot;
  double? _reinforcement;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final rootOpening = double.tryParse(_rootOpeningController.text) ?? 0.125;
    final rootFace = double.tryParse(_rootFaceController.text) ?? 0.0625;
    final grooveAngle = double.tryParse(_grooveAngleController.text) ?? 60;

    if (thickness == null || thickness <= 0) {
      setState(() { _area = null; });
      return;
    }

    final halfAngle = (grooveAngle / 2) * (math.pi / 180);
    double area;

    if (_grooveType == 'Single V') {
      // Rectangle at root + triangle for groove
      final grooveDepth = thickness - rootFace;
      final topWidth = 2 * grooveDepth * math.tan(halfAngle);
      area = (rootOpening * thickness) + (grooveDepth * (rootOpening + topWidth) / 2);
    } else if (_grooveType == 'Double V') {
      // Two triangles meeting at center
      final grooveDepth = (thickness - rootFace) / 2;
      final triangleArea = grooveDepth * grooveDepth * math.tan(halfAngle);
      area = (rootFace * rootOpening) + (2 * triangleArea);
    } else if (_grooveType == 'Single Bevel') {
      // One-sided bevel
      final grooveDepth = thickness - rootFace;
      area = (rootOpening * thickness) + (0.5 * grooveDepth * grooveDepth * math.tan(halfAngle));
    } else if (_grooveType == 'Single U') {
      // U-groove (approximation)
      final grooveDepth = thickness - rootFace;
      final radius = 0.25; // Typical root radius
      area = (rootOpening * thickness) + (math.pi * radius * radius / 2) + (grooveDepth * grooveDepth * math.tan(halfAngle) * 0.8);
    } else {
      // Square groove
      area = thickness * rootOpening;
    }

    // Add reinforcement (typically 1/16" to 1/8" cap height)
    final reinforcementHeight = 0.09375; // 3/32"
    final reinforcement = reinforcementHeight * (rootOpening + 2 * thickness * math.tan(halfAngle)) * 0.5;

    setState(() {
      _area = area;
      _areaPerFoot = area * 12;
      _reinforcement = reinforcement;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _rootOpeningController.text = '0.125';
    _rootFaceController.text = '0.0625';
    _grooveAngleController.text = '60';
    setState(() { _area = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _rootOpeningController.dispose();
    _rootFaceController.dispose();
    _grooveAngleController.dispose();
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
        title: Text('Groove Weld Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Plate thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Root Opening', unit: 'in', hint: '1/8" typical', controller: _rootOpeningController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Root Face', unit: 'in', hint: '1/16" typical', controller: _rootFaceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Groove Angle', unit: 'deg', hint: '60 included', controller: _grooveAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_area != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Single V', 'Double V', 'Single Bevel', 'Single U', 'Square'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t, style: const TextStyle(fontSize: 11)),
        selected: _grooveType == t,
        onSelected: (_) => setState(() { _grooveType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Groove Cross-Sectional Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Calculate weld metal area for groove welds', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Cross-Section', '${_area!.toStringAsFixed(4)} sq in', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Foot', '${_areaPerFoot!.toStringAsFixed(3)} cu in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Reinforcement', '+${_reinforcement!.toStringAsFixed(4)} sq in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Weight/ft', '${((_areaPerFoot! + _reinforcement! * 12) * 0.284).toStringAsFixed(2)} lbs'),
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
