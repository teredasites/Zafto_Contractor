import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Waterline Tile Calculator
class TileCalculatorScreen extends ConsumerStatefulWidget {
  const TileCalculatorScreen({super.key});
  @override
  ConsumerState<TileCalculatorScreen> createState() => _TileCalculatorScreenState();
}

class _TileCalculatorScreenState extends ConsumerState<TileCalculatorScreen> {
  final _perimeterController = TextEditingController();
  final _tileHeightController = TextEditingController(text: '6');
  String _tileSize = '6×6"';

  double? _linearFeet;
  double? _sqFt;
  int? _tilesNeeded;

  // Tile sizes in square inches
  static const Map<String, double> _tileSizes = {
    '2×2"': 4,
    '3×3"': 9,
    '6×6"': 36,
    '1×6"': 6,
  };

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final height = double.tryParse(_tileHeightController.text);

    if (perimeter == null || height == null || perimeter <= 0 || height <= 0) {
      setState(() { _linearFeet = null; });
      return;
    }

    // Convert height to feet
    final heightFt = height / 12;
    final sqFt = perimeter * heightFt;

    // Calculate tiles needed
    final tileSqIn = _tileSizes[_tileSize] ?? 36;
    final tileSqFt = tileSqIn / 144;
    final tiles = (sqFt / tileSqFt).ceil();

    setState(() {
      _linearFeet = perimeter;
      _sqFt = sqFt;
      _tilesNeeded = tiles;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _perimeterController.clear();
    _tileHeightController.text = '6';
    setState(() { _linearFeet = null; });
  }

  @override
  void dispose() {
    _perimeterController.dispose();
    _tileHeightController.dispose();
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
        title: Text('Waterline Tile', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('TILE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Perimeter', unit: 'ft', hint: '2×(L+W) for rectangular', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tile Band Height', unit: 'in', hint: '6" typical', controller: _tileHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linearFeet != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _tileSizes.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _tileSize == size,
        onSelected: (_) => setState(() { _tileSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Sq Ft = Perimeter × Height', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Standard waterline: 6" height', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
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
        _buildResultRow(colors, 'Square Feet', '${_sqFt!.toStringAsFixed(1)} sq ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tiles Needed', '$_tilesNeeded tiles', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add 10% for cuts and breakage. Glass tile needs 15%.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
