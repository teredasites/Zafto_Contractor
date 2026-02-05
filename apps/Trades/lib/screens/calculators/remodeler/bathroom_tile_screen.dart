import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bathroom Tile Calculator - Floor and wall tile estimation
class BathroomTileScreen extends ConsumerStatefulWidget {
  const BathroomTileScreen({super.key});
  @override
  ConsumerState<BathroomTileScreen> createState() => _BathroomTileScreenState();
}

class _BathroomTileScreenState extends ConsumerState<BathroomTileScreen> {
  final _floorLengthController = TextEditingController(text: '8');
  final _floorWidthController = TextEditingController(text: '5');
  final _wallHeightController = TextEditingController(text: '8');

  String _application = 'floor_wall';
  String _tileSize = '12x24';

  double? _floorSqft;
  double? _wallSqft;
  int? _tileBoxes;
  double? _groutLbs;

  @override
  void dispose() { _floorLengthController.dispose(); _floorWidthController.dispose(); _wallHeightController.dispose(); super.dispose(); }

  void _calculate() {
    final floorLength = double.tryParse(_floorLengthController.text) ?? 0;
    final floorWidth = double.tryParse(_floorWidthController.text) ?? 0;
    final wallHeight = double.tryParse(_wallHeightController.text) ?? 8;

    final floorSqft = floorLength * floorWidth;

    // Wall area: perimeter x height, minus ~15% for door/window
    final perimeter = (floorLength + floorWidth) * 2;
    final wallSqft = (perimeter * wallHeight) * 0.85;

    double totalSqft;
    switch (_application) {
      case 'floor': totalSqft = floorSqft; break;
      case 'wall': totalSqft = wallSqft; break;
      case 'floor_wall': totalSqft = floorSqft + wallSqft; break;
      default: totalSqft = floorSqft;
    }

    // Add 10% waste
    final sqftWithWaste = totalSqft * 1.10;

    // Boxes (typically 10-15 sqft per box)
    final tileBoxes = (sqftWithWaste / 12).ceil();

    // Grout: larger tile = less grout
    double groutFactor;
    switch (_tileSize) {
      case '3x6': groutFactor = 0.5; break;
      case '12x12': groutFactor = 0.3; break;
      case '12x24': groutFactor = 0.25; break;
      case '24x24': groutFactor = 0.2; break;
      default: groutFactor = 0.3;
    }
    final groutLbs = sqftWithWaste * groutFactor;

    setState(() { _floorSqft = floorSqft; _wallSqft = wallSqft; _tileBoxes = tileBoxes; _groutLbs = groutLbs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _floorLengthController.text = '8'; _floorWidthController.text = '5'; _wallHeightController.text = '8'; setState(() { _application = 'floor_wall'; _tileSize = '12x24'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bathroom Tile', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['floor', 'wall', 'floor_wall'], _application, {'floor': 'Floor Only', 'wall': 'Walls Only', 'floor_wall': 'Both'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TILE SIZE', ['3x6', '12x12', '12x24', '24x24'], _tileSize, {'3x6': '3x6\"', '12x12': '12x12\"', '12x24': '12x24\"', '24x24': '24x24\"'}, (v) { setState(() => _tileSize = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Length', unit: 'feet', controller: _floorLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Room Width', unit: 'feet', controller: _floorWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wall Height', unit: 'feet', controller: _wallHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_floorSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TILE BOXES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tileBoxes', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_floorSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grout', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_groutLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use large format tile on floors. Waterproof membrane behind shower walls.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMaterialTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildMaterialTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADDITIONAL MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Thinset', '~50 sqft/bag'),
        _buildTableRow(colors, 'Cement board', 'Wet areas'),
        _buildTableRow(colors, 'Waterproof membrane', 'Shower/tub'),
        _buildTableRow(colors, 'Tile spacers', '1/8\" or 1/16\"'),
        _buildTableRow(colors, 'Schluter trim', 'Outside corners'),
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
