import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fascia Calculator - Fascia board materials
class FasciaScreen extends ConsumerStatefulWidget {
  const FasciaScreen({super.key});
  @override
  ConsumerState<FasciaScreen> createState() => _FasciaScreenState();
}

class _FasciaScreenState extends ConsumerState<FasciaScreen> {
  final _perimeterController = TextEditingController(text: '160');

  String _fasciaSize = '1x6';
  String _material = 'pvc';
  String _stockLength = '16';

  int? _boardsNeeded;
  double? _linearFeet;
  int? _cornerPieces;

  @override
  void dispose() { _perimeterController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final stockLengthFeet = int.tryParse(_stockLength) ?? 16;

    if (perimeter == null) {
      setState(() { _boardsNeeded = null; _linearFeet = null; _cornerPieces = null; });
      return;
    }

    // Add 10% waste for cuts
    final totalLF = perimeter * 1.10;
    final boardsNeeded = (totalLF / stockLengthFeet).ceil();

    // Estimate corners (assume rectangular, 4 outside corners)
    final cornerPieces = 4;

    setState(() { _boardsNeeded = boardsNeeded; _linearFeet = totalLF; _cornerPieces = cornerPieces; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; setState(() { _fasciaSize = '1x6'; _material = 'pvc'; _stockLength = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fascia', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FASCIA SIZE', ['1x4', '1x6', '1x8', '1x10'], _fasciaSize, (v) { setState(() => _fasciaSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['wood', 'pvc', 'composite', 'aluminum'], _material, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'BOARD LENGTH', ['12', '16', '18', '20'], _stockLength, (v) { setState(() => _stockLength = v); _calculate(); }, suffix: '\''),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_boardsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BOARDS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boardsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Pieces', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cornerPieces', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getMaterialNote() {
    switch (_material) {
      case 'wood': return 'Wood fascia: Prime all sides, especially end cuts. Caulk joints. Paint within 2 weeks.';
      case 'pvc': return 'PVC/cellular: No painting required. Allow 1/8" expansion gap per 18\'. Use PVC cement.';
      case 'composite': return 'Composite: Pre-finished, low maintenance. Scarf joints for seamless look.';
      case 'aluminum': return 'Aluminum coil stock: Custom-bent on site. Wrap over existing wood or install direct.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'wood': 'Wood', 'pvc': 'PVC', 'composite': 'Composite', 'aluminum': 'Aluminum'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('${labels[o] ?? o}$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
