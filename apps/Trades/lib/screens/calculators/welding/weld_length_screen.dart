import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Weld Length Calculator - Calculate weld lengths for shapes
class WeldLengthScreen extends ConsumerStatefulWidget {
  const WeldLengthScreen({super.key});
  @override
  ConsumerState<WeldLengthScreen> createState() => _WeldLengthScreenState();
}

class _WeldLengthScreenState extends ConsumerState<WeldLengthScreen> {
  final _dim1Controller = TextEditingController();
  final _dim2Controller = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _shape = 'Linear';
  bool _bothSides = false;

  double? _totalLength;
  double? _perPiece;

  void _calculate() {
    final dim1 = double.tryParse(_dim1Controller.text);
    final dim2 = double.tryParse(_dim2Controller.text);
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (dim1 == null || dim1 <= 0) {
      setState(() { _totalLength = null; });
      return;
    }

    double perPiece;
    if (_shape == 'Linear') {
      perPiece = dim1;
    } else if (_shape == 'Rectangle') {
      final width = dim2 ?? dim1;
      perPiece = 2 * (dim1 + width);
    } else if (_shape == 'Circle') {
      perPiece = math.pi * dim1; // dim1 is diameter
    } else if (_shape == 'Pipe') {
      perPiece = math.pi * dim1; // Circumference
    } else if (_shape == 'Square') {
      perPiece = 4 * dim1;
    } else if (_shape == 'Triangle') {
      perPiece = 3 * dim1; // Equilateral
    } else {
      perPiece = dim1;
    }

    if (_bothSides) {
      perPiece *= 2;
    }

    final totalLength = perPiece * quantity;

    setState(() {
      _perPiece = perPiece;
      _totalLength = totalLength;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dim1Controller.clear();
    _dim2Controller.clear();
    _quantityController.text = '1';
    setState(() { _totalLength = null; });
  }

  @override
  void dispose() {
    _dim1Controller.dispose();
    _dim2Controller.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    String dim1Label, dim1Hint;
    bool showDim2 = false;
    switch (_shape) {
      case 'Circle':
      case 'Pipe':
        dim1Label = 'Diameter';
        dim1Hint = 'OD in inches';
        break;
      case 'Rectangle':
        dim1Label = 'Length';
        dim1Hint = 'Longer side';
        showDim2 = true;
        break;
      default:
        dim1Label = 'Length';
        dim1Hint = 'Weld length in inches';
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Weld Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildShapeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: dim1Label, unit: 'in', hint: dim1Hint, controller: _dim1Controller, onChanged: (_) => _calculate()),
            if (showDim2) ...[
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Width', unit: 'in', hint: 'Shorter side', controller: _dim2Controller, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Quantity', unit: 'pcs', hint: 'Number of pieces', controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text('Weld Both Sides', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              value: _bothSides,
              onChanged: (v) => setState(() { _bothSides = v ?? false; _calculate(); }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            if (_totalLength != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildShapeSelector(ZaftoColors colors) {
    final shapes = ['Linear', 'Rectangle', 'Square', 'Circle', 'Pipe', 'Triangle'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shapes.map((s) => ChoiceChip(
        label: Text(s),
        selected: _shape == s,
        onSelected: (_) => setState(() { _shape = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Total Weld Length Calculator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Calculate linear weld footage for estimates', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Length', '${(_totalLength! / 12).toStringAsFixed(1)} ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'In Inches', '${_totalLength!.toStringAsFixed(1)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Piece', '${_perPiece!.toStringAsFixed(1)}"'),
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
