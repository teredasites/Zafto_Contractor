import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tile Accent Calculator - Accent tile/border estimation
class TileAccentScreen extends ConsumerStatefulWidget {
  const TileAccentScreen({super.key});
  @override
  ConsumerState<TileAccentScreen> createState() => _TileAccentScreenState();
}

class _TileAccentScreenState extends ConsumerState<TileAccentScreen> {
  final _lengthController = TextEditingController(text: '10');
  final _tileWidthController = TextEditingController(text: '4');

  String _type = 'border';
  String _pattern = 'single';

  double? _linearFeet;
  int? _tiles;
  int? _tilesWithWaste;
  double? _groutLF;

  @override
  void dispose() { _lengthController.dispose(); _tileWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final tileWidth = double.tryParse(_tileWidthController.text) ?? 4;

    final tileWidthFt = tileWidth / 12;

    // Tiles needed
    int patternRows;
    switch (_pattern) {
      case 'single':
        patternRows = 1;
        break;
      case 'double':
        patternRows = 2;
        break;
      case 'triple':
        patternRows = 3;
        break;
      default:
        patternRows = 1;
    }

    final tilesPerRow = (length / tileWidthFt).ceil();
    final tiles = tilesPerRow * patternRows;

    // Add 10% waste
    final tilesWithWaste = (tiles * 1.10).ceil();

    // Grout: perimeter of each tile
    final groutLF = length * patternRows * 2; // Top and bottom of each row

    setState(() { _linearFeet = length; _tiles = tiles; _tilesWithWaste = tilesWithWaste; _groutLF = groutLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '10'; _tileWidthController.text = '4'; setState(() { _type = 'border'; _pattern = 'single'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tile Accent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['border', 'liner', 'pencil', 'chair'], _type, {'border': 'Border', 'liner': 'Liner', 'pencil': 'Pencil', 'chair': 'Chair Rail'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN', ['single', 'double', 'triple'], _pattern, {'single': 'Single Row', 'double': 'Double Row', 'triple': 'Triple Row'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tile Width', unit: 'inches', controller: _tileWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_tiles != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TILES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tilesWithWaste', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Exact Count', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tiles', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grout Lines', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_groutLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Accent tiles sold individually or by linear foot. Order 10% extra for cuts at corners.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypesTable(colors),
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

  Widget _buildTypesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ACCENT TILE TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Border tile', '4-6\" decorative'),
        _buildTableRow(colors, 'Liner/bar', '1-2\" strips'),
        _buildTableRow(colors, 'Pencil liner', '1/2-3/4\" trim'),
        _buildTableRow(colors, 'Chair rail', '2-3\" molded'),
        _buildTableRow(colors, 'Listello', 'Decorative band'),
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
