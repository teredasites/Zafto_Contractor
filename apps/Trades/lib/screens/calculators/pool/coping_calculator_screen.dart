import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Coping Calculator
class CopingCalculatorScreen extends ConsumerStatefulWidget {
  const CopingCalculatorScreen({super.key});
  @override
  ConsumerState<CopingCalculatorScreen> createState() => _CopingCalculatorScreenState();
}

class _CopingCalculatorScreenState extends ConsumerState<CopingCalculatorScreen> {
  final _perimeterController = TextEditingController();
  String _copingType = 'Bullnose';
  String _copingSize = '12"';

  double? _linearFeet;
  int? _piecesNeeded;
  double? _estimatedCost;

  // Coping piece lengths
  static const Map<String, double> _copingLengths = {
    '12"': 1.0,
    '16"': 1.33,
    '24"': 2.0,
  };

  static const Map<String, double> _costPerFoot = {
    'Bullnose': 15,
    'Cantilevered': 12,
    'Paver': 20,
    'Natural Stone': 35,
  };

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);

    if (perimeter == null || perimeter <= 0) {
      setState(() { _linearFeet = null; });
      return;
    }

    final pieceLength = _copingLengths[_copingSize] ?? 1.0;
    final pieces = (perimeter / pieceLength).ceil();
    final costPerFt = _costPerFoot[_copingType] ?? 15;
    final cost = perimeter * costPerFt;

    setState(() {
      _linearFeet = perimeter;
      _piecesNeeded = pieces;
      _estimatedCost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _perimeterController.clear();
    setState(() { _linearFeet = null; });
  }

  @override
  void dispose() {
    _perimeterController.dispose();
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
        title: Text('Pool Coping', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('COPING TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            Text('PIECE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Perimeter', unit: 'ft', hint: '2×(L+W) for rectangular', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linearFeet != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _costPerFoot.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _copingType == type,
        onSelected: (_) => setState(() { _copingType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _copingLengths.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _copingSize == size,
        onSelected: (_) => setState(() { _copingSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Pieces = Perimeter / Piece Length', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Include corner pieces and radius sections', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Linear Feet', '${_linearFeet!.toStringAsFixed(0)} lf'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pieces Needed', '$_piecesNeeded pcs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Cost', '\$${_estimatedCost!.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add 10% for cuts. Order extra corner/radius pieces.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
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
