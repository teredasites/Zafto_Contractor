import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Edging Calculator - Linear feet and materials
class EdgingScreen extends ConsumerStatefulWidget {
  const EdgingScreen({super.key});
  @override
  ConsumerState<EdgingScreen> createState() => _EdgingScreenState();
}

class _EdgingScreenState extends ConsumerState<EdgingScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _edgingType = 'steel';
  double _wasteFactor = 10;

  double? _totalFeet;
  int? _pieces;
  int? _stakes;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;

    final totalWithWaste = length * (1 + _wasteFactor / 100);

    // Piece lengths and stakes vary by type
    double pieceLength;
    double stakesPerPiece;
    switch (_edgingType) {
      case 'steel': // 4' sections
        pieceLength = 4;
        stakesPerPiece = 3;
        break;
      case 'aluminum': // 8' sections
        pieceLength = 8;
        stakesPerPiece = 4;
        break;
      case 'plastic': // 20' rolls
        pieceLength = 20;
        stakesPerPiece = 5;
        break;
      case 'paver': // Individual pieces ~4" each
        pieceLength = 1; // Sold per linear foot
        stakesPerPiece = 0;
        break;
      case 'stone': // Individual pieces ~6" each
        pieceLength = 0.5;
        stakesPerPiece = 0;
        break;
      default:
        pieceLength = 4;
        stakesPerPiece = 3;
    }

    final pieces = (totalWithWaste / pieceLength).ceil();
    final stakes = (pieces * stakesPerPiece).ceil();

    setState(() {
      _totalFeet = totalWithWaste;
      _pieces = pieces;
      _stakes = stakes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _edgingType = 'steel'; _wasteFactor = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Edging Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EDGING TYPE', ['steel', 'aluminum', 'plastic', 'paver', 'stone'], _edgingType, {'steel': 'Steel', 'aluminum': 'Alum.', 'plastic': 'Plastic', 'paver': 'Paver', 'stone': 'Stone'}, (v) { setState(() => _edgingType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 15, divisions: 2, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_totalFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EDGING NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_getPieceLabel(), style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_stakes! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stakes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            _buildEdgingGuide(colors),
          ]),
        ),
      ),
    );
  }

  String _getPieceLabel() {
    switch (_edgingType) {
      case 'steel': return "4' sections";
      case 'aluminum': return "8' sections";
      case 'plastic': return "20' rolls";
      case 'paver': return 'Paver pieces';
      case 'stone': return 'Stone pieces';
      default: return 'Pieces';
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildEdgingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EDGING COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Steel', 'Durable, clean lines'),
        _buildTableRow(colors, 'Aluminum', 'Lightweight, no rust'),
        _buildTableRow(colors, 'Plastic', 'Cheap, flexible curves'),
        _buildTableRow(colors, 'Paver', 'Decorative, permanent'),
        _buildTableRow(colors, 'Stone', 'Natural look, heavy'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
