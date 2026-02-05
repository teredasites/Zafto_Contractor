import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landscape Edging Calculator - Landscape edging materials estimation
class LandscapeEdgingScreen extends ConsumerStatefulWidget {
  const LandscapeEdgingScreen({super.key});
  @override
  ConsumerState<LandscapeEdgingScreen> createState() => _LandscapeEdgingScreenState();
}

class _LandscapeEdgingScreenState extends ConsumerState<LandscapeEdgingScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _material = 'steel';
  String _height = '4';

  double? _pieces;
  int? _stakes;
  int? _connectors;
  double? _totalFeet;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;

    // Piece length varies by material
    double pieceLength;
    int stakesPerPiece;
    switch (_material) {
      case 'steel':
        pieceLength = 4; // 4' sections
        stakesPerPiece = 4;
        break;
      case 'aluminum':
        pieceLength = 8; // 8' sections
        stakesPerPiece = 4;
        break;
      case 'plastic':
        pieceLength = 20; // 20' rolls
        stakesPerPiece = 10;
        break;
      case 'brick':
        pieceLength = 0.67; // ~8\" per brick
        stakesPerPiece = 0; // no stakes
        break;
      case 'stone':
        pieceLength = 1; // varies, estimate 1' per stone
        stakesPerPiece = 0;
        break;
      default:
        pieceLength = 4;
        stakesPerPiece = 4;
    }

    final pieces = (length / pieceLength).ceil();

    // Stakes
    int stakes;
    if (_material == 'brick' || _material == 'stone') {
      stakes = 0;
    } else {
      stakes = (pieces * stakesPerPiece * 0.25).ceil(); // ~1 stake per foot
    }

    // Connectors: 1 less than pieces for continuous edging
    int connectors;
    if (_material == 'steel' || _material == 'aluminum') {
      connectors = pieces - 1;
    } else {
      connectors = 0;
    }

    setState(() { _pieces = pieces.toDouble(); _stakes = stakes; _connectors = connectors; _totalFeet = length; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _material = 'steel'; _height = '4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landscape Edging', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['steel', 'aluminum', 'plastic', 'brick', 'stone'], _material, {'steel': 'Steel', 'aluminum': 'Aluminum', 'plastic': 'Plastic', 'brick': 'Brick', 'stone': 'Stone'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'HEIGHT', ['4', '5', '6'], _height, {'4': '4\"', '5': '5\"', '6': '6\"'}, (v) { setState(() => _height = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pieces != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_getMaterialLabel(), style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pieces!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_stakes! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stakes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_connectors! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Connectors', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_connectors', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildComparisonTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getMaterialLabel() {
    switch (_material) {
      case 'steel': return 'STEEL SECTIONS';
      case 'aluminum': return 'ALUMINUM SECTIONS';
      case 'plastic': return 'PLASTIC ROLLS';
      case 'brick': return 'BRICKS';
      case 'stone': return 'STONES';
      default: return 'PIECES';
    }
  }

  String _getMaterialTip() {
    switch (_material) {
      case 'steel':
        return 'Steel edging: most durable, clean lines. Bury 3\" deep. Will rust over time (patina look).';
      case 'aluminum':
        return 'Aluminum: rust-proof, easy to bend for curves. Lighter duty than steel. Won\'t patina.';
      case 'plastic':
        return 'Plastic: budget-friendly, flexible for curves. Tends to heave in freeze/thaw. Bury deep.';
      case 'brick':
        return 'Brick edging: set in sand or mortar. Can lay flat or angled (sawtooth). Classic look.';
      case 'stone':
        return 'Stone: natural look, irregular shapes. Set partially buried. Heavier but permanent.';
      default:
        return 'Install edging with top flush with lawn for easy mowing.';
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

  Widget _buildComparisonTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EDGING COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Steel', 'Best durability'),
        _buildTableRow(colors, 'Aluminum', 'Rust-proof'),
        _buildTableRow(colors, 'Plastic', 'Budget-friendly'),
        _buildTableRow(colors, 'Brick', 'Classic look'),
        _buildTableRow(colors, 'Stone', 'Natural aesthetic'),
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
