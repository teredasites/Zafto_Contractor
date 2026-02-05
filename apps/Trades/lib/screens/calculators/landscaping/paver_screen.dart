import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Paver Calculator - Count by size
class PaverScreen extends ConsumerStatefulWidget {
  const PaverScreen({super.key});
  @override
  ConsumerState<PaverScreen> createState() => _PaverScreenState();
}

class _PaverScreenState extends ConsumerState<PaverScreen> {
  final _areaController = TextEditingController(text: '200');
  final _paverLengthController = TextEditingController(text: '8');
  final _paverWidthController = TextEditingController(text: '4');

  String _paverSize = 'custom';
  double _wasteFactor = 10;

  int? _paversNeeded;
  double? _baseTons;
  double? _sandBags;

  @override
  void dispose() { _areaController.dispose(); _paverLengthController.dispose(); _paverWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 200;

    double paverLength;
    double paverWidth;

    switch (_paverSize) {
      case '4x8': paverLength = 8; paverWidth = 4; break;
      case '6x6': paverLength = 6; paverWidth = 6; break;
      case '6x9': paverLength = 9; paverWidth = 6; break;
      case '12x12': paverLength = 12; paverWidth = 12; break;
      case 'custom':
        paverLength = double.tryParse(_paverLengthController.text) ?? 8;
        paverWidth = double.tryParse(_paverWidthController.text) ?? 4;
        break;
      default:
        paverLength = 8; paverWidth = 4;
    }

    // Convert paver size to sq ft
    final paverSqFt = (paverLength * paverWidth) / 144;
    final paversNeeded = (area / paverSqFt * (1 + _wasteFactor / 100)).ceil();

    // Base material: 4" gravel = 0.33 ft depth
    final baseCubicYards = (area * 0.33) / 27;
    final baseTons = baseCubicYards * 1.35; // ~2,700 lbs/yd

    // Sand: 1" bedding = 0.083 ft depth
    final sandCubicFeet = area * 0.083;
    final sandBags = sandCubicFeet / 0.5; // 50 lb bags cover ~0.5 cu ft

    setState(() {
      _paversNeeded = paversNeeded;
      _baseTons = baseTons;
      _sandBags = sandBags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '200'; _paverLengthController.text = '8'; _paverWidthController.text = '4'; setState(() { _paverSize = 'custom'; _wasteFactor = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paver Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PAVER SIZE', ['4x8', '6x6', '6x9', '12x12', 'custom'], _paverSize, {'4x8': '4x8"', '6x6': '6x6"', '6x9': '6x9"', '12x12': '12x12"', 'custom': 'Custom'}, (v) { setState(() => _paverSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            if (_paverSize == 'custom') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ZaftoInputField(label: 'Paver Length', unit: 'in', controller: _paverLengthController, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Paver Width', unit: 'in', controller: _paverWidthController, onChanged: (_) => _calculate())),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste Factor:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 20, divisions: 3, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_paversNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PAVERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_paversNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text('BASE MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel base (4")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sand bedding (1")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandBags!.ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallTips(colors),
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

  Widget _buildInstallTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION LAYERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1. Excavate', '6-8" below grade'),
        _buildTableRow(colors, '2. Gravel base', '4" compacted'),
        _buildTableRow(colors, '3. Sand bedding', '1" screeded'),
        _buildTableRow(colors, '4. Pavers', 'Laid in pattern'),
        _buildTableRow(colors, '5. Joint sand', 'Polymeric recommended'),
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
