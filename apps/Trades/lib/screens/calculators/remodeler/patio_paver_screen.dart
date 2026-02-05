import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Patio Paver Calculator - Paver patio materials estimation
class PatioPaverScreen extends ConsumerStatefulWidget {
  const PatioPaverScreen({super.key});
  @override
  ConsumerState<PatioPaverScreen> createState() => _PatioPaverScreenState();
}

class _PatioPaverScreenState extends ConsumerState<PatioPaverScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');

  String _paverSize = '6x9';
  String _pattern = 'herringbone';

  int? _pavers;
  double? _baseTons;
  double? _sandTons;
  int? _edging;
  int? _spikes;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 16;
    final width = double.tryParse(_widthController.text) ?? 12;

    final sqft = length * width;
    final perimeter = (length + width) * 2;

    // Pavers per sq ft depends on size
    double paversPerSqft;
    switch (_paverSize) {
      case '4x8':
        paversPerSqft = 4.5;
        break;
      case '6x6':
        paversPerSqft = 4.0;
        break;
      case '6x9':
        paversPerSqft = 2.67;
        break;
      case '12x12':
        paversPerSqft = 1.0;
        break;
      default:
        paversPerSqft = 2.67;
    }

    // Add 10% for cuts and waste
    final pavers = (sqft * paversPerSqft * 1.10).ceil();

    // Base material: 4\" depth
    // 1 ton covers ~80 sq ft at 4\" depth
    final baseTons = sqft / 80;

    // Bedding sand: 1\" depth
    // 1 ton covers ~100 sq ft at 1\" depth
    final sandTons = sqft / 100;

    // Add polymeric sand for joints
    final polymerSandBags = (sqft / 50).ceil(); // 50 sq ft per bag

    // Edging: perimeter in feet
    final edging = perimeter.ceil();

    // Spikes: 1 per foot of edging
    final spikes = perimeter.ceil();

    setState(() { _pavers = pavers; _baseTons = baseTons; _sandTons = sandTons; _edging = edging; _spikes = spikes; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; setState(() { _paverSize = '6x9'; _pattern = 'herringbone'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Patio Paver', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PAVER SIZE', ['4x8', '6x6', '6x9', '12x12'], _paverSize, {'4x8': '4\"x8\"', '6x6': '6\"x6\"', '6x9': '6\"x9\"', '12x12': '12\"x12\"'}, (v) { setState(() => _paverSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN', ['herringbone', 'running', 'basket', 'random'], _pattern, {'herringbone': 'Herringbone', 'running': 'Running', 'basket': 'Basket', 'random': 'Random'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_pavers != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PAVERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pavers', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bedding Sand', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edge Restraint', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_edging lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spikes (10\")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_spikes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Excavate 6-8\" deep. Compact base in 2\" lifts. Screed sand perfectly level. Use polymeric sand for joints.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLayersTable(colors),
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

  Widget _buildLayersTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BASE LAYERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Excavation', '6-8\" below grade'),
        _buildTableRow(colors, 'Gravel base', '4-6\" compacted'),
        _buildTableRow(colors, 'Bedding sand', '1\" screeded'),
        _buildTableRow(colors, 'Pavers', '2-2.5\" thick'),
        _buildTableRow(colors, 'Joint sand', 'Polymeric recommended'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
